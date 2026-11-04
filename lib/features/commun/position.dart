import 'package:geolocator/geolocator.dart';

/// Position relevée par le téléphone, au moment d'enregistrer : le serveur la
/// confronte à la zone de référence (`main.geolocalisation`).
class PositionRelevee {
  const PositionRelevee({
    required this.latitude,
    required this.longitude,
    required this.precision,
    this.horodatage,
  });

  final double latitude;
  final double longitude;

  /// Rayon d'incertitude annoncé, en mètres.
  final double precision;

  /// Instant du relevé. Il vient du récepteur GPS et non de l'horloge du
  /// téléphone : le serveur s'en sert pour contrôler une saisie hors ligne.
  final DateTime? horodatage;

  /// Les champs que l'API attend (`geo_latitude`, `geo_longitude`,
  /// `geo_precision`), les mêmes que le formulaire du web.
  Map<String, String> get champs => {
        'geo_latitude': latitude.toStringAsFixed(7),
        'geo_longitude': longitude.toStringAsFixed(7),
        'geo_precision': precision.toStringAsFixed(1),
        if (horodatage != null)
          'geo_horodatage': horodatage!.toUtc().toIso8601String(),
      };
}

/// Pourquoi la position n'a pas pu être relevée.
enum RaisonPosition { serviceDesactive, refusee, refuseeDefinitivement, delai }

class PositionIndisponible implements Exception {
  const PositionIndisponible(this.raison);

  final RaisonPosition raison;
}

/// Relève la position en haute précision, sans position en cache — même
/// règle que le navigateur (`student_portal/js/geolocalisation.js`).
///
/// `delai` s'allonge sans réseau : le GPS ne reçoit alors aucune aide des
/// antennes et met plus de temps à trouver les satellites.
Future<PositionRelevee> releverPosition(
    {Duration delai = const Duration(seconds: 25)}) async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const PositionIndisponible(RaisonPosition.serviceDesactive);
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    throw const PositionIndisponible(RaisonPosition.refuseeDefinitivement);
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.unableToDetermine) {
    throw const PositionIndisponible(RaisonPosition.refusee);
  }
  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: delai,
      ),
    );
    return PositionRelevee(
      latitude: position.latitude,
      longitude: position.longitude,
      precision: position.accuracy,
      horodatage: position.timestamp,
    );
  } on Exception {
    throw const PositionIndisponible(RaisonPosition.delai);
  }
}
