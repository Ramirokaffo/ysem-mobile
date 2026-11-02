import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/models/examens.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/planning_examens.dart';
import '../../application/lectures.dart';

/// « Planning des examens » : les plannings publiés où l'enseignant est
/// attendu, montrés entiers comme au babillard, ses épreuves désignées. Un
/// brouillon n'est lu par personne.
class ExamensEnseignantPage extends ConsumerWidget {
  const ExamensEnseignantPage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionExamens)),
      body: VueAsynchrone<Examens>(
        valeur: ref.watch(examensEnseignantProvider),
        surRafraichir: () => ref.refresh(examensEnseignantProvider.future),
        constructeur: (examens) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (examens.plannings.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EtatVide(
                  message: t.aucunPlanningEnseignant,
                  icone: Icons.event_available_outlined,
                ),
              ),
            for (final planning in examens.plannings) ...[
              CartePlanningExamens(
                planning: planning,
                mentionConcerne: t.votreEpreuve,
                telechargerPdf:
                    ref.read(enseignantRepositoryProvider).planningExamensPdf,
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
