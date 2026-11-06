import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/formulaire.dart';
import '../../../commun/langue.dart';
import '../../../commun/telechargement.dart';
import '../../application/lectures.dart';
import '../../application/sections.dart';
import '../../domain/mobile_money.dart';

/// Ton de la pastille d'une transaction.
TonPastille tonDuPaiement(String statut) => switch (statut) {
      'reussi' => TonPastille.succes,
      'echoue' || 'expire' => TonPastille.danger,
      'annule' => TonPastille.neutre,
      _ => TonPastille.alerte,
    };

/// L'attente de la confirmation, puis le dénouement. Valider l'invite fait
/// sortir de l'application : l'écran relit la transaction toutes les cinq
/// secondes, et aussitôt qu'on y revient. Rien n'est décidé ici — c'est le
/// serveur qui constate, et il continue sans cet écran.
class SuiviPaiementMobilePage extends ConsumerStatefulWidget {
  const SuiviPaiementMobilePage({super.key, required this.paiement});

  final PaiementMobile paiement;

  /// Rythme du serveur : il n'interroge l'agrégateur que toutes les dix.
  static const intervalle = Duration(seconds: 5);

  @override
  ConsumerState<SuiviPaiementMobilePage> createState() =>
      _SuiviPaiementMobilePageState();
}

class _SuiviPaiementMobilePageState
    extends ConsumerState<SuiviPaiementMobilePage>
    with WidgetsBindingObserver {
  late PaiementMobile _paiement = widget.paiement;
  Timer? _minuterie;
  bool _lecture = false;
  bool _annulation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_paiement.ouvert) {
      _minuterie = Timer.periodic(
          SuiviPaiementMobilePage.intervalle, (_) => _relire());
      WidgetsBinding.instance.addPostFrameCallback((_) => _relire());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _minuterie?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    if (etat == AppLifecycleState.resumed) _relire();
  }

  Future<void> _relire() async {
    if (_lecture || !_paiement.ouvert || !mounted) return;
    _lecture = true;
    try {
      final relu =
          await ref.read(etudiantRepositoryProvider).paiementMobile(_paiement.id);
      if (mounted) _adopter(relu);
    } on ApiException {
      // Réseau coupé : le prochain passage réessaiera, et le serveur constate
      // le dénouement sans nous.
    } finally {
      _lecture = false;
    }
  }

  void _adopter(PaiementMobile relu) {
    setState(() => _paiement = relu);
    if (relu.ouvert) return;
    _minuterie?.cancel();
    // Un dénouement change la situation : ce qui en dépend est relu.
    ref.invalidate(mobileMoneyProvider);
    ref.invalidate(financesProvider);
    ref.invalidate(reinscriptionProvider);
    ref.invalidate(versementsProvider);
    ref.invalidate(tableauDeBordProvider);
  }

  Future<void> _annuler() async {
    final t = AppLocalizations.of(context);
    final ok = await confirmer(
      context,
      titre: t.annulerLePaiement,
      texte: t.annulerPaiementConfirmation(_paiement.reference),
      action: t.annulerLePaiement,
    );
    if (!ok || !mounted) return;
    final messager = ScaffoldMessenger.of(context);
    setState(() => _annulation = true);
    try {
      final relu = await ref
          .read(etudiantRepositoryProvider)
          .annulerPaiementMobile(_paiement.id);
      messager.showSnackBar(SnackBar(content: Text(t.paiementAnnule)));
      if (mounted) _adopter(relu);
    } on ApiException catch (e) {
      // Sans doute déjà pris en charge par l'opérateur : le serveur le dit.
      messager.showSnackBar(SnackBar(content: Text(e.message)));
      await _relire();
    } finally {
      if (mounted) setState(() => _annulation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final jetons = YsemTokens.of(context);
    final langue = langueCourante(context);
    final p = _paiement;
    final depot = ref.read(etudiantRepositoryProvider);

    final couleur = p.ouvert
        ? theme.colorScheme.primary
        : (p.reussi ? jetons.succes : jetons.danger);

    Widget ligne(String libelle, String valeur) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(libelle,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(valeur,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(t.paiementMobileMoney)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          if (p.test) ...[
            Encadre(icone: Icons.science_outlined, texte: t.mobileMoneyTest),
            const SizedBox(height: 20),
          ],
          Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: couleur.withValues(alpha: 0.12),
              child: p.ouvert
                  ? SizedBox.square(
                      dimension: 32,
                      child: CircularProgressIndicator(color: couleur))
                  : Icon(p.reussi ? Icons.check_rounded : Icons.close_rounded,
                      size: 36, color: couleur),
            ),
          ),
          const SizedBox(height: 16),
          Text(p.statutLibelle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(p.message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 20),
          CarteYsem(
            titre: p.reference,
            icone: Icons.receipt_long_outlined,
            child: Column(
              children: [
                ligne(t.montantRegle, Formats.montant(p.montant, langue)),
                if (p.tranche.isNotEmpty) ligne(t.trancheReglee, p.tranche),
                if (p.frais > 0)
                  ligne(t.fraisDeTransaction, Formats.montant(p.frais, langue)),
                ligne(t.totalDebite, Formats.montant(p.montantDebite, langue)),
                ligne(p.operateurLibelle, p.telephone),
                if (p.lanceParUnParent && p.payeur.isNotEmpty)
                  ligne(t.lancePar(p.payeur), ''),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (p.ouvert) ...[
            Text(t.quitterEcranPaiement,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (p.annulable) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _annulation ? null : _annuler,
                icon: const Icon(Icons.close_rounded),
                label: Text(t.annulerLePaiement),
              ),
            ],
          ] else ...[
            if (p.recuUrl != null)
              FilledButton.icon(
                onPressed: () => telechargerEtOuvrir(
                  context,
                  () => depot.documentDuChemin(p.recuUrl!,
                      nom: 'recu_${p.reference}.pdf'),
                ),
                icon: const Icon(Icons.download_rounded),
                label: Text(t.telechargerRecu),
              ),
            if (!p.reussi)
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(t.reessayer),
              ),
          ],
        ],
      ),
    );
  }
}
