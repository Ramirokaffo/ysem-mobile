import 'package:flutter/services.dart';

/// Une lecture du compteur interne de l'appareil.
class LectureCompteur {
  const LectureCompteur({required this.ms, this.demarrage});

  /// Millisecondes depuis le démarrage, veille comprise.
  final int ms;

  /// Numéro du démarrage de l'appareil, quand le système le donne : deux
  /// lectures ne se comparent que d'un même démarrage.
  final int? demarrage;

  /// Temps écoulé depuis [avant], ou `null` s'il n'est pas mesurable.
  int? ecouleDepuis(LectureCompteur avant) {
    if (demarrage != avant.demarrage || ms < avant.ms) return null;
    return ms - avant.ms;
  }
}

/// Lit le compteur. Un plugin plutôt qu'un canal de `MainActivity` : il est
/// inscrit dans tous les moteurs, celui de la tâche de fond compris.
class HorlogeMonotone {
  const HorlogeMonotone();

  static const _canal = MethodChannel('ysem/horloge_monotone');

  /// `null` là où le compteur n'existe pas (iOS, tests) : la saisie reste
  /// possible, son heure sera marquée comme non vérifiée.
  Future<LectureCompteur?> lire() async {
    try {
      final valeurs = await _canal.invokeMapMethod<String, Object?>('lire');
      final ms = valeurs?['ms'];
      if (ms is! int) return null;
      final demarrage = valeurs?['demarrage'];
      return LectureCompteur(
        ms: ms,
        demarrage: demarrage is int ? demarrage : null,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
