import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/core/providers.dart';
import 'package:ysem/features/etudiant/application/lectures.dart';
import 'package:ysem/features/etudiant/application/notifications.dart';
import 'package:ysem/features/etudiant/data/etudiant_repository.dart';
import 'package:ysem/features/etudiant/domain/modeles.dart';
import 'package:ysem/features/etudiant/domain/notifications.dart';
import 'package:ysem/features/etudiant/domain/pagination.dart';

/// Dépôt factice : un centre de trois notifications sur deux pages.
class _DepotFactice extends Fake implements EtudiantRepository {
  final marquees = <(int, bool)>[];
  final supprimees = <int>[];
  var toutLu = false;

  NotificationEtudiant _n(int id, {bool lue = false}) =>
      NotificationEtudiant(id: id, titre: 'N$id', lue: lue);

  @override
  Future<Navigation> navigation({bool complet = false}) async =>
      const Navigation(groupes: [], compteurs: {'notification_unread_count': 9});

  @override
  Future<PageNotifications> notifications(
      {int page = 1, bool nonLuesSeulement = false}) async {
    return page == 1
        ? PageNotifications(
            notifications: [_n(1), _n(2, lue: true)],
            pagination: const Pagination(page: 1, pages: 2, pageSuivante: 2),
            nonLues: 2,
          )
        : PageNotifications(
            notifications: [_n(2, lue: true), _n(3)],
            pagination: const Pagination(page: 2, pages: 2),
            nonLues: 2,
          );
  }

  @override
  Future<void> marquerNotification(int id, {required bool lue}) async =>
      marquees.add((id, lue));

  @override
  Future<void> supprimerNotification(int id) async => supprimees.add(id);

  @override
  Future<void> toutMarquerLu() async => toutLu = true;
}

/// Le centre de l'espace étudiant, sans filtre.
const _centre = (Espace.etudiant, false);

void main() {
  late _DepotFactice depot;
  late ProviderContainer conteneur;

  setUp(() {
    depot = _DepotFactice();
    conteneur = ProviderContainer(overrides: [
      etudiantRepositoryProvider.overrideWithValue(depot),
    ]);
    // Garde les providers à suppression automatique en vie.
    conteneur.listen(navigationProvider, (_, _) {});
    conteneur.listen(centreNotificationsProvider(_centre), (_, _) {});
  });
  tearDown(() => conteneur.dispose());

  int pastille() =>
      conteneur.read(navigationProvider).requireValue.notificationsNonLues;

  Future<ListeNotifications> charger() async {
    await conteneur.read(navigationProvider.future);
    return conteneur.read(centreNotificationsProvider(_centre).future);
  }

  test('le compteur du centre est reporté sur la pastille', () async {
    await charger();
    expect(pastille(), 2);
  });

  test('la page suivante ne double aucune notification', () async {
    await charger();
    await conteneur.read(centreNotificationsProvider(_centre).notifier).chargerSuite();
    final liste = conteneur.read(centreNotificationsProvider(_centre)).requireValue;
    expect(liste.notifications.map((n) => n.id), [1, 2, 3]);
    expect(liste.pagination.aUneSuite, isFalse);
  });

  test('lire, relire et supprimer suivent la pastille', () async {
    final liste = await charger();
    final controleur = conteneur.read(centreNotificationsProvider(_centre).notifier);
    final premiere = liste.notifications.first;

    await controleur.marquer(premiere, lue: true);
    expect(depot.marquees, [(1, true)]);
    expect(pastille(), 1);

    // Déjà lue : rien n'est envoyé.
    await controleur.marquer(premiere.copieLue(true), lue: true);
    expect(depot.marquees, hasLength(1));

    // Supprimer une notification lue ne touche pas la pastille.
    await controleur.supprimer(premiere.copieLue(true));
    expect(depot.supprimees, [1]);
    expect(pastille(), 1);
    expect(
      conteneur
          .read(centreNotificationsProvider(_centre))
          .requireValue
          .notifications
          .map((n) => n.id),
      [2],
    );
  });

  test('tout marquer comme lu remet la pastille à zéro', () async {
    await charger();
    await conteneur.read(centreNotificationsProvider(_centre).notifier).toutMarquerLu();
    expect(depot.toutLu, isTrue);
    expect(pastille(), 0);
    expect(
      conteneur
          .read(centreNotificationsProvider(_centre))
          .requireValue
          .notifications
          .every((n) => n.lue),
      isTrue,
    );
  });
}
