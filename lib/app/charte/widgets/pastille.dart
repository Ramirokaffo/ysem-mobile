import 'package:flutter/material.dart';

import '../../theme.dart';

enum TonPastille { succes, alerte, danger, info, neutre, marque }

/// Petite étiquette d'état (statut d'un paiement, d'un document…).
class Pastille extends StatelessWidget {
  const Pastille(this.libelle, {super.key, this.ton = TonPastille.neutre, this.icone});

  final String libelle;
  final TonPastille ton;
  final IconData? icone;

  /// Ton d'un statut rendu par l'API, d'après son code.
  static TonPastille tonDuStatut(String statut) {
    final s = statut.toLowerCase();
    if (const ['paid', 'paye', 'solde', 'up_to_date', 'a_jour', 'valide', 'validated', 'accorde', 'approved', 'available', 'disponible']
        .any(s.contains)) {
      return TonPastille.succes;
    }
    if (const ['overdue', 'retard', 'echu', 'refuse', 'rejete', 'rejected', 'annule', 'bloque']
        .any(s.contains)) {
      return TonPastille.danger;
    }
    if (s.contains('moratori')) return TonPastille.info;
    if (const ['partial', 'partiel', 'pending', 'attente', 'en_cours']
        .any(s.contains)) {
      return TonPastille.alerte;
    }
    return TonPastille.neutre;
  }

  @override
  Widget build(BuildContext context) {
    final jetons = YsemTokens.of(context);
    final schema = Theme.of(context).colorScheme;
    final couleur = switch (ton) {
      TonPastille.succes => jetons.succes,
      TonPastille.alerte => jetons.alerte,
      TonPastille.danger => jetons.danger,
      TonPastille.info => jetons.info,
      TonPastille.neutre => jetons.neutre,
      TonPastille.marque => schema.primary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 14, color: couleur),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              libelle,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: couleur,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
