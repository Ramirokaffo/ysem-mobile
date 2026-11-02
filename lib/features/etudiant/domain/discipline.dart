import '../../../core/models/json.dart';
import 'modeles.dart';

/// Modèles de `discipline/` : l'assiduité **exactement** telle que le service
/// la voit (même dénominateur, même seuil, même éligibilité aux examens).
/// Une sanction seulement proposée n'est jamais rendue par le serveur.

/// Taux de 0 à 1, `null` sans séance prévue (pas de division par zéro).
class Assiduite {
  const Assiduite({
    this.seancesPrevues = 0,
    this.absences = 0,
    this.absencesNonJustifiees = 0,
    this.retards = 0,
    this.retardsNonJustifies = 0,
    this.minutesAbsence = 0,
    this.tauxPresence,
    this.eligibilite = '',
    this.eligibiliteLibelle = '',
    this.modeFiable = true,
  });

  final int seancesPrevues;
  final int absences;
  final int absencesNonJustifiees;
  final int retards;
  final int retardsNonJustifies;
  final int minutesAbsence;
  final double? tauxPresence;

  /// `eligible`, `a_risque`, `non_eligible` ou `indetermine`.
  final String eligibilite;
  final String eligibiliteLibelle;

  /// Faux : le taux repose en partie sur des relevés par exception, où seuls
  /// les manquements sont saisis.
  final bool modeFiable;

  factory Assiduite.depuisJson(Json? json) => json == null
      ? const Assiduite()
      : Assiduite(
          seancesPrevues: json.entier('seances_prevues') ?? 0,
          absences: json.entier('absences') ?? 0,
          absencesNonJustifiees: json.entier('absences_non_justifiees') ?? 0,
          retards: json.entier('retards') ?? 0,
          retardsNonJustifies: json.entier('retards_non_justifies') ?? 0,
          minutesAbsence: json.entier('minutes_absence') ?? 0,
          tauxPresence: json.nombre('taux_presence'),
          eligibilite: json.texte('eligibilite'),
          eligibiliteLibelle: json.texte('eligibilite_libelle'),
          modeFiable: json['mode_fiable'] != false,
        );
}

class AssiduiteCours {
  const AssiduiteCours({
    this.cours = const CoursRef(),
    this.seancesPrevues = 0,
    this.absences = 0,
    this.tauxPresence,
    this.eligibilite = '',
    this.eligibiliteLibelle = '',
  });

  final CoursRef cours;
  final int seancesPrevues;
  final int absences;
  final double? tauxPresence;
  final String eligibilite;
  final String eligibiliteLibelle;

  factory AssiduiteCours.depuisJson(Json json) => AssiduiteCours(
        cours: CoursRef.depuisJson(json.objet('cours')),
        seancesPrevues: json.entier('seances_prevues') ?? 0,
        absences: json.entier('absences') ?? 0,
        tauxPresence: json.nombre('taux_presence'),
        eligibilite: json.texte('eligibilite'),
        eligibiliteLibelle: json.texte('eligibilite_libelle'),
      );
}

/// Une absence ou un retard constaté en salle.
class Manquement {
  const Manquement({
    this.date,
    this.cours,
    this.debut,
    this.fin,
    this.statut = '',
    this.statutLibelle = '',
    this.justification = '',
    this.justificationLibelle = '',
    this.motif = '',
    this.minutesRetard,
    this.dateLimiteJustificatif,
    this.justificatifFourni = false,
  });

  final DateTime? date;
  final CoursRef? cours;
  final String? debut;
  final String? fin;

  /// `absent` ou `retard`.
  final String statut;
  final String statutLibelle;

  /// `sans_objet`, `en_attente`, `justifiee`, `non_justifiee`.
  final String justification;
  final String justificationLibelle;
  final String motif;
  final int? minutesRetard;
  final DateTime? dateLimiteJustificatif;
  final bool justificatifFourni;

  bool get estRetard => statut == 'retard';

  factory Manquement.depuisJson(Json json) {
    final cours = json.objet('cours');
    final creneau = json.objet('creneau');
    return Manquement(
      date: json.date('date'),
      cours: cours == null ? null : CoursRef.depuisJson(cours),
      debut: creneau?.texteOuNul('debut'),
      fin: creneau?.texteOuNul('fin'),
      statut: json.texte('statut'),
      statutLibelle: json.texte('statut_libelle'),
      justification: json.texte('justification'),
      justificationLibelle: json.texte('justification_libelle'),
      motif: json.texte('motif'),
      minutesRetard: json.entier('minutes_retard'),
      dateLimiteJustificatif: json.date('date_limite_justificatif'),
      justificatifFourni: json.booleen('justificatif_fourni'),
    );
  }
}

class Sanction {
  const Sanction({
    this.typeLibelle = '',
    this.statut = '',
    this.statutLibelle = '',
    this.motif = '',
    this.dateEffet,
    this.dateFinEffet,
    this.decideeLe,
  });

  final String typeLibelle;

  /// `validee`, `notifiee`, `appliquee`, `levee`, `annulee`.
  final String statut;
  final String statutLibelle;
  final String motif;
  final DateTime? dateEffet;
  final DateTime? dateFinEffet;
  final DateTime? decideeLe;

  bool get close => statut == 'levee' || statut == 'annulee';

  factory Sanction.depuisJson(Json json) => Sanction(
        typeLibelle: json.texte('type_libelle'),
        statut: json.texte('statut'),
        statutLibelle: json.texte('statut_libelle'),
        motif: json.texte('motif'),
        dateEffet: json.date('date_effet'),
        dateFinEffet: json.date('date_fin_effet'),
        decideeLe: json.date('decidee_le'),
      );
}

class IncidentVestimentaire {
  const IncidentVestimentaire({
    this.date,
    this.typeLibelle = '',
    this.description = '',
    this.evolutionLibelle = '',
    this.echeance,
    this.clos = false,
    this.enRetard = false,
  });

  final DateTime? date;
  final String typeLibelle;
  final String description;
  final String evolutionLibelle;

  /// Échéance de régularisation (calculée par le service).
  final DateTime? echeance;
  final bool clos;
  final bool enRetard;

  factory IncidentVestimentaire.depuisJson(Json json) => IncidentVestimentaire(
        date: json.date('date'),
        typeLibelle: json.texte('type_libelle'),
        description: json.texte('description'),
        evolutionLibelle: json.texte('evolution_libelle'),
        echeance: json.date('echeance'),
        clos: json.booleen('clos'),
        enRetard: json.booleen('en_retard'),
      );
}

/// Réponse de `discipline/`.
class DossierDiscipline {
  const DossierDiscipline({
    this.annee,
    this.seuilAssiduite,
    this.assiduite = const Assiduite(),
    this.parCours = const [],
    this.manquements = const [],
    this.sanctions = const [],
    this.sanctionsActives = 0,
    this.incidents = const [],
    this.pointsRetires,
    this.vide = false,
  });

  final AnneeAcademique? annee;

  /// Seuil d'accès aux examens, de 0 à 1 (0,75 par défaut).
  final double? seuilAssiduite;
  final Assiduite assiduite;
  final List<AssiduiteCours> parCours;
  final List<Manquement> manquements;
  final List<Sanction> sanctions;
  final int sanctionsActives;
  final List<IncidentVestimentaire> incidents;
  final double? pointsRetires;

  /// Aucun dossier pour l'année (pas d'année active, pas d'inscription).
  final bool vide;

  factory DossierDiscipline.depuisJson(Json json) {
    final dossier = json.objet('dossier');
    final annee = AnneeAcademique.depuisJson(json.objet('annee'));
    if (dossier == null) return DossierDiscipline(annee: annee, vide: true);
    return DossierDiscipline(
      annee: annee,
      seuilAssiduite: json.nombre('seuil_assiduite'),
      assiduite: Assiduite.depuisJson(dossier.objet('assiduite')),
      parCours: dossier.liste('par_cours', AssiduiteCours.depuisJson),
      manquements: dossier.liste('manquements', Manquement.depuisJson),
      sanctions: dossier.liste('sanctions', Sanction.depuisJson),
      sanctionsActives: dossier.entier('sanctions_actives') ?? 0,
      incidents:
          dossier.liste('incidents_vestimentaires', IncidentVestimentaire.depuisJson),
      pointsRetires: dossier.nombre('points_retires'),
    );
  }
}
