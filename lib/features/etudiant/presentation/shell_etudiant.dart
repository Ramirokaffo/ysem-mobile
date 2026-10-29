import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/espace.dart';
import '../../commun/espace/coque_espace.dart';

/// Coque de l'espace étudiant.
class ShellEtudiant extends StatelessWidget {
  const ShellEtudiant({super.key, required this.coque});

  final StatefulNavigationShell coque;

  @override
  Widget build(BuildContext context) =>
      CoqueEspace(espace: Espace.etudiant, coque: coque);
}
