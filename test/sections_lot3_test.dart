import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/features/etudiant/domain/discipline.dart';
import 'package:ysem/features/etudiant/domain/documents.dart';
import 'package:ysem/features/etudiant/domain/examens.dart';
import 'package:ysem/features/etudiant/domain/supports.dart';

/// Réponses figées, au format de `student_portal/api/` (lot 3).
void main() {
  test('Documents : regroupés par année, certificat retenu avec son motif', () {
    final documents = Documents.depuisJson({
      'documents': [
        {
          'id': 5,
          'type': 'registration_certificate',
          'type_libelle': 'Certificat de scolarité',
          'reference': 'CI-2026-0042',
          'inscription': {'annee': {'nom': '2026-2027'}},
          'telechargement': {
            'autorise': false,
            'motif_blocage': 'Deuxième tranche impayée',
            'url': '/x/',
          },
        },
        {
          'id': 6,
          'type': 'transcript',
          'type_libelle': 'Relevé de notes',
          'inscription': {'annee': {'nom': '2026-2027'}},
          'telechargement': null,
        },
        {
          'id': 2,
          'type': 'registration_certificate',
          'type_libelle': 'Certificat de scolarité',
          'inscription': {'annee': {'nom': '2025-2026'}},
          'telechargement': {'autorise': true, 'motif_blocage': ''},
        },
      ],
    });
    final groupes = documents.parAnnee;
    expect(groupes.map((g) => g.$1), ['2026-2027', '2025-2026']);
    final certificat = groupes.first.$2.first;
    expect(certificat.telechargeable, isTrue);
    expect(certificat.autorise, isFalse);
    expect(certificat.motifBlocage, 'Deuxième tranche impayée');
    // Le portail ne remet que le certificat.
    expect(groupes.first.$2.last.telechargeable, isFalse);
    expect(groupes.last.$2.single.autorise, isTrue);
  });

  test('Examens : journées du planning, épreuves concernées, pauses', () {
    final examens = Examens.depuisJson({
      'plannings': [
        {
          'id': 3,
          'titre': 'Planning des examens',
          'titre_en': 'Exam schedule',
          'session': 'rattrapage',
          'nb_epreuves': 2,
          'pdf': '/api/v1/portail-etudiant/examens/3/pdf/',
          'creneaux': [
            {'date': '2027-01-11', 'creneau': {'debut': '08:00', 'fin': '11:00'},
             'cours': {'code_affiche': 'GES201', 'intitule': 'Comptabilité'}, 'concerne': true},
            {'date': '2027-01-11', 'creneau': {'debut': '11:00', 'fin': '11:30'}, 'pause': true},
            {'date': '2027-01-12', 'intitule': 'Épreuve commune', 'cours': null},
          ],
        },
      ],
    });
    final planning = examens.plannings.single;
    expect(planning.estRattrapage, isTrue);
    expect(planning.aUnPdf, isTrue);
    expect(planning.libelle('en'), 'Exam schedule');
    final journees = planning.journees;
    expect(journees, hasLength(2));
    expect(journees.first.$2, hasLength(2));
    expect(journees.first.$2.first.concerne, isTrue);
    expect(journees.first.$2.last.pause, isTrue);
    // Sans cours, l'intitulé de la ligne.
    expect(journees.last.$2.single.libelle('fr'), 'Épreuve commune');
  });

  test('Supports : par cours, et ce qui reste à télécharger', () {
    final supports = Supports.depuisJson({
      'a_telecharger': 2,
      'depots': [
        {'id': 1, 'type': 'plan', 'cours': {'code': 'k1', 'code_affiche': 'GES201'},
         'telecharge': true, 'nouvelle_version': true, 'documents': [{'nom': 'plan.pdf'}]},
        {'id': 2, 'type': 'support', 'cours': {'code': 'k2', 'code_affiche': 'MKT210'},
         'telecharge': false},
        {'id': 3, 'type': 'support', 'cours': {'code': 'k1', 'code_affiche': 'GES201'},
         'telecharge': true, 'nouvelle_version': false},
      ],
    });
    expect(supports.parCours.map((c) => c.$1.codeAffiche), ['GES201', 'MKT210']);
    expect(supports.parCours.first.$2.map((d) => d.id), [1, 3]);
    expect(supports.depots.map((d) => d.resteATelecharger), [true, true, false]);
    expect(supports.depots.first.pieces.single.nom, 'plan.pdf');
  });

  test('Discipline : assiduité en taux de 0 à 1, dossier vide sans année', () {
    final dossier = DossierDiscipline.depuisJson({
      'annee': {'id': 3, 'nom': '2026-2027'},
      'seuil_assiduite': '0.75',
      'dossier': {
        'assiduite': {
          'seances_prevues': 40,
          'absences': 6,
          'absences_non_justifiees': 4,
          'taux_presence': 0.85,
          'eligibilite': 'eligible',
          'mode_fiable': false,
        },
        'par_cours': [
          {'cours': {'intitule': 'Comptabilité'}, 'seances_prevues': 10, 'absences': 3,
           'taux_presence': 0.7, 'eligibilite': 'non_eligible'},
        ],
        'manquements': [
          {'date': '2026-10-12', 'statut': 'retard', 'minutes_retard': 25,
           'justification': 'en_attente', 'date_limite_justificatif': '2026-10-19',
           'creneau': {'debut': '08:00', 'fin': '10:00'}, 'cours': null},
        ],
        'sanctions': [{'type_libelle': 'Avertissement', 'statut': 'levee'}],
        'sanctions_actives': 0,
        'incidents_vestimentaires': [],
      },
    });
    expect(dossier.vide, isFalse);
    expect(dossier.seuilAssiduite, 0.75);
    expect(dossier.assiduite.tauxPresence, 0.85);
    expect(dossier.assiduite.modeFiable, isFalse);
    expect(dossier.parCours.single.eligibilite, 'non_eligible');
    final retard = dossier.manquements.single;
    expect(retard.estRetard, isTrue);
    expect(retard.cours, isNull);
    expect(retard.debut, '08:00');
    expect(dossier.sanctions.single.close, isTrue);

    final vide = DossierDiscipline.depuisJson({'annee': null, 'dossier': null});
    expect(vide.vide, isTrue);
  });
}
