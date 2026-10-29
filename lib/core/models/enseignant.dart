import 'json.dart';

/// L'enseignant tel que son propre portail le lui montre
/// (`lecturers/api/serializers.py::enseignant_moi`).
class Enseignant {
  const Enseignant({
    required this.matricule,
    required this.prenom,
    required this.nom,
    required this.nomComplet,
    this.email = '',
    this.telephone = '',
    this.genreLibelle = '',
    this.gradeLibelle = '',
    this.profilLibelle = '',
    this.departement = '',
    this.dernierDiplomeLibelle = '',
    this.dateRecrutement,
    this.permanent = false,
    this.statut = '',
    this.statutLibelle = '',
    this.recrute = false,
    this.langueEffective = 'fr',
    this.langueAffichage = '',
    this.aUnePhoto = false,
    this.derniereConnexion,
    this.doubleAuthentification = false,
  });

  final String matricule;
  final String prenom;
  final String nom;
  final String nomComplet;
  final String email;
  final String telephone;
  final String genreLibelle;

  /// Fixé par le service (il résout le taux de vacation) : lu, jamais saisi.
  final String gradeLibelle;
  final String profilLibelle;
  final String departement;
  final String dernierDiplomeLibelle;
  final DateTime? dateRecrutement;
  final bool permanent;

  /// `draft`, `pending`, `refused`, `hired`, `archived`…
  final String statut;
  final String statutLibelle;

  /// Dossier recruté : les services réservés lui sont ouverts.
  final bool recrute;
  final String langueEffective;

  /// Langue choisie explicitement (vide : celle du profil fait le défaut).
  final String langueAffichage;

  /// La photo se sert par `profil/photo/`, avec le jeton.
  final bool aUnePhoto;
  final DateTime? derniereConnexion;
  final bool doubleAuthentification;

  /// Session restaurée hors ligne : on ne sait encore rien de l'enseignant.
  bool get estVide => matricule.isEmpty;

  String get initiales {
    String premiere(String s) => s.trim().isEmpty ? '' : s.trim()[0];
    final i = '${premiere(prenom)}${premiere(nom)}'.toUpperCase();
    return i.isEmpty ? '?' : i;
  }

  factory Enseignant.depuisJson(Json json) => Enseignant(
        matricule: json.texte('matricule'),
        prenom: json.texte('prenom'),
        nom: json.texte('nom'),
        nomComplet: json.texte('nom_complet'),
        email: json.texte('email'),
        telephone: json.texte('telephone'),
        genreLibelle: json.texte('genre_libelle'),
        gradeLibelle: json.texte('grade_libelle'),
        profilLibelle: json.texte('profil_libelle'),
        departement: json.objet('departement')?.texte('nom') ?? '',
        dernierDiplomeLibelle: json.texte('dernier_diplome_libelle'),
        dateRecrutement: json.date('date_recrutement'),
        permanent: json.booleen('permanent'),
        statut: json.texte('statut'),
        statutLibelle: json.texte('statut_libelle'),
        recrute: json.booleen('recrute'),
        langueEffective: json.texteOuNul('langue_effective') ?? 'fr',
        langueAffichage: json.texte('langue_affichage'),
        aUnePhoto: json.texteOuNul('photo') != null,
        derniereConnexion: json.date('derniere_connexion'),
        doubleAuthentification: json.booleen('double_authentification'),
      );
}
