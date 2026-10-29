import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/formulaire.dart';
import '../../../commun/langue.dart';
import '../../application/lectures.dart';
import '../../domain/cours.dart';

/// « Fiches à signer » : les appels et cahiers de texte que les délégués ont
/// saisis pour les séances de l'enseignant.
///
/// La signature vaut validation et n'est bornée par aucune fenêtre ; un
/// renvoi au délégué exige un motif, sans quoi il ne sait pas quoi corriger.
class FichesASignerPage extends ConsumerStatefulWidget {
  const FichesASignerPage({super.key, this.titre});

  final String? titre;

  @override
  ConsumerState<FichesASignerPage> createState() => _FichesASignerPageState();
}

class _FichesASignerPageState extends ConsumerState<FichesASignerPage> {
  /// Fiche en cours d'envoi (`type:id`), ou `*` pour « tout signer ».
  String? _enCours;

  Future<void> _rafraichir() async {
    ref.invalidate(fichesASignerProvider);
    await ref.read(menuEnseignantProvider.notifier).rafraichir();
  }

  /// Joue un geste, dit le message du serveur et relit la liste.
  Future<void> _geste(String cle, Future<String> Function() geste) async {
    setState(() => _enCours = cle);
    final messager = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context);
    try {
      final message = await geste();
      messager.showSnackBar(SnackBar(content: Text(message)));
      await _rafraichir();
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
      ref.invalidate(fichesASignerProvider);
    } catch (_) {
      messager.showSnackBar(SnackBar(content: Text(t.erreurInattendue)));
    } finally {
      if (mounted) setState(() => _enCours = null);
    }
  }

  Future<void> _signer(FicheDeSeance fiche) => _geste(
        '${fiche.type}:${fiche.id}',
        () => ref.read(enseignantRepositoryProvider).signerFiche(fiche),
      );

  Future<void> _renvoyer(FicheDeSeance fiche) async {
    final motif = await showDialog<String>(
      context: context,
      builder: (_) => const _DemandeMotif(),
    );
    if (motif == null || !mounted) return;
    await _geste(
      '${fiche.type}:${fiche.id}',
      () => ref.read(enseignantRepositoryProvider).renvoyerFiche(fiche, motif),
    );
  }

  Future<void> _signerTout(int nombre) async {
    final t = AppLocalizations.of(context);
    final ok = await confirmer(
      context,
      titre: t.signerToutesLesFiches(nombre),
      texte: t.signerToutConfirmation,
      action: t.signer,
    );
    if (!ok || !mounted) return;
    await _geste('*', () async {
      final (message, refus) =
          await ref.read(enseignantRepositoryProvider).signerToutesLesFiches();
      return [message, ...refus].join('\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.titre ?? t.sectionFichesASigner)),
      body: VueAsynchrone<FichesASigner>(
        valeur: ref.watch(fichesASignerProvider),
        surRafraichir: _rafraichir,
        constructeur: (donnees) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Encadre(
              texte: t.fichesASignerExplication,
              icone: Icons.info_outline_rounded,
            ),
            const SizedBox(height: 16),
            if (donnees.fiches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: EtatVide(
                  message: t.aucuneFicheASigner,
                  icone: Icons.task_alt_rounded,
                ),
              )
            else ...[
              if (donnees.fiches.length > 1) ...[
                FilledButton.icon(
                  onPressed: _enCours != null
                      ? null
                      : () => _signerTout(donnees.fiches.length),
                  icon: _enCours == '*'
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Icon(Icons.done_all_rounded),
                  label: Text(t.signerToutesLesFiches(donnees.fiches.length)),
                ),
                const SizedBox(height: 16),
              ],
              for (final fiche in donnees.fiches) ...[
                _CarteFiche(
                  fiche: fiche,
                  enCours: _enCours == '${fiche.type}:${fiche.id}',
                  actif: _enCours == null,
                  surSigner: () => _signer(fiche),
                  surRenvoyer: () => _renvoyer(fiche),
                ),
                const SizedBox(height: 12),
              ],
            ],
            if (donnees.historique.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(t.dernieresFiches,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final fiche in donnees.historique) ...[
                _CarteFiche(fiche: fiche),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CarteFiche extends StatelessWidget {
  const _CarteFiche({
    required this.fiche,
    this.enCours = false,
    this.actif = false,
    this.surSigner,
    this.surRenvoyer,
  });

  final FicheDeSeance fiche;
  final bool enCours;
  final bool actif;

  /// Absents d'une fiche de l'historique : elle se lit, elle ne se signe plus.
  final VoidCallback? surSigner;
  final VoidCallback? surRenvoyer;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final quand = [
      Formats.jourLong(fiche.date, langue),
      Formats.plage(fiche.debut, fiche.fin),
    ].where((s) => s.isNotEmpty).join(' · ');
    final ou = [fiche.niveau, fiche.salle].where((s) => s.isNotEmpty).join(' · ');

    return CarteYsem(
      titre: fiche.estAppel ? t.ficheAppel : t.ficheCahierDeTexte,
      icone: fiche.estAppel
          ? Icons.how_to_reg_outlined
          : Icons.menu_book_outlined,
      action: fiche.statutLibelle.isEmpty
          ? null
          : Pastille(
              fiche.statutLibelle,
              // Une fiche de la liste attend un geste de l'enseignant.
              ton: surSigner != null
                  ? TonPastille.alerte
                  : Pastille.tonDuStatut(fiche.statut),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(fiche.intituleCours(langue),
              style: theme.textTheme.titleSmall),
          if (quand.isNotEmpty) Text(quand, style: secondaire),
          if (ou.isNotEmpty) Text(ou, style: secondaire),
          if (fiche.delegue.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(t.saisiPar(fiche.delegue), style: secondaire),
          ],
          const SizedBox(height: 12),
          if (fiche.estAppel)
            _ContenuAppel(fiche: fiche)
          else
            _ContenuCahier(fiche: fiche),
          if (fiche.motifRenvoi.isNotEmpty) ...[
            const SizedBox(height: 12),
            Encadre(
              titre: t.motifDuRenvoi,
              texte: fiche.motifRenvoi,
              icone: Icons.reply_rounded,
            ),
          ],
          if (fiche.enAttenteDuService && surSigner == null) ...[
            const SizedBox(height: 8),
            Text(t.enAttenteValidationService, style: secondaire),
          ],
          if (surSigner != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: actif ? surRenvoyer : null,
                    icon: const Icon(Icons.reply_rounded),
                    label: Text(t.renvoyer),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: actif ? surSigner : null,
                    icon: enCours
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Icon(Icons.draw_rounded),
                    label: Text(t.signer),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ContenuAppel extends StatelessWidget {
  const _ContenuAppel({required this.fiche});

  final FicheDeSeance fiche;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final effectif = fiche.effectif;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Pastille(
          effectif == null
              ? t.nbAbsents(fiche.absents.length)
              : t.nbAbsentsSur(fiche.absents.length, effectif),
          ton: fiche.absents.isEmpty ? TonPastille.succes : TonPastille.alerte,
        ),
        if (fiche.absents.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final nom in fiche.absents)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.person_off_outlined,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(nom, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _ContenuCahier extends StatelessWidget {
  const _ContenuCahier({required this.fiche});

  final FicheDeSeance fiche;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (fiche.blocs.isEmpty) {
      return Text(t.cahierSansContenu,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final bloc in fiche.blocs)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bloc.seance.isNotEmpty)
                  Text(bloc.seance,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                if (bloc.chapitre.isNotEmpty)
                  Text(bloc.chapitre, style: theme.textTheme.bodySmall),
                if (bloc.contenus.isNotEmpty)
                  Text(bloc.contenus,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Motif du renvoi au délégué — exigé.
class _DemandeMotif extends StatefulWidget {
  const _DemandeMotif();

  @override
  State<_DemandeMotif> createState() => _DemandeMotifState();
}

class _DemandeMotifState extends State<_DemandeMotif> {
  final _champ = TextEditingController();
  bool _vide = false;

  @override
  void dispose() {
    _champ.dispose();
    super.dispose();
  }

  void _valider() {
    final motif = _champ.text.trim();
    if (motif.isEmpty) {
      setState(() => _vide = true);
      return;
    }
    Navigator.of(context).pop(motif);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(t.renvoyerAuDelegue),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.renvoyerAuDelegueAide),
          const SizedBox(height: 16),
          TextField(
            controller: _champ,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: t.motifDuRenvoi,
              errorText: _vide ? t.motifRequis : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.annuler),
        ),
        FilledButton(onPressed: _valider, child: Text(t.renvoyer)),
      ],
    );
  }
}
