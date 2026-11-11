import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

/// Sections du registre que l'application porte dans ses onglets ; les
/// autres s'ouvrent en plein écran par leur code.
const _onglets = {
  'dashboard': Routes.accueilEtudiant,
  'services': Routes.servicesEtudiant,
  'notifications': Routes.notificationsEtudiant,
  'profile': Routes.profilEtudiant,
};

/// Ouvre une section du menu : bascule d'onglet, ou écran par-dessus.
void ouvrirSection(BuildContext context, String code) {
  final onglet = _onglets[code];
  if (onglet != null) {
    context.go(onglet);
  } else {
    context.push(Routes.sectionEtudiant(code));
  }
}

/// Chemins du portail web (`student_portal/urls.py`, monté sous
/// `/portail-etudiant/`) et section du registre qu'ils désignent. Le plus
/// long l'emporte : `ma-situation-financiere/demandes-de-moratoire/` mène
/// aux moratoires, pas aux finances.
const _cheminsDuPortail = {
  '/portail-etudiant/tableau-de-bord/': 'dashboard',
  '/portail-etudiant/ma-scolarite/': 'academics',
  '/portail-etudiant/planning-des-examens/': 'examens',
  '/portail-etudiant/mes-notes/': 'notes',
  '/portail-etudiant/mes-devoirs/': 'devoirs',
  '/portail-etudiant/ma-promotion/': 'promotion',
  '/portail-etudiant/mes-supports-de-cours/': 'supports',
  '/portail-etudiant/archives/': 'archives',
  '/portail-etudiant/bibliotheque/': 'bibliotheque',
  '/portail-etudiant/ma-reinscription/': 'inscription',
  '/portail-etudiant/mes-documents/': 'documents',
  '/portail-etudiant/ma-situation-financiere/demandes-de-moratoire/':
      'moratoriums',
  '/portail-etudiant/ma-situation-financiere/': 'finances',
  '/portail-etudiant/ma-discipline/': 'discipline',
  '/portail-etudiant/mes-permissions/': 'permissions',
  '/portail-etudiant/ma-delegation/': 'delegation',
  '/portail-etudiant/evaluations/': 'evaluations',
  '/portail-etudiant/association/': 'association',
  '/portail-etudiant/boite-a-suggestions/': 'suggestions',
  '/portail-etudiant/mon-profil/': 'profile',
  '/chat-cours/etudiant/': 'discussions',
  '/messagerie/': 'messages',
};

/// Section de l'application que désigne l'adresse web d'une notification
/// (`/portail-etudiant/mes-notes/?…#…`, ou absolue), `null` si aucune.
String? sectionDeLAdresse(String adresse) {
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
