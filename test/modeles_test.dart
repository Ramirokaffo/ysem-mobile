import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/features/etudiant/domain/modeles.dart';

/// Réponses figées, au format de `student_portal/api/serializers.py`.
void main() {
  group('TableauDeBord.depuisJson', () {
    final json = {
      'etudiant': {
        'matricule': 'YS24-0012',
        'prenom': 'Aïcha',
        'nom': 'NGONO',
        'nom_complet': 'Aïcha NGONO',
        'langue_effective': 'fr',
        'photo': null,
        'double_authentification': true,
      },
      'annee': {'id': 3, 'nom': '2026-2027', 'debut': '2026-09-01'},
      'inscription': {
        'niveau': {'id': 2, 'nom': 'Licence 2'},
        'programme': {'id': 1, 'nom': 'Gestion', 'nom_en': 'Management'},
        'specialite': null,
        'section': 'fr',
        'section_libelle': 'Section francophone',
      },
      'situation_financiere': {
        'statut': 'overdue',
        'statut_libelle': 'En retard',
        'avancement': 140,
        'totaux': {'paye': 250000.0, 'reste_a_payer': 150000.0, 'echu': 50000},
      },
      'prochaines_seances': [
        {
          'date': '2026-11-02',
          'creneau': {'debut': '08:00', 'fin': '10:00'},
          'cours': {'code_affiche': 'GES201', 'intitule': 'Comptabilité', 'intitule_en': 'Accounting'},
          'enseignant': {'nom': 'Paul AYANG'},
          'salle': {'nom': 'A12'},
          'rattrapage': true,
          'periode': null,
        },
      ],
      'prochaines_dates': [
        {'titre': 'Examens', 'libelle_date': 'du 4 au 8 janv.'},
      ],
      'documents_recents': 'inattendu',
    };

    test('lit les rubriques, en tolérant un champ mal formé', () {
      final t = TableauDeBord.depuisJson(json);
      expect(t.etudiant.prenom, 'Aïcha');
      expect(t.etudiant.initiales, 'AN');
      expect(t.etudiant.doubleAuthentification, isTrue);
      expect(t.annee?.nom, '2026-2027');
      expect(t.situationFinanciere?.avancement, 100, reason: 'borné à 100');
      expect(t.situationFinanciere?.totaux.echu, 50000);
      expect(t.prochainesSeances.single.rattrapage, isTrue);
      expect(t.prochainesSeances.single.intitule('en'), 'Accounting');
      expect(t.prochainesSeances.single.salle, 'A12');
      expect(t.prochainesDates.single.libelleDate, 'du 4 au 8 janv.');
      expect(t.documentsRecents, isEmpty);
    });

    test("compose la cohorte dans la langue demandée", () {
      final t = TableauDeBord.depuisJson(json);
      expect(t.inscription?.resume('fr'),
          'Licence 2 · Gestion · Section francophone');
      expect(t.inscription?.resume('en'),
          'Licence 2 · Management · Section francophone');
    });
  });

  test('Navigation : accès rapides sans le tableau de bord, compteur', () {
    final n = Navigation.depuisJson({
      'groupes': [
        {
          'titre': '',
          'sections': [
            {'code': 'dashboard', 'libelle': 'Tableau de bord', 'acces_rapide': true},
          ],
        },
        {
          'titre': 'Mes études',
          'sections': [
            {'code': 'academics', 'libelle': 'Ma scolarité', 'icone': 'fa-graduation-cap', 'acces_rapide': true, 'badge': 2},
            {'code': 'notes', 'libelle': 'Mes notes', 'acces_rapide': false},
          ],
        },
      ],
      'compteurs': {'notification_unread_count': 4},
    });
    expect(n.accesRapides.map((s) => s.code), ['academics']);
    expect(n.section('notes')?.libelle, 'Mes notes');
    expect(n.section('academics')?.badge, 2);
    expect(n.notificationsNonLues, 4);
  });

  test("Profil : état civil et connexions récentes", () {
    final p = Profil.depuisJson({
      'profil': {
        'matricule': 'YS24-0012',
        'nom_complet': 'Aïcha NGONO',
        'etat_civil': {'ville_residence': 'Yaoundé', 'quartier_residence': 'Bastos'},
      },
      'connexions_recentes': [
        {'date': '2026-10-28T09:12:00+01:00', 'appareil': 'Android', 'appareil_connu': false},
      ],
    });
    expect(p.etudiant.matricule, 'YS24-0012');
    expect(p.villeResidence, 'Yaoundé');
    expect(p.connexionsRecentes.single.appareilConnu, isFalse);
  });
}
