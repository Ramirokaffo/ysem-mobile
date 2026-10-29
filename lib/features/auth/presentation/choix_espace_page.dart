import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/charte/charte.dart';
import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../commun/langue.dart';

/// Premier écran : l'étudiant et l'enseignant ne se connectent pas de la
/// même façon (matricule d'un côté, adresse e-mail de l'autre).
class ChoixEspacePage extends StatelessWidget {
  const ChoixEspacePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final haut = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          BandeauMarque(
            image: 'assets/images/hero.jpg',
            rayonBas: 32,
            padding: EdgeInsets.fromLTRB(20, haut + 12, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: SelecteurLangue(),
                ),
                const SizedBox(height: 28),
                const YsemLogo(variante: VarianteLogo.blanc, hauteur: 76),
                const SizedBox(height: 28),
                Text(
                  t.bienvenue,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  t.choisirEspace,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CarteEspace(
                  icone: Icons.school_rounded,
                  titre: t.espaceEtudiant,
                  description: t.espaceEtudiantDescription,
                  onTap: () => context.push(Routes.connexionEtudiant),
                ),
                const SizedBox(height: 12),
                _CarteEspace(
                  icone: Icons.co_present_rounded,
                  titre: t.espaceEnseignant,
                  description: t.espaceEnseignantDescription,
                  onTap: () => context.push(Routes.connexionEnseignant),
                ),
                const SizedBox(height: 32),
                Text(
                  'School of Economics and Management',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteEspace extends StatelessWidget {
  const _CarteEspace({
    required this.icone,
    required this.titre,
    required this.description,
    this.onTap,
  });

  final IconData icone;
  final String titre;
  final String description;

  /// Sans action, la carte est inactive (espace fermé).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actif = onTap != null;
    return Opacity(
      opacity: actif ? 1 : 0.6,
      child: CarteYsem(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: actif ? YsemTokens.of(context).degrade : null,
                color: actif ? null : theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(YsemTokens.rayon),
              ),
              child: Icon(
                icone,
                color: actif ? Colors.white : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (actif)
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
