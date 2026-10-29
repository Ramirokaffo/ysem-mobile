import 'package:flutter/material.dart';

import '../../app/charte/charte.dart';
import '../../core/format/formats.dart';
import '../../core/models/agenda.dart';
import '../../l10n/app_localizations.dart';
import 'langue.dart';
import 'tuile_seance.dart';

// Emploi du temps semaine par semaine, commun aux deux portails.

/// Navigation de semaine en semaine : précédente, suivante, retour à la
/// semaine courante, et le nombre de séances tenues.
class BarreSemaine extends StatelessWidget {
  const BarreSemaine({
    super.key,
    required this.semaine,
    required this.nombre,
    required this.surSemaine,
  });

  final SemaineScolarite semaine;
  final int nombre;

  /// `null` pendant un chargement : on ne relance pas une seconde lecture.
  final ValueChanged<DateTime?>? surSemaine;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final plage = semaine.debut == null
        ? ''
        : t.semaineDuAu(Formats.jourMois(semaine.debut, langue),
            Formats.jourMois(semaine.fin, langue));

    return Material(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: t.semainePrecedente,
                  onPressed: semaine.precedente == null || surSemaine == null
                      ? null
                      : () => surSemaine!(semaine.precedente),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(plage,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Pastille(
                        t.seancesDeLaSemaine(nombre),
                        ton: nombre == 0 ? TonPastille.neutre : TonPastille.marque,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: t.semaineSuivante,
                  onPressed: semaine.suivante == null || surSemaine == null
                      ? null
                      : () => surSemaine!(semaine.suivante),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            if (!semaine.estCourante && semaine.courante != null)
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: surSemaine == null
                    ? null
                    : () => surSemaine!(semaine.courante),
                icon: const Icon(Icons.today_rounded, size: 18),
                label: Text(t.cetteSemaine),
              ),
          ],
        ),
      ),
    );
  }
}

/// Une journée de l'emploi du temps et ses séances.
class CarteJournee extends StatelessWidget {
  const CarteJournee({
    super.key,
    required this.journee,
    this.vueEnseignant = false,
  });

  final Journee journee;
  final bool vueEnseignant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final date = journee.date;
    final maintenant = DateTime.now();
    final aujourdhui = date != null &&
        date.year == maintenant.year &&
        date.month == maintenant.month &&
        date.day == maintenant.day;

    return CarteYsem(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                journee.libelle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: aujourdhui ? theme.colorScheme.primary : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Formats.jourMois(date, langue),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (aujourdhui) ...[
                const Spacer(),
                Icon(Icons.circle, size: 10, color: theme.colorScheme.secondary),
              ],
            ],
          ),
          const SizedBox(height: 4),
          for (final (i, seance) in journee.seances.indexed) ...[
            if (i > 0) const Divider(),
            TuileSeance(
              seance: seance,
              avecDate: false,
              vueEnseignant: vueEnseignant,
            ),
          ],
        ],
      ),
    );
  }
}

/// Une date du calendrier académique.
class TuileEvenement extends StatelessWidget {
  const TuileEvenement(this.evenement, {super.key, this.passe = false});

  final EvenementCalendrier evenement;
  final bool passe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: CircleAvatar(
        backgroundColor: passe
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.secondaryContainer,
        child: Icon(
          Icons.flag_outlined,
          size: 20,
          color: passe
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(
        evenement.titre,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: passe ? theme.colorScheme.onSurfaceVariant : null,
        ),
      ),
      subtitle: Text(evenement.libelleDate.isNotEmpty
          ? evenement.libelleDate
          : Formats.dateLongue(evenement.debut, langue)),
    );
  }
}
