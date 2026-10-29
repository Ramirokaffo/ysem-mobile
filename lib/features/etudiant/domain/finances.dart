import '../../../core/models/json.dart';
import 'modeles.dart';

/// Modèles de `finances/` (`serializers.situation_financiere` et suivants).
///
/// Le calcul de dette n'est pas refait ici : le montant échu est celui de
/// `payments.utils.build_student_financial_statement`, net de la couverture
/// des moratoires actifs — ce que le guichet réclame, au franc près.

class Tranche {
  const Tranche({
    required this.id,
    this.libelle = '',
    this.ordre,
    this.echeance,
    this.montant = 0,
    this.montantPaye = 0,
    this.resteAPayer = 0,
    this.echue = false,
    this.statutLibelle = '',
    this.couverteParMoratoire = false,
  });

  final int id;
  final String libelle;
  final int? ordre;
  final DateTime? echeance;
  final double montant;
  final double montantPaye;
  final double resteAPayer;
  final bool echue;
  final String statutLibelle;
  final bool couverteParMoratoire;

  bool get soldee => resteAPayer <= 0;

  /// Code de ton pour la pastille : soldée, échue, couverte, en cours.
  String get etat {
    if (soldee) return 'paid';
    if (couverteParMoratoire) return 'moratorium';
    if (echue) return 'overdue';
    if (montantPaye > 0) return 'partial';
    return '';
  }

  factory Tranche.depuisJson(Json json) => Tranche(
        id: json.entier('id') ?? 0,
        libelle: json.texte('libelle'),
        ordre: json.entier('ordre'),
        echeance: json.date('echeance'),
        montant: json.nombre('montant') ?? 0,
        montantPaye: json.nombre('montant_paye') ?? 0,
        resteAPayer: json.nombre('reste_a_payer') ?? 0,
        echue: json.booleen('echue'),
        statutLibelle: json.texte('statut_libelle'),
        couverteParMoratoire: json.booleen('couverte_par_moratoire'),
      );
}

class Paiement {
  const Paiement({
    required this.id,
    this.montant = 0,
    this.date,
    this.categorieLibelle = '',
    this.sourceLibelle = '',
    this.numeroRecu = '',
    this.transaction = '',
    this.tranche = '',
    this.aUnRecu = false,
  });

  final int id;
  final double montant;
  final DateTime? date;
  final String categorieLibelle;
  final String sourceLibelle;
  final String numeroRecu;
  final String transaction;
  final String tranche;
  final bool aUnRecu;

  /// Ce qui identifie le paiement pour l'étudiant : n° de reçu, sinon
  /// référence de transaction.
  String get reference => numeroRecu.isNotEmpty ? numeroRecu : transaction;

  factory Paiement.depuisJson(Json json) => Paiement(
        id: json.entier('id') ?? 0,
        montant: json.nombre('montant') ?? 0,
        date: json.date('date'),
        categorieLibelle: json.texte('categorie_libelle'),
        sourceLibelle: json.texte('source_libelle'),
        numeroRecu: json.texte('numero_recu'),
        transaction: json.texte('transaction'),
        tranche: json.texte('tranche'),
        aUnRecu: json.texteOuNul('recu_url') != null,
      );
}

class MoratoireAccorde {
  const MoratoireAccorde({
    required this.id,
    this.montant = 0,
    this.echeance,
    this.statut = '',
    this.statutLibelle = '',
    this.actif = false,
  });

  final int id;
  final double montant;
  final DateTime? echeance;
  final String statut;
  final String statutLibelle;
  final bool actif;

  factory MoratoireAccorde.depuisJson(Json json) => MoratoireAccorde(
        id: json.entier('id') ?? 0,
        montant: json.nombre('montant') ?? 0,
        echeance: json.date('echeance'),
        statut: json.texte('statut'),
        statutLibelle: json.texte('statut_libelle'),
        actif: json.booleen('actif'),
      );
}

class DemandeMoratoire {
  const DemandeMoratoire({
    required this.id,
    this.reference = '',
    this.montant = 0,
    this.dateSouhaitee,
    this.statutLibelle = '',
    this.deposeeLe,
  });

  final int id;
  final String reference;
  final double montant;
  final DateTime? dateSouhaitee;
  final String statutLibelle;
  final DateTime? deposeeLe;

  factory DemandeMoratoire.depuisJson(Json json) => DemandeMoratoire(
        id: json.entier('id') ?? 0,
        reference: json.texte('reference'),
        montant: json.nombre('montant') ?? 0,
        dateSouhaitee: json.date('date_souhaitee'),
        statutLibelle: json.texte('statut_libelle'),
        deposeeLe: json.date('deposee_le'),
      );
}

/// Le relevé d'une année : résumé (statut, avancement, totaux) et détail.
class ReleveFinancier {
  const ReleveFinancier({
    required this.resume,
    this.exigible = 0,
    this.tranches = const [],
    this.paiements = const [],
    this.moratoires = const [],
    this.releveDisponible = false,
  });

  final SituationFinanciere resume;

  /// Ce qui est appelé à ce jour (tranches échues).
  final double exigible;
  final List<Tranche> tranches;
  final List<Paiement> paiements;
  final List<MoratoireAccorde> moratoires;

  /// Le relevé de compte PDF peut être demandé (`releve_url`).
  final bool releveDisponible;

  static ReleveFinancier? depuisJson(Json? json) => json == null
      ? null
      : ReleveFinancier(
          resume: SituationFinanciere.depuisJson(json)!,
          exigible: json.objet('totaux')?.nombre('exigible') ?? 0,
          tranches: json.liste('tranches', Tranche.depuisJson),
          paiements: json.liste('paiements', Paiement.depuisJson),
          moratoires: json.liste('moratoires', MoratoireAccorde.depuisJson),
          releveDisponible: json.texteOuNul('releve_url') != null,
        );
}

/// Réponse de `finances/?annee=`.
class Finances {
  const Finances({
    this.annee,
    this.anneesDisponibles = const [],
    this.releve,
    this.demandeEnAttente,
  });

  final AnneeAcademique? annee;
  final List<AnneeAcademique> anneesDisponibles;
  final ReleveFinancier? releve;
  final DemandeMoratoire? demandeEnAttente;

  factory Finances.depuisJson(Json json) {
    final demande = json.objet('demande_de_moratoire_en_attente');
    return Finances(
      annee: AnneeAcademique.depuisJson(json.objet('annee_selectionnee')),
      anneesDisponibles: json.liste(
          'annees_disponibles', (j) => AnneeAcademique.depuisJson(j)!),
      releve: ReleveFinancier.depuisJson(json.objet('situation')),
      demandeEnAttente:
          demande == null ? null : DemandeMoratoire.depuisJson(demande),
    );
  }
}
