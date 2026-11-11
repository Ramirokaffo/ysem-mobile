import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/models/devoirs.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../application/sections.dart';
import 'devoir_page.dart';

/// « Mes devoirs » : à rendre, rendus, corrigés et fermés — les trois listes
/// du portail web, dans l'ordre que le serveur leur donne.
class DevoirsPage extends ConsumerWidget {
  const DevoirsPage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionDevoirs)),
      body: VueAsynchrone<DevoirsEtudiant>(
        valeur: ref.watch(devoirsProvider),
        surRafraichir: () => ref.refresh(devoirsProvider.future),
        constructeur: (etat) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            for (final bloc in etat.blocs) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(bloc.titre,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              if (bloc.devoirs.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(bloc.vide,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              for (final entree in bloc.devoirs) ...[
                _CarteDevoir(entree: entree),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Ton de la pastille d'état, le même partage que le portail web.
TonPastille tonDeLEtat(String etat) => switch (etat) {
      'a_rendre' => TonPastille.info,
      'en_retard' => TonPastille.danger,
      'rendu' => TonPastille.succes,
      'corrige' => TonPastille.marque,
      _ => TonPastille.neutre,
    };

class _CarteDevoir extends ConsumerWidget {
  const _CarteDevoir({required this.entree});

  final EntreeDevoir entree;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final devoir = entree.devoir;
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final correction = entree.correction;

    return CarteYsem(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => DevoirPage(id: devoir.id, titre: devoir.titre),
        ));
        ref.invalidate(devoirsProvider);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(devoir.titre, style: theme.textTheme.titleSmall)),
              Pastille(entree.etatLibelle, ton: tonDeLEtat(entree.etat)),
            ],
          ),
          const SizedBox(height: 4),
          Text(devoir.coursIntitule, style: secondaire),
          if (devoir.dateLimite != null)
            Text(
              t.devoirARendreAvant(Formats.horodatage(devoir.dateLimite, langue)),
              style: secondaire?.copyWith(
                color: devoir.echeancePassee ? theme.colorScheme.error : null,
              ),
            ),
          if (entree.groupe != null)
            Text('${t.devoirMonGroupe} : ${entree.groupe!.nom}', style: secondaire),
          if (entree.correctionVisible && correction?.note != null && devoir.noteSur != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${Formats.note(correction!.note, langue)} / ${Formats.note(devoir.noteSur, langue)}',
                style: theme.textTheme.titleMedium,
              ),
            ),
        ],
      ),
    );
  }
}
