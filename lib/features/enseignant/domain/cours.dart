import '../../../core/models/agenda.dart';
import '../../../core/models/json.dart';

/// Un délégué de la classe, point de contact de l'enseignant.
class DelegueDeClasse {
  const DelegueDeClasse({
    required this.nomComplet,
    this.matricule = '',
    this.roleLibelle = '',
    this.principal = false,
    this.precision = '',
    this.telephone = '',
    this.email = '',
  });

  final String nomComplet;
  final String matricule;
  final String roleLibelle;
  final bool principal;

  /// Spécialité pour laquelle il parle, quand le cours en réunit plusieurs.
  final String precision;
  final String telephone;
  final String email;

  factory DelegueDeClasse.depuisJson(Json json) {
    final etudiant = json.objet('etudiant') ?? const {};
    return DelegueDeClasse(
      nomComplet: etudiant.texte('nom_complet'),
      matricule: etudiant.texte('matricule'),
      roleLibelle: json.texte('role_libelle'),
      principal: json.booleen('principal'),
      precision: json.texte('precision'),
      telephone: etudiant.texte('telephone'),
      email: etudiant.texte('email'),
    );
  }
}

/// Un créneau hebdomadaire de la classe.
class CreneauDeClasse {
  const CreneauDeClasse({
    this.jourLibelle = '',
    this.debut,
    this.fin,
    this.salle = '',
  });

  final String jourLibelle;
  final String? debut;
  final String? fin;
  final String salle;

  factory CreneauDeClasse.depuisJson(Json json) {
    final creneau = json.objet('creneau');
    return CreneauDeClasse(
      jourLibelle: json.texte('jour_libelle'),
      debut: creneau?.texteOuNul('debut'),
      fin: creneau?.texteOuNul('fin'),
      salle: json.objet('salle')?.texte('nom') ?? '',
    );
  }
}

/// Une classe de l'enseignant : un cours × une cohorte (`classes/`).
class ClasseEnseignant {
  const ClasseEnseignant({
    required this.cle,
    required this.coursIntitule,
    this.coursIntituleEn = '',
    this.coursCode = '',
    this.cohorte = '',
    this.classe = '',
    this.semestre = '',
    this.effectif = 0,
    this.heuresParSemaine,
    this.creneaux = const [],
    this.delegues = const [],
    this.sansDeleguePrincipal = false,
  });

  /// Clé de la classe : elle voyage dans l'adresse, le serveur la compare
  /// aux classes de l'enseignant sans la décoder.
  final String cle;
  final String coursIntitule;
  final String coursIntituleEn;
  final String coursCode;
  final String cohorte;

  /// Section ou classe en clair (« Section anglophone », « Groupe A »).
  final String classe;
  final String semestre;
  final int effectif;
  final double? heuresParSemaine;
  final List<CreneauDeClasse> creneaux;
  final List<DelegueDeClasse> delegues;
  final bool sansDeleguePrincipal;

  String intitule(String langue) =>
      langue == 'en' && coursIntituleEn.isNotEmpty ? coursIntituleEn : coursIntitule;

  factory ClasseEnseignant.depuisJson(Json json) {
    final cours = json.objet('cours') ?? const {};
    return ClasseEnseignant(
      cle: json.texte('cle'),
      coursIntitule: cours.texte('intitule'),
      coursIntituleEn: cours.texte('intitule_en'),
      coursCode: cours.texte('code_affiche'),
      cohorte: json.texte('cohorte'),
      classe: json.texte('classe'),
      semestre: json.objet('semestre')?.texte('nom') ?? '',
      effectif: json.entier('effectif') ?? 0,
      heuresParSemaine: json.nombre('heures_par_semaine'),
      creneaux: json.liste('creneaux', CreneauDeClasse.depuisJson),
      delegues: json.liste('delegues', DelegueDeClasse.depuisJson),
      sansDeleguePrincipal: json.booleen('sans_delegue_principal'),
    );
  }
}

/// Réponse de `classes/`.
class MesClasses {
  const MesClasses({
    this.classes = const [],
    this.nbClasses = 0,
    this.nbCours = 0,
    this.nbEtudiants = 0,
    this.nbSansDelegue = 0,
  });

  final List<ClasseEnseignant> classes;
  final int nbClasses;
  final int nbCours;

  /// Étudiants distincts, toutes classes confondues.
  final int nbEtudiants;
  final int nbSansDelegue;

  factory MesClasses.depuisJson(Json json) {
    final synthese = json.objet('synthese') ?? const {};
    return MesClasses(
      classes: json.liste('classes', ClasseEnseignant.depuisJson),
      nbClasses: synthese.entier('nb_classes') ?? 0,
      nbCours: synthese.entier('nb_cours') ?? 0,
      nbEtudiants: synthese.entier('nb_etudiants') ?? 0,
      nbSansDelegue: synthese.entier('nb_sans_delegue') ?? 0,
    );
  }
}

/// Un inscrit de la classe et ses manquements sur ce cours.
class EtudiantDeClasse {
  const EtudiantDeClasse({
    required this.matricule,
    required this.nom,
    this.prenom = '',
    this.genre = '',
    this.delegation = '',
    this.absences = 0,
    this.absencesNonJustifiees = 0,
    this.retards = 0,
  });

  final String matricule;
  final String nom;
  final String prenom;
  final String genre;

  /// Rôle de délégation (vide pour un étudiant qui n'en a pas).
  final String delegation;
  final int absences;
  final int absencesNonJustifiees;
  final int retards;

  String get nomComplet => '$nom $prenom'.trim();

  factory EtudiantDeClasse.depuisJson(Json json) => EtudiantDeClasse(
        matricule: json.texte('matricule'),
        nom: json.texte('nom'),
        prenom: json.texte('prenom'),
        genre: json.texte('genre'),
        delegation: json.texte('delegation'),
        absences: json.entier('absences') ?? 0,
        absencesNonJustifiees: json.entier('absences_non_justifiees') ?? 0,
        retards: json.entier('retards') ?? 0,
      );
}

/// Réponse de `classes/<cle>/` : la liste de classe.
class DetailClasse {
  const DetailClasse({
    required this.classe,
    this.effectif = 0,
    this.nbFemmes = 0,
    this.nbHommes = 0,
    this.nbReleves = 0,
    this.nbAbsents = 0,
    this.planStatutLibelle = '',
    this.cleDiscussion = '',
    this.etudiants = const [],
  });

  final ClasseEnseignant classe;
  final int effectif;
  final int nbFemmes;
  final int nbHommes;

  /// Séances relevées en salle sur ce cours.
  final int nbReleves;

  /// Étudiants ayant au moins une absence sur ce cours.
  final int nbAbsents;
  final String planStatutLibelle;
  final String cleDiscussion;
  final List<EtudiantDeClasse> etudiants;

  factory DetailClasse.depuisJson(Json json) => DetailClasse(
        classe: ClasseEnseignant.depuisJson(json.objet('classe') ?? const {}),
        effectif: json.entier('effectif') ?? 0,
        nbFemmes: json.entier('nb_femmes') ?? 0,
        nbHommes: json.entier('nb_hommes') ?? 0,
        nbReleves: json.entier('nb_releves') ?? 0,
        nbAbsents: json.entier('nb_absents') ?? 0,
        planStatutLibelle:
            json.objet('plan_de_cours')?.texte('statut_libelle') ?? '',
        cleDiscussion: json.texte('discussion'),
        etudiants: json.liste('etudiants', EtudiantDeClasse.depuisJson),
      );
}

/// Un bloc du cahier de texte : ce qui a été fait.
class BlocCahier {
  const BlocCahier({this.seance = '', this.chapitre = '', this.contenus = ''});

  /// Séance du plan faite (« Séance 4 — … »).
  final String seance;
  final String chapitre;
  final String contenus;

  factory BlocCahier.depuisJson(Json json) {
    final fait = json.objet('programme_fait');
    return BlocCahier(
      seance: fait?.texte('libelle') ?? '',
      chapitre: json.objet('chapitre')?.texte('titre') ??
          fait?.objet('chapitre')?.texte('titre') ??
          '',
      contenus: json.texte('contenus_realises'),
    );
  }
}

/// Un appel ou un cahier de texte du délégué, adressé à l'enseignant
/// (`fiches-a-signer/`).
class FicheDeSeance {
  const FicheDeSeance({
    required this.id,
    required this.type,
    this.date,
    this.debut,
    this.fin,
    this.cours = '',
    this.coursEn = '',
    this.niveau = '',
    this.salle = '',
    this.delegue = '',
    this.statut = '',
    this.statutLibelle = '',
    this.motifRenvoi = '',
    this.signeLe,
    this.saisieLe,
    this.enAttenteDuService = false,
    this.effectif,
    this.absents = const [],
    this.blocs = const [],
  });

  final int id;

  /// `appel` ou `cahier` : c'est aussi le segment de l'adresse du geste.
  final String type;
  final DateTime? date;
  final String? debut;
  final String? fin;
  final String cours;
  final String coursEn;
  final String niveau;
  final String salle;
  final String delegue;
  final String statut;
  final String statutLibelle;
  final String motifRenvoi;
  final DateTime? signeLe;
  final DateTime? saisieLe;

  /// Signée, elle part encore à la validation du service.
  final bool enAttenteDuService;

  /// Appel : effectif attendu et absents nommés.
  final int? effectif;
  final List<String> absents;

  /// Cahier de texte : ce qui a été fait.
  final List<BlocCahier> blocs;

  bool get estAppel => type == 'appel';

  String intituleCours(String langue) =>
      langue == 'en' && coursEn.isNotEmpty ? coursEn : cours;

  factory FicheDeSeance.depuisJson(Json json) {
    final creneau = json.objet('creneau');
    final cours = json.objet('cours') ?? const {};
    return FicheDeSeance(
      id: json.entier('id') ?? 0,
      type: json.texte('type'),
      date: json.date('date'),
      debut: creneau?.texteOuNul('debut'),
      fin: creneau?.texteOuNul('fin'),
      cours: cours.texte('intitule'),
      coursEn: cours.texte('intitule_en'),
      niveau: json.objet('niveau')?.texte('nom') ?? '',
      salle: json.objet('salle')?.texte('nom') ?? '',
      delegue: json.objet('delegue')?.texte('nom_complet') ?? '',
      statut: json.texte('statut'),
      statutLibelle: json.texte('statut_libelle'),
      motifRenvoi: json.texte('motif_renvoi'),
      signeLe: json.date('signe_le'),
      saisieLe: json.date('saisi_le'),
      enAttenteDuService: json.booleen('en_attente_du_service'),
      effectif: json.entier('effectif'),
      absents: json.liste('absents_detail', (j) => j.texte('nom_complet')),
      blocs: json.liste('blocs', BlocCahier.depuisJson),
    );
  }
}

/// Réponse de `fiches-a-signer/`.
class FichesASigner {
  const FichesASigner({this.fiches = const [], this.historique = const []});

  final List<FicheDeSeance> fiches;

  /// Dernières fiches signées ou renvoyées.
  final List<FicheDeSeance> historique;

  factory FichesASigner.depuisJson(Json json) => FichesASigner(
        fiches: json.liste('fiches', FicheDeSeance.depuisJson),
        historique: json.liste('historique', FicheDeSeance.depuisJson),
      );
}

/// L'avancement d'un cours : les chiffres du service, jamais recalculés
/// (`Teaching.services.get_suivi_enseignant`).
class LigneAvancement {
  const LigneAvancement({
    this.cours = const CoursRef(),
    this.niveau = '',
    this.classe = '',
    this.semestre = '',
    this.seancesFaites = 0,
    this.seancesPrevues = 0,
    this.sourceSeancesPrevues = '',
    this.seancesNonSuivies = 0,
    this.chapitresFaits = 0,
    this.chapitresPrevus = 0,
    this.tauxSeances,
    this.tauxChapitres,
    this.interpretationLibelle = '',
    this.tonalite = '',
    this.derniereSeance,
  });

  final CoursRef cours;
  final String niveau;
  final String classe;
  final String semestre;
  final int seancesFaites;
  final int seancesPrevues;

  /// D'où vient le total prévu (plan, emploi du temps, réglage de l'année).
  final String sourceSeancesPrevues;
  final int seancesNonSuivies;
  final int chapitresFaits;
  final int chapitresPrevus;

  /// De 0 à 1, au-delà en cas d'avance ; `null` faute de prévu.
  final double? tauxSeances;
  final double? tauxChapitres;
  final String interpretationLibelle;

  /// `success`, `warning`, `danger`, `info` ou `secondary`.
  final String tonalite;
  final DateTime? derniereSeance;

  factory LigneAvancement.depuisJson(Json json) => LigneAvancement(
        cours: CoursRef.depuisJson(json.objet('cours')),
        niveau: json.objet('niveau')?.texte('nom') ?? '',
        classe: json.texte('classe'),
        semestre: json.objet('semestre')?.texte('nom') ?? '',
        seancesFaites: json.entier('seances_faites') ?? 0,
        seancesPrevues: json.entier('seances_prevues') ?? 0,
        sourceSeancesPrevues: json.texte('source_seances_prevues_libelle'),
        seancesNonSuivies: json.entier('seances_non_suivies') ?? 0,
        chapitresFaits: json.entier('chapitres_faits') ?? 0,
        chapitresPrevus: json.entier('chapitres_prevus') ?? 0,
        tauxSeances: json.nombre('taux_seances'),
        tauxChapitres: json.nombre('taux_chapitres'),
        interpretationLibelle: json.texte('interpretation_libelle'),
        tonalite: json.texte('tonalite'),
        derniereSeance: json.date('derniere_seance'),
      );
}

/// Une séance observée en salle par le service.
class SeanceObservee {
  const SeanceObservee({
    this.date,
    this.cours = const CoursRef(),
    this.niveau = '',
    this.debut,
    this.fin,
    this.salle = '',
    this.statut = '',
    this.statutLibelle = '',
    this.constatLibelle = '',
    this.resolutionLibelle = '',
    this.chapitreAtteint,
    this.observation = '',
    this.clotureeAutomatiquement = false,
  });

  final DateTime? date;
  final CoursRef cours;
  final String niveau;
  final String? debut;
  final String? fin;
  final String salle;
  final String statut;
  final String statutLibelle;
  final String constatLibelle;
  final String resolutionLibelle;
  final int? chapitreAtteint;
  final String observation;

  /// Constat posé d'office à minuit, que personne n'a observé.
  final bool clotureeAutomatiquement;

  factory SeanceObservee.depuisJson(Json json) {
    final creneau = json.objet('creneau');
    return SeanceObservee(
      date: json.date('date'),
      cours: CoursRef.depuisJson(json.objet('cours')),
      niveau: json.objet('niveau')?.texte('nom') ?? '',
      debut: creneau?.texteOuNul('debut'),
      fin: creneau?.texteOuNul('fin'),
      salle: json.objet('salle')?.texte('nom') ?? '',
      statut: json.texte('statut'),
      statutLibelle: json.texte('statut_libelle'),
      constatLibelle: json.texte('constat_libelle'),
      resolutionLibelle: json.texte('resolution_libelle'),
      chapitreAtteint: json.entier('chapitre_atteint'),
      observation: json.texte('observation'),
      clotureeAutomatiquement: json.booleen('cloturee_automatiquement'),
    );
  }
}

/// Une suite que le service a choisi de partager : jamais un verbatim brut.
class RetourPartage {
  const RetourPartage({this.cours = '', this.constat = '', this.actionMenee = ''});

  final String cours;
  final String constat;
  final String actionMenee;

  factory RetourPartage.depuisJson(Json json) => RetourPartage(
        cours: json.texte('cours'),
        constat: json.texte('constat'),
        actionMenee: json.texte('action_menee'),
      );
}

/// Réponse de `enseignements/`.
class Enseignements {
  const Enseignements({
    this.avancement = const [],
    this.nbSeances = 0,
    this.nbAbsences = 0,
    this.seances = const [],
    this.rattrapagesOuverts = 0,
    this.retours = const [],
  });

  final List<LigneAvancement> avancement;
  final int nbSeances;
  final int nbAbsences;
  final List<SeanceObservee> seances;
  final int rattrapagesOuverts;
  final List<RetourPartage> retours;

  factory Enseignements.depuisJson(Json json) => Enseignements(
        avancement: json.liste('avancement', LigneAvancement.depuisJson),
        nbSeances: json.entier('nb_seances') ?? 0,
        nbAbsences: json.entier('nb_absences') ?? 0,
        seances: json.liste('seances', SeanceObservee.depuisJson),
        rattrapagesOuverts: json
            .liste('rattrapages', (j) => j.booleen('ouverte'))
            .where((ouverte) => ouverte)
            .length,
        retours: json.liste('retours_partages', RetourPartage.depuisJson),
      );
}
