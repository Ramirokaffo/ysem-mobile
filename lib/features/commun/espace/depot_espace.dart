import '../../../core/models/navigation.dart';
import '../../../core/models/notifications.dart';

/// Ce que les deux API (portail étudiant, portail enseignant) rendent sous la
/// même forme : le menu tiré du registre du portail et le centre de
/// notifications (`Notification.as_payload`).
///
/// C'est ce qui permet à la coque, à la page « Services » et au centre de
/// notifications d'être écrits une seule fois pour les deux espaces.
abstract interface class DepotEspace {
  /// `complet` ajoute les pastilles coûteuses (`?complet=1`).
  Future<Navigation> navigation({bool complet = false});

  Future<PageNotifications> notifications(
      {int page = 1, bool nonLuesSeulement = false});

  Future<int> compteurNotifications();

  Future<void> marquerNotification(int id, {required bool lue});

  Future<void> supprimerNotification(int id);

  Future<void> toutMarquerLu();
}
