import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/espace.dart';
import '../../../core/navigation/icones_sections.dart';
import '../../commun/fil/discussions_page.dart';
import '../../shell/presentation/a_implementer_page.dart';
import '../application/lectures.dart';
import 'classes/classes_page.dart';
import 'devoirs/devoirs_enseignant_page.dart';
import 'disponibilites/disponibilites_page.dart';
import 'dossier/dossier_page.dart';
import 'emploi_du_temps/emploi_du_temps_page.dart';
import 'enseignements/enseignements_page.dart';
import 'examens/examens_enseignant_page.dart';
import 'documents/documents_page.dart';
import 'epreuves/epreuves_page.dart';
import 'fiches/fiches_a_signer_page.dart';
import 'notes/feuilles_page.dart';
import 'ponctualite/ponctualite_page.dart';
import 'rattrapages/rattrapages_page.dart';
import 'vacations/vacations_page.dart';

/// Une section du menu enseignant, ouverte par son code de registre
/// (`lecturers.navigation`). Celles qui ne sont pas encore livrées dans
/// l'application affichent un écran d'attente, avec le libellé et l'icône
/// du registre du portail.
class SectionEnseignantPage extends ConsumerWidget {
  const SectionEnseignantPage({
    super.key,
    required this.code,
    this.parametres = const {},
  });

  final String code;

  /// Paramètres de l'adresse : l'objet de la section à ouvrir d'emblée
  /// (`devoir` — voir la lecture des adresses de notification).
  final Map<String, String> parametres;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section =
        ref.watch(menuEnseignantProvider).valueOrNull?.section(code);
    final titre = section?.libelle;
    return switch (code) {
      'emploi_du_temps' => EmploiDuTempsEnseignantPage(titre: titre),
      'disponibilites' => DisponibilitesPage(titre: titre),
      'examens' => ExamensEnseignantPage(titre: titre),
      'rattrapages' => RattrapagesPage(titre: titre),
      'classes' => ClassesPage(titre: titre),
      'devoirs' => DevoirsEnseignantPage(
          titre: titre,
          devoirInitial: int.tryParse(parametres['devoir'] ?? ''),
        ),
      'fiches_a_signer' => FichesASignerPage(titre: titre),
      'ponctualite' => PonctualitePage(titre: titre),
      'vacations' => VacationsPage(titre: titre),
      'enseignements' => EnseignementsPage(titre: titre),
      'discussions' =>
        DiscussionsPage(espace: Espace.enseignant, titre: titre),
      'feuilles_de_notes' => FeuillesPage(titre: titre),
      'documents' => DocumentsCoursPage(titre: titre),
      'epreuves' => EpreuvesPage(titre: titre),
      'dossier' => DossierPage(titre: titre),
      _ => AImplementerPage(
          titre: titre ?? code,
          icone: section == null ? null : iconeDeSection(section.icone),
        ),
    };
  }
}
