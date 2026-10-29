import 'json.dart';
import 'pagination.dart';

/// Une notification du centre d'un espace (`student` ou `lecturer`) :
/// `Notification.as_payload` du backend, rendue telle quelle par les deux API.
class NotificationPortail {
  const NotificationPortail({
    required this.id,
    required this.titre,
    this.message = '',
    this.categorie = '',
    this.categorieLibelle = '',
    this.niveau = 'info',
    this.url = '',
    this.lue = false,
    this.creeLe,
  });

  final int id;
  final String titre;
  final String message;

  /// `payment`, `notes`, `planning`… (`notifications.models.CATEGORY_CHOICES`).
  final String categorie;
  final String categorieLibelle;

  /// `info`, `success`, `warning` ou `danger`.
  final String niveau;

  /// Adresse du portail web que la notification désigne.
  final String url;
  final bool lue;
  final DateTime? creeLe;

  NotificationPortail copieLue(bool valeur) => NotificationPortail(
        id: id,
        titre: titre,
        message: message,
        categorie: categorie,
        categorieLibelle: categorieLibelle,
        niveau: niveau,
        url: url,
        lue: valeur,
        creeLe: creeLe,
      );

  factory NotificationPortail.depuisJson(Json json) => NotificationPortail(
        id: json.entier('id') ?? 0,
        titre: json.texte('title'),
        message: json.texte('message'),
        categorie: json.texte('category'),
        categorieLibelle: json.texte('category_label'),
        niveau: json.texteOuNul('level') ?? 'info',
        url: json.texte('url'),
        lue: json.booleen('is_read'),
        creeLe: json.date('created_at'),
      );
}

/// Une page du centre (`GET notifications/`).
class PageNotifications {
  const PageNotifications({
    required this.notifications,
    required this.pagination,
    this.nonLues = 0,
  });

  final List<NotificationPortail> notifications;
  final Pagination pagination;
  final int nonLues;

  factory PageNotifications.depuisJson(Json json) => PageNotifications(
        notifications:
            json.liste('notifications', NotificationPortail.depuisJson),
        pagination: Pagination.depuisJson(json.objet('pagination')),
        nonLues: json.entier('non_lues') ?? 0,
      );
}
