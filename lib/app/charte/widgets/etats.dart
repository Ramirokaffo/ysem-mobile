import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../l10n/app_localizations.dart';

/// Rien à montrer : une icône et une phrase, jamais un écran blanc.
class EtatVide extends StatelessWidget {
  const EtatVide({super.key, required this.message, this.icone = Icons.inbox_outlined});

  final String message;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        children: [
          Icon(icone, size: 36, color: theme.colorScheme.outline),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Une erreur, dite avec le message du serveur quand il en a donné un.
class EtatErreur extends StatelessWidget {
  const EtatErreur({super.key, required this.erreur, this.surReessayer});

  final Object erreur;
  final VoidCallback? surReessayer;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final api = erreur is ApiException ? erreur as ApiException : null;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            api?.estErreurReseau == true
                ? Icons.wifi_off_rounded
                : Icons.error_outline_rounded,
            size: 44,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            api?.message ?? t.erreurInattendue,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          if (surReessayer != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: surReessayer,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(t.reessayer),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chargement, erreur ou données d'une lecture, avec « tirer pour
/// rafraîchir ». [constructeur] doit rendre une vue défilante.
class VueAsynchrone<T> extends StatelessWidget {
  const VueAsynchrone({
    super.key,
    required this.valeur,
    required this.surRafraichir,
    required this.constructeur,
  });

  final AsyncValue<T> valeur;
  final Future<void> Function() surRafraichir;
  final Widget Function(T donnees) constructeur;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: surRafraichir,
      child: valeur.when(
        data: constructeur,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erreur, _) => LayoutBuilder(
          builder: (context, contraintes) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: contraintes.maxHeight),
              child: Center(
                child: EtatErreur(erreur: erreur, surReessayer: surRafraichir),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
