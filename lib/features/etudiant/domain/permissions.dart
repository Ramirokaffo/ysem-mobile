import '../../../core/models/json.dart';
import 'modeles.dart';

/// Modèles de `permissions/` : les séances demandables d'une semaine et les
/// demandes déjà déposées. Une permission porte sur des **séances**, jamais
/// sur une journée ; et seule une demande accordée décharge.

/// Une séance telle qu'elle se coche. Le `jeton` porte la séance entière :
/// c'est lui, et lui seul, que le dépôt accepte.
class SeanceDemandable {
  const SeanceDemandable({
    required this.jeton,
    this.date,
    this.debut,
    this.fin,
    this.cours,
    this.salle = '',
    this.enseignant = '',
    this.annulee = false,
    this.chomee = false,
    this.demandable = false,
    this.libelle = '',
    this.dejaCouverte,
  });

  final String jeton;
  final DateTime? date;
  final String? debut;
  final String? fin;
  final CoursRef? cours;
  final String salle;
  final String enseignant;
  final bool annulee;
  final bool chomee;
  final bool demandable;
  final String libelle;

  /// Identifiant de la permission qui couvre déjà la séance, le cas échéant.
  final int? dejaCouverte;

  String intitule(String langue) {
    final texte = cours?.libelle(langue) ?? '';
    return texte.isNotEmpty ? texte : libelle;
  }

  factory SeanceDemandable.depuisJson(Json json) {
    final cours = json.objet('cours');
    final creneau = json.objet('creneau');
    return SeanceDemandable(
      jeton: json.texte('jeton'),
      date: json.date('date'),
      debut: creneau?.texteOuNul('debut'),
      fin: creneau?.texteOuNul('fin'),
      cours: cours == null ? null : CoursRef.depuisJson(cours),
      salle: json.objet('salle')?.texte('nom') ?? '',
      enseignant: json.objet('enseignant')?.texte('nom') ?? '',
      annulee: json.booleen('annulee'),
      chomee: json.booleen('chomee'),
      demandable: json.booleen('demandable'),
      libelle: json.texte('libelle'),
      dejaCouverte: json.entier('deja_couverte'),
    );
  }
}

class SeanceDePermission {
  const SeanceDePermission({this.date, this.debut, this.fin, this.cours});

  final DateTime? date;
  final String? debut;
  final String? fin;
  final CoursRef? cours;

  factory SeanceDePermission.depuisJson(Json json) {
    final cours = json.objet('cours');
    final creneau = json.objet('creneau');
    return SeanceDePermission(
      date: json.date('date'),
      debut: creneau?.texteOuNul('debut'),
      fin: creneau?.texteOuNul('fin'),
      cours: cours == null ? null : CoursRef.depuisJson(cours),
    );
  }
}

class DemandePermission {
  const DemandePermission({
    required this.id,
    this.type = '',
    this.typeLibelle = '',
    this.motif = '',
    this.explication = '',
    this.heureArriveePrevue,
    this.justificatifFourni = false,
    this.statut = '',
    this.statutLibelle = '',
    this.ouverte = false,
    this.saisieParLeService = false,
    this.deposeeLe,
    this.decideeLe,
    this.commentaireDecision = '',
    this.seances = const [],
  });

  final int id;

  /// `absence` ou `retard`.
  final String type;
  final String typeLibelle;
  final String motif;
  final String explication;
  final String? heureArriveePrevue;
  final bool justificatifFourni;

  /// `en_attente`, `accordee`, `refusee`, `annulee`.
  final String statut;
  final String statutLibelle;

  /// Encore à trancher : seule une demande ouverte se retire.
  final bool ouverte;
  final bool saisieParLeService;
  final DateTime? deposeeLe;
  final DateTime? decideeLe;
  final String commentaireDecision;
  final List<SeanceDePermission> seances;

  bool get estRetard => type == 'retard';

  factory DemandePermission.depuisJson(Json json) => DemandePermission(
        id: json.entier('id') ?? 0,
        type: json.texte('type'),
        typeLibelle: json.texte('type_libelle'),
        motif: json.texte('motif'),
        explication: json.texte('explication'),
        heureArriveePrevue: json.texteOuNul('heure_arrivee_prevue'),
        justificatifFourni: json.booleen('justificatif_fourni'),
        statut: json.texte('statut'),
        statutLibelle: json.texte('statut_libelle'),
        ouverte: json.booleen('ouverte'),
        saisieParLeService: json.booleen('saisie_par_le_service'),
        deposeeLe: json.date('deposee_le'),
        decideeLe: json.date('decidee_le'),
        commentaireDecision: json.texte('commentaire_decision'),
        seances: json.liste('seances', SeanceDePermission.depuisJson),
      );
}

/// Un choix d'une liste fermée du serveur (objet de la demande, motif).
class Choix {
  const Choix(this.valeur, this.libelle);

  final String valeur;
  final String libelle;
}

class SemainePermissions {
  const SemainePermissions({
    this.debut,
    this.fin,
    this.precedente,
    this.suivante,
    this.courante,
  });

  final DateTime? debut;
  final DateTime? fin;
  final DateTime? precedente;
  final DateTime? suivante;
  final DateTime? courante;

  bool get estCourante =>
      debut != null && courante != null && debut == courante;

  factory SemainePermissions.depuisJson(Json? json) => json == null
      ? const SemainePermissions()
      : SemainePermissions(
          debut: json.date('debut'),
          fin: json.date('fin'),
          precedente: json.date('precedente'),
          suivante: json.date('suivante'),
          courante: json.date('courante'),
        );
}

class Permissions {
  const Permissions({
    this.annee,
    this.depotOuvert = false,
    this.justificatifObligatoire = false,
    this.preavisHeures,
    this.semaine = const SemainePermissions(),
    this.journees = const [],
    this.types = const [],
    this.motifs = const [],
    this.mesDemandes = const [],
    this.enAttente = 0,
  });

  final AnneeAcademique? annee;
  final bool depotOuvert;

  /// Exigé pour une permission d'**absence** seulement.
  final bool justificatifObligatoire;

  /// Préavis attendu : signalé, jamais opposé.
  final int? preavisHeures;
  final SemainePermissions semaine;
  final List<(DateTime, List<SeanceDemandable>)> journees;
  final List<Choix> types;
  final List<Choix> motifs;
  final List<DemandePermission> mesDemandes;
  final int enAttente;

  bool get aDesSeancesDemandables =>
      journees.any((j) => j.$2.any((s) => s.demandable));

  factory Permissions.depuisJson(Json json) => Permissions(
        annee: AnneeAcademique.depuisJson(json.objet('annee')),
        depotOuvert: json.booleen('depot_ouvert'),
        justificatifObligatoire: json.booleen('justificatif_obligatoire'),
        preavisHeures: json.entier('preavis_heures'),
        semaine: SemainePermissions.depuisJson(json.objet('semaine')),
        journees: [
          for (final j in json.liste('journees', (j) => j))
            if (j.date('date') case final date?)
              (date, j.liste('seances', SeanceDemandable.depuisJson)),
        ],
        types: json.liste(
            'types_de_demande', (c) => Choix(c.texte('valeur'), c.texte('libelle'))),
        motifs: json.liste(
            'motifs', (c) => Choix(c.texte('id'), c.texte('libelle'))),
        mesDemandes: json.liste('mes_demandes', DemandePermission.depuisJson),
        enAttente: json.entier('en_attente') ?? 0,
      );
}
