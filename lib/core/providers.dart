import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/application/session_controller.dart';
import '../features/auth/data/auth_enseignant_repository.dart';
import '../features/auth/data/auth_etudiant_repository.dart';
import '../features/commun/espace/depot_espace.dart';
import '../features/enseignant/data/enseignant_repository.dart';
import '../features/etudiant/data/etudiant_repository.dart';
import 'auth/espace.dart';
import 'network/api_client.dart';
import 'storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Préférences de l'appareil, chargées une fois dans `main()` et injectées
/// par `overrides`.
final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('preferencesProvider doit être injecté'),
);

/// Langue forcée dans l'application (`fr` / `en`), ou `null` pour suivre
/// celle du dossier une fois connecté, et celle de l'appareil avant.
///
/// C'est le dernier choix explicite fait sur cet appareil ; il est conservé
/// d'une ouverture à l'autre, et envoyé au serveur en `Accept-Language`.
class LangueController extends Notifier<String?> {
  static const _cle = 'ysem.langue';

  @override
  String? build() => ref.watch(preferencesProvider).getString(_cle);

  Future<void> definir(String? langue) async {
    final prefs = ref.read(preferencesProvider);
    if (langue == null) {
      await prefs.remove(_cle);
    } else {
      await prefs.setString(_cle, langue);
    }
    state = langue;
  }
}

final langueForceeProvider =
    NotifierProvider<LangueController, String?>(LangueController.new);

/// Un client HTTP par espace, chacun avec ses jetons.
final apiClientProvider = Provider.family<ApiClient, Espace>((ref, espace) {
  return ApiClient(
    espace: espace,
    stockage: ref.watch(tokenStorageProvider),
    langueForcee: () => ref.read(langueForceeProvider),
    surSessionPerdue: () =>
        ref.read(sessionProvider.notifier).sessionPerdue(espace),
  );
});

final authEtudiantRepositoryProvider = Provider<AuthEtudiantRepository>(
  (ref) => AuthEtudiantRepository(ref.watch(apiClientProvider(Espace.etudiant))),
);

final etudiantRepositoryProvider = Provider<EtudiantRepository>(
  (ref) => EtudiantRepository(ref.watch(apiClientProvider(Espace.etudiant))),
);

final authEnseignantRepositoryProvider = Provider<AuthEnseignantRepository>(
  (ref) =>
      AuthEnseignantRepository(ref.watch(apiClientProvider(Espace.enseignant))),
);

final enseignantRepositoryProvider = Provider<EnseignantRepository>(
  (ref) => EnseignantRepository(ref.watch(apiClientProvider(Espace.enseignant))),
);

/// Le dépôt d'authentification d'un espace (code, mot de passe, langue…).
final authRepositoryProvider = Provider.family<AuthRepository, Espace>(
  (ref, espace) => switch (espace) {
    Espace.etudiant => ref.watch(authEtudiantRepositoryProvider),
    Espace.enseignant => ref.watch(authEnseignantRepositoryProvider),
  },
);

/// Ce que les deux espaces partagent : menu et centre de notifications.
final depotEspaceProvider = Provider.family<DepotEspace, Espace>(
  (ref, espace) => switch (espace) {
    Espace.etudiant => ref.watch(etudiantRepositoryProvider),
    Espace.enseignant => ref.watch(enseignantRepositoryProvider),
  },
);
