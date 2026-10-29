/// Configuration d'environnement, fixée à la compilation.
///
/// L'adresse du backend se passe par `--dart-define` :
///
/// ```bash
/// flutter run --dart-define=API_BASE_URL=https://ysem.example.cm
/// ```
///
/// Le défaut vise un `runserver` local vu depuis l'émulateur Android
/// (`10.0.2.2` est l'hôte de la machine de développement).
class Env {
  const Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.20:8002',
  );

  /// Journalise les requêtes HTTP dans la console (jamais les en-têtes
  /// d'autorisation). Activé par `--dart-define=API_LOGS=true`.
  static const bool apiLogs = bool.fromEnvironment('API_LOGS');

  static const Duration delaiConnexion = Duration(seconds: 15);
  static const Duration delaiReception = Duration(seconds: 30);
}
