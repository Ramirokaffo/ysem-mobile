import '../../../core/models/agenda.dart';
import '../../../core/models/json.dart';
import 'reinscription.dart';

/// Modèles de `delegation/` : les gestes de fin de séance du délégué —
/// l'appel des absents et le cahier de texte — et leur circuit (validé
/// d'office, par le service, signé par l'enseignant). Toutes les séances du
/// jour sont rendues, même celles dont la fenêtre n'est pas ouverte.

class MembreDelegation {
  const MembreDelegation({
    required this.id,
    this.nom = '',
    this.matricule = '',
    this.roleLibelle = '',
    this.principal = false,
    this.peutFaireAppel = false,
    this.appelAutorise = false,
  });

  final int id;
  final String nom;
  final String matricule;
  final String roleLibelle;
  final bool principal;

  /// Réglé par le délégué principal pour un assistant.
  final bool peutFaireAppel;
  final bool appelAutorise;

  factory MembreDelegation.depuisJson(Json json) => MembreDelegation(
        id: json.entier('id') ?? 0,
        nom: json.objet('etudiant')?.texte('nom_complet') ?? '',
        matricule: json.objet('etudiant')?.texte('matricule') ?? '',
        roleLibelle: json.texte('role_libelle'),
        principal: json.booleen('principal'),
        peutFaireAppel: json.booleen('peut_faire_appel'),
        appelAutorise: json.booleen('appel_autorise'),
      );
}

/// Où en est un constat du délégué (appel ou cahier) dans son circuit.
class Constat {
  const Constat({
    this.id,
    this.statut = '',
    this.statutLibelle = '',
    this.motifRejet = '',
    this.motifRenvoi = '',
    this.signeLe,
    this.signePar = '',
    this.absents = const [],
  });

  final int? id;

  /// `a_signer`, `renvoye`, `en_attente`, `valide`, `rejete`.
  final String statut;
  final String statutLibelle;
  final String motifRejet;
  final String motifRenvoi;
  final DateTime? signeLe;
  final String signePar;

  /// Pour un appel : les étudiants notés absents.
  final List<int> absents;

  static Constat? depuisJson(Json? json) => json == null
      ? null
      : Constat(
          id: json.entier('id'),
          statut: json.texte('statut'),
          statutLibelle: json.texte('statut_libelle'),
          motifRejet: json.texte('motif_rejet'),
          motifRenvoi: json.texte('motif_renvoi'),
          signeLe: json.date('signe_le'),
          signePar: json.objet('signe_par')?.texte('nom') ?? '',
          absents: [
            for (final v in (json['absents'] as List? ?? const []))
              if (v is int) v,
          ],
        );
}

/// Une séance de la classe et l'état de ses deux fenêtres.
class SeanceDelegue {
  const SeanceDelegue({
    this.date,
    this.debut,
    this.fin,
    this.creneauId,
    this.cours = const CoursRef(),
    this.niveauId,
    this.salle = '',
    this.enseignant = '',
    this.emploiDuTemps,
    this.troncCommun = '',
    this.annulee = false,
    this.chomee = false,
    this.ouverture,
    this.fermeture,
    this.appelOuvert = false,
    this.etatAppel = '',
    this.appelRouvert = false,
    this.appel,
    this.cahierOuvert = false,
    this.etatCahier = '',
    this.cahierRouvert = false,
    this.cahierFermeture,
    this.cahier,
  });

  final DateTime? date;
  final String? debut;
  final String? fin;
  final int? creneauId;
  final CoursRef cours;
  final int? niveauId;
  final String salle;
  final String enseignant;
  final int? emploiDuTemps;
  final String troncCommun;
  final bool annulee;
  final bool chomee;
  final DateTime? ouverture;
  final DateTime? fermeture;

  final bool appelOuvert;

  /// `ouverte`, `renvoye`, `signe`, `valide`, `a_venir`, `close`,
  /// `annulee`, `chomee`, `hors_planning`.
  final String etatAppel;
  final bool appelRouvert;
  final Constat? appel;

  final bool cahierOuvert;

  /// Mêmes valeurs, plus `non_tenue`.
  final String etatCahier;
  final bool cahierRouvert;
  final DateTime? cahierFermeture;
  final Constat? cahier;

  /// Ce qui désigne la séance auprès du serveur (`date`, `course`, `level`,
  /// `time_slot`, `schedule`) : il la retrouve dans l'agenda de la classe.
  Map<String, Object?> get designation => {
        'date': date == null
            ? null
            : '${date!.year.toString().padLeft(4, '0')}-'
                '${date!.month.toString().padLeft(2, '0')}-'
                '${date!.day.toString().padLeft(2, '0')}',
        'course': cours.code,
        'level': niveauId,
        'time_slot': creneauId,
        'schedule': emploiDuTemps,
      };

  factory SeanceDelegue.depuisJson(Json json) {
    final creneau = json.objet('creneau');
    final cahier = json.objet('cahier_texte');
    return SeanceDelegue(
      date: json.date('date'),
      debut: creneau?.texteOuNul('debut'),
      fin: creneau?.texteOuNul('fin'),
      creneauId: creneau?.entier('id'),
      cours: CoursRef.depuisJson(json.objet('cours')),
      niveauId: json.objet('niveau')?.entier('id'),
      salle: json.objet('salle')?.texte('nom') ?? '',
      enseignant: json.objet('enseignant')?.texte('nom') ?? '',
      emploiDuTemps: json.entier('emploi_du_temps'),
      troncCommun: json.texte('tronc_commun_libelle'),
      annulee: json.booleen('annulee'),
      chomee: json.booleen('chomee'),
      ouverture: json.date('ouverture'),
      fermeture: json.date('fermeture'),
      appelOuvert: json.booleen('ouverte'),
      etatAppel: json.texte('etat'),
      appelRouvert: json.booleen('rouverte_par_le_service'),
      appel: Constat.depuisJson(json.objet('appel')),
      cahierOuvert: cahier?.booleen('ouvert') ?? false,
      etatCahier: cahier?.texte('etat') ?? '',
      cahierRouvert: cahier?.booleen('rouvert_par_le_service') ?? false,
      cahierFermeture: cahier?.date('fermeture'),
      cahier: Constat.depuisJson(cahier?.objet('cahier')),
    );
  }
}

class ReouvertureSeance {
  const ReouvertureSeance({
    this.gesteLibelle = '',
    this.date,
    this.debut,
    this.cours = const CoursRef(),
    this.jusquAu,
    this.motif = '',
  });

  final String gesteLibelle;
  final DateTime? date;
  final String? debut;
  final CoursRef cours;
  final DateTime? jusquAu;
  final String motif;

  factory ReouvertureSeance.depuisJson(Json json) => ReouvertureSeance(
        gesteLibelle: json.texte('geste_libelle'),
        date: json.date('date'),
        debut: json.objet('creneau')?.texteOuNul('debut'),
        cours: CoursRef.depuisJson(json.objet('cours')),
        jusquAu: json.date('jusqu_au'),
        motif: json.texte('motif'),
      );
}

class Delegation {
  const Delegation({
    required this.membre,
    this.niveau,
    this.programme,
    this.specialite,
    this.assistants = const [],
    this.appelAutorise = false,
    this.cahierAutorise = false,
    this.circuitAppel,
    this.circuitCahier,
    this.positionExigee = false,
    this.jour,
    this.veille,
    this.lendemain,
    this.aujourdhui,
    this.seances = const [],
    this.reouvertures = const [],
  });

  final MembreDelegation membre;
  final Reference? niveau;
  final Reference? programme;
  final Reference? specialite;
  final List<MembreDelegation> assistants;
  final bool appelAutorise;
  final bool cahierAutorise;

  /// `automatique`, `service`, `enseignant`, `enseignant_service`.
  final String? circuitAppel;
  final String? circuitCahier;
  final bool positionExigee;
  final DateTime? jour;
  final DateTime? veille;
  final DateTime? lendemain;
  final DateTime? aujourdhui;
  final List<SeanceDelegue> seances;
  final List<ReouvertureSeance> reouvertures;

  bool get estAujourdhui => jour != null && jour == aujourdhui;

  factory Delegation.depuisJson(Json json) {
    final delegation = json.objet('delegation');
    return Delegation(
      membre: MembreDelegation.depuisJson(json.objet('membre') ?? const {}),
      niveau: Reference.depuisJson(delegation?.objet('niveau')),
      programme: Reference.depuisJson(delegation?.objet('programme')),
      specialite: Reference.depuisJson(delegation?.objet('specialite')),
      assistants: json.liste('assistants', MembreDelegation.depuisJson),
      appelAutorise: json.booleen('appel_autorise'),
      cahierAutorise: json.booleen('cahier_autorise'),
      circuitAppel: json.texteOuNul('circuit_appel'),
      circuitCahier: json.texteOuNul('circuit_cahier'),
      positionExigee: json.objet('geolocalisation')?.booleen('exigee') ?? false,
      jour: json.date('jour'),
      veille: json.date('veille'),
      lendemain: json.date('lendemain'),
      aujourdhui: json.date('aujourd_hui'),
      seances: json.liste('seances', SeanceDelegue.depuisJson),
      reouvertures: json.liste('reouvertures', ReouvertureSeance.depuisJson),
    );
  }
}

/// Une ligne de la feuille d'appel.
class LigneAppel {
  const LigneAppel({
    required this.etudiantId,
    this.matricule = '',
    this.nom = '',
    this.absent = false,
    this.verrouillee = false,
    this.permission = '',
  });

  final int etudiantId;
  final String matricule;
  final String nom;
  final bool absent;

  /// Couverte par une permission d'absence accordée : le serveur la tient
  /// absente (justifiée) quoi qu'on coche.
  final bool verrouillee;
  final String permission;

  factory LigneAppel.depuisJson(Json json) => LigneAppel(
        etudiantId: json.objet('etudiant')?.entier('id') ?? 0,
        matricule: json.objet('etudiant')?.texte('matricule') ?? '',
        nom: json.objet('etudiant')?.texte('nom_complet') ?? '',
        absent: json.booleen('absent'),
        verrouillee: json.booleen('verrouillee'),
        permission: json.objet('permission')?.texte('type_libelle') ?? '',
      );
}

class FeuilleAppel {
  const FeuilleAppel({
    required this.seance,
    this.dejaRelevee = false,
    this.appel,
    this.positionExigee = false,
    this.lignes = const [],
  });

  final SeanceDelegue seance;
  final bool dejaRelevee;
  final Constat? appel;
  final bool positionExigee;
  final List<LigneAppel> lignes;

  factory FeuilleAppel.depuisJson(Json json) => FeuilleAppel(
        seance: SeanceDelegue.depuisJson(json.objet('seance') ?? const {}),
        dejaRelevee: json.booleen('deja_relevee'),
        appel: Constat.depuisJson(json.objet('appel')),
        positionExigee: json.booleen('position_exigee'),
        lignes: json.liste('lignes', LigneAppel.depuisJson),
      );
}

/// Une séance du programme du plan de cours.
class SeancePlan {
  const SeancePlan({
    required this.id,
    this.numero,
    this.libelle = '',
    this.chapitre = '',
    this.contenu = '',
  });

  final int id;
  final int? numero;
  final String libelle;
  final String chapitre;
  final String contenu;

  static SeancePlan? depuisJson(Json? json) => json == null
      ? null
      : SeancePlan(
          id: json.entier('id') ?? 0,
          numero: json.entier('numero'),
          libelle: json.texte('libelle'),
          chapitre: json.objet('chapitre')?.texte('titre') ?? '',
          contenu: json.texte('contenu'),
        );
}

/// Une des trois questions d'activité pédagogique et ses réponses.
class GroupeActivite {
  const GroupeActivite({
    required this.champ,
    this.libelle = '',
    this.options = const [],
  });

  final String champ;
  final String libelle;
  final List<(String, String)> options;

  factory GroupeActivite.depuisJson(Json json) => GroupeActivite(
        champ: json.texte('champ'),
        libelle: json.texte('libelle'),
        options: json.liste(
            'options', (o) => (o.texte('valeur'), o.texte('libelle'))),
      );
}

class FeuilleCahier {
  const FeuilleCahier({
    required this.seance,
    this.circuit,
    this.positionExigee = false,
    this.cahier,
    this.activites = const {},
    this.blocsFaits = const [],
    this.contenusPrevus = const [],
    this.seancesPlan = const [],
    this.groupes = const [],
  });

  final SeanceDelegue seance;
  final String? circuit;
  final bool positionExigee;
  final Constat? cahier;

  /// Réponses déjà consignées, par champ.
  final Map<String, String> activites;

  /// Séances du plan déjà déclarées faites, dans l'ordre des blocs.
  final List<int> blocsFaits;

  /// Le contenu prévu au plan : repris du programme, jamais saisi.
  final List<SeancePlan> contenusPrevus;
  final List<SeancePlan> seancesPlan;
  final List<GroupeActivite> groupes;

  factory FeuilleCahier.depuisJson(Json json) {
    final cahier = json.objet('cahier');
    final activites = cahier?.objet('activites') ?? const {};
    return FeuilleCahier(
      seance: SeanceDelegue.depuisJson(json.objet('seance') ?? const {}),
      circuit: json.texteOuNul('circuit'),
      positionExigee: json.booleen('position_exigee'),
      cahier: Constat.depuisJson(cahier),
      activites: {
        for (final MapEntry(:key, :value) in activites.entries)
          if (value != null && '$value'.isNotEmpty) key: '$value',
      },
      blocsFaits: [
        for (final bloc in cahier?.liste('blocs', (b) => b) ?? const <Json>[])
          ?bloc.objet('programme_fait')?.entier('id'),
      ],
      contenusPrevus: json.liste(
          'contenus_prevus', (j) => SeancePlan.depuisJson(j)!),
      seancesPlan: json.liste('seances_plan', (j) => SeancePlan.depuisJson(j)!),
      groupes: json.liste('groupes_activites', GroupeActivite.depuisJson),
    );
  }
}
