import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/network/api_client.dart';
import 'package:ysem/core/providers.dart';
import 'package:ysem/core/storage/token_storage.dart';
import 'package:ysem/features/auth/application/session_controller.dart';
import 'package:ysem/features/auth/data/auth_etudiant_repository.dart';
import 'package:ysem/features/commun/push/canal_push.dart';
import 'package:ysem/features/commun/push/push.dart';

class CanalFactice implements CanalPush {
  bool autorise = true;
  String fid = 'fid-1';
  int oublis = 0;
  int demandes = 0;
  MessagePush? initial;

  final inscriptions = StreamController<String>.broadcast();
  final messagesRecus = StreamController<MessagePush>.broadcast();
  final messagesOuverts = StreamController<MessagePush>.broadcast();

  @override
  Future<bool> demanderAutorisation() async {
    demandes++;
    return autorise;
  }

  /// Comme FCM : chaque inscription réussie rend l'identifiant.
  @override
  Future<void> inscrire() async => inscriptions.add(fid);

  @override
  Future<void> desinscrire() async => oublis++;

  @override
  Stream<String> get installations => inscriptions.stream;

  @override
  Stream<MessagePush> get recus => messagesRecus.stream;

  @override
  Stream<MessagePush> get ouverts => messagesOuverts.stream;

  @override
  Future<MessagePush?> ouvertureInitiale() async => initial;
}

class DepotFactice extends AuthEtudiantRepository {
  DepotFactice()
      : super(ApiClient(
          espace: Espace.etudiant,
          stockage: TokenStorage(),
          langueForcee: () => null,
          surSessionPerdue: () async {},
        ));

  final declares = <String>[];
  final retires = <String>[];
  bool enPanne = false;

  @override
  Future<void> declarerAppareil(String fid, String plateforme) async {
    if (enPanne) throw Exception('hors ligne');
    declares.add(fid);
  }

  @override
  Future<void> retirerAppareil(String fid) async {
    if (enPanne) throw Exception('hors ligne');
    retires.add(fid);
  }
}

class SessionFactice extends SessionController {
  SessionFactice(this.depart);

  final Session? depart;

  @override
  Future<Session?> build() async => depart;

  void poser(Session? session) => state = AsyncData(session);
}

const session = Session(
  espace: Espace.etudiant,
  acteur: {'matricule': 'ETU001'},
);

Future<void> laisserPasser() => Future<void>.delayed(Duration.zero);

void main() {
  late CanalFactice canal;
  late DepotFactice depot;

  ProviderContainer conteneur(Session? depart) {
    final c = ProviderContainer(overrides: [
      canalPushProvider.overrideWithValue(canal),
      authEtudiantRepositoryProvider.overrideWithValue(depot),
      sessionProvider.overrideWith(() => SessionFactice(depart)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<ProviderContainer> demarre(Session? depart) async {
    final c = conteneur(depart);
    c.read(pushProvider);
    await c.read(sessionProvider.future);
    await laisserPasser();
    return c;
  }

  SessionFactice controleur(ProviderContainer c) =>
      c.read(sessionProvider.notifier) as SessionFactice;

  setUp(() {
    canal = CanalFactice();
    depot = DepotFactice();
  });

  group('DestinationPush', () {
    test('lit ce que le serveur envoie', () {
      final d = DestinationPush.depuis({
        'espace': 'enseignant',
        'notification_id': '42',
        'url': '/portail-enseignant/mes-classes/',
      })!;
      expect(d.espace, Espace.enseignant);
      expect(d.notificationId, 42);
      expect(d.url, '/portail-enseignant/mes-classes/');
    });

    test('un espace inconnu ne désigne rien', () {
      expect(DestinationPush.depuis({'espace': 'parent'}), isNull);
      expect(DestinationPush.depuis({}), isNull);
    });

    test('un identifiant illisible garde la destination', () {
      final d = DestinationPush.depuis({'espace': 'etudiant'})!;
      expect(d.notificationId, isNull);
      expect(d.url, '');
    });
  });

  group('déclaration du téléphone', () {
    test('à l\'ouverture de la session, pas avant', () async {
      final c = await demarre(null);
      expect(canal.demandes, 0);
      expect(depot.declares, isEmpty);

      controleur(c).poser(session);
      await laisserPasser();
      expect(depot.declares, ['fid-1']);
    });

    test('une seule fois pour une même session', () async {
      final c = await demarre(session);
      controleur(c).mettreAJourActeur({'matricule': 'ETU001', 'lang': 'en'});
      await laisserPasser();
      expect(depot.declares, ['fid-1']);
    });

    test('à nouveau après un changement de mot de passe', () async {
      final c = await demarre(session);
      controleur(c).marquerMotDePasseChange({'matricule': 'ETU001'});
      await laisserPasser();
      expect(depot.declares, ['fid-1', 'fid-1']);
    });

    test('rien sans l\'autorisation d\'afficher', () async {
      canal.autorise = false;
      await demarre(session);
      expect(depot.declares, isEmpty);
    });

    test('un identifiant qui change est redéclaré', () async {
      await demarre(session);
      canal.inscriptions.add('fid-2');
      await laisserPasser();
      expect(depot.declares, ['fid-1', 'fid-2']);
    });

    test('un identifiant reçu sans session ne déclare personne', () async {
      await demarre(null);
      canal.inscriptions.add('fid-1');
      await laisserPasser();
      expect(depot.declares, isEmpty);
    });

    test('un échec est retenté au changement de session suivant', () async {
      depot.enPanne = true;
      final c = await demarre(session);
      expect(depot.declares, isEmpty);

      depot.enPanne = false;
      controleur(c).mettreAJourActeur({'matricule': 'ETU001'});
      await laisserPasser();
      expect(depot.declares, ['fid-1']);
    });
  });

  group('sortie', () {
    test('retire le téléphone puis le désinscrit', () async {
      final c = await demarre(session);
      await c.read(pushProvider).retirer(Espace.etudiant);
      expect(depot.retires, ['fid-1']);

      controleur(c).poser(null);
      await laisserPasser();
      expect(canal.oublis, 1);
    });

    test('hors ligne, la sortie aboutit quand même', () async {
      final c = await demarre(session);
      depot.enPanne = true;
      await c.read(pushProvider).retirer(Espace.etudiant);
      controleur(c).poser(null);
      await laisserPasser();
      expect(canal.oublis, 1);
    });

    test('un téléphone jamais déclaré n\'a rien à retirer', () async {
      canal.autorise = false;
      final c = await demarre(session);
      await c.read(pushProvider).retirer(Espace.etudiant);
      expect(depot.retires, isEmpty);
    });
  });

  group('ouverture par une notification', () {
    const message = MessagePush(donnees: {
      'espace': 'etudiant',
      'notification_id': '7',
      'url': '/portail-etudiant/mes-notes/',
    });

    test('une notification touchée à froid attend la coque', () async {
      canal.initial = message;
      final c = await demarre(null);

      final push = c.read(pushProvider);
      final destination = push.prendreDestination(Espace.etudiant);
      expect(destination?.notificationId, 7);
      expect(push.prendreDestination(Espace.etudiant), isNull,
          reason: 'une destination ne se suit qu\'une fois');
    });

    test('la coque est prévenue d\'une ouverture depuis l\'arrière-plan',
        () async {
      final c = await demarre(session);
      final push = c.read(pushProvider);
      var signaux = 0;
      push.ouvertures.listen((_) => signaux++);

      canal.messagesOuverts.add(message);
      await laisserPasser();
      expect(signaux, 1);
      expect(push.prendreDestination(Espace.etudiant)?.notificationId, 7);
    });

    test('la destination d\'un autre espace est abandonnée', () async {
      canal.initial = message;
      final c = await demarre(null);
      final push = c.read(pushProvider);
      expect(push.prendreDestination(Espace.enseignant), isNull);
      expect(push.prendreDestination(Espace.etudiant), isNull);
    });
  });
}
