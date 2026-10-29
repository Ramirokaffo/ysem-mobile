import '../../../core/models/json.dart';

/// Modèles de `suggestions/` : les dépôts de l'étudiant et leur **état** —
/// la suite donnée reste interne au service, et le dépôt est anonyme pour lui.

class PreuveSuggestion {
  const PreuveSuggestion({required this.id, this.nom = '', this.extension = ''});

  final int id;

  /// « Preuve n° 2 » : le nom d'origine n'est pas conservé.
  final String nom;
  final String extension;

  factory PreuveSuggestion.depuisJson(Json json) => PreuveSuggestion(
        id: json.entier('id') ?? 0,
        nom: json.texte('nom'),
        extension: json.texte('extension'),
      );
}

class Suggestion {
  const Suggestion({
    required this.id,
    this.reference = '',
    this.texte = '',
    this.solution = '',
    this.statut = '',
    this.statutLibelle = '',
    this.deposeeLe,
    this.preuves = const [],
  });

  final int id;
  final String reference;
  final String texte;
  final String solution;

  /// `nouvelle`, `a_letude`, `retenue`, `non_retenue`.
  final String statut;
  final String statutLibelle;
  final DateTime? deposeeLe;
  final List<PreuveSuggestion> preuves;

  factory Suggestion.depuisJson(Json json) => Suggestion(
        id: json.entier('id') ?? 0,
        reference: json.texte('reference'),
        texte: json.texte('texte'),
        solution: json.texte('solution_proposee'),
        statut: json.texte('statut'),
        statutLibelle: json.texte('statut_libelle'),
        deposeeLe: json.date('deposee_le'),
        preuves: json.liste('preuves', PreuveSuggestion.depuisJson),
      );
}

class Suggestions {
  const Suggestions({
    this.suggestions = const [],
    this.champPreuves = 'preuves',
    this.preuvesMax = 5,
    this.anonymat = '',
  });

  final List<Suggestion> suggestions;
  final String champPreuves;
  final int preuvesMax;
  final String anonymat;

  factory Suggestions.depuisJson(Json json) => Suggestions(
        suggestions: json.liste('mes_suggestions', Suggestion.depuisJson),
        champPreuves: json.objet('preuves')?.texte('champ') ?? 'preuves',
        preuvesMax: json.objet('preuves')?.entier('maximum') ?? 5,
        anonymat: json.texte('anonymat'),
      );
}
