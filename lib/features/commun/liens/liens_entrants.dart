import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/espace.dart';
import '../../../core/config/env.dart';
import '../../enseignant/presentation/sections.dart';
import '../../etudiant/presentation/sections.dart';

/// Liens d'application Android (App Links) : une adresse du portail web
/// touchée hors de l'application — e-mail de notification, message collé dans
/// un groupe de classe — l'ouvre sur la même page.
///
/// Android ne remet à l'application que les chemins déclarés par
/// l'`intent-filter` du manifeste, après avoir vérifié que le site la reconnaît
/// (`/.well-known/assetlinks.json`, `main.liens_application` côté serveur). Les
/// deux listes ci-dessous sont **exactement** ces chemins — une garde
/// (`test/liens_entrants_test.dart`) compare au manifeste. Elles ne citent que
/// des pages que l'application sait ouvrir : jamais une page de connexion, le
/// lien de double authentification ou de réinitialisation du mot de passe
/// (réservés au web), le portail parent, l'admission, ni les écrans du
/// personnel — `/enseignants/` mêle le portail et la gestion des dossiers,
/// `/messagerie/` est aussi le guichet de la scolarité.
const cheminsEtudiant = [
  '/portail-etudiant/tableau-de-bord/',
  '/portail-etudiant/ma-scolarite/',
  '/portail-etudiant/planning-des-examens/',
  '/portail-etudiant/mes-notes/',
  '/portail-etudiant/mes-devoirs/',
  '/portail-etudiant/ma-promotion/',
  '/portail-etudiant/mes-supports-de-cours/',
  '/portail-etudiant/archives/',
  '/portail-etudiant/bibliotheque/',
  '/portail-etudiant/ma-reinscription/',
  '/portail-etudiant/mes-documents/',
  '/portail-etudiant/ma-situation-financiere/',
  '/portail-etudiant/ma-discipline/',
  '/portail-etudiant/mes-permissions/',
  '/portail-etudiant/ma-delegation/',
  '/portail-etudiant/evaluations/',
  '/portail-etudiant/association/',
  '/portail-etudiant/boite-a-suggestions/',
  '/portail-etudiant/mon-profil/',
  '/chat-cours/etudiant/',
  '/messagerie/mes-messages/',
];

/// Pendant enseignant de [cheminsEtudiant].
const cheminsEnseignant = [
  '/enseignants/tableau-de-bord/',
  '/enseignants/mon-emploi-du-temps/',
  '/enseignants/mes-disponibilites/',
  '/enseignants/mes-examens/',
  '/enseignants/mes-rattrapages/',
  '/enseignants/mes-classes/',
  '/enseignants/mes-devoirs/',
  '/enseignants/fiches-a-signer/',
  '/enseignants/mes-enseignements/',
  '/enseignants/mes-documents-de-cours/',
  '/enseignants/mes-plans-de-cours/',
  '/enseignants/mes-epreuves/',
  '/enseignants/mes-feuilles-de-notes/',
  '/enseignants/ma-ponctualite/',
  '/enseignants/mes-vacations/',
  '/enseignants/mon-dossier/',
  '/chat-cours/enseignant/',
];

/// Une page du portail web que l'application sait ouvrir.
class LienEntrant {
  const LienEntrant({required this.espace, required this.chemin});

  final Espace espace;

  /// Chemin web, lu par `sectionDeLAdresse` de l'espace.
  final String chemin;

  @override
  bool operator ==(Object other) =>
      other is LienEntrant && other.espace == espace && other.chemin == chemin;

  @override
  int get hashCode => Object.hash(espace, chemin);

  @override
  String toString() => 'LienEntrant(${espace.name}, $chemin)';
}

/// Hôte du serveur que vise la compilation : un lien d'un autre site (la pile
/// de test, pour une application de production) n'est pas suivi.
String get hoteDuServeur => Uri.parse(Env.apiBaseUrl).host;

/// La page du portail que désigne [uri], `null` si ce n'en est pas une — une
/// route de l'application, une adresse d'un autre site, un chemin non déclaré.
LienEntrant? lienEntrant(Uri uri, {String? hote}) {
  if (uri.host.isNotEmpty && uri.host != (hote ?? hoteDuServeur)) return null;
  var chemin = uri.path;
  if (!chemin.endsWith('/')) chemin = '$chemin/';
  for (final (espace, chemins, lecteur) in [
    (Espace.etudiant, cheminsEtudiant, sectionDeLAdresse),
    (Espace.enseignant, cheminsEnseignant, sectionEnseignantDeLAdresse),
  ]) {
    if (chemins.any(chemin.startsWith) && lecteur(chemin) != null) {
      return LienEntrant(espace: espace, chemin: chemin);
    }
  }
  return null;
}

/// Retient le lien arrivé, le temps que la session soit prête : la coque de
/// l'espace le prend en se montrant, comme une notification touchée à froid
/// (`CoqueEspace`). Le routeur, lui, mène à l'accueil — la section s'ouvre
/// par-dessus, si bien que « retour » ramène dans l'application plutôt que de
/// la fermer.
class LiensEntrants {
  final _arrivees = StreamController<void>.broadcast();
  LienEntrant? _enAttente;

  /// Signale qu'un lien attend d'être pris.
  Stream<void> get arrivees => _arrivees.stream;

  void retenir(LienEntrant lien) {
    _enAttente = lien;
    if (!_arrivees.isClosed) _arrivees.add(null);
  }

  /// Le lien à suivre dans cet espace, une seule fois. Celui de l'autre
  /// espace est abandonné : un jeton d'un espace n'ouvre pas l'autre.
  LienEntrant? prendre(Espace espace) {
    final lien = _enAttente;
    _enAttente = null;
    return lien?.espace == espace ? lien : null;
  }

  void fermer() => _arrivees.close();
}

final liensEntrantsProvider = Provider<LiensEntrants>((ref) {
  final liens = LiensEntrants();
  ref.onDispose(liens.fermer);
  return liens;
});
