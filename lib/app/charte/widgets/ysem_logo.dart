import 'package:flutter/material.dart';

/// Les trois présentations du logo YSEM.
enum VarianteLogo {
  /// Logo complet, logotype noir : sur fond clair.
  couleur,

  /// Logo complet, logotype blanc : sur le bandeau bleu ou en mode sombre.
  blanc,

  /// Emblème seul, blanc : sur fond bleu, en petit format.
  embleme,
}

class YsemLogo extends StatelessWidget {
  const YsemLogo({
    super.key,
    this.variante = VarianteLogo.couleur,
    this.hauteur = 56,
  });

  final VarianteLogo variante;
  final double hauteur;

  String get _fichier => switch (variante) {
        VarianteLogo.couleur => 'assets/images/ysem_logo.png',
        VarianteLogo.blanc => 'assets/images/ysem_logo_blanc.png',
        VarianteLogo.embleme => 'assets/images/ysem_embleme.png',
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'YSEM — School of Economics and Management',
      image: true,
      child: Image.asset(
        _fichier,
        height: hauteur,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      ),
    );
  }
}
