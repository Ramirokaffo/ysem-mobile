import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../commun/position.dart';

/// Relève la position avant un envoi qui l'exige. Rend `(true, null)` quand
/// rien n'est exigé, `(true, position)` une fois relevée, `(false, null)`
/// quand elle n'a pas pu l'être — l'étudiant lit pourquoi, rien n'est envoyé.
Future<(bool, PositionRelevee?)> positionPourEnvoi(
    BuildContext context, bool exigee) async {
  if (!exigee) return (true, null);
  final t = AppLocalizations.of(context);
  final messager = ScaffoldMessenger.of(context);
  messager.showSnackBar(SnackBar(
    content: Text(t.releveDePosition),
    duration: const Duration(seconds: 20),
  ));
  try {
    final position = await releverPosition();
    messager.hideCurrentSnackBar();
    return (true, position);
  } on PositionIndisponible catch (e) {
    messager.hideCurrentSnackBar();
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.location_off_outlined),
          title: Text(t.positionIndisponible),
          content: Text(switch (e.raison) {
            RaisonPosition.serviceDesactive => t.positionServiceDesactive,
            RaisonPosition.refusee => t.positionRefusee,
            RaisonPosition.refuseeDefinitivement => t.positionRefuseeReglages,
            RaisonPosition.delai => t.positionDelai,
          }),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.compris),
            ),
          ],
        ),
      );
    }
    return (false, null);
  }
}
