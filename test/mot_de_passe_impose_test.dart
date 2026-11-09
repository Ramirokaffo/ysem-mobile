import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ysem/app/router.dart';
import 'package:ysem/app/theme.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/providers.dart';
import 'package:ysem/features/auth/application/session_controller.dart';
import 'package:ysem/features/auth/data/auth_etudiant_repository.dart';
import 'package:ysem/features/auth/presentation/changement_mot_de_passe_page.dart';
import 'package:ysem/l10n/app_localizations.dart';

class _Depot extends Fake implements AuthEtudiantRepository {
  @override
  Future<({Map<String, dynamic> acteur, String message})> changerMotDePasse({
    required String actuel,
    required String nouveau,
    required String confirmation,
  }) async =>
      (acteur: <String, dynamic>{'matricule': '261100161'}, message: 'Changé.');
}

class _Session extends SessionController {
  _Session(this.impose);

  final bool impose;

  @override
  Future<Session?> build() async => Session(
        espace: Espace.etudiant,
        acteur: const {'matricule': '261100161'},
        doitChangerMotDePasse: impose,
      );
}

Future<void> _monter(WidgetTester tester,
    {required bool impose, required String depart}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final conteneur = ProviderContainer(overrides: [
    preferencesProvider.overrideWithValue(preferences),
    authEtudiantRepositoryProvider.overrideWithValue(_Depot()),
    sessionProvider.overrideWith(() => _Session(impose)),
  ]);
  addTearDown(conteneur.dispose);
  await conteneur.read(sessionProvider.future);

  final rafraichir = ValueNotifier(0);
  conteneur.listen(sessionProvider, (_, _) => rafraichir.value++);
  // La règle de redirection de l'application, sur des pages réduites.
  final routeur = GoRouter(
    initialLocation: depart,
    refreshListenable: rafraichir,
    redirect: (_, etat) =>
        redirection(conteneur.read(sessionProvider), etat.matchedLocation),
    routes: [
      GoRoute(path: Routes.choixEspace, builder: (_, _) => const Text('choix')),
      GoRoute(
          path: Routes.accueilEtudiant,
          builder: (_, _) => const Scaffold(body: Text('accueil'))),
      GoRoute(
        path: Routes.profilEtudiant,
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push(Routes.motDePasseEtudiant),
            child: const Text('profil'),
          ),
        ),
      ),
      GoRoute(
        path: Routes.motDePasseEtudiant,
        builder: (_, _) => const ChangementMotDePassePage(),
      ),
    ],
  );

  await tester.pumpWidget(UncontrolledProviderScope(
    container: conteneur,
    child: MaterialApp.router(
      theme: AppTheme.clair,
      routerConfig: routeur,
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _changer(WidgetTester tester) async {
  final champs = find.byType(TextFormField);
  await tester.enterText(champs.at(0), 'ancien');
  await tester.enterText(champs.at(1), 'Nouveau-2026');
  await tester.enterText(champs.at(2), 'Nouveau-2026');
  await tester.tap(find.text('Enregistrer'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("changement imposé : l'accueil s'ouvre une fois le mot de passe "
      'changé', (tester) async {
    await _monter(tester, impose: true, depart: Routes.accueilEtudiant);
    expect(find.byType(ChangementMotDePassePage), findsOneWidget,
        reason: 'la redirection impose le changement');

    await _changer(tester);
    expect(find.byType(ChangementMotDePassePage), findsNothing);
    expect(find.text('accueil'), findsOneWidget);
  });

  testWidgets('changement volontaire : retour à la page qui l\'a ouvert',
      (tester) async {
    await _monter(tester, impose: false, depart: Routes.profilEtudiant);
    await tester.tap(find.text('profil'));
    await tester.pumpAndSettle();
    expect(find.byType(ChangementMotDePassePage), findsOneWidget);

    await _changer(tester);
    expect(find.byType(ChangementMotDePassePage), findsNothing);
    expect(find.text('profil'), findsOneWidget);
  });
}
