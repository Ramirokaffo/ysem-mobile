/// Chemins de l'API du portail étudiant (`/api/v1/portail-etudiant/`).
///
/// Ils reprennent `student_portal/api/urls.py` du backend, section par
/// section, dans l'ordre du menu. Les routes à identifiant sont des
/// fonctions.
class RoutesEtudiant {
  const RoutesEtudiant._();

  // Compte
  static const connexion = 'auth/connexion/';
  static const verificationConnexion = 'auth/connexion/verification/';
  static const renvoyerCode = 'auth/connexion/renvoyer-code/';
  static const rafraichir = 'auth/rafraichir/';
  static const deconnexion = 'auth/deconnexion/';
  static const moi = 'auth/moi/';
  static const motDePasse = 'auth/mot-de-passe/';
  static const langue = 'auth/langue/';
  static const doubleAuthentification = 'auth/double-authentification/';

  // Menu, tableau de bord, profil
  static const navigation = 'navigation/';
  static const tableauDeBord = 'tableau-de-bord/';
  static const profil = 'profil/';
  static const profilModifier = 'profil/modifier/';
  static const profilPhoto = 'profil/photo/';

  // Scolarité
  static const scolarite = 'scolarite/';
  static const examens = 'examens/';
  static String examenPdf(int id) => 'examens/$id/pdf/';
  static const supports = 'supports/';
  static String supportTelecharger(int id) => 'supports/$id/telecharger/';
  static const notes = 'notes/';

  // Documents et finances
  static const documents = 'documents/';
  static String certificatInscription(int id) =>
      'documents/$id/certificat-inscription/';
  static const finances = 'finances/';
  static String recuPaiement(int id) => 'finances/paiements/$id/recu/';
  static String releveCompte(int annee) => 'finances/releve/$annee/';
  static const declarations = 'finances/declarations/';
  static String declarationRetirer(int id) =>
      'finances/declarations/$id/retirer/';
  static String declarationRecuBanque(int id) =>
      'finances/declarations/$id/recu-banque/';
  static const reinscription = 'reinscription/';
  static const moratoires = 'moratoires/';
  static String moratoireRetirer(int id) => 'moratoires/$id/retirer/';

  // Assiduité et discipline
  static const discipline = 'discipline/';
  static const permissions = 'permissions/';
  static String permissionRetirer(int id) => 'permissions/$id/retirer/';
  static const delegation = 'delegation/';
  static const delegationAppel = 'delegation/appel/';
  static const delegationCahier = 'delegation/cahier/';
  static String delegationAssistant(int id) =>
      'delegation/assistants/$id/appel/';

  // Vie étudiante
  static const evaluations = 'evaluations/';
  static const association = 'association/';
  static String associationListe(int id) => 'association/listes/$id/';
  static String associationResultats(int id) => 'association/resultats/$id/';
  static const associationHistorique = 'association/historique/';
  static String associationHistoriqueListe(int id) =>
      'association/historique/$id/';
  static const suggestions = 'suggestions/';
  static const bibliotheque = 'bibliotheque/';
  static String bibliothequeDocument(int id) => 'bibliotheque/documents/$id/';
  static const archives = 'archives/';
  static const promotion = 'promotion/';

  // Échanges
  static const discussions = 'discussions/';
  static String discussionMessages(String cle) => 'discussions/$cle/messages/';
  static String discussionLu(String cle) => 'discussions/$cle/lu/';
  static String discussionReaction(int id) => 'discussions/messages/$id/reaction/';
  static String discussionPiece(int id) => 'discussions/pieces-jointes/$id/';
  static const messages = 'messages/';
  static const messagesLu = 'messages/lu/';
  static String messageReaction(int id) => 'messages/$id/reaction/';
  static String messagePiece(int id) => 'messages/pieces-jointes/$id/';
  static const notifications = 'notifications/';
  static const notificationsCompteur = 'notifications/compteur/';
  static const notificationsToutLu = 'notifications/tout-marquer-lu/';
  static String notification(int id) => 'notifications/$id/';
}

/// Chemins de l'API du portail enseignant (`/api/v1/portail-enseignant/`),
/// repris de `lecturers/api/urls.py`, dans l'ordre du menu.
class RoutesEnseignant {
  const RoutesEnseignant._();

  // Compte
  static const connexion = 'auth/connexion/';
  static const motDePasseOublie = 'auth/mot-de-passe-oublie/';
  static const moi = 'auth/moi/';

  // Menu, tableau de bord, dossier
  static const navigation = 'navigation/';
  static const tableauDeBord = 'tableau-de-bord/';
  static const profil = 'profil/';
  static const profilModifier = 'profil/modifier/';
  static const profilPhoto = 'profil/photo/';

  // Planning
  static const emploiDuTemps = 'emploi-du-temps/';
  static const disponibilites = 'disponibilites/';
  static String disponibilite(int id) => 'disponibilites/$id/';
  static const examens = 'examens/';
  static String examenPdf(int id) => 'examens/$id/pdf/';
  static const rattrapages = 'rattrapages/';
  static String rattrapageProposer(int id) => 'rattrapages/$id/proposer/';

  // Mes cours
  static const classes = 'classes/';
  static String classe(String cle) => 'classes/$cle/';
  static String classeExporter(String cle) => 'classes/$cle/exporter/';
  static const fichesASigner = 'fiches-a-signer/';
  static const fichesSignerTout = 'fiches-a-signer/signer-tout/';
  static String ficheSigner(String genre, int id) =>
      'fiches-a-signer/$genre/$id/signer/';
  static String ficheRenvoyer(String genre, int id) =>
      'fiches-a-signer/$genre/$id/renvoyer/';
  static const enseignements = 'enseignements/';
  static const discussions = 'discussions/';
  static String discussionMessages(String cle) => 'discussions/$cle/messages/';
  static String discussionLu(String cle) => 'discussions/$cle/lu/';
  static String discussionReaction(int id) =>
      'discussions/messages/$id/reaction/';
  static String discussionPiece(int id) => 'discussions/pieces-jointes/$id/';

  // Documents et notes
  static const documents = 'documents/';
  static String documentDeposer(int id) => 'documents/depots/$id/';
  static String documentPiece(int id) => 'documents/pieces/$id/';
  static String plan(int id) => 'plans/$id/';
  static String planImporter(int id) => 'plans/$id/importer/';
  static const epreuves = 'epreuves/';
  static const epreuvesModeles = 'epreuves/modeles/';
  static String epreuveDeposer(int id) => 'epreuves/sujets/$id/';
  static String epreuvePiece(int id) => 'epreuves/pieces/$id/';
  static String epreuveModele(int id, int numero, String langue) =>
      'epreuves/$id/modele/$numero/$langue/';
  static const feuilles = 'feuilles-de-notes/';
  static String feuille(int id) => 'feuilles-de-notes/$id/';
  static String controle(int feuille, int controle) =>
      'feuilles-de-notes/$feuille/controles/$controle/';

  // Ma situation
  static const ponctualite = 'ponctualite/';
  static const vacations = 'vacations/';
  static String ficheTransmettre(int id) => 'vacations/fiches/$id/transmettre/';

  // Notifications
  static const notifications = 'notifications/';
  static const notificationsCompteur = 'notifications/compteur/';
  static const notificationsToutLu = 'notifications/tout-marquer-lu/';
  static String notification(int id) => 'notifications/$id/';
}
