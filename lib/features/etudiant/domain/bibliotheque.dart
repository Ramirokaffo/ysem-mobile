import '../../../core/models/json.dart';
import 'pagination.dart';

/// Modèles de `bibliotheque/` : l'arborescence composée par le service,
/// lue par **tous** les étudiants, sans filtre de cohorte.

class Categorie {
  const Categorie({required this.id, this.nom = ''});

  final int id;
  final String nom;

  factory Categorie.depuisJson(Json json) =>
      Categorie(id: json.entier('id') ?? 0, nom: json.texte('nom'));
}

class DossierBibliotheque {
  const DossierBibliotheque({
    required this.id,
    this.nom = '',
    this.description = '',
    this.nbSousDossiers,
    this.nbDocuments,
  });

  final int id;
  final String nom;
  final String description;
  final int? nbSousDossiers;
  final int? nbDocuments;

  static DossierBibliotheque? depuisJson(Json? json) => json == null
      ? null
      : DossierBibliotheque(
          id: json.entier('id') ?? 0,
          nom: json.texte('nom'),
          description: json.texte('description'),
          nbSousDossiers: json.entier('nb_sous_dossiers'),
          nbDocuments: json.entier('nb_documents'),
        );
}

class DocumentBibliotheque {
  const DocumentBibliotheque({
    required this.id,
    this.titre = '',
    this.auteurs = '',
    this.annee,
    this.description = '',
    this.categories = const [],
    this.extension = '',
    this.tailleLisible = '',
    this.nbTelechargements = 0,
    this.deposeLe,
  });

  final int id;
  final String titre;
  final String auteurs;
  final int? annee;
  final String description;
  final List<Categorie> categories;
  final String extension;
  final String tailleLisible;
  final int nbTelechargements;
  final DateTime? deposeLe;

  factory DocumentBibliotheque.depuisJson(Json json) => DocumentBibliotheque(
        id: json.entier('id') ?? 0,
        titre: json.texte('titre'),
        auteurs: json.texte('auteurs'),
        annee: json.entier('annee'),
        description: json.texte('description'),
        categories: json.liste('categories', Categorie.depuisJson),
        extension: json.texte('extension'),
        tailleLisible: json.texte('taille_lisible'),
        nbTelechargements: json.entier('nb_telechargements') ?? 0,
        deposeLe: json.date('depose_le'),
      );
}

/// Un dossier (la racine sans dossier), ou les résultats d'une recherche.
class VueBibliotheque {
  const VueBibliotheque({
    this.dossier,
    this.chemin = const [],
    this.categories = const [],
    this.dossiers = const [],
    this.paginationDossiers = const Pagination(),
    this.documents = const [],
    this.pagination = const Pagination(),
  });

  final DossierBibliotheque? dossier;

  /// Les ancêtres du dossier, de la racine vers lui.
  final List<DossierBibliotheque> chemin;
  final List<Categorie> categories;
  final List<DossierBibliotheque> dossiers;
  final Pagination paginationDossiers;
  final List<DocumentBibliotheque> documents;
  final Pagination pagination;

  factory VueBibliotheque.depuisJson(Json json) => VueBibliotheque(
        dossier: DossierBibliotheque.depuisJson(json.objet('dossier')),
        chemin: json.liste('chemin', (j) => DossierBibliotheque.depuisJson(j)!),
        categories: json.liste('categories', Categorie.depuisJson),
        dossiers:
            json.liste('dossiers', (j) => DossierBibliotheque.depuisJson(j)!),
        paginationDossiers:
            Pagination.depuisJson(json.objet('pagination_dossiers')),
        documents: json.liste('documents', DocumentBibliotheque.depuisJson),
        pagination: Pagination.depuisJson(json.objet('pagination')),
      );
}
