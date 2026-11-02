import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/models/discussions.dart';
import 'package:ysem/core/models/messagerie.dart';
import 'package:ysem/core/network/api_client.dart';
import 'package:ysem/core/providers.dart';
import 'package:ysem/core/storage/token_storage.dart';
import 'package:ysem/features/commun/fil/fil.dart';
import 'package:ysem/features/enseignant/data/enseignant_repository.dart';
import 'package:ysem/features/enseignant/domain/cours.dart';

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

const _fil = {
  'classe': {
    'cle': 'g-17',
    'cours': {'code': 'GES201', 'intitule': 'Comptabilité'},
    'cohorte': 'Licence 2 · Gestion',
    'effectif': 31,
    'ouverte': true,
    'groupe': {'id': 4},
  },
  'lecteur': 'lecturer:LEC0042',
  'messages': [
    {'id': 1, 'corps': 'Bonjour', 'auteur': 'Awa', 'auteur_cle': 'student:11'},
    {'id': 2, 'corps': 'Bonjour à tous', 'auteur': 'Paul', 'auteur_cle': 'lecturer:LEC0042'},
  ],
  'pieces_jointes': {'maximum': 5, 'extensions': ['pdf'], 'champ': 'fichiers'},
  'avertissement': 'Toute la classe lit ces messages.',
};

void main() {
  test('Une source de fil dit son espace', () {
    expect(SourceFil.espaceDe(SourceFil.guichet), Espace.etudiant);
    expect(SourceFil.espaceDe(SourceFil.classe('k')), Espace.etudiant);
    expect(SourceFil.espaceDe(SourceFil.classeEnseignant('k')), Espace.enseignant);
    expect(SourceFil.classeDe(Espace.enseignant, 'k'), 'enseignant:k');
    expect(SourceFil.classeDe(Espace.etudiant, 'k'), 'classe:k');
  });

  test("Le fil d'une classe passe par l'API de l'enseignant ; ses messages sont les siens",
      () async {
    final (depot, adaptateur) = _depot(_fil);
    final conteneur = ProviderContainer(overrides: [
      enseignantRepositoryProvider.overrideWithValue(depot),
    ]);
    addTearDown(conteneur.dispose);
    final source = SourceFil.classeEnseignant('g-17');
    conteneur.listen(filProvider(source), (_, _) {});

    final etat = await conteneur.read(filProvider(source).future);
    expect(adaptateur.requetes.single.path, 'discussions/g-17/messages/');
    expect(etat.fil.interlocuteur, 'Comptabilité');
    expect(etat.fil.sousTitre, 'Licence 2 · Gestion');
    expect(etat.fil.accuse, isFalse);
    expect(etat.fil.lectureSeule, isFalse);
    // Le rien-à-dire de présence : l'enseignant n'a personne à guetter.
    expect(etat.fil.enLigne, isNull);
    expect(etat.messages.first.estDe(etat.fil.lecteur), isFalse);
    expect(etat.messages.last.estDe(etat.fil.lecteur), isTrue);
  });

  test('Envoi, réaction et pièce : les routes de l\'espace enseignant', () async {
    final (envoi, a1) = _depot({
      'message': {'id': 3, 'corps': 'Cours reporté', 'auteur_cle': 'lecturer:LEC0042'},
    });
    final message =
        await envoi.envoyerDiscussion('g-17', corps: 'Cours reporté', repondA: 1);
    expect(message.id, 3);
    expect(a1.requetes.single.path, 'discussions/g-17/messages/');
    final donnees = a1.requetes.single.data as FormData;
    expect(Map.fromEntries(donnees.fields),
        {'corps': 'Cours reporté', 'repond_a': '1'});

    final (reaction, a2) = _depot({'reactions': {}});
    await reaction.reagirDiscussion(3, reactionJaime);
    expect(a2.requetes.single.path, 'discussions/messages/3/reaction/');
    expect(a2.requetes.single.data, {'valeur': reactionJaime});
  });

  test('Discussions : effectif rendu, passées en lecture seule', () {
    final d = Discussions.depuisJson({
      'classes': [
        {
          'cle': 'g-17',
          'cours': {'code': 'GES201', 'intitule': 'Comptabilité'},
          'cohorte': 'Licence 2',
          'effectif': 31,
          'ouverte': true,
          'groupe': {'non_lus': 2},
        },
      ],
      'discussions_passees': [
        {'cle': 'g-3', 'cours': {'intitule': 'Audit'}, 'effectif': null, 'ouverte': false, 'groupe': null},
      ],
    });
    expect(d.classes.single.effectif, 31);
    expect(d.classes.single.nonLus, 2);
    expect(d.passees.single.ouverte, isFalse);
    expect(d.passees.single.effectif, isNull);
  });

  test('Mes enseignements : les chiffres du service', () {
    final e = Enseignements.depuisJson({
      'avancement': [
        {
          'cours': {'intitule': 'Comptabilité'},
          'niveau': {'nom': 'Licence 2'},
          'classe': 'Section francophone',
          'seances_faites': 6,
          'seances_prevues': 10,
          'seances_non_suivies': 1,
          'chapitres_faits': 3,
          'chapitres_prevus': 8,
          'taux_seances': 0.6,
          'taux_chapitres': 0.375,
          'interpretation_libelle': 'En cours',
          'tonalite': 'warning',
          'derniere_seance': '2026-10-28',
        },
        {'cours': {'intitule': 'Audit'}, 'taux_seances': null, 'taux_chapitres': null, 'tonalite': 'dark'},
      ],
      'nb_seances': 12,
      'nb_absences': 1,
      'seances': [
        {
          'date': '2026-10-28',
          'cours': {'intitule': 'Comptabilité'},
          'statut_libelle': 'Tenue',
          'constat_libelle': 'RAS',
          'chapitre_atteint': 3,
          'cloturee_automatiquement': true,
        },
      ],
      'rattrapages': [
        {'id': 1, 'ouverte': true},
        {'id': 2, 'ouverte': false},
      ],
      'retours_partages': [
        {'cours': 'Comptabilité', 'constat': 'Rythme soutenu', 'action_menee': 'Séance de révision'},
      ],
    });
    expect(e.avancement.first.tauxChapitres, 0.375);
    expect(e.avancement.first.seancesNonSuivies, 1);
    expect(e.avancement.last.tauxSeances, isNull);
    expect(e.rattrapagesOuverts, 1);
    expect(e.seances.single.clotureeAutomatiquement, isTrue);
    expect(e.retours.single.actionMenee, 'Séance de révision');
  });
}
