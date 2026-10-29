import 'package:flutter/material.dart';

import '../../../../core/auth/espace.dart';
import '../../../commun/espace/centre_notifications_page.dart';
import '../sections.dart';

/// Centre de notifications de l'espace `student`.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) => const CentreNotificationsPage(
        espace: Espace.etudiant,
        sectionDeLAdresse: sectionDeLAdresse,
        ouvrirSection: ouvrirSection,
      );
}
