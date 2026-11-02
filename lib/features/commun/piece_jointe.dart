import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Un fichier choisi sur l'appareil, lu en mémoire : les pièces des demandes
/// sont petites, et un fichier ouvert par un fournisseur de contenu Android
/// n'a pas toujours de chemin.
class PieceAJoindre {
  const PieceAJoindre({required this.nom, required this.octets});

  final String nom;
  final Uint8List octets;

  int get taille => octets.length;

  MultipartFile versMultipart() =>
      MultipartFile.fromBytes(octets, filename: nom);
}

/// Les pièces que le service sait lire : un PDF ou une photo.
const extensionsPieces = ['pdf', 'jpg', 'jpeg', 'png'];

/// 5 Mo, la limite des pièces du système (`main.validators`).
const tailleMaxPiece = 5 * 1024 * 1024;

/// `340 Ko`, `1,2 Mo`.
String tailleLisible(int octets, String langue) {
  if (octets < 1024 * 1024) return '${(octets / 1024).ceil()} Ko';
  final mo = (octets / (1024 * 1024)).toStringAsFixed(1);
  return '${langue == 'en' ? mo : mo.replaceAll('.', ',')} ${langue == 'en' ? 'MB' : 'Mo'}';
}

/// Ouvre le sélecteur de l'appareil et rend les fichiers choisis, au plus
/// `restant`. Ceux qui dépassent 5 Mo sont écartés, et l'étudiant le lit.
Future<List<PieceAJoindre>> choisirPieces(
  BuildContext context, {
  List<String> extensions = extensionsPieces,
  int restant = 1,
  int tailleMax = tailleMaxPiece,
  String? messageTropLourd,
}) async {
  if (restant <= 0) return const [];
  final t = AppLocalizations.of(context);
  final messager = ScaffoldMessenger.of(context);
  final fichiers = restant == 1
      ? [
          ?await FilePicker.pickFile(
              type: FileType.custom, allowedExtensions: extensions),
        ]
      : await FilePicker.pickFiles(
          type: FileType.custom, allowedExtensions: extensions);
  final pieces = <PieceAJoindre>[];
  var tropLourdes = 0;
  for (final fichier in fichiers.take(restant)) {
    final octets = await fichier.xFile.readAsBytes();
    if (octets.length > tailleMax) {
      tropLourdes++;
    } else {
      pieces.add(PieceAJoindre(nom: fichier.name, octets: octets));
    }
  }
  if (tropLourdes > 0) {
    messager.showSnackBar(SnackBar(content: Text(messageTropLourd ?? t.pieceTropLourde)));
  } else if (fichiers.length > restant) {
    messager.showSnackBar(SnackBar(content: Text(t.piecesAuPlus(restant))));
  }
  return pieces;
}

IconData iconeDeFichier(String nom) {
  final n = nom.toLowerCase();
  if (n.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
  if (RegExp(r'\.(jpe?g|png|gif|webp|heic)$').hasMatch(n)) {
    return Icons.image_outlined;
  }
  return Icons.insert_drive_file_outlined;
}

/// Une pièce choisie, en puce retirable (composeur de message).
class PucePiece extends StatelessWidget {
  const PucePiece({super.key, required this.piece, this.surRetrait});

  final PieceAJoindre piece;
  final VoidCallback? surRetrait;

  @override
  Widget build(BuildContext context) {
    final langue = Localizations.localeOf(context).languageCode;
    return InputChip(
      avatar: Icon(iconeDeFichier(piece.nom), size: 18),
      label: Text('${piece.nom} · ${tailleLisible(piece.taille, langue)}',
          overflow: TextOverflow.ellipsis),
      onDeleted: surRetrait,
    );
  }
}

/// Plusieurs pièces (preuves d'une suggestion) : liste et bouton d'ajout.
class ChampPiecesJointes extends StatelessWidget {
  const ChampPiecesJointes({
    super.key,
    required this.libelle,
    required this.pieces,
    required this.maximum,
    required this.surChangement,
    this.extensions = extensionsPieces,
    this.aide,
    this.actif = true,
  });

  final String libelle;
  final String? aide;
  final List<PieceAJoindre> pieces;
  final int maximum;
  final List<String> extensions;
  final ValueChanged<List<PieceAJoindre>> surChangement;
  final bool actif;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final restant = maximum - pieces.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(libelle, style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final piece in pieces)
              PucePiece(
                piece: piece,
                surRetrait: actif
                    ? () => surChangement([...pieces]..remove(piece))
                    : null,
              ),
          ],
        ),
        if (restant > 0) ...[
          if (pieces.isNotEmpty) const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: actif
                ? () async {
                    final ajoutees = await choisirPieces(context,
                        extensions: extensions, restant: restant);
                    if (ajoutees.isNotEmpty) {
                      surChangement([...pieces, ...ajoutees]);
                    }
                  }
                : null,
            icon: const Icon(Icons.attach_file_rounded),
            label: Text(t.ajouterFichiers),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Text(
            aide ?? t.piecesAuPlus(maximum),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Champ « Pièce justificative » : choisir, remplacer, retirer. La taille est
/// contrôlée sur l'appareil, pour ne pas envoyer pour rien.
class ChampPieceJointe extends StatelessWidget {
  const ChampPieceJointe({
    super.key,
    required this.libelle,
    required this.piece,
    required this.surChoix,
    this.aide,
    this.erreur,
    this.actif = true,
    this.extensions = extensionsPieces,
  });

  final String libelle;
  final String? aide;
  final String? erreur;
  final List<String> extensions;
  final PieceAJoindre? piece;
  final ValueChanged<PieceAJoindre?> surChoix;
  final bool actif;

  Future<void> _choisir(BuildContext context) async {
    final pieces = await choisirPieces(context, extensions: extensions);
    if (pieces.isNotEmpty) surChoix(pieces.first);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = Localizations.localeOf(context).languageCode;
    final couleurBord =
        erreur != null ? theme.colorScheme.error : theme.colorScheme.outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(libelle, style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        if (piece == null)
          OutlinedButton.icon(
            onPressed: actif ? () => _choisir(context) : null,
            style: OutlinedButton.styleFrom(side: BorderSide(color: couleurBord)),
            icon: const Icon(Icons.attach_file_rounded),
            label: Text(t.choisirFichier),
          )
        else
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
            decoration: BoxDecoration(
              border: Border.all(color: couleurBord),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(iconeDeFichier(piece!.nom),
                    color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(piece!.nom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium),
                      Text(tailleLisible(piece!.taille, langue),
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: t.remplacerFichier,
                  onPressed: actif ? () => _choisir(context) : null,
                  icon: const Icon(Icons.swap_horiz_rounded),
                ),
                IconButton(
                  tooltip: t.retirerFichier,
                  onPressed: actif ? () => surChoix(null) : null,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        if (erreur != null || aide != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Text(
              erreur ?? aide!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: erreur != null
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
