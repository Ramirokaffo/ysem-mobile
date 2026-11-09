import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/app/theme.dart';
import 'package:ysem/core/models/messagerie.dart';
import 'package:ysem/core/network/temps_reel.dart';
import 'package:ysem/features/commun/fil/fil.dart';
import 'package:ysem/features/commun/fil/fil_page.dart';
import 'package:ysem/features/commun/piece_jointe.dart';
import 'package:ysem/features/commun/temps_reel.dart';
import 'package:ysem/l10n/app_localizations.dart';

class _Canal extends CanalTempsReel {
  _Canal(String chemin)
      : super(chemin: chemin, jeton: ({bool forcer = false}) async => null);

  final flux = StreamController<Map<String, dynamic>>.broadcast();
  final envoyes = <Map<String, dynamic>>[];

  @override
  Stream<Map<String, dynamic>> get evenements => flux.stream;

  @override
  void ouvrir() => connecte.value = true;

  @override
  void fermer() => connecte.value = false;

  @override
  void envoyer(Map<String, dynamic> action) => envoyes.add(action);
}

/// Le guichet côté serveur : le test y dépose les messages.
class _Acces implements AccesFil {
  final messages = <MessageFil>[];
  var lectures = 0;

  @override
  Future<FilMessages> lire({int? avant}) async {
    lectures++;
    return FilMessages(
      conversation: 12,
      interlocuteur: 'Service de la scolarité',
      enLigne: false,
      messages: List.of(messages),
    );
  }

  @override
  Future<MessageFil> envoyer({
    required String corps,
    List<PieceAJoindre> pieces = const [],
    int? repondA,
  }) =>
      throw UnimplementedError();

  @override
  Future<Map<String, ResumeReaction>> reagir(int id, String valeur) =>
      throw UnimplementedError();

  @override
  Future<File> piece(PieceMessage piece) => throw UnimplementedError();
}

void main() {
  late _Acces acces;
  late Map<String, _Canal> sockets;

  Future<void> monter(WidgetTester tester) async {
    acces = _Acces()
      ..messages.add(MessageFil.depuisJson(const {
        'id': 1,
        'camp': 'student',
        'corps': 'Bonjour',
        'envoye_le': '2026-11-09T14:59:00+01:00',
      }));
    sockets = {};
    await tester.pumpWidget(ProviderScope(
      overrides: [
        accesFilProvider.overrideWith((ref, source) => acces),
        fabriqueCanalProvider.overrideWithValue(
            (espace, chemin) => sockets[chemin] = _Canal(chemin)),
      ],
      child: MaterialApp(
        theme: AppTheme.clair,
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const FilPage(source: SourceFil.guichet),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('le fil ouvre son websocket et le suit', (tester) async {
    await monter(tester);
    expect(sockets.keys, ['ws/messagerie/student/conversation/12/']);
    final socket = sockets.values.single;
    final lectures = acces.lectures;

    // Socket ouvert : pas de relecture périodique.
    await tester.pump(const Duration(seconds: 40));
    expect(acces.lectures, lectures);

    // Présence de la scolarité.
    socket.flux.add({'type': 'presence', 'en_ligne': true});
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Un agent est en ligne'), findsOneWidget);

    // « En train d'écrire… », éteint de lui-même faute d'arrêt.
    socket.flux.add({'type': 'frappe', 'camp': 'scolarite', 'actif': true});
    await tester.pump();
    await tester.pump();
    expect(find.text('La scolarité écrit…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
    expect(find.text('La scolarité écrit…'), findsNothing);

    // Un message annoncé fait relire le fil par l'API.
    acces.messages.add(MessageFil.depuisJson(const {
      'id': 2,
      'camp': 'scolarite',
      'auteur': 'Agent',
      'corps': 'Nous avons bien reçu votre dossier.',
      'envoye_le': '2026-11-09T15:06:00+01:00',
    }));
    socket.flux.add({'type': 'message', 'message': {'id': 2}});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(acces.lectures, lectures + 1);
    expect(find.text('Nous avons bien reçu votre dossier.'), findsOneWidget);
  });

  testWidgets('ma frappe part au socket, et son arrêt aussi', (tester) async {
    await monter(tester);
    final socket = sockets.values.single;
    await tester.enterText(find.byType(TextField).last, 'Bon');
    await tester.pump();
    expect(socket.envoyes, [
      {'action': 'frappe', 'actif': true},
    ]);
    await tester.pump(const Duration(seconds: 4));
    expect(socket.envoyes.last, {'action': 'frappe', 'actif': false});
  });

  testWidgets('socket tombé, le fil se relit périodiquement', (tester) async {
    await monter(tester);
    sockets.values.single.connecte.value = false;
    final lectures = acces.lectures;
    await tester.pump(const Duration(seconds: 16));
    await tester.pump();
    expect(acces.lectures, greaterThan(lectures));
  });
}
