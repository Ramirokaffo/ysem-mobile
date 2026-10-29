import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../domain/promotion.dart';

final _promotionProvider = FutureProvider.autoDispose<Promotion>(
  (ref) => ref.watch(etudiantRepositoryProvider).promotion(),
);

/// « Ma promotion » : les moyennes arrêtées de la classe, année par année,
/// leur tendance, et les majors. Aucune moyenne d'étudiant ; une moyenne de
/// classe sous le plancher d'effectif n'est pas montrée.
class PromotionPage extends ConsumerWidget {
  const PromotionPage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionPromotion)),
      body: VueAsynchrone<Promotion>(
        valeur: ref.watch(_promotionProvider),
        surRafraichir: () => ref.refresh(_promotionProvider.future),
        constructeur: (promotion) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (promotion.estVide)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EtatVide(
                    message: t.aucunePromotion,
                    icone: Icons.leaderboard_outlined),
              ),
            for (final niveau in promotion.niveaux) ...[
              _CarteMoyennes(
                  niveau: niveau, effectifMinimum: promotion.effectifMinimum),
              const SizedBox(height: 16),
            ],
            if (promotion.majorsAnnee.isNotEmpty) ...[
              Text(t.majorsDeLAnnee, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final m in promotion.majorsAnnee) ...[
                _CarteMajors(majors: m),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
            ],
            if (promotion.majorsHistoire.isNotEmpty) ...[
              Text(t.majorsDesAnneesPassees,
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final m in promotion.majorsHistoire) ...[
                _CarteMajors(majors: m),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CarteMoyennes extends StatelessWidget {
  const _CarteMoyennes({required this.niveau, required this.effectifMinimum});

  final MoyennesNiveau niveau;
  final int effectifMinimum;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final jetons = YsemTokens.of(context);
    final langue = langueCourante(context);

    Widget? tendance;
    if (niveau.tendance != null && niveau.ecart != null) {
      final (icone, couleur) = switch (niveau.tendance) {
        'hausse' => (Icons.trending_up_rounded, jetons.succes),
        'baisse' => (Icons.trending_down_rounded, jetons.danger),
        _ => (Icons.trending_flat_rounded, jetons.neutre),
      };
      final ecart = niveau.ecart!;
      tendance = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 18, color: couleur),
          const SizedBox(width: 4),
          Text('${ecart > 0 ? '+' : ''}${Formats.note(ecart, langue)}',
              style: theme.textTheme.labelLarge?.copyWith(color: couleur)),
        ],
      );
    }

    return CarteYsem(
      titre: niveau.libelle,
      icone: Icons.insights_rounded,
      action: tendance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final serie in niveau.series)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(serie.annee, style: theme.textTheme.bodyMedium),
                        if (serie.libelle.isNotEmpty &&
                            serie.libelle != serie.annee)
                          Text(serie.libelle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (serie.suffisant && serie.moyenne != null)
                    Text('${Formats.note(serie.moyenne, langue)} /20',
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary))
                  else
                    Text(t.effectifInsuffisant,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          if (niveau.series.any((s) => !s.suffisant)) ...[
            const SizedBox(height: 6),
            Text(t.plancherEffectif(effectifMinimum),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _CarteMajors extends StatelessWidget {
  const _CarteMajors({required this.majors});

  final MajorsPromotion majors;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return CarteYsem(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(majors.cohorte, style: theme.textTheme.titleSmall),
          Text(
            [
              majors.annee,
              if (majors.semestre.isNotEmpty) majors.semestre,
              if (majors.sessionLibelle.isNotEmpty) majors.sessionLibelle,
              if (majors.effectif != null) t.nbEtudiants(majors.effectif!),
            ].where((s) => s.isNotEmpty).join(' · '),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          for (final major in majors.majors)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_rounded,
                      size: 18,
                      color: major.rang == 1
                          ? const Color(0xFFD4A017)
                          : theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  if (major.rang != null)
                    Text(Formats.ordinal(major.rang!, langueCourante(context)),
                        style: theme.textTheme.labelLarge),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(major.nom,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          if (majors.partage)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(t.premierePlacePartagee,
                  style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}
