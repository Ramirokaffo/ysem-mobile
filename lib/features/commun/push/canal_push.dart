import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Un push tel que l'application le reçoit.
class MessagePush {
  const MessagePush({required this.donnees, this.titre, this.texte});

  /// `notification_id`, `url`, `espace` (`notifications/push.py` du serveur).
  final Map<String, dynamic> donnees;
  final String? titre;
  final String? texte;
}

/// Ce que l'application attend du système de notifications du téléphone.
///
/// Isolé de Firebase pour que le reste se teste sans services Google.
abstract interface class CanalPush {
  /// Demande l'autorisation d'afficher, et dit si elle est accordée.
  Future<bool> demanderAutorisation();

  /// Inscrit ce téléphone auprès de FCM ; l'identifiant arrive par
  /// [installations].
  Future<void> inscrire();

  /// Ce téléphone cesse d'être joignable.
  Future<void> desinscrire();

  /// L'identifiant d'installation (FID), à chaque inscription réussie et à
  /// chaque fois qu'il change.
  Stream<String> get installations;

  /// Reçus pendant que l'application est à l'écran : le système n'affiche rien.
  Stream<MessagePush> get recus;

  /// Touchés pendant que l'application tournait en arrière-plan.
  Stream<MessagePush> get ouverts;

  /// Celui qui a lancé l'application, s'il y en a un.
  Future<MessagePush?> ouvertureInitiale();
}

/// Téléphone sans services Google, ou application construite sans
/// `google-services.json` : tout continue, avec la relecture du compteur.
class CanalInactif implements CanalPush {
  const CanalInactif();

  @override
  Future<bool> demanderAutorisation() async => false;

  @override
  Future<void> inscrire() async {}

  @override
  Future<void> desinscrire() async {}

  @override
  Stream<String> get installations => const Stream.empty();

  @override
  Stream<MessagePush> get recus => const Stream.empty();

  @override
  Stream<MessagePush> get ouverts => const Stream.empty();

  @override
  Future<MessagePush?> ouvertureInitiale() async => null;
}

class CanalFirebase implements CanalPush {
  CanalFirebase() : _messagerie = FirebaseMessaging.instance;

  final FirebaseMessaging _messagerie;

  static MessagePush _lire(RemoteMessage message) => MessagePush(
        donnees: message.data,
        titre: message.notification?.title,
        texte: message.notification?.body,
      );

  @override
  Future<bool> demanderAutorisation() async {
    final reglages = await _messagerie.requestPermission();
    return reglages.authorizationStatus == AuthorizationStatus.authorized ||
        reglages.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<void> inscrire() => _messagerie.register();

  @override
  Future<void> desinscrire() => _messagerie.unregister();

  @override
  Stream<String> get installations => _messagerie.onRegistered;

  @override
  Stream<MessagePush> get recus => FirebaseMessaging.onMessage.map(_lire);

  @override
  Stream<MessagePush> get ouverts =>
      FirebaseMessaging.onMessageOpenedApp.map(_lire);

  @override
  Future<MessagePush?> ouvertureInitiale() async {
    final message = await _messagerie.getInitialMessage();
    return message == null ? null : _lire(message);
  }
}

/// Ouvre le canal au lancement. Ne fait jamais échouer le démarrage.
Future<CanalPush> ouvrirCanalPush() async {
  try {
    await Firebase.initializeApp();
    return CanalFirebase();
  } catch (erreur) {
    debugPrint('Notifications push indisponibles : $erreur');
    return const CanalInactif();
  }
}
