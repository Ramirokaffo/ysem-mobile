import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/espace.dart';
import '../../../core/providers.dart';
import '../../auth/application/session_controller.dart';
import 'canal_push.dart';

/// Ce qu'un push désigne : la notification, et l'espace auquel elle s'adresse.
class DestinationPush {
  const DestinationPush({
    required this.espace,
    required this.notificationId,
    required this.url,
  });

  final Espace espace;
  final int? notificationId;
  final String url;

  /// `null` quand le message ne désigne aucun espace de l'application.
  static DestinationPush? depuis(Map<String, dynamic> donnees) {
    final espace = Espace.values
        .where((e) => e.name == donnees['espace'])
        .firstOrNull;
    if (espace == null) return null;
    return DestinationPush(
      espace: espace,
      notificationId:
          int.tryParse((donnees['notification_id'] ?? '').toString()),
      url: (donnees['url'] ?? '').toString(),
    );
  }
}

/// Tient le téléphone déclaré auprès du serveur, et transmet à la coque ce
/// qui arrive.
///
/// Chaque ouverture de session inscrit le téléphone auprès de FCM, qui rend
/// son identifiant d'installation : c'est lui qui part au serveur, ce qui lui
/// dit aussi que le téléphone est toujours en service. Un changement de mot de
/// passe fait de même : le serveur coupe alors tous les téléphones de l'acteur,
/// celui-ci compris.
class PushController {
  PushController(this._ref, this._canal);

  final Ref _ref;
  final CanalPush _canal;

  final _recus = StreamController<MessagePush>.broadcast();
  final _ouvertures = StreamController<void>.broadcast();
  final List<StreamSubscription<dynamic>> _ecoutes = [];

  (Espace, int)? _declaration;
  Espace? _espaceJoignable;
  String? _dernierFid;
  DestinationPush? _enAttente;

  /// Les messages reçus application ouverte.
  Stream<MessagePush> get recus => _recus.stream;

  /// Signale qu'une destination attend d'être prise.
  Stream<void> get ouvertures => _ouvertures.stream;

  void demarrer() {
    _ecoutes
      ..add(_canal.recus.listen(_recus.add))
      ..add(_canal.ouverts.listen(_surOuverture))
      ..add(_canal.installations.listen(_surInstallation));
    unawaited(_canal.ouvertureInitiale().then((message) {
      if (message != null) _surOuverture(message);
    }).catchError((Object erreur) {
      debugPrint('Ouverture par notification illisible : $erreur');
    }));
  }

  void arreter() {
    for (final ecoute in _ecoutes) {
      ecoute.cancel();
    }
    _recus.close();
    _ouvertures.close();
  }

  void surSession(Session? avant, Session? apres) {
    if (apres == null) {
      _declaration = null;
      _espaceJoignable = null;
      _dernierFid = null;
      if (avant != null) unawaited(_desinscrire());
      return;
    }
    final declaration = (apres.espace, apres.revisionMotDePasse);
    if (declaration == _declaration) return;
    _declaration = declaration;
    unawaited(_inscrire(apres.espace));
  }

  Future<void> _inscrire(Espace espace) async {
    try {
      if (!await _canal.demanderAutorisation()) return;
      _espaceJoignable = espace;
      await _canal.inscrire();
    } catch (erreur) {
      _echec(erreur);
    }
  }

  /// FCM répond aussi de lui-même au démarrage : sans espace joignable, ni
  /// session ouverte ni autorisation, il n'y a personne à déclarer.
  void _surInstallation(String fid) {
    final espace = _espaceJoignable;
    if (espace == null) return;
    unawaited(_declarer(espace, fid));
  }

  Future<void> _declarer(Espace espace, String fid) async {
    try {
      await _ref.read(authRepositoryProvider(espace)).declarerAppareil(
            fid,
            defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
          );
      _dernierFid = fid;
    } catch (erreur) {
      _echec(erreur);
    }
  }

  /// Hors ligne, par exemple : le prochain changement de session réessaie.
  void _echec(Object erreur) {
    _declaration = null;
    debugPrint('Téléphone non déclaré : $erreur');
  }

  /// À appeler à la déconnexion, tant que les jetons de session sont valables.
  /// Hors ligne, la sortie n'attend pas : le téléphone se désinscrit de toute
  /// façon, et le serveur l'oubliera au premier envoi refusé.
  Future<void> retirer(Espace espace) async {
    final fid = _dernierFid;
    if (fid == null) return;
    try {
      await _ref.read(authRepositoryProvider(espace)).retirerAppareil(fid);
    } catch (erreur) {
      debugPrint('Téléphone non retiré : $erreur');
    }
  }

  Future<void> _desinscrire() async {
    try {
      await _canal.desinscrire();
    } catch (erreur) {
      debugPrint('Téléphone non désinscrit : $erreur');
    }
  }

  void _surOuverture(MessagePush message) {
    _enAttente = DestinationPush.depuis(message.donnees);
    if (_enAttente != null && !_ouvertures.isClosed) _ouvertures.add(null);
  }

  /// La destination à suivre pour cet espace, une seule fois. Celle d'un
  /// autre espace est abandonnée : un jeton d'un espace n'ouvre pas l'autre.
  DestinationPush? prendreDestination(Espace espace) {
    final destination = _enAttente;
    _enAttente = null;
    return destination?.espace == espace ? destination : null;
  }
}

/// Remplacé dans `main()` par le canal ouvert au lancement.
final canalPushProvider = Provider<CanalPush>((ref) => const CanalInactif());

final pushProvider = Provider<PushController>((ref) {
  final push = PushController(ref, ref.watch(canalPushProvider));
  ref.onDispose(push.arreter);
  push.demarrer();
  ref.listen(
    sessionProvider,
    (avant, apres) => push.surSession(avant?.valueOrNull, apres.valueOrNull),
    fireImmediately: true,
  );
  return push;
});
