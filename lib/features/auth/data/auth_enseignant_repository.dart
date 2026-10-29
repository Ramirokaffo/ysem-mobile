import '../../../core/auth/espace.dart';
import '../../../core/network/endpoints.dart';
import 'auth_repository.dart';

export 'auth_repository.dart';

/// Authentification de l'API du portail enseignant : adresse e-mail + mot de
/// passe du portail web, compte activé exigé, dossier archivé refusé, puis
/// code e-mail si la double authentification est active.
class AuthEnseignantRepository extends AuthRepository {
  AuthEnseignantRepository(super.client);

  @override
  Espace get espace => Espace.enseignant;

  @override
  String get cleActeur => 'enseignant';

  Future<ResultatConnexion> connexion({
    required String email,
    required String motDePasse,
  }) async {
    final reponse = await client.post<Map<String, dynamic>>(
      RoutesEnseignant.connexion,
      donnees: {'email': email.trim(), 'mot_de_passe': motDePasse},
      public: true,
    );
    return lire(reponse);
  }

  /// Envoie le lien de réinitialisation du portail web. La réponse est la
  /// même que l'adresse soit connue ou non : rend son message.
  Future<String> motDePasseOublie(String email) async {
    final reponse = await client.post<Map<String, dynamic>>(
      RoutesEnseignant.motDePasseOublie,
      donnees: {'email': email.trim()},
      public: true,
    );
    return (reponse['detail'] ?? '').toString();
  }
}
