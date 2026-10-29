import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/espace.dart';
import '../../../core/models/enseignant.dart';
import '../../../core/models/etudiant.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../data/auth_repository.dart';

/// Session ouverte dans l'application.
class Session {
  const Session({
    required this.espace,
    required this.acteur,
    this.doitChangerMotDePasse = false,
  });

  final Espace espace;

  /// L'étudiant ou l'enseignant tel que le rend l'API.
  final Map<String, dynamic> acteur;
  final bool doitChangerMotDePasse;

  /// L'acteur lu en étudiant (vide pour une session restaurée hors ligne).
  Etudiant get etudiant => Etudiant.depuisJson(acteur);

  /// L'acteur lu en enseignant (vide pour une session restaurée hors ligne).
  Enseignant get enseignant => Enseignant.depuisJson(acteur);

  /// Langue du dossier, `null` tant qu'on ne sait rien de l'acteur.
  String? get langueDuDossier {
    if ((acteur['matricule'] ?? '').toString().isEmpty) return null;
    final langue = (acteur['langue_effective'] ?? '').toString();
    return langue.isEmpty ? 'fr' : langue;
  }

  Session avec({Map<String, dynamic>? acteur, bool? doitChangerMotDePasse}) =>
      Session(
        espace: espace,
        acteur: acteur ?? this.acteur,
        doitChangerMotDePasse:
            doitChangerMotDePasse ?? this.doitChangerMotDePasse,
      );
}

/// État de connexion : `null` = personne n'est connecté.
///
/// Au démarrage, la session est restaurée depuis les jetons enregistrés et
/// revalidée auprès du serveur (`auth/moi/`) : un mot de passe changé
/// depuis un autre appareil ferme la session ici aussi.
class SessionController extends AsyncNotifier<Session?> {
  @override
  Future<Session?> build() async {
    final stockage = ref.read(tokenStorageProvider);
    final espace = await stockage.espaceActif();
    if (espace == null) return null;

    final jetons = await stockage.lire(espace);
    if (jetons == null || jetons.rafraichissementExpire) {
      await stockage.effacer(espace);
      return null;
    }

    final depot = ref.read(authRepositoryProvider(espace));
    try {
      final moi = await depot.moi();
      return Session(
        espace: espace,
        acteur: depot.acteurDe(moi),
        doitChangerMotDePasse: moi['doit_changer_mot_de_passe'] == true,
      );
    } on ApiException catch (e) {
      // Hors ligne : on ne déconnecte pas pour autant, les jetons restent.
      if (e.estErreurReseau) {
        return Session(espace: espace, acteur: const {});
      }
      await stockage.effacer(espace);
      return null;
    }
  }

  /// À appeler après une [ConnexionOuverte] du dépôt d'authentification.
  void ouvrir(ConnexionOuverte connexion) {
    state = AsyncData(Session(
      espace: connexion.espace,
      acteur: connexion.acteur,
      doitChangerMotDePasse: connexion.doitChangerMotDePasse,
    ));
  }

  /// L'acteur a changé côté serveur (langue, double authentification…).
  void mettreAJourActeur(Map<String, dynamic> acteur) {
    final session = state.valueOrNull;
    if (session == null) return;
    state = AsyncData(session.avec(
      acteur: acteur,
      doitChangerMotDePasse: acteur['doit_changer_mot_de_passe'] == true,
    ));
  }

  /// Le mot de passe vient d'être changé : l'écran imposé se lève.
  void marquerMotDePasseChange(Map<String, dynamic> acteur) {
    final session = state.valueOrNull;
    if (session == null) return;
    state = AsyncData(
        session.avec(acteur: acteur, doitChangerMotDePasse: false));
  }

  Future<void> deconnexion() async {
    final session = state.valueOrNull;
    if (session != null) {
      await ref.read(authRepositoryProvider(session.espace)).deconnexion();
    }
    state = const AsyncData(null);
  }

  /// Appelée par le client HTTP quand le serveur refuse définitivement les
  /// jetons (expirés, mot de passe changé, compte fermé).
  Future<void> sessionPerdue(Espace espace) async {
    if (state.valueOrNull?.espace == espace) {
      await ref.read(tokenStorageProvider).definirEspaceActif(null);
      state = const AsyncData(null);
    }
  }
}

final sessionProvider =
    AsyncNotifierProvider<SessionController, Session?>(SessionController.new);
