import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/app/charte/charte.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/network/api_client.dart';
import 'package:ysem/core/network/endpoints.dart';
import 'package:ysem/core/storage/token_storage.dart';
import 'package:ysem/features/commun/piece_jointe.dart';
import 'package:ysem/features/enseignant/data/enseignant_repository.dart';
import 'package:ysem/features/enseignant/domain/epreuves.dart';
import 'package:ysem/features/enseignant/presentation/epreuves/epreuves_page.dart';
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

Map<String, dynamic> _sujet({
  bool sujet = true,
  bool corrige = true,
  List<String> manquantes = const [],
}) =>
    {
      'id': 1,
      'numero': 1,
      'a_sujet': sujet,
      'a_corrige': corrige,
      'langues_manquantes': manquantes,
      'modifiable': true,
    };

void main() {
  final t = AppLocalizationsFr();

  group('lecture', () {
    test('une épreuve lit sa campagne, ses versions et ses modèles', () {
      final m = MesEpreuves.depuisJson({
        'extensions_acceptees': ['.pdf', 'docx'],
        'formats_acceptes': 'PDF, Word',
        'depots': [
          {
            'id': 5,
            'cours': {'code': 'X', 'intitule': 'Compta'},
            'bilingue': true,
            'campagne': {'nb_sujets_requis': 2, 'corrige_obligatoire': true},
            'modeles': [
              {'numero': 1, 'langue': 'fr'},
              {'numero': 1, 'langue': 'en'},
              {'numero': 2, 'langue': 'fr'},
            ],
            'sujets': [
              {
                'id': 1,
                'numero': 1,
                'versions_sujet': [
                  {
                    'langue': 'fr',
                    'libelle': 'Version française',
                    'exigee': true,
                    'pieces': [
                      {'id': 9, 'nom': 'sujet.pdf', 'taille': 10},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      });
      expect(m.extensionsAcceptees, ['pdf', 'docx']);
      final d = m.depot(5)!;
      expect(d.modelesDu(1).map((e) => e.langue), ['fr', 'en']);
      expect(d.sujets.single.versions.single.pieces.single.nom, 'sujet.pdf');
      expect(m.depot(99), isNull);
    });

    test('un sujet n\'est complet qu\'avec ce que la campagne exige', () {
      expect(SujetEpreuve.depuisJson(_sujet()).estComplet(true), isTrue);
      expect(
          SujetEpreuve.depuisJson(_sujet(corrige: false)).estComplet(true),
          isFalse);
      expect(
          SujetEpreuve.depuisJson(_sujet(corrige: false)).estComplet(false),
          isTrue);
      expect(
          SujetEpreuve.depuisJson(_sujet(manquantes: ['en'])).estComplet(false),
          isFalse);
      expect(
          SujetEpreuve.depuisJson(_sujet(sujet: false)).estComplet(false),
          isFalse);
    });
  });

  group('états', () {
    test('complet, en retard, attendu, puis l\'arbitrage', () {
      expect(
        etatDeLaDemande(
            t,
            const DepotEpreuve(
                id: 1, complet: true, statutDelaiLibelle: 'Déposé')).single,
        ('Déposé', TonPastille.succes),
      );
      expect(
        etatDeLaDemande(
            t, const DepotEpreuve(id: 1, enRetard: true, joursDeRetard: 2))
            .single
            .$1,
        t.enRetardDeJours(2),
      );
      final enReprise = etatDeLaDemande(
          t, const DepotEpreuve(id: 1, statutValidation: 'revision'));
      expect(enReprise.first.$1, t.depotAttendu);
      expect(enReprise.last, (t.aReprendre, TonPastille.alerte));
    });
  });

  group('envois', () {
    test('toutes les pièces d\'un sujet partent d\'un seul envoi', () async {
      final (depot, a) = _depot({'detail': 'Sujet n° 1 déposé.'});
      final message = await depot.deposerSujet(
        1,
        fichiersSujet: [PieceAJoindre(nom: 'fr.pdf', octets: Uint8List(1))],
        fichiersSujetEn: [PieceAJoindre(nom: 'en.pdf', octets: Uint8List(1))],
        fichiersCorrige: [PieceAJoindre(nom: 'c.pdf', octets: Uint8List(1))],
        intitule: 'Étude de cas',
        dureeMinutes: '120',
        commentaire: '',
      );
      expect(message, 'Sujet n° 1 déposé.');
      final corps = a.requetes.single.data as FormData;
      expect(corps.files.map((f) => f.key),
          ['fichiers_sujet', 'fichiers_sujet_en', 'fichiers_corrige']);
      expect(Map.fromEntries(corps.fields), {
        'intitule': 'Étude de cas',
        'duree_minutes': '120',
        'commentaire': '',
      });
      expect(a.requetes.single.path, contains('epreuves/sujets/1/'));
    });

    test('un modèle se demande par épreuve, numéro et langue', () {
      expect(RoutesEnseignant.epreuveModele(5, 2, 'en'),
          'epreuves/5/modele/2/en/');
    });
  });
}
