import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/models/discussions.dart';
import '../../../core/models/examens.dart';
import '../../../core/models/messagerie.dart';
import '../../../core/models/notifications.dart';
import '../../../core/format/formats.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints.dart';
import '../../commun/espace/depot_espace.dart';
import '../../commun/fil/fil.dart';
import '../../commun/piece_jointe.dart';
import '../domain/cours.dart';
import '../domain/documents.dart';
import '../domain/epreuves.dart';
import '../domain/feuilles.dart';
import '../domain/modeles.dart';
import '../domain/planning.dart';
import '../domain/situation.dart';

/// Lectures de l'espace enseignant : accueil, menu, dossier et centre de
/// notifications (`/api/v1/portail-enseignant/`).
class EnseignantRepository implements DepotEspace, DepotDiscussions {
  EnseignantRepository(this._client);

  final ApiClient _client;

  Future<TableauDeBordEnseignant> tableauDeBord() async =>
      TableauDeBordEnseignant.depuisJson(await _client
          .get<Map<String, dynamic>>(RoutesEnseignant.tableauDeBord));

  /// `complet` ajoute les pastilles qui relisent les écrans des documents,
  /// des épreuves et des notes : plus lent, demandé au rafraîchissement.
  @override
  Future<Navigation> navigation({bool complet = false}) async =>
      Navigation.depuisJson(await _client.get<Map<String, dynamic>>(
        RoutesEnseignant.navigation,
        query: complet ? {'complet': '1'} : null,
      ));

  /// Le dossier (réservé aux recrutés : 403 `reserve_aux_recrutes` sinon).
  Future<DossierEnseignant> dossier() async => DossierEnseignant.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEnseignant.profil));

  /// La photo du dossier, servie par une vue gardée par le jeton : elle ne
  /// se charge donc pas par une simple adresse. `null` sans photo.
  Future<Uint8List?> photo() async {
    try {
      final reponse = await _client.dio.get<List<int>>(
        RoutesEnseignant.profilPhoto,
        options: Options(responseType: ResponseType.bytes),
      );
      final octets = reponse.data;
      return octets == null ? null : Uint8List.fromList(octets);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.depuisDio(e);
    }
  }

  // --- Planning ----------------------------------------------------------

  /// `semaine` : n'importe quel jour de la semaine voulue (`AAAA-MM-JJ`),
  /// `null` pour la semaine courante.
  Future<EmploiDuTemps> emploiDuTemps({String? semaine}) async =>
      EmploiDuTemps.depuisJson(await _client.get<Map<String, dynamic>>(
        RoutesEnseignant.emploiDuTemps,
        query: semaine == null ? null : {'semaine': semaine},
      ));

  Future<Rattrapages> rattrapages() async => Rattrapages.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEnseignant.rattrapages));

  /// Propose une date ; elle n'engage rien avant l'arbitrage du service.
  /// Rend le message du serveur et la demande à jour.
  Future<(String, Rattrapage)> proposerRattrapage(
    int id, {
    required DateTime date,
    required String creneau,
    String? salle,
    String commentaire = '',
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      RoutesEnseignant.rattrapageProposer(id),
      donnees: {
        'date_prevue': Formats.iso(date),
        'time_slot': creneau,
        'classroom': salle ?? '',
        'commentaire': commentaire,
      },
    );
    return (
      _detail(json),
      Rattrapage.depuisJson(Map<String, dynamic>.from(json['rattrapage'] as Map)),
    );
  }

  Future<Disponibilites> disponibilites() async => Disponibilites.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEnseignant.disponibilites));

  /// Déclare une disponibilité, ou modifie celle que désigne [id]. Le
  /// formulaire du web valide ; rend son message.
  Future<String> enregistrerDisponibilite({
    int? id,
    required String creneau,
    required String statut,
    DateTime? debut,
    DateTime? fin,
    String notes = '',
  }) async =>
      _detail(await _client.post<Map<String, dynamic>>(
        id == null
            ? RoutesEnseignant.disponibilites
            : RoutesEnseignant.disponibilite(id),
        donnees: {
          'time_slot': creneau,
          'status': statut,
          'start_date': debut == null ? '' : Formats.iso(debut),
          'end_date': fin == null ? '' : Formats.iso(fin),
          'notes': notes,
        },
      ));

  Future<void> retirerDisponibilite(int id) =>
      _client.delete<dynamic>(RoutesEnseignant.disponibilite(id));

  Future<Examens> examens() async => Examens.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEnseignant.examens));

  /// Le document officiel, le même que celui du service.
  Future<File> planningExamensPdf(int id) => _client.telecharger(
      RoutesEnseignant.examenPdf(id),
      nomParDefaut: 'planning_examens_$id.pdf');

  // --- Mes cours ---------------------------------------------------------

  Future<MesClasses> classes() async => MesClasses.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEnseignant.classes));

  Future<DetailClasse> classe(String cle) async => DetailClasse.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEnseignant.classe(cle)));

  /// La liste de classe en classeur, le même que celui du portail web.
  Future<File> exporterClasse(String cle) => _client.telecharger(
      RoutesEnseignant.classeExporter(cle),
      nomParDefaut: 'classe_$cle.xlsx');

  Future<FichesASigner> fichesASigner() async => FichesASigner.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEnseignant.fichesASigner));

  /// Signe une fiche ; rend le message du serveur.
  Future<String> signerFiche(FicheDeSeance fiche) async => _detail(
      await _client.post<Map<String, dynamic>>(
          RoutesEnseignant.ficheSigner(fiche.type, fiche.id)));

  /// Renvoie une fiche au délégué, motif exigé.
  Future<String> renvoyerFiche(FicheDeSeance fiche, String motif) async =>
      _detail(await _client.post<Map<String, dynamic>>(
        RoutesEnseignant.ficheRenvoyer(fiche.type, fiche.id),
        donnees: {'motif': motif},
      ));

  /// Signe d'un geste toutes les fiches en attente ; rend le message et les
  /// refus éventuels (une fiche changée entre-temps).
  Future<(String, List<String>)> signerToutesLesFiches() async {
    final json = await _client
        .post<Map<String, dynamic>>(RoutesEnseignant.fichesSignerTout);
    final refus = json['refus'];
    return (
      _detail(json),
      refus is List ? [for (final r in refus) r.toString()] : const <String>[],
    );
  }

  Future<Enseignements> enseignements() async => Enseignements.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEnseignant.enseignements));

  // --- Discussions de classe --------------------------------------------

  @override
  Future<Discussions> discussions({String? recherche}) async =>
      Discussions.depuisJson(await _client.get<Map<String, dynamic>>(
        RoutesEnseignant.discussions,
        query: recherche == null || recherche.isEmpty ? null : {'q': recherche},
      ));

  /// Le fil d'une classe ; le lire avance le curseur de lecture.
  @override
  Future<FilMessages> messagesDiscussion(String cle, {int? avant}) async =>
      FilMessages.depuisDiscussion(await _client.get<Map<String, dynamic>>(
        RoutesEnseignant.discussionMessages(cle),
        query: avant == null ? null : {'avant': '$avant'},
      ));

  /// Un message de l'enseignant notifie toute la classe.
  @override
  Future<MessageFil> envoyerDiscussion(
    String cle, {
    required String corps,
    List<PieceAJoindre> pieces = const [],
    int? repondA,
  }) async {
    final donnees = FormData()
      ..fields.addAll([
        MapEntry('corps', corps),
        if (repondA != null) MapEntry('repond_a', '$repondA'),
      ]);
    for (final piece in pieces) {
      donnees.files.add(MapEntry('fichiers', piece.versMultipart()));
    }
    final json = await _client.post<Map<String, dynamic>>(
        RoutesEnseignant.discussionMessages(cle),
        donnees: donnees);
    return MessageFil.depuisJson(
        Map<String, dynamic>.from(json['message'] as Map? ?? const {}));
  }

  @override
  Future<Map<String, ResumeReaction>> reagirDiscussion(
      int id, String valeur) async {
    final json = await _client.post<Map<String, dynamic>>(
        RoutesEnseignant.discussionReaction(id),
        donnees: {'valeur': valeur});
    return lireReactions(json['reactions']);
  }

  @override
  Future<File> pieceDiscussion(PieceMessage piece) => _client.telecharger(
      RoutesEnseignant.discussionPiece(piece.id),
      query: {'telecharger': '1'},
      nomParDefaut: piece.nom.isEmpty ? 'piece_${piece.id}' : piece.nom);

  // --- Documents de cours et plan -----------------------------------------

  Future<DocumentsDeCours> documentsDeCours() async =>
      DocumentsDeCours.depuisJson(
          await _client.get<Map<String, dynamic>>(RoutesEnseignant.documents));

  /// Dépose des pièces, qui **s'ajoutent**. Les champs laissés vides gardent
  /// leur valeur : un dépôt n'efface ni le commentaire ni le projet.
  Future<ResultatDepot> deposerDocument(
    int depot, {
    List<PieceAJoindre> pieces = const [],
    String? commentaire,
    bool? projetPrevu,
    String? projetDescription,
    PieceAJoindre? projetFichier,
  }) async {
    final donnees = FormData.fromMap({
      'commentaire': ?commentaire,
      if (projetPrevu != null) 'projet_fin_cours': projetPrevu ? 'true' : 'false',
      'projet_fin_cours_description': ?projetDescription,
      'projet_fin_cours_fichier': ?projetFichier?.versMultipart(),
    });
    donnees.files.addAll([
      for (final piece in pieces) MapEntry('fichiers', piece.versMultipart()),
    ]);
    return ResultatDepot.depuisJson(await _client.post<Map<String, dynamic>>(
        RoutesEnseignant.documentDeposer(depot),
        donnees: donnees));
  }

  Future<String> retirerPieceDocument(int piece) async =>
      _detail(await _client.delete<Map<String, dynamic>>(
          RoutesEnseignant.documentPiece(piece)));

  Future<File> telechargerPieceDocument(PieceDeDepot piece) => _client.telecharger(
      RoutesEnseignant.documentPiece(piece.id),
      nomParDefaut: piece.nom);

  Future<PlanEnLigne> planDeCours(int id) async => PlanEnLigne.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEnseignant.plan(id)));

  Future<ResultatPlan> enregistrerPlan(int id, Map<String, dynamic> corps) async =>
      ResultatPlan.depuisJson(await _client.post<Map<String, dynamic>>(
          RoutesEnseignant.plan(id),
          donnees: corps));

  /// Confie un document à l'assistant : une pièce déposée ou un fichier. Rend
  /// le message et la proposition, que rien n'a écrite dans le plan. La lecture
  /// prend souvent une minute, d'où le délai propre.
  Future<(String, Map<String, dynamic>)> importerPlan(
    int id, {
    int? document,
    PieceAJoindre? fichier,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      RoutesEnseignant.planImporter(id),
      donnees: FormData.fromMap({
        'document': ?document,
        'fichier': ?fichier?.versMultipart(),
      }),
      delai: const Duration(minutes: 3),
    );
    return (
      _detail(json),
      Map<String, dynamic>.from(json['proposition'] as Map? ?? const {}),
    );
  }

  // --- Épreuves d'examen --------------------------------------------------

  Future<MesEpreuves> mesEpreuves() async => MesEpreuves.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEnseignant.epreuves));

  /// Dépose les pièces d'un sujet, qui **s'ajoutent**. Le serveur exige que
  /// l'envoi laisse le sujet entier (corrigé, seconde langue) : tout part d'un
  /// seul geste.
  Future<String> deposerSujet(
    int sujet, {
    List<PieceAJoindre> fichiersSujet = const [],
    List<PieceAJoindre> fichiersSujetEn = const [],
    List<PieceAJoindre> fichiersCorrige = const [],
    required String intitule,
    required String dureeMinutes,
    required String commentaire,
  }) async {
    final donnees = FormData.fromMap({
      'intitule': intitule,
      'duree_minutes': dureeMinutes,
      'commentaire': commentaire,
    });
    donnees.files.addAll([
      for (final p in fichiersSujet)
        MapEntry('fichiers_sujet', p.versMultipart()),
      for (final p in fichiersSujetEn)
        MapEntry('fichiers_sujet_en', p.versMultipart()),
      for (final p in fichiersCorrige)
        MapEntry('fichiers_corrige', p.versMultipart()),
    ]);
    return _detail(await _client.post<Map<String, dynamic>>(
        RoutesEnseignant.epreuveDeposer(sujet),
        donnees: donnees));
  }

  Future<String> retirerPieceEpreuve(int piece) async =>
      _detail(await _client.delete<Map<String, dynamic>>(
          RoutesEnseignant.epreuvePiece(piece)));

  Future<File> telechargerPieceEpreuve(PieceDeDepot piece) => _client.telecharger(
      RoutesEnseignant.epreuvePiece(piece.id),
      nomParDefaut: piece.nom);

  Future<File> telechargerModeleEpreuve(int depot, int numero, String langue) =>
      _client.telecharger(RoutesEnseignant.epreuveModele(depot, numero, langue));

  Future<File> telechargerModelesEpreuves() =>
      _client.telecharger(RoutesEnseignant.epreuvesModeles);

  // --- Feuilles de notes -------------------------------------------------

  Future<FeuillesDeNotes> feuillesDeNotes() async => FeuillesDeNotes.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEnseignant.feuilles));

  Future<DetailFeuille> feuille(int id) async => DetailFeuille.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEnseignant.feuille(id)));

  /// Déclare un contrôle continu ; rend le message et le contrôle créé, dont
  /// les notes sont à saisir.
  Future<(String, ControleDeFeuille)> creerControle(
    int feuille, {
    required String type,
    required DateTime date,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      RoutesEnseignant.feuille(feuille),
      donnees: {
        'action': 'controle_creer',
        'type_controle': type,
        'date': Formats.iso(date),
      },
    );
    return (
      _detail(json),
      ControleDeFeuille.depuisJson(
          Map<String, dynamic>.from(json['controle'] as Map? ?? const {})),
    );
  }

  /// Rend le contrôle continu au service ; refusé tant qu'une note manque.
  Future<String> rendreControleContinu(int feuille) async =>
      _detail(await _client.post<Map<String, dynamic>>(
        RoutesEnseignant.feuille(feuille),
        donnees: {'action': 'rendre_cc'},
      ));

  /// Enregistre des notes par code sans rendre l'épreuve. Rend le message et
  /// la grille à jour.
  Future<(String, List<LigneNote>)> enregistrerCopies(
    int feuille,
    String epreuve,
    List<NoteAEnvoyer> notes,
  ) async {
    final json = await _client.post<Map<String, dynamic>>(
      RoutesEnseignant.feuille(feuille),
      donnees: {
        'action': 'enregistrer',
        'epreuve': epreuve,
        'notes': [for (final n in notes) n.versJson()],
      },
    );
    return (
      _detail(json),
      [
        for (final c in (json['copies'] as List? ?? const []))
          LigneNote.depuisCopie(Map<String, dynamic>.from(c as Map)),
      ],
    );
  }

  /// Enregistre puis rend l'épreuve au service, qui seul pourra la renvoyer.
  Future<String> rendreEpreuve(
    int feuille,
    String epreuve,
    List<NoteAEnvoyer> notes,
  ) async =>
      _detail(await _client.post<Map<String, dynamic>>(
        RoutesEnseignant.feuille(feuille),
        donnees: {
          'action': 'rendre',
          'epreuve': epreuve,
          'notes': [for (final n in notes) n.versJson()],
        },
      ));

  Future<DetailControle> controle(int feuille, int controle) async =>
      DetailControle.depuisJson(await _client.get<Map<String, dynamic>>(
          RoutesEnseignant.controle(feuille, controle)));

  Future<(String, List<LigneNote>)> enregistrerNotesControle(
    int feuille,
    int controle,
    List<NoteAEnvoyer> notes,
  ) async {
    final json = await _client.post<Map<String, dynamic>>(
      RoutesEnseignant.controle(feuille, controle),
      donnees: {
        'notes': [for (final n in notes) n.versJson()],
      },
    );
    return (
      _detail(json),
      [
        for (final n in (json['notes'] as List? ?? const []))
          LigneNote.depuisControle(Map<String, dynamic>.from(n as Map)),
      ],
    );
  }

  Future<void> supprimerControle(int feuille, int controle) =>
      _client.delete<dynamic>(RoutesEnseignant.controle(feuille, controle));

  // --- Ma situation -------------------------------------------------------

  Future<Ponctualite> ponctualite() async => Ponctualite.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEnseignant.ponctualite));

  Future<Vacations> vacations() async => Vacations.depuisJson(
      await _client.get<Map<String, dynamic>>(RoutesEnseignant.vacations));

  /// Transmet une fiche d'émargement au service ; rend son message.
  Future<String> transmettreFiche(int id) async => _detail(await _client
      .post<Map<String, dynamic>>(RoutesEnseignant.ficheTransmettre(id)));

  static String _detail(Map<String, dynamic>? json) =>
      json?['detail']?.toString() ?? '';

  // --- Centre de notifications ----------------------------------------

  @override
  Future<PageNotifications> notifications(
          {int page = 1, bool nonLuesSeulement = false}) async =>
      PageNotifications.depuisJson(await _client.get<Map<String, dynamic>>(
        RoutesEnseignant.notifications,
        query: {
          'page': '$page',
          if (nonLuesSeulement) 'statut': 'non-lues',
        },
      ));

  @override
  Future<int> compteurNotifications() async {
    final json = await _client
        .get<Map<String, dynamic>>(RoutesEnseignant.notificationsCompteur);
    final valeur = json['non_lues'];
    return valeur is int ? valeur : int.tryParse('$valeur') ?? 0;
  }

  @override
  Future<void> marquerNotification(int id, {required bool lue}) =>
      _client.post<dynamic>(RoutesEnseignant.notification(id),
          donnees: {'lue': lue});

  @override
  Future<void> supprimerNotification(int id) =>
      _client.delete<dynamic>(RoutesEnseignant.notification(id));

  @override
  Future<void> toutMarquerLu() =>
      _client.post<dynamic>(RoutesEnseignant.notificationsToutLu);
}
