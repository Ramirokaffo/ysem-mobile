import 'package:flutter/material.dart';

import '../../../app/charte/charte.dart';
import '../../../l10n/app_localizations.dart';

/// Écran d'attente des rubriques encore à construire dans l'application :
/// elles restent ouvertes sur le portail web.
class AImplementerPage extends StatelessWidget {
  const AImplementerPage({super.key, required this.titre, this.icone});

  final String titre;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: YsemTokens.of(context).degrade,
                  shape: BoxShape.circle,
                ),
                child: Icon(icone ?? Icons.construction_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text(t.aImplementer,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                t.aImplementerDetail,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
