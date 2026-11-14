import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ysem/app/router.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/models/navigation.dart';
import 'package:ysem/core/models/notifications.dart';
import 'package:ysem/core/network/temps_reel.dart';
import 'package:ysem/core/providers.dart';
import 'package:ysem/features/auth/application/session_controller.dart';
import 'package:ysem/features/commun/espace/coque_espace.dart';
import 'package:ysem/features/commun/espace/depot_espace.dart';
import 'package:ysem/features/commun/liens/liens_entrants.dart';
import 'package:ysem/features/commun/push/push.dart';
import 'package:ysem/features/commun/temps_reel.dart';
import 'package:ysem/features/etudiant/presentation/sections.dart';
import 'package:ysem/l10n/app_localizations.dart';

const hote = 'si.ysem.education';

LienEntrant? lien(String chemin) =>
    lienEntrant(Uri.parse('https://$hote$chemin'), hote: hote);

void main() {
  group('garde du manifeste', () {
    final manifeste =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    test('les chemins déclarés sont exactement ceux que l\'application ouvre',
        () {
      final declares = RegExp(r'android:pathPrefix="([^"]+)"')
          .allMatches(manifeste)
          .map((m) => m.group(1)!)
          .toList();
      final attendus = [...cheminsEtudiant, ...cheminsEnseignant];
      expect(declares.toSet(), attendus.toSet());
      expect(declares, hasLength(declares.toSet().length),
          reason: 'un chemin déclaré deux fois');
      expect(attendus, hasLength(attendus.toSet().length));
    });

    test('vérifié, en https, sur l\'hôte calculé à la compilation', () {
      expect(manifeste, contains('android:autoVerify="true"'));
      expect(manifeste, contains('<data android:scheme="https"/>'));
      expect(manifeste, contains(r'<data android:host="${hoteLiens}"/>'));
      expect(manifeste, isNot(contains('android:scheme="http"')));
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('manifestPlaceholders["hoteLiens"] = hoteLiens'));
    });

    test('chaque chemin déclaré mène à une section de son espace', () {
      for (final chemin in cheminsEtudiant) {
        expect(lien(chemin)?.espace, Espace.etudiant, reason: chemin);
      }
      for (final chemin in cheminsEnseignant) {
        expect(lien(chemin)?.espace, Espace.enseignant, reason: chemin);
      }
    });
  });

  group('lecture d\'un lien', () {
    test('page du portail, avec ou sans barre finale', () {
      expect(lien('/portail-etudiant/mes-notes/'),
          const LienEntrant(
              espace: Espace.etudiant, chemin: '/portail-etudiant/mes-notes/'));
      // go_router retire la barre finale avant le redirect.
      expect(lien('/portail-etudiant/mes-notes')?.chemin,
          '/portail-etudiant/mes-notes/');
      expect(sectionDeLAdresse(lien('/portail-etudiant/mes-devoirs/12/')!.chemin),
          'devoirs?devoir=12');
      expect(lien('/enseignants/fiches-a-signer/')?.espace, Espace.enseignant);
      expect(lien('/chat-cours/enseignant/groupe/abc/')?.espace,
          Espace.enseignant);
    });

    test('jamais une page réservée au web ou au personnel', () {
      for (final chemin in [
        '/portail-etudiant/',
        '/portail-etudiant/connexion/',
        '/portail-etudiant/verification/jeton/',
        '/enseignants/connexion/',
        '/enseignants/verification/jeton/',
        '/enseignants/reinitialiser/jeton/',
        '/enseignants/activer/jeton/',
        '/enseignants/dossiers/',
        '/enseignants/recrutement/',
        '/messagerie/',
        '/messagerie/conversation/3/',
        '/portail-parent/notes/',
        '/admissions/',
        '/scholar/',
      ]) {
        expect(lien(chemin), isNull, reason: chemin);
      }
    });

    test('les routes de l\'application ne sont pas des liens', () {
      expect(lienEntrant(Uri.parse(Routes.accueilEtudiant)), isNull);
      expect(lienEntrant(Uri.parse(Routes.sectionEtudiant('notes'))), isNull);
      expect(lienEntrant(Uri.parse('/demarrage')), isNull);
    });

    test('un autre site n\'est pas suivi', () {
      expect(
          lienEntrant(Uri.parse('https://test.ysem.education/portail-etudiant/mes-notes/'),
              hote: hote),
          isNull);
      // Sans hôte (chemin seul, tel que go_router le transmet parfois).
      expect(lienEntrant(Uri.parse('/portail-etudiant/mes-notes/'), hote: hote),
          isNotNull);
    });
  });

  group('redirection d\'un lien', () {
    const notes = LienEntrant(
        espace: Espace.etudiant, chemin: '/portail-etudiant/mes-notes/');
    const etudiant =
        Session(espace: Espace.etudiant, acteur: {'matricule': 'X'});
    const enseignant =
        Session(espace: Espace.enseignant, acteur: {'matricule': 'LEC1'});

    test('restauration en cours : démarrage', () {
      expect(redirectionLien(const AsyncLoading(), notes), Routes.demarrage);
    });

    test('personne de connecté : la connexion de son espace', () {
      expect(redirectionLien(const AsyncData(null), notes),
          Routes.connexionEtudiant);
      expect(
          redirectionLien(
              const AsyncData(null),
              const LienEntrant(
                  espace: Espace.enseignant,
                  chemin: '/enseignants/mes-classes/')),
          Routes.connexionEnseignant);
    });

    test('connecté : l\'accueil, sur lequel la coque ouvre la section', () {
      expect(redirectionLien(const AsyncData(etudiant), notes),
          Routes.accueilEtudiant);
    });

    test('autre espace : son propre accueil', () {
      expect(redirectionLien(const AsyncData(enseignant), notes),
          Routes.accueilEnseignant);
    });

    test('mot de passe à changer : le changement d\'abord', () {
      const aChanger = Session(
        espace: Espace.etudiant,
        acteur: {'matricule': 'X'},
        doitChangerMotDePasse: true,
      );
      expect(redirectionLien(const AsyncData(aChanger), notes),
          Routes.motDePasseEtudiant);
    });
  });

  group('la coque ouvre le lien', () {
    late GoRouter routeur;

    Future<void> monter(WidgetTester tester, String depart,
        {Espace espace = Espace.etudiant}) async {
      final conteneur = ProviderContainer(overrides: [
        sessionProvider.overrideWith(_SessionFermee.new),
        depotEspaceProvider.overrideWith((ref, espace) => _Depot()),
        fabriqueCanalProvider
            .overrideWithValue((espace, chemin) => _CanalMuet(chemin)),
      ]);
      addTearDown(conteneur.dispose);
      routeur = GoRouter(
        initialLocation: depart,
        redirect: (_, etat) {
          final arrive = lienEntrant(etat.uri);
          if (arrive == null) return null;
          conteneur.read(liensEntrantsProvider).retenir(arrive);
          return '/accueil';
        },
        routes: [
          GoRoute(
            path: '/etudiant/section/:code',
            builder: (_, etat) => Scaffold(
                body: Text('section ${etat.pathParameters['code']}')),
          ),
          StatefulShellRoute.indexedStack(
            builder: (_, _, coque) => CoqueEspace(
              espace: espace,
              coque: coque,
              sectionDeLAdresse: sectionDeLAdresse,
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
      await tester.pumpWidget(UncontrolledProviderScope(
        container: conteneur,
        child: _Application(routeur: routeur),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('à froid : la section s\'ouvre sur l\'accueil', (tester) async {
      await monter(tester, '/portail-etudiant/mes-notes/');
      expect(find.text('section notes'), findsOneWidget);

      // « Retour » ramène dans l'application, pas hors d'elle.
      tester.element(find.text('section notes')).pop();
      await tester.pumpAndSettle();
      expect(find.text('page accueil'), findsOneWidget);
    });

    testWidgets('application ouverte : depuis un autre onglet aussi',
        (tester) async {
      await monter(tester, '/services');
      expect(find.text('page services'), findsOneWidget);

      routeur.go('/portail-etudiant/mes-documents/');
      await tester.pumpAndSettle();
      expect(find.text('section documents'), findsOneWidget);
    });

    testWidgets('un lien de l\'autre espace reste sans effet', (tester) async {
      await monter(tester, '/enseignants/mes-classes/');
      expect(find.text('page accueil'), findsOneWidget);
      expect(find.textContaining('section'), findsNothing);
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

class _SessionFermee extends SessionController {
  @override
  Future<Session?> build() async => null;
}

class _CanalMuet extends CanalTempsReel {
  _CanalMuet(String chemin)
      : super(chemin: chemin, jeton: ({bool forcer = false}) async => null);

  @override
  Stream<Map<String, dynamic>> get evenements => const Stream.empty();

  @override
  void ouvrir() => connecte.value = true;

  @override
  void fermer() => connecte.value = false;

  @override
  void envoyer(Map<String, dynamic> action) {}
}

class _Depot implements DepotEspace {
  @override
  Future<Navigation> navigation({bool complet = false}) async =>
      Navigation.depuisJson({'compteurs': {}});

  @override
  Future<int> compteurNotifications() async => 0;

  @override
  Future<void> marquerNotification(int id, {required bool lue}) async {}

  @override
  Future<PageNotifications> notifications(
          {int page = 1, bool nonLuesSeulement = false}) =>
      throw UnimplementedError();

  @override
  Future<void> supprimerNotification(int id) async {}

  @override
  Future<void> toutMarquerLu() async {}
}
