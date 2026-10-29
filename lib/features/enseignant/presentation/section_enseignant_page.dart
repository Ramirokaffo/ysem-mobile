import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/icones_sections.dart';
import '../../shell/presentation/a_implementer_page.dart';
import '../application/lectures.dart';
import 'classes/classes_page.dart';
import 'dossier/dossier_page.dart';
import 'emploi_du_temps/emploi_du_temps_page.dart';
import 'fiches/fiches_a_signer_page.dart';
import 'rattrapages/rattrapages_page.dart';

/// Une section du menu enseignant, ouverte par son code de registre
/// (`lecturers.navigation`). Celles qui ne sont pas encore livrées dans
/// l'application affichent un écran d'attente, avec le libellé et l'icône
/// du registre du portail.
class SectionEnseignantPage extends ConsumerWidget {
  const SectionEnseignantPage({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section =
        ref.watch(menuEnseignantProvider).valueOrNull?.section(code);
    final titre = section?.libelle;
    return switch (code) {
      'emploi_du_temps' => EmploiDuTempsEnseignantPage(titre: titre),
      'rattrapages' => RattrapagesPage(titre: titre),
      'classes' => ClassesPage(titre: titre),
      'fiches_a_signer' => FichesASignerPage(titre: titre),
      'dossier' => DossierPage(titre: titre),
      _ => AImplementerPage(
          titre: titre ?? code,
          icone: section == null ? null : iconeDeSection(section.icone),
        ),
    };
  }
}
