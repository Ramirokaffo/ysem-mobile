import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/network/api_client.dart';
import 'package:ysem/core/network/api_exception.dart';
import 'package:ysem/core/storage/token_storage.dart';
import 'package:ysem/features/commun/formulaire.dart';
import 'package:ysem/features/commun/piece_jointe.dart';
import 'package:ysem/features/etudiant/data/etudiant_repository.dart';
import 'package:ysem/features/etudiant/domain/moratoires.dart';
import 'package:ysem/features/etudiant/domain/permissions.dart';

class _Stockage extends Fake implements TokenStorage {
  @override
  Future<Jetons?> lire(Espace espace) async => null;
}

/// Adaptateur qui garde la requête et rend une réponse figée.
class _Adaptateur implements HttpClientAdapter {
  _Adaptateur(this.statut, this.corps);

  final int statut;
  final Map<String, dynamic> corps;
  RequestOptions? requete;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requete = options;
    return ResponseBody.fromString(jsonEncode(corps), statut, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

(EtudiantRepository, _Adaptateur) _depot(int statut, Map<String, dynamic> corps) {
  final adaptateur = _Adaptateur(statut, corps);
  final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1/portail-etudiant/'))
    ..httpClientAdapter = adaptateur;
  final client =
      ApiClient(espace: Espace.etudiant, stockage: _Stockage(), dio: dio);
  return (EtudiantRepository(client), adaptateur);
}

/// Réponses figées, au format de `student_portal/api/` (lot 4).
void main() {
  test('Moratoires : historique, plafond et demande en instruction', () {
    final etat = Moratoires.depuisJson({
      'annee': {'id': 3, 'nom': '2026-2027'},
      'montant_demandable': '150000.00',
      'depot_possible': false,
      'demandes': [
        {
          'id': 8,
          'reference': 'MOR-2026-0008',
          'montant': '100000.00',
          'date_souhaitee': '2026-12-15',
          'statut': 'pending',
          'statut_libelle': 'En attente',
          'en_attente': true,
          'piece_jointe': true,
          'annee': {'nom': '2026-2027'},
        },
        {
          'id': 2,
          'statut': 'rejected',
          'en_attente': false,
          'commentaire_decision': 'Pièce illisible',
        },
      ],
    });
    expect(etat.montantDemandable, 150000);
    expect(etat.depotPossible, isFalse);
    expect(etat.enInstruction?.reference, 'MOR-2026-0008');
    expect(etat.demandes.first.pieceJointe, isTrue);
    expect(etat.demandes.first.annee, '2026-2027');
    expect(etat.demandes.last.commentaireDecision, 'Pièce illisible');
  });

  test('Permissions : semaine, journées, séances non demandables, choix', () {
    final etat = Permissions.depuisJson({
      'depot_ouvert': true,
      'justificatif_obligatoire': true,
      'preavis_heures': 24,
      'semaine': {
        'debut': '2026-11-02',
        'fin': '2026-11-08',
        'precedente': '2026-10-26',
        'suivante': '2026-11-09',
        'courante': '2026-10-26',
      },
      'journees': [
        {
          'date': '2026-11-02',
          'seances': [
            {
              'jeton': '2026-11-02|4|k1|2',
              'creneau': {'debut': '08:00', 'fin': '10:00'},
              'cours': {'code_affiche': 'GES201', 'intitule': 'Comptabilité'},
              'salle': {'nom': 'A12'},
              'demandable': true,
              'deja_couverte': 5,
            },
            {'jeton': 'x', 'chomee': true, 'demandable': false, 'libelle': 'Férié'},
          ],
        },
      ],
      'types_de_demande': [
        {'valeur': 'retard', 'libelle': 'Retard'},
        {'valeur': 'absence', 'libelle': 'Absence'},
      ],
      'motifs': [
        {'id': 3, 'libelle': 'Maladie'},
      ],
      'mes_demandes': [
        {
          'id': 4,
          'type': 'retard',
          'heure_arrivee_prevue': '09:15',
          'statut': 'accordee',
          'ouverte': false,
          'seances': [
            {'date': '2026-10-20', 'creneau': {'debut': '08:00', 'fin': '10:00'}},
          ],
        },
      ],
      'en_attente': 0,
    });
    expect(etat.semaine.estCourante, isFalse);
    expect(etat.preavisHeures, 24);
    expect(etat.aDesSeancesDemandables, isTrue);
    final (_, seances) = etat.journees.single;
    expect(seances.first.salle, 'A12');
    expect(seances.first.dejaCouverte, 5);
    expect(seances.first.intitule('fr'), 'Comptabilité');
    // Sans cours, le libellé du serveur.
    expect(seances.last.intitule('fr'), 'Férié');
    expect(seances.last.demandable, isFalse);
    expect(etat.motifs.single.valeur, '3');
    final demande = etat.mesDemandes.single;
    expect(demande.estRetard, isTrue);
    expect(demande.heureArriveePrevue, '09:15');
    expect(demande.seances.single.debut, '08:00');
  });

  test('Dépôt d’une permission : multipart, séances répétées, semaine reposée',
      () async {
    final (depot, adaptateur) =
        _depot(201, {'detail': 'Votre demande a été transmise.'});
    final message = await depot.deposerPermission(
      semaine: '2026-11-02',
      type: 'absence',
      seances: ['a|1', 'b|2'],
      explication: 'Rendez-vous médical',
      motif: '3',
      justificatif: PieceAJoindre(
          nom: 'certificat.pdf', octets: Uint8List.fromList([37, 80, 68, 70])),
    );
    expect(message, 'Votre demande a été transmise.');
    final requete = adaptateur.requete!;
    expect(requete.method, 'POST');
    expect(requete.path, 'permissions/');
    // Le serveur ne reconnaît que les jetons de la semaine consultée.
    expect(requete.queryParameters, {'semaine': '2026-11-02'});
    final donnees = requete.data as FormData;
    expect(
      donnees.fields.where((c) => c.key == 'seances').map((c) => c.value),
      ['a|1', 'b|2'],
    );
    expect(donnees.fields, contains(isA<MapEntry<String, String>>()
        .having((c) => c.key, 'clé', 'motif_libre')));
    // Pas d'heure d'arrivée pour une absence.
    expect(donnees.fields.any((c) => c.key == 'heure_arrivee_prevue'), isFalse);
    expect(donnees.files.single.key, 'justificatif');
    expect(donnees.files.single.value.filename, 'certificat.pdf');
  });

  test('Dépôt d’un moratoire : champs du formulaire du portail', () async {
    final (depot, adaptateur) = _depot(201, {
      'detail': 'Votre demande MOR-1 a bien été transmise.',
      'depot_possible': false,
      'demandes': [
        {'id': 1, 'reference': 'MOR-1', 'en_attente': true},
      ],
    });
    final (message, etat) = await depot.deposerMoratoire(
      montant: '50000',
      dateSouhaitee: DateTime(2026, 12, 15),
      motif: 'Bourse en retard',
    );
    expect(message, contains('MOR-1'));
    expect(etat.enInstruction?.id, 1);
    final donnees = adaptateur.requete!.data as FormData;
    expect(Map.fromEntries(donnees.fields), {
      'amount': '50000',
      'requested_due_date': '2026-12-15',
      'reason': 'Bourse en retard',
    });
    expect(donnees.files, isEmpty);
  });

  test('Refus du formulaire : les erreurs des champs non affichés remontent',
      () async {
    final (depot, _) = _depot(400, {
      'detail': "Les informations transmises n'ont pas été acceptées.",
      'code': 'formulaire_invalide',
      'erreurs': {
        'seances': ['Cochez au moins une séance.'],
        '__all__': ['Dépôt fermé.'],
      },
    });
    try {
      await depot.deposerPermission(
          semaine: null, type: 'absence', seances: [], explication: 'x');
      fail('Le refus aurait dû lever une ApiException.');
    } on ApiException catch (e) {
      expect(e.estFormulaireInvalide, isTrue);
      expect(e.erreurDuChamp('seances'), 'Cochez au moins une séance.');
      expect(erreursGlobales(e, {'seances'}), [
        "Les informations transmises n'ont pas été acceptées.",
        'Dépôt fermé.',
      ]);
    }
  });

  test('Taille lisible d’une pièce', () {
    expect(tailleLisible(2048, 'fr'), '2 Ko');
    expect(tailleLisible(1572864, 'fr'), '1,5 Mo');
    expect(tailleLisible(1572864, 'en'), '1.5 MB');
  });
}
