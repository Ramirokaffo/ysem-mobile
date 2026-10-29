import '../../../core/models/agenda.dart';
import '../../../core/models/champs.dart';
import '../../../core/models/json.dart';

/// Réponse de `emploi-du-temps/?semaine=` : la semaine et le calendrier.
class EmploiDuTemps {
  const EmploiDuTemps({
    this.annee,
    this.semaine = const SemaineScolarite(),
    this.nombreDeSeances = 0,
    this.journees = const [],
    this.calendrier = const [],
  });

  final AnneeAcademique? annee;
  final SemaineScolarite semaine;

  /// Séances tenues de la semaine — le compte du serveur.
  final int nombreDeSeances;
  final List<Journee> journees;
  final List<EvenementCalendrier> calendrier;

  factory EmploiDuTemps.depuisJson(Json json) => EmploiDuTemps(
        annee: AnneeAcademique.depuisJson(json.objet('annee')),
        semaine: SemaineScolarite.depuisJson(json.objet('semaine')),
        nombreDeSeances: json.entier('nombre_de_seances') ?? 0,
        journees: json.liste('journees', Journee.depuisJson),
        calendrier: json.liste('calendrier', EvenementCalendrier.depuisJson),
      );
}

/// Une séance que l'enseignant doit rattraper, et la date en jeu
/// (`lecturers/api/serializers.py::demande_rattrapage`).
class Rattrapage {
  const Rattrapage({
    required this.id,
    required this.cours,
    this.niveau = '',
    this.classe = '',
    this.origineLibelle = '',
    this.motif = '',
    this.seanceManquee,
    this.echeance,
    this.statut = '',
    this.statutLibelle = '',
    this.approbation = '',
    this.approbationLibelle = '',
    this.datePrevue,
    this.debut,
    this.fin,
    this.salle = '',
    this.motifRefus = '',
    this.rattrapeLe,
    this.ouverte = false,
    this.programmee = false,
    this.enAttenteArbitrage = false,
    this.refusee = false,
    this.dateProposable = false,
  });

  final int id;
  final String cours;
  final String niveau;
  final String classe;

  /// D'où vient la demande (séance manquée, jour férié, congé…).
  final String origineLibelle;
  final String motif;
  final DateTime? seanceManquee;

  /// À rattraper avant le…
  final DateTime? echeance;
  final String statut;
  final String statutLibelle;

  /// D'où vient la date : proposée par l'enseignant, elle n'engage rien
  /// avant l'arbitrage du service.
  final String approbation;
  final String approbationLibelle;
  final DateTime? datePrevue;
  final String? debut;
  final String? fin;
  final String salle;

  /// Motif d'une date refusée : sans lui, rien ne dit quoi proposer d'autre.
  final String motifRefus;
  final DateTime? rattrapeLe;
  final bool ouverte;
  final bool programmee;
  final bool enAttenteArbitrage;
  final bool refusee;

  /// Une date peut être proposée (ouverte, ni programmée ni en arbitrage).
  final bool dateProposable;

  factory Rattrapage.depuisJson(Json json) {
    final creneau = json.objet('creneau');
    return Rattrapage(
      id: json.entier('id') ?? 0,
      cours: json.texte('cours'),
      niveau: json.objet('niveau')?.texte('nom') ?? '',
      classe: json.texte('classe'),
      origineLibelle: json.texte('origine_libelle'),
      motif: json.texte('motif'),
      seanceManquee: json.date('seance_manquee'),
      echeance: json.date('echeance'),
      statut: json.texte('statut'),
      statutLibelle: json.texte('statut_libelle'),
      approbation: json.texte('statut_approbation'),
      approbationLibelle: json.texte('statut_approbation_libelle'),
      datePrevue: json.date('date_prevue'),
      debut: creneau?.texteOuNul('debut'),
      fin: creneau?.texteOuNul('fin'),
      salle: json.objet('salle')?.texte('nom') ?? '',
      motifRefus: json.texte('motif_refus'),
      rattrapeLe: json.date('rattrape_le'),
      ouverte: json.booleen('ouverte'),
      programmee: json.booleen('programmee'),
      enAttenteArbitrage: json.booleen('en_attente_arbitrage'),
      refusee: json.booleen('refusee'),
      dateProposable: json.booleen('date_proposable'),
    );
  }
}

/// Réponse de `rattrapages/`.
class Rattrapages {
  const Rattrapages({
    this.rattrapages = const [],
    this.ouverts = 0,
    this.formulaire = const DescriptionFormulaire([]),
  });

  final List<Rattrapage> rattrapages;
  final int ouverts;

  /// Champs du formulaire du web (`date_prevue`, `time_slot`, `classroom`,
  /// `commentaire`) : créneaux et salles proposables.
  final DescriptionFormulaire formulaire;

  List<Rattrapage> get enCours => rattrapages.where((r) => r.ouverte).toList();
  List<Rattrapage> get clos => rattrapages.where((r) => !r.ouverte).toList();

  factory Rattrapages.depuisJson(Json json) => Rattrapages(
        rattrapages: json.liste('rattrapages', Rattrapage.depuisJson),
        ouverts: json.entier('ouverts') ?? 0,
        formulaire: DescriptionFormulaire.depuisJson(json, 'champs'),
      );
}
