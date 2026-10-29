import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

/// Sections du registre `lecturers.navigation` que l'application porte dans
/// ses onglets ; les autres s'ouvrent en plein écran par leur code.
const _onglets = {
  'dashboard': Routes.accueilEnseignant,
  'services': Routes.servicesEnseignant,
  'notifications': Routes.notificationsEnseignant,
  'profile': Routes.profilEnseignant,
};

/// Ouvre une section du menu : bascule d'onglet, ou écran par-dessus.
void ouvrirSectionEnseignant(BuildContext context, String code) {
  final onglet = _onglets[code];
  if (onglet != null) {
    context.go(onglet);
  } else {
    context.push(Routes.sectionEnseignant(code));
  }
}

/// Chemins du portail web enseignant (`lecturers/urls.py`, monté sous
/// `/enseignants/`) et section du registre qu'ils désignent. Le plus long
/// l'emporte.
const _cheminsDuPortail = {
  '/enseignants/tableau-de-bord/': 'dashboard',
  '/enseignants/mon-emploi-du-temps/': 'emploi_du_temps',
  '/enseignants/mes-disponibilites/': 'disponibilites',
  '/enseignants/mes-examens/': 'examens',
  '/enseignants/mes-rattrapages/': 'rattrapages',
  '/enseignants/mes-classes/': 'classes',
  '/enseignants/fiches-a-signer/': 'fiches_a_signer',
  '/enseignants/mes-enseignements/': 'enseignements',
  '/enseignants/mes-documents-de-cours/': 'documents',
  '/enseignants/mes-plans-de-cours/': 'documents',
  '/enseignants/mes-epreuves/': 'epreuves',
  '/enseignants/mes-feuilles-de-notes/': 'feuilles_de_notes',
  '/enseignants/ma-ponctualite/': 'ponctualite',
  '/enseignants/mes-vacations/': 'vacations',
  '/enseignants/mon-dossier/': 'dossier',
  '/enseignants/changer-mot-de-passe/': 'profile',
  '/chat-cours/enseignant/': 'discussions',
};

/// Section de l'application que désigne l'adresse web d'une notification
/// de l'espace `lecturer`, `null` si aucune.
String? sectionEnseignantDeLAdresse(String adresse) {
  if (adresse.trim().isEmpty) return null;
  final uri = Uri.tryParse(adresse.trim());
  if (uri == null) return null;
  var chemin = uri.path;
  if (!chemin.endsWith('/')) chemin = '$chemin/';
  String? trouvee;
  var longueur = 0;
  for (final MapEntry(key: prefixe, value: code) in _cheminsDuPortail.entries) {
    if (chemin.startsWith(prefixe) && prefixe.length > longueur) {
      trouvee = code;
      longueur = prefixe.length;
    }
  }
  return trouvee;
}
