import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/models/notifications.dart';
import '../../../core/format/formats.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints.dart';
import '../../commun/espace/depot_espace.dart';
import '../domain/cours.dart';
import '../domain/modeles.dart';
import '../domain/planning.dart';

/// Lectures de l'espace enseignant : accueil, menu, dossier et centre de
/// notifications (`/api/v1/portail-enseignant/`).
class EnseignantRepository implements DepotEspace {
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
