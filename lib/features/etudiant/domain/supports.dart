import '../../../core/models/json.dart';
import 'modeles.dart';
import 'notes.dart';

/// Modèles de `supports/` (`serializers.depot_support`) : ce que le service
/// a **publié** pour la cohorte — un plan validé, un support validé.

class PieceSupport {
  const PieceSupport({this.nom = '', this.taille});

  final String nom;

  /// Octets.
  final int? taille;

  factory PieceSupport.depuisJson(Json json) => PieceSupport(
        nom: json.texte('nom'),
        taille: json.entier('taille'),
      );
}

class DepotSupport {
  const DepotSupport({
    required this.id,
    this.type = '',
    this.typeLibelle = '',
    this.cours = const CoursRef(),
    this.enseignant = '',
    this.deposeLe,
    this.pieces = const [],
    this.telecharge = false,
    this.telechargeLe,
    this.misAJourLe,
    this.nouvelleVersion = false,
  });

  final int id;

  /// `plan` ou `support`.
  final String type;
  final String typeLibelle;
  final CoursRef cours;
  final String enseignant;
  final DateTime? deposeLe;
  final List<PieceSupport> pieces;

  /// Le téléchargement est constaté par le service.
  final bool telecharge;
  final DateTime? telechargeLe;
  final DateTime? misAJourLe;

  /// Le document a changé depuis le dernier téléchargement.
  final bool nouvelleVersion;

  /// À télécharger : jamais téléchargé, ou changé depuis
  /// (`Teaching.services.reste_a_telecharger`).
  bool get resteATelecharger => !telecharge || nouvelleVersion;

  factory DepotSupport.depuisJson(Json json) => DepotSupport(
        id: json.entier('id') ?? 0,
        type: json.texte('type'),
        typeLibelle: json.texte('type_libelle'),
        cours: CoursRef.depuisJson(json.objet('cours')),
        enseignant: json.objet('enseignant')?.texte('nom') ?? '',
        deposeLe: json.date('depose_le'),
        pieces: json.liste('documents', PieceSupport.depuisJson),
        telecharge: json.booleen('telecharge'),
        telechargeLe: json.date('telecharge_le'),
        misAJourLe: json.date('mis_a_jour_le'),
        nouvelleVersion: json.booleen('nouvelle_version'),
      );
}

/// Réponse de `supports/`.
class Supports {
  const Supports({this.annee, this.depots = const [], this.aTelecharger = 0});

  final AnneeAcademique? annee;
  final List<DepotSupport> depots;
  final int aTelecharger;

  /// Les dépôts regroupés par cours, dans l'ordre de la réponse.
  List<(CoursRef, List<DepotSupport>)> get parCours {
    final resultat = <(CoursRef, List<DepotSupport>)>[];
    for (final depot in depots) {
      final i = resultat.indexWhere((e) =>
          e.$1.code == depot.cours.code &&
          e.$1.codeAffiche == depot.cours.codeAffiche);
      if (i < 0) {
        resultat.add((depot.cours, [depot]));
      } else {
        resultat[i].$2.add(depot);
      }
    }
    return resultat;
  }

  factory Supports.depuisJson(Json json) => Supports(
        annee: AnneeAcademique.depuisJson(json.objet('annee')),
        depots: json.liste('depots', DepotSupport.depuisJson),
        aTelecharger: json.entier('a_telecharger') ?? 0,
      );
}
