import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../../commun/telechargement.dart';
import '../../application/sections.dart';
import '../../domain/supports.dart';

/// « Mes supports de cours » : plans et supports que le service a publiés
/// pour la cohorte, cours par cours. Chaque téléchargement est constaté par
/// le service ; la liste est relue ensuite pour le montrer.
class SupportsPage extends ConsumerWidget {
  const SupportsPage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionSupports)),
      body: VueAsynchrone<Supports>(
        valeur: ref.watch(supportsProvider),
        surRafraichir: () => ref.refresh(supportsProvider.future),
        constructeur: (supports) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (supports.depots.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EtatVide(
                    message: t.aucunSupport, icone: Icons.menu_book_outlined),
              )
            else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Pastille(
                  t.supportsATelecharger(supports.aTelecharger),
                  ton: supports.aTelecharger > 0
                      ? TonPastille.marque
                      : TonPastille.succes,
                  icone: supports.aTelecharger > 0
                      ? Icons.download_rounded
                      : Icons.done_all_rounded,
                ),
              ),
              const SizedBox(height: 12),
              for (final (cours, depots) in supports.parCours) ...[
                CarteYsem(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(cours.libelle(langueCourante(context)),
                          style: theme.textTheme.titleMedium),
                      Text(
                        [
                          cours.codeAffiche,
                          if (depots.first.enseignant.isNotEmpty)
                            depots.first.enseignant,
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      for (final (i, depot) in depots.indexed) ...[
                        if (i > 0) const Divider(),
                        _LigneDepot(depot: depot),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _LigneDepot extends ConsumerWidget {
  const _LigneDepot({required this.depot});

  final DepotSupport depot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);

    final etat = depot.nouvelleVersion
        ? Pastille(t.nouvelleVersion, ton: TonPastille.info)
        : depot.telecharge
            ? Pastille(
                depot.telechargeLe == null
                    ? t.telecharge
                    : t.telechargeLe(Formats.dateLongue(depot.telechargeLe, langue)),
                ton: TonPastille.succes)
            : Pastille(t.aTelecharger, ton: TonPastille.marque);

    final pieces = depot.pieces.map((p) => p.nom).where((n) => n.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            depot.type == 'plan'
                ? Icons.assignment_outlined
                : Icons.slideshow_outlined,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(depot.typeLibelle, style: theme.textTheme.titleSmall),
                Text(
                  [
                    if (depot.pieces.isNotEmpty)
                      t.nbFichiers(depot.pieces.length),
                    if (depot.misAJourLe != null)
                      t.misAJourLe(Formats.dateLongue(depot.misAJourLe, langue))
                    else if (depot.deposeLe != null)
                      t.publieLe(Formats.dateLongue(depot.deposeLe, langue)),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                if (pieces.isNotEmpty)
                  Text(
                    pieces.join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                const SizedBox(height: 6),
                etat,
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: t.telecharger,
            onPressed: () async {
              final recu = await telechargerEtOuvrir(
                context,
                () => ref.read(etudiantRepositoryProvider).support(depot.id),
              );
              // Le service a constaté la remise : la liste le montre.
              if (recu) ref.invalidate(supportsProvider);
            },
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
    );
  }
}
