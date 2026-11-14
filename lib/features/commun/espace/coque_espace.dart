import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/espace.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../liens/liens_entrants.dart';
import '../push/canal_push.dart';
import '../push/push.dart';
import '../temps_reel.dart';
import 'centre_notifications.dart';
import 'centre_notifications_page.dart';
import 'menu.dart';

/// Coque d'un espace : quatre onglets (accueil, services, notifications,
/// profil), chacun avec sa pile.
///
/// Elle tient aussi la pastille des notifications à jour par le websocket de
/// la cloche, le même que celui du navigateur — c'est aussi lui qui rend
/// l'acteur « en ligne » côté serveur tant que l'application est au premier
/// plan. Socket tombé, le compteur est relu périodiquement : le repli du web.
///
/// Elle reçoit enfin les push et les liens du portail web touchés hors de
/// l'application : elle n'existe qu'une fois la session restaurée, si bien
/// qu'une notification ou un lien touchés à froid l'attendent ici.
class CoqueEspace extends ConsumerStatefulWidget {
  const CoqueEspace({
    super.key,
    required this.espace,
    required this.coque,
    required this.sectionDeLAdresse,
    required this.ouvrirSection,
  });

  final Espace espace;
  final StatefulNavigationShell coque;
  final LecteurAdresse sectionDeLAdresse;
  final OuvreurSection ouvrirSection;

  /// Onglet du centre de notifications.
  static const ongletNotifications = 2;

  /// Intervalle de relecture du compteur, quand le websocket est tombé.
  static const intervalle = Duration(seconds: 90);

  /// Une même notification annoncée par le socket puis par le push (ou
  /// l'inverse) ne fait qu'un bandeau.
  static const fenetreDoublon = Duration(seconds: 10);

  @override
  ConsumerState<CoqueEspace> createState() => _CoqueEspaceState();
}

class _CoqueEspaceState extends ConsumerState<CoqueEspace> {
  Timer? _minuterie;
  late final GardeCanal _cloche;
  late final StreamSubscription<Map<String, dynamic>> _evenements;
  late final StreamSubscription<MessagePush> _recus;
  late final StreamSubscription<void> _ouvertures;
  late final StreamSubscription<void> _liens;
  final Map<int, DateTime> _bandeauxRecents = {};

  @override
  void initState() {
    super.initState();
    _cloche = GardeCanal(
      canalTempsReel(
          ref, widget.espace, CheminsTempsReel.notifications(widget.espace)),
      surRetour: _relire,
    );
    _evenements = _cloche.canal.evenements.listen(_surEvenement);
    _minuterie = Timer.periodic(CoqueEspace.intervalle, (_) {
      if (!_cloche.canal.estConnecte) _relire();
    });
    final push = ref.read(pushProvider);
    _recus = push.recus.listen(_surPush);
    _ouvertures = push.ouvertures.listen((_) => _suivreDestination());
    // Le routeur retient le lien pendant qu'il mène à l'accueil : la section
    // s'ouvre par-dessus une fois cette navigation rendue.
    _liens = ref.read(liensEntrantsProvider).arrivees.listen((_) =>
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _suivreDestination()));
    WidgetsBinding.instance.addPostFrameCallback((_) => _suivreDestination());
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    _evenements.cancel();
    _cloche.dispose();
    _recus.cancel();
    _ouvertures.cancel();
    _liens.cancel();
    super.dispose();
  }

  /// Un push reçu application ouverte : le système n'affiche rien, un bandeau
  /// le fait. Pas de bandeau sur la section même qu'il désigne : le fil qu'on
  /// lit montre déjà le message.
  void _surPush(MessagePush message) {
    if (!mounted) return;
    // Une notification rafraîchie ne fait pas monter le compteur.
    ref.invalidate(centreNotificationsProvider);
    _relire();
    final destination = DestinationPush.depuis(message.donnees);
    if (destination == null || destination.espace != widget.espace) return;
    _bandeau(destination, message.titre);
  }

  /// Ce que pousse le socket de la cloche (`notifications.consumers`).
  void _surEvenement(Map<String, dynamic> evenement) {
    if (!mounted) return;
    final nombre = evenement['unread_count'];
    switch (evenement['type']) {
      case 'connected':
        // (Re)connexion : ce qui est arrivé pendant la coupure se relit.
        final avant = ref
                .read(menuProvider(widget.espace))
                .valueOrNull
                ?.notificationsNonLues ??
            0;
        if (nombre is int) _reporter(nombre);
        if (nombre is int && nombre > avant) {
          ref.invalidate(centreNotificationsProvider);
        }
      case 'count':
        if (nombre is int) _reporter(nombre);
      case 'notification':
        if (nombre is int) _reporter(nombre);
        ref.invalidate(centreNotificationsProvider);
        // Les autres pastilles du menu (messages, discussions, documents…)
        // bougent avec ce qui vient d'être annoncé.
        unawaited(ref.read(menuProvider(widget.espace).notifier).rafraichir());
        final notification = evenement['notification'];
        if (notification is Map) {
          _bandeau(
            DestinationPush(
              espace: widget.espace,
              notificationId: int.tryParse('${notification['id'] ?? ''}'),
              url: (notification['url'] ?? '').toString(),
            ),
            notification['title']?.toString(),
          );
        }
    }
  }

  void _reporter(int nombre) => ref
      .read(menuProvider(widget.espace).notifier)
      .reporterNotificationsNonLues(nombre);

  /// Bandeau d'une notification reçue application ouverte.
  void _bandeau(DestinationPush destination, String? titre) {
    final id = destination.notificationId;
    final maintenant = DateTime.now();
    _bandeauxRecents.removeWhere((_, quand) =>
        maintenant.difference(quand) > CoqueEspace.fenetreDoublon);
    if (id != null && _bandeauxRecents.containsKey(id)) return;

    final section = widget.sectionDeLAdresse(destination.url);
    // Pas `uri` : il ignore les pages ouvertes par `push`, dont les sections.
    final ici = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .lastOrNull
        ?.matchedLocation;
    if (section != null && (ici?.endsWith('/section/$section') ?? false)) {
      return;
    }

    // Noté seulement une fois montré : un bandeau tu sur sa propre section
    // ne doit pas faire taire le suivant.
    if (id != null) _bandeauxRecents[id] = maintenant;
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(titre ?? t.ongletNotifications),
        action: SnackBarAction(
          label: t.notificationVoir,
          onPressed: () => _ouvrir(destination),
        ),
      ));
  }

  void _suivreDestination() {
    if (!mounted) return;
    final destination =
        ref.read(pushProvider).prendreDestination(widget.espace);
    // Pris dans tous les cas : un lien laissé en attente s'ouvrirait plus
    // tard, sans que personne ne l'ait demandé à ce moment-là.
    final lien = ref.read(liensEntrantsProvider).prendre(widget.espace);
    if (destination != null) {
      _ouvrir(destination);
    } else if (lien != null) {
      // Un lien n'est pas une notification : rien à marquer comme lu.
      _ouvrir(DestinationPush(
        espace: widget.espace,
        notificationId: null,
        url: lien.chemin,
      ));
    }
  }

  /// Ouvre ce que désigne la notification, comme un toucher dans le centre.
  void _ouvrir(DestinationPush destination) {
    final id = destination.notificationId;
    if (id != null) unawaited(_marquerLue(id));
    final section = widget.sectionDeLAdresse(destination.url);
    if (section != null) {
      widget.ouvrirSection(context, section);
    } else {
      widget.coque.goBranch(CoqueEspace.ongletNotifications);
    }
  }

  Future<void> _marquerLue(int id) async {
    try {
      await ref
          .read(depotEspaceProvider(widget.espace))
          .marquerNotification(id, lue: true);
    } catch (_) {
      // Sans réseau, elle reste non lue : le centre le montrera.
      return;
    }
    if (!mounted) return;
    ref.invalidate(centreNotificationsProvider);
    await _relire();
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
          if (i == CoqueEspace.ongletNotifications) _relire();
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
