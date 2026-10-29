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
  });

  final String nom;
  final String libelle;
  final String aide;
  final bool obligatoire;

  /// Classe du champ Django (`DateField`, `ModelChoiceField`…).
  final String type;
  final List<OptionChamp> choix;

  factory ChampFormulaire.depuisJson(Json json) => ChampFormulaire(
        nom: json.texte('nom'),
        libelle: json.texte('libelle'),
        aide: json.texte('aide'),
        obligatoire: json.booleen('obligatoire'),
        type: json.texte('type'),
        choix: json.liste('choix', OptionChamp.depuisJson),
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
