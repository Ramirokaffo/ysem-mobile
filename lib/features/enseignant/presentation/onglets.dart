import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/espace.dart';
import '../../commun/espace/centre_notifications_page.dart';
import '../../commun/espace/coque_espace.dart';
import '../../commun/espace/services_espace_page.dart';
import 'sections.dart';

/// Coque de l'espace enseignant : les mêmes quatre onglets que l'étudiant.
class ShellEnseignant extends StatelessWidget {
  const ShellEnseignant({super.key, required this.coque});

  final StatefulNavigationShell coque;

  @override
  Widget build(BuildContext context) =>
      CoqueEspace(espace: Espace.enseignant, coque: coque);
}

/// Tous les services de l'enseignant, venus du registre du portail.
class ServicesEnseignantPage extends StatelessWidget {
  const ServicesEnseignantPage({super.key});

  @override
  Widget build(BuildContext context) => const ServicesEspacePage(
        espace: Espace.enseignant,
        ouvrirSection: ouvrirSectionEnseignant,
      );
}

/// Centre de notifications de l'espace `lecturer`.
class NotificationsEnseignantPage extends StatelessWidget {
  const NotificationsEnseignantPage({super.key});

  @override
  Widget build(BuildContext context) => const CentreNotificationsPage(
        espace: Espace.enseignant,
        sectionDeLAdresse: sectionEnseignantDeLAdresse,
        ouvrirSection: ouvrirSectionEnseignant,
      );
}
