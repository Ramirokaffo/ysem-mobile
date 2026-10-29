import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/charte/couleurs.dart';
import '../application/lectures.dart';
import '../domain/modeles.dart';

/// Photo du dossier, ou les initiales sur le bleu de l'établissement.
///
/// La photo est servie par `profil/photo/`, gardée par le jeton : elle est
/// chargée en octets par le dépôt plutôt que par une adresse.
class AvatarEnseignant extends ConsumerWidget {
  const AvatarEnseignant({super.key, required this.enseignant, this.rayon = 26});

  final Enseignant enseignant;
  final double rayon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final octets = enseignant.aUnePhoto
        ? ref.watch(photoEnseignantProvider).valueOrNull
        : null;
    final initiales = Text(
      enseignant.initiales,
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
      child: octets == null
          ? initiales
          : Image.memory(
              octets,
              width: rayon * 2,
              height: rayon * 2,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => initiales,
            ),
    );
  }
}
