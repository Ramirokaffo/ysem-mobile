import '../../../core/auth/espace.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

/// Issue d'une tentative de connexion.
sealed class ResultatConnexion {
  const ResultatConnexion();
}

/// Jetons émis et enregistrés : l'acteur est connecté.
class ConnexionOuverte extends ResultatConnexion {
  const ConnexionOuverte({
    required this.espace,
    required this.acteur,
    required this.doitChangerMotDePasse,
  });

  final Espace espace;

  /// L'étudiant ou l'enseignant tel que le rend l'API.
  final Map<String, dynamic> acteur;

  /// Le portail étudiant redirige ; l'API le dit et le client ouvre l'écran
  /// de changement — tout le reste répond 403 `mot_de_passe_a_changer`.
  /// Toujours faux côté enseignant, qui choisit son mot de passe lui-même.
  final bool doitChangerMotDePasse;
}

/// Double authentification : un code a été envoyé par e-mail (`202`).
class CodeRequis extends ResultatConnexion {
  const CodeRequis({
    required this.espace,
    required this.defi,
    required this.message,
    required this.envoye,
    this.adresse,
    this.expireLe,
  });

  /// Espace dont le défi relève : c'est à son API que le code se vérifie.
  final Espace espace;

  /// Référence du défi, à renvoyer avec le code. Inutile sans lui.
  final String defi;
  final String message;
  final bool envoye;

  /// Adresse masquée (`j***@gmail.com`).
  final String? adresse;
  final DateTime? expireLe;
}

/// Ce que les deux API d'authentification ont en commun : vérification du
/// code, renouvellement du défi, acteur courant, mot de passe, double
/// authentification, langue, déconnexion. Seule la connexion elle-même
/// diffère (matricule pour l'étudiant, adresse e-mail pour l'enseignant),
/// et la clé sous laquelle l'acteur est rendu.
abstract class AuthRepository {
  AuthRepository(this.client);

  final ApiClient client;

  Espace get espace;

  /// Clé de l'acteur dans les réponses (`etudiant`, `enseignant`).
  String get cleActeur;

  TokenStorage get _stockage => client.stockage;

  Future<ResultatConnexion> verifierCode({
    required String defi,
    required String code,
  }) async {
    final reponse = await client.post<Map<String, dynamic>>(
      'auth/connexion/verification/',
      donnees: {'defi': defi, 'code': code.trim()},
      public: true,
    );
    return lire(reponse);
  }

  /// Ouvre un défi neuf (nouvelle référence, nouveau délai).
  Future<CodeRequis> renvoyerCode(String defi) async {
    final reponse = await client.post<Map<String, dynamic>>(
      'auth/connexion/renvoyer-code/',
      donnees: {'defi': defi},
      public: true,
    );
    return await lire(reponse) as CodeRequis;
  }

  /// L'acteur que porte le jeton enregistré.
  Future<Map<String, dynamic>> moi() =>
      client.get<Map<String, dynamic>>('auth/moi/');

  /// L'acteur seul, lu dans la réponse de `auth/moi/`.
  Map<String, dynamic> acteurDe(Map<String, dynamic> reponse) =>
      Map<String, dynamic>.from(reponse[cleActeur] as Map);

  /// Change le mot de passe. Le serveur périme les jetons déjà émis et en
  /// rend de nouveaux : ils remplacent les anciens, sans quoi l'appareil se
  /// déconnecterait lui-même. Rend l'acteur à jour et le message.
  Future<({Map<String, dynamic> acteur, String message})> changerMotDePasse({
    required String actuel,
    required String nouveau,
    required String confirmation,
  }) async {
    final reponse = await client.post<Map<String, dynamic>>(
      'auth/mot-de-passe/',
      donnees: {
        'mot_de_passe_actuel': actuel,
        'nouveau_mot_de_passe': nouveau,
        'confirmation': confirmation,
      },
    );
    final precedent = await _stockage.lire(espace);
    await _stockage.ecrire(
      espace,
      Jetons.depuisJson(Map<String, dynamic>.from(reponse['jetons'] as Map),
          precedent: precedent),
    );
    return (
      acteur: acteurDe(reponse),
      message: (reponse['detail'] ?? '').toString(),
    );
  }

  /// Déclare ce téléphone pour les notifications push.
  Future<void> declarerAppareil(String fid, String plateforme) =>
      client.post<Map<String, dynamic>>(
        'appareils/',
        donnees: {'fid': fid, 'plateforme': plateforme},
      );

  /// Ce téléphone ne reçoit plus rien. Le délai est court : la déconnexion
  /// l'attend, et elle doit aboutir sans réseau.
  Future<void> retirerAppareil(String fid) =>
      client.post<Map<String, dynamic>>(
        'appareils/retirer/',
        donnees: {'fid': fid},
        delai: const Duration(seconds: 5),
      );

  /// Active ou désactive la double authentification ; le mot de passe est
  /// redemandé, comme sur le portail web.
  Future<({Map<String, dynamic> acteur, String message})> basculerDoubleAuth({
    required String motDePasse,
    required bool activer,
  }) async {
    final reponse = await client.post<Map<String, dynamic>>(
      'auth/double-authentification/',
      donnees: {'mot_de_passe': motDePasse, 'activer': activer},
    );
    return (
      acteur: acteurDe(reponse),
      message: (reponse['detail'] ?? '').toString(),
    );
  }

  /// Enregistre la langue d'affichage au dossier : le portail web et
  /// l'application lisent ensuite la même préférence.
  Future<Map<String, dynamic>> changerLangue(String langue) async {
    final reponse = await client.post<Map<String, dynamic>>(
      'auth/langue/',
      donnees: {'langue': langue},
    );
    return acteurDe(reponse);
  }

  /// Clôt la session de l'appareil côté serveur puis oublie les jetons —
  /// même si le serveur est injoignable.
  Future<void> deconnexion() async {
    try {
      await client.post<Map<String, dynamic>>('auth/deconnexion/');
    } catch (_) {
      // Rien à faire : les jetons sont oubliés de toute façon.
    } finally {
      await _stockage.effacer(espace);
      await _stockage.definirEspaceActif(null);
    }
  }

  /// Lit la réponse d'une connexion : défi à relever, ou jetons à ranger.
  Future<ResultatConnexion> lire(Map<String, dynamic> corps) async {
    if (corps['code'] == 'double_authentification_requise') {
      return CodeRequis(
        espace: espace,
        defi: corps['defi'] as String,
        message: (corps['detail'] ?? '').toString(),
        envoye: corps['envoye'] == true,
        adresse: corps['adresse'] as String?,
        expireLe: DateTime.tryParse('${corps['expire_le'] ?? ''}'),
      );
    }
    final jetons =
        Jetons.depuisJson(Map<String, dynamic>.from(corps['jetons'] as Map));
    await _stockage.ecrire(espace, jetons);
    await _stockage.definirEspaceActif(espace);
    return ConnexionOuverte(
      espace: espace,
      acteur: acteurDe(corps),
      doitChangerMotDePasse: corps['doit_changer_mot_de_passe'] == true,
    );
  }
}
