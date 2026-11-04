import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/network/api_client.dart';
import 'package:ysem/core/network/api_exception.dart';
import 'package:ysem/core/providers.dart';
import 'package:ysem/core/storage/token_storage.dart';
import 'package:ysem/features/auth/data/auth_enseignant_repository.dart';
import 'package:ysem/features/commun/piece_jointe.dart';
import 'package:ysem/features/enseignant/data/enseignant_repository.dart';
import 'package:ysem/features/enseignant/domain/dossier.dart';
import 'package:ysem/features/enseignant/domain/modeles.dart';
import 'package:ysem/features/enseignant/presentation/dossier/dossier_page.dart';
import 'package:ysem/features/enseignant/presentation/dossier/edition_dossier_page.dart';
import 'package:ysem/l10n/app_localizations.dart';

class _Stockage extends Fake implements TokenStorage {
  @override
  Future<Jetons?> lire(Espace espace) async => null;
}

class _Adaptateur implements HttpClientAdapter {
  final requetes = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requetes.add(options);
    return ResponseBody.fromString(
        jsonEncode({'detail': 'Enregistré.', 'modifie': true}), 200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
  }

  @override
  void close({bool force = false}) {}
}

class _Depot extends Fake implements EnseignantRepository {
  _Depot({this.reponse, this.refus});

  final DossierEnseignant? reponse;
  final ApiException? refus;
  final envois = <Map<String, dynamic>>[];

  @override
  Future<DossierEnseignant> dossier() async => reponse!;

  @override
  Future<Uint8List?> photo() async => null;

  @override
  Future<ResultatDossier> modifierDossier(
    Map<String, dynamic> corps, {
    Map<String, PieceAJoindre> fichiers = const {},
  }) async {
    envois.add(corps);
    if (refus != null) throw refus!;
    return const ResultatDossier(detail: 'Votre dossier a bien été mis à jour.');
  }
}

class _Auth extends Fake implements AuthEnseignantRepository {
  @override
  Future<Map<String, dynamic>> moi() async =>
      throw ApiException(code: 'reseau', message: 'Hors ligne');
}

const _autres = 'Autres';

Map<String, dynamic> _reponseProfil({bool avecValeurs = true}) => {
      'dossier': {
        'matricule': 'LEC1',
        'nom_complet': 'Ada Nkoulou',
        'recrute': true,
        'cv_depose': true,
        'cursus': [
          {'id': 3, 'diplome': 'BAC', 'specialization': 'Série D'},
          {'id': 8, 'diplome': 'Licence', 'specialization': 'Gestion'},
        ],
      },
      'pieces_a_completer': ['Adresse'],
      if (avecValeurs) ...{
        'champs': {
          'identite': [
            {'nom': 'firstname', 'libelle': 'Prénom', 'type': 'CharField'},
            {
              'nom': 'date_naiss',
              'libelle': 'Date de naissance',
              'type': 'DateField',
            },
            {
              'nom': 'nationality',
              'libelle': 'Nationalité',
              'type': 'ChoiceField',
              'choix': [
                {'valeur': 'Cameroun', 'libelle': 'Cameroun'},
                {'valeur': 'Gabon', 'libelle': 'Gabon'},
              ],
            },
            {
              'nom': 'has_health_problem',
              'libelle': 'Problèmes de santé ?',
              'type': 'BooleanField',
            },
            {
              'nom': 'health_problem_description',
              'libelle': 'Description',
              'type': 'CharField',
              'multiligne': true,
            },
            {'nom': 'phone_number', 'libelle': 'Téléphone', 'type': 'CharField'},
            {'nom': 'photo', 'libelle': 'Photo', 'type': 'ImageField'},
          ],
          'professionnel': [
            {'nom': 'cv', 'libelle': 'CV', 'type': 'FileField', 'retirable': true},
          ],
          'cursus': [
            {
              'nom': 'diploma',
              'libelle': 'Diplôme',
              'obligatoire': true,
              'type': 'TypedChoiceField',
              'choix': [
                {'valeur': 'BAC', 'libelle': 'Baccalauréat'},
                {'valeur': 'Licence', 'libelle': 'Licence'},
              ],
            },
            {
              'nom': 'specialization',
              'libelle': 'Spécialisation',
              'obligatoire': true,
              'type': 'CharField',
            },
            {
              'nom': 'establishment',
              'libelle': 'Établissement',
              'type': 'ChoixOrganismeField',
              'champ_autre': 'establishment_autre',
              'valeur_autre': _autres,
              'choix': [
                {'valeur': 'UY1', 'libelle': 'Université de Yaoundé I'},
                {'valeur': _autres, 'libelle': 'Autres (à préciser)'},
              ],
            },
            {
              'nom': 'proof_document',
              'libelle': 'Justificatif',
              'type': 'FileField',
              'retirable': true,
            },
            {
              'nom': 'establishment_autre',
              'libelle': 'Précisez le nom',
              'type': 'CharField',
            },
          ],
        },
        'valeurs': {
          'identite': {
            'firstname': 'Ada',
            'date_naiss': '1980-05-17',
            'nationality': 'Cameroun',
            'has_health_problem': 'false',
            'health_problem_description': '',
            'phone_number': '677000000',
          },
          'professionnel': {},
          'cursus': [
            {
              'id': 3,
              'valeurs': {
                'diploma': 'BAC',
                'specialization': 'Série D',
                'establishment': _autres,
                'establishment_autre': 'Lycée de Bafia',
              },
              'pieces': ['proof_document'],
            },
            {
              'id': 8,
              'valeurs': {
                'diploma': 'Licence',
                'specialization': 'Gestion',
                'establishment': 'UY1',
                'establishment_autre': '',
              },
              'pieces': [],
            },
          ],
          'certifications': [],
          'experiences_enseignement': [],
          'experiences_entreprise': [],
        },
      },
    };

FormulairesDossier _formulaires() =>
    FormulairesDossier.depuisJson(_reponseProfil())!;

SaisieDossier _ligne(int id) {
  final f = _formulaires();
  return SaisieDossier(
      f, CibleLigne(TableauDossier.cursus, f.ligne(TableauDossier.cursus, id)));
}

Widget _app(Widget page, {required _Depot depot}) => ProviderScope(
      overrides: [
        enseignantRepositoryProvider.overrideWithValue(depot),
        authEnseignantRepositoryProvider.overrideWithValue(_Auth()),
      ],
      child: MaterialApp(
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
  group('Formulaires du dossier', () {
    test('un serveur qui ne rend pas les valeurs laisse le dossier en lecture',
        () {
      final d =
          DossierEnseignant.depuisJson(_reponseProfil(avecValeurs: false));
      expect(d.formulaires, isNull);
      expect(d.cursus.first.id, 3);
    });

    test('le champ libre suit sa liste, et ne s’offre que sous « Autres »', () {
      final s = _ligne(8);
      expect(s.champs.map((c) => c.nom).toList(), [
        'diploma',
        'specialization',
        'establishment',
        'establishment_autre',
        'proof_document',
      ]);
      expect(s.champsVisibles.map((c) => c.nom),
          isNot(contains('establishment_autre')));

      s.valeurs['establishment'] = _autres;
      expect(s.champsVisibles.map((c) => c.nom),
          contains('establishment_autre'));
    });

    test('la description de santé attend la case', () {
      final s = SaisieDossier(_formulaires(), const CibleBloc(BlocDossier.identite));
      bool visible() => s.champsVisibles
          .any((c) => c.nom == 'health_problem_description');
      expect(visible(), isFalse);
      s.valeurs['has_health_problem'] = 'true';
      expect(visible(), isTrue);
    });

    test('un bloc n’envoie que ce qui a changé', () {
      final s =
          SaisieDossier(_formulaires(), const CibleBloc(BlocDossier.coordonnees));
      expect(s.corps, isEmpty);
      s.valeurs['phone_number'] = '699000000';
      expect(s.corps, {'phone_number': '699000000'});
    });

    test('vider un champ s’envoie : l’absence garderait la valeur', () {
      final s =
          SaisieDossier(_formulaires(), const CibleBloc(BlocDossier.coordonnees));
      s.valeurs['phone_number'] = '';
      expect(s.corps, {'phone_number': ''});
    });

    test('une ligne connue porte son id et ses seuls changements', () {
      final s = _ligne(3);
      s.valeurs['specialization'] = 'Série C';
      expect(s.corps, {
        'cursus': [
          {'id': 3, 'specialization': 'Série C'},
        ],
      });
    });

    test('une ligne neuve n’envoie pas ses champs vides', () {
      final s = SaisieDossier(
          _formulaires(), const CibleLigne(TableauDossier.cursus));
      expect(s.estLigneNeuve, isTrue);
      s.valeurs['diploma'] = 'Licence';
      expect(s.corps, {
        'cursus': [
          {'diploma': 'Licence'},
        ],
      });
    });

    test('une pièce de ligne part sous la clé du serveur', () {
      final s = _ligne(3);
      final piece = PieceAJoindre(nom: 'bac.pdf', octets: Uint8List(1));
      s.pieces['proof_document'] = piece;
      expect(s.fichiers, {'cursus-0-proof_document': piece});
    });

    test('retirer une pièce est un envoi, sans fichier', () {
      final s = _ligne(3);
      expect(s.deposees, contains('proof_document'));
      s.retraits.add('proof_document');
      expect(s.corps, {
        'cursus': [
          {'id': 3, 'proof_document_retirer': true},
        ],
      });
      expect(s.fichiers, isEmpty);
    });
  });

  group('Erreurs d’un refus', () {
    const titres = {TableauDossier.cursus: 'Cursus'};

    ApiException refus({Map<String, List<String>> erreurs = const {}, Object? tableaux}) =>
        ApiException(
          code: 'formulaire_invalide',
          message: 'Veuillez corriger les erreurs ci-dessous.',
          erreurs: erreurs,
          donnees: {'erreurs_tableaux': ?tableaux},
        );

    test('une erreur de ce bloc va sous son champ', () {
      final s =
          SaisieDossier(_formulaires(), const CibleBloc(BlocDossier.identite));
      final bandeau = s.poserErreurs(
          refus(erreurs: {'firstname': ['Obligatoire.']}), titres);
      expect(s.erreurs['firstname'], ['Obligatoire.']);
      expect(bandeau, ['Veuillez corriger les erreurs ci-dessous.']);
    });

    test('une erreur d’un autre bloc se nomme au bandeau', () {
      final s = SaisieDossier(
          _formulaires(), const CibleBloc(BlocDossier.coordonnees));
      final bandeau = s.poserErreurs(
          refus(erreurs: {'nationality': ['Choix invalide.']}), titres);
      expect(s.erreurs, isEmpty);
      expect(bandeau, contains('Nationalité : Choix invalide.'));
    });

    test('le rang de la ligne désigne ses erreurs, les autres vont au bandeau',
        () {
      final s = _ligne(8);
      final bandeau = s.poserErreurs(
        refus(tableaux: {
          'cursus': {
            'lignes': [
              {'establishment_autre': ['Précisez le nom.']},
              {'specialization': ['Obligatoire.']},
            ],
            'ensemble': ['Déclaré deux fois.'],
          },
        }),
        titres,
      );
      expect(s.erreurs, {'specialization': ['Obligatoire.']});
      expect(bandeau, contains('Cursus : Déclaré deux fois.'));
      expect(bandeau, contains('Cursus — Précisez le nom : Précisez le nom.'));
    });

    test('une ligne neuve vient après les lignes connues', () {
      final s = SaisieDossier(
          _formulaires(), const CibleLigne(TableauDossier.cursus));
      s.poserErreurs(
        refus(tableaux: {
          'cursus': {
            'lignes': [
              {},
              {},
              {'diploma': ['Obligatoire.']},
            ],
            'ensemble': [],
          },
        }),
        titres,
      );
      expect(s.erreurs, {'diploma': ['Obligatoire.']});
    });
  });

  group('Envoi', () {
    (EnseignantRepository, _Adaptateur) depot() {
      final adaptateur = _Adaptateur();
      final dio =
          Dio(BaseOptions(baseUrl: 'http://test/api/v1/portail-enseignant/'))
            ..httpClientAdapter = adaptateur;
      return (
        EnseignantRepository(ApiClient(
            espace: Espace.enseignant, stockage: _Stockage(), dio: dio)),
        adaptateur,
      );
    }

    test('sans fichier, l’envoi reste en JSON', () async {
      final (d, a) = depot();
      final r = await d.modifierDossier({'phone_number': '699000000'});
      expect(r.detail, 'Enregistré.');
      expect(a.requetes.single.path, 'profil/modifier/');
      expect(a.requetes.single.data, {'phone_number': '699000000'});
    });

    test('avec un fichier, les listes se postent en JSON dans le multipart',
        () async {
      final (d, a) = depot();
      await d.modifierDossier(
        {
          'cv_retirer': true,
          'cursus': [
            {'id': 3},
          ],
        },
        fichiers: {
          'cursus-0-proof_document':
              PieceAJoindre(nom: 'bac.pdf', octets: Uint8List(1)),
        },
      );
      final data = a.requetes.single.data as FormData;
      expect(Map.fromEntries(data.fields), {
        'cv_retirer': 'true',
        'cursus': '[{"id":3}]',
      });
      expect(data.files.single.key, 'cursus-0-proof_document');
    });
  });

  group('Écrans', () {
    testWidgets('le dossier offre la saisie de chaque bloc', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(800, 3000);
      addTearDown(tester.view.reset);
      final depot =
          _Depot(reponse: DossierEnseignant.depuisJson(_reponseProfil()));
      await tester.pumpWidget(_app(const DossierPage(), depot: depot));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Modifier'), findsNWidgets(3));
      expect(find.text('Ajouter un diplôme'), findsOneWidget);
      expect(find.text('Changer la photo'), findsNothing);
      expect(find.text('Ajouter une photo'), findsOneWidget);

      await tester.tap(find.text('BAC — Série D'));
      await tester.pumpAndSettle();
      expect(find.text('Modifier le diplôme'), findsOneWidget);
      expect(find.text('Lycée de Bafia'), findsOneWidget);
    });

    testWidgets('sans valeurs, le dossier reste en lecture', (tester) async {
      final depot = _Depot(
          reponse:
              DossierEnseignant.depuisJson(_reponseProfil(avecValeurs: false)));
      await tester.pumpWidget(_app(const DossierPage(), depot: depot));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Modifier'), findsNothing);
      expect(find.text('Ajouter un diplôme'), findsNothing);
    });

    testWidgets('choisir « Autres » révèle le champ libre, et l’envoi le porte',
        (tester) async {
      final depot = _Depot();
      final f = _formulaires();
      await tester.pumpWidget(_app(
        EditionDossierPage(
          titre: 'Modifier le diplôme',
          formulaires: f,
          cible: CibleLigne(
              TableauDossier.cursus, f.ligne(TableauDossier.cursus, 8)),
        ),
        depot: depot,
      ));

      expect(find.text('Précisez le nom'), findsNothing);
      await tester.tap(find.text('Université de Yaoundé I'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Autres (à préciser)'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Précisez le nom'), 'IUT de Bafia');
      await tester.ensureVisible(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(depot.envois.single, {
        'cursus': [
          {
            'id': 8,
            'establishment': _autres,
            'establishment_autre': 'IUT de Bafia',
          },
        ],
      });
    });

    testWidgets('un refus reste sur l’écran, l’erreur sous son champ',
        (tester) async {
      final depot = _Depot(
        refus: ApiException(
          code: 'formulaire_invalide',
          message: 'Veuillez corriger les erreurs ci-dessous.',
          donnees: const {
            'erreurs_tableaux': {
              'cursus': {
                'lignes': [
                  {},
                  {
                    'specialization': ['Ce champ est obligatoire.'],
                  },
                ],
                'ensemble': [],
              },
            },
          },
        ),
      );
      final f = _formulaires();
      await tester.pumpWidget(_app(
        EditionDossierPage(
          titre: 'Modifier le diplôme',
          formulaires: f,
          cible: CibleLigne(
              TableauDossier.cursus, f.ligne(TableauDossier.cursus, 8)),
        ),
        depot: depot,
      ));

      await tester.ensureVisible(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
      expect(find.text('Veuillez corriger les erreurs ci-dessous.'),
          findsOneWidget);
    });

    testWidgets('supprimer une ligne se confirme', (tester) async {
      final depot = _Depot();
      final f = _formulaires();
      await tester.pumpWidget(_app(
        EditionDossierPage(
          titre: 'Modifier le diplôme',
          formulaires: f,
          cible: CibleLigne(
              TableauDossier.cursus, f.ligne(TableauDossier.cursus, 3)),
        ),
        depot: depot,
      ));

      await tester.tap(find.byTooltip('Supprimer'));
      await tester.pumpAndSettle();
      expect(depot.envois, isEmpty);
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(depot.envois.single, {
        'cursus': [
          {'id': 3, 'supprimer': true},
        ],
      });
    });

    testWidgets('une pièce déposée se retire, et le retrait s’annule',
        (tester) async {
      final depot = _Depot();
      final f = _formulaires();
      await tester.pumpWidget(_app(
        EditionDossierPage(
          titre: 'Modifier le diplôme',
          formulaires: f,
          cible: CibleLigne(
              TableauDossier.cursus, f.ligne(TableauDossier.cursus, 3)),
        ),
        depot: depot,
      ));

      final retirer = find.text('Retirer le fichier actuel');
      await tester.ensureVisible(retirer);
      await tester.pumpAndSettle();
      await tester.tap(retirer);
      await tester.pump();
      expect(find.textContaining('sera retiré'), findsOneWidget);
      await tester.tap(find.text('Le conserver'));
      await tester.pump();
      expect(find.text('Retirer le fichier actuel'), findsOneWidget);
    });
  });
}
