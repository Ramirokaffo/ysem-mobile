/// Les deux espaces que sert l'application, chacun avec son API.
///
/// Un jeton d'un espace n'ouvre jamais l'autre (revendications `student_id`
/// et `lecturer_id`) : les jetons sont donc rangés espace par espace.
enum Espace {
  etudiant(prefixe: '/api/v1/portail-etudiant/'),

  /// API du portail enseignant (`lecturers/api/`).
  enseignant(prefixe: '/api/v1/portail-enseignant/');

  const Espace({required this.prefixe});

  /// Préfixe des routes de l'espace, avec la barre finale (les chemins des
  /// points d'entrée sont relatifs : `auth/connexion/`).
  final String prefixe;
}
