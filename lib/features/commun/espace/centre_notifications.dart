import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/espace.dart';
import '../../../core/models/notifications.dart';
import '../../../core/models/pagination.dart';
import '../../../core/providers.dart';
import 'menu.dart';

/// Ce que le centre affiche : les notifications chargées jusqu'ici et ce qui
/// reste à charger.
class ListeNotifications {
  const ListeNotifications({
    this.notifications = const [],
    this.pagination = const Pagination(),
    this.chargementSuite = false,
  });

  final List<NotificationPortail> notifications;
  final Pagination pagination;
  final bool chargementSuite;

  ListeNotifications copie({
    List<NotificationPortail>? notifications,
    Pagination? pagination,
    bool? chargementSuite,
  }) =>
      ListeNotifications(
        notifications: notifications ?? this.notifications,
        pagination: pagination ?? this.pagination,
        chargementSuite: chargementSuite ?? this.chargementSuite,
      );
}

/// Ce qu'ouvre le centre : l'espace, et le filtre sur les non lues.
typedef FiltreCentre = (Espace espace, bool nonLuesSeulement);

/// Centre de notifications d'un espace.
///
/// Chaque geste est envoyé au serveur puis reporté sur la liste et sur la
/// pastille de l'onglet, sans relire tout le centre.
class NotificationsController
    extends AutoDisposeFamilyAsyncNotifier<ListeNotifications, FiltreCentre> {
  Espace get _espace => arg.$1;
  bool get _nonLuesSeulement => arg.$2;

  @override
  Future<ListeNotifications> build(FiltreCentre filtre) async {
    final page = await ref
        .watch(depotEspaceProvider(filtre.$1))
        .notifications(nonLuesSeulement: filtre.$2);
    _reporterCompteur(page.nonLues);
    return ListeNotifications(
      notifications: page.notifications,
      pagination: page.pagination,
    );
  }

  /// Page suivante, quand on arrive au bas de la liste.
  Future<void> chargerSuite() async {
    final actuel = state.valueOrNull;
    final suivante = actuel?.pagination.pageSuivante;
    if (actuel == null || suivante == null || actuel.chargementSuite) return;
    state = AsyncData(actuel.copie(chargementSuite: true));
    try {
      final page = await ref
          .read(depotEspaceProvider(_espace))
          .notifications(page: suivante, nonLuesSeulement: _nonLuesSeulement);
      final dejaLa = {for (final n in actuel.notifications) n.id};
      state = AsyncData(actuel.copie(
        notifications: [
          ...actuel.notifications,
          ...page.notifications.where((n) => !dejaLa.contains(n.id)),
        ],
        pagination: page.pagination,
        chargementSuite: false,
      ));
      _reporterCompteur(page.nonLues);
    } catch (_) {
      state = AsyncData(actuel.copie(chargementSuite: false));
      rethrow;
    }
  }

  Future<void> marquer(NotificationPortail notification,
      {required bool lue}) async {
    if (notification.lue == lue) return;
    await ref
        .read(depotEspaceProvider(_espace))
        .marquerNotification(notification.id, lue: lue);
    final actuel = state.valueOrNull;
    if (actuel != null) {
      state = AsyncData(actuel.copie(notifications: [
        for (final n in actuel.notifications)
          if (n.id == notification.id) n.copieLue(lue) else n,
      ]));
    }
    _decalerCompteur(lue ? -1 : 1);
  }

  Future<void> supprimer(NotificationPortail notification) async {
    await ref
        .read(depotEspaceProvider(_espace))
        .supprimerNotification(notification.id);
    final actuel = state.valueOrNull;
    if (actuel != null) {
      state = AsyncData(actuel.copie(notifications: [
        for (final n in actuel.notifications)
          if (n.id != notification.id) n,
      ]));
    }
    if (!notification.lue) _decalerCompteur(-1);
  }

  Future<void> toutMarquerLu() async {
    await ref.read(depotEspaceProvider(_espace)).toutMarquerLu();
    final actuel = state.valueOrNull;
    if (actuel != null) {
      state = AsyncData(actuel.copie(notifications: [
        // Filtrée sur les non lues, la liste se vide.
        if (!_nonLuesSeulement)
          for (final n in actuel.notifications) n.copieLue(true),
      ]));
    }
    _reporterCompteur(0);
  }

  void _reporterCompteur(int nombre) => ref
      .read(menuProvider(_espace).notifier)
      .reporterNotificationsNonLues(nombre);

  void _decalerCompteur(int ecart) {
    final actuel =
        ref.read(menuProvider(_espace)).valueOrNull?.notificationsNonLues;
    if (actuel != null) _reporterCompteur((actuel + ecart).clamp(0, 1 << 30));
  }
}

final centreNotificationsProvider = AsyncNotifierProvider.autoDispose
    .family<NotificationsController, ListeNotifications, FiltreCentre>(
  NotificationsController.new,
);
