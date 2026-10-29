import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ysem/app/theme.dart';
import 'package:ysem/core/network/api_exception.dart';
import 'package:ysem/core/providers.dart';
import 'package:ysem/features/auth/data/auth_etudiant_repository.dart';
import 'package:ysem/features/auth/presentation/connexion_etudiant_page.dart';
import 'package:ysem/l10n/app_localizations.dart';

class _DepotRefusant extends Fake implements AuthEtudiantRepository {
  String? matriculeRecu;

  @override
  Future<ResultatConnexion> connexion({
    required String matricule,
    required String motDePasse,
  }) async {
    matriculeRecu = matricule;
    throw ApiException(
      code: 'identifiants_invalides',
      message: 'Matricule ou mot de passe incorrect.',
      statut: 401,
    );
  }
}

void main() {
  testWidgets("affiche le refus du serveur sous le formulaire", (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final depot = _DepotRefusant();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(preferences),
        authEtudiantRepositoryProvider.overrideWithValue(depot),
      ],
      child: MaterialApp(
        theme: AppTheme.clair,
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const ConnexionEtudiantPage(),
      ),
    ));
    await tester.pumpAndSettle();

    // Champs vides : contrôle local, aucun appel.
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Ce champ est obligatoire.'), findsNWidgets(2));
    expect(depot.matriculeRecu, isNull);

    await tester.enterText(find.byType(TextFormField).at(0), 'YS24-0012');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(depot.matriculeRecu, 'YS24-0012');
    expect(find.text('Matricule ou mot de passe incorrect.'), findsOneWidget);
  });
}
