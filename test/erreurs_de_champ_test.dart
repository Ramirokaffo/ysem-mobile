import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/app/theme.dart';
import 'package:ysem/core/network/api_exception.dart';
import 'package:ysem/core/providers.dart';
import 'package:ysem/features/commun/piece_jointe.dart';
import 'package:ysem/features/etudiant/data/etudiant_repository.dart';
import 'package:ysem/features/etudiant/domain/moratoires.dart';
import 'package:ysem/features/etudiant/domain/permissions.dart';
import 'package:ysem/features/etudiant/domain/reinscription.dart';
import 'package:ysem/features/etudiant/presentation/moratoires/nouvelle_demande_moratoire_page.dart';
import 'package:ysem/features/etudiant/presentation/permissions/nouvelle_permission_page.dart';
import 'package:ysem/features/etudiant/presentation/reinscription/declarer_versement_page.dart';
import 'package:ysem/features/etudiant/presentation/suggestions/nouvelle_suggestion_page.dart';
import 'package:ysem/l10n/app_localizations.dart';

/// Un refus du serveur sur un champ doit se lire **sous ce champ**, et ne
/// doit pas survivre au nouvel essai. Un validateur qui lirait une copie de
/// l'erreur prise au dernier `build` manquerait les deux : `validate()` part
/// avant la reconstruction, si bien que le premier refus ne s'affiche pas
/// sous le champ et que le second appui bute sur l'erreur d'avant, sans rien
/// envoyer au serveur.
const _messageGeneral = 'La demande n\'a pas pu être enregistrée.';
const _messageChamp = 'Ce champ est refusé par le serveur.';

ApiException _refus(String champ) => ApiException(
      code: 'formulaire_invalide',
      message: _messageGeneral,
      statut: 400,
      erreurs: {
        champ: [_messageChamp],
      },
    );

/// Refuse tous les envois, et les compte.
class _Depot extends Fake implements EtudiantRepository {
  _Depot(this.champ);

  final String champ;
  int envois = 0;

  Never _refuser() {
    envois++;
    throw _refus(champ);
  }

  @override
  Future<(String, Versements)> declarerVersement({
    required int compte,
    required String montant,
    required DateTime dateOperation,
    required String referenceOperation,
    required PieceAJoindre recu,
    int? tranche,
    String commentaire = '',
  }) async =>
      _refuser();

  @override
  Future<(String, Moratoires)> deposerMoratoire({
    required String montant,
    required DateTime dateSouhaitee,
    required String motif,
    PieceAJoindre? piece,
  }) async =>
      _refuser();

  @override
  Future<String> deposerSuggestion({
    required String texte,
    required String solution,
    List<PieceAJoindre> preuves = const [],
    String champPreuves = 'preuves',
  }) async =>
      _refuser();

  @override
  Future<Permissions> permissions({String? semaine}) async =>
      const Permissions(depotOuvert: true);

  @override
  Future<String> deposerPermission({
    required String? semaine,
    required String type,
    required List<String> seances,
    required String explication,
    String? motif,
    String? heureArrivee,
    PieceAJoindre? justificatif,
  }) async =>
      _refuser();
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

Future<void> _saisir(WidgetTester tester, String libelle, String texte) =>
    tester.enterText(find.widgetWithText(TextFormField, libelle), texte);

/// Le champ qui porte ce libellé.
Finder _champ(String libelle) => find
    .ancestor(
      of: find.text(libelle),
      matching: find.byWidgetPredicate((w) => w is FormField),
    )
    .first;

/// Deux appuis sur l'envoi, le serveur refusant chaque fois : après le
/// premier le message est sous **son** champ, et le second repart bien au
/// serveur.
Future<void> _deuxEnvoisRefuses(
  WidgetTester tester,
  _Depot depot, {
  required String bouton,
  required String libelle,
}) async {
  final sousLeChamp =
      find.descendant(of: _champ(libelle), matching: find.text(_messageChamp));

  await tester.tap(find.text(bouton));
  await tester.pumpAndSettle();
  expect(depot.envois, 1);
  expect(sousLeChamp, findsOneWidget);
  expect(find.text(_messageChamp), findsOneWidget);
  expect(find.text(_messageGeneral), findsOneWidget);

  await tester.tap(find.text(bouton));
  await tester.pumpAndSettle();
  expect(depot.envois, 2, reason: 'l\'erreur d\'avant ne bloque pas l\'envoi');
  expect(sousLeChamp, findsOneWidget);
}

Versements _versements() => Versements.depuisJson({
      'ouvert': true,
      'comptes': [
        {'id': 2, 'banque': 'Afriland', 'numero': '10005 00001'},
      ],
    });

Future<void> _ouvrirVersement(WidgetTester tester, _Depot depot) async {
  final t = lookupAppLocalizations(const Locale('fr'));
  await tester.pumpWidget(_app(DeclarerVersementPage(etat: _versements()), depot));
  await _saisir(tester, t.montantVerse, '150000');
  await _saisir(tester, t.referenceOperation, 'BRD-778');
  tester
      .widget<ChampPieceJointe>(find.byType(ChampPieceJointe))
      .surChoix(PieceAJoindre(nom: 'recu.jpg', octets: Uint8List(4)));
  await tester.pump();
}

Future<void> _ouvrirMoratoire(WidgetTester tester, _Depot depot) async {
  final t = lookupAppLocalizations(const Locale('fr'));
  await tester.pumpWidget(_app(
    const NouvelleDemandeMoratoirePage(
        montantDemandable: 200000, annee: '2026-2027'),
    depot,
  ));
  await _saisir(tester, t.montantSollicite, '50000');
  await _saisir(tester, t.motifDeLaDemande, 'Salaire versé en fin de mois.');
  await _validerSelecteur(tester, t.dateReglementSouhaitee);
}

/// Ouvre le sélecteur d'un champ de date ou d'heure et valide sa proposition.
Future<void> _validerSelecteur(WidgetTester tester, String libelle) async {
  await tester.tap(find.widgetWithText(InputDecorator, libelle));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  final t = lookupAppLocalizations(const Locale('fr'));

  group('Déclaration d\'un versement', () {
    final champs = {
      'compte': t.compteCredite,
      'montant': t.montantVerse,
      'date_operation': t.dateDuVersement,
      'reference_operation': t.referenceOperation,
      'piece': t.recuDeLaBanque,
    };
    for (final MapEntry(key: champ, value: libelle) in champs.entries) {
      testWidgets('le refus de « $champ » se lit sous le champ', (tester) async {
        _grandEcran(tester);
        final depot = _Depot(champ);
        await _ouvrirVersement(tester, depot);
        await _deuxEnvoisRefuses(tester, depot,
            bouton: t.declarerLeVersement, libelle: libelle);
      });
    }
  });

  group('Demande de moratoire', () {
    final champs = {
      'amount': t.montantSollicite,
      'requested_due_date': t.dateReglementSouhaitee,
      'reason': t.motifDeLaDemande,
    };
    for (final MapEntry(key: champ, value: libelle) in champs.entries) {
      testWidgets('le refus de « $champ » se lit sous le champ', (tester) async {
        _grandEcran(tester);
        final depot = _Depot(champ);
        await _ouvrirMoratoire(tester, depot);
        await _deuxEnvoisRefuses(tester, depot,
            bouton: t.envoyerDemande, libelle: libelle);
      });
    }
  });

  group('Suggestion', () {
    final champs = {
      'texte': t.votreSuggestion,
      'solution_proposee': t.solutionProposee,
    };
    for (final MapEntry(key: champ, value: libelle) in champs.entries) {
      testWidgets('le refus de « $champ » se lit sous le champ', (tester) async {
        _grandEcran(tester);
        final depot = _Depot(champ);
        await tester.pumpWidget(_app(
          const NouvelleSuggestionPage(preuvesMax: 5, champPreuves: 'preuves'),
          depot,
        ));
        await _saisir(tester, t.votreSuggestion, 'Ouvrir la salle le soir.');
        await _saisir(tester, t.solutionProposee, 'Un agent jusqu\'à 20 h.');
        await _deuxEnvoisRefuses(tester, depot,
            bouton: t.deposerSuggestion, libelle: libelle);
      });
    }
  });

  group('Demande de permission', () {
    Future<_Depot> ouvrir(WidgetTester tester, String champ) async {
      _grandEcran(tester);
      final depot = _Depot(champ);
      await tester.pumpWidget(_app(const NouvellePermissionPage(), depot));
      await tester.pumpAndSettle();
      await _saisir(tester, t.explication, 'Rendez-vous à l\'hôpital.');
      return depot;
    }

    testWidgets('le refus de l\'explication se lit sous le champ',
        (tester) async {
      final depot = await ouvrir(tester, 'motif_libre');
      await _deuxEnvoisRefuses(tester, depot,
          bouton: t.envoyerDemande, libelle: t.explication);
    });

    testWidgets('le refus de l\'heure d\'arrivée se lit sous le champ',
        (tester) async {
      final depot = await ouvrir(tester, 'heure_arrivee_prevue');
      await tester.tap(find.text(t.retard));
      await tester.pumpAndSettle();
      await _validerSelecteur(tester, t.heureArriveeAnnoncee);
      await _deuxEnvoisRefuses(tester, depot,
          bouton: t.envoyerDemande, libelle: t.heureArriveeAnnoncee);
    });
  });
}
