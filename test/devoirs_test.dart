import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/app/theme.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/models/devoirs.dart';
import 'package:ysem/core/network/api_client.dart';
import 'package:ysem/core/providers.dart';
import 'package:ysem/core/storage/token_storage.dart';
import 'package:ysem/features/commun/piece_jointe.dart';
import 'package:ysem/features/enseignant/data/enseignant_repository.dart';
import 'package:ysem/features/enseignant/presentation/devoirs/formulaire_devoir_page.dart';
import 'package:ysem/features/enseignant/presentation/sections.dart';
import 'package:ysem/features/etudiant/data/etudiant_repository.dart';
import 'package:ysem/features/etudiant/presentation/devoirs/devoirs_page.dart';
import 'package:ysem/features/etudiant/presentation/sections.dart';
import 'package:ysem/l10n/app_localizations.dart';

class _Stockage extends Fake implements TokenStorage {
  @override
  Future<Jetons?> lire(Espace espace) async => null;
}

/// Répond selon « VERBE chemin » ; garde chaque requête reçue.
class _Adaptateur implements HttpClientAdapter {
  _Adaptateur(this.reponses);

  final Map<String, Object?> reponses;
  final requetes = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requetes.add(options);
    final cle = '${options.method} ${options.uri.path.split('/api/v1/').last.split('/').skip(1).join('/')}';
    final corps = reponses[cle];
    if (corps == null) {
      return ResponseBody.fromString('', 204);
    }
    return ResponseBody.fromString(jsonEncode(corps), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _client(Espace espace, _Adaptateur adaptateur) {
  final base = espace == Espace.etudiant ? 'portail-etudiant' : 'portail-enseignant';
  final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1/$base/'))
    ..httpClientAdapter = adaptateur;
  return ApiClient(espace: espace, stockage: _Stockage(), dio: dio);
}

const _classe = {
  'cle': '4-17-2-1-0-0',
  'cours': {'code': 'GES201', 'intitule': 'Comptabilité'},
  'cohorte': 'Licence 2 · Gestion',
};

Map<String, dynamic> _devoir({List<Map<String, dynamic>> pieces = const []}) => {
      'id': 12,
      'titre': 'Bilan simplifié',
      'consignes': 'Établir le bilan de la société X.',
      'classe': _classe,
      'enseignant': 'Paul Ayang',
      'date_limite': '2026-11-18T08:00:00+01:00',
      'echeance_passee': false,
      'mode': 'groupe',
      'mode_libelle': 'En groupe',
      'groupement': {'id': 3, 'nom': 'Groupes de TP'},
      'note_sur': 20.0,
      'statut': 'publie',
      'statut_libelle': 'Publié',
      'publie_le': '2026-11-10T09:00:00+01:00',
      'corrections_publiees_le': null,
      'pieces': pieces,
    };

const _piece = {
  'id': 5,
  'nom': 'enonce.pdf',
  'taille': 2048,
  'taille_lisible': '2,0 Ko',
  'type_mime': 'application/pdf',
  'previsualisable': true,
  'url': '/api/v1/portail-enseignant/devoirs/pieces/5/',
};

Map<String, dynamic> _entree() => {
      'devoir': _devoir(),
      'etat': 'a_rendre',
      'etat_libelle': 'À rendre',
      'groupe': {
        'id': 7,
        'nom': 'Groupe 1',
        'membres': [
          {'id': 1, 'matricule': 'M1', 'nom': 'KAFFO', 'prenom': 'Ramiro'},
        ],
      },
      'sujet': 'Société Alpha',
      'rendu': null,
      'correction_visible': false,
      'correction': null,
      'modifiable': true,
    };

Widget _app(Widget page, List<Override> surcharges) => ProviderScope(
      overrides: surcharges,
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
  group('Adresses des notifications', () {
    test("la fiche d'un devoir ouvre ce devoir", () {
      expect(sectionDeLAdresse('/portail-etudiant/mes-devoirs/12/'), 'devoirs?devoir=12');
      expect(sectionDeLAdresse('https://si.ysem.education/portail-etudiant/mes-devoirs/12/#rendu'),
          'devoirs?devoir=12');
      expect(sectionEnseignantDeLAdresse('/enseignants/mes-devoirs/12/'), 'devoirs?devoir=12');
    });

    test('la liste et les pièces mènent à la liste', () {
      expect(sectionDeLAdresse('/portail-etudiant/mes-devoirs/'), 'devoirs');
      expect(sectionDeLAdresse('/portail-etudiant/mes-devoirs/pieces/3/'), 'devoirs');
      expect(sectionEnseignantDeLAdresse('/enseignants/mes-devoirs/groupes/4/'), 'devoirs');
      expect(sectionEnseignantDeLAdresse('/enseignants/mes-devoirs/12/modifier/'), 'devoirs');
    });
  });

  group('Modèles', () {
    test("entrée de l'étudiant : groupe, sujet, limites", () {
      final entree = EntreeDevoir.depuisJson({
        ..._entree(),
        'pieces_jointes': {'maximum': 5, 'extensions': ['pdf', 'docx'], 'champ': 'fichiers'},
      });
      expect(entree.devoir.estDeGroupe, isTrue);
      expect(entree.devoir.estNote, isTrue);
      expect(entree.devoir.cleClasse, '4-17-2-1-0-0');
      expect(entree.groupe!.membres.single.nomComplet, 'KAFFO Ramiro');
      expect(entree.sujet, 'Société Alpha');
      expect(entree.limites.extensions, ['pdf', 'docx']);
    });

    test("fiche de l'enseignant : synthèse, lignes, versement", () {
      final complet = DevoirComplet.depuisJson({
        ..._devoir(pieces: [_piece]),
        'synthese': {'attendus': 6, 'rendus': 4, 'en_retard': 1, 'a_corriger': 3},
        'lignes': [
          {
            'cible': 'g7',
            'libelle': 'Groupe 1',
            'etudiant': null,
            'groupe': {'id': 7, 'nom': 'Groupe 1', 'membres': []},
            'sujet': '',
            'rendu': {
              'id': 2,
              'texte': 'Voir pièce',
              'rendu_le': '2026-11-17T20:00:00+01:00',
              'en_retard': false,
              'nb_pieces': 1,
              'pieces': [],
              'statut_correction': 'corrige',
              'statut_correction_libelle': 'Corrigé',
              'note': 14.5,
              'commentaire': 'Bien',
            },
          },
        ],
        'fige': true,
        'etudiants_sans_groupe': [
          {'id': 9, 'matricule': 'M9', 'nom': 'NGA', 'prenom': 'Alice'},
        ],
        'versement': {
          'controle': null,
          'feuilles': [{'id': 31, 'libelle': 'Comptabilité — Licence 2'}],
          'types_controle': [{'id': 1, 'libelle': 'Devoir'}],
        },
        'avertissement': {'detail': 'Deux inscrits sans groupe.', 'code': 'sans_groupe'},
      });
      expect(complet.rendus, 4);
      expect(complet.aCorriger, 3);
      expect(complet.lignes.single.rendu!.note, 14.5);
      expect(complet.sansGroupe.single.nomComplet, 'NGA Alice');
      expect(complet.feuilles.single.id, 31);
      expect(complet.avertissement, 'Deux inscrits sans groupe.');
      expect(complet.devoir.pieces.single.nom, 'enonce.pdf');
    });
  });

  group('Envois', () {
    test('un rendu part en multipart : texte et fichiers', () async {
      final adaptateur = _Adaptateur({'POST devoirs/12/rendu/': _entree()});
      final depot = EtudiantRepository(_client(Espace.etudiant, adaptateur));
      await depot.rendreDevoir(12,
          texte: 'Ma réponse',
          pieces: [PieceAJoindre(nom: 'bilan.pdf', octets: Uint8List.fromList([1, 2, 3]))]);
      final donnees = adaptateur.requetes.single.data as FormData;
      expect(Map.fromEntries(donnees.fields), {'texte': 'Ma réponse'});
      expect(donnees.files.single.key, 'fichiers');
      expect(donnees.files.single.value.filename, 'bilan.pdf');
    });

    test('un devoir avec pièces : groupes répétés, sujet par groupe', () async {
      final adaptateur = _Adaptateur({'POST devoirs/': {..._devoir(), 'synthese': {}}});
      final depot = EnseignantRepository(_client(Espace.enseignant, adaptateur));
      await depot.creerDevoir({
        'classe': '4-17-2-1-0-0',
        'titre': 'Bilan',
        'mode': 'groupe',
        'groupes': [7, 8],
        'sujets': {'7': 'Alpha'},
        'noter': true,
      }, pieces: [PieceAJoindre(nom: 'enonce.pdf', octets: Uint8List.fromList([1]))]);
      final donnees = adaptateur.requetes.single.data as FormData;
      expect(donnees.fields.where((c) => c.key == 'groupes').map((c) => c.value), ['7', '8']);
      expect(donnees.fields.firstWhere((c) => c.key == 'sujet_7').value, 'Alpha');
      expect(donnees.fields.firstWhere((c) => c.key == 'noter').value, 'true');
      expect(donnees.files.single.key, 'fichiers');
    });

    test('une correction part en JSON, sous « corrections »', () async {
      final adaptateur = _Adaptateur({'POST devoirs/12/corrections/': {..._devoir(), 'synthese': {}}});
      final depot = EnseignantRepository(_client(Espace.enseignant, adaptateur));
      await depot.corrigerDevoir(12, [
        {'cible': 's1', 'statut': 'corrige', 'note': '15', 'commentaire': ''},
      ]);
      final corps = adaptateur.requetes.single.data as Map<String, dynamic>;
      expect((corps['corrections'] as List).single['cible'], 's1');
    });
  });

  group('Écrans', () {
    testWidgets("la notification d'un devoir ouvre sa fiche par-dessus la liste", (tester) async {
      final adaptateur = _Adaptateur({
        'GET devoirs/': {
          'blocs': [
            {'cle': 'a_rendre', 'titre': 'À rendre', 'vide': '', 'devoirs': [_entree()]},
          ],
          'a_rendre': 1,
        },
        'GET devoirs/12/': _entree(),
      });
      await tester.pumpWidget(_app(const DevoirsPage(devoirInitial: 12), [
        etudiantRepositoryProvider
            .overrideWithValue(EtudiantRepository(_client(Espace.etudiant, adaptateur))),
      ]));
      await tester.pumpAndSettle();

      // La fiche : sujet du groupe et bouton de rendu.
      expect(find.text('Société Alpha'), findsOneWidget);
      expect(find.text('Rendre le devoir'), findsOneWidget);

      Navigator.of(tester.element(find.text('Société Alpha'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('À rendre'), findsWidgets);
      expect(find.text('Rendre le devoir'), findsNothing);
    });

    testWidgets('une pièce des consignes se retire depuis la modification', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final adaptateur = _Adaptateur({
        'GET devoirs/prochaines-seances/': {
          'date_limite_proposee': '2026-11-18T08:00:00+01:00',
          'seances': [],
          'groupements': [],
        },
      });
      final complet = DevoirComplet.depuisJson({..._devoir(pieces: [_piece]), 'mode': 'individuel'});
      await tester.pumpWidget(_app(
        FormulaireDevoirPage(
          classe: const ClasseDevoir(cle: '4-17-2-1-0-0', coursIntitule: 'Comptabilité'),
          devoir: complet,
        ),
        [
          enseignantRepositoryProvider
              .overrideWithValue(EnseignantRepository(_client(Espace.enseignant, adaptateur))),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('enonce.pdf'), findsOneWidget);

      await tester.tap(find.byTooltip('Retirer'));
      await tester.pumpAndSettle();
      // Confirmation, puis DELETE de la pièce.
      await tester.tap(find.widgetWithText(FilledButton, 'Retirer'));
      await tester.pumpAndSettle();

      expect(find.text('enonce.pdf'), findsNothing);
      final retrait = adaptateur.requetes.where((r) => r.method == 'DELETE').single;
      expect(retrait.uri.path, endsWith('devoirs/pieces/5/'));
    });
  });
}
