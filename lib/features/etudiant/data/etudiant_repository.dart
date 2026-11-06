import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/format/formats.dart';
import '../../../core/models/json.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../commun/espace/depot_espace.dart';
import '../../commun/fil/fil.dart';
import '../../commun/piece_jointe.dart';
import '../../commun/position.dart';
import '../domain/archives.dart';
import '../domain/association.dart';
import '../domain/delegation.dart';
import '../domain/bibliotheque.dart';
import '../domain/promotion.dart';
import '../domain/discipline.dart';
import '../domain/discussions.dart';
import '../domain/documents.dart';
import '../domain/examens.dart';
import '../domain/finances.dart';
import '../domain/mobile_money.dart';
import '../domain/messagerie.dart';
import '../domain/modeles.dart';
import '../domain/moratoires.dart';
import '../domain/notes.dart';
import '../domain/notifications.dart';
import '../domain/permissions.dart';
import '../domain/reinscription.dart';
import '../domain/scolarite.dart';
import '../domain/suggestions.dart';
import '../domain/supports.dart';

/// Lectures de l'espace étudiant : accueil, menu, profil, sections et
/// centre de notifications.
class EtudiantRepository implements DepotEspace, DepotDiscussions {
  EtudiantRepository(this._client);

  final ApiClient _client;

  Future<TableauDeBord> tableauDeBord() async => TableauDeBord.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEtudiant.tableauDeBord));

  /// `complet` ajoute les pastilles qui supposent de déplier l'agenda
  /// (discipline, notes, évaluations) : plus lent, demandé au rafraîchissement.
  @override
  Future<Navigation> navigation({bool complet = false}) async =>
      Navigation.depuisJson(await _client.get<Map<String, dynamic>>(
        RoutesEtudiant.navigation,
        query: complet ? {'complet': '1'} : null,
      ));

  Future<Profil> profil() async => Profil.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEtudiant.profil));

  // --- Sections --------------------------------------------------------

  /// `semaine` : n'importe quel jour de la semaine voulue (`AAAA-MM-JJ`),
  /// `null` pour la semaine courante.
  Future<Scolarite> scolarite({String? semaine}) async =>
      Scolarite.depuisJson(await _client.get<Map<String, dynamic>>(
        RoutesEtudiant.scolarite,
        query: semaine == null ? null : {'semaine': semaine},
      ));

  Future<Notes> notes() async => Notes.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEtudiant.notes));

  /// `annee` : identifiant d'une année académique, `null` pour l'année active.
  Future<Finances> finances({int? annee}) async =>
      Finances.depuisJson(await _client.get<Map<String, dynamic>>(
        RoutesEtudiant.finances,
        query: annee == null ? null : {'annee': '$annee'},
      ));

  Future<Examens> examens() async => Examens.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEtudiant.examens));

  Future<Supports> supports() async => Supports.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEtudiant.supports));

  /// Le dossier entier : quelques documents par année, jamais des centaines.
  Future<Documents> documents() async =>
      Documents.depuisJson(await _client.get<Map<String, dynamic>>(
        RoutesEtudiant.documents,
        query: {'taille_page': '100'},
      ));

  Future<DossierDiscipline> discipline() async => DossierDiscipline.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEtudiant.discipline));

  // --- Demandes : moratoires et permissions ----------------------------

  Future<Moratoires> moratoires() async => Moratoires.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEtudiant.moratoires));

  /// Dépose une demande pour l'année active, avec les champs du formulaire
  /// du portail (`amount`, `requested_due_date`, `reason`, `attachment`).
  /// Rend le message du serveur et l'état relu.
  Future<(String, Moratoires)> deposerMoratoire({
    required String montant,
    required DateTime dateSouhaitee,
    required String motif,
    PieceAJoindre? piece,
  }) async {
    final donnees = FormData.fromMap({
      'amount': montant,
      'requested_due_date': Formats.iso(dateSouhaitee),
      'reason': motif,
      if (piece != null) 'attachment': piece.versMultipart(),
    });
    final json = await _client.post<Map<String, dynamic>>(
        RoutesEtudiant.moratoires,
        donnees: donnees);
    return (json['detail']?.toString() ?? '', Moratoires.depuisJson(json));
  }

  Future<String> retirerMoratoire(int id) async => _detail(await _client
      .post<Map<String, dynamic>>(RoutesEtudiant.moratoireRetirer(id)));

  /// `semaine` : n'importe quel jour de la semaine voulue, `null` pour la
  /// semaine courante.
  Future<Permissions> permissions({String? semaine}) async =>
      Permissions.depuisJson(await _client.get<Map<String, dynamic>>(
        RoutesEtudiant.permissions,
        query: semaine == null ? null : {'semaine': semaine},
      ));

  /// Dépose une demande sur des séances de **la semaine consultée** : le
  /// serveur ne reconnaît que les jetons de cette semaine-là, d'où `semaine`
  /// reposté en paramètre.
  Future<String> deposerPermission({
    required String? semaine,
    required String type,
    required List<String> seances,
    required String explication,
    String? motif,
    String? heureArrivee,
    PieceAJoindre? justificatif,
  }) async {
    final donnees = FormData()
      ..fields.addAll([
        MapEntry('type_demande', type),
        for (final jeton in seances) MapEntry('seances', jeton),
        MapEntry('motif_libre', explication),
        if (motif != null && motif.isNotEmpty) MapEntry('motif', motif),
        if (heureArrivee != null) MapEntry('heure_arrivee_prevue', heureArrivee),
      ]);
    if (justificatif != null) {
      donnees.files
          .add(MapEntry('justificatif', justificatif.versMultipart()));
    }
    return _detail(await _client.post<Map<String, dynamic>>(
      RoutesEtudiant.permissions,
      donnees: donnees,
      query: semaine == null ? null : {'semaine': semaine},
    ));
  }

  Future<String> retirerPermission(int id) async => _detail(await _client
      .post<Map<String, dynamic>>(RoutesEtudiant.permissionRetirer(id)));

  // --- Réinscription et versements déclarés ------------------------------

  Future<Reinscription> reinscription() async => Reinscription.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEtudiant.reinscription));

  /// Demande (ou corrige) la réinscription de l'année active. Rend le message
  /// du serveur et l'état relu.
  Future<(String, Reinscription)> demanderReinscription(
      {required int niveau, int? specialite}) async {
    final json = await _client.post<Map<String, dynamic>>(
      RoutesEtudiant.reinscription,
      donnees: {'level': '$niveau', 'speciality': specialite == null ? '' : '$specialite'},
    );
    return (_detail(json), Reinscription.depuisJson(json));
  }

  Future<Versements> versements() async => Versements.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEtudiant.declarations));

  /// Déclare un versement bancaire, avec le reçu de la banque. `tranche`
  /// vide : le versement se répartit sur les tranches dans leur ordre.
  Future<(String, Versements)> declarerVersement({
    required int compte,
    required String montant,
    required DateTime dateOperation,
    required String referenceOperation,
    required PieceAJoindre recu,
    int? tranche,
    String commentaire = '',
  }) async {
    final donnees = FormData()
      ..fields.addAll([
        MapEntry('compte', '$compte'),
        MapEntry('montant', montant),
        MapEntry('date_operation', Formats.iso(dateOperation)),
        MapEntry('reference_operation', referenceOperation),
        MapEntry('installment', tranche == null ? '' : '$tranche'),
        MapEntry('commentaire', commentaire),
      ])
      ..files.add(MapEntry('piece', recu.versMultipart()));
    final json = await _client.post<Map<String, dynamic>>(
        RoutesEtudiant.declarations,
        donnees: donnees);
    return (_detail(json), Versements.depuisJson(json));
  }

  Future<String> retirerDeclaration(int id) async => _detail(await _client
      .post<Map<String, dynamic>>(RoutesEtudiant.declarationRetirer(id)));

  /// Le reçu de la banque déposé avec la déclaration.
  Future<File> recuBanque(int id) => _client.telecharger(
      RoutesEtudiant.declarationRecuBanque(id),
      nomParDefaut: 'recu_banque_$id');

  // --- Mobile Money -------------------------------------------------------

  /// État et transactions de l'année. `montant` ajoute l'aperçu des frais :
  /// c'est le serveur qui les calcule.
  Future<MobileMoney> mobileMoney({int? montant}) async =>
      MobileMoney.depuisJson(await _client.get<Map<String, dynamic>>(
        RoutesEtudiant.mobileMoney,
        query: montant == null ? null : {'montant': '$montant'},
      ));

  /// Ouvre la transaction et pousse l'invite sur le téléphone. Le serveur
  /// attend l'agrégateur (20 s au plus) : le délai ordinaire ne suffirait pas.
  Future<PaiementMobile> lancerPaiementMobile({
    required int montant,
    required String operateur,
    required String telephone,
    int? tranche,
  }) async =>
      PaiementMobile.depuisJson(await _client.post<Map<String, dynamic>>(
        RoutesEtudiant.mobileMoney,
        donnees: {
          'montant': montant,
          'operateur': operateur,
          'telephone': telephone,
          'installment': tranche == null ? '' : '$tranche',
        },
        delai: const Duration(seconds: 45),
      ));

  /// Relit une transaction ; le serveur interroge l'agrégateur si elle est
  /// ouverte (au plus toutes les 10 s).
  Future<PaiementMobile> paiementMobile(int id) async =>
      PaiementMobile.depuisJson(await _client
          .get<Map<String, dynamic>>(RoutesEtudiant.paiementMobile(id)));

  Future<PaiementMobile> annulerPaiementMobile(int id) async =>
      PaiementMobile.depuisJson(await _client
          .post<Map<String, dynamic>>(RoutesEtudiant.paiementMobileAnnuler(id)));

  /// Un document désigné par le chemin que rend l'API (`recu_url`…).
  Future<File> documentDuChemin(String chemin, {String? nom}) =>
      _client.telecharger(chemin, nomParDefaut: nom);

  // --- Messagerie avec la scolarité --------------------------------------

  /// Le fil (50 derniers messages) ; `avant` remonte le temps. Lire le fil
  /// accuse aussi réception des messages de la scolarité.
  Future<FilMessages> messages({int? avant}) async =>
      FilMessages.depuisJson(await _client.get<Map<String, dynamic>>(
        RoutesEtudiant.messages,
        query: avant == null ? null : {'avant': '$avant'},
      ));

  /// Envoie un message (le fil naît au premier). `repondA` cite un message
  /// du même fil ; les pièces partent sous le champ `fichiers`.
  Future<MessageFil> envoyerMessage({
    required String corps,
    List<PieceAJoindre> pieces = const [],
    int? repondA,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
        RoutesEtudiant.messages,
        donnees: _formulaireMessage(corps, pieces, repondA));
    return MessageFil.depuisJson(
        Map<String, dynamic>.from(json['message'] as Map? ?? const {}));
  }

  Future<void> marquerMessagesLus() =>
      _client.post<dynamic>(RoutesEtudiant.messagesLu);

  /// Le même geste pose, remplace ou retire l'avis : rend le résumé à jour.
  Future<Map<String, ResumeReaction>> reagirMessage(int id, String valeur) async {
    final json = await _client.post<Map<String, dynamic>>(
        RoutesEtudiant.messageReaction(id),
        donnees: {'valeur': valeur});
    return lireReactions(json['reactions']);
  }

  Future<File> pieceMessage(PieceMessage piece) => _client.telecharger(
      RoutesEtudiant.messagePiece(piece.id),
      query: {'telecharger': '1'},
      nomParDefaut: piece.nom.isEmpty ? 'piece_${piece.id}' : piece.nom);

  // --- Bibliothèque, archives, promotion ---------------------------------

  /// Un dossier (`null` : la racine), ou une recherche dans toute la
  /// bibliothèque (`recherche`, `categorie`).
  Future<VueBibliotheque> bibliotheque({
    int? dossier,
    String? recherche,
    int? categorie,
    int page = 1,
    int pageDossiers = 1,
  }) async =>
      VueBibliotheque.depuisJson(await _client.get<Map<String, dynamic>>(
        RoutesEtudiant.bibliotheque,
        query: {
          if (dossier != null) 'dossier': '$dossier',
          if (recherche != null && recherche.isNotEmpty) 'q': recherche,
          if (categorie != null) 'categorie': '$categorie',
          'page': '$page',
          'page_dossiers': '$pageDossiers',
        },
      ));

  /// Le fichier d'un document : chaque remise est comptée comme une
  /// consultation.
  Future<File> documentBibliotheque(DocumentBibliotheque document) =>
      _client.telecharger(
        RoutesEtudiant.bibliothequeDocument(document.id),
        query: {'telecharger': '1'},
        nomParDefaut: document.extension.isEmpty
            ? 'document_${document.id}'
            : 'document_${document.id}.${document.extension}',
      );

  Future<Archives> archives(
          {int? annee, int pageAnnales = 1, int pageSupports = 1}) async =>
      Archives.depuisJson(await _client.get<Map<String, dynamic>>(
        RoutesEtudiant.archives,
        query: {
          if (annee != null) 'annee': '$annee',
          'page_annales': '$pageAnnales',
          'page_supports': '$pageSupports',
        },
      ));

  Future<Promotion> promotion() async => Promotion.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEtudiant.promotion));

  // --- Association des étudiants -----------------------------------------

  Future<Association> association() async => Association.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEtudiant.association));

  /// Une liste du scrutin publié, programme compris.
  Future<ListeCandidate> listeCandidate(int id) async {
    final json = await _client
        .get<Map<String, dynamic>>(RoutesEtudiant.associationListe(id));
    return ListeCandidate.depuisJson(
        Map<String, dynamic>.from(json['liste'] as Map? ?? const {}));
  }

  /// Une liste d'un scrutin terminé, programme compris.
  Future<ListeCandidate> listeHistorique(int id) async {
    final json = await _client.get<Map<String, dynamic>>(
        RoutesEtudiant.associationHistoriqueListe(id));
    return ListeCandidate.depuisJson(
        Map<String, dynamic>.from(json['liste'] as Map? ?? const {}));
  }

  /// Le dépouillement seul, pour le suivre pendant le vote.
  Future<Resultats?> resultatsScrutin(int scrutin) async => Resultats.depuisJson(
      await _client.get<Map<String, dynamic>>(
          RoutesEtudiant.associationResultats(scrutin)));

  /// Dépose le bulletin. Rend le message du serveur et le dépouillement.
  Future<(String, Resultats?)> voter(int liste) async {
    final json = await _client.post<Map<String, dynamic>>(
        RoutesEtudiant.association,
        donnees: {'bureau': '$liste'});
    return (_detail(json), Resultats.depuisJson(json.objet('resultats')));
  }

  Future<List<ScrutinPasse>> historiqueAssociation() async =>
      (await _client.get<Map<String, dynamic>>(
              RoutesEtudiant.associationHistorique))
          .liste('historique', ScrutinPasse.depuisJson);

  // --- Délégation de classe ----------------------------------------------

  /// Les séances d'une journée (`null` : aujourd'hui) et l'état de leurs
  /// fenêtres. 404 (`non_delegue`) pour qui n'est pas délégué.
  Future<Delegation> delegation({String? jour}) async =>
      Delegation.depuisJson(await _client.get<Map<String, dynamic>>(
        RoutesEtudiant.delegation,
        query: jour == null ? null : {'jour': jour},
      ));

  static Map<String, dynamic> designationDe(SeanceDelegue seance) => {
        for (final MapEntry(:key, :value) in seance.designation.entries)
          if (value != null) key: '$value',
      };

  Future<FeuilleAppel> feuilleAppel(SeanceDelegue seance) async =>
      FeuilleAppel.depuisJson(await _client.get<Map<String, dynamic>>(
          RoutesEtudiant.delegationAppel,
          query: designationDe(seance)));

  /// Enregistre l'appel : seuls les absents sont cochés, le relevé qui en
  /// sort est pourtant un appel complet. `position` quand elle est exigée.
  Future<String> enregistrerAppel(
    SeanceDelegue seance, {
    required List<int> absents,
    PositionRelevee? position,
  }) async =>
      _detail(await _client.post<Map<String, dynamic>>(
        RoutesEtudiant.delegationAppel,
        donnees: {
          ...designationDe(seance),
          'absents': absents,
          ...?position?.champs,
        },
      ));

  Future<FeuilleCahier> feuilleCahier(SeanceDelegue seance) async =>
      FeuilleCahier.depuisJson(await _client.get<Map<String, dynamic>>(
          RoutesEtudiant.delegationCahier,
          query: designationDe(seance)));

  /// Tient le cahier : réponses d'activité et séances du plan faites. Le
  /// contenu prévu n'est jamais envoyé, le serveur le reprend du plan.
  Future<String> enregistrerCahier(
    SeanceDelegue seance, {
    required Map<String, String> activites,
    required List<int> seancesFaites,
    PositionRelevee? position,
  }) async =>
      _detail(await _client.post<Map<String, dynamic>>(
        RoutesEtudiant.delegationCahier,
        donnees: {
          ...designationDe(seance),
          ...activites,
          'blocs': [
            for (final id in seancesFaites) {'programme_fait': id},
          ],
          ...?position?.champs,
        },
      ));

  /// Tout ce qu'il faut pour tenir la semaine sans réseau.
  Future<Map<String, dynamic>> paquetHorsLigne() =>
      _client.get<Map<String, dynamic>>(RoutesEtudiant.delegationHorsLigne);

  /// Ce que le téléphone a recueilli : un résultat par saisie. `immediate` :
  /// le délégué est devant son écran et peut corriger un refus.
  Future<Map<String, dynamic>> synchroniserSaisies(
    List<Map<String, dynamic>> saisies, {
    required bool immediate,
  }) =>
      _client.post<Map<String, dynamic>>(
        RoutesEtudiant.delegationSynchroniser,
        donnees: {'saisies': saisies, 'immediate': immediate},
      );

  /// Le principal ouvre ou referme l'appel à un assistant.
  Future<String> autoriserAssistant(int id, {required bool peutFaireAppel}) async =>
      _detail(await _client.post<Map<String, dynamic>>(
        RoutesEtudiant.delegationAssistant(id),
        donnees: {'peut_faire_appel': peutFaireAppel},
      ));

  // --- Discussions de classe ------------------------------------------

  @override
  Future<Discussions> discussions({String? recherche}) async =>
      Discussions.depuisJson(await _client.get<Map<String, dynamic>>(
        RoutesEtudiant.discussions,
        query: recherche == null || recherche.isEmpty ? null : {'q': recherche},
      ));

  /// Le fil d'une classe ; le lire avance le curseur de lecture.
  @override
  Future<FilMessages> messagesDiscussion(String cle, {int? avant}) async =>
      FilMessages.depuisDiscussion(await _client.get<Map<String, dynamic>>(
        RoutesEtudiant.discussionMessages(cle),
        query: avant == null ? null : {'avant': '$avant'},
      ));

  @override
  Future<MessageFil> envoyerDiscussion(
    String cle, {
    required String corps,
    List<PieceAJoindre> pieces = const [],
    int? repondA,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
        RoutesEtudiant.discussionMessages(cle),
        donnees: _formulaireMessage(corps, pieces, repondA));
    return MessageFil.depuisJson(
        Map<String, dynamic>.from(json['message'] as Map? ?? const {}));
  }

  @override
  Future<Map<String, ResumeReaction>> reagirDiscussion(
      int id, String valeur) async {
    final json = await _client.post<Map<String, dynamic>>(
        RoutesEtudiant.discussionReaction(id),
        donnees: {'valeur': valeur});
    return lireReactions(json['reactions']);
  }

  @override
  Future<File> pieceDiscussion(PieceMessage piece) => _client.telecharger(
      RoutesEtudiant.discussionPiece(piece.id),
      query: {'telecharger': '1'},
      nomParDefaut: piece.nom.isEmpty ? 'piece_${piece.id}' : piece.nom);

  /// Corps, citation et pièces (`fichiers`) : même envoi pour les deux chats.
  static FormData _formulaireMessage(
      String corps, List<PieceAJoindre> pieces, int? repondA) {
    final donnees = FormData()
      ..fields.addAll([
        MapEntry('corps', corps),
        if (repondA != null) MapEntry('repond_a', '$repondA'),
      ]);
    for (final piece in pieces) {
      donnees.files.add(MapEntry('fichiers', piece.versMultipart()));
    }
    return donnees;
  }

  // --- Boîte à suggestions ---------------------------------------------

  Future<Suggestions> suggestions() async => Suggestions.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEtudiant.suggestions));

  Future<String> deposerSuggestion({
    required String texte,
    required String solution,
    List<PieceAJoindre> preuves = const [],
    String champPreuves = 'preuves',
  }) async {
    final donnees = FormData()
      ..fields.addAll([
        MapEntry('texte', texte),
        MapEntry('solution_proposee', solution),
      ]);
    for (final preuve in preuves) {
      donnees.files.add(MapEntry(champPreuves, preuve.versMultipart()));
    }
    return _detail(await _client.post<Map<String, dynamic>>(
        RoutesEtudiant.suggestions,
        donnees: donnees));
  }

  static String _detail(Map<String, dynamic>? json) =>
      json?['detail']?.toString() ?? '';

  // --- Centre de notifications ----------------------------------------

  @override
  Future<PageNotifications> notifications(
          {int page = 1, bool nonLuesSeulement = false}) async =>
      PageNotifications.depuisJson(await _client.get<Map<String, dynamic>>(
        RoutesEtudiant.notifications,
        query: {
          'page': '$page',
          if (nonLuesSeulement) 'statut': 'non-lues',
        },
      ));

  @override
  Future<int> compteurNotifications() async {
    final json = await _client
        .get<Map<String, dynamic>>(RoutesEtudiant.notificationsCompteur);
    final valeur = json['non_lues'];
    return valeur is int ? valeur : int.tryParse('$valeur') ?? 0;
  }

  @override
  Future<void> marquerNotification(int id, {required bool lue}) =>
      _client.post<dynamic>(RoutesEtudiant.notification(id),
          donnees: {'lue': lue});

  @override
  Future<void> supprimerNotification(int id) =>
      _client.delete<dynamic>(RoutesEtudiant.notification(id));

  @override
  Future<void> toutMarquerLu() =>
      _client.post<dynamic>(RoutesEtudiant.notificationsToutLu);

  // --- Documents -------------------------------------------------------

  /// Reçu PDF d'un paiement.
  Future<File> recuPaiement(int id) => _client.telecharger(
      RoutesEtudiant.recuPaiement(id),
      nomParDefaut: 'recu_paiement_$id.pdf');

  /// Certificat de scolarité : refusé (403, motif lisible) tant que la
  /// situation financière de l'année n'est pas régularisée.
  Future<File> certificatScolarite(int id) => _client.telecharger(
      RoutesEtudiant.certificatInscription(id),
      nomParDefaut: 'certificat_scolarite_$id.pdf');

  /// Planning de passage des épreuves, le document officiel du service.
  Future<File> planningExamensPdf(int id) => _client.telecharger(
      RoutesEtudiant.examenPdf(id),
      nomParDefaut: 'planning_examens_$id.pdf');

  /// Plan ou support de cours : une pièce sous son nom, un ZIP au-delà.
  /// Le téléchargement est constaté par le service.
  Future<File> support(int id) => _client.telecharger(
      RoutesEtudiant.supportTelecharger(id),
      nomParDefaut: 'support_$id');

  /// Relevé de compte PDF d'une année académique.
  Future<File> releveCompte(int annee) => _client.telecharger(
      RoutesEtudiant.releveCompte(annee),
      nomParDefaut: 'releve_compte_$annee.pdf');
}
