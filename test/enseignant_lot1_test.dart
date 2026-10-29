import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/app/router.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/network/api_client.dart';
import 'package:ysem/core/network/api_exception.dart';
import 'package:ysem/core/storage/token_storage.dart';
import 'package:ysem/features/auth/application/session_controller.dart';
import 'package:ysem/features/auth/data/auth_enseignant_repository.dart';
import 'package:ysem/features/enseignant/domain/modeles.dart';
import 'package:ysem/features/enseignant/presentation/sections.dart';

/// Rangement en mémoire des jetons.
class _Stockage extends Fake implements TokenStorage {
  final jetons = <Espace, Jetons>{};
  Espace? actif;

  @override
  Future<Jetons?> lire(Espace espace) async => jetons[espace];

  @override
  Future<void> ecrire(Espace espace, Jetons j) async => jetons[espace] = j;

  @override
  Future<void> effacer(Espace espace) async => jetons.remove(espace);

  @override
  Future<void> definirEspaceActif(Espace? espace) async => actif = espace;
}

/// Une réponse figée par appel, et la dernière requête reçue.
class _Adaptateur implements HttpClientAdapter {
  _Adaptateur(this.statut, this.corps);

  final int statut;
  final Map<String, dynamic> corps;
  RequestOptions? requete;
  Object? envoye;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requete = options;
    envoye = options.data;
    return ResponseBody.fromString(jsonEncode(corps), statut, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

(AuthEnseignantRepository, _Adaptateur, _Stockage) _auth(
    int statut, Map<String, dynamic> corps) {
  final adaptateur = _Adaptateur(statut, corps);
  final stockage = _Stockage();
  final dio =
      Dio(BaseOptions(baseUrl: 'http://test/api/v1/portail-enseignant/'))
        ..httpClientAdapter = adaptateur;
  return (
    AuthEnseignantRepository(
        ApiClient(espace: Espace.enseignant, stockage: stockage, dio: dio)),
    adaptateur,
    stockage,
  );
}

const _moi = {
  'matricule': 'LEC0042',
  'prenom': 'Paul',
  'nom': 'AYANG',
  'nom_complet': 'Paul AYANG',
  'email': 'p.ayang@example.cm',
  'grade_libelle': 'Chargé de cours',
  'departement': {'id': 3, 'nom': 'Gestion'},
  'statut': 'hired',
  'statut_libelle': 'Recruté',
  'recrute': true,
  'permanent': false,
  'langue_effective': 'en',
  'photo': '/api/v1/portail-enseignant/profil/photo/',
  'double_authentification': true,
  'date_recrutement': '2024-10-01',
};

void main() {
  group('Connexion enseignant', () {
    test("adresse e-mail et mot de passe ; jetons rangés sous l'espace", () async {
      final (depot, adaptateur, stockage) = _auth(200, {
        'jetons': {'acces': 'A', 'rafraichissement': 'R'},
        'enseignant': _moi,
      });
      final resultat = await depot.connexion(
          email: ' p.ayang@example.cm ', motDePasse: 'secret');

      expect(adaptateur.requete!.path, 'auth/connexion/');
      expect(adaptateur.envoye,
          {'email': 'p.ayang@example.cm', 'mot_de_passe': 'secret'});
      expect(resultat, isA<ConnexionOuverte>());
      final ouverte = resultat as ConnexionOuverte;
      expect(ouverte.espace, Espace.enseignant);
      expect(ouverte.acteur['matricule'], 'LEC0042');
      expect(ouverte.doitChangerMotDePasse, isFalse);
      expect(stockage.jetons[Espace.enseignant]!.acces, 'A');
      expect(stockage.actif, Espace.enseignant);
    });

    test('double authentification : un défi rattaché à son espace', () async {
      final (depot, _, stockage) = _auth(202, {
        'code': 'double_authentification_requise',
        'defi': 'ref-1',
        'detail': 'Un code vous a été envoyé.',
        'envoye': true,
        'adresse': 'p***@example.cm',
        'expire_le': '2026-10-29T10:15:00+01:00',
      });
      final resultat =
          await depot.connexion(email: 'p.ayang@example.cm', motDePasse: 'x');

      expect(resultat, isA<CodeRequis>());
      final defi = resultat as CodeRequis;
      expect(defi.espace, Espace.enseignant);
      expect(defi.defi, 'ref-1');
      expect(defi.adresse, 'p***@example.cm');
      expect(stockage.jetons, isEmpty, reason: 'aucun jeton avant le code');
    });

    test('compte non activé : le message du serveur remonte', () async {
      final (depot, _, _) = _auth(403, {
        'detail': "Votre compte n'est pas encore activé.",
        'code': 'compte_non_active',
      });
      expect(
        () => depot.connexion(email: 'a@b.cm', motDePasse: 'x'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'compte_non_active')
            .having((e) => e.message, 'message', contains('activé'))),
      );
    });

    test('mot de passe oublié : rend le message uniforme', () async {
      final (depot, adaptateur, _) = _auth(200, {
        'detail': 'Si un compte correspond à cette adresse, un lien…',
      });
      final message = await depot.motDePasseOublie('a@b.cm');
      expect(adaptateur.requete!.path, 'auth/mot-de-passe-oublie/');
      expect(message, startsWith('Si un compte'));
    });

    test('un dossier archivé ferme la session du téléphone', () {
      expect(ApiException.codesSessionPerdue, contains('dossier_archive'));
    });
  });

  group('Modèles', () {
    test('Enseignant : identité, rattachement, photo servie par le jeton', () {
      final e = Enseignant.depuisJson(_moi);
      expect(e.nomComplet, 'Paul AYANG');
      expect(e.initiales, 'PA');
      expect(e.departement, 'Gestion');
      expect(e.recrute, isTrue);
      expect(e.aUnePhoto, isTrue);
      expect(e.dateRecrutement, DateTime(2024, 10, 1));
      final session = const Session(espace: Espace.enseignant, acteur: _moi);
      expect(session.langueDuDossier, 'en');
      expect(const Session(espace: Espace.enseignant, acteur: {}).langueDuDossier,
          isNull);
    });

    test('Tableau de bord : candidature, compteurs, séances avec la classe', () {
      final t = TableauDeBordEnseignant.depuisJson({
        'enseignant': _moi,
        'annee': {'id': 5, 'nom': '2026-2027'},
        'candidature': {
          'afficher': true,
          'etape': 3,
          'etapes': 5,
          'prochaine_etape': 4,
          'progression': 60,
          'soumise': false,
          'dernier_refus': {'motif': 'Pièces illisibles'},
        },
        'compteurs': {'nav_fiches_a_signer': 2, 'nav_rattrapages_ouverts': '1'},
        'prochaines_seances': [
          {
            'date': '2026-10-30',
            'creneau': {'debut': '08:00', 'fin': '10:00'},
            'cours': {'code_affiche': 'GES201', 'intitule': 'Comptabilité'},
            'salle': {'nom': 'A12'},
            'classe': 'Section anglophone',
          },
        ],
        'prochaines_dates': 'pas une liste',
      });
      expect(t.annee!.nom, '2026-2027');
      expect(t.candidature.progression, 60);
      expect(t.candidature.motifDernierRefus, 'Pièces illisibles');
      expect(t.compteur('nav_fiches_a_signer'), 2);
      expect(t.compteur('nav_rattrapages_ouverts'), 1);
      expect(t.compteur('nav_fiches_a_transmettre'), 0);
      expect(t.prochainesSeances.single.classe, 'Section anglophone');
      expect(t.prochainesSeances.single.salle, 'A12');
      expect(t.prochainesDates, isEmpty);
    });

    test('Dossier : tableaux, validations et pièces à compléter', () {
      final d = DossierEnseignant.depuisJson({
        'dossier': {
          ..._moi,
          'nationalite': 'Camerounaise',
          'situation_matrimoniale': 'married',
          'situation_matrimoniale_libelle': 'Marié(e)',
          'enfants_a_charge': 2,
          'contact_urgence': {'nom': 'Marie', 'telephone': '699', 'relation': 'Épouse'},
          'cv_depose': true,
          'cursus': [
            {
              'id': 1,
              'diplome': 'Master',
              'diplome_libelle': 'Master',
              'specialization': 'Finance',
              'establishment': 'Université de Yaoundé II',
              'year_obtained': 2015,
              'proof_document_depose': true,
            },
          ],
          'experiences_enseignement': [
            {'id': 4, 'establishment': 'ESSEC', 'years': 3, 'months': 6},
          ],
          'experiences_entreprise': [
            {'id': 5, 'company': 'Banque X', 'position': 'Analyste', 'years': 2},
          ],
          'domaines': [
            {'domaine': 'Finance', 'statut': 'validated', 'statut_libelle': 'Validé'},
          ],
          'cours_proposes': [
            {
              'cours': {'code_affiche': 'FIN301', 'intitule': 'Finance de marché'},
              'statut': 'pending',
              'statut_libelle': 'En attente de validation',
            },
          ],
        },
        'pieces_a_completer': ['Photo', 'Signature'],
      });
      expect(d.situationMatrimoniale, 'Marié(e)');
      expect(d.enfantsACharge, 2);
      expect(d.contactUrgenceRelation, 'Épouse');
      expect(d.cursus.single.etablissement, 'Université de Yaoundé II');
      expect(d.cursus.single.justificatif, isTrue);
      expect(d.experiencesEnseignement.single.organisme, 'ESSEC');
      expect(d.experiencesEnseignement.single.mois, 6);
      expect(d.experiencesEntreprise.single.organisme, 'Banque X');
      expect(d.experiencesEntreprise.single.poste, 'Analyste');
      expect(d.domaines.single.statut, 'validated');
      expect(d.coursProposes.single.code, 'FIN301');
      expect(d.piecesACompleter, ['Photo', 'Signature']);
    });
  });

  test("adresse d'une notification enseignant → section de l'application", () {
    expect(sectionEnseignantDeLAdresse('/enseignants/fiches-a-signer/'),
        'fiches_a_signer');
    expect(
        sectionEnseignantDeLAdresse(
            'https://ysem.cm/enseignants/mes-plans-de-cours/12/?x=1#plan'),
        'documents');
    expect(sectionEnseignantDeLAdresse('/chat-cours/enseignant/groupe/4/'),
        'discussions');
    expect(sectionEnseignantDeLAdresse('/enseignants/mes-vacations'),
        'vacations');
    expect(sectionEnseignantDeLAdresse('/portail-etudiant/mes-notes/'), isNull);
    expect(sectionEnseignantDeLAdresse(''), isNull);
  });

  group('Redirection', () {
    const enseignant =
        Session(espace: Espace.enseignant, acteur: {'matricule': 'LEC1'});
    const etudiant = Session(espace: Espace.etudiant, acteur: {'matricule': 'X'});

    test("connecté en enseignant : les pages publiques mènent à l'accueil", () {
      expect(redirection(const AsyncData(enseignant), Routes.connexionEnseignant),
          Routes.accueilEnseignant);
      expect(redirection(const AsyncData(enseignant), Routes.profilEnseignant),
          isNull);
      expect(
          redirection(
              const AsyncData(enseignant), Routes.sectionEnseignant('dossier')),
          isNull);
    });

    test("l'espace de l'autre reste fermé", () {
      expect(redirection(const AsyncData(enseignant), Routes.notificationsEtudiant),
          Routes.accueilEnseignant);
      expect(redirection(const AsyncData(etudiant), Routes.servicesEnseignant),
          Routes.accueilEtudiant);
      expect(redirection(const AsyncData(etudiant), Routes.accueilEnseignant),
          Routes.accueilEtudiant);
    });

    test("personne de connecté : la connexion enseignant est publique", () {
      const personne = AsyncData<Session?>(null);
      expect(redirection(personne, Routes.connexionEnseignant), isNull);
      expect(redirection(personne, Routes.accueilEnseignant), Routes.choixEspace);
    });
  });
}
