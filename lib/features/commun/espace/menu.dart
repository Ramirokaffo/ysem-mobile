import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/espace.dart';
import '../../../core/models/navigation.dart';
import '../../../core/providers.dart';

/// Le menu d'un espace, venu du registre du portail. Gardé tant que la coque
/// est affichée (pastille des notifications, accès rapides, services).
class MenuController extends AutoDisposeFamilyAsyncNotifier<Navigation, Espace> {
  @override
  Future<Navigation> build(Espace espace) =>
      ref.watch(depotEspaceProvider(espace)).navigation();

  /// Relit le menu ; `complet` calcule aussi les pastilles coûteuses. Une
  /// erreur garde le menu précédent à l'écran.
  Future<void> rafraichir({bool complet = false}) async {
    final suivant = await AsyncValue.guard(
      () => ref.read(depotEspaceProvider(arg)).navigation(complet: complet),
    );
    state = suivant.hasError && state.hasValue
        ? suivant.copyWithPrevious(state)
        : suivant;
  }

  /// Reporte sur la pastille le compteur des notifications lu ailleurs
  /// (centre de notifications, interrogation périodique).
  void reporterNotificationsNonLues(int nombre) {
    final actuel = state.valueOrNull;
    if (actuel == null || actuel.notificationsNonLues == nombre) return;
    state = AsyncData(actuel.avecNotificationsNonLues(nombre));
  }

  /// Relit le seul compteur des notifications (`notifications/compteur/`) :
  /// c'est l'interrogation périodique du web quand son websocket tombe, le
  /// mode normal de l'application. Rend le nouveau compte, `null` en cas
  /// d'échec (silencieux : la pastille garde sa valeur).
  Future<int?> relireCompteur() async {
    try {
      final nombre =
          await ref.read(depotEspaceProvider(arg)).compteurNotifications();
      reporterNotificationsNonLues(nombre);
      return nombre;
    } catch (_) {
      return null;
    }
  }
}

/// Menu de chaque espace.
final menuProvider = AsyncNotifierProvider.autoDispose
    .family<MenuController, Navigation, Espace>(MenuController.new);
