import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/app/theme.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/network/api_client.dart';
import 'package:ysem/core/network/api_exception.dart';
import 'package:ysem/core/providers.dart';
import 'package:ysem/core/storage/token_storage.dart';
import 'package:ysem/features/etudiant/data/etudiant_repository.dart';
import 'package:ysem/features/etudiant/domain/finances.dart';
import 'package:ysem/features/etudiant/domain/mobile_money.dart';
import 'package:ysem/features/etudiant/presentation/finances/finances_page.dart';
import 'package:ysem/features/etudiant/presentation/mobile_money/mobile_money_page.dart';
import 'package:ysem/features/etudiant/presentation/mobile_money/suivi_paiement_mobile_page.dart';
import 'package:ysem/l10n/app_localizations.dart';

const _tranche = {
  'id': 7,
  'libelle': 'Première tranche',
  'ordre': 1,
  'echeance': '2026-11-30',
  'montant': 100000,
  'montant_paye': 25000,
  'reste_a_payer': 75000,
  'echue': false,
  'statut_libelle': 'Partielle',
};

Map<String, dynamic> _paiement({
  String statut = 'en_attente',
  bool ouvert = true,
  bool annulable = true,
  bool parTiers = false,
  String? recu,
}) =>
    {
      'id': 41,
      'reference': 'PMM-20261105-AB12CD34',
      'annee': {'id': 3, 'nom': '2026-2027'},
      'tranche': 'Première tranche',
      'operateur': 'MTN',
      'operateur_libelle': 'MTN Mobile Money',
      'telephone': '670000000',
      'montant': 75000,
      'frais': 2320,
      'montant_debite': 77320,
      'statut': statut,
      'statut_libelle': statut == 'reussi' ? 'Réussi' : 'En attente de confirmation',
      'message': statut == 'reussi'
          ? 'Paiement reçu : la situation financière est à jour.'
          : 'Une invite va s\'afficher sur votre téléphone.',
      'ouvert': ouvert,
      'annulable': annulable,
      'lance_par_un_parent': parTiers,
      'payeur': parTiers ? 'Paul Njoya' : 'Amina Njoya',
      'test': false,
      'ouvert_le': '2026-11-05T10:00:00+01:00',
      'confirme_le': null,
      'recu_url': recu,
    };

Map<String, dynamic> _etat({
  bool ouvert = true,
  List<Map<String, dynamic>> paiements = const [],
  num payable = 175000,
  Map<String, dynamic>? apercu,
}) =>
    {
      'ouvert': ouvert,
      'motif': ouvert ? '' : 'Le paiement Mobile Money n\'est pas ouvert.',
      'annee': {'id': 3, 'nom': '2026-2027'},
      'test': false,
      'operateurs': [
        {'code': 'MTN', 'libelle': 'MTN Mobile Money'},
        {'code': 'ORANGE', 'libelle': 'Orange Money'},
      ],
      'telephone_propose': '670000000',
      'montant_payable': payable,
      'tranches': [_tranche],
      'paiements': paiements,
      'apercu': ?apercu,
    };

class _Depot extends Fake implements EtudiantRepository {
  _Depot({
    required this.etat,
    this.relectures = const [],
    this.refus,
    this.situation,
  });

  MobileMoney etat;
  List<PaiementMobile> relectures;
  ApiException? refus;
  Finances? situation;
  Map<String, Object?>? envoi;
  int lectures = 0;
  int annulations = 0;

  @override
  Future<MobileMoney> mobileMoney({int? montant}) async => montant == null
      ? etat
      : MobileMoney.depuisJson(_etat(apercu: {
          'montant': montant,
          'frais': 310,
          'montant_debite': montant + 310,
        }));

  @override
  Future<PaiementMobile> lancerPaiementMobile({
    required int montant,
    required String operateur,
    required String telephone,
    int? tranche,
  }) async {
    envoi = {
      'montant': montant,
      'operateur': operateur,
      'telephone': telephone,
      'tranche': tranche,
    };
    if (refus != null) throw refus!;
    return PaiementMobile.depuisJson(_paiement());
  }

  @override
  Future<PaiementMobile> paiementMobile(int id) async {
    lectures++;
    final courante = relectures.first;
    if (relectures.length > 1) relectures = relectures.sublist(1);
    return courante;
  }

  @override
  Future<PaiementMobile> annulerPaiementMobile(int id) async {
    annulations++;
    return PaiementMobile.depuisJson(
        _paiement(statut: 'annule', ouvert: false, annulable: false));
  }

  @override
  Future<Finances> finances({int? annee}) async => situation!;
}

Widget _app(Widget page, _Depot depot) => ProviderScope(
      overrides: [etudiantRepositoryProvider.overrideWithValue(depot)],
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

/// Un écran assez haut pour que tout le formulaire tienne sans défilement.
void _grandEcran(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

class _Stockage extends Fake implements TokenStorage {
  @override
  Future<Jetons?> lire(Espace espace) async => null;
}

class _Adaptateur implements HttpClientAdapter {
  RequestOptions? requete;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requete = options;
    return ResponseBody.fromString(jsonEncode(_paiement()), 201, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('Modèles', () {
    test('une transaction se lit, et un parent se reconnaît', () {
      final p = PaiementMobile.depuisJson(_paiement(parTiers: true));
      expect(p.ouvert, isTrue);
      expect(p.montantDebite, 77320);
      expect(p.lanceParUnParent, isTrue);
      expect(p.payeur, 'Paul Njoya');
    });

    test('un serveur plus ancien ne dit rien du payeur', () {
      final json = _paiement()
        ..remove('lance_par_un_parent')
        ..remove('payeur');
      final p = PaiementMobile.depuisJson(json);
      expect(p.lanceParUnParent, isFalse);
      expect(p.payeur, isEmpty);
    });

    test('la transaction ouverte se trouve dans l\'historique', () {
      final etat = MobileMoney.depuisJson(_etat(paiements: [
        _paiement(statut: 'reussi', ouvert: false),
        _paiement(),
      ]));
      expect(etat.enCours?.statut, 'en_attente');
    });

    test('rien à payer ou portail fermé : le paiement n\'est pas offert', () {
      expect(MobileMoney.depuisJson(_etat(payable: 0)).payable, isFalse);
      expect(MobileMoney.depuisJson(_etat(ouvert: false)).payable, isFalse);
      expect(MobileMoney.depuisJson(_etat()).payable, isTrue);
    });
  });

  group('Dépôt', () {
    test('le lancement poste les champs du formulaire du serveur', () async {
      final adaptateur = _Adaptateur();
      final dio =
          Dio(BaseOptions(baseUrl: 'http://test/api/v1/portail-etudiant/'))
            ..httpClientAdapter = adaptateur;
      final depot = EtudiantRepository(
          ApiClient(espace: Espace.etudiant, stockage: _Stockage(), dio: dio));

      await depot.lancerPaiementMobile(
          montant: 75000, operateur: 'MTN', telephone: '670000000', tranche: 7);

      final requete = adaptateur.requete!;
      expect(requete.path, 'finances/mobile-money/');
      expect(requete.data, {
        'montant': 75000,
        'operateur': 'MTN',
        'telephone': '670000000',
        'installment': '7',
      });
      // L'attente de l'agrégateur dépasse le délai ordinaire.
      expect(requete.receiveTimeout, const Duration(seconds: 45));
    });
  });

  group('Formulaire', () {
    testWidgets('une tranche visée propose son reste et le numéro connu',
        (tester) async {
      _grandEcran(tester);
      final depot = _Depot(etat: MobileMoney.depuisJson(_etat()));
      await tester.pumpWidget(_app(const MobileMoneyPage(trancheVisee: 7), depot));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, '75000'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '670000000'), findsOneWidget);
      // Frais calculés par le serveur, pas par l'écran.
      expect(find.text('Frais de transaction'), findsOneWidget);
    });

    testWidgets('sans opérateur rien ne part', (tester) async {
      _grandEcran(tester);
      final depot = _Depot(etat: MobileMoney.depuisJson(_etat()));
      await tester.pumpWidget(_app(const MobileMoneyPage(tout: true), depot));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lancer le paiement'));
      await tester.pumpAndSettle();

      expect(find.text('Choisissez l\'opérateur.'), findsOneWidget);
      expect(depot.envoi, isNull);
    });

    testWidgets('un montant au-delà du plafond est refusé avant l\'envoi',
        (tester) async {
      _grandEcran(tester);
      final depot = _Depot(etat: MobileMoney.depuisJson(_etat()));
      await tester.pumpWidget(_app(const MobileMoneyPage(tout: true), depot));
      await tester.pumpAndSettle();

      await tester.tap(find.text('MTN Mobile Money'));
      await tester.enterText(
          find.widgetWithText(TextFormField, '175000'), '999999');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Lancer le paiement'));
      await tester.pumpAndSettle();

      expect(depot.envoi, isNull);
    });

    testWidgets('le paiement part et mène au suivi', (tester) async {
      _grandEcran(tester);
      final depot = _Depot(
        etat: MobileMoney.depuisJson(_etat()),
        relectures: [PaiementMobile.depuisJson(_paiement())],
      );
      await tester.pumpWidget(_app(const MobileMoneyPage(trancheVisee: 7), depot));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Orange Money'));
      await tester.pump();
      await tester.tap(find.text('Lancer le paiement'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(depot.envoi, {
        'montant': 75000,
        'operateur': 'ORANGE',
        'telephone': '670000000',
        'tranche': 7,
      });
      expect(find.byType(SuiviPaiementMobilePage), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('un paiement déjà ouvert mène à sa transaction', (tester) async {
      _grandEcran(tester);
      final depot = _Depot(
        etat: MobileMoney.depuisJson(_etat()),
        relectures: [PaiementMobile.depuisJson(_paiement())],
        refus: ApiException(
          code: 'paiement_mobile_en_cours',
          message: 'Déjà en cours',
          statut: 409,
          donnees: {'paiement': _paiement()},
        ),
      );
      await tester.pumpWidget(_app(const MobileMoneyPage(trancheVisee: 7), depot));
      await tester.pumpAndSettle();

      await tester.tap(find.text('MTN Mobile Money'));
      await tester.pump();
      await tester.tap(find.text('Lancer le paiement'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SuiviPaiementMobilePage), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('une réponse perdue relit l\'état et ne laisse pas relancer',
        (tester) async {
      _grandEcran(tester);
      final depot = _Depot(
        etat: MobileMoney.depuisJson(_etat()),
        refus: ApiException(code: ApiException.codeDelai, message: 'Trop long'),
      );
      await tester.pumpWidget(_app(const MobileMoneyPage(trancheVisee: 7), depot));
      await tester.pumpAndSettle();

      await tester.tap(find.text('MTN Mobile Money'));
      await tester.pump();
      // Le serveur avait bien ouvert la transaction.
      depot.etat = MobileMoney.depuisJson(_etat(paiements: [_paiement()]));
      await tester.tap(find.text('Lancer le paiement'));
      await tester.pumpAndSettle();

      expect(find.text('Suivre le paiement'), findsOneWidget);
      expect(find.text('Lancer le paiement'), findsNothing);
    });

    testWidgets('un champ refusé par le serveur s\'affiche sous le champ',
        (tester) async {
      _grandEcran(tester);
      final depot = _Depot(
        etat: MobileMoney.depuisJson(_etat()),
        refus: ApiException(
          code: 'formulaire_invalide',
          message: 'Le paiement n\'a pas pu être lancé.',
          statut: 400,
          erreurs: const {
            'montant': ['Le montant dépasse ce qui reste à payer.'],
          },
        ),
      );
      await tester.pumpWidget(_app(const MobileMoneyPage(trancheVisee: 7), depot));
      await tester.pumpAndSettle();

      await tester.tap(find.text('MTN Mobile Money'));
      await tester.pump();
      await tester.tap(find.text('Lancer le paiement'));
      await tester.pumpAndSettle();

      // Sous son champ, et non sous celui que le bandeau aurait décalé.
      expect(
        find.descendant(
          of: find.byWidgetPredicate((w) =>
              w is TextFormField && w.controller?.text == '75000'),
          matching: find.text('Le montant dépasse ce qui reste à payer.'),
        ),
        findsOneWidget,
      );
      expect(find.text('Le montant dépasse ce qui reste à payer.'), findsOneWidget);
      expect(find.text('Le paiement n\'a pas pu être lancé.'), findsOneWidget);
    });
  });

  group('Page', () {
    testWidgets('une transaction en attente prend la place du formulaire',
        (tester) async {
      _grandEcran(tester);
      final depot =
          _Depot(etat: MobileMoney.depuisJson(_etat(paiements: [_paiement()])));
      await tester.pumpWidget(_app(const MobileMoneyPage(), depot));
      await tester.pumpAndSettle();

      expect(find.text('Lancer le paiement'), findsNothing);
      expect(find.text('Suivre le paiement'), findsOneWidget);
    });

    testWidgets('fermé, le motif du serveur s\'affiche', (tester) async {
      final depot = _Depot(etat: MobileMoney.depuisJson(_etat(ouvert: false)));
      await tester.pumpWidget(_app(const MobileMoneyPage(), depot));
      await tester.pumpAndSettle();

      expect(find.text('Le paiement Mobile Money n\'est pas ouvert.'), findsOneWidget);
      expect(find.text('Lancer le paiement'), findsNothing);
    });

    testWidgets('l\'historique nomme le parent qui a payé', (tester) async {
      _grandEcran(tester);
      final depot = _Depot(
        etat: MobileMoney.depuisJson(_etat(paiements: [
          _paiement(statut: 'reussi', ouvert: false, annulable: false, parTiers: true),
        ])),
      );
      await tester.pumpWidget(_app(const MobileMoneyPage(), depot));
      await tester.pumpAndSettle();

      expect(find.textContaining('Lancé par Paul Njoya'), findsOneWidget);
    });
  });

  group('Suivi', () {
    testWidgets('la lecture périodique s\'arrête au dénouement', (tester) async {
      _grandEcran(tester);
      final depot = _Depot(
        etat: MobileMoney.depuisJson(_etat()),
        relectures: [
          PaiementMobile.depuisJson(_paiement()),
          PaiementMobile.depuisJson(_paiement(
              statut: 'reussi', ouvert: false, annulable: false,
              recu: '/api/v1/portail-etudiant/finances/paiements/9/recu/')),
        ],
      );
      await tester.pumpWidget(_app(
        SuiviPaiementMobilePage(paiement: PaiementMobile.depuisJson(_paiement())),
        depot,
      ));
      await tester.pump();
      await tester.pump();
      expect(depot.lectures, 1);
      expect(find.text('Annuler le paiement'), findsOneWidget);

      await tester.pump(SuiviPaiementMobilePage.intervalle);
      await tester.pump();
      expect(find.text('Réussi'), findsOneWidget);
      expect(find.text('Télécharger le reçu'), findsOneWidget);
      expect(find.text('Annuler le paiement'), findsNothing);

      final avant = depot.lectures;
      await tester.pump(SuiviPaiementMobilePage.intervalle * 3);
      expect(depot.lectures, avant);
    });

    testWidgets('revenir dans l\'application relit la transaction',
        (tester) async {
      _grandEcran(tester);
      final depot = _Depot(
        etat: MobileMoney.depuisJson(_etat()),
        relectures: [PaiementMobile.depuisJson(_paiement())],
      );
      await tester.pumpWidget(_app(
        SuiviPaiementMobilePage(paiement: PaiementMobile.depuisJson(_paiement())),
        depot,
      ));
      await tester.pump();
      await tester.pump();
      final avant = depot.lectures;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(depot.lectures, avant + 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('un paiement lancé par un parent ne s\'annule pas ici',
        (tester) async {
      _grandEcran(tester);
      final paiement = _paiement(annulable: false, parTiers: true);
      final depot = _Depot(
        etat: MobileMoney.depuisJson(_etat()),
        relectures: [PaiementMobile.depuisJson(paiement)],
      );
      await tester.pumpWidget(_app(
        SuiviPaiementMobilePage(paiement: PaiementMobile.depuisJson(paiement)),
        depot,
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Annuler le paiement'), findsNothing);
      expect(find.text('Lancé par Paul Njoya'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renoncer demande confirmation', (tester) async {
      _grandEcran(tester);
      final depot = _Depot(
        etat: MobileMoney.depuisJson(_etat()),
        relectures: [PaiementMobile.depuisJson(_paiement())],
      );
      await tester.pumpWidget(_app(
        SuiviPaiementMobilePage(paiement: PaiementMobile.depuisJson(_paiement())),
        depot,
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Annuler le paiement'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(depot.annulations, 0);

      await tester.tap(find.widgetWithText(FilledButton, 'Annuler le paiement'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(depot.annulations, 1);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Situation financière', () {
    Finances finances({int annee = 3}) => Finances.depuisJson({
          'annee_selectionnee': {'id': annee, 'nom': '2026-2027'},
          'annees_disponibles': [
            {'id': annee, 'nom': '2026-2027'},
          ],
          'situation': {
            'totaux': {'total_du': 175000, 'reste_a_payer': 175000},
            'tranches': [_tranche],
            'paiements': const [],
            'moratoires': const [],
          },
        });

    testWidgets('l\'année active offre le paiement, tranche comprise',
        (tester) async {
      _grandEcran(tester);
      final depot = _Depot(
          etat: MobileMoney.depuisJson(_etat()), situation: finances());
      await tester.pumpWidget(_app(const FinancesPage(), depot));
      await tester.pumpAndSettle();

      expect(find.text('Payer par Mobile Money'), findsOneWidget);
      expect(find.text('Payer cette tranche'), findsOneWidget);
    });

    testWidgets('une année passée ne l\'offre pas', (tester) async {
      _grandEcran(tester);
      final depot = _Depot(
          etat: MobileMoney.depuisJson(_etat()), situation: finances(annee: 2));
      await tester.pumpWidget(_app(const FinancesPage(), depot));
      await tester.pumpAndSettle();

      expect(find.text('Payer par Mobile Money'), findsNothing);
      expect(find.text('Payer cette tranche'), findsNothing);
    });

    testWidgets('fermé, la page reste entière', (tester) async {
      _grandEcran(tester);
      final depot = _Depot(
          etat: MobileMoney.depuisJson(_etat(ouvert: false)),
          situation: finances());
      await tester.pumpWidget(_app(const FinancesPage(), depot));
      await tester.pumpAndSettle();

      expect(find.text('Payer par Mobile Money'), findsNothing);
      expect(find.text('Première tranche'), findsOneWidget);
    });
  });
}
