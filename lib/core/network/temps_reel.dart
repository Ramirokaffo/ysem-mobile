import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/env.dart';

/// Rend un jeton d'accès valide, ou `null` sans session. `forcer` demande
/// d'en obtenir un neuf même si le courant semble encore bon : le serveur
/// vient de le refuser.
typedef FournisseurJeton = Future<String?> Function({bool forcer});

/// Un websocket du serveur, tenu ouvert tant qu'on le demande.
///
/// Les mêmes routes que le navigateur (`ws/notifications/student/`,
/// `ws/messagerie/student/conversation/12/`…), à ceci près que le porteur est
/// le jeton de l'API — en en-tête `Authorization`, jamais dans l'adresse —
/// au lieu de la session (`notifications.jeton_ws` côté serveur). L'en-tête
/// `Origin` est celui du serveur lui-même : le validateur d'origine refuse une
/// poignée de main qui n'en porte pas.
///
/// Le canal ne fait que **recevoir** (et relayer « en train d'écrire… ») :
/// toute écriture passe par l'API, comme au web. Il bat le cœur toutes les
/// 45 s — c'est ce qui garde l'acteur « en ligne » côté serveur et ce qui y
/// fait relire le jeton — et se reconnecte seul, avec un délai croissant.
class CanalTempsReel {
  CanalTempsReel({
    required this.chemin,
    required FournisseurJeton jeton,
    String? baseUrl,
    this.battement = const Duration(seconds: 45),
    this.delaiMax = const Duration(seconds: 60),
  })  : _jeton = jeton,
        _base = Uri.parse(baseUrl ?? Env.apiBaseUrl);

  /// Chemin de la route, sans barre initiale : `ws/notifications/student/`.
  final String chemin;
  final Duration battement;
  final Duration delaiMax;

  final FournisseurJeton _jeton;
  final Uri _base;

  final _evenements = StreamController<Map<String, dynamic>>.broadcast();
  final ValueNotifier<bool> connecte = ValueNotifier(false);

  WebSocket? _socket;
  StreamSubscription<dynamic>? _ecoute;
  Timer? _battement;
  Timer? _reprise;
  bool _voulu = false;
  bool _enCours = false;
  bool _jetonARenouveler = false;
  int _echecs = 0;

  /// Évènements du serveur (`{"type": "notification", …}`), sans les `pong`.
  Stream<Map<String, dynamic>> get evenements => _evenements.stream;

  bool get estConnecte => connecte.value;

  /// Adresse du socket : `https` devient `wss`, `http` devient `ws`.
  Uri get adresse => _base.replace(
        scheme: _base.scheme == 'https' ? 'wss' : 'ws',
        path: '/$chemin',
        query: null,
      );

  /// Ouvre le canal (sans effet s'il l'est déjà) et le garde ouvert.
  void ouvrir() {
    if (_voulu) return;
    _voulu = true;
    _echecs = 0;
    unawaited(_connecter());
  }

  /// Ferme le canal et renonce à le rouvrir — l'application passe en arrière
  /// plan, l'écran se ferme. Fermer, c'est aussi ne plus être « en ligne ».
  void fermer() {
    _voulu = false;
    _reprise?.cancel();
    _arreter(fermerSocket: true);
  }

  /// Envoie une action au serveur (`ping`, `frappe`). Ignoré hors connexion.
  void envoyer(Map<String, dynamic> action) {
    final socket = _socket;
    if (socket == null || !estConnecte) return;
    try {
      socket.add(jsonEncode(action));
    } catch (_) {
      // La fermeture suivra : onDone s'en chargera.
    }
  }

  Future<void> dispose() async {
    fermer();
    connecte.dispose();
    await _evenements.close();
  }

  Future<void> _connecter() async {
    if (!_voulu || _enCours || _socket != null) return;
    _enCours = true;
    try {
      final jeton = await _jeton(forcer: _jetonARenouveler);
      _jetonARenouveler = false;
      if (!_voulu) return;
      if (jeton == null) {
        _planifierReprise();
        return;
      }
      final socket = await WebSocket.connect(
        adresse.toString(),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $jeton',
          'Origin': _base.origin,
        },
      ).timeout(const Duration(seconds: 15));
      if (!_voulu) {
        await socket.close();
        return;
      }
      _socket = socket;
      // Ping du protocole : détecte une connexion morte (réseau coupé) que
      // le système ne signalerait pas.
      socket.pingInterval = const Duration(seconds: 30);
      _ecoute = socket.listen(
        _recevoir,
        onDone: _surFermeture,
        onError: (_) => _surFermeture(),
        cancelOnError: true,
      );
      _echecs = 0;
      connecte.value = true;
      _battement = Timer.periodic(battement, (_) => envoyer({'action': 'ping'}));
    } catch (_) {
      // Poignée de main refusée (jeton expiré, compte refermé, fil hors de
      // portée) ou réseau absent : le serveur ne dit pas lequel. Au second
      // échec, puis de loin en loin, on renouvelle le jeton avant de réessayer.
      _echecs++;
      if (_echecs == 2 || _echecs % 6 == 0) _jetonARenouveler = true;
      _planifierReprise();
    } finally {
      _enCours = false;
    }
  }

  void _recevoir(dynamic brut) {
    if (brut is! String) return;
    Object? json;
    try {
      json = jsonDecode(brut);
    } catch (_) {
      return;
    }
    if (json is! Map) return;
    final evenement = Map<String, dynamic>.from(json);
    if (evenement['type'] == 'pong') return;
    if (!_evenements.isClosed) _evenements.add(evenement);
  }

  void _surFermeture() {
    final code = _socket?.closeCode;
    _arreter(fermerSocket: false);
    // 4001 : le serveur ne reconnaît plus le porteur (mot de passe changé,
    // dossier archivé). On ne réessaie qu'avec un jeton neuf ; si la session
    // est perdue, l'API le dira à l'application.
    if (code == 4001) _jetonARenouveler = true;
    _planifierReprise();
  }

  void _arreter({required bool fermerSocket}) {
    _battement?.cancel();
    _battement = null;
    unawaited(_ecoute?.cancel());
    _ecoute = null;
    final socket = _socket;
    _socket = null;
    if (fermerSocket && socket != null) unawaited(socket.close(1000));
    if (connecte.value) connecte.value = false;
  }

  void _planifierReprise() {
    if (!_voulu) return;
    _reprise?.cancel();
    _reprise = Timer(delaiReprise(_echecs, delaiMax), _connecter);
  }

  /// 1 s, 2 s, 4 s… plafonné, avec un aléa pour que les téléphones d'une
  /// salle ne reviennent pas tous à la même seconde après une coupure.
  @visibleForTesting
  static Duration delaiReprise(int echecs, Duration plafond) {
    final base = min(plafond.inMilliseconds,
        1000 * pow(2, min(echecs, 10)).toInt());
    final alea = Random().nextInt(max(1, base ~/ 4));
    return Duration(milliseconds: min(plafond.inMilliseconds, base + alea));
  }
}
