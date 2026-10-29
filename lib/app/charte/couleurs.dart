import 'package:flutter/material.dart';

/// Couleurs de la charte YSEM.
///
/// Le bleu est celui du logo (`ysemlogo.png`, mesuré `#16A1D8`) ; ses deux
/// déclinaisons sont celles que le portail enseignant pose déjà
/// (`--lec-brand-deep`, `--lec-brand-ink`). Les tons d'état sont ceux du
/// portail étudiant (`portal.css`) : un statut doit se lire de la même couleur
/// sur le web et sur le téléphone.
class YsemCouleurs {
  const YsemCouleurs._();

  /// Le bleu du logo. Sur fond blanc il n'offre qu'environ 3:1 de contraste :
  /// réservé aux grandes surfaces (bandeaux), aux icônes et au mode sombre.
  static const bleu = Color(0xFF16A1D8);

  /// Couleur d'action en mode clair (boutons, liens) : 5,9:1 sur blanc.
  static const bleuProfond = Color(0xFF0A6890);

  /// Fin du dégradé de marque, titres sur fond clair.
  static const encre = Color(0xFF05374D);

  static const noir = Color(0xFF000000);
  static const blanc = Color(0xFFFFFFFF);

  static const succes = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);
  static const alerte = Color(0xFFD97706);
  static const info = Color(0xFF0EA5E9);

  // Neutres
  static const fondClair = Color(0xFFF3F6F9);
  static const texte = Color(0xFF1B2530);
  static const texteDiscret = Color(0xFF5D6B7A);
  static const ligne = Color(0xFFDCE3EA);

  static const fondSombre = Color(0xFF07131A);
  static const surfaceSombre = Color(0xFF0B1A22);
  static const surfaceSombreHaute = Color(0xFF132631);

  /// Dégradé du bandeau de marque, le même que le volet des écrans de
  /// connexion du portail enseignant (`.lec-auth__aside`, 155°).
  static const degradeMarque = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [bleu, bleuProfond, encre],
    stops: [0, 0.52, 1],
  );
}
