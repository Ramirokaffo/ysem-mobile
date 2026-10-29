import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../application/sections.dart';
import '../../domain/suggestions.dart';
import 'nouvelle_suggestion_page.dart';

/// « Boîte à suggestions » : mes dépôts et leur état. Le dépôt est anonyme
/// pour le service, et la suite donnée lui reste interne : l'auteur n'en
/// apprend que l'état.
class SuggestionsPage extends ConsumerWidget {
  const SuggestionsPage({super.key, this.titre});

  final String? titre;

  Future<void> _deposer(
      BuildContext context, WidgetRef ref, Suggestions etat) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => NouvelleSuggestionPage(
          preuvesMax: etat.preuvesMax,
          champPreuves: etat.champPreuves,
          anonymat: etat.anonymat,
        ),
      ),
    );
    if (message == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    ref.invalidate(suggestionsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final valeur = ref.watch(suggestionsProvider);
    final etat = valeur.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionSuggestions)),
      floatingActionButton: etat == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _deposer(context, ref, etat),
              icon: const Icon(Icons.lightbulb_outline_rounded),
              label: Text(t.nouvelleSuggestion),
            ),
      body: VueAsynchrone<Suggestions>(
        valeur: valeur,
        surRafraichir: () => ref.refresh(suggestionsProvider.future),
        constructeur: (etat) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Encadre(
              icone: Icons.visibility_off_outlined,
              titre: t.suggestionAnonyme,
              texte: etat.anonymat.isEmpty
                  ? t.suggestionExplication
                  : '${etat.anonymat} ${t.suggestionExplication}',
            ),
            const SizedBox(height: 20),
            Text(t.mesSuggestions,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (etat.suggestions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: EtatVide(
                    message: t.aucuneSuggestion,
                    icone: Icons.lightbulb_outline_rounded),
              ),
            for (final suggestion in etat.suggestions) ...[
              _CarteSuggestion(suggestion: suggestion),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

TonPastille _tonDuStatut(String statut) => switch (statut) {
      'nouvelle' => TonPastille.info,
      'a_letude' => TonPastille.alerte,
      'retenue' => TonPastille.succes,
      _ => TonPastille.neutre,
    };

class _CarteSuggestion extends StatelessWidget {
  const _CarteSuggestion({required this.suggestion});

  final Suggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return CarteYsem(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(suggestion.reference,
                    style: theme.textTheme.titleSmall),
              ),
              Pastille(suggestion.statutLibelle,
                  ton: _tonDuStatut(suggestion.statut)),
            ],
          ),
          if (suggestion.deposeeLe != null)
            Text(
                t.deposeeLe(
                    Formats.horodatage(suggestion.deposeeLe, langue)),
                style: secondaire),
          const SizedBox(height: 8),
          Text(suggestion.texte,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium),
          if (suggestion.solution.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(t.solutionProposee, style: theme.textTheme.labelLarge),
            Text(suggestion.solution,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium),
          ],
          if (suggestion.preuves.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_file_rounded,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(t.nbPreuves(suggestion.preuves.length),
                    style: secondaire),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
