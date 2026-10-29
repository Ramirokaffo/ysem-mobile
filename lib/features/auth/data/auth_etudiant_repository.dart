import '../../../core/auth/espace.dart';
import '../../../core/network/endpoints.dart';
import 'auth_repository.dart';

export 'auth_repository.dart';

/// Authentification de l'API du portail étudiant : matricule + mot de passe
/// externe (le même que sur le web), puis code e-mail si la double
/// authentification est active.
class AuthEtudiantRepository extends AuthRepository {
  AuthEtudiantRepository(super.client);

  @override
  Espace get espace => Espace.etudiant;

  @override
  String get cleActeur => 'etudiant';

  Future<ResultatConnexion> connexion({
    required String matricule,
    required String motDePasse,
  }) async {
    final reponse = await client.post<Map<String, dynamic>>(
      RoutesEtudiant.connexion,
      donnees: {'matricule': matricule.trim(), 'mot_de_passe': motDePasse},
      public: true,
    );
    return lire(reponse);
  }
}
