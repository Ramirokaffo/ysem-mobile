import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/models/champs.dart';
import 'package:ysem/core/network/api_client.dart';
import 'package:ysem/core/network/api_exception.dart';
import 'package:ysem/core/storage/token_storage.dart';
import 'package:ysem/features/enseignant/data/enseignant_repository.dart';
import 'package:ysem/features/enseignant/domain/feuilles.dart';
import 'package:ysem/features/enseignant/presentation/notes/grille_notes.dart';
import 'package:ysem/l10n/app_localizations.dart';

class _Stockage extends Fake implements TokenStorage {
  @override
  Future<Jetons?> lire(Espace espace) async => null;
}

class _Adaptateur implements HttpClientAdapter {
  _Adaptateur(this.corps, this.code);

  final Map<String, dynamic> corps;
  final int code;
  final requetes = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requetes.add(options);
    return ResponseBody.fromString(jsonEncode(corps), code, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

(EnseignantRepository, _Adaptateur) _depot(Map<String, dynamic> corps,
    {int code = 200}) {
  final adaptateur = _Adaptateur(corps, code);
  final dio =
      Dio(BaseOptions(baseUrl: 'http://test/api/v1/portail-enseignant/'))
        ..httpClientAdapter = adaptateur;
  return (
    EnseignantRepository(
        ApiClient(espace: Espace.enseignant, stockage: _Stockage(), dio: dio)),
    adaptateur,
  );
}

const _statuts = [
  OptionChamp(valeur: 'saisie', libelle: 'Note saisie'),
  OptionChamp(valeur: 'attendue', libelle: 'Attendue'),
  OptionChamp(valeur: 'absent_justifie', libelle: 'Absence justifiée'),
];

Map<String, dynamic> _epreuve(String type, String statut, {bool cc = false}) => {
      'type': type,
      'type_libelle': type,
      'statut': statut,
      'anonyme': !cc,
      'controle_continu': cc,
      'saisissable': statut == 'ouverte',
      'total': 2,
      'saisies': 1,
      'manquantes': 1,
    };

void main() {
  group('lecture', () {
    test('une feuille lit ses objets imbriqués et ses épreuves', () {
      final f = FeuilleNotes.depuisJson({
        'id': 4,
        'cours': {'code': 'X', 'intitule': 'Compta'},
        'niveau': {'nom': 'Licence 2'},
        'programme': {'nom': 'Gestion'},
        'specialite': {'nom': 'Finance'},
        'semestre': {'nom': 'S3'},
        'classe': 'Section francophone',
        'modifiable': false,
        'epreuves': [_epreuve('cc', 'ouverte', cc: true)],
      });
      expect(f.cohorte, 'Licence 2 · Finance · Section francophone');
      expect(f.modifiable, isFalse);
      expect(f.epreuves.single.controleContinu, isTrue);
    });

    test('une feuille sans spécialité nomme son programme', () {
      final f = FeuilleNotes.depuisJson({
        'id': 1,
        'niveau': {'nom': 'Licence 1'},
        'programme': {'nom': 'Gestion'},
        'specialite': null,
      });
      expect(f.cohorte, 'Licence 1 · Gestion');
    });

    test('une copie anonyme ne porte que son code', () {
      final l = LigneNote.depuisCopie(
          {'id': 9, 'code': 'CG-E-007', 'valeur': 12.5, 'statut': 'saisie'});
      expect(l.titre, 'CG-E-007');
      expect(l.sousTitre, isEmpty);
      expect(l.valeur, 12.5);
    });

    test('une note de contrôle nomme l\'étudiant', () {
      final l = LigneNote.depuisControle({
        'id': 2,
        'etudiant': {'matricule': 'M1', 'nom_complet': 'ABENA Paul'},
        'valeur': null,
        'statut': 'attendue',
      });
      expect(l.titre, 'ABENA Paul');
      expect(l.sousTitre, 'M1');
      expect(l.valeur, isNull);
    });

    test('la virgule du clavier vaut un point, le reste n\'est pas une note',
        () {
      expect(lireNote('12,5'), 12.5);
      expect(lireNote(' 8 '), 8);
      expect(lireNote('1,2,3'), isNull);
      expect(lireNote(''), isNull);
    });

    test('les erreurs se lisent ligne par ligne, dans l\'ordre', () {
      final corps = {
        'erreurs_tableaux': {
          'notes': {
            'lignes': [
              {},
              {
                'valeur': ['Trop haut.']
              },
            ],
            'ensemble': ['Global.'],
          },
        },
      };
      final lignes = erreursDesLignes(corps);
      expect(lignes[0], isEmpty);
      expect(lignes[1]['valeur'], ['Trop haut.']);
      expect(erreursDeLEnsemble(corps), ['Global.']);
      expect(erreursDesLignes(const {}), isEmpty);
    });
  });

  group('envois', () {
    test('déclarer un contrôle poste son action, son type et sa date', () async {
      final (depot, a) = _depot({
        'detail': 'Ajouté.',
        'controle': {'id': 3, 'libelle': 'Devoir 1'},
      });
      final (message, c) = await depot.creerControle(4,
          type: '7', date: DateTime(2026, 11, 2));
      expect(message, 'Ajouté.');
      expect(c.id, 3);
      expect(a.requetes.single.path, contains('feuilles-de-notes/4/'));
      expect(a.requetes.single.data, {
        'action': 'controle_creer',
        'type_controle': '7',
        'date': '2026-11-02',
      });
    });

    test('rendre une épreuve poste l\'épreuve et les seules cases touchées',
        () async {
      final (depot, a) = _depot({'detail': 'Rendu.'});
      await depot.rendreEpreuve(4, 'examen', const [
        NoteAEnvoyer(id: 9, valeur: '12.5', statut: 'saisie'),
      ]);
      expect(a.requetes.single.data, {
        'action': 'rendre',
        'epreuve': 'examen',
        'notes': [
          {'id': 9, 'valeur': '12.5', 'statut': 'saisie'},
        ],
      });
    });

    test('un refus garde ses erreurs de lignes', () async {
      final (depot, _) = _depot({
        'detail': 'Certaines notes…',
        'code': 'formulaire_invalide',
        'erreurs_tableaux': {
          'notes': {
            'lignes': [
              {
                'valeur': ['Non.']
              },
            ],
            'ensemble': [],
          },
        },
      }, code: 400);
      await expectLater(
        depot.enregistrerCopies(4, 'examen', const []),
        throwsA(isA<ApiException>().having(
          (e) => erreursDesLignes(e.donnees).single['valeur'],
          'erreurs',
          ['Non.'],
        )),
      );
    });
  });

  group('grille', () {
    Future<GlobalKey<GrilleNotesState>> monter(
      WidgetTester tester, {
      required EnvoiGrille surEnregistrer,
      List<LigneNote>? lignes,
    }) async {
      final cle = GlobalKey<GrilleNotesState>();
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: GrilleNotes(
              key: cle,
              lignes: lignes ??
                  const [
                    LigneNote(id: 1, titre: 'CG-E-001'),
                    LigneNote(
                        id: 2,
                        titre: 'CG-E-002',
                        valeur: 11,
                        statut: StatutsNote.saisie),
                  ],
              statuts: _statuts,
              noteMax: 20,
              modifiable: true,
              anonyme: true,
              surEnregistrer: surEnregistrer,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return cle;
    }

    testWidgets('seule la case touchée part, virgule convertie, statut saisi',
        (tester) async {
      List<NoteAEnvoyer>? envoi;
      final cle = await monter(tester, surEnregistrer: (notes) async {
        envoi = notes;
        return ('Enregistré.', const <LigneNote>[]);
      });
      expect(cle.currentState!.aDesModifications, isFalse);

      await tester.enterText(find.byType(TextField).first, '12,5');
      await tester.pump();
      expect(cle.currentState!.aDesModifications, isTrue);

      await tester.tap(find.text('Enregistrer les notes'));
      await tester.pump();
      expect(envoi!.single.versJson(),
          {'id': 1, 'valeur': '12.5', 'statut': 'saisie'});
    });

    testWidgets('vider une note saisie rend la case attendue, valeur nulle',
        (tester) async {
      final cle = await monter(tester,
          surEnregistrer: (_) async => ('', const <LigneNote>[]));
      await tester.enterText(find.byType(TextField).last, '');
      await tester.pump();
      expect(cle.currentState!.modifications().single.versJson(),
          {'id': 2, 'valeur': null, 'statut': 'attendue'});
    });

    testWidgets('une note au-dessus du barème n\'est pas envoyée',
        (tester) async {
      var appele = false;
      await monter(tester, surEnregistrer: (_) async {
        appele = true;
        return ('', const <LigneNote>[]);
      });
      await tester.enterText(find.byType(TextField).first, '21');
      await tester.tap(find.text('Enregistrer les notes'));
      await tester.pump();
      expect(appele, isFalse);
      expect(find.text('La note ne peut pas dépasser 20.'), findsOneWidget);
    });

    testWidgets('un refus du serveur s\'affiche sur sa ligne, saisie conservée',
        (tester) async {
      await monter(tester, surEnregistrer: (_) async {
        throw ApiException(
          code: 'formulaire_invalide',
          message: 'Certaines notes…',
          donnees: {
            'erreurs_tableaux': {
              'notes': {
                'lignes': [
                  {
                    'statut': ['Statut refusé.']
                  },
                  {},
                ],
                'ensemble': [],
              },
            },
          },
        );
      });
      await tester.enterText(find.byType(TextField).first, '9');
      await tester.tap(find.text('Enregistrer les notes'));
      await tester.pumpAndSettle();
      expect(find.text('Statut refusé.'), findsOneWidget);
      expect(find.text('Certaines notes…'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
    });

    testWidgets('sur une grille anonyme, rien d\'autre que le code',
        (tester) async {
      await monter(tester,
          surEnregistrer: (_) async => ('', const <LigneNote>[]));
      expect(find.text('CG-E-001'), findsOneWidget);
      expect(find.text('Note saisie'), findsOneWidget);
    });
  });
}
