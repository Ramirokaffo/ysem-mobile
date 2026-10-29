import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ysem/core/format/formats.dart';
import 'package:ysem/features/etudiant/domain/finances.dart';
import 'package:ysem/features/etudiant/domain/notes.dart';
import 'package:ysem/features/etudiant/domain/notifications.dart';
import 'package:ysem/features/etudiant/domain/scolarite.dart';
import 'package:ysem/features/etudiant/presentation/sections.dart';

/// Réponses figées, au format de `student_portal/api/` (vues et sérialiseurs).
void main() {
  setUpAll(initializeDateFormatting);

  test('Scolarite.depuisJson : semaine, journées, parcours', () {
    final s = Scolarite.depuisJson({
      'semaine': {
        'debut': '2026-11-02',
        'fin': '2026-11-08',
        'precedente': '2026-10-26',
        'suivante': '2026-11-09',
        'courante': '2026-10-26',
        'est_semaine_courante': false,
      },
      'nombre_de_seances': 1,
      'journees': [
        {
          'date': '2026-11-02',
          'libelle': 'Lundi',
          'seances': [
            {
              'date': '2026-11-02',
              'creneau': {'debut': '08:00', 'fin': '10:00'},
              'cours': {'code_affiche': 'GES201', 'intitule': 'Comptabilité'},
              'chomee': true,
              'periode': {'nom': 'Toussaint', 'nature': 'ferie'},
            },
          ],
        },
      ],
      'calendrier': [
        {'titre': 'Examens S1', 'debut': '2027-01-10', 'passe': false},
      ],
      'parcours': [
        {
          'annee': {'id': 3, 'nom': '2026-2027'},
          'niveau': {'id': 2, 'nom': 'Licence 2'},
          'actif': true,
          'inscrit': false,
        },
      ],
    });
    expect(s.semaine.estCourante, isFalse);
    expect(s.semaine.precedente, DateTime(2026, 10, 26));
    expect(s.journees.single.seances.single.chomee, isTrue);
    expect(s.journees.single.seances.single.periode, 'Toussaint');
    expect(s.calendrier.single.titre, 'Examens S1');
    expect(s.parcours.single.actif, isTrue);
    expect(s.parcours.single.inscrit, isFalse);
  });

  test("Notes.depuisJson : une note non publiée n'a pas de valeur", () {
    final notes = Notes.depuisJson({
      'annee': {'id': 3, 'nom': '2026-2027'},
      'semestres': [
        {
          'semestre': {'id': 7, 'nom': 'Semestre 3', 'numero': 3},
          'notes': [
            {
              'id': 1,
              'cours': {'code_affiche': 'GES201', 'intitule': 'Comptabilité', 'credits': 3},
              'session': 'normale',
              'note': null,
              'note_publiee': false,
              'epreuves': [
                {
                  'type': 'controle_continu',
                  'libelle': 'Contrôle continu',
                  'note': 12.5,
                  'controles': [
                    {'libelle': 'Interrogation', 'date': '2026-10-12', 'ponderation': 2, 'note': 13},
                  ],
                },
              ],
            },
          ],
        },
      ],
      'resultats_semestre': [
        {
          'semestre': {'id': 7, 'nom': 'Semestre 3'},
          'session': 'rattrapage',
          'moyenne': 11.2,
          'decision': 'AD',
          'cours_a_rattraper': [],
        },
        {
          'semestre': {'id': 7, 'nom': 'Semestre 3'},
          'session': 'normale',
          'moyenne': 9.4,
          'decision': 'RAT',
          'cours_a_rattraper': ['GES201', ' '],
          'session_close': true,
        },
      ],
      'resultat_annuel': null,
    });
    final ligne = notes.semestres.single.notes.single;
    expect(ligne.note, isNull);
    expect(ligne.notePubliee, isFalse);
    expect(ligne.epreuves.single.controles.single.ponderation, 2);
    expect(notes.resultatAnnuel, isNull);
    expect(notes.estVide, isFalse);

    // Session normale d'abord, codes vides écartés.
    final resultats = notes.resultatsDe(notes.semestres.single.semestre);
    expect(resultats.map((r) => r.session), ['normale', 'rattrapage']);
    expect(resultats.first.coursARattraper, ['GES201']);
    expect(resultats.first.sessionClose, isTrue);
  });

  test('Finances.depuisJson : relevé, tranches, reçus', () {
    final f = Finances.depuisJson({
      'annee_selectionnee': {'id': 3, 'nom': '2026-2027'},
      'annees_disponibles': [
        {'id': 3, 'nom': '2026-2027'},
        {'id': 2, 'nom': '2025-2026'},
      ],
      'situation': {
        'statut': 'overdue',
        'statut_libelle': 'En retard',
        'avancement': 40,
        'totaux': {'total_du': 500000, 'paye': 200000, 'echu': 50000, 'exigible': 250000},
        'tranches': [
          {'id': 1, 'libelle': 'Tranche 1', 'montant': 250000, 'montant_paye': 200000,
           'reste_a_payer': 50000, 'echue': true},
          {'id': 2, 'libelle': 'Tranche 2', 'montant': 250000, 'montant_paye': 0,
           'reste_a_payer': 250000, 'echue': false, 'couverte_par_moratoire': true},
        ],
        'paiements': [
          {'id': 9, 'montant': 200000, 'date': '2026-09-15', 'numero_recu': 'R-0009',
           'recu_url': '/api/v1/portail-etudiant/finances/paiements/9/recu/'},
        ],
        'releve_url': '/api/v1/portail-etudiant/finances/releve/3/',
      },
      'demande_de_moratoire_en_attente': null,
    });
    final releve = f.releve!;
    expect(f.anneesDisponibles, hasLength(2));
    expect(releve.resume.statut, 'overdue');
    expect(releve.exigible, 250000);
    expect(releve.tranches.map((t) => t.etat), ['overdue', 'moratorium']);
    expect(releve.paiements.single.aUnRecu, isTrue);
    expect(releve.paiements.single.reference, 'R-0009');
    expect(releve.releveDisponible, isTrue);
    expect(f.demandeEnAttente, isNull);
  });

  test('Finances.depuisJson : aucune situation pour l\'année', () {
    final f = Finances.depuisJson({'situation': null, 'annees_disponibles': []});
    expect(f.releve, isNull);
  });

  test('PageNotifications.depuisJson', () {
    final page = PageNotifications.depuisJson({
      'notifications': [
        {
          'id': 4,
          'title': 'Paiement enregistré',
          'category': 'payment',
          'level': 'success',
          'url': '/portail-etudiant/ma-situation-financiere/',
          'is_read': false,
          'created_at': '2026-10-29T08:15:00+01:00',
        },
      ],
      'pagination': {'page': 1, 'pages': 2, 'total': 21, 'page_suivante': 2},
      'non_lues': 5,
    });
    expect(page.notifications.single.lue, isFalse);
    expect(page.notifications.single.copieLue(true).lue, isTrue);
    expect(page.pagination.aUneSuite, isTrue);
    expect(page.nonLues, 5);
  });

  test("section désignée par l'adresse d'une notification", () {
    expect(sectionDeLAdresse('/portail-etudiant/mes-notes/'), 'notes');
    expect(sectionDeLAdresse('/portail-etudiant/mes-notes'), 'notes');
    expect(
        sectionDeLAdresse(
            'https://ysem.cm/portail-etudiant/ma-situation-financiere/?annee=3#paiements'),
        'finances');
    // Le chemin le plus long l'emporte.
    expect(
        sectionDeLAdresse(
            '/portail-etudiant/ma-situation-financiere/demandes-de-moratoire/'),
        'moratoriums');
    expect(sectionDeLAdresse('/chat-cours/etudiant/abc/'), 'discussions');
    expect(sectionDeLAdresse(''), isNull);
    expect(sectionDeLAdresse('/scholar/etudiants/'), isNull);
  });

  test('formats des notes et des dates de requête', () {
    expect(Formats.note(14.5, 'fr'), '14,50');
    expect(Formats.note(14.5, 'en'), '14.50');
    expect(Formats.note(null, 'fr'), '—');
    expect(Formats.coefficient(2, 'fr'), '2');
    expect(Formats.coefficient(1.5, 'fr'), '1,5');
    expect(Formats.iso(DateTime(2026, 11, 4)), '2026-11-04');
  });
}
