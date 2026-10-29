import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../../commun/telechargement.dart';
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
              _CartePlanning(planning: planning),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _CartePlanning extends ConsumerWidget {
  const _CartePlanning({required this.planning});

  final PlanningExamens planning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);

    final (etat, ton) = planning.termine
        ? (t.planningTermine, TonPastille.neutre)
        : planning.enCours
            ? (t.planningEnCours, TonPastille.marque)
            : (t.planningAVenir, TonPastille.info);

    return CarteYsem(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(planning.libelle(langue), style: theme.textTheme.titleMedium),
          if (planning.cohorte.isNotEmpty)
            Text(planning.cohorte,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Pastille(etat, ton: ton),
              if (planning.typeExamenLibelle.isNotEmpty)
                Pastille(planning.typeExamenLibelle),
              if (planning.estRattrapage)
                Pastille(planning.sessionLibelle, ton: TonPastille.alerte),
              Pastille(t.nbEpreuves(planning.nbEpreuves)),
            ],
          ),
          if (planning.debut != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.date_range_outlined,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  t.semaineDuAu(Formats.dateLongue(planning.debut, langue),
                      Formats.dateLongue(planning.fin, langue)),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
          for (final (date, lignes) in planning.journees) ...[
            const SizedBox(height: 14),
            Text(
              Formats.jourLong(date, langue),
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 4),
            for (final ligne in lignes) _LigneCreneau(ligne: ligne),
          ],
          if (planning.aUnPdf) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => telechargerEtOuvrir(
                context,
                () => ref
                    .read(etudiantRepositoryProvider)
                    .planningExamensPdf(planning.id),
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(t.telechargerPlanning),
            ),
          ],
        ],
      ),
    );
  }
}

class _LigneCreneau extends StatelessWidget {
  const _LigneCreneau({required this.ligne});

  final CreneauExamen ligne;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final horaire = Formats.plage(ligne.debut, ligne.fin);

    if (ligne.pause) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Text(horaire,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            Icon(Icons.coffee_outlined,
                size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(t.pause,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    final details = [
      if (ligne.cours.codeAffiche.isNotEmpty) ligne.cours.codeAffiche,
      if (ligne.salle.isNotEmpty) ligne.salle,
      if (ligne.duree.isNotEmpty) ligne.duree,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: ligne.concerne
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(YsemTokens.rayonPetit),
        border: Border.all(
          color: ligne.concerne
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      // L'horaire au-dessus de l'intitulé : une colonne à part le collerait
      // au nom de l'épreuve sur un écran étroit.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(horaire,
              style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary)),
          Text(ligne.libelle(langue),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (details.isNotEmpty)
            Text(details,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          if (ligne.concerne) ...[
            const SizedBox(height: 4),
            Pastille(t.epreuveConcernee,
                ton: TonPastille.marque, icone: Icons.edit_note_rounded),
          ],
        ],
      ),
    );
  }
}
