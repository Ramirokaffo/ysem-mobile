import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../domain/association.dart';
import 'association_commun.dart';

final _historiqueProvider = FutureProvider.autoDispose<List<ScrutinPasse>>(
  (ref) => ref.watch(etudiantRepositoryProvider).historiqueAssociation(),
);

/// « Listes élues » : les scrutins terminés, leur dépouillement et la liste
/// élue — ou le ballottage, que le module ne tranche pas.
class AssociationHistoriquePage extends ConsumerWidget {
  const AssociationHistoriquePage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final depot = ref.read(etudiantRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionAssociationHistorique)),
      body: VueAsynchrone<List<ScrutinPasse>>(
        valeur: ref.watch(_historiqueProvider),
        surRafraichir: () => ref.refresh(_historiqueProvider.future),
        constructeur: (historique) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (historique.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EtatVide(
                    message: t.aucunScrutinPasse,
                    icone: Icons.history_rounded),
              ),
            for (final passe in historique) ...[
              Text(passe.scrutin.libelle, style: theme.textTheme.titleMedium),
              if (passe.scrutin.dateVote != null)
                Text(Formats.dateLongue(passe.scrutin.dateVote, langue),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              if (passe.listeElue != null)
                CarteYsem(
                  child: Row(
                    children: [
                      InitialesListe(liste: passe.listeElue!),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(passe.listeElue!.nom,
                                style: theme.textTheme.titleSmall),
                            if (passe.listeElue!.candidat.isNotEmpty)
                              Text(t.presidentElu(passe.listeElue!.candidat),
                                  style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Pastille(t.elu,
                          ton: TonPastille.succes,
                          icone: Icons.emoji_events_rounded),
                    ],
                  ),
                )
              else if (passe.ballottage)
                Encadre(icone: Icons.balance_rounded, texte: t.ballottage),
              if (passe.resultats != null) ...[
                const SizedBox(height: 10),
                CarteResultats(resultats: passe.resultats!),
              ],
              const SizedBox(height: 10),
              for (final liste in passe.listes) ...[
                CarteListe(
                  liste: liste,
                  lireProgramme: () => depot.listeHistorique(liste.id),
                ),
                const SizedBox(height: 10),
              ],
              const Divider(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}
