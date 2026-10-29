import 'package:flutter/material.dart';

import '../../../app/charte/charte.dart';

/// En-tête des écrans de connexion : le bandeau de marque, compact, avec
/// retour, logo et intitulé de l'étape.
class EnteteConnexion extends StatelessWidget {
  const EnteteConnexion({
    super.key,
    required this.titre,
    required this.sousTitre,
    this.retour = true,
    this.actions = const [],
  });

  final String titre;
  final String sousTitre;
  final bool retour;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final haut = MediaQuery.paddingOf(context).top;
    return BandeauMarque(
      image: 'assets/images/hero.jpg',
      padding: EdgeInsets.fromLTRB(8, haut + 4, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (retour && Navigator.of(context).canPop())
                const BackButton(color: Colors.white)
              else
                const SizedBox(height: 48, width: 8),
              const Spacer(),
              ...actions,
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                const YsemLogo(variante: VarianteLogo.blanc, hauteur: 48),
                const SizedBox(height: 20),
                Text(
                  titre,
                  style:
                      theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  sousTitre,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
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

/// Bloc d'erreur sous un formulaire : le message du serveur, déjà traduit.
class MessageErreur extends StatelessWidget {
  const MessageErreur(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: schema.errorContainer,
          borderRadius: BorderRadius.circular(YsemTokens.rayonPetit),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded,
                color: schema.onErrorContainer, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: schema.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton principal avec indicateur d'attente.
class BoutonEnvoi extends StatelessWidget {
  const BoutonEnvoi({
    super.key,
    required this.libelle,
    required this.enCours,
    required this.onPressed,
  });

  final String libelle;
  final bool enCours;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: enCours ? null : onPressed,
      child: enCours
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Text(libelle),
    );
  }
}
