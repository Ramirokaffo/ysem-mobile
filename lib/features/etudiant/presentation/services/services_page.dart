import 'package:flutter/material.dart';

import '../../../../core/auth/espace.dart';
import '../../../commun/espace/services_espace_page.dart';
import '../sections.dart';

/// Tous les services de l'étudiant.
class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) => const ServicesEspacePage(
        espace: Espace.etudiant,
        ouvrirSection: ouvrirSection,
      );
}
