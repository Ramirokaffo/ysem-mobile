import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../commun/position.dart';

/// Relève la position avant un envoi qui l'exige. Rend `(true, null)` quand
/// rien n'est exigé, `(true, position)` une fois relevée, `(false, null)`
/// quand elle n'a pas pu l'être — l'étudiant lit pourquoi, rien n'est envoyé.
///
/// `precisionMax` est le seuil du serveur, connu du paquet : sans réseau, une
/// position trop imprécise doit se refuser ici, tant que le délégué est dans la
/// salle pour réessayer. `sansReseau` laisse plus de temps au GPS.
Future<(bool, PositionRelevee?)> positionPourEnvoi(
  BuildContext context,
  bool exigee, {
  int? precisionMax,
  bool sansReseau = false,
}) async {
  if (!exigee) return (true, null);
  final delai = Duration(seconds: sansReseau ? 90 : 25);
  final t = AppLocalizations.of(context);
  final messager = ScaffoldMessenger.of(context);
  messager.showSnackBar(SnackBar(
    content: Text(t.releveDePosition),
    duration: delai,
  ));
  try {
    final position = await releverPosition(delai: delai);
    messager.hideCurrentSnackBar();
    if (precisionMax != null && position.precision > precisionMax) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.location_searching_rounded),
            title: Text(t.positionIndisponible),
            content: Text(t.positionTropImprecise(
                position.precision.round(), precisionMax)),
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
