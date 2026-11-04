import 'json.dart';

/// Une option d'une liste fermée d'un formulaire du web.
class OptionChamp {
  const OptionChamp({required this.valeur, required this.libelle});

  /// Ce qui se poste (identifiant, code).
  final String valeur;
  final String libelle;

  factory OptionChamp.depuisJson(Json json) => OptionChamp(
        valeur: json.texte('valeur'),
        libelle: json.texte('libelle'),
      );
}

/// Un champ d'un formulaire du portail web, tel que l'API le décrit
/// (`lecturers/api/formulaires.py::description_champs`) : l'application
/// compose son formulaire à partir de ce que le web déclare, au lieu d'en
/// tenir une copie qui divergerait.
class ChampFormulaire {
  const ChampFormulaire({
    required this.nom,
    required this.libelle,
    this.aide = '',
    this.obligatoire = false,
    this.type = '',
    this.choix = const [],
    this.multiligne = false,
    this.retirable = false,
    this.champAutre = '',
    this.valeurAutre = '',
  });

  final String nom;
  final String libelle;
  final String aide;
  final bool obligatoire;

  /// Classe du champ Django (`DateField`, `ModelChoiceField`…).
  final String type;
  final List<OptionChamp> choix;

  /// Zone de texte plutôt que ligne simple.
  final bool multiligne;

  /// Pièce que le web permet d'effacer (`<champ>_retirer`).
  final bool retirable;

  /// Liste fermée sur « Autres » : le champ libre, et la valeur qui le révèle.
  final String champAutre;
  final String valeurAutre;

  bool get estFichier => type == 'FileField' || type == 'ImageField';
  bool get estDate => type == 'DateField';
  bool get estBooleen => type == 'BooleanField';
  bool get estEntier => type == 'IntegerField';
  bool get estEmail => type == 'EmailField';
  bool get estListe => choix.isNotEmpty || champAutre.isNotEmpty;

  factory ChampFormulaire.depuisJson(Json json) => ChampFormulaire(
        nom: json.texte('nom'),
        libelle: json.texte('libelle'),
        aide: json.texte('aide'),
        obligatoire: json.booleen('obligatoire'),
        type: json.texte('type'),
        choix: json.liste('choix', OptionChamp.depuisJson),
        multiligne: json.booleen('multiligne'),
        retirable: json.booleen('retirable'),
        champAutre: json.texte('champ_autre'),
        valeurAutre: json.texte('valeur_autre'),
      );
}

/// Les champs d'un formulaire, par nom.
class DescriptionFormulaire {
  const DescriptionFormulaire(this.champs);

  final List<ChampFormulaire> champs;

  ChampFormulaire? operator [](String nom) =>
      champs.where((c) => c.nom == nom).firstOrNull;

  static DescriptionFormulaire depuisJson(Json json, String cle) =>
      DescriptionFormulaire(json.liste(cle, ChampFormulaire.depuisJson));
}
