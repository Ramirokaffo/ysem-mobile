import 'json.dart';

/// Référence nommée du référentiel (programme, spécialité, niveau…).
class Reference {
  const Reference({required this.id, required this.nom, this.nomEn = ''});

  final int? id;
  final String nom;
  final String nomEn;

  /// Le nom dans la langue de l'utilisateur, repli sur le français.
  String libelle(String langue) =>
      langue == 'en' && nomEn.isNotEmpty ? nomEn : nom;

  static Reference? depuisJson(Json? json) => json == null
      ? null
      : Reference(
          id: json.entier('id'),
          nom: json.texte('nom'),
          nomEn: json.texte('nom_en'),
        );
}

/// L'étudiant tel que son propre portail le lui montre
/// (`student_portal/api/serializers.py::etudiant`).
class Etudiant {
  const Etudiant({
    required this.matricule,
    required this.prenom,
    required this.nom,
    required this.nomComplet,
    this.email = '',
    this.telephone = '',
    this.genreLibelle = '',
    this.dateNaissance,
    this.langueEffective = 'fr',
    this.langueAffichage = '',
    this.programme,
    this.photo,
    this.statutLibelle = '',
    this.derniereConnexion,
    this.doitChangerMotDePasse = false,
    this.doubleAuthentification = false,
  });

  final String matricule;
  final String prenom;
  final String nom;
  final String nomComplet;
  final String email;
  final String telephone;
  final String genreLibelle;
  final DateTime? dateNaissance;
  final String langueEffective;

  /// Langue choisie explicitement (vide : celle du profil fait le défaut).
  final String langueAffichage;
  final Reference? programme;

  /// Chemin relatif de la photo (`/media/...`), ou `null`.
  final String? photo;
  final String statutLibelle;
  final DateTime? derniereConnexion;
  final bool doitChangerMotDePasse;
  final bool doubleAuthentification;

  /// Session restaurée hors ligne : on ne sait encore rien de l'étudiant.
  bool get estVide => matricule.isEmpty;

  String get initiales {
    String premiere(String s) => s.trim().isEmpty ? '' : s.trim()[0];
    final i = '${premiere(prenom)}${premiere(nom)}'.toUpperCase();
    return i.isEmpty ? '?' : i;
  }

  factory Etudiant.depuisJson(Json json) => Etudiant(
        matricule: json.texte('matricule'),
        prenom: json.texte('prenom'),
        nom: json.texte('nom'),
        nomComplet: json.texte('nom_complet'),
        email: json.texte('email'),
        telephone: json.texte('telephone'),
        genreLibelle: json.texte('genre_libelle'),
        dateNaissance: json.date('date_naissance'),
        langueEffective: json.texteOuNul('langue_effective') ?? 'fr',
        langueAffichage: json.texte('langue_affichage'),
        programme: Reference.depuisJson(json.objet('programme')),
        photo: json.texteOuNul('photo'),
        statutLibelle: json.texte('statut_libelle'),
        derniereConnexion: json.date('derniere_connexion'),
        doitChangerMotDePasse: json.booleen('doit_changer_mot_de_passe'),
        doubleAuthentification: json.booleen('double_authentification'),
      );
}
