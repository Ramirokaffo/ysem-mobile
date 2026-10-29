import 'package:flutter/material.dart';

import '../../app/charte/charte.dart';
import '../../core/format/formats.dart';
import '../../core/models/agenda.dart';
import '../../l10n/app_localizations.dart';
import 'langue.dart';

/// Une séance de l'emploi du temps : horaire, cours, lieu et marqueurs
/// (annulée, chômée, rattrapage, tronc commun, langue).
class TuileSeance extends StatelessWidget {
  const TuileSeance({
    super.key,
    required this.seance,
    this.avecDate = true,
    this.vueEnseignant = false,
  });

  final Seance seance;

  /// Faux dans une grille déjà regroupée par jour.
  final bool avecDate;

  /// Côté enseignant : l'enseignant, c'est lui ; la cohorte et la classe
  /// disent à qui il fait cours.
  final bool vueEnseignant;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final barree = seance.annulee || seance.chomee;
    final details = [
      if (avecDate) Formats.jourCourt(seance.date, langue),
      if (seance.salle.isNotEmpty) seance.salle,
      if (!vueEnseignant && seance.enseignant.isNotEmpty) seance.enseignant,
      if (vueEnseignant && seance.cohorte.isNotEmpty) seance.cohorte,
      if (vueEnseignant && seance.classe.isNotEmpty) seance.classe,
    ].where((s) => s.isNotEmpty).join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(YsemTokens.rayonPetit),
            ),
            child: Column(
              children: [
                Text(
                  seance.debut ?? '—',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (seance.fin != null)
                  Text(
                    seance.fin!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.75),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seance.intitule(langue),
                  style: theme.textTheme.titleSmall?.copyWith(
                    decoration: barree ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (seance.annulee)
                      Pastille(t.seanceAnnulee, ton: TonPastille.danger),
                    if (seance.chomee)
                      Pastille(
                        seance.periode.isEmpty ? t.seanceChomee : seance.periode,
                        ton: TonPastille.alerte,
                      ),
                    if (seance.rattrapage)
                      Pastille(t.seanceRattrapage, ton: TonPastille.info),
                    if (seance.troncCommun)
                      Pastille(t.seanceTroncCommun, ton: TonPastille.marque),
                    if (seance.langueLibelle.isNotEmpty)
                      Pastille(seance.langueLibelle),
                  ],
                ).paddingTopSiNonVide(6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on Wrap {
  /// Un espace au-dessus des marqueurs, seulement s'il y en a.
  Widget paddingTopSiNonVide(double haut) => children.isEmpty
      ? const SizedBox.shrink()
      : Padding(padding: EdgeInsets.only(top: haut), child: this);
}
