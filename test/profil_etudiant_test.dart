import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/app/theme.dart';
import 'package:ysem/core/network/api_exception.dart';
import 'package:ysem/core/providers.dart';
import 'package:ysem/features/commun/piece_jointe.dart';
import 'package:ysem/features/etudiant/application/lectures.dart';
import 'package:ysem/features/etudiant/data/etudiant_repository.dart';
import 'package:ysem/features/etudiant/domain/modeles.dart';
import 'package:ysem/features/etudiant/presentation/profil/edition_profil_page.dart';
import 'package:ysem/features/etudiant/presentation/profil/profil_page.dart';
import 'package:ysem/l10n/app_localizations.dart';

/// Réponse de `profil/`, au format de `student_portal/api/views_compte.py`.
Map<String, dynamic> _reponse({bool profil = true, bool photo = false}) => {
      'profil': {
        'matricule': 'YS24001',
        'prenom': 'Paul',
        'nom': 'KAMGA',
        'nom_complet': 'Paul KAMGA',
        'telephone': '+237 690 00 00 00',
        'email': 'paul@exemple.cm',
        'photo': null,
        'etat_civil': {
          'ville_residence': 'Yaoundé',
          'quartier_residence': 'Bastos',
          'pere': {
            'nom': 'KAMGA Jean',
            'telephone': '',
            'email': '',
            'profession': 'Commerçant',
            'ville_residence': 'Bafoussam',
          },
          'mere': {
            'nom': '',
            'telephone': '',
            'email': '',
            'profession': '',
            'ville_residence': '',
          },
        },
      },
      'modification': {
        'profil_autorise': profil,
        'photo_autorisee': photo,
        'champs': profil
            ? [
                'firstname', 'lastname', 'phone_number',
                'residence_city', 'residence_quarter',
                'father_full_name', 'father_phone_number', 'father_email',
                'father_occupation', 'father_live_city',
                'mother_full_name', 'mother_phone_number', 'mother_email',
                'mother_occupation', 'mother_live_city',
              ]
            : [],
      },
      'inscription_courante': null,
      'connexions_recentes': [],
    };

class _Depot extends Fake implements EtudiantRepository {
  _Depot({this.reponse, this.refus});

  final Map<String, dynamic>? reponse;
  final ApiException? refus;
  final envois = <Map<String, String>>[];

  @override
  Future<Profil> profil() async => Profil.depuisJson(reponse ?? _reponse());

  @override
  Future<bool> modifierProfil(Map<String, String> champs) async {
    envois.add(champs);
    final erreur = refus;
    if (erreur != null) throw erreur;
    return true;
  }

  @override
  Future<void> changerPhoto(PieceAJoindre photo) async {}

  @override
  Future<void> retirerPhoto() async {}
}

Widget _app(Widget page, _Depot depot) => ProviderScope(
      overrides: [
        etudiantRepositoryProvider.overrideWithValue(depot),
        tableauDeBordProvider.overrideWith((ref) => throw UnimplementedError()),
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
        home: page,
      ),
    );

void main() {
  test('le profil lit les parents et ce que la scolarité ouvre', () {
    final p = Profil.depuisJson(_reponse(photo: true));
    expect(p.modification.profilAutorise, isTrue);
    expect(p.modification.photoAutorisee, isTrue);
    expect(p.modification.champs, contains('father_live_city'));
    expect(p.modification.champs, isNot(contains('email')));
    expect(p.pere.profession, 'Commerçant');
    expect(p.mere.estVide, isTrue);
    expect(p.valeursFormulaire['residence_quarter'], 'Bastos');
    expect(p.valeursFormulaire['father_full_name'], 'KAMGA Jean');
    expect(p.valeursFormulaire.containsKey('email'), isFalse);
  });

  test('un serveur antérieur ne rend rien de modifiable', () {
    final json = _reponse()..remove('modification');
    final p = Profil.depuisJson(json);
    expect(p.modification.profilAutorise, isFalse);
    expect(p.modification.photoAutorisee, isFalse);
  });

  group('Mise à jour du profil', () {
    testWidgets('fermée, le profil reste en lecture', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(800, 3000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
          _app(const ProfilPage(), _Depot(reponse: _reponse(profil: false))));
      await tester.pumpAndSettle();
      expect(find.text('Mettre à jour mon profil'), findsNothing);
      // Les parents connus restent lisibles.
      expect(find.text('Commerçant'), findsOneWidget);
    });

    testWidgets('ouverte, le profil offre la mise à jour', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(800, 3000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(const ProfilPage(), _Depot()));
      await tester.pumpAndSettle();
      expect(find.text('Mettre à jour mon profil'), findsOneWidget);
      expect(find.text('Parents et tuteurs'), findsOneWidget);

      await tester.tap(find.text('Mettre à jour mon profil'));
      await tester.pumpAndSettle();
      expect(find.byType(EditionProfilPage), findsOneWidget);
    });

    testWidgets('seuls les champs changés partent, jamais l’e-mail',
        (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(800, 3000);
      addTearDown(tester.view.reset);
      final depot = _Depot();
      await tester.pumpWidget(_app(
          EditionProfilPage(profil: Profil.depuisJson(_reponse())), depot));

      // L'adresse e-mail est montrée, désactivée.
      final email = tester.widget<TextField>(find.descendant(
        of: find.widgetWithText(TextFormField, 'Adresse e-mail').first,
        matching: find.byType(TextField),
      ));
      expect(email.enabled, isFalse);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Quartier de résidence'),
          'Mvog-Mbi ');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(depot.envois.single, {'residence_quarter': 'Mvog-Mbi'});
    });

    testWidgets('sans changement, rien ne part', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(800, 3000);
      addTearDown(tester.view.reset);
      final depot = _Depot();
      await tester.pumpWidget(_app(
          EditionProfilPage(profil: Profil.depuisJson(_reponse())), depot));
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(depot.envois, isEmpty);
      expect(find.text('Aucune modification à enregistrer.'), findsOneWidget);
    });

    testWidgets('un refus reste sur l’écran, l’erreur sous son champ',
        (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(800, 3000);
      addTearDown(tester.view.reset);
      final depot = _Depot(
        refus: ApiException(
          code: 'formulaire_invalide',
          message: "Les informations transmises n'ont pas été acceptées.",
          erreurs: const {
            'father_phone_number': ['Numéro de téléphone invalide.'],
          },
        ),
      );
      await tester.pumpWidget(_app(
          EditionProfilPage(profil: Profil.depuisJson(_reponse())), depot));
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Téléphone').first, '12');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.byType(EditionProfilPage), findsOneWidget);
      expect(find.text('Numéro de téléphone invalide.'), findsOneWidget);
      expect(find.text("Les informations transmises n'ont pas été acceptées."),
          findsOneWidget);
    });

    testWidgets('le prénom ne se vide pas', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(800, 3000);
      addTearDown(tester.view.reset);
      final depot = _Depot();
      await tester.pumpWidget(_app(
          EditionProfilPage(profil: Profil.depuisJson(_reponse())), depot));
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Prénom *'), '  ');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(depot.envois, isEmpty);
      expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
    });
  });
}
