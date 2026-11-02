import '../../../core/models/agenda.dart';
import '../../../core/models/champs.dart';
import '../../../core/models/json.dart';

// Disponibilités, ponctualité et vacations : les chiffres du service
// (`lecturers/api/serializers.py`), jamais recalculés ici.

/// Une disponibilité déclarée pour un créneau.
class Disponibilite {
  const Disponibilite({
    required this.id,
    this.creneauId,
    this.creneauLibelle = '',
    this.debutCreneau,
    this.finCreneau,
    this.statut = '',
    this.statutLibelle = '',
    this.debut,
    this.fin,
    this.notes = '',
  });

  final int id;
  final int? creneauId;
  final String creneauLibelle;
  final String? debutCreneau;
  final String? finCreneau;

  /// `available`, `unavailable` ou `preferred`.
  final String statut;
  final String statutLibelle;

  /// Période facultative ; vide, la déclaration vaut pour toute l'année.
  final DateTime? debut;
  final DateTime? fin;
  final String notes;

  factory Disponibilite.depuisJson(Json json) {
    final creneau = json.objet('creneau');
    return Disponibilite(
      id: json.entier('id') ?? 0,
      creneauId: creneau?.entier('id'),
      creneauLibelle: creneau?.texte('libelle') ?? '',
      debutCreneau: creneau?.texteOuNul('debut'),
      finCreneau: creneau?.texteOuNul('fin'),
      statut: json.texte('statut'),
      statutLibelle: json.texte('statut_libelle'),
      debut: json.date('debut'),
      fin: json.date('fin'),
      notes: json.texte('notes'),
    );
  }
}

/// Réponse de `disponibilites/`.
class Disponibilites {
  const Disponibilites({
    this.annee,
    this.disponibilites = const [],
    this.formulaire = const DescriptionFormulaire([]),
  });

  final AnneeAcademique? annee;
  final List<Disponibilite> disponibilites;

  /// Champs du formulaire du web : créneaux proposables, statuts.
  final DescriptionFormulaire formulaire;

  factory Disponibilites.depuisJson(Json json) => Disponibilites(
        annee: AnneeAcademique.depuisJson(json.objet('annee')),
        disponibilites: json.liste('disponibilites', Disponibilite.depuisJson),
        formulaire: DescriptionFormulaire.depuisJson(json, 'champs'),
      );
}

/// Les totaux de ponctualité de l'année.
class TotauxPonctualite {
  const TotauxPonctualite({
    this.seancesRelevees = 0,
    this.absences = 0,
    this.absencesNonJustifiees = 0,
    this.retards = 0,
    this.retardsNonJustifies = 0,
    this.minutesRetard = 0,
    this.minutesRetenues = 0,
    this.minutesPrevues = 0,
    this.minutesEffectives = 0,
    this.minutesPerdues = 0,
  });

  final int seancesRelevees;
  final int absences;
  final int absencesNonJustifiees;
  final int retards;
  final int retardsNonJustifies;
  final int minutesRetard;
  final int minutesRetenues;
  final int minutesPrevues;
  final int minutesEffectives;
  final int minutesPerdues;

  factory TotauxPonctualite.depuisJson(Json json) => TotauxPonctualite(
        seancesRelevees: json.entier('seances_relevees') ?? 0,
        absences: json.entier('absences') ?? 0,
        absencesNonJustifiees: json.entier('absences_non_justifiees') ?? 0,
        retards: json.entier('retards') ?? 0,
        retardsNonJustifies: json.entier('retards_non_justifies') ?? 0,
        minutesRetard: json.entier('minutes_retard') ?? 0,
        minutesRetenues: json.entier('minutes_retenues') ?? 0,
        minutesPrevues: json.entier('minutes_prevues') ?? 0,
        minutesEffectives: json.entier('minutes_effectives') ?? 0,
        minutesPerdues: json.entier('minutes_perdues') ?? 0,
      );
}

/// Une séance relevée en salle.
class SeancePointee {
  const SeancePointee({
    this.date,
    this.cours = const CoursRef(),
    this.niveau = '',
    this.classe = '',
    this.debut,
    this.fin,
    this.salle = '',
    this.statut = '',
    this.statutLibelle = '',
    this.heureAttendue,
    this.heureArrivee,
    this.heureFin,
    this.minutesRetard = 0,
    this.minutesRetenues = 0,
    this.justificationLibelle = '',
    this.motif = '',
    this.finConstateeAutomatiquement = false,
  });

  final DateTime? date;
  final CoursRef cours;
  final String niveau;
  final String classe;
  final String? debut;
  final String? fin;
  final String salle;

  /// `present`, `retard` ou `absent`.
  final String statut;
  final String statutLibelle;
  final String? heureAttendue;
  final String? heureArrivee;
  final String? heureFin;
  final int minutesRetard;
  final int minutesRetenues;
  final String justificationLibelle;
  final String motif;

  /// Heure de fin posée d'office à minuit, et non relevée par un agent.
  final bool finConstateeAutomatiquement;

  factory SeancePointee.depuisJson(Json json) {
    final creneau = json.objet('creneau');
    return SeancePointee(
      date: json.date('date'),
      cours: CoursRef.depuisJson(json.objet('cours')),
      niveau: json.objet('niveau')?.texte('nom') ?? '',
      classe: json.texte('classe'),
      debut: creneau?.texteOuNul('debut'),
      fin: creneau?.texteOuNul('fin'),
      salle: json.objet('salle')?.texte('nom') ?? '',
      statut: json.texte('statut'),
      statutLibelle: json.texte('statut_libelle'),
      heureAttendue: json.texteOuNul('heure_arrivee_attendue'),
      heureArrivee: json.texteOuNul('heure_arrivee'),
      heureFin: json.texteOuNul('heure_fin'),
      minutesRetard: json.entier('minutes_retard') ?? 0,
      minutesRetenues: json.entier('minutes_retenues') ?? 0,
      justificationLibelle: json.texte('justification_libelle'),
      motif: json.texte('motif'),
      finConstateeAutomatiquement: json.booleen('fin_constatee_automatiquement'),
    );
  }
}

/// Une sanction notifiée ; une sanction seulement proposée n'arrive jamais ici.
class SanctionEnseignant {
  const SanctionEnseignant({
    this.typeLibelle = '',
    this.statut = '',
    this.statutLibelle = '',
    this.motif = '',
    this.notifieeLe,
    this.minutesRetenues,
  });

  final String typeLibelle;
  final String statut;
  final String statutLibelle;
  final String motif;
  final DateTime? notifieeLe;
  final int? minutesRetenues;

  factory SanctionEnseignant.depuisJson(Json json) => SanctionEnseignant(
        typeLibelle: json.texte('type_libelle'),
        statut: json.texte('statut'),
        statutLibelle: json.texte('statut_libelle'),
        motif: json.texte('motif'),
        notifieeLe: json.date('notifiee_le'),
        minutesRetenues: json.entier('minutes_retenues'),
      );
}

/// Réponse de `ponctualite/`.
class Ponctualite {
  const Ponctualite({
    this.annee,
    this.avanceAttendue,
    this.tolerance,
    this.totaux,
    this.seances = const [],
    this.sanctions = const [],
  });

  final AnneeAcademique? annee;

  /// Règles de l'année, en minutes.
  final int? avanceAttendue;
  final int? tolerance;

  /// `null` sans année active.
  final TotauxPonctualite? totaux;
  final List<SeancePointee> seances;
  final List<SanctionEnseignant> sanctions;

  factory Ponctualite.depuisJson(Json json) {
    final regles = json.objet('regles');
    final totaux = json.objet('totaux');
    return Ponctualite(
      annee: AnneeAcademique.depuisJson(json.objet('annee')),
      avanceAttendue: regles?.entier('avance_arrivee_attendue_minutes'),
      tolerance: regles?.entier('tolerance_retard_minutes'),
      totaux: totaux == null ? null : TotauxPonctualite.depuisJson(totaux),
      seances: json.liste('seances', SeancePointee.depuisJson),
      sanctions: json.liste('sanctions', SanctionEnseignant.depuisJson),
    );
  }
}

/// Une ligne d'une fiche d'émargement.
class LigneFiche {
  const LigneFiche({
    this.date,
    this.arrivee,
    this.depart,
    this.heures,
    this.rattrapage = false,
    this.observation = '',
  });

  final DateTime? date;
  final String? arrivee;
  final String? depart;
  final double? heures;
  final bool rattrapage;
  final String observation;

  factory LigneFiche.depuisJson(Json json) => LigneFiche(
        date: json.date('date'),
        arrivee: json.texteOuNul('heure_arrivee'),
        depart: json.texteOuNul('heure_depart'),
        heures: json.nombre('heures'),
        rattrapage: json.booleen('rattrapage'),
        observation: json.texte('observation'),
      );
}

/// Une fiche mensuelle d'émargement. L'enseignant la transmet, il ne la
/// valide jamais.
class FicheEmargement {
  const FicheEmargement({
    required this.id,
    this.mois,
    this.cours = const CoursRef(),
    this.cohorte = '',
    this.statut = '',
    this.statutLibelle = '',
    this.motifRejet = '',
    this.transmiseLe,
    this.valideeLe,
    this.nbSeances = 0,
    this.heuresEffectives,
    this.transmissible = false,
    this.seances = const [],
  });

  final int id;
  final DateTime? mois;
  final CoursRef cours;
  final String cohorte;
  final String statut;
  final String statutLibelle;
  final String motifRejet;
  final DateTime? transmiseLe;
  final DateTime? valideeLe;
  final int nbSeances;
  final double? heuresEffectives;
  final bool transmissible;
  final List<LigneFiche> seances;

  factory FicheEmargement.depuisJson(Json json) => FicheEmargement(
        id: json.entier('id') ?? 0,
        mois: json.date('mois'),
        cours: CoursRef.depuisJson(json.objet('cours')),
        cohorte: json.texte('cohorte'),
        statut: json.texte('statut'),
        statutLibelle: json.texte('statut_libelle'),
        motifRejet: json.texte('motif_rejet'),
        transmiseLe: json.date('transmise_le'),
        valideeLe: json.date('validee_le'),
        nbSeances: json.entier('nb_seances') ?? 0,
        heuresEffectives: json.nombre('heures_effectives'),
        transmissible: json.booleen('transmissible'),
        seances: json.liste('seances', LigneFiche.depuisJson),
      );
}

/// Un état mensuel de paiement arrêté ; un brouillon n'arrive jamais ici.
class EtatPaiement {
  const EtatPaiement({
    this.mois,
    this.heuresEffectives,
    this.heuresRattrapage,
    this.heuresRetenues,
    this.montantBrut,
    this.exonere = false,
    this.tauxPrecompte,
    this.montantPrecompte,
    this.montantNet,
    this.statut = '',
    this.statutLibelle = '',
    this.payeLe,
    this.motifBlocage = '',
    this.reserves = const [],
  });

  final DateTime? mois;
  final double? heuresEffectives;
  final double? heuresRattrapage;
  final double? heuresRetenues;
  final double? montantBrut;
  final bool exonere;
  final double? tauxPrecompte;
  final double? montantPrecompte;
  final double? montantNet;
  final String statut;
  final String statutLibelle;
  final DateTime? payeLe;
  final String motifBlocage;

  /// Ce qui pesait sur le mois (plan non déposé, notes non rendues…).
  final List<String> reserves;

  factory EtatPaiement.depuisJson(Json json) {
    final reserves = json['reserves'];
    return EtatPaiement(
      mois: json.date('mois'),
      heuresEffectives: json.nombre('heures_effectives'),
      heuresRattrapage: json.nombre('heures_rattrapage'),
      heuresRetenues: json.nombre('heures_retenues'),
      montantBrut: json.nombre('montant_brut'),
      exonere: json.booleen('exonere_precompte'),
      tauxPrecompte: json.nombre('taux_precompte'),
      montantPrecompte: json.nombre('montant_precompte'),
      montantNet: json.nombre('montant_net'),
      statut: json.texte('statut'),
      statutLibelle: json.texte('statut_libelle'),
      payeLe: json.date('paye_le'),
      motifBlocage: json.texte('motif_blocage'),
      reserves: reserves is List
          ? [for (final r in reserves) r.toString()]
          : const [],
    );
  }
}

/// La vacation d'examen d'une session, arrêtée.
class VacationExamen {
  const VacationExamen({
    this.session = '',
    this.commissions,
    this.surveillance,
    this.brut,
    this.exonere = false,
    this.precompte,
    this.net,
    this.statut = '',
    this.statutLibelle = '',
    this.payeLe,
  });

  final String session;
  final double? commissions;
  final double? surveillance;
  final double? brut;
  final bool exonere;
  final double? precompte;
  final double? net;
  final String statut;
  final String statutLibelle;
  final DateTime? payeLe;

  factory VacationExamen.depuisJson(Json json) => VacationExamen(
        session: json.texte('session'),
        commissions: json.nombre('commissions'),
        surveillance: json.nombre('surveillance'),
        brut: json.nombre('brut'),
        exonere: json.booleen('exonere'),
        precompte: json.nombre('precompte'),
        net: json.nombre('net'),
        statut: json.texte('statut'),
        statutLibelle: json.texte('statut_libelle'),
        payeLe: json.date('paye_le'),
      );
}

/// Réponse de `vacations/`.
class Vacations {
  const Vacations({
    this.annee,
    this.fiches = const [],
    this.etats = const [],
    this.vacationsExamen = const [],
    this.aTransmettre = 0,
  });

  final AnneeAcademique? annee;
  final List<FicheEmargement> fiches;
  final List<EtatPaiement> etats;
  final List<VacationExamen> vacationsExamen;
  final int aTransmettre;

  factory Vacations.depuisJson(Json json) => Vacations(
        annee: AnneeAcademique.depuisJson(json.objet('annee')),
        fiches: json.liste('fiches', FicheEmargement.depuisJson),
        etats: json.liste('etats', EtatPaiement.depuisJson),
        vacationsExamen:
            json.liste('vacations_examen', VacationExamen.depuisJson),
        aTransmettre: json.entier('a_transmettre') ?? 0,
      );
}
