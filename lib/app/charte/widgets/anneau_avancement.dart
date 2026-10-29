import 'package:flutter/material.dart';

/// Anneau d'avancement (part payée, part validée…), valeur en pourcentage
/// au centre.
class AnneauAvancement extends StatelessWidget {
  const AnneauAvancement({
    super.key,
    required this.pourcentage,
    this.couleur,
    this.taille = 76,
  });

  /// De 0 à 100.
  final int pourcentage;
  final Color? couleur;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: taille,
      height: taille,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: pourcentage.clamp(0, 100) / 100,
            strokeWidth: taille / 9.5,
            strokeCap: StrokeCap.round,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: couleur ?? theme.colorScheme.secondary,
          ),
          Center(
            child: Text(
              '$pourcentage%',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
