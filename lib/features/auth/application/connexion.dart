import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/auth/espace.dart';
import '../data/auth_repository.dart';
import 'session_controller.dart';

/// Suite d'une tentative de connexion (étudiant ou enseignant) : session ouverte (le
/// routeur mène alors à l'accueil, ou au changement de mot de passe imposé),
/// ou code de vérification à saisir.
void poursuivreConnexion(
  BuildContext context,
  WidgetRef ref,
  ResultatConnexion resultat, {
  bool remplacer = false,
}) {
  switch (resultat) {
    case ConnexionOuverte():
      ref.read(sessionProvider.notifier).ouvrir(resultat);
    case CodeRequis():
      final route = switch (resultat.espace) {
        Espace.etudiant => Routes.codeEtudiant,
        Espace.enseignant => Routes.codeEnseignant,
      };
      if (remplacer) {
        context.replace(route, extra: resultat);
      } else {
        context.push(route, extra: resultat);
      }
  }
}
