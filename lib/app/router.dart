import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/espace.dart';
import '../features/auth/application/session_controller.dart';
import '../features/auth/data/auth_etudiant_repository.dart';
import '../features/auth/presentation/changement_mot_de_passe_page.dart';
import '../features/auth/presentation/choix_espace_page.dart';
import '../features/auth/presentation/code_verification_page.dart';
import '../features/auth/presentation/connexion_enseignant_page.dart';
import '../features/auth/presentation/connexion_etudiant_page.dart';
import '../features/auth/presentation/demarrage_page.dart';
import '../features/etudiant/presentation/accueil/tableau_de_bord_page.dart';
import '../features/etudiant/presentation/notifications/notifications_page.dart';
import '../features/etudiant/presentation/profil/profil_page.dart';
import '../features/etudiant/presentation/section_page.dart';
import '../features/etudiant/presentation/services/services_page.dart';
import '../features/etudiant/presentation/shell_etudiant.dart';
import '../features/enseignant/presentation/accueil/tableau_de_bord_enseignant_page.dart';
import '../features/enseignant/presentation/onglets.dart';
import '../features/enseignant/presentation/profil/profil_enseignant_page.dart';
import '../features/enseignant/presentation/section_enseignant_page.dart';

class Routes {
  const Routes._();

  static const demarrage = '/demarrage';
  static const choixEspace = '/';
  static const connexionEtudiant = '/connexion/etudiant';
  static const codeEtudiant = '/connexion/etudiant/code';
  static const connexionEnseignant = '/connexion/enseignant';
  static const codeEnseignant = '/connexion/enseignant/code';

  static const accueilEtudiant = '/etudiant';
  static const servicesEtudiant = '/etudiant/services';
  static const notificationsEtudiant = '/etudiant/notifications';
  static const profilEtudiant = '/etudiant/profil';
  static const motDePasseEtudiant = '/etudiant/mot-de-passe';
  static String sectionEtudiant(String code) => '/etudiant/section/$code';

  static const accueilEnseignant = '/enseignant';
  static const servicesEnseignant = '/enseignant/services';
  static const notificationsEnseignant = '/enseignant/notifications';
  static const profilEnseignant = '/enseignant/profil';
  static const motDePasseEnseignant = '/enseignant/mot-de-passe';
  static String sectionEnseignant(String code) => '/enseignant/section/$code';

  static String accueil(Espace espace) => switch (espace) {
        Espace.etudiant => accueilEtudiant,
        Espace.enseignant => accueilEnseignant,
      };
}

final _cleRacine = GlobalKey<NavigatorState>(debugLabel: 'racine');

/// Routeur : la session décide où l'on peut aller.
final routerProvider = Provider<GoRouter>((ref) {
  final rafraichir = ValueNotifier(0);
  ref.listen(sessionProvider, (_, _) => rafraichir.value++);
  ref.onDispose(rafraichir.dispose);

  return GoRouter(
    navigatorKey: _cleRacine,
    initialLocation: Routes.demarrage,
    refreshListenable: rafraichir,
    redirect: (context, etat) => redirection(
      ref.read(sessionProvider),
      etat.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: Routes.demarrage,
        builder: (_, _) => const DemarragePage(),
      ),
      GoRoute(
        path: Routes.choixEspace,
        builder: (_, _) => const ChoixEspacePage(),
      ),
      GoRoute(
        path: Routes.connexionEtudiant,
        builder: (_, _) => const ConnexionEtudiantPage(),
      ),
      GoRoute(
        path: Routes.codeEtudiant,
        redirect: (_, etat) =>
            etat.extra is CodeRequis ? null : Routes.connexionEtudiant,
        builder: (_, etat) =>
            CodeVerificationPage(defi: etat.extra! as CodeRequis),
      ),
      GoRoute(
        path: Routes.connexionEnseignant,
        builder: (_, _) => const ConnexionEnseignantPage(),
      ),
      GoRoute(
        path: Routes.codeEnseignant,
        redirect: (_, etat) =>
            etat.extra is CodeRequis ? null : Routes.connexionEnseignant,
        builder: (_, etat) =>
            CodeVerificationPage(defi: etat.extra! as CodeRequis),
      ),
      GoRoute(
        path: Routes.motDePasseEtudiant,
        parentNavigatorKey: _cleRacine,
        builder: (_, _) => const ChangementMotDePassePage(),
      ),
      GoRoute(
        path: '/etudiant/section/:code',
        parentNavigatorKey: _cleRacine,
        builder: (_, etat) => SectionPage(code: etat.pathParameters['code']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, coque) => ShellEtudiant(coque: coque),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.accueilEtudiant,
              builder: (_, _) => const TableauDeBordPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.servicesEtudiant,
              builder: (_, _) => const ServicesPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.notificationsEtudiant,
              builder: (_, _) => const NotificationsPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.profilEtudiant,
              builder: (_, _) => const ProfilPage(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: Routes.motDePasseEnseignant,
        parentNavigatorKey: _cleRacine,
        builder: (_, _) => const ChangementMotDePassePage(),
      ),
      GoRoute(
        path: '/enseignant/section/:code',
        parentNavigatorKey: _cleRacine,
        builder: (_, etat) =>
            SectionEnseignantPage(code: etat.pathParameters['code']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, coque) => ShellEnseignant(coque: coque),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.accueilEnseignant,
              builder: (_, _) => const TableauDeBordEnseignantPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.servicesEnseignant,
              builder: (_, _) => const ServicesEnseignantPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.notificationsEnseignant,
              builder: (_, _) => const NotificationsEnseignantPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.profilEnseignant,
              builder: (_, _) => const ProfilEnseignantPage(),
            ),
          ]),
        ],
      ),
    ],
  );
});

/// Règle de redirection, isolée pour être testée sans routeur.
///
/// - session en cours de restauration : écran de démarrage ;
/// - personne de connecté : seules les pages publiques sont ouvertes ;
/// - mot de passe à changer : tout ramène à l'écran de changement — la
///   règle de `StudentPortalSecurityMiddleware`, que l'API applique aussi
///   (403 `mot_de_passe_a_changer`) ;
/// - connecté sur une page publique, ou sur une page de l'autre espace :
///   accueil de son espace (un jeton d'un espace n'ouvre pas l'autre).
String? redirection(AsyncValue<Session?> session, String ici) {
  if (session.isLoading && !session.hasValue) return Routes.demarrage;

  final ouverte = session.valueOrNull;
  final pagePublique = ici == Routes.choixEspace ||
      ici.startsWith('/connexion') ||
      ici == Routes.demarrage;

  if (ouverte == null) {
    return pagePublique && ici != Routes.demarrage ? null : Routes.choixEspace;
  }
  if (ouverte.espace == Espace.etudiant && ouverte.doitChangerMotDePasse) {
    return ici == Routes.motDePasseEtudiant ? null : Routes.motDePasseEtudiant;
  }
  if (pagePublique) return Routes.accueil(ouverte.espace);
  final autreEspace = switch (ouverte.espace) {
    Espace.etudiant => _dansLEspace(ici, Routes.accueilEnseignant),
    Espace.enseignant => _dansLEspace(ici, Routes.accueilEtudiant),
  };
  if (autreEspace) return Routes.accueil(ouverte.espace);
  return null;
}

bool _dansLEspace(String ici, String racine) =>
    ici == racine || ici.startsWith('$racine/');
