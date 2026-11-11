import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

import '../../core/network/api_exception.dart';
import '../../l10n/app_localizations.dart';

/// Télécharge un document du serveur (reçu, relevé…) puis l'ouvre avec
/// l'application du téléphone qui sait le lire.
///
/// Le fichier passe par le cache de l'application : le serveur reste la
/// source, et le document est recomposé à chaque demande comme sur le web.
///
/// Quand aucune application du téléphone ne sait l'ouvrir (un `.docx` sans
/// suite bureautique, une archive…), le document n'est pas perdu : on propose
/// de l'enregistrer dans le téléphone par le sélecteur du système (dossier
/// Téléchargements, Drive…), sans permission de stockage à demander.
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
      if (context.mounted) {
        await proposerEnregistrement(context, fichier);
      } else {
        messager.showSnackBar(SnackBar(content: Text(t.ouvertureImpossible)));
      }
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

/// Explique qu'aucune application ne sait ouvrir [fichier] et propose de
/// l'enregistrer dans le téléphone.
Future<void> proposerEnregistrement(BuildContext context, File fichier) async {
  final t = AppLocalizations.of(context);
  final messager = ScaffoldMessenger.of(context);
  final nom = p.basename(fichier.path);
  final enregistrer = await showDialog<bool>(
    context: context,
    builder: (contexte) => AlertDialog(
      icon: const Icon(Icons.save_alt_rounded),
      title: Text(t.ouvertureImpossibleTitre),
      content: Text(t.ouvertureImpossibleEnregistrer(nom)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(contexte).pop(false),
          child: Text(t.annuler),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(contexte).pop(true),
          icon: const Icon(Icons.download_rounded),
          label: Text(t.enregistrerDansTelephone),
        ),
      ],
    ),
  );
  if (enregistrer != true) return;
  try {
    final destination = await FilePicker.saveFile(
      fileName: nom,
      bytes: await fichier.readAsBytes(),
      mimeType: lookupMimeType(nom) ?? 'application/octet-stream',
    );
    // `null` : l'utilisateur a refermé le sélecteur sans choisir.
    if (destination != null) {
      messager.showSnackBar(SnackBar(content: Text(t.documentEnregistre)));
    }
  } catch (_) {
    messager.showSnackBar(SnackBar(content: Text(t.enregistrementImpossible)));
  }
}
