import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../core/network/api_exception.dart';
import '../../l10n/app_localizations.dart';

/// Télécharge un document du serveur (reçu, relevé…) puis l'ouvre avec
/// l'application du téléphone qui sait le lire.
///
/// Le fichier passe par le cache de l'application : le serveur reste la
/// source, et le document est recomposé à chaque demande comme sur le web.
///
/// Rend vrai si le document a été reçu (même si aucune application du
/// téléphone ne sait l'ouvrir) : un téléchargement constaté par le service
/// doit alors être relu.
Future<bool> telechargerEtOuvrir(
  BuildContext context,
  Future<File> Function() telecharger,
) async {
  final t = AppLocalizations.of(context);
  final messager = ScaffoldMessenger.of(context);
  messager
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(
        children: [
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Text(t.telechargementEnCours),
        ],
      ),
      duration: const Duration(minutes: 1),
    ));

  try {
    final fichier = await telecharger();
    messager.hideCurrentSnackBar();
    final resultat = await OpenFilex.open(fichier.path);
    if (resultat.type != ResultType.done) {
      messager.showSnackBar(SnackBar(content: Text(t.ouvertureImpossible)));
    }
    return true;
  } on ApiException catch (e) {
    messager
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.message)));
  } catch (_) {
    messager
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t.erreurInattendue)));
  }
  return false;
}
