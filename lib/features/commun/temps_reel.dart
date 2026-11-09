import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/espace.dart';
import '../../core/network/temps_reel.dart';
import '../../core/providers.dart';

/// Les routes websocket du serveur, telles que l'application les ouvre.
///
/// L'espace fait partie du chemin, comme au navigateur : c'est lui qui dit au
/// serveur dans quel camp lire le porteur du jeton.
class CheminsTempsReel {
  const CheminsTempsReel._();

  /// `student` / `lecturer` : l'audience des notifications et le camp des
  /// chats côté serveur.
  static String camp(Espace espace) => switch (espace) {
        Espace.etudiant => 'student',
        Espace.enseignant => 'lecturer',
      };

  /// La cloche : compteur, notifications au fil de l'eau — et la présence
  /// en ligne de l'acteur, que ce socket tient côté serveur.
  static String notifications(Espace espace) =>
      'ws/notifications/${camp(espace)}/';

  /// Le fil de l'étudiant au guichet de la scolarité.
  static String guichet(int conversation) =>
      'ws/messagerie/student/conversation/$conversation/';

  /// La discussion d'une classe, depuis l'un ou l'autre espace.
  static String classe(Espace espace, int groupe) =>
      'ws/chat-cours/${camp(espace)}/groupe/$groupe/';

  /// Le dépouillement en direct d'un scrutin.
  static String scrutin(int id) => 'ws/association/scrutin/$id/';
}

/// Fabrique les canaux : un canal de l'espace, porté par le jeton de son API.
/// Remplacée dans les tests par des canaux factices.
final fabriqueCanalProvider =
    Provider<CanalTempsReel Function(Espace espace, String chemin)>(
  (ref) => (espace, chemin) => CanalTempsReel(
        chemin: chemin,
        jeton: ref.read(apiClientProvider(espace)).jetonAcces,
      ),
);

/// Un canal de l'espace, porté par le jeton de son API.
CanalTempsReel canalTempsReel(WidgetRef ref, Espace espace, String chemin) =>
    ref.read(fabriqueCanalProvider)(espace, chemin);

/// Tient un canal ouvert **tant que l'application est au premier plan**.
///
/// En arrière-plan, le socket se ferme : l'acteur n'est plus « en ligne », ce
/// qui est vrai, et le push prend le relais. Au retour, il se rouvre et
/// l'écran se resynchronise (`surRetour`).
class GardeCanal {
  GardeCanal(this.canal, {this.surRetour}) {
    _cycle = AppLifecycleListener(onStateChange: _surEtat);
    canal.ouvrir();
  }

  final CanalTempsReel canal;
  final VoidCallback? surRetour;
  late final AppLifecycleListener _cycle;

  void _surEtat(AppLifecycleState etat) {
    switch (etat) {
      case AppLifecycleState.resumed:
        canal.ouvrir();
        surRetour?.call();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        canal.fermer();
      case AppLifecycleState.inactive:
        // Volet de notifications, boîte de dialogue du système : on reste.
        break;
    }
  }

  void dispose() {
    _cycle.dispose();
    canal.dispose();
  }
}
