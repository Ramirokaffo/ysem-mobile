import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/auth/espace.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../data/etudiant_repository.dart';
import 'base_hors_ligne.dart';
import 'providers.dart';
import 'synchroniseur.dart';

const _tacheEnvoi = 'ysem.hors_ligne.envoi';
const _tachePaquet = 'ysem.hors_ligne.paquet';

final _reseau = Constraints(networkType: NetworkType.connected);

/// Le système réveille l'application au retour du réseau, même fermée.
@pragma('vm:entry-point')
void tacheDeFond() {
  Workmanager().executeTask((_, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    final base = await BaseHorsLigne.ouvrir();
    final matricule = await base.matriculeActif();
    if (matricule == null) return true;
    if (!await base.aUnPaquet() && await base.nombreAEnvoyer(matricule) == 0) {
      return true;
    }
    final client = ApiClient(espace: Espace.etudiant, stockage: TokenStorage());
    final sync = Synchroniseur(
      base: base,
      serveur: ServeurEtudiant(EtudiantRepository(client)),
    );
    final vide = await sync.envoyerEnAttente(matricule);
    try {
      await sync.rafraichirPaquet();
    } on ApiException catch (e) {
      debugPrint('Paquet hors ligne non relu : $e');
    }
    // Le système rejouera la tâche, avec son délai croissant, tant que des
    // saisies restent à envoyer.
    return vide;
  });
}

/// Inscrit la relecture périodique du paquet. Sans effet là où le système n'a
/// pas de tâche de fond (tests).
Future<void> demarrerTacheDeFond() async {
  try {
    await Workmanager().initialize(tacheDeFond);
    await Workmanager().registerPeriodicTask(
      _tachePaquet,
      _tachePaquet,
      frequency: const Duration(hours: 6),
      constraints: _reseau,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  } catch (e) {
    debugPrint('Tâche de fond indisponible : $e');
  }
}

/// Demande l'envoi dès que le réseau revient.
Future<void> planifierEnvoi() async {
  try {
    await Workmanager().registerOneOffTask(
      _tacheEnvoi,
      _tacheEnvoi,
      constraints: _reseau,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
    );
  } catch (e) {
    debugPrint('Envoi différé non planifié : $e');
  }
}

Future<void> arreterTacheDeFond() async {
  try {
    await Workmanager().cancelAll();
  } catch (e) {
    debugPrint('Tâche de fond non annulée : $e');
  }
}
