import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/charte/charte.dart';
import '../../core/format/formats.dart';
import '../../core/models/examens.dart';
import '../../l10n/app_localizations.dart';
import 'langue.dart';
import 'telechargement.dart';

/// Un planning publié, montré entier comme au babillard, les lignes du
/// lecteur désignées par [mentionConcerne].
class CartePlanningExamens extends StatelessWidget {
  const CartePlanningExamens({
    super.key,
    required this.planning,
    required this.mentionConcerne,
    required this.telechargerPdf,
  });

  final PlanningExamens planning;

  /// « Vous composez » côté étudiant, « Votre épreuve » côté enseignant.
  final String mentionConcerne;
  final Future<File> Function(int id) telechargerPdf;

  @override
  Widget build(BuildContext context) {
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
            for (final ligne in lignes) _LigneCreneau(ligne: ligne, mentionConcerne: mentionConcerne),
          ],
          if (planning.aUnPdf) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => telechargerEtOuvrir(
                context,
                () => telechargerPdf(planning.id),
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
  const _LigneCreneau({required this.ligne, required this.mentionConcerne});

  final CreneauExamen ligne;
  final String mentionConcerne;

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
            Pastille(mentionConcerne,
                ton: TonPastille.marque, icone: Icons.edit_note_rounded),
          ],
        ],
      ),
    );
  }
}
