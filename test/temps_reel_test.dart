import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/network/temps_reel.dart';
import 'package:ysem/features/commun/temps_reel.dart';

/// Un serveur websocket local : il garde chaque poignée de main et ce qu'il
/// reçoit, et laisse le test parler ou raccrocher.
class Serveur {
  late final HttpServer _http;
  final poignees = <HttpHeaders>[];
  final chemins = <String>[];
  final recus = <Map<String, dynamic>>[];
  final sockets = <WebSocket>[];
  final _connexions = StreamController<WebSocket>.broadcast();

  /// Un jeton refusé : la poignée de main est rejetée (403), comme le fait
  /// Channels quand le consumer ferme avant d'accepter.
  String? jetonRefuse;

  String get base => 'http://127.0.0.1:${_http.port}';
  Stream<WebSocket> get connexions => _connexions.stream;

  Future<void> demarrer() async {
    _http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _http.listen((requete) async {
      poignees.add(requete.headers);
      chemins.add(requete.uri.path);
      final autorisation =
          requete.headers.value(HttpHeaders.authorizationHeader);
      if (jetonRefuse != null && autorisation == 'Bearer $jetonRefuse') {
        requete.response.statusCode = HttpStatus.forbidden;
        await requete.response.close();
        return;
      }
      final socket = await WebSocketTransformer.upgrade(requete);
      sockets.add(socket);
      _connexions.add(socket);
      socket.listen((brut) {
        recus.add(Map<String, dynamic>.from(jsonDecode(brut as String) as Map));
      });
    });
  }

  Future<void> arreter() async {
    for (final s in sockets) {
      await s.close();
    }
    await _http.close(force: true);
  }
}

Future<void> attendre(bool Function() condition,
    {Duration delai = const Duration(seconds: 5)}) async {
  final fin = DateTime.now().add(delai);
  while (!condition()) {
    if (DateTime.now().isAfter(fin)) fail('condition jamais remplie');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  late Serveur serveur;

  setUp(() async {
    serveur = Serveur();
    await serveur.demarrer();
  });

  tearDown(() => serveur.arreter());

  test("porte le jeton en en-tête et l'origine du serveur", () async {
    final canal = CanalTempsReel(
      chemin: 'ws/notifications/student/',
      jeton: ({bool forcer = false}) async => 'abc',
      baseUrl: serveur.base,
    )..ouvrir();
    await attendre(() => canal.estConnecte);

    expect(serveur.chemins.single, '/ws/notifications/student/');
    final entetes = serveur.poignees.single;
    expect(entetes.value(HttpHeaders.authorizationHeader), 'Bearer abc');
    expect(entetes.value('origin'), serveur.base);
    await canal.dispose();
  });

  test('rend les évènements, sauf les pong, et bat le cœur', () async {
    final canal = CanalTempsReel(
      chemin: 'ws/x/',
      jeton: ({bool forcer = false}) async => 'abc',
      baseUrl: serveur.base,
      battement: const Duration(milliseconds: 100),
    );
    final recus = <Map<String, dynamic>>[];
    canal.evenements.listen(recus.add);
    canal.ouvrir();
    final socket = await serveur.connexions.first;

    socket.add(jsonEncode({'type': 'pong'}));
    socket.add('pas du json');
    socket.add(jsonEncode({'type': 'count', 'unread_count': 3}));
    await attendre(() => recus.isNotEmpty);
    expect(recus.single, {'type': 'count', 'unread_count': 3});

    await attendre(() => serveur.recus.any((r) => r['action'] == 'ping'));
    canal.envoyer({'action': 'frappe', 'actif': true});
    await attendre(() => serveur.recus.any((r) => r['action'] == 'frappe'));
    await canal.dispose();
  });

  test('se reconnecte quand le serveur raccroche', () async {
    final canal = CanalTempsReel(
      chemin: 'ws/x/',
      jeton: ({bool forcer = false}) async => 'abc',
      baseUrl: serveur.base,
    )..ouvrir();
    final premier = await serveur.connexions.first;
    await attendre(() => canal.estConnecte);

    await premier.close(1011);
    await attendre(() => serveur.sockets.length == 2);
    await attendre(() => canal.estConnecte);
    await canal.dispose();
  });

  test('un porteur refusé (4001) se reconnecte avec un jeton neuf', () async {
    final demandes = <bool>[];
    final canal = CanalTempsReel(
      chemin: 'ws/x/',
      jeton: ({bool forcer = false}) async {
        demandes.add(forcer);
        return forcer ? 'neuf' : 'vieux';
      },
      baseUrl: serveur.base,
    )..ouvrir();
    final premier = await serveur.connexions.first;
    await premier.close(4001);

    await attendre(() => serveur.sockets.length == 2);
    expect(demandes, [false, true]);
    expect(serveur.poignees.last.value(HttpHeaders.authorizationHeader),
        'Bearer neuf');
    await canal.dispose();
  });

  test('une poignée de main refusée fait renouveler le jeton', () async {
    serveur.jetonRefuse = 'vieux';
    final demandes = <bool>[];
    final canal = CanalTempsReel(
      chemin: 'ws/x/',
      jeton: ({bool forcer = false}) async {
        demandes.add(forcer);
        return forcer ? 'neuf' : 'vieux';
      },
      baseUrl: serveur.base,
      delaiMax: const Duration(milliseconds: 200),
    )..ouvrir();

    await attendre(() => canal.estConnecte, delai: const Duration(seconds: 8));
    expect(demandes.last, isTrue);
    expect(serveur.poignees.last.value(HttpHeaders.authorizationHeader),
        'Bearer neuf');
    await canal.dispose();
  });

  test('fermé, il ne se rouvre pas ; sans jeton, il ne se connecte pas',
      () async {
    final canal = CanalTempsReel(
      chemin: 'ws/x/',
      jeton: ({bool forcer = false}) async => 'abc',
      baseUrl: serveur.base,
    )..ouvrir();
    await attendre(() => canal.estConnecte);
    canal.fermer();
    expect(canal.estConnecte, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(serveur.sockets, hasLength(1));
    await canal.dispose();

    final sansSession = CanalTempsReel(
      chemin: 'ws/x/',
      jeton: ({bool forcer = false}) async => null,
      baseUrl: serveur.base,
    )..ouvrir();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(serveur.sockets, hasLength(1));
    await sansSession.dispose();
  });

  test('adresse et délais', () {
    final canal = CanalTempsReel(
      chemin: 'ws/messagerie/student/conversation/4/',
      jeton: ({bool forcer = false}) async => null,
      baseUrl: 'https://test.ysem.education',
    );
    expect(canal.adresse.toString(),
        'wss://test.ysem.education/ws/messagerie/student/conversation/4/');
    const plafond = Duration(seconds: 60);
    expect(CanalTempsReel.delaiReprise(0, plafond).inMilliseconds,
        inInclusiveRange(1000, 1250));
    expect(CanalTempsReel.delaiReprise(20, plafond), plafond);
  });

  test('chemins des deux espaces', () {
    expect(CheminsTempsReel.notifications(Espace.etudiant),
        'ws/notifications/student/');
    expect(CheminsTempsReel.notifications(Espace.enseignant),
        'ws/notifications/lecturer/');
    expect(CheminsTempsReel.classe(Espace.enseignant, 9),
        'ws/chat-cours/lecturer/groupe/9/');
    expect(CheminsTempsReel.guichet(3),
        'ws/messagerie/student/conversation/3/');
    expect(CheminsTempsReel.scrutin(2), 'ws/association/scrutin/2/');
  });
}
