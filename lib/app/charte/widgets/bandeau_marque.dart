import 'package:flutter/material.dart';

import '../../theme.dart';

/// Bandeau aux couleurs de l'établissement : le dégradé du logo, et en
/// option une photo du campus voilée par ce dégradé.
class BandeauMarque extends StatelessWidget {
  const BandeauMarque({
    super.key,
    required this.child,
    this.image,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 24),
    this.rayonBas = 28,
  });

  final Widget child;

  /// Ressource d'image affichée sous le dégradé (`assets/images/hero.jpg`).
  final String? image;
  final EdgeInsetsGeometry padding;
  final double rayonBas;

  @override
  Widget build(BuildContext context) {
    final degrade = YsemTokens.of(context).degrade;
    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(rayonBas)),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: degrade)),
          ),
          if (image != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.22,
                child: Image.asset(image!, fit: BoxFit.cover),
              ),
            ),
          Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: IconTheme.merge(
                data: const IconThemeData(color: Colors.white),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
