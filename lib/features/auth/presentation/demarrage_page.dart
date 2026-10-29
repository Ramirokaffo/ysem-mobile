import 'package:flutter/material.dart';

import '../../../app/charte/charte.dart';

/// Affichée pendant la restauration de la session, dans la continuité de
/// l'écran natif de démarrage (même bleu, même emblème).
class DemarragePage extends StatelessWidget {
  const DemarragePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: YsemCouleurs.bleu,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            YsemLogo(variante: VarianteLogo.embleme, hauteur: 112),
            SizedBox(height: 40),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
