import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/formulaire.dart';
import '../../../commun/langue.dart';
import '../../../commun/telechargement.dart';
import '../../application/sections.dart';
import '../../domain/reinscription.dart';
import 'declarer_versement_page.dart';

/// « Mes versements déclarés » : les comptes de l'établissement, les
/// versements bancaires déclarés pour l'année active et leur vérification.
/// Ouvert depuis la réinscription et depuis la situation financière.
class VersementsPage extends ConsumerWidget {
  const VersementsPage({super.key, this.trancheVisee});

  /// Tranche proposée par défaut dans le formulaire (première tranche).
  final int? trancheVisee;

  Future<void> _declarer(
      BuildContext context, WidgetRef ref, Versements etat) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            DeclarerVersementPage(etat: etat, trancheVisee: trancheVisee),
      ),
    );
    if (message == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    _relire(ref);
  }

  static void _relire(WidgetRef ref) {
    ref.invalidate(versementsProvider);
    ref.invalidate(reinscriptionProvider);
    ref.invalidate(financesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final valeur = ref.watch(versementsProvider);
    final etat = valeur.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(t.versementsDeclares)),
      floatingActionButton: etat != null &&
              etat.ouvert &&
              (etat.montantDeclarable ?? 0) > 0
          ? FloatingActionButton.extended(
              onPressed: () => _declarer(context, ref, etat),
              icon: const Icon(Icons.add_rounded),
              label: Text(t.declarerUnVersement),
            )
          : null,
      body: VueAsynchrone<Versements>(
        valeur: valeur,
        surRafraichir: () => ref.refresh(versementsProvider.future),
        constructeur: (etat) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            if (!etat.ouvert)
              Encadre(
                icone: Icons.storefront_outlined,
                texte: etat.motifFermeture.isEmpty
                    ? t.versementsFermes
                    : etat.motifFermeture,
              )
            else ...[
              Encadre(texte: t.versementExplication),
              const SizedBox(height: 16),
              _CarteMontants(etat: etat),
              for (final compte in etat.comptes) ...[
                const SizedBox(height: 12),
                _CarteCompte(compte: compte),
              ],
            ],
            const SizedBox(height: 20),
            Text(t.mesDeclarations,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (etat.declarations.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: EtatVide(
                    message: t.aucuneDeclaration,
                    icone: Icons.receipt_long_outlined),
              ),
            for (final declaration in etat.declarations) ...[
              _CarteDeclaration(declaration: declaration),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _CarteMontants extends StatelessWidget {
  const _CarteMontants({required this.etat});

  final Versements etat;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    Widget bloc(String libelle, double? valeur, Color? couleur) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(libelle,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(Formats.montant(valeur ?? 0, langue),
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800, color: couleur)),
              ),
            ],
          ),
        );
    return CarteYsem(
      child: Row(
        children: [
          bloc(t.resteADeclarer, etat.montantDeclarable,
              theme.colorScheme.primary),
          const SizedBox(width: 12),
          bloc(t.enVerification, etat.montantEnVerification, null),
        ],
      ),
    );
  }
}

class _CarteCompte extends StatelessWidget {
  const _CarteCompte({required this.compte});

  final CompteBancaire compte;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return CarteYsem(
      titre: compte.banque,
      icone: Icons.account_balance_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compte.intitule.isNotEmpty)
            Text(compte.intitule, style: theme.textTheme.bodyMedium),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  compte.numero,
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
              IconButton(
                tooltip: t.copierNumero,
                onPressed: () async {
                  final messager = ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(text: compte.numero));
                  messager.showSnackBar(
                      SnackBar(content: Text(t.numeroCopie)));
                },
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
          if (compte.agence.isNotEmpty) Text(compte.agence, style: secondaire),
          if (compte.consignes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(compte.consignes, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

TonPastille _tonDeclaration(String statut) => switch (statut) {
      'validee' => TonPastille.succes,
      'rejetee' => TonPastille.danger,
      'en_attente' => TonPastille.alerte,
      _ => TonPastille.neutre,
    };

class _CarteDeclaration extends ConsumerStatefulWidget {
  const _CarteDeclaration({required this.declaration});

  final DeclarationVersement declaration;

  @override
  ConsumerState<_CarteDeclaration> createState() => _CarteDeclarationState();
}

class _CarteDeclarationState extends ConsumerState<_CarteDeclaration> {
  bool _retrait = false;

  Future<void> _retirer() async {
    final t = AppLocalizations.of(context);
    final d = widget.declaration;
    final ok = await confirmer(
      context,
      titre: t.retirerDeclaration,
      texte: t.retirerDeclarationConfirmation(d.reference),
      action: t.retirer,
    );
    if (!ok || !mounted) return;
    final messager = ScaffoldMessenger.of(context);
    setState(() => _retrait = true);
    try {
      final message =
          await ref.read(etudiantRepositoryProvider).retirerDeclaration(d.id);
      messager.showSnackBar(SnackBar(content: Text(message)));
      VersementsPage._relire(ref);
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
    final d = widget.declaration;
    final depot = ref.read(etudiantRepositoryProvider);
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final retenuDifferent = d.montantRetenu != null &&
        d.statut == 'validee' &&
        (d.montantRetenu! - d.montant).abs() >= 1;

    return CarteYsem(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(d.reference, style: theme.textTheme.titleSmall)),
              Pastille(d.statutLibelle, ton: _tonDeclaration(d.statut)),
            ],
          ),
          const SizedBox(height: 6),
          Text(Formats.montant(d.montant, langue),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          if (retenuDifferent)
            Text(t.montantRetenu(Formats.montant(d.montantRetenu, langue)),
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700)),
          Text(
            [
              if (d.dateOperation != null)
                t.verseLe(Formats.dateLongue(d.dateOperation, langue)),
              if (d.referenceOperation.isNotEmpty) d.referenceOperation,
            ].join(' · '),
            style: secondaire,
          ),
          if (d.compte.isNotEmpty) Text(d.compte, style: secondaire),
          if (d.tranche.isNotEmpty) Text(t.trancheVisee(d.tranche), style: secondaire),
          if (d.declarant.isNotEmpty && d.espaceLibelle.isNotEmpty)
            Text(t.declarePar(d.declarant, d.espaceLibelle), style: secondaire),
          if (d.motifRejet.isNotEmpty) ...[
            const SizedBox(height: 10),
            Encadre(
                icone: Icons.block_rounded,
                titre: t.motifDuRejet,
                texte: d.motifRejet),
          ],
          if (d.observation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Encadre(
                icone: Icons.forum_outlined,
                titre: t.reponseDuService,
                texte: d.observation),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: () =>
                    telechargerEtOuvrir(context, () => depot.recuBanque(d.id)),
                icon: const Icon(Icons.receipt_outlined),
                label: Text(t.recuDeLaBanque),
              ),
              if (d.recuUrl != null)
                TextButton.icon(
                  onPressed: () => telechargerEtOuvrir(
                    context,
                    () => depot.documentDuChemin(d.recuUrl!,
                        nom: 'recu_${d.reference}.pdf'),
                  ),
                  icon: const Icon(Icons.download_rounded),
                  label: Text(t.recuDePaiement),
                ),
              if (d.retraitPossible)
                TextButton.icon(
                  onPressed: _retrait ? null : _retirer,
                  icon: const Icon(Icons.undo_rounded),
                  label: Text(t.retirer),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
