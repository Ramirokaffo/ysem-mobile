import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/json.dart';
import '../../../core/providers.dart';
import '../../auth/application/session_controller.dart';
import '../data/etudiant_repository.dart';
import 'base_hors_ligne.dart';
import 'depot_delegation.dart';
import 'synchroniseur.dart';
import 'tache_de_fond.dart';

/// Les deux routes de la synchronisation, par le dépôt de l'étudiant.
class ServeurEtudiant implements ServeurHorsLigne {
  const ServeurEtudiant(this._depot);

  final EtudiantRepository _depot;

  @override
  Future<Json> lirePaquet() => _depot.paquetHorsLigne();

  @override
  Future<Json> envoyer(List<Json> saisies, {required bool immediate}) =>
      _depot.synchroniserSaisies(saisies, immediate: immediate);
}

/// La base du téléphone, `null` là où elle ne s'ouvre pas : la délégation
/// reste alors utilisable en ligne, comme avant.
final baseHorsLigneProvider = FutureProvider<BaseHorsLigne?>((ref) async {
  try {
    return await BaseHorsLigne.ouvrir();
  } catch (e) {
    debugPrint('Base hors ligne indisponible : $e');
    return null;
  }
});

final synchroniseurProvider = FutureProvider<Synchroniseur?>((ref) async {
  final base = await ref.watch(baseHorsLigneProvider.future);
  if (base == null) return null;
  return Synchroniseur(
    base: base,
    serveur: ServeurEtudiant(ref.watch(etudiantRepositoryProvider)),
  );
});

final depotDelegationProvider = FutureProvider<DepotDelegation>((ref) async {
  return DepotDelegation(
    depot: ref.watch(etudiantRepositoryProvider),
    base: await ref.watch(baseHorsLigneProvider.future),
    synchroniseur: await ref.watch(synchroniseurProvider.future),
    matriculeSession: () {
      final acteur = ref.read(sessionProvider).valueOrNull?.acteur;
      final matricule = acteur?['matricule'];
      return matricule == null ? null : '$matricule';
    },
    apresSaisie: planifierEnvoi,
  );
});

/// Le téléphone a-t-il un réseau ? Une connexion sans internet répond oui :
/// l'envoi échoue alors, et la saisie reste à envoyer.
final reseauProvider = StreamProvider<bool>((ref) async* {
  final connexion = Connectivity();
  bool actif(List<ConnectivityResult> etats) =>
      etats.any((e) => e != ConnectivityResult.none);
  yield actif(await connexion.checkConnectivity());
  yield* connexion.onConnectivityChanged.map(actif);
});

class EtatHorsLigne {
  const EtatHorsLigne({this.aUnPaquet = false, this.aEnvoyer = 0});

  final bool aUnPaquet;
  final int aEnvoyer;
}

/// De quoi dire au délégué où il en est, quel que soit l'écran.
final etatHorsLigneProvider = FutureProvider.autoDispose<EtatHorsLigne>((ref) async {
  final base = await ref.watch(baseHorsLigneProvider.future);
  if (base == null) return const EtatHorsLigne();
  final matricule = await base.matriculeActif();
  if (matricule == null) return const EtatHorsLigne();
  return EtatHorsLigne(
    aUnPaquet: await base.aUnPaquet(),
    aEnvoyer: await base.nombreAEnvoyer(matricule),
  );
});


/// Ce qui n'a pas encore quitté le téléphone, à dire avant une déconnexion.
Future<int> nombreSaisiesNonEnvoyees(WidgetRef ref) async {
  final base = await ref.read(baseHorsLigneProvider.future);
  final matricule = await base?.matriculeActif();
  if (base == null || matricule == null) return 0;
  return base.nombreAEnvoyer(matricule);
}
