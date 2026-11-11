import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/core/models/navigation.dart';
import 'package:ysem/features/commun/espace/bouton_discussions.dart';
import 'package:ysem/l10n/app_localizations.dart';

/// Icône « Discussions de classe » du bandeau d'accueil.
void main() {
  Navigation menu({int? badge, bool avecDiscussions = true}) => Navigation(
        groupes: [
          GroupeNavigation(titre: 'Échanges', sections: [
            const SectionNavigation(code: 'messages', libelle: 'Mes messages'),
            if (avecDiscussions)
              SectionNavigation(
                code: 'discussions',
                libelle: 'Discussions de classe',
                badge: badge,
              ),
          ]),
        ],
      );

  Future<void> afficher(WidgetTester tester, Navigation? navigation,
      {VoidCallback? ouvrir}) {
    return tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: BoutonDiscussions(
          navigation: navigation,
          ouvrir: ouvrir ?? () {},
        ),
      ),
    ));
  }

  testWidgets('ouvre les discussions et montre les non-lus', (tester) async {
    var ouvertures = 0;
    await afficher(tester, menu(badge: 3), ouvrir: () => ouvertures++);

    expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.byTooltip('Discussions de classe'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.forum_outlined));
    expect(ouvertures, 1);
  });

  testWidgets('sans non-lus, pas de pastille', (tester) async {
    await afficher(tester, menu(badge: 0));
    expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('absente quand le menu ne l\'offre pas', (tester) async {
    // Candidat enseignant (section réservée aux recrutés), ou menu pas encore
    // lu : rien n'est promis.
    await afficher(tester, menu(avecDiscussions: false));
    expect(find.byIcon(Icons.forum_outlined), findsNothing);

    await afficher(tester, null);
    expect(find.byIcon(Icons.forum_outlined), findsNothing);
  });
}
