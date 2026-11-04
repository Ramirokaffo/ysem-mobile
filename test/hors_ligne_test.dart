import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horloge_monotone/horloge_monotone.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ysem/app/theme.dart';
import 'package:ysem/core/format/formats.dart';
import 'package:ysem/core/network/api_exception.dart';
import 'package:ysem/features/etudiant/data/etudiant_repository.dart';
import 'package:ysem/features/etudiant/domain/delegation.dart';
import 'package:ysem/features/etudiant/hors_ligne/base_hors_ligne.dart';
import 'package:ysem/features/etudiant/hors_ligne/depot_delegation.dart';
import 'package:ysem/features/etudiant/hors_ligne/paquet.dart';
import 'package:ysem/features/etudiant/hors_ligne/providers.dart';
import 'package:ysem/features/etudiant/hors_ligne/saisie_locale.dart';
import 'package:ysem/features/etudiant/hors_ligne/synchroniseur.dart';
import 'package:ysem/features/etudiant/presentation/delegation/delegation_page.dart';
import 'package:ysem/l10n/app_localizations.dart';

/// Un compteur que le test fait avancer, et qu'il peut remettre à zéro.
class _Compteur extends HorlogeMonotone {
  LectureCompteur? valeur = const LectureCompteur(ms: 1000, demarrage: 3);

  @override
  Future<LectureCompteur?> lire() async => valeur;
}

class _Serveur implements ServeurHorsLigne {
  Json? paquet;
  ApiException? panne;
  Map<String, dynamic> Function(Json saisie, bool immediate) repondre =
      (saisie, _) => {'reference': saisie['reference'], 'statut': 'acceptee'};
  final envois = <List<Json>>[];

  @override
  Future<Json> lirePaquet() async {
    if (panne != null) throw panne!;
    return paquet!;
  }

  @override
  Future<Json> envoyer(List<Json> saisies, {required bool immediate}) async {
    envois.add(saisies);
    if (panne != null) throw panne!;
    return {
      'resultats': [for (final s in saisies) repondre(s, immediate)],
    };
  }
}

typedef Json = Map<String, dynamic>;

final _reseau = ApiException(code: ApiException.codeReseau, message: 'Hors réseau');

const _ouverture = '2026-11-04T10:00:00Z';
const _fermeture = '2026-11-04T12:00:00Z';

Json _seance({
  String cle = 'c1',
  String date = '2026-11-04',
  String etat = 'a_venir',
  int rang = 1,
  Json? cahier,
}) =>
    {
      'cle': cle,
      'date': date,
      'creneau': {'id': 5, 'debut': '09:00', 'fin': '11:00'},
      'cours': {'code': 'DEV501', 'intitule': 'Développement web'},
      'niveau': {'id': 2},
      'emploi_du_temps': 7,
      'ouverture': _ouverture,
      'fermeture': _fermeture,
      'ouverte': false,
      'etat': etat,
      'cahier_texte': cahier ??
          {
            'etat': 'a_venir',
            'ouvert': false,
            'ouverture': _ouverture,
            'fermeture': _fermeture,
          },
      'etudiants': [1, 2, 3],
      'absents': [2],
      'permissions': [
        {'etudiant': 3, 'type_libelle': 'Absence', 'verrouillee': true},
      ],
      'plan': 9,
      'rang': rang,
      'position_appel': false,
      'position_cahier': false,
    };

Json _paquet({List<Json>? seances, bool actif = true}) => {
      'actif': actif,
      'horloge_serveur': '2026-11-04T08:00:00Z',
      'du': '2026-11-03',
      'au': '2026-11-11',
      'membre': {
        'id': 1,
        'etudiant': {'matricule': 'ETU001', 'nom_complet': 'A'},
        'role_libelle': 'Délégué',
        'principal': true,
      },
      'delegation': {'niveau': null},
      'appel_autorise': true,
      'cahier_autorise': true,
      'circuit_appel': 'service',
      'circuit_cahier': 'service',
      'geolocalisation': {'exigee': false, 'precision_max': 100},
      'etudiants': [
        {'id': 1, 'matricule': 'ETU001', 'nom_complet': 'Alice'},
        {'id': 2, 'matricule': 'ETU002', 'nom_complet': 'Bruno'},
        {'id': 3, 'matricule': 'ETU003', 'nom_complet': 'Carine'},
      ],
      'plans': [
        {
          'id': 9,
          'seances': [
            for (final n in [1, 2, 3, 4])
              {'id': 100 + n, 'numero': n, 'libelle': 'Séance $n', 'contenu': 'C$n'},
          ],
        },
      ],
      'groupes_activites': [
        {
          'champ': 'lieu_travail',
          'libelle': 'Lieu',
          'options': [
            {'valeur': 'salle', 'libelle': 'En salle'},
          ],
        },
      ],
      'seances': seances ?? [_seance()],
      'saisies': <Json>[],
      'reouvertures': <Json>[],
    };

SaisieLocale _saisie({
  String reference = 'r1',
  String geste = SaisieLocale.gesteAppel,
  String cle = 'c1',
  String jour = '2026-11-04',
  String matricule = 'ETU001',
  Json? charge,
  LectureCompteur? compteur = const LectureCompteur(ms: 1000, demarrage: 3),
  EtatSaisie etat = EtatSaisie.enAttente,
}) =>
    SaisieLocale(
      reference: reference,
      matricule: matricule,
      geste: geste,
      cle: cle,
      jour: jour,
      charge: charge ?? {'absents': [1]},
      saisiLe: DateTime.utc(2026, 11, 4, 11),
      compteur: compteur,
      etat: etat,
    );

PaquetGarde _garde(Json contenu,
        {LectureCompteur? compteur = const LectureCompteur(ms: 1000, demarrage: 3)}) =>
    PaquetGarde(
      contenu: contenu,
      luLe: DateTime.utc(2026, 11, 4, 8),
      horlogeServeur: DateTime.utc(2026, 11, 4, 8),
      compteur: compteur,
    );

Future<BaseHorsLigne> _base() async {
  final base = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: BaseHorsLigne.creer,
      singleInstance: false,
    ),
  );
  return BaseHorsLigne(base);
}

void main() {
  sqfliteFfiInit();

  group('Fenêtres rejouées sans serveur', () {
    final paquet = Paquet(_garde(_paquet()));

    test('la fenêtre s\'ouvre et se ferme à l\'heure dite', () {
      final seance = _seance();
      expect(Paquet.reevaluer(seance, DateTime.utc(2026, 11, 4, 9))['etat'], 'a_venir');
      final ouverte = Paquet.reevaluer(seance, DateTime.utc(2026, 11, 4, 11));
      expect(ouverte['etat'], 'ouverte');
      expect(ouverte['ouverte'], isTrue);
      expect((ouverte['cahier_texte'] as Map)['ouvert'], isTrue);
      expect(Paquet.reevaluer(seance, DateTime.utc(2026, 11, 4, 13))['etat'], 'close');
    });

    test('ce que le serveur a tranché ne se recalcule pas', () {
      for (final etat in ['signe', 'valide', 'annulee', 'chomee']) {
        final seance = _seance(etat: etat);
        expect(Paquet.reevaluer(seance, DateTime.utc(2026, 11, 4, 11))['etat'], etat);
      }
      final renvoye = {..._seance(etat: 'renvoye'), 'ouverte': true};
      final lu = Paquet.reevaluer(renvoye, DateTime.utc(2026, 11, 9));
      expect(lu['etat'], 'renvoye');
      expect(lu['ouverte'], isTrue);
    });

    test('reculer l\'heure du téléphone n\'ouvre pas la fenêtre', () {
      // Lu à 8 h ; 13 h de compteur plus tard il est 21 h, le téléphone dit 11 h.
      final maintenant = paquet.maintenant(
        DateTime.utc(2026, 11, 4, 11),
        const LectureCompteur(ms: 1000 + 13 * 3600 * 1000, demarrage: 3),
      );
      expect(maintenant, DateTime.utc(2026, 11, 4, 21));
      expect(Paquet.reevaluer(_seance(), maintenant)['etat'], 'close');
    });

    test('après un redémarrage, l\'horloge corrigée de l\'écart constaté', () {
      final decale = Paquet(PaquetGarde(
        contenu: _paquet(),
        luLe: DateTime.utc(2026, 11, 4, 7), // le téléphone retardait d'une heure
        horlogeServeur: DateTime.utc(2026, 11, 4, 8),
        compteur: const LectureCompteur(ms: 1000, demarrage: 3),
      ));
      expect(
        decale.maintenant(DateTime.utc(2026, 11, 4, 10),
            const LectureCompteur(ms: 50, demarrage: 4)),
        DateTime.utc(2026, 11, 4, 11),
      );
    });

    test('une journée se lit comme une réponse du serveur', () {
      final vue = paquet.delegationDuJour(
          DateTime(2026, 11, 4), DateTime.utc(2026, 11, 4, 11));
      expect(vue.seances.single.cle, 'c1');
      expect(vue.seances.single.appelOuvert, isTrue);
      expect(vue.appelAutorise, isTrue);
      expect(vue.estAujourdhui, isTrue);
      expect(Formats.iso(vue.lendemain!), '2026-11-05');
    });
  });

  group('Feuilles', () {
    final paquet = Paquet(_garde(_paquet()));
    final instant = DateTime.utc(2026, 11, 4, 11);

    test('la feuille d\'appel porte la cohorte et ses verrous', () {
      final feuille = paquet.feuilleAppel('c1', instant, null)!;
      expect(feuille.lignes.map((l) => l.nom), ['Alice', 'Bruno', 'Carine']);
      expect(feuille.lignes[1].absent, isTrue);
      expect(feuille.lignes[2].verrouillee, isTrue);
      expect(feuille.lignes[2].absent, isTrue);
    });

    test('une saisie en cours prime sur ce que le serveur connaissait', () {
      final feuille = paquet.feuilleAppel('c1', instant, _saisie())!;
      expect(feuille.lignes[0].absent, isTrue);
      expect(feuille.lignes[1].absent, isFalse);
      expect(feuille.lignes[2].absent, isTrue, reason: 'une permission ne se décoche pas');
    });

    test('le contenu prévu suit les cahiers gardés sur le téléphone', () {
      final seances = [
        _seance(cle: 'lundi', date: '2026-11-02'),
        _seance(cle: 'mardi', date: '2026-11-03'),
      ];
      final p = Paquet(_garde(_paquet(seances: seances)));
      expect(
        p.feuilleCahier('mardi', instant, null, const [])!.contenusPrevus.first.numero,
        1,
      );
      final lundi = _saisie(
        geste: SaisieLocale.gesteCahier,
        cle: 'lundi',
        jour: '2026-11-02',
        charge: {
          'blocs': [102],
          'activites': <String, String>{},
        },
      );
      final feuille = p.feuilleCahier('mardi', instant, null, [lundi])!;
      expect(feuille.contenusPrevus.map((s) => s.numero), [3, 4, 4]);
    });

    test('un cahier sans séance du plan compte pour une séance tenue', () {
      final p = Paquet(_garde(_paquet(seances: [
        _seance(cle: 'lundi', date: '2026-11-02'),
        _seance(cle: 'mardi', date: '2026-11-03'),
      ])));
      final lundi = _saisie(
        geste: SaisieLocale.gesteCahier,
        cle: 'lundi',
        jour: '2026-11-02',
        charge: {'blocs': <int>[], 'activites': <String, String>{}},
      );
      expect(
        p.feuilleCahier('mardi', instant, null, [lundi])!.contenusPrevus.first.numero,
        2,
      );
    });

    test('le cahier repris garde ce que le délégué a choisi', () {
      final saisie = _saisie(
        geste: SaisieLocale.gesteCahier,
        charge: {
          'blocs': [103],
          'activites': {'lieu_travail': 'salle'},
        },
      );
      final feuille = paquet.feuilleCahier('c1', instant, saisie, [saisie])!;
      expect(feuille.blocsFaits, [103]);
      expect(feuille.activites['lieu_travail'], 'salle');
      expect(feuille.seancesPlan, hasLength(4));
      expect(feuille.groupes.single.champ, 'lieu_travail');
    });
  });

  group('Preuve de l\'heure', () {
    test('le temps écoulé part avec la saisie', () {
      final envoi = _saisie().envoi(const LectureCompteur(ms: 61000, demarrage: 3));
      expect(envoi['ecoule_ms'], 60000);
      expect(envoi['reference'], 'r1');
      expect(envoi['saisi_le'], '2026-11-04T11:00:00.000Z');
    });

    test('après un redémarrage rien n\'est prétendu', () {
      expect(
        _saisie().envoi(const LectureCompteur(ms: 99999, demarrage: 4)),
        isNot(contains('ecoule_ms')),
      );
      expect(
        _saisie(compteur: const LectureCompteur(ms: 5000))
            .envoi(const LectureCompteur(ms: 10)),
        isNot(contains('ecoule_ms')),
        reason: 'un compteur revenu en arrière trahit un redémarrage',
      );
      expect(_saisie(compteur: null).envoi(null), isNot(contains('ecoule_ms')));
    });

    test('deux références ne se ressemblent pas', () {
      final a = nouvelleReference();
      expect(
        a,
        matches(RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')),
      );
      expect(a, isNot(nouvelleReference()));
    });
  });

  group('Ce que garde le téléphone', () {
    late BaseHorsLigne base;

    setUp(() async => base = await _base());
    tearDown(() => base.fermer());

    test('une correction prend la place de ce qui n\'est pas parti', () async {
      await base.enregistrerSaisie(_saisie());
      await base.enregistrerSaisie(_saisie(reference: 'r2', charge: {'absents': [2]}));
      final saisies = await base.saisiesDe('ETU001');
      expect(saisies.single.reference, 'r2');
      expect(saisies.single.absents, [2]);
    });

    test('ce qui attend l\'arbitrage n\'est pas effacé par une correction', () async {
      await base.enregistrerSaisie(_saisie());
      await base.poserEtat('r1', EtatSaisie.aArbitrer);
      await base.enregistrerSaisie(_saisie(reference: 'r2'));
      expect(await base.saisiesDe('ETU001'), hasLength(2));
    });

    test('les saisies partent dans l\'ordre des séances', () async {
      await base.enregistrerSaisie(_saisie(reference: 'b', cle: 'c2', jour: '2026-11-05'));
      await base.enregistrerSaisie(_saisie(reference: 'a', cle: 'c1', jour: '2026-11-03'));
      expect(
        (await base.saisiesAEnvoyer('ETU001')).map((s) => s.reference),
        ['a', 'b'],
      );
    });

    test('un autre compte ne voit ni n\'envoie rien', () async {
      await base.definirMatricule('ETU001');
      await base.ecrirePaquet('ETU001', _paquet(),
          luLe: DateTime.utc(2026), horlogeServeur: DateTime.utc(2026));
      await base.enregistrerSaisie(_saisie());

      await base.definirMatricule('ETU009');

      expect(await base.lirePaquet('ETU001'), isNull,
          reason: 'la liste de la classe ne reste pas');
      expect(await base.saisiesAEnvoyer('ETU009'), isEmpty);
      expect(await base.saisiesAEnvoyer('ETU001'), hasLength(1),
          reason: 'sa saisie attend son retour');
    });

    test('la déconnexion efface le paquet, pas les saisies', () async {
      await base.definirMatricule('ETU001');
      await base.ecrirePaquet('ETU001', _paquet(),
          luLe: DateTime.utc(2026), horlogeServeur: DateTime.utc(2026));
      await base.enregistrerSaisie(_saisie());
      await base.oublierPaquet();
      expect(await base.aUnPaquet(), isFalse);
      expect(await base.nombreAEnvoyer('ETU001'), 1);
    });
  });

  group('Synchronisation', () {
    late BaseHorsLigne base;
    late _Serveur serveur;
    late _Compteur compteur;
    late Synchroniseur sync;

    setUp(() async {
      base = await _base();
      serveur = _Serveur();
      compteur = _Compteur();
      sync = Synchroniseur(
        base: base,
        serveur: serveur,
        horloge: compteur,
        maintenant: () => DateTime.utc(2026, 11, 4, 8),
      );
    });
    tearDown(() => base.fermer());

    test('sans réseau la saisie reste, avec sa référence', () async {
      serveur.panne = _reseau;
      final issue = await sync.enregistrer(_saisie());
      expect(issue.genre, GenreIssue.surLeTelephone);
      expect(await base.nombreAEnvoyer('ETU001'), 1);

      serveur.panne = null;
      expect(await sync.envoyerEnAttente('ETU001'), isTrue);
      expect(serveur.envois.last.single['reference'], 'r1');
      expect(await base.nombreAEnvoyer('ETU001'), 0);
    });

    test('une réponse perdue se rejoue sous la même référence', () async {
      await base.enregistrerSaisie(_saisie());
      serveur.panne = _reseau;
      expect(await sync.envoyerEnAttente('ETU001'), isFalse);
      serveur.panne = null;
      await sync.envoyerEnAttente('ETU001');
      expect(
        serveur.envois.map((e) => e.single['reference']).toSet(),
        {'r1'},
      );
    });

    test('devant son écran, un refus se lit et ne laisse rien', () async {
      serveur.repondre = (s, immediate) {
        expect(immediate, isTrue);
        return {
          'reference': s['reference'],
          'statut': 'refusee',
          'motif': 'hors_zone',
          'detail': 'Vous êtes à 800 m',
        };
      };
      await expectLater(
        sync.enregistrer(_saisie()),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Vous êtes à 800 m')
            .having((e) => e.code, 'code', 'hors_zone')),
      );
      expect(await base.saisiesDe('ETU001'), isEmpty);
    });

    test('un refus rend la saisie qu\'on corrigeait', () async {
      await base.enregistrerSaisie(_saisie(reference: 'ancienne'));
      serveur.repondre = (s, _) =>
          {'reference': s['reference'], 'statut': 'refusee', 'motif': 'hors_zone'};
      await expectLater(
          sync.enregistrer(_saisie(reference: 'nouvelle')), throwsA(isA<ApiException>()));
      expect((await base.saisiesDe('ETU001')).single.reference, 'ancienne');
    });

    test('une collision part à l\'arbitrage et reste visible', () async {
      serveur.repondre = (s, _) => {
            'reference': s['reference'],
            'statut': 'a_arbitrer',
            'motif': 'autre_delegue',
            'detail': 'Bruno a déjà saisi cette séance',
          };
      final issue = await sync.enregistrer(_saisie());
      expect(issue.genre, GenreIssue.aArbitrer);
      expect(issue.detail, contains('Bruno'));
      final saisie = (await base.saisiesDe('ETU001')).single;
      expect(saisie.etat, EtatSaisie.aArbitrer);
      expect(saisie.motif, 'autre_delegue');
    });

    test('une panne du serveur sur une saisie la garde à envoyer', () async {
      await base.enregistrerSaisie(_saisie());
      await base.enregistrerSaisie(_saisie(reference: 'r2', cle: 'c2'));
      serveur.repondre = (s, _) => {
            'reference': s['reference'],
            'statut': s['reference'] == 'r1' ? 'reessayer' : 'acceptee',
          };
      await sync.envoyerEnAttente('ETU001');
      expect(
        (await base.saisiesAEnvoyer('ETU001')).map((s) => s.reference),
        ['r1'],
      );
      expect(serveur.envois, hasLength(2), reason: 'puis il attend le prochain passage');
    });

    test('la session perdue n\'enlève rien à la file', () async {
      await base.enregistrerSaisie(_saisie());
      serveur.panne =
          ApiException(code: 'session_expiree', message: 'Reconnectez-vous', statut: 401);
      expect(await sync.envoyerEnAttente('ETU001'), isFalse);
      expect(await base.nombreAEnvoyer('ETU001'), 1);
    });

    test('le paquet relu solde ce qui a été transmis', () async {
      await base.enregistrerSaisie(_saisie(etat: EtatSaisie.transmise));
      serveur.paquet = _paquet();
      expect(await sync.rafraichirPaquet(), isTrue);
      expect(await base.saisiesDe('ETU001'), isEmpty);
      expect(await base.matriculeActif(), 'ETU001');
      expect((await base.lirePaquet('ETU001'))!.horlogeServeur,
          DateTime.utc(2026, 11, 4, 8));
    });

    test('le sort décidé par le service redescend', () async {
      await base.enregistrerSaisie(_saisie(reference: 'garde', etat: EtatSaisie.aArbitrer));
      await base.enregistrerSaisie(
          _saisie(reference: 'retenue', cle: 'c2', etat: EtatSaisie.aArbitrer));
      await base.enregistrerSaisie(
          _saisie(reference: 'ecartee', cle: 'c3', etat: EtatSaisie.aArbitrer));
      await base.enregistrerSaisie(
          _saisie(reference: 'ancienne', cle: 'c4', etat: EtatSaisie.aArbitrer));
      serveur.paquet = {
        ..._paquet(),
        'saisies': [
          {'reference': 'garde', 'statut': 'a_arbitrer'},
          {'reference': 'retenue', 'statut': 'retenue'},
          {'reference': 'ecartee', 'statut': 'ecartee', 'detail': 'Le principal était là'},
        ],
      };
      await sync.rafraichirPaquet();
      final saisies = {
        for (final s in await base.saisiesDe('ETU001')) s.reference: s,
      };
      expect(saisies.keys, unorderedEquals(['garde', 'ecartee']));
      expect(saisies['ecartee']!.etat, EtatSaisie.ecartee);
      expect(saisies['ecartee']!.detail, 'Le principal était là');
    });

    test('sans réseau l\'ancien paquet reste', () async {
      serveur.paquet = _paquet();
      await sync.rafraichirPaquet();
      serveur.panne = _reseau;
      await expectLater(sync.rafraichirPaquet(), throwsA(isA<ApiException>()));
      expect(await base.aUnPaquet(), isTrue);
    });

    test('qui n\'est plus délégué perd le paquet, pas ses saisies', () async {
      serveur.paquet = _paquet();
      await sync.rafraichirPaquet();
      await base.enregistrerSaisie(_saisie());
      serveur.panne = ApiException(code: 'non_delegue', message: 'Non', statut: 404);
      expect(await sync.rafraichirPaquet(), isFalse);
      expect(await base.aUnPaquet(), isFalse);
      expect(await base.nombreAEnvoyer('ETU001'), 1);
    });

    test('l\'établissement coupe le hors ligne : le paquet tombe', () async {
      serveur.paquet = _paquet();
      await sync.rafraichirPaquet();
      serveur.paquet = {'actif': false, 'saisies': <Json>[]};
      expect(await sync.rafraichirPaquet(), isFalse);
      expect(await base.aUnPaquet(), isFalse);
    });
  });

  group('Délégation vue par les écrans', () {
    late BaseHorsLigne base;
    late _Serveur serveur;
    late DepotDelegation depot;
    late _Depot distant;
    var relances = 0;

    setUp(() async {
      base = await _base();
      serveur = _Serveur()..paquet = _paquet();
      distant = _Depot();
      relances = 0;
      final compteur = _Compteur();
      final sync = Synchroniseur(
        base: base,
        serveur: serveur,
        horloge: compteur,
        maintenant: () => DateTime.utc(2026, 11, 4, 8),
      );
      await sync.rafraichirPaquet();
      compteur.valeur = const LectureCompteur(ms: 1000 + 3 * 3600 * 1000, demarrage: 3);
      depot = DepotDelegation(
        depot: distant,
        base: base,
        synchroniseur: sync,
        matriculeSession: () => null,
        apresSaisie: () async => relances++,
        horloge: () => DateTime.utc(2026, 11, 4, 11),
      );
    });
    tearDown(() => base.fermer());

    test('sans réseau, la journée vient du téléphone', () async {
      serveur.panne = _reseau;
      final vue = await depot.delegation();
      expect(vue.depuisLePaquet, isTrue);
      expect(vue.etat.seances.single.appelOuvert, isTrue);
      expect(distant.lectures, 0);
    });

    test('sans réseau, l\'appel se fait et attend', () async {
      serveur.panne = _reseau;
      final seance = (await depot.delegation()).etat.seances.single;
      final issue = await depot.enregistrerAppel(seance, absents: [1, 2]);

      expect(issue.genre, GenreIssue.surLeTelephone);
      expect(relances, 1, reason: 'la tâche de fond prend le relais');
      final saisie = (await base.saisiesDe('ETU001')).single;
      expect(saisie.absents, [1, 2]);
      expect(saisie.charge['course'], 'DEV501');
      expect(saisie.charge['time_slot'], '5');
      expect(saisie.charge['schedule'], '7');

      final vue = await depot.delegation();
      expect(vue.aEnvoyer, 1);
      expect(vue.saisieDe('c1', SaisieLocale.gesteAppel), isNotNull);
      final feuille = await depot.feuilleAppel(seance);
      expect(feuille.lignes.first.absent, isTrue);
    });

    test('corriger hors ligne ne laisse qu\'une saisie', () async {
      serveur.panne = _reseau;
      final seance = (await depot.delegation()).etat.seances.single;
      await depot.enregistrerAppel(seance, absents: [1]);
      await depot.enregistrerAppel(seance, absents: [2]);
      expect((await base.saisiesDe('ETU001')).single.absents, [2]);
    });

    test('hors de la période du paquet, c\'est le serveur qui répond', () async {
      final vue = await depot.delegation(jour: '2026-12-01');
      expect(vue.depuisLePaquet, isFalse);
      expect(distant.lectures, 1);
    });

    test('sans base, tout passe par le serveur comme avant', () async {
      final seul = DepotDelegation(
        depot: distant,
        base: null,
        synchroniseur: null,
        matriculeSession: () => 'ETU001',
      );
      final vue = await seul.delegation();
      expect(vue.depuisLePaquet, isFalse);
      final issue = await seul.enregistrerAppel(
        SeanceDelegue.depuisJson(_seance()),
        absents: [1],
      );
      expect(issue.message, 'Appel enregistré');
    });

    testWidgets('l\'écran dit ce qui attend le réseau', (tester) async {
      await tester.runAsync(() async {
        serveur.panne = _reseau;
        final seance = (await depot.delegation()).etat.seances.single;
        await depot.enregistrerAppel(seance, absents: [1]);
      });
      await tester.pumpWidget(ProviderScope(
        overrides: [depotDelegationProvider.overrideWith((_) async => depot)],
        child: MaterialApp(
          theme: AppTheme.clair,
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DelegationPage(),
        ),
      ));
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
      expect(find.text('Disponible hors ligne'), findsOneWidget);
      expect(find.text('1 saisie à envoyer'), findsOneWidget);
      expect(find.text("Sur le téléphone, en attente d'envoi"), findsOneWidget);
      expect(find.text('Corriger'), findsWidgets);
    });
  });
}

class _Depot extends Fake implements EtudiantRepository {
  int lectures = 0;

  @override
  Future<Delegation> delegation({String? jour}) async {
    lectures++;
    return Delegation.depuisJson({
      'membre': {'id': 1},
      'jour': jour ?? '2026-11-04',
    });
  }

  @override
  Future<String> enregistrerAppel(SeanceDelegue seance,
          {required List<int> absents, position}) async =>
      'Appel enregistré';
}
