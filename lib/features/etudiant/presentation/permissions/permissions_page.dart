import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/formulaire.dart';
import '../../../commun/langue.dart';
import '../../application/sections.dart';
import '../../domain/permissions.dart';
import 'nouvelle_permission_page.dart';

/// « Mes permissions » : les demandes déposées et leur décision. Une demande
/// ne décharge de rien tant que le service ne l'a pas accordée.
class PermissionsPage extends ConsumerWidget {
  const PermissionsPage({super.key, this.titre});

  final String? titre;

  Future<void> _deposer(BuildContext context, WidgetRef ref) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const NouvellePermissionPage()),
    );
    if (message == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    ref.invalidate(permissionsProvider);
    ref.invalidate(disciplineProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final valeur = ref.watch(permissionsProvider(null));
    final etat = valeur.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionPermissions)),
      floatingActionButton: etat != null && etat.depotOuvert
          ? FloatingActionButton.extended(
              onPressed: () => _deposer(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: Text(t.demanderPermission),
            )
          : null,
      body: VueAsynchrone<Permissions>(
        valeur: valeur,
        surRafraichir: () => ref.refresh(permissionsProvider(null).future),
        constructeur: (etat) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            if (!etat.depotOuvert)
              Encadre(
                  icone: Icons.lock_outline_rounded,
                  texte: t.depotPermissionsFerme)
            else
              Encadre(texte: t.permissionExplication),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(t.mesDemandes,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (etat.enAttente > 0)
                  Pastille(t.nbEnAttente(etat.enAttente),
                      ton: TonPastille.alerte),
              ],
            ),
            const SizedBox(height: 8),
            if (etat.mesDemandes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: EtatVide(
                    message: t.aucuneDemandePermission,
                    icone: Icons.event_busy_outlined),
              ),
            for (final demande in etat.mesDemandes) ...[
              _CarteDemande(demande: demande),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _CarteDemande extends ConsumerStatefulWidget {
  const _CarteDemande({required this.demande});

  final DemandePermission demande;

  @override
  ConsumerState<_CarteDemande> createState() => _CarteDemandeState();
}

class _CarteDemandeState extends ConsumerState<_CarteDemande> {
  bool _retrait = false;

  Future<void> _retirer() async {
    final t = AppLocalizations.of(context);
    final ok = await confirmer(
      context,
      titre: t.retirerDemande,
      texte: t.retirerPermissionConfirmation,
      action: t.retirer,
    );
    if (!ok || !mounted) return;
    final messager = ScaffoldMessenger.of(context);
    setState(() => _retrait = true);
    try {
      final message = await ref
          .read(etudiantRepositoryProvider)
          .retirerPermission(widget.demande.id);
      messager.showSnackBar(SnackBar(content: Text(message)));
      ref.invalidate(permissionsProvider);
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
      if (mounted) setState(() => _retrait = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final demande = widget.demande;
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return CarteYsem(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                demande.estRetard
                    ? Icons.schedule_rounded
                    : Icons.event_busy_outlined,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t.permissionDe(demande.typeLibelle),
                    style: theme.textTheme.titleSmall),
              ),
              Pastille(
                demande.statutLibelle,
                ton: demande.statut == 'annulee'
                    ? TonPastille.neutre
                    : Pastille.tonDuStatut(demande.statut),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (demande.deposeeLe != null)
                t.deposeeLe(Formats.horodatage(demande.deposeeLe, langue)),
              if (demande.saisieParLeService) t.saisieAuBureau,
            ].join(' · '),
            style: secondaire,
          ),
          const SizedBox(height: 8),
          for (final seance in demande.seances)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle,
                      size: 6, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      [
                        Formats.jourCourt(seance.date, langue),
                        Formats.plage(seance.debut, seance.fin),
                        seance.cours?.libelle(langue) ?? '',
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          if (demande.estRetard && demande.heureArriveePrevue != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(t.arriveeAnnoncee(demande.heureArriveePrevue!),
                  style: secondaire),
            ),
          if (demande.motif.isNotEmpty || demande.explication.isNotEmpty) ...[
            const SizedBox(height: 8),
            if (demande.motif.isNotEmpty)
              Text(demande.motif, style: theme.textTheme.labelLarge),
            if (demande.explication.isNotEmpty)
              Text(demande.explication,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium),
          ],
          if (demande.justificatifFourni) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.attach_file_rounded,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(t.pieceJointeFournie, style: secondaire),
              ],
            ),
          ],
          if (demande.commentaireDecision.isNotEmpty) ...[
            const SizedBox(height: 10),
            Encadre(
              icone: Icons.forum_outlined,
              titre: demande.decideeLe == null
                  ? t.reponseDuService
                  : t.reponseDuServiceLe(
                      Formats.dateLongue(demande.decideeLe, langue)),
              texte: demande.commentaireDecision,
            ),
          ],
          if (demande.ouverte) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _retrait ? null : _retirer,
                icon: _retrait
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.undo_rounded),
                label: Text(t.retirerDemande),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
