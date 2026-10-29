import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/network/api_client.dart';
import 'package:ysem/core/storage/token_storage.dart';
import 'package:ysem/features/enseignant/data/enseignant_repository.dart';
import 'package:ysem/features/enseignant/domain/cours.dart';
import 'package:ysem/features/enseignant/domain/planning.dart';

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

const _rattrapage = {
  'id': 7,
  'cours': 'Comptabilité générale',
  'niveau': {'id': 2, 'nom': 'Licence 2'},
  'classe': 'Section francophone',
  'origine_libelle': 'Jour férié',
  'motif': 'Jour férié : Fête nationale',
  'seance_manquee': '2026-05-20',
  'echeance': '2026-06-05',
  'statut': 'a_rattraper',
  'statut_libelle': 'À rattraper',
  'statut_approbation': '',
  'date_prevue': null,
  'creneau': null,
  'salle': null,
  'ouverte': true,
  'programmee': false,
  'en_attente_arbitrage': false,
  'refusee': false,
  'date_proposable': true,
};

void main() {
  test('Emploi du temps : semaine, journées, séances avec leur cohorte', () {
    final e = EmploiDuTemps.depuisJson({
      'annee': {'id': 5, 'nom': '2026-2027'},
      'semaine': {
        'debut': '2026-10-26',
        'fin': '2026-11-01',
        'precedente': '2026-10-19',
        'suivante': '2026-11-02',
        'courante': '2026-10-26',
        'est_semaine_courante': true,
      },
      'nombre_de_seances': 4,
      'journees': [
        {
          'date': '2026-10-26',
          'libelle': 'Lundi',
          'seances': [
            {
              'date': '2026-10-26',
              'creneau': {'debut': '08:00', 'fin': '10:00'},
              'cours': {'intitule': 'Comptabilité'},
              'cohorte': 'Licence 2 · Gestion',
              'classe': 'Section anglophone',
              'rattrapage': true,
            },
          ],
        },
      ],
      'calendrier': [
        {'titre': 'Examens', 'libelle_date': 'Du 12 au 23 janvier'},
      ],
    });
    expect(e.nombreDeSeances, 4);
    expect(e.semaine.suivante, DateTime(2026, 11, 2));
    final seance = e.journees.single.seances.single;
    expect(seance.cohorte, 'Licence 2 · Gestion');
    expect(seance.classe, 'Section anglophone');
    expect(seance.rattrapage, isTrue);
    expect(e.calendrier.single.titre, 'Examens');
  });

  test('Rattrapages : ouverts et clos, choix du formulaire du web', () {
    final r = Rattrapages.depuisJson({
      'rattrapages': [
        _rattrapage,
        {
          ..._rattrapage,
          'id': 8,
          'ouverte': false,
          'date_proposable': false,
          'rattrape_le': '2026-05-30',
        },
      ],
      'ouverts': 1,
      'champs': [
        {
          'nom': 'time_slot',
          'libelle': 'Créneau',
          'obligatoire': true,
          'choix': [
            {'valeur': '4', 'libelle': '08:00 – 10:00'},
          ],
        },
        {'nom': 'classroom', 'libelle': 'Salle', 'choix': []},
      ],
    });
    expect(r.enCours.single.id, 7);
    expect(r.enCours.single.dateProposable, isTrue);
    expect(r.enCours.single.niveau, 'Licence 2');
    expect(r.clos.single.rattrapeLe, DateTime(2026, 5, 30));
    expect(r.formulaire['time_slot']!.choix.single.valeur, '4');
    expect(r.formulaire['time_slot']!.obligatoire, isTrue);
    expect(r.formulaire['inconnu'], isNull);
  });

  test('Proposer une date : champs du formulaire du web', () async {
    final (depot, adaptateur) = _depot({
      'detail': 'Votre proposition du 03/06/2026 a été transmise au service.',
      'rattrapage': {
        ..._rattrapage,
        'date_prevue': '2026-06-03',
        'en_attente_arbitrage': true,
        'date_proposable': false,
      },
    });
    final (message, rattrapage) = await depot.proposerRattrapage(
      7,
      date: DateTime(2026, 6, 3),
      creneau: '4',
    );
    expect(adaptateur.requete!.path, 'rattrapages/7/proposer/');
    expect(adaptateur.requete!.data, {
      'date_prevue': '2026-06-03',
      'time_slot': '4',
      'classroom': '',
      'commentaire': '',
    });
    expect(message, contains('transmise'));
    expect(rattrapage.enAttenteArbitrage, isTrue);
  });

  test('Mes classes : synthèse, créneaux et délégués', () {
    final c = MesClasses.depuisJson({
      'synthese': {'nb_classes': 2, 'nb_cours': 1, 'nb_etudiants': 58, 'nb_sans_delegue': 1},
      'classes': [
        {
          'cle': '17-2-3-0',
          'cours': {'code_affiche': 'GES201', 'intitule': 'Comptabilité', 'intitule_en': 'Accounting'},
          'cohorte': 'Licence 2 · Gestion',
          'classe': 'Section anglophone',
          'effectif': 31,
          'heures_par_semaine': 2.0,
          'creneaux': [
            {'jour_libelle': 'Lundi', 'creneau': {'debut': '08:00', 'fin': '10:00'}, 'salle': {'nom': 'A12'}},
          ],
          'delegues': [
            {
              'role_libelle': 'Délégué principal',
              'principal': true,
              'precision': 'Finance',
              'etudiant': {'nom_complet': 'Awa NDONGO', 'telephone': '699', 'email': 'a@b.cm'},
            },
          ],
          'sans_delegue_principal': false,
        },
      ],
    });
    expect(c.nbEtudiants, 58);
    expect(c.nbSansDelegue, 1);
    final classe = c.classes.single;
    expect(classe.intitule('en'), 'Accounting');
    expect(classe.creneaux.single.salle, 'A12');
    expect(classe.delegues.single.precision, 'Finance');
    expect(classe.delegues.single.principal, isTrue);
  });

  test('Liste de classe : inscrits, manquements, plan', () {
    final d = DetailClasse.depuisJson({
      'classe': {'cle': 'k', 'cours': {'intitule': 'Comptabilité'}},
      'effectif': 2,
      'nb_femmes': 1,
      'nb_hommes': 1,
      'nb_releves': 9,
      'nb_absents': 1,
      'plan_de_cours': {'statut_libelle': 'Validé'},
      'discussion': 'g-17',
      'etudiants': [
        {'matricule': 'YS1', 'nom': 'ABENA', 'prenom': 'Rose', 'absences': 2, 'absences_non_justifiees': 1, 'retards': 1},
        {'matricule': 'YS2', 'nom': 'BELLO', 'prenom': 'Ali', 'delegation': 'principal'},
      ],
    });
    expect(d.nbReleves, 9);
    expect(d.planStatutLibelle, 'Validé');
    expect(d.etudiants.first.nomComplet, 'ABENA Rose');
    expect(d.etudiants.first.absencesNonJustifiees, 1);
    expect(d.etudiants.last.delegation, 'principal');
  });

  test('Fiches à signer : appel avec absents, cahier avec ses blocs', () {
    final f = FichesASigner.depuisJson({
      'fiches': [
        {
          'id': 3,
          'type': 'appel',
          'date': '2026-10-28',
          'creneau': {'debut': '08:00', 'fin': '10:00'},
          'cours': {'intitule': 'Comptabilité'},
          'niveau': {'nom': 'Licence 2'},
          'delegue': {'nom_complet': 'Awa NDONGO'},
          'statut': 'a_signer',
          'statut_libelle': 'À signer',
          'effectif': 31,
          'absents': [11, 12],
          'absents_detail': [
            {'nom_complet': 'Rose ABENA'},
            {'nom_complet': 'Ali BELLO'},
          ],
        },
        {
          'id': 4,
          'type': 'cahier',
          'statut': 'a_signer',
          'blocs': [
            {
              'programme_fait': {'libelle': 'Séance 4', 'chapitre': {'titre': 'Bilan'}},
              'contenus_realises': 'Actif et passif',
            },
          ],
        },
      ],
      'historique': [
        {'id': 1, 'type': 'appel', 'statut': 'valide', 'en_attente_du_service': false},
      ],
    });
    final appel = f.fiches.first;
    expect(appel.estAppel, isTrue);
    expect(appel.effectif, 31);
    expect(appel.absents, ['Rose ABENA', 'Ali BELLO']);
    expect(appel.delegue, 'Awa NDONGO');
    final cahier = f.fiches.last;
    expect(cahier.estAppel, isFalse);
    expect(cahier.blocs.single.seance, 'Séance 4');
    expect(cahier.blocs.single.chapitre, 'Bilan');
    expect(f.historique.single.statut, 'valide');
  });

  test('Signer et renvoyer : adresse par type de fiche, motif posté', () async {
    final fiche = FicheDeSeance.depuisJson({'id': 4, 'type': 'cahier'});

    final (signer, a1) = _depot({'detail': 'Fiche signée.'});
    expect(await signer.signerFiche(fiche), 'Fiche signée.');
    expect(a1.requete!.path, 'fiches-a-signer/cahier/4/signer/');

    final (renvoyer, a2) = _depot({'detail': 'Fiche renvoyée au délégué.'});
    await renvoyer.renvoyerFiche(fiche, 'Chapitre manquant');
    expect(a2.requete!.path, 'fiches-a-signer/cahier/4/renvoyer/');
    expect(a2.requete!.data, {'motif': 'Chapitre manquant'});

    final (tout, a3) = _depot({
      'detail': '2 fiche(s) signée(s).',
      'signees': 2,
      'refus': ['Appel du 28/10 : déjà validé'],
    });
    final (message, refus) = await tout.signerToutesLesFiches();
    expect(a3.requete!.path, 'fiches-a-signer/signer-tout/');
    expect(message, startsWith('2'));
    expect(refus.single, contains('déjà validé'));
  });
}
