import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/app/charte/charte.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/network/api_client.dart';
import 'package:ysem/core/storage/token_storage.dart';
import 'package:ysem/features/commun/piece_jointe.dart';
import 'package:ysem/features/enseignant/data/enseignant_repository.dart';
import 'package:ysem/features/enseignant/domain/documents.dart';
import 'package:ysem/features/enseignant/presentation/documents/documents_page.dart';
import 'package:ysem/l10n/app_localizations_fr.dart';

class _Stockage extends Fake implements TokenStorage {
  @override
  Future<Jetons?> lire(Espace espace) async => null;
}

class _Adaptateur implements HttpClientAdapter {
  _Adaptateur(this.corps);

  final Map<String, dynamic> corps;
  final requetes = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requetes.add(options);
    return ResponseBody.fromString(jsonEncode(corps), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

(EnseignantRepository, _Adaptateur) _depot(Map<String, dynamic> corps) {
  final adaptateur = _Adaptateur(corps);
  final dio =
      Dio(BaseOptions(baseUrl: 'http://test/api/v1/portail-enseignant/'))
        ..httpClientAdapter = adaptateur;
  return (
    EnseignantRepository(
        ApiClient(espace: Espace.enseignant, stockage: _Stockage(), dio: dio)),
    adaptateur,
  );
}

PlanEnLigne _plan({
  List<Map<String, dynamic>> chapitres = const [],
  List<Map<String, dynamic>> programme = const [],
  int seances = 3,
}) =>
    PlanEnLigne.depuisJson({
      'plan': {'id': 7, 'statut': 'brouillon', 'objectifs': 'Savoir'},
      'modifiable': true,
      'nb_seances_attendues': seances,
      'lignes': {
        'chapitres': chapitres,
        'travaux': <dynamic>[],
        'programme': programme,
      },
    });

void main() {
  final t = AppLocalizationsFr();

  group('brouillon du plan', () {
    test('les séances manquantes sont amorcées, sans rien à envoyer', () {
      final b = BrouillonPlan.depuis(_plan(programme: [
        {
          'id': 40,
          'numero': 2,
          'theme': 'Bilan',
          'chapitre': null,
          'seance': {'x': 1},
        },
      ]));
      expect(b.lignesTriees(TablesPlan.programme).map((l) => l['numero']),
          ['1', '2', '3']);
      expect(b.seancesRemplies, 1);
      expect(b.modifie, isFalse);
      expect(b.envoi()['programme'], isEmpty);
    });

    test('une séance amorcée remplie part sans id, une ligne intacte ne part pas',
        () {
      final b = BrouillonPlan.depuis(_plan(programme: [
        {'id': 40, 'numero': 2, 'theme': 'Bilan'},
      ]));
      b.tables[TablesPlan.programme]!
          .firstWhere((l) => l['numero'] == '1')
          .valeurs = {'numero': '1', 'theme': 'Accueil'};
      expect(b.modifie, isTrue);
      expect(b.envoi()['programme'], [
        {'numero': '1', 'theme': 'Accueil'},
      ]);
    });

    test('retirer : une ligne existante part en supprimer et se restaure', () {
      final b = BrouillonPlan.depuis(_plan(chapitres: [
        {'id': 5, 'ordre': 1, 'titre': 'Intro'},
      ]));
      final ligne = b.tables[TablesPlan.chapitres]!.single;
      b.retirer(TablesPlan.chapitres, ligne);
      expect(b.envoi()['chapitres'], [
        {'id': 5, 'supprimer': true},
      ]);
      ligne.supprimee = false;
      expect(b.modifie, isFalse);
    });

    test('retirer une ligne jamais envoyée la fait simplement disparaître', () {
      final b = BrouillonPlan.depuis(_plan());
      b.ajouter(TablesPlan.chapitres, {'ordre': '1', 'titre': 'Intro'});
      b.retirer(
          TablesPlan.chapitres, b.tables[TablesPlan.chapitres]!.single);
      expect(b.envoi()['chapitres'], isEmpty);
      expect(b.modifie, isFalse);
    });

    test('le prochain numéro suit le plus grand', () {
      final b = BrouillonPlan.depuis(_plan(chapitres: [
        {'id': 5, 'ordre': 4, 'titre': 'A'},
      ]));
      expect(b.prochainNumero(TablesPlan.chapitres), '5');
    });

    test('transmettre et rattacher les thèmes se disent à l\'envoi', () {
      final b = BrouillonPlan.depuis(_plan());
      expect(b.envoi().containsKey('action'), isFalse);
      expect(b.envoi(transmettre: true)['action'], 'transmettre');
      b.appliquerProposition(const {});
      expect(b.envoi()['depuis_proposition'], isTrue);
    });

    test('les erreurs suivent l\'ordre du serveur : existantes, puis nouvelles',
        () {
      final b = BrouillonPlan.depuis(_plan(programme: [
        {'id': 40, 'numero': 3, 'theme': 'Fin'},
      ]));
      final amorce = b.tables[TablesPlan.programme]!
          .firstWhere((l) => l['numero'] == '1');
      amorce.valeurs = {'numero': '1', 'theme': 'Accueil'};
      b.envoi();
      final comptes = b.poserErreurs({
        'erreurs_tableaux': {
          'programme': {
            'lignes': [
              {},
              {
                'theme': ['Trop long.'],
              },
            ],
            'ensemble': ['La séance 1 figure deux fois.'],
          },
        },
      });
      expect(comptes, {TablesPlan.programme: 1});
      expect(amorce.erreurs['theme'], ['Trop long.']);
      expect(
          b.tables[TablesPlan.programme]!
              .firstWhere((l) => l.id == 40)
              .erreurs,
          isEmpty);
    });

    test('les erreurs d\'ensemble se lisent à part', () {
      expect(
        BrouillonPlan.erreursDEnsemble({
          'erreurs_tableaux': {
            'programme': {
              'lignes': [],
              'ensemble': ['Numérotez de 1 à 3.'],
            },
          },
        }),
        ['Numérotez de 1 à 3.'],
      );
    });

    group('proposition de l\'assistant', () {
      test('elle réécrit par id, ajoute le reste, et n\'envoie rien d\'elle-même',
          () {
        final b = BrouillonPlan.depuis(_plan(chapitres: [
          {'id': 5, 'ordre': 1, 'titre': 'Ancien', 'competence_visee': 'X'},
        ]));
        b.appliquerProposition({
          'objectifs': 'Nouveaux',
          'chapitres': [
            {'id': 5, 'ordre': 1, 'titre': 'Nouveau'},
            {'ordre': 2, 'titre': 'Deuxième'},
          ],
          'programme': <dynamic>[],
          'travaux': <dynamic>[],
          'depuis_proposition': true,
        });
        expect(b.objectifs, 'Nouveaux');
        final existant = b.tables[TablesPlan.chapitres]!.first;
        expect(existant['titre'], 'Nouveau');
        expect(existant['competence_visee'], 'X');
        expect(b.tables[TablesPlan.chapitres]!.length, 2);
        expect(b.depuisProposition, isTrue);
      });

      test('une séance remplit l\'amorce de son numéro, sans doublon', () {
        final b = BrouillonPlan.depuis(_plan());
        b.appliquerProposition({
          'programme': [
            {'numero': 2, 'theme': 'Bilan', 'chapitre': null},
          ],
        });
        final lignes = b.lignesTriees(TablesPlan.programme);
        expect(lignes.map((l) => l['numero']), ['1', '2', '3']);
        expect(lignes[1]['theme'], 'Bilan');
        expect(b.seancesRemplies, 1);
      });

      test('une séance renumérotée ne laisse pas d\'amorce en double', () {
        final b = BrouillonPlan.depuis(_plan(programme: [
          {'id': 40, 'numero': 3, 'theme': 'Fin'},
        ]));
        b.appliquerProposition({
          'programme': [
            {'id': 40, 'numero': 1, 'theme': 'Accueil'},
          ],
        });
        final numeros =
            b.lignesTriees(TablesPlan.programme).map((l) => l['numero']);
        expect(numeros, ['1', '2', '3']);
      });
    });
  });

  group('lecture', () {
    test('une ligne lit son plan, ses dépôts et leurs pièces', () {
      final d = DocumentsDeCours.depuisJson({
        'assistant_plan': true,
        'plan_pages_max': 8,
        'plan_extensions': ['.pdf', '.docx'],
        'lignes': [
          {
            'plan': {'id': 7, 'statut': 'brouillon', 'saisie_attendue': true},
            'cours': {'code': 'X', 'intitule': 'Compta'},
            'niveau': {'nom': 'Licence 2'},
            'specialite': null,
            'programme': {'nom': 'Gestion'},
            'depot_plan': {
              'id': 3,
              'pieces': [
                {'id': 1, 'nom': 'plan.pdf', 'taille': 2048},
              ],
            },
            'depot_support': null,
          },
        ],
      });
      expect(d.planExtensions, ['pdf', 'docx']);
      final l = d.lignePourPlan(7)!;
      expect(l.cohorte, 'Licence 2 · Gestion');
      expect(l.depotPlan!.pieces.single.nom, 'plan.pdf');
      expect(l.depotSupport, isNull);
      expect(d.lignePourPlan(99), isNull);
    });

    test('le plan fermé n\'ouvre pas la saisie', () {
      final p = PlanEnLigne.depuisJson({
        'plan': {'id': 7, 'statut': 'valide'},
        'modifiable': false,
        'modification_apres_validation': false,
        'lignes': {},
        'champs': {},
      });
      expect(p.saisieOuverte, isFalse);
      expect(p.champsTables[TablesPlan.chapitres]!.champs, isEmpty);
    });

    test('la suite d\'un dépôt mène au plan', () {
      final r = ResultatDepot.depuisJson({
        'detail': 'Reçu.',
        'suite': {'plan': 7, 'assistant': true, 'piece_a_lire': 12},
      });
      expect(r.suite!.pieceALire, 12);
      expect(ResultatDepot.depuisJson(const {'suite': null}).suite, isNull);
    });
  });

  group('états', () {
    LigneDocuments ligne(Map<String, dynamic> plan,
            {Map<String, dynamic>? depot}) =>
        LigneDocuments.depuisJson({'plan': plan, 'depot_plan': depot});

    test('la décision du service prime sur ce qu\'il reste à faire', () {
      final etats = etatDuPlan(
          t,
          ligne({
            'id': 1,
            'statut': 'valide',
            'statut_libelle': 'Validé',
            'saisie_attendue': true,
          }));
      expect(etats.map((e) => e.$1), ['Validé', t.publieAuxEtudiants]);
    });

    test('un fichier reçu ne vaut pas dépôt quand la saisie est attendue', () {
      final etats = etatDuPlan(
          t,
          ligne({'id': 1, 'statut': 'brouillon', 'saisie_attendue': true},
              depot: {
                'id': 3,
                'pieces': [
                  {'id': 1, 'nom': 'a.pdf'},
                ],
              }));
      expect(etats.single.$1, t.fichierRecuPlanATransmettre);
    });

    test('un renvoi se lit avant le reste', () {
      final etats = etatDuPlan(
          t,
          ligne({
            'id': 1,
            'statut': 'brouillon',
            'en_correction': true,
            'saisie_attendue': true,
          }));
      expect(etats.single.$1, t.aCorriger);
    });

    test('support : retard, hors délai en alerte, attente de validation', () {
      expect(
        etatDuSupport(t, const DepotDocument(id: 1, enRetard: true, joursDeRetard: 3))
            .single,
        (t.enRetardDeJours(3), TonPastille.alerte),
      );
      final depose = etatDuSupport(
        t,
        DepotDocument(
          id: 1,
          deposeLe: DateTime(2026, 11, 2),
          statut: 'hors_delai',
          statutLibelle: 'Déposé hors délai',
        ),
      );
      expect(depose.first.$2, TonPastille.alerte);
      expect(depose.last.$1, t.enAttenteDeValidation);
    });
  });

  group('envois', () {
    test('un dépôt poste chaque pièce sous « fichiers », sans effacer le reste',
        () async {
      final (depot, a) = _depot({'detail': 'Déposé.', 'suite': null});
      final r = await depot.deposerDocument(3, pieces: [
        PieceAJoindre(nom: 'a.pdf', octets: Uint8List(2)),
        PieceAJoindre(nom: 'b.pdf', octets: Uint8List(2)),
      ]);
      expect(r.detail, 'Déposé.');
      final corps = a.requetes.single.data as FormData;
      expect(corps.files.map((f) => f.key), ['fichiers', 'fichiers']);
      expect(corps.fields, isEmpty);
      expect(a.requetes.single.path, contains('documents/depots/3/'));
    });

    test('le projet ne part que s\'il est demandé', () async {
      final (depot, a) = _depot({'detail': 'ok'});
      await depot.deposerDocument(3, projetPrevu: false, projetDescription: '');
      final corps = a.requetes.single.data as FormData;
      expect(Map.fromEntries(corps.fields), {
        'projet_fin_cours': 'false',
        'projet_fin_cours_description': '',
      });
    });

    test('l\'import s\'accorde plus de temps et rend la proposition', () async {
      final (depot, a) = _depot({
        'detail': 'Analysé.',
        'proposition': {'objectifs': 'X'},
      });
      final (message, proposition) = await depot.importerPlan(7, document: 12);
      expect(message, 'Analysé.');
      expect(proposition['objectifs'], 'X');
      expect(a.requetes.single.receiveTimeout, const Duration(minutes: 3));
      expect(Map.fromEntries((a.requetes.single.data as FormData).fields),
          {'document': '12'});
    });

    test('le serveur dit si le plan est parti', () async {
      final (depot, _) = _depot({
        'detail': 'Enregistré, non transmis.',
        'issue': 'non_transmis',
        'manques': ['1 séance sur 3'],
      });
      final r = await depot.enregistrerPlan(7, const {'action': 'transmettre'});
      expect(r.transmis, isFalse);
      expect(r.manques, ['1 séance sur 3']);
    });
  });
}
