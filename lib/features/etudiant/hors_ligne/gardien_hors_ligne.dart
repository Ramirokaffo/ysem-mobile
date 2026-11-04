import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/network/api_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../application/lectures.dart';
import '../presentation/delegation/delegation_page.dart';
import 'providers.dart';
import 'tache_de_fond.dart';

/// Veille, tant que l'espace étudiant est ouvert, à ce que le téléphone du
/// délégué reste à jour : ce qui attend part au retour du réseau et à chaque
/// retour dans l'application, et le paquet se télécharge sans que le délégué ait
/// à ouvrir sa section — il n'en aura plus l'occasion une fois en salle.
///
/// Sans réseau le menu ne se lit pas : le bandeau est la porte vers
/// « Ma délégation ».
class GardienHorsLigne extends ConsumerStatefulWidget {
  const GardienHorsLigne({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GardienHorsLigne> createState() => _GardienHorsLigneState();
}

class _GardienHorsLigneState extends ConsumerState<GardienHorsLigne>
    with WidgetsBindingObserver {
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(demarrerTacheDeFond());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    if (etat == AppLifecycleState.resumed) unawaited(_synchroniser());
  }

  Future<void> _synchroniser() async {
    if (_enCours) return;
    final base = await ref.read(baseHorsLigneProvider.future);
    if (base == null || !mounted) return;
    final delegue = ref
            .read(navigationProvider)
            .valueOrNull
            ?.section('delegation') !=
        null;
    if (!delegue && !await base.aUnPaquet()) return;
    _enCours = true;
    try {
      await (await ref.read(depotDelegationProvider.future)).synchroniser();
    } on ApiException catch (e) {
      debugPrint('Synchronisation reportée : $e');
    } finally {
      _enCours = false;
      if (mounted) {
        ref.invalidate(etatHorsLigneProvider);
        ref.invalidate(delegationProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(reseauProvider, (avant, apres) {
      if (apres.valueOrNull == true && avant?.valueOrNull != true) {
        unawaited(_synchroniser());
      }
    });
    ref.listen(navigationProvider, (avant, apres) {
      final delegue = apres.valueOrNull?.section('delegation') != null;
      final avait = avant?.valueOrNull?.section('delegation') != null;
      if (delegue && !avait) unawaited(_synchroniser());
    });

    final t = AppLocalizations.of(context);
    final etat = ref.watch(etatHorsLigneProvider).valueOrNull;
    final sansReseau = ref.watch(reseauProvider).valueOrNull == false;
    final aEnvoyer = etat?.aEnvoyer ?? 0;
    final visible = (etat?.aUnPaquet ?? false) && (sansReseau || aEnvoyer > 0);

    return Column(
      children: [
        if (visible)
          Material(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: SafeArea(
              bottom: false,
              child: InkWell(
                onTap: () =>
                    context.push(Routes.sectionEtudiant('delegation')),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      Icon(
                        sansReseau
                            ? Icons.cloud_off_rounded
                            : Icons.cloud_upload_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          [
                            if (sansReseau) t.horsLigne,
                            if (aEnvoyer > 0) t.saisiesAEnvoyer(aEnvoyer),
                          ].join(' · '),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      Text(t.sectionDelegation,
                          style: Theme.of(context).textTheme.labelMedium),
                      const Icon(Icons.chevron_right_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
