import 'package:flutter/material.dart';

import '../../../core/models/navigation.dart';
import '../../../l10n/app_localizations.dart';

/// Code de la section « Discussions de classe », le même dans les deux
/// registres (`student_portal.navigation`, `lecturers.navigation`).
const codeSectionDiscussions = 'discussions';

/// Icône du bandeau d'accueil qui ouvre les discussions de classe, avec la
/// pastille des messages non lus.
///
/// Elle ne paraît que si le menu offre la section : le serveur la retire à un
/// candidat enseignant (réservée aux recrutés), et tant que le menu n'est pas
/// lu rien n'est promis.
class BoutonDiscussions extends StatelessWidget {
  const BoutonDiscussions({
    super.key,
    required this.navigation,
    required this.ouvrir,
  });

  final Navigation? navigation;
  final VoidCallback ouvrir;

  @override
  Widget build(BuildContext context) {
    final section = navigation?.section(codeSectionDiscussions);
    if (section == null) return const SizedBox.shrink();
    final nonLus = section.badge ?? 0;
    final libelle = section.libelle.isNotEmpty
        ? section.libelle
        : AppLocalizations.of(context).sectionDiscussions;

    return IconButton(
      tooltip: libelle,
      onPressed: ouvrir,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.16),
        foregroundColor: Colors.white,
      ),
      icon: Badge(
        isLabelVisible: nonLus > 0,
        label: Text(nonLus > 99 ? '99+' : '$nonLus'),
        child: const Icon(Icons.forum_outlined),
      ),
    );
  }
}
