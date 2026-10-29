import 'package:flutter/material.dart';

import '../../theme.dart';

/// Encadré d'information, sur le fond secondaire de la marque : une règle à
/// connaître, une demande en cours d'examen.
class Encadre extends StatelessWidget {
  const Encadre({
    super.key,
    required this.texte,
    this.titre,
    this.icone = Icons.info_outline_rounded,
  });

  final String texte;
  final String? titre;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleur = theme.colorScheme.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(YsemTokens.rayon),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 20, color: couleur),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (titre != null) ...[
                  Text(titre!,
                      style:
                          theme.textTheme.titleSmall?.copyWith(color: couleur)),
                  const SizedBox(height: 2),
                ],
                Text(texte,
                    style: theme.textTheme.bodySmall?.copyWith(color: couleur)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
