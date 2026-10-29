import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/espace.dart';
import '../../../l10n/app_localizations.dart';
import 'centre_notifications.dart';
import 'menu.dart';

/// Coque d'un espace : quatre onglets (accueil, services, notifications,
/// profil), chacun avec sa pile.
///
/// Elle tient aussi la pastille des notifications à jour : le compteur est
/// relu périodiquement et au retour dans l'application — l'interrogation
/// que le web n'emploie qu'en repli de son websocket.
class CoqueEspace extends ConsumerStatefulWidget {
  const CoqueEspace({super.key, required this.espace, required this.coque});

  final Espace espace;
  final StatefulNavigationShell coque;

  /// Intervalle de relecture du compteur.
  static const intervalle = Duration(seconds: 90);

  @override
  ConsumerState<CoqueEspace> createState() => _CoqueEspaceState();
}

class _CoqueEspaceState extends ConsumerState<CoqueEspace> {
  Timer? _minuterie;
  late final AppLifecycleListener _cycle;

  @override
  void initState() {
    super.initState();
    _minuterie = Timer.periodic(CoqueEspace.intervalle, (_) => _relire());
    _cycle = AppLifecycleListener(onResume: _relire);
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    _cycle.dispose();
    super.dispose();
  }

  /// Relit le compteur ; s'il a monté, le centre est relu pour montrer les
  /// nouvelles notifications.
  Future<void> _relire() async {
    final menu = menuProvider(widget.espace);
    final avant = ref.read(menu).valueOrNull?.notificationsNonLues ?? 0;
    final apres = await ref.read(menu.notifier).relireCompteur();
    if (apres != null && apres > avant && mounted) {
      ref.invalidate(centreNotificationsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coque = widget.coque;
    final t = AppLocalizations.of(context);
    final nonLues = ref
            .watch(menuProvider(widget.espace))
            .valueOrNull
            ?.notificationsNonLues ??
        0;

    Widget cloche(IconData icone) => Badge(
          isLabelVisible: nonLues > 0,
          label: Text(nonLues > 99 ? '99+' : '$nonLues'),
          child: Icon(icone),
        );

    return Scaffold(
      body: coque,
      bottomNavigationBar: NavigationBar(
        selectedIndex: coque.currentIndex,
        onDestinationSelected: (i) {
          coque.goBranch(i, initialLocation: i == coque.currentIndex);
          if (i == 2) _relire();
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: t.ongletAccueil,
          ),
          NavigationDestination(
            icon: const Icon(Icons.apps_outlined),
            selectedIcon: const Icon(Icons.apps_rounded),
            label: t.ongletServices,
          ),
          NavigationDestination(
            icon: cloche(Icons.notifications_outlined),
            selectedIcon: cloche(Icons.notifications_rounded),
            label: t.ongletNotifications,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: t.ongletProfil,
          ),
        ],
      ),
    );
  }
}
