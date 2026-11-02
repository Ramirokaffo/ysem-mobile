import '../../../core/models/agenda.dart';
import '../../../core/models/champs.dart';
import '../../../core/models/json.dart';

// « Mes documents de cours » et plan de cours (`lecturers/api/serializers.py`,
// `views_documents.py`). Le plan rempli en ligne et le fichier du plan sont le
// même contrat pédagogique remis de deux façons : ils se lisent sur une ligne.

/// Les valeurs de `PlanDeCours.statut`.
class StatutsPlan {
  const StatutsPlan._();

  static const brouillon = 'brouillon';
  static const propose = 'propose';
  static const valide = 'valide';
}

/// Formats acceptés au dépôt : la liste fermée du serveur, qui reste juge
/// (`planification.EXTENSIONS_DOCUMENTS_EPREUVE`).
const extensionsDocumentsCours = [
  'pdf', 'doc', 'docx', 'odt', 'rtf', 'txt',
  'xls', 'xlsx', 'ods', 'csv', 'ppt', 'pptx', 'odp',
  'jpg', 'jpeg', 'png', 'zip',
];

/// Dix pièces par dépôt (`Teaching.DOCUMENTS_SUPPORT_MAX`).
const piecesParDepotMax = 10;

/// Dix mégaoctets pour un document confié à l'assistant.
const tailleMaxDocumentAssistant = 10 * 1024 * 1024;

class PieceDeDepot {
  const PieceDeDepot({required this.id, this.nom = '', this.taille = 0});

  final int id;
  final String nom;
  final int taille;

  factory PieceDeDepot.depuisJson(Json json) => PieceDeDepot(
        id: json.entier('id') ?? 0,
        nom: json.texte('nom'),
        taille: json.entier('taille') ?? 0,
      );
}

/// Un renvoi pour correction encore ouvert : le motif est ce qu'il faut reprendre.
class RenvoiDocument {
  const RenvoiDocument({this.motif = '', this.renvoyeLe});

  final String motif;
  final DateTime? renvoyeLe;

  static RenvoiDocument? depuisJson(Json? json) => json == null
      ? null
      : RenvoiDocument(
          motif: json.texte('motif'),
          renvoyeLe: json.date('renvoye_le'),
        );
}

/// Le projet de fin de cours, demandé une fois, au dépôt du support.
class ProjetFinCours {
  const ProjetFinCours({
    this.prevu = false,
    this.description = '',
    this.fichierDepose = false,
  });

  final bool prevu;
  final String description;
  final bool fichierDepose;

  static ProjetFinCours? depuisJson(Json? json) => json == null
      ? null
      : ProjetFinCours(
          prevu: json.booleen('prevu'),
          description: json.texte('description'),
          fichierDepose: json.booleen('fichier_depose'),
        );
}

/// Un dépôt de fichiers, plan ou support.
class DepotDocument {
  const DepotDocument({
    required this.id,
    this.statut = '',
    this.statutLibelle = '',
    this.echeance,
    this.deposeLe,
    this.misAJourLe,
    this.enRetard = false,
    this.joursDeRetard = 0,
    this.moratoire = false,
    this.valide = false,
    this.commentaire = '',
    this.modifiable = false,
    this.modificationApresValidation = false,
    this.enCorrection = false,
    this.renvoi,
    this.pieces = const [],
    this.projet,
  });

  final int id;
  final String statut;
  final String statutLibelle;
  final DateTime? echeance;
  final DateTime? deposeLe;
  final DateTime? misAJourLe;
  final bool enRetard;
  final int joursDeRetard;
  final bool moratoire;
  final bool valide;
  final String commentaire;
  final bool modifiable;
  final bool modificationApresValidation;
  final bool enCorrection;
  final RenvoiDocument? renvoi;
  final List<PieceDeDepot> pieces;
  final ProjetFinCours? projet;

  static DepotDocument? depuisJson(Json? json) => json == null
      ? null
      : DepotDocument(
          id: json.entier('id') ?? 0,
          statut: json.texte('statut'),
          statutLibelle: json.texte('statut_libelle'),
          echeance: json.date('echeance'),
          deposeLe: json.date('depose_le'),
          misAJourLe: json.date('mis_a_jour_le'),
          enRetard: json.booleen('en_retard'),
          joursDeRetard: json.entier('jours_de_retard') ?? 0,
          moratoire: json.booleen('moratoire'),
          valide: json.booleen('valide'),
          commentaire: json.texte('commentaire'),
          modifiable: json.booleen('modifiable'),
          modificationApresValidation:
              json.booleen('modification_apres_validation'),
          enCorrection: json.booleen('en_correction'),
          renvoi: RenvoiDocument.depuisJson(json.objet('renvoi')),
          pieces: json.liste('pieces', PieceDeDepot.depuisJson),
          projet: ProjetFinCours.depuisJson(json.objet('projet_fin_cours')),
        );
}

/// L'état du plan vu de la liste.
class PlanDeLigne {
  const PlanDeLigne({
    required this.id,
    this.statut = '',
    this.statutLibelle = '',
    this.modifiable = false,
    this.modificationApresValidation = false,
    this.saisieAttendue = false,
    this.enCorrection = false,
    this.renvoi,
    this.pieceLisible,
  });

  final int id;
  final String statut;
  final String statutLibelle;
  final bool modifiable;
  final bool modificationApresValidation;
  final bool saisieAttendue;
  final bool enCorrection;
  final RenvoiDocument? renvoi;

  /// La pièce déposée que l'assistant sait lire.
  final int? pieceLisible;

  factory PlanDeLigne.depuisJson(Json json) => PlanDeLigne(
        id: json.entier('id') ?? 0,
        statut: json.texte('statut'),
        statutLibelle: json.texte('statut_libelle'),
        modifiable: json.booleen('modifiable'),
        modificationApresValidation:
            json.booleen('modification_apres_validation'),
        saisieAttendue: json.booleen('saisie_attendue'),
        enCorrection: json.booleen('en_correction'),
        renvoi: RenvoiDocument.depuisJson(json.objet('renvoi')),
        pieceLisible: json.entier('piece_lisible_par_assistant'),
      );
}

/// Une ligne : un cours, son plan et son support.
class LigneDocuments {
  const LigneDocuments({
    required this.plan,
    this.cours = const CoursRef(),
    this.niveau = '',
    this.programme = '',
    this.specialite = '',
    this.classe = '',
    this.depotPlan,
    this.depotSupport,
  });

  final PlanDeLigne plan;
  final CoursRef cours;
  final String niveau;
  final String programme;
  final String specialite;
  final String classe;
  final DepotDocument? depotPlan;
  final DepotDocument? depotSupport;

  String get cohorte => [
        niveau,
        if (specialite.isNotEmpty) specialite else programme,
        classe,
      ].where((s) => s.isNotEmpty).join(' · ');

  factory LigneDocuments.depuisJson(Json json) => LigneDocuments(
        plan: PlanDeLigne.depuisJson(json.objet('plan') ?? const {}),
        cours: CoursRef.depuisJson(json.objet('cours')),
        niveau: json.objet('niveau')?.texte('nom') ?? '',
        programme: json.objet('programme')?.texte('nom') ?? '',
        specialite: json.objet('specialite')?.texte('nom') ?? '',
        classe: json.texte('classe'),
        depotPlan: DepotDocument.depuisJson(json.objet('depot_plan')),
        depotSupport: DepotDocument.depuisJson(json.objet('depot_support')),
      );
}

/// Réponse de `documents/`.
class DocumentsDeCours {
  const DocumentsDeCours({
    this.lignes = const [],
    this.documentsACorriger = 0,
    this.assistantPlan = false,
    this.planPagesMax,
    this.planExtensions = const [],
  });

  final List<LigneDocuments> lignes;
  final int documentsACorriger;
  final bool assistantPlan;
  final int? planPagesMax;

  /// Sans le point : le sélecteur de fichiers ne les veut pas autrement.
  final List<String> planExtensions;

  LigneDocuments? lignePourPlan(int plan) =>
      lignes.where((l) => l.plan.id == plan).firstOrNull;

  factory DocumentsDeCours.depuisJson(Json json) => DocumentsDeCours(
        lignes: json.liste('lignes', LigneDocuments.depuisJson),
        documentsACorriger: json.entier('documents_a_corriger') ?? 0,
        assistantPlan: json.booleen('assistant_plan'),
        planPagesMax: json.entier('plan_pages_max'),
        planExtensions: [
          for (final e in (json['plan_extensions'] as List? ?? const []))
            '$e'.replaceFirst('.', ''),
        ],
      );
}

/// Ce qui suit le dépôt d'un fichier de plan : le remplir en ligne.
class SuiteDepotPlan {
  const SuiteDepotPlan({required this.plan, this.pieceALire});

  final int plan;
  final int? pieceALire;

  static SuiteDepotPlan? depuisJson(Json? json) => json == null
      ? null
      : SuiteDepotPlan(
          plan: json.entier('plan') ?? 0,
          pieceALire: json.entier('piece_a_lire'),
        );
}

/// Réponse d'un dépôt.
class ResultatDepot {
  const ResultatDepot({this.detail = '', this.suite});

  final String detail;
  final SuiteDepotPlan? suite;

  factory ResultatDepot.depuisJson(Json json) => ResultatDepot(
        detail: json.texte('detail'),
        suite: SuiteDepotPlan.depuisJson(json.objet('suite')),
      );
}

// ---------------------------------------------------------------- Plan ----

/// Les trois tableaux du plan, tels que l'API les nomme.
class TablesPlan {
  const TablesPlan._();

  static const chapitres = 'chapitres';
  static const travaux = 'travaux';
  static const programme = 'programme';
  static const toutes = [chapitres, programme, travaux];

  /// Le champ qui numérote une ligne de chaque tableau.
  static String cleNumero(String table) =>
      table == programme ? 'numero' : 'ordre';
}

/// Réponse de `plans/<id>/`.
class PlanEnLigne {
  const PlanEnLigne({
    required this.id,
    this.cours = const CoursRef(),
    this.statut = '',
    this.statutLibelle = '',
    this.objectifs = '',
    this.saisieExigee = false,
    this.transmis = false,
    this.renvoi,
    this.documentSourceNom = '',
    this.documentSourceLe,
    this.modifiable = false,
    this.modificationApresValidation = false,
    this.nbSeancesAttendues = 0,
    this.manques = const [],
    this.lignes = const {},
    this.champsPlan = const DescriptionFormulaire([]),
    this.champsTables = const {},
    this.assistantDisponible = false,
    this.piecesLisibles = const [],
    this.extensionsAssistant = const [],
    this.pagesMax,
  });

  final int id;
  final CoursRef cours;
  final String statut;
  final String statutLibelle;
  final String objectifs;
  final bool saisieExigee;
  final bool transmis;
  final RenvoiDocument? renvoi;
  final String documentSourceNom;
  final DateTime? documentSourceLe;
  final bool modifiable;
  final bool modificationApresValidation;
  final int nbSeancesAttendues;
  final List<String> manques;
  final Map<String, List<Json>> lignes;
  final DescriptionFormulaire champsPlan;
  final Map<String, DescriptionFormulaire> champsTables;
  final bool assistantDisponible;
  final List<PieceDeDepot> piecesLisibles;
  final List<String> extensionsAssistant;
  final int? pagesMax;

  /// La saisie est ouverte : en brouillon, ou plan validé que l'année rouvre.
  bool get saisieOuverte => modifiable || modificationApresValidation;

  factory PlanEnLigne.depuisJson(Json json) {
    final plan = json.objet('plan') ?? const <String, dynamic>{};
    final lignes = json.objet('lignes') ?? const <String, dynamic>{};
    final champs = json.objet('champs') ?? const <String, dynamic>{};
    final assistant = json.objet('assistant') ?? const <String, dynamic>{};
    final source = plan.objet('document_source');
    return PlanEnLigne(
      id: plan.entier('id') ?? 0,
      cours: CoursRef.depuisJson(plan.objet('cours')),
      statut: plan.texte('statut'),
      statutLibelle: plan.texte('statut_libelle'),
      objectifs: plan.texte('objectifs'),
      saisieExigee: plan.booleen('saisie_exigee'),
      transmis: plan.booleen('transmis'),
      renvoi: RenvoiDocument.depuisJson(plan.objet('renvoi')),
      documentSourceNom: source?.texte('nom') ?? '',
      documentSourceLe: source?.date('le'),
      modifiable: json.booleen('modifiable'),
      modificationApresValidation:
          json.booleen('modification_apres_validation'),
      nbSeancesAttendues: json.entier('nb_seances_attendues') ?? 0,
      manques: [
        for (final m in (json['manques_transmission'] as List? ?? const []))
          '$m',
      ],
      lignes: {
        for (final table in TablesPlan.toutes)
          table: [
            for (final l in (lignes[table] as List? ?? const []))
              Map<String, dynamic>.from(l as Map),
          ],
      },
      champsPlan: DescriptionFormulaire.depuisJson(champs, 'plan'),
      champsTables: {
        for (final table in TablesPlan.toutes)
          table: DescriptionFormulaire.depuisJson(champs, table),
      },
      assistantDisponible: assistant.booleen('disponible'),
      piecesLisibles:
          assistant.liste('pieces_lisibles', PieceDeDepot.depuisJson),
      extensionsAssistant: [
        for (final e in (assistant['extensions'] as List? ?? const [])) '$e',
      ],
      pagesMax: assistant.entier('pages_max'),
    );
  }
}

/// Réponse d'un enregistrement du plan : le serveur dit ce qui s'est passé,
/// y compris une transmission refusée alors que la saisie est gardée.
class ResultatPlan {
  const ResultatPlan({this.detail = '', this.issue = '', this.manques = const []});

  final String detail;
  final String issue;
  final List<String> manques;

  /// Le plan est parti au service : il ne se modifie plus d'ici.
  bool get transmis => issue == 'transmis';

  factory ResultatPlan.depuisJson(Json json) => ResultatPlan(
        detail: json.texte('detail'),
        issue: json.texte('issue'),
        manques: [
          for (final m in (json['manques'] as List? ?? const [])) '$m',
        ],
      );
}

/// Une ligne d'un tableau du plan en cours d'édition.
class LigneBrouillon {
  LigneBrouillon({this.id, required Map<String, String> valeurs})
      : valeurs = Map.of(valeurs),
        _origine = Map.of(valeurs);

  /// Vide tant que la ligne n'existe pas au serveur.
  final int? id;
  Map<String, String> valeurs;
  final Map<String, String> _origine;
  bool supprimee = false;
  Map<String, List<String>> erreurs = const {};

  String operator [](String cle) => valeurs[cle] ?? '';

  /// Rien de saisi, hors le numéro qui amorce une séance.
  bool estVierge(String cleNumero) => valeurs.entries
      .where((e) => e.key != cleNumero)
      .every((e) => e.value.trim().isEmpty);

  bool get modifiee {
    if (supprimee) return true;
    final cles = {...valeurs.keys, ..._origine.keys};
    return cles.any((c) => (valeurs[c] ?? '') != (_origine[c] ?? ''));
  }
}

/// Le plan en cours d'édition, gardé en mémoire jusqu'à l'enregistrement.
///
/// Le programme compte toujours N séances : celles qui manquent sont amorcées
/// par leur numéro, et une séance restée vierge ne part pas — le serveur la
/// compterait pour saisie. Seules les lignes touchées sont envoyées : une
/// ligne absente garde sa valeur.
class BrouillonPlan {
  BrouillonPlan._(this._objectifsInitiaux, this.nbSeances, this.tables)
      : objectifs = _objectifsInitiaux;

  factory BrouillonPlan.depuis(PlanEnLigne plan) {
    final brouillon = BrouillonPlan._(
      plan.objectifs,
      plan.nbSeancesAttendues,
      {
        for (final table in TablesPlan.toutes)
          table: [
            for (final ligne in plan.lignes[table] ?? const <Json>[])
              LigneBrouillon(
                id: ligne.entier('id'),
                valeurs: _textes(ligne),
              ),
          ],
      },
    );
    brouillon._amorcerProgramme();
    return brouillon;
  }

  final String _objectifsInitiaux;
  final int nbSeances;
  final Map<String, List<LigneBrouillon>> tables;
  String objectifs;

  /// La dernière proposition de l'assistant n'est pas encore enregistrée :
  /// le serveur rattachera les séances aux chapitres par leur thème.
  bool depuisProposition = false;

  /// L'ordre des lignes du dernier envoi, celui des erreurs du serveur : les
  /// lignes existantes, puis les nouvelles envoyées.
  final Map<String, List<LigneBrouillon>> _dernierEnvoi = {};

  static Map<String, String> _textes(Json ligne) => {
        for (final MapEntry(:key, :value) in ligne.entries)
          if (key != 'id' && key != 'seance' && value is! Map && value is! List)
            key: value == null ? '' : '$value',
      };

  void _amorcerProgramme() {
    final lignes = tables[TablesPlan.programme]!;
    lignes.removeWhere((l) => l.id == null && l.estVierge('numero'));
    final presents = {for (final l in lignes) l['numero']};
    for (var n = 1; n <= nbSeances; n++) {
      if (!presents.contains('$n')) {
        lignes.add(LigneBrouillon(valeurs: {'numero': '$n'}));
      }
    }
  }

  bool _aEnvoyer(String table, LigneBrouillon ligne) => ligne.id == null
      ? !ligne.estVierge(TablesPlan.cleNumero(table))
      : ligne.modifiee;

  bool get modifie =>
      objectifs != _objectifsInitiaux ||
      depuisProposition ||
      tables.entries.any((t) => t.value.any((l) => _aEnvoyer(t.key, l)));

  /// Les lignes à l'écran, dans l'ordre de leur numéro ; l'ordre interne, lui,
  /// reste celui du serveur.
  List<LigneBrouillon> lignesTriees(String table) {
    final cle = TablesPlan.cleNumero(table);
    return [...tables[table]!]..sort((a, b) =>
        (int.tryParse(a[cle]) ?? 1 << 30)
            .compareTo(int.tryParse(b[cle]) ?? 1 << 30));
  }

  /// Séances réellement remplies, sur le total attendu.
  int get seancesRemplies => tables[TablesPlan.programme]!
      .where((l) => !l.supprimee && !l.estVierge('numero'))
      .length;

  /// Le numéro proposé pour une nouvelle ligne.
  String prochainNumero(String table) {
    final cle = TablesPlan.cleNumero(table);
    final numeros = tables[table]!.map((l) => int.tryParse(l[cle]) ?? 0);
    return '${numeros.fold<int>(0, (a, b) => a > b ? a : b) + 1}';
  }

  void ajouter(String table, Map<String, String> valeurs) =>
      tables[table]!.add(LigneBrouillon(valeurs: valeurs));

  /// Une ligne existante se marque, et part en `supprimer` ; une ligne qui
  /// n'est jamais partie disparaît simplement.
  void retirer(String table, LigneBrouillon ligne) {
    if (ligne.id == null) {
      tables[table]!.remove(ligne);
      if (table == TablesPlan.programme) _amorcerProgramme();
    } else {
      ligne.supprimee = true;
    }
  }

  /// Le corps de `POST plans/<id>/`.
  Map<String, dynamic> envoi({bool transmettre = false}) {
    final corps = <String, dynamic>{'objectifs': objectifs};
    if (transmettre) corps['action'] = 'transmettre';
    if (depuisProposition) corps['depuis_proposition'] = true;
    for (final table in TablesPlan.toutes) {
      final lignes = tables[table]!;
      _dernierEnvoi[table] = [
        ...lignes.where((l) => l.id != null),
        ...lignes.where((l) => l.id == null && _aEnvoyer(table, l)),
      ];
      corps[table] = [
        for (final ligne in lignes)
          if (_aEnvoyer(table, ligne))
            ligne.supprimee
                ? {'id': ligne.id, 'supprimer': true}
                : {
                    if (ligne.id != null) 'id': ligne.id,
                    ...ligne.valeurs,
                  },
      ];
    }
    return corps;
  }

  /// Pose sur chaque ligne les erreurs d'un refus ; rend le nombre de lignes
  /// visées par tableau, pour les signaler sur les onglets.
  Map<String, int> poserErreurs(Map<String, dynamic> corps) {
    for (final lignes in tables.values) {
      for (final ligne in lignes) {
        ligne.erreurs = const {};
      }
    }
    final comptes = <String, int>{};
    final tableaux = corps['erreurs_tableaux'];
    if (tableaux is! Map) return comptes;
    for (final table in TablesPlan.toutes) {
      final notes = tableaux[table];
      final lignes = notes is Map ? notes['lignes'] : null;
      final envoyees = _dernierEnvoi[table] ?? const <LigneBrouillon>[];
      if (lignes is! List) continue;
      for (final (i, erreurs) in lignes.indexed) {
        if (i >= envoyees.length || erreurs is! Map || erreurs.isEmpty) continue;
        envoyees[i].erreurs = {
          for (final MapEntry(:key, :value) in erreurs.entries)
            '$key': value is List ? [for (final m in value) '$m'] : ['$value'],
        };
        comptes[table] = (comptes[table] ?? 0) + 1;
      }
    }
    return comptes;
  }

  /// Les messages qui ne visent aucune ligne (numéro répété, séance en trop).
  static List<String> erreursDEnsemble(Map<String, dynamic> corps) {
    final tableaux = corps['erreurs_tableaux'];
    if (tableaux is! Map) return const [];
    return [
      for (final table in TablesPlan.toutes)
        if (tableaux[table] case {'ensemble': final List ensemble})
          for (final m in ensemble) '$m',
    ];
  }

  /// Reporte une proposition de l'assistant : **rien n'est enregistré**,
  /// l'enseignant relit puis enregistre. Une ligne proposée au rang d'une
  /// ligne existante en porte l'`id` et la réécrit ; les autres s'ajoutent.
  void appliquerProposition(Json proposition) {
    final texte = proposition['objectifs'];
    if (texte is String && texte.trim().isNotEmpty) objectifs = texte;
    for (final table in TablesPlan.toutes) {
      final cleNumero = TablesPlan.cleNumero(table);
      for (final brute in (proposition[table] as List? ?? const [])) {
        final ligne = Map<String, dynamic>.from(brute as Map);
        final valeurs = _textes(ligne);
        final id = ligne.entier('id');
        final existante = id != null
            ? tables[table]!.where((l) => l.id == id).firstOrNull
            : tables[table]!
                .where((l) =>
                    l.id == null && l[cleNumero] == (valeurs[cleNumero] ?? ''))
                .firstOrNull;
        if (existante != null) {
          existante
            ..valeurs = {...existante.valeurs, ...valeurs}
            ..supprimee = false;
        } else {
          ajouter(table, valeurs);
        }
      }
    }
    // Une séance réécrite a pu changer de numéro : on ne garde qu'une séance
    // par numéro, et les amorces reprennent ce qui manque encore.
    final remplis = {
      for (final l in tables[TablesPlan.programme]!)
        if (!l.estVierge('numero')) l['numero'],
    };
    tables[TablesPlan.programme]!.removeWhere((l) =>
        l.id == null && l.estVierge('numero') && remplis.contains(l['numero']));
    _amorcerProgramme();
    depuisProposition = true;
  }
}
