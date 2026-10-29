import 'package:flutter/material.dart';

/// Carte de rubrique : un titre (avec icône et action facultatives) puis
/// son contenu.
class CarteYsem extends StatelessWidget {
  const CarteYsem({
    super.key,
    this.titre,
    this.icone,
    this.action,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final String? titre;
  final IconData? icone;
  final Widget? action;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contenu = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (titre != null) ...[
            Row(
              children: [
                if (icone != null) ...[
                  Icon(icone, size: 20, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(titre!, style: theme.textTheme.titleMedium),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? contenu : InkWell(onTap: onTap, child: contenu),
    );
  }
}
