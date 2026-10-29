import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../l10n/app_localizations.dart';

/// Ce qu'un envoi refusé doit dire en tête du formulaire : le message du
/// serveur, ses erreurs d'ensemble (`__all__`) et celles des champs que
/// l'écran ne montre pas. Les autres s'affichent sous leur champ.
List<String> erreursGlobales(ApiException e, Set<String> champsAffiches) => [
      e.message,
      for (final MapEntry(key: champ, value: messages) in e.erreurs.entries)
        if (!champsAffiches.contains(champ)) ...messages,
    ];

/// Bandeau d'erreur en tête d'un formulaire.
class BandeauErreurs extends StatelessWidget {
  const BandeauErreurs({super.key, required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleur = theme.colorScheme.onErrorContainer;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: couleur),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final m in messages)
                  Text(m,
                      style:
                          theme.textTheme.bodySmall?.copyWith(color: couleur)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmation d'un geste qui ne se défait pas (retrait d'une demande).
Future<bool> confirmer(
  BuildContext context, {
  required String titre,
  required String texte,
  required String action,
}) async {
  final t = AppLocalizations.of(context);
  final reponse = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titre),
      content: Text(texte),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(t.annuler),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return reponse == true;
}
