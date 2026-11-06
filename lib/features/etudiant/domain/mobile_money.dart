import '../../../core/models/agenda.dart';
import '../../../core/models/json.dart';
import 'finances.dart';

/// Modèles de `finances/mobile-money/`. À la différence d'une déclaration,
/// personne ne vérifie une transaction : la confirmation de l'opérateur vaut
/// encaissement, et le serveur fait seul avancer son état.

class OperateurMobile {
  const OperateurMobile({required this.code, this.libelle = ''});

  final String code;
  final String libelle;

  factory OperateurMobile.depuisJson(Json json) => OperateurMobile(
        code: json.texte('code'),
        libelle: json.texte('libelle'),
      );
}

/// Ce que coûte un règlement, calculé par le serveur.
class ApercuFrais {
  const ApercuFrais({this.montant = 0, this.frais = 0, this.montantDebite = 0});

  final double montant;
  final double frais;
  final double montantDebite;

  static ApercuFrais? depuisJson(Json? json) => json == null
      ? null
      : ApercuFrais(
          montant: json.nombre('montant') ?? 0,
          frais: json.nombre('frais') ?? 0,
          montantDebite: json.nombre('montant_debite') ?? 0,
        );
}

/// Une transaction : celle de l'étudiant, ou celle qu'un parent a lancée pour
/// lui (`lanceParUnParent`), qu'il lit sans pouvoir y renoncer.
class PaiementMobile {
  const PaiementMobile({
    required this.id,
    this.reference = '',
    this.tranche = '',
    this.operateur = '',
    this.operateurLibelle = '',
    this.telephone = '',
    this.montant = 0,
    this.frais = 0,
    this.montantDebite = 0,
    this.statut = '',
    this.statutLibelle = '',
    this.message = '',
    this.ouvert = false,
    this.annulable = false,
    this.test = false,
    this.ouvertLe,
    this.confirmeLe,
    this.recuUrl,
    this.lanceParUnParent = false,
    this.payeur = '',
  });

  final int id;
  final String reference;
  final String tranche;
  final String operateur;
  final String operateurLibelle;
  final String telephone;

  /// Ce qui est imputé à l'étudiant.
  final double montant;
  final double frais;

  /// Ce qui quitte le compte Mobile Money.
  final double montantDebite;
  final String statut;
  final String statutLibelle;

  /// Ce que le serveur dit de la transaction, déjà traduit.
  final String message;

  /// Sans dénouement : le montant reste réservé.
  final bool ouvert;
  final bool annulable;
  final bool test;
  final DateTime? ouvertLe;
  final DateTime? confirmeLe;

  /// Chemin du reçu, une fois le paiement confirmé.
  final String? recuUrl;
  final bool lanceParUnParent;
  final String payeur;

  bool get reussi => statut == 'reussi';

  factory PaiementMobile.depuisJson(Json json) => PaiementMobile(
        id: json.entier('id') ?? 0,
        reference: json.texte('reference'),
        tranche: json.texte('tranche'),
        operateur: json.texte('operateur'),
        operateurLibelle: json.texte('operateur_libelle'),
        telephone: json.texte('telephone'),
        montant: json.nombre('montant') ?? 0,
        frais: json.nombre('frais') ?? 0,
        montantDebite: json.nombre('montant_debite') ?? 0,
        statut: json.texte('statut'),
        statutLibelle: json.texte('statut_libelle'),
        message: json.texte('message'),
        ouvert: json.booleen('ouvert'),
        annulable: json.booleen('annulable'),
        test: json.booleen('test'),
        ouvertLe: json.date('ouvert_le'),
        confirmeLe: json.date('confirme_le'),
        recuUrl: json.texteOuNul('recu_url'),
        lanceParUnParent: json.booleen('lance_par_un_parent'),
        payeur: json.texte('payeur'),
      );
}

/// L'état du paiement pour l'année active.
class MobileMoney {
  const MobileMoney({
    this.ouvert = false,
    this.motif = '',
    this.annee,
    this.test = false,
    this.operateurs = const [],
    this.telephonePropose = '',
    this.montantPayable,
    this.tranches = const [],
    this.paiements = const [],
    this.apercu,
  });

  final bool ouvert;
  final String motif;
  final AnneeAcademique? annee;
  final bool test;
  final List<OperateurMobile> operateurs;
  final String telephonePropose;

  /// Reste de l'année, moins ce qui est en vérification ou en cours : le
  /// plafond qu'applique le formulaire du serveur.
  final double? montantPayable;
  final List<Tranche> tranches;
  final List<PaiementMobile> paiements;
  final ApercuFrais? apercu;

  /// La transaction qui attend son dénouement : une seule par étudiant.
  PaiementMobile? get enCours =>
      paiements.where((p) => p.ouvert).firstOrNull;

  bool get payable => ouvert && (montantPayable ?? 0) > 0;

  factory MobileMoney.depuisJson(Json json) => MobileMoney(
        ouvert: json.booleen('ouvert'),
        motif: json.texte('motif'),
        annee: AnneeAcademique.depuisJson(json.objet('annee')),
        test: json.booleen('test'),
        operateurs: json.liste('operateurs', OperateurMobile.depuisJson),
        telephonePropose: json.texte('telephone_propose'),
        montantPayable: json.nombre('montant_payable'),
        tranches: json.liste('tranches', Tranche.depuisJson),
        paiements: json.liste('paiements', PaiementMobile.depuisJson),
        apercu: ApercuFrais.depuisJson(json.objet('apercu')),
      );
}
