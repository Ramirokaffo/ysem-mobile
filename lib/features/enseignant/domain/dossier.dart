import '../../../core/models/champs.dart';
import '../../../core/models/json.dart';
import '../../../core/network/api_exception.dart';
import '../../commun/piece_jointe.dart';

// La saisie du dossier. Rien n'y est recopié des formulaires du web : `profil/`
// rend leurs champs (`champs`) et ce qu'ils montrent (`valeurs`), l'application
// ne décide que de la répartition en écrans. La validation reste au serveur.

/// Les quatre tableaux du dossier, sous leur clé d'API.
enum TableauDossier {
  cursus('cursus'),
  certifications('certifications'),
  experiencesEnseignement('experiences_enseignement'),
  experiencesEntreprise('experiences_entreprise');

  const TableauDossier(this.cle);

  final String cle;
}

/// Les blocs du dossier qui ne sont pas des tableaux : un écran chacun, sur le
/// découpage de la page du web. La photo a son geste à part.
enum BlocDossier {
  identite('identite', [
    'firstname', 'lastname', 'date_naiss', 'place_of_birth', //
    'nationality', 'region_origine', 'gender', 'marital_status',
    'number_of_dependent_children', 'lang', 'nic', 'niu',
    'has_health_problem', 'health_problem_description',
  ]),
  coordonnees('identite', [
    'phone_number', 'phone_number_2', 'address', //
    'emergency_contact_name', 'emergency_contact_relationship',
    'emergency_contact_phone', 'emergency_contact_email',
  ]),
  professionnel('professionnel', ['profil', 'affiliated_university', 'cv']);

  const BlocDossier(this.formulaire, this.champs);

  /// Clé du formulaire du web dans `champs` et `valeurs`.
  final String formulaire;
  final List<String> champs;
}

/// Une ligne d'un tableau, telle que le formulaire du web la montre.
class LigneDeFormulaire {
  const LigneDeFormulaire({
    required this.id,
    this.valeurs = const {},
    this.pieces = const {},
  });

  final int id;
  final Map<String, String> valeurs;

  /// Les champs de fichier qui portent déjà une pièce.
  final Set<String> pieces;

  factory LigneDeFormulaire.depuisJson(Json json) {
    final pieces = json['pieces'];
    return LigneDeFormulaire(
      id: json.entier('id') ?? 0,
      valeurs: _textes(json.objet('valeurs')),
      pieces: pieces is List ? {for (final p in pieces) '$p'} : const {},
    );
  }
}

Map<String, String> _textes(Json? json) =>
    {for (final MapEntry(:key, :value) in (json ?? const {}).entries) key: '${value ?? ''}'};

/// De quoi composer tous les écrans de saisie du dossier.
class FormulairesDossier {
  const FormulairesDossier({
    this.champs = const {},
    this.valeurs = const {},
    this.lignes = const {},
  });

  /// Les champs de chaque formulaire, par clé.
  final Map<String, DescriptionFormulaire> champs;

  /// Les valeurs de `identite` et `professionnel`.
  final Map<String, Map<String, String>> valeurs;

  /// Dans l'ordre où le serveur rend les erreurs d'un refus.
  final Map<TableauDossier, List<LigneDeFormulaire>> lignes;

  DescriptionFormulaire description(String cle) =>
      champs[cle] ?? const DescriptionFormulaire([]);

  LigneDeFormulaire? ligne(TableauDossier tableau, int id) =>
      lignes[tableau]?.where((l) => l.id == id).firstOrNull;

  /// `null` quand le serveur ne rend pas de quoi saisir.
  static FormulairesDossier? depuisJson(Json json) {
    final valeurs = json.objet('valeurs');
    final champs = json.objet('champs');
    if (valeurs == null || champs == null) return null;
    return FormulairesDossier(
      champs: {
        for (final cle in champs.keys)
          cle: DescriptionFormulaire.depuisJson(champs, cle),
      },
      valeurs: {
        for (final cle in const ['identite', 'professionnel'])
          cle: _textes(valeurs.objet(cle)),
      },
      lignes: {
        for (final tableau in TableauDossier.values)
          tableau: valeurs.liste(tableau.cle, LigneDeFormulaire.depuisJson),
      },
    );
  }
}

/// Ce qu'un écran de saisie modifie : un bloc, une ligne, ou une ligne neuve.
sealed class CibleEdition {
  const CibleEdition();
}

final class CibleBloc extends CibleEdition {
  const CibleBloc(this.bloc);

  final BlocDossier bloc;
}

final class CibleLigne extends CibleEdition {
  const CibleLigne(this.tableau, [this.ligne]);

  final TableauDossier tableau;

  /// `null` pour une ligne neuve.
  final LigneDeFormulaire? ligne;
}

/// L'état d'un écran de saisie : valeurs, pièces, et erreurs du dernier envoi.
class SaisieDossier {
  SaisieDossier(
    FormulairesDossier formulaires,
    this.cible, {
    Set<String> piecesDeposees = const {},
  })  : _formulaires = formulaires,
        deposees = {...piecesDeposees} {
    final DescriptionFormulaire description;
    final Iterable<String> noms;
    switch (cible) {
      case CibleBloc(:final bloc):
        description = formulaires.description(bloc.formulaire);
        noms = bloc.champs;
        _initiales = formulaires.valeurs[bloc.formulaire] ?? const {};
      case CibleLigne(:final tableau, :final ligne):
        description = formulaires.description(tableau.cle);
        noms = description.champs.map((c) => c.nom);
        _initiales = ligne?.valeurs ?? const {};
        deposees.addAll(ligne?.pieces ?? const {});
    }
    _ordonner(description, noms);
    valeurs = {..._initiales};
  }

  final FormulairesDossier _formulaires;
  final CibleEdition cible;

  /// Les pièces au dossier avant cette saisie.
  final Set<String> deposees;

  late final Map<String, String> _initiales;

  /// Dans l'ordre d'affichage, le champ libre sous sa liste.
  final List<ChampFormulaire> champs = [];

  /// Champ libre → la liste « Autres » qui le révèle.
  final Map<String, ChampFormulaire> _listes = {};

  late final Map<String, String> valeurs;
  final Map<String, PieceAJoindre> pieces = {};
  final Set<String> retraits = {};

  /// Erreurs du dernier refus, sous les champs de cet écran.
  Map<String, List<String>> erreurs = const {};

  void _ordonner(DescriptionFormulaire description, Iterable<String> noms) {
    final libres = {
      for (final c in description.champs)
        if (c.champAutre.isNotEmpty) c.champAutre,
    };
    for (final nom in noms) {
      final champ = description[nom];
      if (champ == null || libres.contains(nom)) continue;
      champs.add(champ);
      final libre = description[champ.champAutre];
      if (libre != null) {
        champs.add(libre);
        _listes[libre.nom] = champ;
      }
    }
  }

  bool get estLigneNeuve => switch (cible) {
        CibleLigne(ligne: null) => true,
        _ => false,
      };

  String valeur(String nom) => valeurs[nom] ?? '';

  /// La description de santé et le champ libre ne s'offrent que quand la case
  /// ou la liste les appelle, comme sur le web.
  bool estVisible(ChampFormulaire champ) {
    if (champ.nom == 'health_problem_description') {
      return valeur('has_health_problem') == 'true';
    }
    final liste = _listes[champ.nom];
    return liste == null || valeur(liste.nom) == liste.valeurAutre;
  }

  Iterable<ChampFormulaire> get champsVisibles => champs.where(estVisible);

  /// Seul ce qui a changé part : un champ absent garde sa valeur au serveur.
  Map<String, dynamic> _changements() {
    final corps = <String, dynamic>{};
    for (final champ in champsVisibles) {
      final nom = champ.nom;
      if (champ.estFichier) {
        if (retraits.contains(nom)) corps['${nom}_retirer'] = true;
      } else if (estLigneNeuve) {
        if (valeur(nom).isNotEmpty) corps[nom] = valeur(nom);
      } else if (valeur(nom) != (_initiales[nom] ?? '')) {
        corps[nom] = valeur(nom);
      }
    }
    return corps;
  }

  Map<String, dynamic> get corps => switch (cible) {
        CibleBloc() => _changements(),
        CibleLigne(:final tableau, :final ligne) => {
            tableau.cle: [
              {if (ligne != null) 'id': ligne.id, ..._changements()},
            ],
          },
      };

  /// Sous la clé qu'attend le serveur : `<tableau>-0-<champ>` pour une ligne,
  /// la seule de l'envoi.
  Map<String, PieceAJoindre> get fichiers => switch (cible) {
        CibleBloc() => pieces,
        CibleLigne(:final tableau) => {
            for (final MapEntry(:key, :value) in pieces.entries)
              '${tableau.cle}-0-$key': value,
          },
      };

  /// Rang de cette ligne dans `erreurs_tableaux.<tableau>.lignes` : les lignes
  /// connues d'abord, puis la ligne neuve.
  int? _rang(TableauDossier tableau) {
    final cible = this.cible;
    if (cible is! CibleLigne || cible.tableau != tableau) return null;
    final connues = _formulaires.lignes[tableau] ?? const [];
    final ligne = cible.ligne;
    if (ligne == null) return connues.length;
    final rang = connues.indexWhere((l) => l.id == ligne.id);
    return rang < 0 ? null : rang;
  }

  bool _estIci(String nom) => champsVisibles.any((c) => c.nom == nom);

  /// Pose sous leurs champs les erreurs d'un refus, et rend ce qui va au
  /// bandeau.
  ///
  /// Le serveur revalide **tout le dossier**, comme le web : une ligne
  /// ancienne devenue invalide refuse l'envoi d'un écran qui ne la montre pas.
  /// Le bandeau nomme alors le champ et son tableau, sans quoi le message ne
  /// mènerait nulle part.
  List<String> poserErreurs(
    ApiException e,
    Map<TableauDossier, String> titres,
  ) {
    final ici = <String, List<String>>{};
    final bandeau = <String>[e.message];
    final identite = _formulaires.description('identite');
    final professionnel = _formulaires.description('professionnel');
    final blocEnCours = cible is CibleBloc;

    for (final MapEntry(key: nom, value: messages) in e.erreurs.entries) {
      if (blocEnCours && _estIci(nom)) {
        ici[nom] = messages;
        continue;
      }
      final libelle = (identite[nom] ?? professionnel[nom])?.libelle;
      bandeau.addAll(libelle == null
          ? messages
          : messages.map((m) => '$libelle : $m'));
    }

    final tableaux = e.donnees['erreurs_tableaux'];
    if (tableaux is Map) {
      for (final tableau in TableauDossier.values) {
        final erreurs = tableaux[tableau.cle];
        if (erreurs is! Map) continue;
        final titre = titres[tableau] ?? tableau.cle;
        final ensemble = erreurs['ensemble'];
        if (ensemble is List) {
          bandeau.addAll(ensemble.map((m) => '$titre : $m'));
        }
        final lignes = erreurs['lignes'];
        if (lignes is! List) continue;
        final rang = _rang(tableau);
        final champs = _formulaires.description(tableau.cle);
        for (final (i, ligne) in lignes.indexed) {
          if (ligne is! Map) continue;
          for (final MapEntry(:key, :value) in ligne.entries) {
            final nom = '$key';
            final messages =
                value is List ? [for (final m in value) '$m'] : ['$value'];
            if (i == rang && _estIci(nom)) {
              ici[nom] = messages;
              continue;
            }
            final libelle = champs[nom]?.libelle;
            bandeau.addAll(messages.map((m) =>
                libelle == null ? '$titre : $m' : '$titre — $libelle : $m'));
          }
        }
      }
    }
    erreurs = ici;
    return bandeau;
  }
}

/// Réponse de `profil/modifier/`.
class ResultatDossier {
  const ResultatDossier({
    required this.detail,
    this.modifie = false,
    this.avertissement,
  });

  final String detail;
  final bool modifie;

  /// Le dernier diplôme a reculé : déduit du cursus, c'est dit à l'écran.
  final String? avertissement;

  factory ResultatDossier.depuisJson(Json json) => ResultatDossier(
        detail: json.texte('detail'),
        modifie: json.booleen('modifie'),
        avertissement: json.texteOuNul('avertissement'),
      );
}
