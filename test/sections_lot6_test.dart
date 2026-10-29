import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/format/formats.dart';
import 'package:ysem/core/format/texte_html.dart';
import 'package:ysem/core/network/api_client.dart';
import 'package:ysem/core/storage/token_storage.dart';
import 'package:ysem/features/commun/piece_jointe.dart';
import 'package:ysem/features/commun/position.dart';
import 'package:ysem/features/etudiant/data/etudiant_repository.dart';
import 'package:ysem/features/etudiant/domain/archives.dart';
import 'package:ysem/features/etudiant/domain/association.dart';
import 'package:ysem/features/etudiant/domain/bibliotheque.dart';
import 'package:ysem/features/etudiant/domain/delegation.dart';
import 'package:ysem/features/etudiant/domain/discussions.dart';
import 'package:ysem/features/etudiant/domain/messagerie.dart';
import 'package:ysem/features/etudiant/domain/promotion.dart';
import 'package:ysem/features/etudiant/domain/reinscription.dart';

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

const _seance = {
  'cle': 'k',
  'date': '2026-10-29',
  'creneau': {'id': 4, 'debut': '08:00', 'fin': '10:00'},
  'cours': {'code': 'C-17', 'code_affiche': 'GES201', 'intitule': 'Comptabilité'},
  'niveau': {'id': 2, 'nom': 'Licence 2'},
  'emploi_du_temps': 9,
  'ouverte': true,
  'etat': 'renvoye',
  'appel': {'id': 5, 'statut': 'renvoye', 'motif_renvoi': 'Deux absents oubliés', 'absents': [11, 12]},
  'cahier_texte': {'etat': 'a_venir', 'ouvert': false, 'cahier': null},
};

/// Réponses figées, au format de `student_portal/api/` (lot 6).
void main() {
  test('Réinscription : niveau selon jury, demande, première tranche', () {
    final etat = Reinscription.depuisJson({
      'annee': {'id': 4, 'nom': '2027-2028'},
      'ouverte': true,
      'demande_possible': true,
      'en_attente_de_paiement': true,
      'niveau_selon_jury': true,
      'decision_jury': 'ADD',
      'programme': {'id': 1, 'nom': 'Gestion', 'nom_en': 'Management'},
      'niveaux_proposes': [{'id': 3, 'nom': 'Licence 3'}],
      'niveau_par_defaut': {'id': 3, 'nom': 'Licence 3'},
      'specialites_proposees': [{'id': 7, 'nom': 'Finance'}],
      'inscription': {'niveau': {'id': 3, 'nom': 'Licence 3'}, 'specialite': {'id': 7, 'nom': 'Finance'}, 'inscrit': false},
      'demande': {'statut': 'en_attente', 'statut_libelle': 'En attente de la première tranche'},
      'premiere_tranche': {'configuree': true, 'montant': '200000.00', 'paye': '50000.00', 'reste': '150000.00', 'couverte': false, 'tranche_id': 31},
      'paiement_en_ligne_ouvert': true,
    });
    expect(etat.aUneDemande, isTrue);
    expect(etat.programme!.libelle('en'), 'Management');
    expect(etat.niveaux.single.id, 3);
    expect(etat.specialiteInscrite?.id, 7);
    expect(etat.premiereTranche.reste, 150000);
    expect(etat.premiereTranche.trancheId, 31);
  });

  test('Versements : comptes, plafond, tranches ouvertes, déclaration validée', () {
    final etat = Versements.depuisJson({
      'ouvert': true,
      'comptes': [{'id': 2, 'banque': 'Afriland', 'numero': '10005 00001'}],
      'montant_declarable': '150000.00',
      'tranches_ouvertes': [{'id': 31, 'libelle': 'Tranche 1', 'reste_a_payer': '150000.00'}],
      'declarations': [
        {'id': 9, 'reference': 'VER-1', 'statut': 'validee', 'montant': '100000.00', 'montant_retenu': '95000.00',
         'recu_url': '/api/v1/portail-etudiant/finances/paiements/44/recu/', 'retrait_possible': false},
      ],
    });
    expect(etat.comptes.single.numero, '10005 00001');
    expect(etat.tranchesOuvertes.single.resteAPayer, 150000);
    final d = etat.declarations.single;
    expect(d.montantRetenu, 95000);
    expect(d.recuUrl, startsWith('/api/'));
  });

  test('Déclaration d’un versement : multipart, reçu sous « piece »', () async {
    final (depot, adaptateur) = _depot({'detail': 'Déclaré.', 'ouvert': true});
    final (message, _) = await depot.declarerVersement(
      compte: 2,
      montant: '150000',
      dateOperation: DateTime(2026, 10, 27),
      referenceOperation: 'BRD-778',
      recu: PieceAJoindre(nom: 'recu.jpg', octets: Uint8List(4)),
    );
    expect(message, 'Déclaré.');
    final donnees = adaptateur.requete!.data as FormData;
    expect(Map.fromEntries(donnees.fields), {
      'compte': '2',
      'montant': '150000',
      'date_operation': '2026-10-27',
      'reference_operation': 'BRD-778',
      // Vide : le versement se répartit sur les tranches dans leur ordre.
      'installment': '',
      'commentaire': '',
    });
    expect(donnees.files.single.key, 'piece');
  });

  test('Discussion de classe : le lecteur se reconnaît à sa clé, pas au camp', () {
    final fil = FilMessages.depuisDiscussion({
      'classe': {
        'cle': 'a-b-c',
        'cours': {'code': 'GES201', 'intitule': 'Comptabilité'},
        'cohorte': 'Licence 2 · Gestion',
        'enseignants': [{'nom': 'Paul AYANG', 'en_ligne': true}],
        'ouverte': false,
        'groupe': {'id': 3},
      },
      'lecteur': 'student:12',
      'messages': [
        {'id': 1, 'camp': 'student', 'auteur': 'Camarade', 'auteur_cle': 'student:40'},
        {'id': 2, 'camp': 'student', 'auteur': 'Moi', 'auteur_cle': 'student:12',
         'reactions': {'like': {'nombre': 1, 'lecteurs': ['student:12']}}},
      ],
    });
    expect(fil.interlocuteur, 'Comptabilité');
    expect(fil.enLigne, isTrue);
    expect(fil.accuse, isFalse);
    expect(fil.lectureSeule, isTrue);
    expect(fil.messages.first.estDe(fil.lecteur), isFalse);
    expect(fil.messages.last.estDe(fil.lecteur), isTrue);
    expect(fil.messages.last.reactionDe(fil.lecteur), reactionJaime);

    final liste = Discussions.depuisJson({
      'classes': [
        {'cle': 'a-b-c', 'cours': {'intitule': 'Comptabilité'}, 'groupe': {'non_lus': 3, 'dernier_message': {'id': 9, 'auteur': 'X', 'corps': 'Bonjour'}}},
      ],
      'discussions_passees': [{'cle': 'z', 'ouverte': false, 'groupe': null}],
    });
    expect(liste.classes.single.nonLus, 3);
    expect(liste.classes.single.dernierMessage?.extrait, 'Bonjour');
    expect(liste.passees.single.ouverte, isFalse);
  });

  test('Bibliothèque, archives, promotion', () {
    final vue = VueBibliotheque.depuisJson({
      'dossier': {'id': 5, 'nom': 'Mémoires'},
      'chemin': [{'id': 1, 'nom': 'Racine'}, {'id': 5, 'nom': 'Mémoires'}],
      'dossiers': [{'id': 8, 'nom': '2025', 'nb_documents': 12}],
      'documents': [{'id': 3, 'titre': 'Mémoire', 'annee': 2025, 'extension': 'pdf', 'categories': [{'id': 1, 'nom': 'Finance'}]}],
      'pagination': {'page': 1, 'pages': 2, 'total': 30, 'page_suivante': 2},
    });
    expect(vue.chemin.map((d) => d.nom), ['Racine', 'Mémoires']);
    expect(vue.dossiers.single.nbDocuments, 12);
    expect(vue.documents.single.categories.single.nom, 'Finance');
    expect(vue.pagination.aUneSuite, isTrue);

    final archives = Archives.depuisJson({
      'annales': [{'id': 1, 'cours': {'intitule': 'Stat'}, 'annee': {'nom': '2024-2025'}, 'nb_pieces': 2, 'url': '/a/'}],
      'supports': [{'id': 2, 'type': 'plan', 'url': null}],
      'annees': [{'id': 3, 'nom': '2024-2025'}],
    });
    expect(archives.annales.single.annee, '2024-2025');
    expect(archives.supports.single.url, isNull);

    final promotion = Promotion.depuisJson({
      'effectif_minimum': 5,
      'niveaux': [
        {'libelle': 'Licence 2', 'series': [{'annee': {'nom': '2025-2026'}, 'moyenne': null, 'effectif': 3, 'suffisant': false}],
         'tendance': {'sens': '', 'ecart': null}},
      ],
      'majors_annee': [{'cohorte': 'L2 Gestion', 'majors': [{'nom': 'A', 'rang': 1}], 'partage': true}],
    });
    expect(promotion.niveaux.single.series.single.suffisant, isFalse);
    expect(promotion.niveaux.single.tendance, isNull);
    expect(promotion.majorsAnnee.single.partage, isTrue);
  });

  test('Association : ballottage sans élu, vote envoyé par identifiant', () async {
    final etat = Association.depuisJson({
      'scrutin': {'id': 2, 'libelle': 'Élection 2026', 'urnes_ouvertes': true},
      'listes': [{'id': 7, 'nom': 'Avenir', 'membres': [{'poste_libelle': 'Trésorier', 'nom': 'B'}]}],
      'resultats': {'vote_termine': true, 'en_tete': [7, 8], 'elu': null, 'lignes': [{'bureau': 7, 'voix': 10, 'part': 50}]},
      'a_vote': false,
      'refus': '',
    });
    expect(etat.peutVoter, isTrue);
    expect(etat.resultats!.ballottage, isTrue);
    expect(etat.listes.single.membres.single.posteLibelle, 'Trésorier');

    final (depot, adaptateur) = _depot({'detail': 'Voté.', 'resultats': {'votants': 1}});
    final (message, resultats) = await depot.voter(7);
    expect(message, 'Voté.');
    expect(resultats?.votants, 1);
    expect(adaptateur.requete!.data, {'bureau': '7'});
  });

  test('Délégation : la séance se désigne par ses clés, l’appel part en JSON',
      () async {
    final delegation = Delegation.depuisJson({
      'membre': {'id': 1, 'etudiant': {'nom_complet': 'Moi'}, 'principal': true},
      'assistants': [{'id': 2, 'etudiant': {'nom_complet': 'B'}, 'peut_faire_appel': false}],
      'appel_autorise': true,
      'geolocalisation': {'exigee': true},
      'jour': '2026-10-29',
      'aujourd_hui': '2026-10-29',
      'seances': [_seance],
    });
    expect(delegation.estAujourdhui, isTrue);
    expect(delegation.positionExigee, isTrue);
    final seance = delegation.seances.single;
    expect(seance.etatAppel, 'renvoye');
    expect(seance.appel?.motifRenvoi, 'Deux absents oubliés');
    expect(seance.designation, {
      'date': '2026-10-29',
      'course': 'C-17',
      'level': 2,
      'time_slot': 4,
      'schedule': 9,
    });

    final (depot, adaptateur) = _depot({'detail': 'Appel enregistré : 1 absent(s) sur 30.'});
    await depot.enregistrerAppel(
      seance,
      absents: [11],
      position: const PositionRelevee(latitude: 3.8667, longitude: 11.5167, precision: 12),
    );
    final corps = adaptateur.requete!.data as Map;
    expect(corps['absents'], [11]);
    expect(corps['course'], 'C-17');
    expect(corps['geo_latitude'], '3.8667000');
    expect(corps['geo_precision'], '12.0');
  });

  test('Cahier de texte : blocs déjà faits relus, envoi des séances du plan', () async {
    final feuille = FeuilleCahier.depuisJson({
      'seance': _seance,
      'position_exigee': false,
      'cahier': {
        'statut': 'en_attente',
        'activites': {'type_travail': 'individuel', 'lieu_travail': null},
        'blocs': [{'programme_fait': {'id': 51}}, {'programme_fait': null}],
      },
      'contenus_prevus': [{'id': 51, 'numero': 3, 'libelle': 'Séance 3'}],
      'seances_plan': [{'id': 51, 'numero': 3}, {'id': 52, 'numero': 4}],
      'groupes_activites': [
        {'champ': 'type_travail', 'libelle': 'Type', 'options': [{'valeur': 'individuel', 'libelle': 'Individuel'}]},
      ],
    });
    expect(feuille.blocsFaits, [51]);
    expect(feuille.activites, {'type_travail': 'individuel'});
    expect(feuille.groupes.single.options.single.$1, 'individuel');

    final (depot, adaptateur) = _depot({'detail': 'Cahier enregistré.'});
    await depot.enregistrerCahier(
      feuille.seance,
      activites: {'type_travail': 'individuel', 'lieu_travail': ''},
      seancesFaites: [51, 52],
    );
    final corps = adaptateur.requete!.data as Map;
    expect(corps['blocs'], [
      {'programme_fait': 51},
      {'programme_fait': 52},
    ]);
    expect(corps['lieu_travail'], '');
    expect(corps.containsKey('geo_latitude'), isFalse);
  });

  test('Programme en HTML rendu en texte, ordinaux', () {
    expect(
      texteDuHtml('<p>Nos axes&nbsp;:</p><ul><li>Wi-Fi</li><li>Sport &amp; culture</li></ul>'),
      'Nos axes :\n\n• Wi-Fi\n\n• Sport & culture',
    );
    expect(Formats.ordinal(1, 'fr'), '1er');
    expect(Formats.ordinal(2, 'fr'), '2e');
    expect(Formats.ordinal(2, 'en'), '2nd');
    expect(Formats.ordinal(13, 'en'), '13th');
  });
}
