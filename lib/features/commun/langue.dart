import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// Langue de l'interface affichée (`fr` ou `en`).
String langueCourante(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

/// Sélecteur compact « FR · EN », pour les écrans sans profil (choix de
/// l'espace, connexion) : même rôle que le cookie `ysem_langue` du web.
/// Posé sur le bandeau bleu, il s'écrit en blanc.
class SelecteurLangue extends ConsumerWidget {
  const SelecteurLangue({super.key, this.surFondBleu = true});

  final bool surFondBleu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actuelle = langueCourante(context);
    final couleur = surFondBleu
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    Widget option(String code) {
      final choisie = code == actuelle;
      return Semantics(
        selected: choisie,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: choisie
              ? null
              : () => ref.read(langueForceeProvider.notifier).definir(code),
          child: Container(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: choisie ? couleur.withValues(alpha: 0.18) : null,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              code.toUpperCase(),
              style: TextStyle(
                color: couleur.withValues(alpha: choisie ? 1 : 0.75),
                fontWeight: choisie ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: couleur.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [option('fr'), option('en')],
      ),
    );
  }
}
