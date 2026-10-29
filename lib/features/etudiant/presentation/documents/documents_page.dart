import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../../commun/telechargement.dart';
import '../../application/sections.dart';
import '../../domain/documents.dart';
import '../../domain/modeles.dart';

/// « Mes documents » : les documents officiels du dossier, année par année.
///
/// Le portail ne remet que le certificat de scolarité, et seulement quand la
/// situation financière de l'année est régularisée — sinon le motif est dit.
class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionDocuments)),
      body: VueAsynchrone<Documents>(
        valeur: ref.watch(documentsProvider),
        surRafraichir: () => ref.refresh(documentsProvider.future),
        constructeur: (donnees) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (donnees.documents.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EtatVide(
                    message: t.aucunDocumentDossier,
                    icone: Icons.folder_off_outlined),
              )
            else ...[
              for (final (annee, documents) in donnees.parAnnee) ...[
                if (annee.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                    child: Text(annee, style: theme.textTheme.titleMedium),
                  ),
                for (final document in documents) ...[
                  _CarteDocument(document: document),
                  const SizedBox(height: 12),
                ],
              ],
              const SizedBox(height: 4),
              Text(
                t.documentsAuGuichet,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CarteDocument extends ConsumerWidget {
  const _CarteDocument({required this.document});

  final DocumentOfficiel document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final dates = [
      if (document.creeLe != null)
        t.documentEtabliLe(Formats.dateLongue(document.creeLe, langue)),
      if (document.dechargeLe != null)
        t.documentRetireLe(Formats.dateLongue(document.dechargeLe, langue)),
    ];

    return CarteYsem(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(
                  document.telechargeable
                      ? Icons.workspace_premium_outlined
                      : Icons.description_outlined,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(document.typeLibelle,
                        style: theme.textTheme.titleSmall),
                    if (document.reference.isNotEmpty)
                      Text(document.reference,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: 0.3)),
                    for (final date in dates)
                      Text(date,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (document.statutLibelle.isNotEmpty) ...[
                const SizedBox(width: 8),
                Pastille(document.statutLibelle,
                    ton: Pastille.tonDuStatut(document.statut)),
              ],
            ],
          ),
          if (document.telechargeable && document.id != null) ...[
            const SizedBox(height: 14),
            if (document.autorise)
              FilledButton.icon(
                onPressed: () => telechargerEtOuvrir(
                  context,
                  () => ref
                      .read(etudiantRepositoryProvider)
                      .certificatScolarite(document.id!),
                ),
                icon: const Icon(Icons.download_rounded),
                label: Text(t.telechargerCertificat),
              )
            else
              _Blocage(motif: document.motifBlocage),
          ],
        ],
      ),
    );
  }
}

/// Le certificat est retenu : on dit pourquoi, au lieu d'un bouton inerte.
class _Blocage extends StatelessWidget {
  const _Blocage({required this.motif});

  final String motif;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final alerte = YsemTokens.of(context).alerte;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alerte.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(YsemTokens.rayonPetit),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, size: 20, color: alerte),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.certificatIndisponible,
                    style: theme.textTheme.titleSmall?.copyWith(color: alerte)),
                if (motif.isNotEmpty)
                  Text(motif, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
