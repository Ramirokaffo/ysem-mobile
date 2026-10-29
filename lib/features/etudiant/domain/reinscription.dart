import '../../../core/models/json.dart';
import 'finances.dart';
import 'modeles.dart';

/// Modèles de `reinscription/` et de `finances/declarations/` : la
/// réinscription de l'année active et les versements bancaires déclarés.
/// Une déclaration n'a **aucun effet financier** tant que le module Paiements
/// ne l'a pas validée sur le relevé de la banque.

/// Un niveau, une spécialité ou un programme, tels que les rend l'API.
class Reference {
  const Reference({required this.id, this.nom = '', this.nomEn = ''});

  final int id;
  final String nom;
  final String nomEn;

  String libelle(String langue) =>
      langue == 'en' && nomEn.isNotEmpty ? nomEn : nom;

  static Reference? depuisJson(Json? json) => json == null
      ? null
      : Reference(
          id: json.entier('id') ?? 0,
          nom: json.texte('nom'),
          nomEn: json.texte('nom_en'),
        );
}

class PremiereTranche {
  const PremiereTranche({
    this.configuree = false,
    this.montant = 0,
    this.paye = 0,
    this.reste = 0,
    this.couverte = false,
    this.moratoire = '',
    this.trancheId,
  });

  final bool configuree;
  final double montant;
  final double paye;
  final double reste;

  /// Soldée, ou couverte par un moratoire accordé.
  final bool couverte;
  final String moratoire;
  final int? trancheId;

  factory PremiereTranche.depuisJson(Json? json) => json == null
      ? const PremiereTranche()
      : PremiereTranche(
          configuree: json.booleen('configuree'),
          montant: json.nombre('montant') ?? 0,
          paye: json.nombre('paye') ?? 0,
          reste: json.nombre('reste') ?? 0,
          couverte: json.booleen('couverte'),
          moratoire: json.texte('moratoire'),
          trancheId: json.entier('tranche_id'),
        );
}

class Reinscription {
  const Reinscription({
    this.annee,
    this.ouverte = false,
    this.dejaInscrit = false,
    this.motif = '',
    this.demandePossible = false,
    this.enAttenteDePaiement = false,
    this.niveauSelonJury = false,
    this.decisionJury = '',
    this.programme,
    this.niveaux = const [],
    this.niveauParDefaut,
    this.specialites = const [],
    this.niveauInscrit,
    this.specialiteInscrite,
    this.demandeStatut = '',
    this.demandeStatutLibelle = '',
    this.demandeeLe,
    this.demandeur = '',
    this.premiereTranche = const PremiereTranche(),
    this.paiementEnLigneOuvert = false,
  });

  final AnneeAcademique? annee;
  final bool ouverte;
  final bool dejaInscrit;

  /// Pourquoi la demande n'est pas offerte (vide sinon).
  final String motif;

  /// Le formulaire est offert : première demande, ou modification tant que
  /// rien n'a été versé.
  final bool demandePossible;
  final bool enAttenteDePaiement;

  /// Le niveau est fixé par la décision du jury publiée.
  final bool niveauSelonJury;
  final String decisionJury;
  final Reference? programme;
  final List<Reference> niveaux;
  final Reference? niveauParDefaut;
  final List<Reference> specialites;
  final Reference? niveauInscrit;
  final Reference? specialiteInscrite;

  /// `en_attente` ou `finalisee`, vide sans demande.
  final String demandeStatut;
  final String demandeStatutLibelle;
  final DateTime? demandeeLe;
  final String demandeur;
  final PremiereTranche premiereTranche;
  final bool paiementEnLigneOuvert;

  bool get aUneDemande => demandeStatut.isNotEmpty;

  factory Reinscription.depuisJson(Json json) {
    final inscription = json.objet('inscription');
    final demande = json.objet('demande');
    return Reinscription(
      annee: AnneeAcademique.depuisJson(json.objet('annee')),
      ouverte: json.booleen('ouverte'),
      dejaInscrit: json.booleen('deja_inscrit'),
      motif: json.texte('motif'),
      demandePossible: json.booleen('demande_possible'),
      enAttenteDePaiement: json.booleen('en_attente_de_paiement'),
      niveauSelonJury: json.booleen('niveau_selon_jury'),
      decisionJury: json.texte('decision_jury'),
      programme: Reference.depuisJson(json.objet('programme')),
      niveaux: json.liste('niveaux_proposes', (j) => Reference.depuisJson(j)!),
      niveauParDefaut: Reference.depuisJson(json.objet('niveau_par_defaut')),
      specialites:
          json.liste('specialites_proposees', (j) => Reference.depuisJson(j)!),
      niveauInscrit: Reference.depuisJson(inscription?.objet('niveau')),
      specialiteInscrite: Reference.depuisJson(inscription?.objet('specialite')),
      demandeStatut: demande?.texte('statut') ?? '',
      demandeStatutLibelle: demande?.texte('statut_libelle') ?? '',
      demandeeLe: demande?.date('demandee_le'),
      demandeur: demande?.texte('demandeur') ?? '',
      premiereTranche: PremiereTranche.depuisJson(json.objet('premiere_tranche')),
      paiementEnLigneOuvert: json.booleen('paiement_en_ligne_ouvert'),
    );
  }
}

/// Un compte de l'établissement sur lequel verser.
class CompteBancaire {
  const CompteBancaire({
    required this.id,
    this.banque = '',
    this.intitule = '',
    this.numero = '',
    this.agence = '',
    this.consignes = '',
  });

  final int id;
  final String banque;
  final String intitule;
  final String numero;
  final String agence;
  final String consignes;

  factory CompteBancaire.depuisJson(Json json) => CompteBancaire(
        id: json.entier('id') ?? 0,
        banque: json.texte('banque'),
        intitule: json.texte('intitule'),
        numero: json.texte('numero'),
        agence: json.texte('agence'),
        consignes: json.texte('consignes'),
      );
}

class DeclarationVersement {
  const DeclarationVersement({
    required this.id,
    this.reference = '',
    this.compte = '',
    this.tranche = '',
    this.montant = 0,
    this.montantRetenu,
    this.dateOperation,
    this.referenceOperation = '',
    this.commentaire = '',
    this.declarant = '',
    this.espaceLibelle = '',
    this.statut = '',
    this.statutLibelle = '',
    this.motifRejet = '',
    this.observation = '',
    this.deposeeLe,
    this.decideeLe,
    this.recuUrl,
    this.retraitPossible = false,
  });

  final int id;
  final String reference;
  final String compte;
  final String tranche;
  final double montant;

  /// Montant constaté au relevé par le service, une fois validée.
  final double? montantRetenu;
  final DateTime? dateOperation;
  final String referenceOperation;
  final String commentaire;
  final String declarant;
  final String espaceLibelle;

  /// `en_attente`, `validee`, `rejetee`, `retiree`.
  final String statut;
  final String statutLibelle;
  final String motifRejet;
  final String observation;
  final DateTime? deposeeLe;
  final DateTime? decideeLe;

  /// Chemin du reçu de paiement, une fois la déclaration validée.
  final String? recuUrl;
  final bool retraitPossible;

  factory DeclarationVersement.depuisJson(Json json) => DeclarationVersement(
        id: json.entier('id') ?? 0,
        reference: json.texte('reference'),
        compte: json.texte('compte'),
        tranche: json.texte('tranche'),
        montant: json.nombre('montant') ?? 0,
        montantRetenu: json.nombre('montant_retenu'),
        dateOperation: json.date('date_operation'),
        referenceOperation: json.texte('reference_operation'),
        commentaire: json.texte('commentaire'),
        declarant: json.texte('declarant'),
        espaceLibelle: json.texte('espace_libelle'),
        statut: json.texte('statut'),
        statutLibelle: json.texte('statut_libelle'),
        motifRejet: json.texte('motif_rejet'),
        observation: json.texte('observation'),
        deposeeLe: json.date('deposee_le'),
        decideeLe: json.date('decidee_le'),
        recuUrl: json.texteOuNul('recu_url'),
        retraitPossible: json.booleen('retrait_possible'),
      );
}

class Versements {
  const Versements({
    this.annee,
    this.ouvert = false,
    this.motifFermeture = '',
    this.comptes = const [],
    this.montantDeclarable,
    this.montantEnVerification,
    this.tranchesOuvertes = const [],
    this.declarations = const [],
  });

  final AnneeAcademique? annee;
  final bool ouvert;
  final String motifFermeture;
  final List<CompteBancaire> comptes;

  /// Reste de l'année, moins ce qui est déjà en vérification : le plafond
  /// qu'applique le formulaire du serveur.
  final double? montantDeclarable;
  final double? montantEnVerification;
  final List<Tranche> tranchesOuvertes;
  final List<DeclarationVersement> declarations;

  factory Versements.depuisJson(Json json) => Versements(
        annee: AnneeAcademique.depuisJson(json.objet('annee')),
        ouvert: json.booleen('ouvert'),
        motifFermeture: json.texte('motif_fermeture'),
        comptes: json.liste('comptes', CompteBancaire.depuisJson),
        montantDeclarable: json.nombre('montant_declarable'),
        montantEnVerification: json.nombre('montant_en_verification'),
        tranchesOuvertes: json.liste('tranches_ouvertes', Tranche.depuisJson),
        declarations: json.liste('declarations', DeclarationVersement.depuisJson),
      );
}
