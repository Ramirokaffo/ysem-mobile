import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/planning_examens.dart';
import '../../application/sections.dart';
import '../../domain/examens.dart';

/// « Planning des examens » : les plannings publiés pour la cohorte,
/// montrés entiers comme au babillard, les épreuves de l'étudiant désignées.
class ExamensPage extends ConsumerWidget {
  const ExamensPage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionExamens)),
      body: VueAsynchrone<Examens>(
        valeur: ref.watch(examensProvider),
        surRafraichir: () => ref.refresh(examensProvider.future),
        constructeur: (examens) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (examens.plannings.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EtatVide(
                    message: t.aucunPlanning,
                    icone: Icons.event_available_outlined),
              ),
            for (final planning in examens.plannings) ...[
              CartePlanningExamens(
                planning: planning,
                mentionConcerne: t.epreuveConcernee,
                telechargerPdf:
                    ref.read(etudiantRepositoryProvider).planningExamensPdf,
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
