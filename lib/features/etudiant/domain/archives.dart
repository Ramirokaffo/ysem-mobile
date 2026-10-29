import '../../../core/models/json.dart';
import 'modeles.dart';
import 'notes.dart';
import 'pagination.dart';

/// Modèles de `archives/` : les anciennes épreuves publiées (le sujet seul,
/// **jamais le corrigé**) et les supports des années passées de la classe.

class Annale {
  const Annale({
    required this.id,
    this.cours = const CoursRef(),
    this.annee = '',
    this.typeExamenLibelle = '',
    this.semestre,
    this.intitule = '',
    this.dureeMinutes,
    this.nbPieces = 0,
    this.url,
  });

  final int id;
  final CoursRef cours;
  final String annee;
  final String typeExamenLibelle;
  final SemestreRef? semestre;
  final String intitule;
  final int? dureeMinutes;
  final int nbPieces;
  final String? url;

  factory Annale.depuisJson(Json json) => Annale(
        id: json.entier('id') ?? 0,
        cours: CoursRef.depuisJson(json.objet('cours')),
        annee: json.objet('annee')?.texte('nom') ?? '',
        typeExamenLibelle: json.texte('type_examen_libelle'),
        semestre: SemestreRef.depuisJson(json.objet('semestre')),
        intitule: json.texte('intitule'),
        dureeMinutes: json.entier('duree_minutes'),
        nbPieces: json.entier('nb_pieces') ?? 0,
        url: json.texteOuNul('url'),
      );
}

class SupportArchive {
  const SupportArchive({
    required this.id,
    this.type = '',
    this.typeLibelle = '',
    this.annee = '',
    this.cours = const CoursRef(),
    this.semestre,
    this.enseignant = '',
    this.url,
  });

  final int id;

  /// `plan` ou `support`.
  final String type;
  final String typeLibelle;
  final String annee;
  final CoursRef cours;
  final SemestreRef? semestre;
  final String enseignant;
  final String? url;

  factory SupportArchive.depuisJson(Json json) => SupportArchive(
        id: json.entier('id') ?? 0,
        type: json.texte('type'),
        typeLibelle: json.texte('type_libelle'),
        annee: json.objet('annee')?.texte('nom') ?? '',
        cours: CoursRef.depuisJson(json.objet('cours')),
        semestre: SemestreRef.depuisJson(json.objet('semestre')),
        enseignant: json.objet('enseignant')?.texte('nom') ?? '',
        url: json.texteOuNul('url'),
      );
}

class Archives {
  const Archives({
    this.annales = const [],
    this.paginationAnnales = const Pagination(),
    this.supports = const [],
    this.paginationSupports = const Pagination(),
    this.annees = const [],
  });

  final List<Annale> annales;
  final Pagination paginationAnnales;
  final List<SupportArchive> supports;
  final Pagination paginationSupports;

  /// Années qui ont laissé des archives, pour le filtre.
  final List<AnneeAcademique> annees;

  factory Archives.depuisJson(Json json) => Archives(
        annales: json.liste('annales', Annale.depuisJson),
        paginationAnnales:
            Pagination.depuisJson(json.objet('pagination_annales')),
        supports: json.liste('supports', SupportArchive.depuisJson),
        paginationSupports:
            Pagination.depuisJson(json.objet('pagination_supports')),
        annees: json.liste('annees', (j) => AnneeAcademique.depuisJson(j)!),
      );
}
