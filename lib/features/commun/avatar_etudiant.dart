import 'package:flutter/material.dart';

import '../../app/charte/couleurs.dart';
import '../../core/config/env.dart';
import '../../core/models/etudiant.dart';

/// Photo de l'étudiant, ou ses initiales sur le bleu de l'établissement.
class AvatarEtudiant extends StatelessWidget {
  const AvatarEtudiant({super.key, required this.etudiant, this.rayon = 26});

  final Etudiant etudiant;
  final double rayon;

  /// Adresse absolue de la photo : l'API rend un chemin relatif (`/media/…`).
  static String? adressePhoto(String? photo) {
    if (photo == null || photo.isEmpty) return null;
    if (photo.startsWith('http')) return photo;
    return '${Env.apiBaseUrl}$photo';
  }

  @override
  Widget build(BuildContext context) {
    final adresse = adressePhoto(etudiant.photo);
    final initiales = Text(
      etudiant.initiales,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: rayon * 0.72,
      ),
    );
    return Container(
      width: rayon * 2,
      height: rayon * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: YsemCouleurs.bleuProfond,
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: adresse == null
          ? initiales
          : Image.network(
              adresse,
              width: rayon * 2,
              height: rayon * 2,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => initiales,
            ),
    );
  }
}
