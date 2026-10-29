// Le menu d'un espace, tel que le décrit le registre du portail web : les
// deux espaces (étudiant, enseignant) le rendent sous la même forme.

import 'json.dart';

/// Une entrée du menu, reprise du registre du portail
/// (`student_portal.navigation` ou `lecturers.navigation`).
class SectionNavigation {
  const SectionNavigation({
    required this.code,
    required this.libelle,
    this.description = '',
    this.icone = '',
    this.badge,
    this.accesRapide = false,
  });

  final String code;
  final String libelle;
  final String description;

  /// Code Font Awesome du registre (`fa-graduation-cap`).
  final String icone;
  final int? badge;
  final bool accesRapide;

  factory SectionNavigation.depuisJson(Json json) => SectionNavigation(
        code: json.texte('code'),
        libelle: json.texte('libelle'),
        description: json.texte('description'),
        icone: json.texte('icone'),
        badge: json.entier('badge'),
        accesRapide: json.booleen('acces_rapide'),
      );
}

class GroupeNavigation {
  const GroupeNavigation({required this.titre, required this.sections});

  /// Vide pour le tableau de bord, qui n'a pas d'intitulé de groupe.
  final String titre;
  final List<SectionNavigation> sections;

  factory GroupeNavigation.depuisJson(Json json) => GroupeNavigation(
        titre: json.texte('titre'),
        sections: json.liste('sections', SectionNavigation.depuisJson),
      );
}

/// Réponse de `navigation/`.
class Navigation {
  const Navigation({required this.groupes, this.compteurs = const {}});

  final List<GroupeNavigation> groupes;
  final Json compteurs;

  Iterable<SectionNavigation> get sections =>
      groupes.expand((g) => g.sections);

  List<SectionNavigation> get accesRapides =>
      sections.where((s) => s.accesRapide && s.code != 'dashboard').toList();

  SectionNavigation? section(String code) =>
      sections.where((s) => s.code == code).firstOrNull;

  /// Notifications non lues (`compteurs.notification_unread_count`).
  int get notificationsNonLues =>
      compteurs.entier('notification_unread_count') ?? 0;

  /// Le même menu, avec le compteur des notifications relu à part
  /// (`notifications/compteur/`).
  Navigation avecNotificationsNonLues(int nombre) => Navigation(
        groupes: groupes,
        compteurs: {...compteurs, 'notification_unread_count': nombre},
      );

  factory Navigation.depuisJson(Json json) => Navigation(
        groupes: json.liste('groupes', GroupeNavigation.depuisJson),
        compteurs: json.objet('compteurs') ?? const {},
      );
}
