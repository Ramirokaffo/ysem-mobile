import 'package:flutter/material.dart';

import '../../app/charte/charte.dart';
import '../../core/format/formats.dart';
import '../../core/network/api_exception.dart';
import '../../l10n/app_localizations.dart';
import 'langue.dart';

/// Ce qu'un envoi refusé doit dire en tête du formulaire : le message du
/// serveur, ses erreurs d'ensemble (`__all__`) et celles des champs que
/// l'écran ne montre pas. Les autres s'affichent sous leur champ.
List<String> erreursGlobales(ApiException e, Set<String> champsAffiches) => [
      e.message,
      for (final MapEntry(key: champ, value: messages) in e.erreurs.entries)
        if (!champsAffiches.contains(champ)) ...messages,
    ];

/// Bandeau d'erreur en tête d'un formulaire.
class BandeauErreurs extends StatelessWidget {
  const BandeauErreurs({super.key, required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleur = theme.colorScheme.onErrorContainer;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: couleur),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final m in messages)
                  Text(m,
                      style:
                          theme.textTheme.bodySmall?.copyWith(color: couleur)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmation d'un geste qui ne se défait pas (retrait d'une demande).
Future<bool> confirmer(
  BuildContext context, {
  required String titre,
  required String texte,
  required String action,
}) async {
  final t = AppLocalizations.of(context);
  final reponse = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titre),
      content: Text(texte),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(t.annuler),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return reponse == true;
}

/// Champ de date : ouvre le calendrier du téléphone, et se vide d'un geste
/// quand il est facultatif.
class ChampDate extends StatelessWidget {
  const ChampDate({
    super.key,
    required this.libelle,
    required this.valeur,
    required this.surChoix,
    required this.premiere,
    required this.derniere,
    this.icone = Icons.event_rounded,
    this.erreur,
    this.effacable = false,
  });

  final String libelle;
  final DateTime? valeur;
  final ValueChanged<DateTime?> surChoix;
  final DateTime premiere;
  final DateTime derniere;
  final IconData icone;
  final String? erreur;
  final bool effacable;

  Future<void> _choisir(BuildContext context) async {
    final depart = valeur ?? DateTime.now();
    final choisie = await showDatePicker(
      context: context,
      initialDate: depart.isBefore(premiere)
          ? premiere
          : depart.isAfter(derniere)
              ? derniere
              : depart,
      firstDate: premiere,
      lastDate: derniere,
    );
    if (choisie != null) surChoix(choisie);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return InkWell(
      onTap: () => _choisir(context),
      borderRadius: BorderRadius.circular(YsemTokens.rayon),
      child: InputDecorator(
        isEmpty: valeur == null,
        decoration: InputDecoration(
          labelText: libelle,
          prefixIcon: Icon(icone),
          errorText: erreur,
          errorMaxLines: 3,
          suffixIcon: effacable && valeur != null
              ? IconButton(
                  tooltip: t.effacer,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => surChoix(null),
                )
              : null,
        ),
        child: Text(valeur == null
            ? ''
            : Formats.dateLongue(valeur, langueCourante(context))),
      ),
    );
  }
}
