import '../../../core/models/json.dart';
import 'modeles.dart';

/// Modèles de `moratoires/` : l'historique des demandes de moratoire et ce
/// qu'il reste demandable. Une demande n'a **aucun effet** sur la dette tant
/// que la scolarité ne l'a pas acceptée.

class DemandeMoratoireSuivie {
  const DemandeMoratoireSuivie({
    required this.id,
    this.reference = '',
    this.montant = 0,
    this.dateSouhaitee,
    this.motif = '',
    this.pieceJointe = false,
    this.statut = '',
    this.statutLibelle = '',
    this.enAttente = false,
    this.deposeeLe,
    this.decideeLe,
    this.commentaireDecision = '',
    this.annee = '',
  });

  final int id;
  final String reference;
  final double montant;
  final DateTime? dateSouhaitee;
  final String motif;
  final bool pieceJointe;

  /// `pending`, `approved`, `rejected`, `withdrawn`.
  final String statut;
  final String statutLibelle;

  /// Seule une demande encore en instruction se retire.
  final bool enAttente;
  final DateTime? deposeeLe;
  final DateTime? decideeLe;
  final String commentaireDecision;
  final String annee;

  factory DemandeMoratoireSuivie.depuisJson(Json json) =>
      DemandeMoratoireSuivie(
        id: json.entier('id') ?? 0,
        reference: json.texte('reference'),
        montant: json.nombre('montant') ?? 0,
        dateSouhaitee: json.date('date_souhaitee'),
        motif: json.texte('motif'),
        pieceJointe: json.booleen('piece_jointe'),
        statut: json.texte('statut'),
        statutLibelle: json.texte('statut_libelle'),
        enAttente: json.booleen('en_attente'),
        deposeeLe: json.date('deposee_le'),
        decideeLe: json.date('decidee_le'),
        commentaireDecision: json.texte('commentaire_decision'),
        annee: json.objet('annee')?.texte('nom') ?? '',
      );
}

class Moratoires {
  const Moratoires({
    this.annee,
    this.montantDemandable,
    this.depotPossible = false,
    this.demandes = const [],
  });

  final AnneeAcademique? annee;

  /// Reste à payer de l'année, moins ce que couvrent déjà les moratoires
  /// accordés : le plafond qu'applique le formulaire du serveur.
  final double? montantDemandable;

  /// Faux quand une demande est déjà en instruction, ou que rien ne reste dû.
  final bool depotPossible;
  final List<DemandeMoratoireSuivie> demandes;

  DemandeMoratoireSuivie? get enInstruction {
    for (final d in demandes) {
      if (d.enAttente) return d;
    }
    return null;
  }

  factory Moratoires.depuisJson(Json json) => Moratoires(
        annee: AnneeAcademique.depuisJson(json.objet('annee')),
        montantDemandable: json.nombre('montant_demandable'),
        depotPossible: json.booleen('depot_possible'),
        demandes: json.liste('demandes', DemandeMoratoireSuivie.depuisJson),
      );
}
