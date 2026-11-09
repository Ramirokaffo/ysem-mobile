import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../auth/espace.dart';
import '../config/env.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Clé de `RequestOptions.extra` : la route ne demande pas de jeton
/// (connexion, vérification du code, rafraîchissement).
const String extraPublic = 'ysem.public';
const String _extraReessaye = 'ysem.reessaye';

/// Client HTTP d'un espace (étudiant ou enseignant).
///
/// Toutes les routes sont relatives au préfixe de l'espace :
/// `client.get('tableau-de-bord/')`. Les erreurs sortent toujours en
/// [ApiException], jamais en `DioException`.
class ApiClient {
  ApiClient({
    required this.espace,
    required TokenStorage stockage,
    String? Function()? langueForcee,
    Future<void> Function()? surSessionPerdue,
    Dio? dio,
  })  : _stockage = stockage,
        dio = dio ?? Dio(_options(espace)) {
    _auth = _AuthInterceptor(
      espace: espace,
      stockage: stockage,
      dio: this.dio,
      surSessionPerdue: surSessionPerdue,
    );
    this.dio.interceptors.addAll([
      _LangueInterceptor(langueForcee),
      _auth,
      if (Env.apiLogs && kDebugMode)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          logPrint: (o) => debugPrint(o.toString()),
        ),
    ]);
  }

  final Espace espace;
  final Dio dio;
  final TokenStorage _stockage;
  late final _AuthInterceptor _auth;

  TokenStorage get stockage => _stockage;

  static BaseOptions _options(Espace espace) => BaseOptions(
        baseUrl: Env.apiBaseUrl + espace.prefixe,
        connectTimeout: Env.delaiConnexion,
        receiveTimeout: Env.delaiReception,
        headers: {HttpHeaders.acceptHeader: 'application/json'},
      );

  Future<T> _executer<T>(Future<Response<dynamic>> Function() appel) async {
    try {
      final reponse = await appel();
      return reponse.data as T;
    } on DioException catch (e) {
      throw ApiException.depuisDio(e);
    }
  }

  Future<T> get<T>(String chemin,
          {Map<String, dynamic>? query, bool public = false}) =>
      _executer(() => dio.get(chemin,
          queryParameters: query, options: _opts(public)));

  /// `donnees` : un `Map` (envoyé en JSON) ou un [FormData] (multipart, pour
  /// les envois avec pièce jointe : moratoire, permission, message…).
  ///
  /// `delai` remplace le délai de réception pour un traitement long, comme
  /// la lecture d'un document par l'assistant d'IA.
  Future<T> post<T>(String chemin,
          {Object? donnees,
          Map<String, dynamic>? query,
          bool public = false,
          Duration? delai}) =>
      _executer(() => dio.post(chemin,
          data: donnees,
          queryParameters: query,
          options: (_opts(public) ?? Options()).copyWith(receiveTimeout: delai)));

  Future<T> delete<T>(String chemin) =>
      _executer(() => dio.delete(chemin));

  /// Télécharge un document binaire (reçu, certificat, relevé, support…)
  /// dans le cache de l'application et rend le fichier enregistré.
  Future<File> telecharger(String chemin,
      {Map<String, dynamic>? query, String? nomParDefaut}) async {
    final dossier = await getTemporaryDirectory();
    try {
      final reponse = await dio.get<List<int>>(
        chemin,
        queryParameters: query,
        options: Options(responseType: ResponseType.bytes),
      );
      final nom = _nomDuFichier(reponse.headers) ??
          nomParDefaut ??
          'document-${DateTime.now().millisecondsSinceEpoch}';
      final fichier = File('${dossier.path}/$nom');
      return fichier.writeAsBytes(reponse.data ?? const []);
    } on DioException catch (e) {
      throw ApiException.depuisDio(_corpsDecode(e));
    }
  }

  /// Une erreur d'un téléchargement arrive en octets : le `{detail, code}`
  /// du serveur est décodé pour que son message soit lu, comme ailleurs.
  static DioException _corpsDecode(DioException e) {
    final reponse = e.response;
    final corps = reponse?.data;
    if (reponse == null || corps is! List<int>) return e;
    try {
      final json = jsonDecode(utf8.decode(corps));
      return e.copyWith(
        response: Response<dynamic>(
          requestOptions: reponse.requestOptions,
          statusCode: reponse.statusCode,
          headers: reponse.headers,
          data: json,
        ),
      );
    } catch (_) {
      return e;
    }
  }

  /// Jeton d'accès pour ouvrir un websocket (`CanalTempsReel`), ou `null`
  /// sans session.
  ///
  /// Un socket ne passe pas par l'intercepteur : un jeton qui expire dans la
  /// minute — ou que le serveur vient de refuser (`forcer`) — est d'abord
  /// renouvelé. Un renouvellement refusé perd la session, comme pour une
  /// requête ; sans réseau, le jeton courant est rendu tel quel.
  Future<String?> jetonAcces({bool forcer = false}) async {
    final jetons = await _stockage.lire(espace);
    if (jetons == null) return null;
    final maintenant = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final fin = jetons.accesExpireLe;
    final bientotExpire = fin != null && fin - 60 <= maintenant;
    if (forcer || bientotExpire) await _auth.renouveler();
    return (await _stockage.lire(espace))?.acces;
  }

  Options? _opts(bool public) =>
      public ? Options(extra: {extraPublic: true}) : null;

  static String? _nomDuFichier(Headers entetes) {
    final disposition = entetes.value('content-disposition');
    if (disposition == null) return null;
    final etoile = RegExp(r"filename\*=UTF-8''([^;]+)").firstMatch(disposition);
    if (etoile != null) return Uri.decodeComponent(etoile.group(1)!);
    final simple = RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
    return simple?.group(1);
  }
}

/// N'envoie `Accept-Language` que si une langue est forcée dans
/// l'application : sans lui, le serveur répond dans la langue que l'acteur a
/// choisie (partagée avec le portail web).
class _LangueInterceptor extends Interceptor {
  _LangueInterceptor(this._langue);

  final String? Function()? _langue;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final langue = _langue?.call();
    if (langue != null) {
      options.headers[HttpHeaders.acceptLanguageHeader] = langue;
    }
    handler.next(options);
  }
}

/// Porte le jeton d'accès et le renouvelle une seule fois quand plusieurs
/// requêtes échouent en même temps (les erreurs sont traitées en file).
class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor({
    required this.espace,
    required this.stockage,
    required this.dio,
    this.surSessionPerdue,
  }) : _dioNu = Dio(BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: dio.options.connectTimeout,
          receiveTimeout: dio.options.receiveTimeout,
          headers: {HttpHeaders.acceptHeader: 'application/json'},
        ));

  final Espace espace;
  final TokenStorage stockage;
  final Dio dio;
  final Future<void> Function()? surSessionPerdue;

  /// Client sans intercepteur, pour le rafraîchissement lui-même.
  final Dio _dioNu;

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[extraPublic] != true) {
      final jetons = await stockage.lire(espace);
      if (jetons != null) {
        options.headers[HttpHeaders.authorizationHeader] =
            'Bearer ${jetons.acces}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final requete = err.requestOptions;
    final eligible = err.response?.statusCode == 401 &&
        requete.extra[extraPublic] != true &&
        requete.extra[_extraReessaye] != true;
    if (!eligible) return handler.next(err);

    final corps = err.response?.data;
    final code = corps is Map ? corps['code']?.toString() : null;
    if (ApiException.codesSessionPerdue.contains(code)) {
      await _perdreSession();
      return handler.next(err);
    }

    final actuels = await stockage.lire(espace);
    if (actuels == null || actuels.rafraichissementExpire) {
      await _perdreSession();
      return handler.next(err);
    }

    try {
      // Une requête précédente de la file a déjà renouvelé le jeton : on
      // rejoue simplement avec le jeton courant.
      final envoye = requete.headers[HttpHeaders.authorizationHeader];
      var jetons = actuels;
      if (envoye == 'Bearer ${actuels.acces}') {
        jetons = await _rafraichir(actuels);
      }
      requete.headers[HttpHeaders.authorizationHeader] =
          'Bearer ${jetons.acces}';
      requete.extra[_extraReessaye] = true;
      handler.resolve(await dio.fetch(requete));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) await _perdreSession();
      handler.next(e);
    }
  }

  /// Renouvelle le jeton d'accès hors de toute requête (ouverture d'un
  /// websocket). Un refus du serveur perd la session ; une erreur réseau ne
  /// change rien.
  Future<void> renouveler() async {
    final actuels = await stockage.lire(espace);
    if (actuels == null) return;
    if (actuels.rafraichissementExpire) return _perdreSession();
    try {
      await _rafraichir(actuels);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) await _perdreSession();
    }
  }

  Future<Jetons> _rafraichir(Jetons actuels) async {
    final reponse = await _dioNu.post<Map<String, dynamic>>(
      'auth/rafraichir/',
      data: {'rafraichissement': actuels.rafraichissement},
    );
    final jetons = Jetons.depuisJson(
      Map<String, dynamic>.from(reponse.data!['jetons'] as Map),
      precedent: actuels,
    );
    await stockage.ecrire(espace, jetons);
    return jetons;
  }

  Future<void> _perdreSession() async {
    await stockage.effacer(espace);
    await surSessionPerdue?.call();
  }
}
