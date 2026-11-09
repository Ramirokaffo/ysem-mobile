import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/models/navigation.dart';
import 'package:ysem/core/models/notifications.dart';
import 'package:ysem/core/network/temps_reel.dart';
import 'package:ysem/core/providers.dart';
import 'package:ysem/features/auth/application/session_controller.dart';
import 'package:ysem/features/commun/espace/coque_espace.dart';
import 'package:ysem/features/commun/espace/depot_espace.dart';
import 'package:ysem/features/commun/push/canal_push.dart';
import 'package:ysem/features/commun/push/push.dart';
import 'package:ysem/features/commun/temps_reel.dart';
import 'package:ysem/l10n/app_localizations.dart';

class Canal extends CanalInactif {
  Canal({this.initial});

  final MessagePush? initial;
  final messagesRecus = StreamController<MessagePush>.broadcast();
  final messagesOuverts = StreamController<MessagePush>.broadcast();

  @override
  Stream<MessagePush> get recus => messagesRecus.stream;

  @override
  Stream<MessagePush> get ouverts => messagesOuverts.stream;

  @override
  Future<MessagePush?> ouvertureInitiale() async => initial;
}

/// Un websocket sans réseau : le test y pousse ce que dirait le serveur.
class CanalFactice extends CanalTempsReel {
  CanalFactice(String chemin)
      : super(chemin: chemin, jeton: ({bool forcer = false}) async => null);

  final flux = StreamController<Map<String, dynamic>>.broadcast();
  var ouvertures = 0;

  @override
  Stream<Map<String, dynamic>> get evenements => flux.stream;

  @override
  void ouvrir() {
    ouvertures++;
    connecte.value = true;
  }

  @override
  void fermer() => connecte.value = false;

  @override
  void envoyer(Map<String, dynamic> action) {}
}

class Depot implements DepotEspace {
  final lues = <int>[];
  var relectures = 0;

  /// Ce que le serveur compte : le menu et le compteur le rendent.
  var nonLues = 0;

  @override
  Future<Navigation> navigation({bool complet = false}) async =>
      Navigation.depuisJson({
        'compteurs': {'notification_unread_count': nonLues},
      });

  @override
  Future<int> compteurNotifications() async {
    relectures++;
    return nonLues;
  }

  @override
  Future<void> marquerNotification(int id, {required bool lue}) async =>
      lues.add(id);

  @override
  Future<PageNotifications> notifications(
          {int page = 1, bool nonLuesSeulement = false}) =>
      throw UnimplementedError();

  @override
  Future<void> supprimerNotification(int id) async {}

  @override
  Future<void> toutMarquerLu() async {}
}

class SessionOuverte extends SessionController {
  @override
  Future<Session?> build() async => null;
}

const notes = MessagePush(
  titre: 'Résultats publiés',
  donnees: {'espace': 'etudiant', 'notification_id': '7', 'url': '/notes/'},
);
const sansSection = MessagePush(
  titre: 'Rappel',
  donnees: {'espace': 'etudiant', 'notification_id': '8', 'url': ''},
);
const autreEspace = MessagePush(
  titre: 'Fiche à signer',
  donnees: {'espace': 'enseignant', 'notification_id': '9', 'url': '/notes/'},
);

String? section(String adresse) => adresse == '/notes/' ? 'notes' : null;

void main() {
  late Depot depot;
  late Map<String, CanalFactice> sockets;

  Future<Canal> monter(WidgetTester tester, {MessagePush? initial}) async {
    final canal = Canal(initial: initial);
    depot = Depot();
    sockets = {};
    final routeur = GoRouter(
      initialLocation: '/accueil',
      routes: [
        GoRoute(
          path: '/etudiant/section/:code',
          builder: (_, etat) =>
              Scaffold(body: Text('section ${etat.pathParameters['code']}')),
        ),
        StatefulShellRoute.indexedStack(
          builder: (_, _, coque) => CoqueEspace(
            espace: Espace.etudiant,
            coque: coque,
            sectionDeLAdresse: section,
            ouvrirSection: (context, code) =>
                context.push('/etudiant/section/$code'),
          ),
          branches: [
            for (final nom in ['accueil', 'services', 'cloche', 'profil'])
              StatefulShellBranch(routes: [
                GoRoute(path: '/$nom', builder: (_, _) => Text('page $nom')),
              ]),
          ],
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        canalPushProvider.overrideWithValue(canal),
        sessionProvider.overrideWith(SessionOuverte.new),
        depotEspaceProvider.overrideWith((ref, espace) => depot),
        fabriqueCanalProvider.overrideWithValue(
            (espace, chemin) => sockets[chemin] = CanalFactice(chemin)),
      ],
      child: _Application(routeur: routeur),
    ));
    await tester.pumpAndSettle();
    return canal;
  }

  testWidgets('une notification touchée à froid ouvre sa section et se lit',
      (tester) async {
    await monter(tester, initial: notes);
    expect(find.text('section notes'), findsOneWidget);
    expect(depot.lues, [7]);
  });

  testWidgets('touchée depuis l\'arrière-plan aussi', (tester) async {
    final canal = await monter(tester);
    expect(find.text('page accueil'), findsOneWidget);

    canal.messagesOuverts.add(notes);
    await tester.pumpAndSettle();
    expect(find.text('section notes'), findsOneWidget);
    expect(depot.lues, [7]);
  });

  testWidgets('sans section, le centre de notifications s\'ouvre',
      (tester) async {
    final canal = await monter(tester);
    canal.messagesOuverts.add(sansSection);
    await tester.pumpAndSettle();
    expect(find.text('page cloche'), findsOneWidget);
    expect(depot.lues, [8]);
  });

  testWidgets('une notification de l\'autre espace reste sans effet',
      (tester) async {
    final canal = await monter(tester);
    canal.messagesOuverts.add(autreEspace);
    await tester.pumpAndSettle();
    expect(find.text('page accueil'), findsOneWidget);
    expect(depot.lues, isEmpty);
  });

  testWidgets('application ouverte, un bandeau propose de voir',
      (tester) async {
    final canal = await monter(tester);
    final avant = depot.relectures;

    canal.messagesRecus.add(notes);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Résultats publiés'), findsOneWidget);
    expect(depot.relectures, greaterThan(avant));
    expect(depot.lues, isEmpty, reason: 'rien n\'est lu avant le geste');

    await tester.tap(find.text('Voir'));
    await tester.pumpAndSettle();
    expect(find.text('section notes'), findsOneWidget);
    expect(depot.lues, [7]);
  });

  testWidgets('pas de bandeau sur la section même qu\'il désigne',
      (tester) async {
    final canal = await monter(tester);
    canal.messagesOuverts.add(notes);
    await tester.pumpAndSettle();
    expect(find.text('section notes'), findsOneWidget);

    canal.messagesRecus.add(notes);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Résultats publiés'), findsNothing);

    // Revenu à l'accueil, le même push se signale.
    tester.element(find.text('section notes')).pop();
    await tester.pumpAndSettle();
    canal.messagesRecus.add(notes);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Résultats publiés'), findsOneWidget);
  });

  group('websocket de la cloche', () {
    testWidgets("s'ouvre sur la route de l'espace", (tester) async {
      await monter(tester);
      expect(sockets.keys, ['ws/notifications/student/']);
      expect(sockets.values.single.ouvertures, 1);
    });

    testWidgets('le compteur et le bandeau suivent le socket', (tester) async {
      final push = await monter(tester);
      final socket = sockets['ws/notifications/student/']!;

      socket.flux.add({'type': 'connected', 'unread_count': 4});
      await tester.pump();
      await tester.pump();
      expect(find.text('4'), findsOneWidget);

      depot.nonLues = 5;
      socket.flux.add({
        'type': 'notification',
        'unread_count': 5,
        'notification': {'id': 7, 'title': 'Résultats publiés', 'url': '/notes/'},
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Résultats publiés'), findsOneWidget);

      // Le push de la même notification ne fait pas un second bandeau.
      ScaffoldMessenger.of(tester.element(find.text('page accueil')))
          .hideCurrentSnackBar();
      await tester.pumpAndSettle();
      expect(find.text('Résultats publiés'), findsNothing);
      push.messagesRecus.add(notes);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Résultats publiés'), findsNothing);

      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      expect(find.text('page cloche'), findsOneWidget);
    });

    testWidgets('socket connecté, pas de relecture périodique', (tester) async {
      await monter(tester);
      final avant = depot.relectures;
      await tester.pump(CoqueEspace.intervalle * 2);
      expect(depot.relectures, avant);

      sockets.values.single.connecte.value = false;
      await tester.pump(CoqueEspace.intervalle);
      expect(depot.relectures, greaterThan(avant));
    });

    testWidgets('en arrière-plan le socket se ferme, au retour il se rouvre',
        (tester) async {
      await monter(tester);
      final socket = sockets.values.single;
      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(socket.estConnecte, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(socket.estConnecte, isTrue);
      expect(socket.ouvertures, 2);
    });
  });
}

class _Application extends ConsumerWidget {
  const _Application({required this.routeur});

  final GoRouter routeur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pushProvider);
    return MaterialApp.router(
      routerConfig: routeur,
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}
