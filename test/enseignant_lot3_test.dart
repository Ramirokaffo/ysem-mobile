import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/format/formats.dart';
import 'package:ysem/core/models/examens.dart';
import 'package:ysem/core/network/api_client.dart';
import 'package:ysem/core/storage/token_storage.dart';
import 'package:ysem/features/enseignant/data/enseignant_repository.dart';
import 'package:ysem/features/enseignant/domain/situation.dart';
import 'package:ysem/features/enseignant/presentation/sections.dart';

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

void main() {
  test('Disponibilités : lignes et choix du formulaire du web', () {
    final d = Disponibilites.depuisJson({
      'disponibilites': [
        {
          'id': 3,
          'creneau': {'id': 4, 'libelle': 'Lundi 08:00', 'debut': '08:00', 'fin': '10:00'},
          'statut': 'preferred',
          'statut_libelle': 'Préféré',
          'debut': null,
          'fin': null,
          'notes': 'Sauf novembre',
        },
      ],
      'champs': [
        {
          'nom': 'time_slot',
          'libelle': 'Créneau horaire',
          'choix': [
            {'valeur': '4', 'libelle': 'Lundi 08:00'},
          ],
        },
        {
          'nom': 'status',
          'libelle': 'Statut',
          'choix': [
            {'valeur': 'available', 'libelle': 'Disponible'},
          ],
        },
      ],
    });
    final ligne = d.disponibilites.single;
    expect(ligne.creneauId, 4);
    expect(ligne.debut, isNull);
    expect(ligne.notes, 'Sauf novembre');
    expect(d.formulaire['time_slot']!.choix.single.valeur, '4');
    expect(d.formulaire['status']!.choix.single.libelle, 'Disponible');
  });

  test('Déclarer et modifier : la même charge, une adresse par cas', () async {
    final (creer, a1) = _depot({'detail': 'La disponibilité a été enregistrée.'});
    final message = await creer.enregistrerDisponibilite(
      creneau: '4',
      statut: 'available',
      debut: DateTime(2026, 11, 2),
      fin: DateTime(2026, 12, 18),
    );
    expect(message, contains('enregistrée'));
    expect(a1.requete!.path, 'disponibilites/');
    expect(a1.requete!.data, {
      'time_slot': '4',
      'status': 'available',
      'start_date': '2026-11-02',
      'end_date': '2026-12-18',
      'notes': '',
    });

    // Des dates retirées partent vides : un champ absent garderait sa valeur.
    final (modifier, a2) = _depot({'detail': 'modifiée'});
    await modifier.enregistrerDisponibilite(
        id: 3, creneau: '4', statut: 'unavailable', notes: 'x');
    expect(a2.requete!.path, 'disponibilites/3/');
    expect((a2.requete!.data as Map)['start_date'], '');
  });

  test('Planning des examens : lecture commune, ligne de l\'enseignant', () {
    final e = Examens.depuisJson({
      'plannings': [
        {
          'id': 8,
          'titre': 'Planning',
          'session': 'normale',
          'pdf': '/api/v1/portail-enseignant/examens/8/pdf/',
          'creneaux': [
            {
              'date': '2027-01-12',
              'creneau': {'debut': '08:00', 'fin': '11:00'},
              'cours': {'code_affiche': 'GES201', 'intitule': 'Comptabilité'},
              'concerne': true,
            },
          ],
        },
      ],
    });
    expect(e.plannings.single.aUnPdf, isTrue);
    expect(e.plannings.single.creneaux.single.concerne, isTrue);
    expect(e.plannings.single.creneaux.single.libelle('fr'), 'Comptabilité');
  });

  test('Ponctualité : totaux, séances, règles ; sans année rien ne tombe', () {
    final p = Ponctualite.depuisJson({
      'regles': {'avance_arrivee_attendue_minutes': 10, 'tolerance_retard_minutes': 25},
      'totaux': {
        'seances_relevees': 12,
        'retards': 2,
        'absences': 1,
        'minutes_retenues': 45,
        'minutes_perdues': 130,
        'minutes_effectives': 1200,
      },
      'seances': [
        {
          'date': '2026-10-28',
          'cours': {'intitule': 'Comptabilité'},
          'creneau': {'debut': '08:00', 'fin': '10:00'},
          'statut': 'retard',
          'statut_libelle': 'En retard',
          'heure_arrivee': '08:40',
          'heure_fin': '10:00',
          'minutes_retard': 40,
          'minutes_retenues': 45,
          'fin_constatee_automatiquement': true,
        },
      ],
      'sanctions': [
        {'type_libelle': 'Avertissement', 'statut': 'notifiee', 'motif': 'Retards'},
      ],
    });
    expect(p.tolerance, 25);
    expect(p.totaux!.minutesPerdues, 130);
    expect(p.seances.single.minutesRetard, 40);
    expect(p.seances.single.finConstateeAutomatiquement, isTrue);
    expect(p.sanctions.single.motif, 'Retards');

    final vide = Ponctualite.depuisJson({'annee': null, 'totaux': null, 'regles': null});
    expect(vide.totaux, isNull);
    expect(vide.seances, isEmpty);
  });

  test('Vacations : fiches, états figés, réserves, vacations d\'examen', () {
    final v = Vacations.depuisJson({
      'a_transmettre': 1,
      'fiches': [
        {
          'id': 5,
          'mois': '2026-10-01',
          'cours': {'intitule': 'Comptabilité'},
          'cohorte': 'Licence 2',
          'statut': 'rejetee',
          'statut_libelle': "Renvoyée à l'enseignant",
          'motif_rejet': 'Séance du 12 à revoir',
          'nb_seances': 2,
          'heures_effectives': 3.5,
          'transmissible': true,
          'seances': [
            {'date': '2026-10-12', 'heure_arrivee': '08:00', 'heure_depart': '10:00', 'heures': 2.0},
            {'date': '2026-10-19', 'heures': 1.5, 'rattrapage': true},
          ],
        },
      ],
      'etats': [
        {
          'mois': '2026-09-01',
          'heures_effectives': 20,
          'montant_brut': 100000.0,
          'taux_precompte': 5.5,
          'montant_precompte': 5500.0,
          'montant_net': 94500.0,
          'statut': 'paye',
          'statut_libelle': 'Payé',
          'paye_le': '2026-10-05',
          'reserves': ['Support non déposé'],
        },
      ],
      'vacations_examen': [
        {'session': 'Janvier 2027', 'commissions': 15000.0, 'surveillance': 5000.0, 'net': 20000.0, 'statut': 'arrete'},
      ],
    });
    expect(v.aTransmettre, 1);
    expect(v.fiches.single.transmissible, isTrue);
    expect(v.fiches.single.motifRejet, contains('à revoir'));
    expect(v.fiches.single.seances.last.rattrapage, isTrue);
    expect(v.etats.single.montantNet, 94500);
    expect(v.etats.single.reserves.single, 'Support non déposé');
    expect(v.vacationsExamen.single.commissions, 15000);
  });

  test('Transmettre une fiche : son adresse, le message du serveur', () async {
    final (depot, a) = _depot({'detail': 'Fiche transmise.'});
    expect(await depot.transmettreFiche(5), 'Fiche transmise.');
    expect(a.requete!.path, 'vacations/fiches/5/transmettre/');
  });

  test('Durées et heures lues du serveur', () {
    expect(Formats.duree(45), '45 min');
    expect(Formats.duree(120), '2 h');
    expect(Formats.duree(85), '1 h 25');
    expect(Formats.duree(62), '1 h 02');
    expect(Formats.heures(12.5, 'fr'), '12,5 h');
    expect(Formats.heures(null, 'fr'), '—');
  });

  test('Les notifications de ces sections y mènent', () {
    expect(sectionEnseignantDeLAdresse('/enseignants/mes-disponibilites/'),
        'disponibilites');
    expect(sectionEnseignantDeLAdresse('/enseignants/mes-examens/3/pdf/'),
        'examens');
    expect(sectionEnseignantDeLAdresse('/enseignants/ma-ponctualite/'),
        'ponctualite');
    expect(sectionEnseignantDeLAdresse('/enseignants/mes-vacations/'),
        'vacations');
  });
}
