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
import '../../domain/moratoires.dart';
import 'nouvelle_demande_moratoire_page.dart';

/// « Mes moratoires » : l'historique des demandes et, quand il reste quelque
/// chose à couvrir, le dépôt d'une nouvelle. Une demande ne change rien à la
/// situation financière tant que la scolarité ne l'a pas acceptée.
class MoratoiresPage extends ConsumerWidget {
  const MoratoiresPage({super.key, this.titre});

  final String? titre;

  Future<void> _deposer(BuildContext context, WidgetRef ref, Moratoires etat) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => NouvelleDemandeMoratoirePage(
          montantDemandable: etat.montantDemandable,
          annee: etat.annee?.nom ?? '',
        ),
      ),
    );
    if (message == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    ref.invalidate(moratoiresProvider);
    ref.invalidate(financesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final valeur = ref.watch(moratoiresProvider);
    final etat = valeur.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionMoratoires)),
      floatingActionButton: etat != null && etat.depotPossible
          ? FloatingActionButton.extended(
              onPressed: () => _deposer(context, ref, etat),
              icon: const Icon(Icons.add_rounded),
              label: Text(t.nouvelleDemande),
            )
          : null,
      body: VueAsynchrone<Moratoires>(
        valeur: valeur,
        surRafraichir: () => ref.refresh(moratoiresProvider.future),
        constructeur: (etat) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            _CarteEtat(etat: etat),
            const SizedBox(height: 20),
            Text(t.mesDemandes, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (etat.demandes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: EtatVide(
                    message: t.aucuneDemandeMoratoire,
                    icone: Icons.event_note_outlined),
              ),
            for (final demande in etat.demandes) ...[
              _CarteDemande(demande: demande),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _CarteEtat extends StatelessWidget {
  const _CarteEtat({required this.etat});

  final Moratoires etat;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final enCours = etat.enInstruction;

    return CarteYsem(
      titre: etat.annee == null
          ? t.sectionMoratoires
          : '${t.anneeAcademique} ${etat.annee!.nom}',
      icone: Icons.handshake_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.montantDemandable,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(Formats.montant(etat.montantDemandable ?? 0, langue),
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary)),
          const SizedBox(height: 12),
          if (etat.annee == null)
            Encadre(texte: t.moratoireSansAnnee)
          else if (enCours != null)
            Encadre(
              icone: Icons.hourglass_top_rounded,
              titre: t.demandeMoratoireEnCours,
              texte: t.moratoireAttendreDecision(enCours.reference),
            )
          else if (!etat.depotPossible)
            Encadre(
                icone: Icons.check_circle_outline_rounded,
                texte: t.moratoireRienACouvrir)
          else
            Encadre(texte: t.moratoireExplication),
        ],
      ),
    );
  }
}

class _CarteDemande extends ConsumerStatefulWidget {
  const _CarteDemande({required this.demande});

  final DemandeMoratoireSuivie demande;

  @override
  ConsumerState<_CarteDemande> createState() => _CarteDemandeState();
}

class _CarteDemandeState extends ConsumerState<_CarteDemande> {
  bool _retrait = false;

  Future<void> _retirer() async {
    final t = AppLocalizations.of(context);
    final demande = widget.demande;
    final ok = await confirmer(
      context,
      titre: t.retirerDemande,
      texte: t.retirerMoratoireConfirmation(demande.reference),
      action: t.retirer,
    );
    if (!ok || !mounted) return;
    final messager = ScaffoldMessenger.of(context);
    setState(() => _retrait = true);
    try {
      final message =
          await ref.read(etudiantRepositoryProvider).retirerMoratoire(demande.id);
      messager.showSnackBar(SnackBar(content: Text(message)));
      ref.invalidate(moratoiresProvider);
      ref.invalidate(financesProvider);
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
              Expanded(
                child: Text(
                  demande.reference.isEmpty ? t.demandeMoratoire : demande.reference,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Pastille(demande.statutLibelle,
                  ton: demande.statut == 'withdrawn'
                      ? TonPastille.neutre
                      : Pastille.tonDuStatut(demande.statut)),
            ],
          ),
          const SizedBox(height: 6),
          Text(Formats.montant(demande.montant, langue),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          if (demande.dateSouhaitee != null)
            Text(
                t.reglementSouhaiteLe(
                    Formats.dateLongue(demande.dateSouhaitee, langue)),
                style: secondaire),
          if (demande.deposeeLe != null)
            Text(t.deposeeLe(Formats.horodatage(demande.deposeeLe, langue)),
                style: secondaire),
          if (demande.motif.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(demande.motif,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium),
          ],
          if (demande.pieceJointe) ...[
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
          if (demande.enAttente) ...[
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
