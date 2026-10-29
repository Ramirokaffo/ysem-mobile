import 'package:dio/dio.dart';

/// Erreur rendue par l'API, ou survenue en chemin.
///
/// Le backend répond toujours `{detail, code}` (plus `erreurs` champ par
/// champ pour un formulaire refusé) : `message` est ce que l'application
/// affiche — déjà traduit par le serveur — et `code` ce sur quoi elle
/// branche son comportement.
class ApiException implements Exception {
  ApiException({
    required this.code,
    required this.message,
    this.statut,
    this.erreurs = const {},
    this.donnees = const {},
  });

  /// Codes produits côté client, quand le serveur n'a rien pu dire.
  static const codeReseau = 'reseau';
  static const codeDelai = 'delai_depasse';
  static const codeAnnule = 'annule';
  static const codeInconnu = 'inconnu';

  /// Codes du backend qui obligent à rouvrir la connexion.
  static const codesSessionPerdue = {
    'mot_de_passe_change',
    'compte_inconnu',
    'acces_ferme',
    'session_expiree',
    // Portail enseignant : archiver un dossier ferme aussi le téléphone.
    'dossier_archive',
  };

  final String code;
  final String message;
  final int? statut;

  /// Erreurs de formulaire, par nom de champ (`__all__` pour l'ensemble).
  final Map<String, List<String>> erreurs;

  /// Corps complet de la réponse, pour les champs propres à une route
  /// (`tentatives_restantes`, `defi`…).
  final Map<String, dynamic> donnees;

  bool get estErreurReseau => code == codeReseau || code == codeDelai;
  bool get estFormulaireInvalide => code == 'formulaire_invalide';
  bool get exigeChangementMotDePasse => code == 'mot_de_passe_a_changer';
  bool get sessionPerdue => codesSessionPerdue.contains(code);

  /// Premier message d'erreur d'un champ, pour l'afficher sous le champ.
  String? erreurDuChamp(String champ) {
    final messages = erreurs[champ];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }

  factory ApiException.depuisDio(DioException e) {
    final reponse = e.response;
    final corps = reponse?.data;

    if (corps is Map) {
      final donnees = Map<String, dynamic>.from(corps);
      return ApiException(
        statut: reponse?.statusCode,
        code: (donnees['code'] ?? ApiException.codeInconnu).toString(),
        message: (donnees['detail'] ?? _messageParDefaut(reponse?.statusCode))
            .toString(),
        erreurs: _lireErreurs(donnees['erreurs']),
        donnees: donnees,
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          code: codeDelai,
          message: 'Le serveur met trop de temps à répondre.',
        );
      case DioExceptionType.connectionError:
        return ApiException(
          code: codeReseau,
          message: 'Impossible de joindre le serveur. Vérifiez votre connexion.',
        );
      case DioExceptionType.cancel:
        return ApiException(code: codeAnnule, message: 'Requête annulée.');
      default:
        return ApiException(
          statut: reponse?.statusCode,
          code: codeInconnu,
          message: _messageParDefaut(reponse?.statusCode),
        );
    }
  }

  static Map<String, List<String>> _lireErreurs(Object? brut) {
    if (brut is! Map) return const {};
    return brut.map((champ, messages) => MapEntry(
          champ.toString(),
          messages is List
              ? messages.map((m) => m.toString()).toList()
              : [messages.toString()],
        ));
  }

  static String _messageParDefaut(int? statut) {
    if (statut == null) return 'Une erreur inattendue est survenue.';
    if (statut >= 500) return 'Le serveur a rencontré une erreur ($statut).';
    if (statut == 404) return 'Ressource introuvable.';
    // Refusé en amont par le serveur web (taille d'envoi), sans corps JSON.
    if (statut == 413) return 'Le fichier joint est trop volumineux pour être envoyé.';
    if (statut == 403) return 'Accès refusé.';
    if (statut == 401) return 'Authentification requise.';
    return 'La requête a été refusée ($statut).';
  }

  @override
  String toString() => 'ApiException($statut, $code): $message';
}
