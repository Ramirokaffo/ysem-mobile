import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/charte/charte.dart';
import '../../../core/auth/espace.dart';
import '../../../core/models/navigation.dart';
import '../../../core/navigation/icones_sections.dart';
import '../../../l10n/app_localizations.dart';
import 'centre_notifications_page.dart';
import 'menu.dart';

/// Tous les services d'un espace, groupés comme le menu du portail web :
/// la liste vient du registre du serveur, jamais d'une liste tenue ici.
class ServicesEspacePage extends ConsumerWidget {
  const ServicesEspacePage({
    super.key,
    required this.espace,
    required this.ouvrirSection,
  });

  final Espace espace;
  final OuvreurSection ouvrirSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.ongletServices)),
      body: VueAsynchrone<Navigation>(
        valeur: ref.watch(menuProvider(espace)),
        surRafraichir: () =>
            ref.read(menuProvider(espace).notifier).rafraichir(complet: true),
        constructeur: (navigation) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            for (final groupe in navigation.groupes)
              if (groupe.sections.any((s) => s.code != 'dashboard'))
                _Groupe(groupe: groupe, ouvrirSection: ouvrirSection),
          ],
        ),
      ),
    );
  }
}

class _Groupe extends StatelessWidget {
  const _Groupe({required this.groupe, required this.ouvrirSection});

  final GroupeNavigation groupe;
  final OuvreurSection ouvrirSection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections =
        groupe.sections.where((s) => s.code != 'dashboard').toList();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (groupe.titre.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                groupe.titre.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, section) in sections.indexed) ...[
                  if (i > 0) const Divider(indent: 68),
                  _TuileSection(
                    section: section,
                    onTap: () => ouvrirSection(context, section.code),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TuileSection extends StatelessWidget {
  const _TuileSection({required this.section, required this.onTap});

  final SectionNavigation section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = section.badge ?? 0;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(YsemTokens.rayonPetit),
        ),
        child: Icon(iconeDeSection(section.icone),
            color: theme.colorScheme.onSecondaryContainer, size: 22),
      ),
      title: Text(section.libelle,
          style:
              theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
      subtitle: section.description.isEmpty
          ? null
          : Text(section.description,
              maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge > 0) Badge(label: Text(badge > 99 ? '99+' : '$badge')),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
      onTap: onTap,
    );
  }
}
