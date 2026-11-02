import '../../../core/models/agenda.dart';
import '../../../core/models/json.dart';
import 'documents.dart';

// « Mes épreuves d'examen » (`lecturers/api/serializers.py::depot_epreuve`).
// L'acceptation du service se lit ici ; la rétention du sujet composé reste
// interne et le serveur ne l'envoie pas.

/// Dix pièces par nature et par sujet (`planification.DOCUMENTS_EPREUVE_MAX`).
const piecesParSujetMax = 10;

/// La campagne de dépôt qui demande l'épreuve.
class CampagneEpreuves {
  const CampagneEpreuves({
    this.intitule = '',
    this.ouverte = false,
    this.consignes = '',
    this.nbSujetsRequis = 0,
    this.corrigeObligatoire = false,
  });

  final String intitule;
  final bool ouverte;
  final String consignes;
  final int nbSujetsRequis;
  final bool corrigeObligatoire;

  factory CampagneEpreuves.depuisJson(Json json) => CampagneEpreuves(
        intitule: json.texte('intitule'),
        ouverte: json.booleen('ouverte'),
        consignes: json.texte('consignes'),
        nbSujetsRequis: json.entier('nb_sujets_requis') ?? 0,
        corrigeObligatoire: json.booleen('corrige_obligatoire'),
      );
}

/// L'énoncé d'un sujet dans une langue, pour une épreuve des deux sections.
class VersionSujet {
  const VersionSujet({
    this.langue = '',
    this.libelle = '',
    this.exigee = false,
    this.pieces = const [],
  });

  final String langue;
  final String libelle;
  final bool exigee;
  final List<PieceDeDepot> pieces;

  factory VersionSujet.depuisJson(Json json) => VersionSujet(
        langue: json.texte('langue'),
        libelle: json.texte('libelle'),
        exigee: json.booleen('exigee'),
        pieces: json.liste('pieces', PieceDeDepot.depuisJson),
      );
}

/// Un sujet demandé, ses pièces et la décision du service.
class SujetEpreuve {
  const SujetEpreuve({
    required this.id,
    this.numero = 0,
    this.intitule = '',
    this.dureeMinutes,
    this.commentaire = '',
    this.deposeLe,
    this.acceptee = false,
    this.modifiable = false,
    this.aSujet = false,
    this.aCorrige = false,
    this.languesManquantes = const [],
    this.versions = const [],
    this.piecesSujet = const [],
    this.piecesCorrige = const [],
  });

  final int id;
  final int numero;
  final String intitule;
  final int? dureeMinutes;
  final String commentaire;
  final DateTime? deposeLe;
  final bool acceptee;

  /// Faux une fois accepté : c'est parmi ces sujets que sera pris celui composé.
  final bool modifiable;
  final bool aSujet;
  final bool aCorrige;
  final List<String> languesManquantes;
  final List<VersionSujet> versions;
  final List<PieceDeDepot> piecesSujet;
  final List<PieceDeDepot> piecesCorrige;

  /// Rien ne manque au regard de ce que la campagne exige.
  bool estComplet(bool corrigeObligatoire) =>
      aSujet &&
      (aCorrige || !corrigeObligatoire) &&
      languesManquantes.isEmpty;

  factory SujetEpreuve.depuisJson(Json json) => SujetEpreuve(
        id: json.entier('id') ?? 0,
        numero: json.entier('numero') ?? 0,
        intitule: json.texte('intitule'),
        dureeMinutes: json.entier('duree_minutes'),
        commentaire: json.texte('commentaire'),
        deposeLe: json.date('depose_le'),
        acceptee: json.booleen('acceptee'),
        modifiable: json.booleen('modifiable'),
        aSujet: json.booleen('a_sujet'),
        aCorrige: json.booleen('a_corrige'),
        languesManquantes: [
          for (final l in (json['langues_manquantes'] as List? ?? const [])) '$l',
        ],
        versions: json.liste('versions_sujet', VersionSujet.depuisJson),
        piecesSujet: json.liste('pieces_sujet', PieceDeDepot.depuisJson),
        piecesCorrige: json.liste('pieces_corrige', PieceDeDepot.depuisJson),
      );
}

/// Le modèle Word d'un sujet, déjà identifié, dans une langue.
class ModeleEpreuve {
  const ModeleEpreuve({this.numero = 0, this.langue = ''});

  final int numero;
  final String langue;

  factory ModeleEpreuve.depuisJson(Json json) => ModeleEpreuve(
        numero: json.entier('numero') ?? 0,
        langue: json.texte('langue'),
      );
}

/// Une épreuve demandée à l'enseignant.
class DepotEpreuve {
  const DepotEpreuve({
    required this.id,
    this.cours = const CoursRef(),
    this.cohorte = '',
    this.campagne = const CampagneEpreuves(),
    this.echeance,
    this.deposeLe,
    this.statutDelaiLibelle = '',
    this.enRetard = false,
    this.joursDeRetard = 0,
    this.moratoire = false,
    this.statutValidation = '',
    this.motifReprise = '',
    this.complet = false,
    this.bilingue = false,
    this.modeles = const [],
    this.sujets = const [],
  });

  final int id;
  final CoursRef cours;
  final String cohorte;
  final CampagneEpreuves campagne;
  final DateTime? echeance;
  final DateTime? deposeLe;
  final String statutDelaiLibelle;
  final bool enRetard;
  final int joursDeRetard;
  final bool moratoire;

  /// `pending`, `accepted` ou `revision`.
  final String statutValidation;
  final String motifReprise;
  final bool complet;
  final bool bilingue;
  final List<ModeleEpreuve> modeles;
  final List<SujetEpreuve> sujets;

  int get sujetsComplets =>
      sujets.where((s) => s.estComplet(campagne.corrigeObligatoire)).length;

  List<ModeleEpreuve> modelesDu(int numero) =>
      modeles.where((m) => m.numero == numero).toList();

  factory DepotEpreuve.depuisJson(Json json) => DepotEpreuve(
        id: json.entier('id') ?? 0,
        cours: CoursRef.depuisJson(json.objet('cours')),
        cohorte: json.texte('cohorte'),
        campagne:
            CampagneEpreuves.depuisJson(json.objet('campagne') ?? const {}),
        echeance: json.date('echeance'),
        deposeLe: json.date('depose_le'),
        statutDelaiLibelle: json.texte('statut_delai_libelle'),
        enRetard: json.booleen('en_retard'),
        joursDeRetard: json.entier('jours_de_retard') ?? 0,
        moratoire: json.booleen('moratoire'),
        statutValidation: json.texte('statut_validation'),
        motifReprise: json.texte('motif_reprise'),
        complet: json.booleen('complet'),
        bilingue: json.booleen('bilingue'),
        modeles: json.liste('modeles', ModeleEpreuve.depuisJson),
        sujets: json.liste('sujets', SujetEpreuve.depuisJson),
      );
}

/// Réponse de `epreuves/`.
class MesEpreuves {
  const MesEpreuves({
    this.depots = const [],
    this.formatsAcceptes = '',
    this.extensionsAcceptees = const [],
    this.aDeposer = 0,
    this.completes = 0,
    this.enRetard = 0,
  });

  final List<DepotEpreuve> depots;

  /// « PDF, Word » : le réglage de l'année, en clair.
  final String formatsAcceptes;
  final List<String> extensionsAcceptees;
  final int aDeposer;
  final int completes;
  final int enRetard;

  DepotEpreuve? depot(int id) => depots.where((d) => d.id == id).firstOrNull;

  factory MesEpreuves.depuisJson(Json json) => MesEpreuves(
        depots: json.liste('depots', DepotEpreuve.depuisJson),
        formatsAcceptes: json.texte('formats_acceptes'),
        extensionsAcceptees: [
          for (final e in (json['extensions_acceptees'] as List? ?? const []))
            '$e'.replaceFirst('.', ''),
        ],
        aDeposer: json.entier('a_deposer') ?? 0,
        completes: json.entier('completes') ?? 0,
        enRetard: json.entier('en_retard') ?? 0,
      );
}
