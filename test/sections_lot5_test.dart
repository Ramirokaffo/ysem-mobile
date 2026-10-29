import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/network/api_client.dart';
import 'package:ysem/core/providers.dart';
import 'package:ysem/core/storage/token_storage.dart';
import 'package:ysem/features/commun/piece_jointe.dart';
import 'package:ysem/features/etudiant/application/messagerie.dart';
import 'package:ysem/features/etudiant/data/etudiant_repository.dart';
import 'package:ysem/features/etudiant/domain/messagerie.dart';
import 'package:ysem/features/etudiant/domain/suggestions.dart';

class _Stockage extends Fake implements TokenStorage {
  @override
  Future<Jetons?> lire(Espace espace) async => null;
}

class _Adaptateur implements HttpClientAdapter {
  _Adaptateur(this.corps);

  final Map<String, dynamic> corps;
  RequestOptions? requete;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requete = options;
    return ResponseBody.fromString(jsonEncode(corps), 201, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

(EtudiantRepository, _Adaptateur) _depot(Map<String, dynamic> corps) {
  final adaptateur = _Adaptateur(corps);
  final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1/portail-etudiant/'))
    ..httpClientAdapter = adaptateur;
  return (
    EtudiantRepository(
        ApiClient(espace: Espace.etudiant, stockage: _Stockage(), dio: dio)),
    adaptateur,
  );
}

MessageFil _m(int id, {String camp = 'scolarite', String corps = ''}) =>
    MessageFil(id: id, camp: camp, corps: corps.isEmpty ? 'M$id' : corps);

/// Dépôt factice : un fil de 50 messages (lot plein), puis 2 plus anciens.
class _DepotFactice extends Fake implements EtudiantRepository {
  int lectures = 0;

  @override
  Future<FilMessages> messages({int? avant}) async {
    lectures++;
    if (avant != null) {
      return FilMessages(messages: [_m(1), _m(2)]);
    }
    return FilMessages(
      interlocuteur: 'Service de la scolarité',
      messages: [for (var i = 11; i <= 60; i++) _m(i)],
    );
  }

  @override
  Future<MessageFil> envoyerMessage(
          {required String corps,
          List<PieceAJoindre> pieces = const [],
          int? repondA}) async =>
      MessageFil(id: 99, camp: campEtudiant, corps: corps);

  @override
  Future<Map<String, ResumeReaction>> reagirMessage(
          int id, String valeur) async =>
      {valeur: const ResumeReaction(nombre: 1, lecteurs: [campEtudiant])};
}

/// Réponses figées, au format de `student_portal/api/` (lot 5).
void main() {
  test('Message : citation, pièces, réactions et la mienne', () {
    final fil = FilMessages.depuisJson({
      'conversation': {'id': 7},
      'interlocuteur': {'nom': 'Service de la scolarité', 'en_ligne': true},
      'messages': [
        {
          'id': 12,
          'camp': 'scolarite',
          'auteur': 'Mme NGO',
          'corps': 'Votre attestation est prête.',
          'envoye_le': '2026-10-29T08:15:00+01:00',
          'pieces_jointes': [
            {'id': 3, 'nom': 'attestation.pdf', 'taille_lisible': '84,1 Ko', 'est_pdf': true},
          ],
          'repond_a': {'id': 11, 'auteur': 'KAMGA Paul', 'extrait': 'Bonjour…'},
          'reactions': {
            'like': {'nombre': 1, 'lecteurs': ['student'], 'noms': []},
            'dislike': {'nombre': 0, 'lecteurs': [], 'noms': []},
          },
          'apercu': null,
        },
      ],
      'pieces_jointes': {'maximum': 5, 'extensions': ['pdf', 'png'], 'champ': 'fichiers'},
      'avertissement': 'Les échanges ne sont pas chiffrés.',
    });
    expect(fil.conversation, 7);
    expect(fil.enLigne, isTrue);
    expect(fil.extensions, ['pdf', 'png']);
    final message = fil.messages.single;
    expect(message.estDe(campEtudiant), isFalse);
    expect(message.repondA?.auteur, 'KAMGA Paul');
    expect(message.pieces.single.estPdf, isTrue);
    expect(message.reactionDe(campEtudiant), reactionJaime);
    expect(message.reactions[reactionJaimePas]?.nombre, 0);
  });

  test('Fil vide : pas de conversation tant qu’aucun message n’est parti', () {
    final fil = FilMessages.depuisJson({'conversation': null, 'messages': []});
    expect(fil.conversation, isNull);
    expect(fil.messages, isEmpty);
    expect(fil.piecesMax, 5);
  });

  test('Fusion : un message relu remplace l’ancien, l’ordre suit l’envoi', () {
    final fusion = fusionnerMessages(
      [_m(1), _m(3)],
      [_m(3, corps: 'relu'), _m(2), _m(4)],
    );
    expect(fusion.map((m) => m.id), [1, 2, 3, 4]);
    expect(fusion[2].corps, 'relu');
  });

  test('Contrôleur : anciens, envoi, réaction', () async {
    final depot = _DepotFactice();
    final conteneur = ProviderContainer(overrides: [
      etudiantRepositoryProvider.overrideWithValue(depot),
    ]);
    addTearDown(conteneur.dispose);
    conteneur.listen(filProvider(SourceFil.guichet), (_, _) {});

    var etat = await conteneur.read(filProvider(SourceFil.guichet).future);
    expect(etat.messages, hasLength(50));
    expect(etat.plusAnciens, isTrue);

    await conteneur.read(filProvider(SourceFil.guichet).notifier).chargerAnciens();
    etat = conteneur.read(filProvider(SourceFil.guichet)).requireValue;
    expect(etat.messages.first.id, 1);
    expect(etat.plusAnciens, isFalse);

    await conteneur.read(filProvider(SourceFil.guichet).notifier).envoyer(corps: 'Merci');
    etat = conteneur.read(filProvider(SourceFil.guichet)).requireValue;
    expect(etat.messages.last.id, 99);
    expect(etat.messages.last.estDe(campEtudiant), isTrue);

    await conteneur
        .read(filProvider(SourceFil.guichet).notifier)
        .reagir(etat.messages.first, reactionJaime);
    etat = conteneur.read(filProvider(SourceFil.guichet)).requireValue;
    expect(etat.messages.first.reactionDe(campEtudiant), reactionJaime);

    // La relecture garde les anciens et le message envoyé.
    final nouveaux = await conteneur.read(filProvider(SourceFil.guichet).notifier).actualiser();
    expect(nouveaux, 0);
    expect(conteneur.read(filProvider(SourceFil.guichet)).requireValue.messages, hasLength(53));
  });

  test('Envoi d’un message : multipart, pièces sous « fichiers », citation',
      () async {
    final (depot, adaptateur) = _depot({
      'message': {'id': 40, 'camp': 'student', 'corps': 'Voici'},
      'conversation': 7,
    });
    final message = await depot.envoyerMessage(
      corps: 'Voici',
      repondA: 12,
      pieces: [
        PieceAJoindre(nom: 'a.pdf', octets: Uint8List(3)),
        PieceAJoindre(nom: 'b.png', octets: Uint8List(3)),
      ],
    );
    expect(message.id, 40);
    final donnees = adaptateur.requete!.data as FormData;
    expect(Map.fromEntries(donnees.fields), {'corps': 'Voici', 'repond_a': '12'});
    expect(donnees.files.map((f) => f.key), ['fichiers', 'fichiers']);
    expect(donnees.files.map((f) => f.value.filename), ['a.pdf', 'b.png']);
  });

  test('Suggestions : état seul, preuves nommées par leur rang', () async {
    final etat = Suggestions.depuisJson({
      'mes_suggestions': [
        {
          'id': 1,
          'reference': 'SUG-2026-0001',
          'texte': 'Plus de prises en bibliothèque',
          'solution_proposee': 'Une rangée de multiprises',
          'statut': 'a_letude',
          'statut_libelle': "À l'étude",
          'preuves': [
            {'id': 4, 'nom': 'Preuve n° 1', 'extension': 'jpg'},
          ],
        },
      ],
      'preuves': {'champ': 'preuves', 'maximum': 5},
      'anonymat': "Votre nom n'est montré sur aucun écran du service.",
    });
    final suggestion = etat.suggestions.single;
    expect(suggestion.solution, 'Une rangée de multiprises');
    expect(suggestion.preuves.single.nom, 'Preuve n° 1');
    expect(etat.preuvesMax, 5);

    final (depot, adaptateur) = _depot({'detail': 'Transmise sans votre nom.'});
    final detail = await depot.deposerSuggestion(
      texte: 'T',
      solution: 'S',
      preuves: [PieceAJoindre(nom: 'photo.jpg', octets: Uint8List(2))],
      champPreuves: etat.champPreuves,
    );
    expect(detail, 'Transmise sans votre nom.');
    final donnees = adaptateur.requete!.data as FormData;
    expect(Map.fromEntries(donnees.fields),
        {'texte': 'T', 'solution_proposee': 'S'});
    expect(donnees.files.single.key, 'preuves');
  });
}
