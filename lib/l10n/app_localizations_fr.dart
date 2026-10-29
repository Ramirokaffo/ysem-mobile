// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'YSEM';

  @override
  String get bienvenue => 'Bienvenue à YSEM';

  @override
  String get choisirEspace => 'Choisissez votre espace pour continuer.';

  @override
  String get espaceEtudiant => 'Espace étudiant';

  @override
  String get espaceEtudiantDescription =>
      'Emploi du temps, notes, finances et documents.';

  @override
  String get espaceEnseignant => 'Espace enseignant';

  @override
  String get espaceEnseignantDescription =>
      'Cours, séances, notes et vacations.';

  @override
  String get bientotDisponible => 'Bientôt disponible';

  @override
  String get connexion => 'Connexion';

  @override
  String get seConnecter => 'Se connecter';

  @override
  String get deconnexion => 'Se déconnecter';

  @override
  String get deconnexionConfirmation =>
      'Vous devrez saisir à nouveau votre matricule et votre mot de passe pour revenir.';

  @override
  String get connexionEtudiantConsigne =>
      'Connectez-vous avec votre matricule et le mot de passe du portail étudiant.';

  @override
  String get connexionAide =>
      'Mot de passe oublié ou accès non configuré ? Rapprochez-vous de la scolarité.';

  @override
  String get matricule => 'Matricule';

  @override
  String get motDePasse => 'Mot de passe';

  @override
  String get afficher => 'Afficher';

  @override
  String get masquer => 'Masquer';

  @override
  String get champObligatoire => 'Ce champ est obligatoire.';

  @override
  String get verificationTitre => 'Vérification';

  @override
  String get verificationConsigne =>
      'Saisissez le code à six chiffres reçu par e-mail.';

  @override
  String verificationConsigneAdresse(String adresse) {
    return 'Saisissez le code à six chiffres envoyé à $adresse.';
  }

  @override
  String get verificationAide =>
      'Pensez à vérifier vos courriers indésirables.';

  @override
  String get codeVerification => 'Code de vérification';

  @override
  String codeExpireDans(String duree) {
    return 'Le code expire dans $duree';
  }

  @override
  String get codeExpire => 'Le code a expiré : demandez-en un nouveau.';

  @override
  String get verifier => 'Vérifier';

  @override
  String get renvoyerCode => 'Renvoyer le code';

  @override
  String tentativesRestantes(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: 'Encore $nombre essais.',
      one: 'Encore 1 essai.',
    );
    return '$_temp0';
  }

  @override
  String get changerMotDePasse => 'Changer le mot de passe';

  @override
  String get motDePasseImposeConsigne =>
      'Pour votre sécurité, choisissez un nouveau mot de passe avant de continuer.';

  @override
  String get motDePasseVolontaireConsigne =>
      'Le nouveau mot de passe vaut aussi pour le portail web.';

  @override
  String get motDePasseActuel => 'Mot de passe actuel';

  @override
  String get nouveauMotDePasse => 'Nouveau mot de passe';

  @override
  String get confirmationMotDePasse => 'Confirmer le nouveau mot de passe';

  @override
  String get confirmationDifferente =>
      'Les deux mots de passe ne correspondent pas.';

  @override
  String get enregistrer => 'Enregistrer';

  @override
  String get annuler => 'Annuler';

  @override
  String get confirmer => 'Confirmer';

  @override
  String get ongletAccueil => 'Accueil';

  @override
  String get ongletServices => 'Services';

  @override
  String get ongletNotifications => 'Notifications';

  @override
  String get ongletProfil => 'Profil';

  @override
  String bonjour(String nom) {
    return 'Bonjour, $nom';
  }

  @override
  String get situationFinanciere => 'Situation financière';

  @override
  String get montantPaye => 'Payé';

  @override
  String get resteAPayer => 'Reste à payer';

  @override
  String get montantEchu => 'Échu';

  @override
  String get prochainesSeances => 'Prochaines séances';

  @override
  String get aucuneSeance => 'Aucune séance à venir cette semaine.';

  @override
  String get datesAVenir => 'Dates à venir';

  @override
  String get aucuneDate => 'Aucune date annoncée au calendrier.';

  @override
  String get documentsRecents => 'Documents récents';

  @override
  String get aucunDocument => 'Aucun document pour le moment.';

  @override
  String get toutVoir => 'Tout voir';

  @override
  String get seanceAnnulee => 'Annulée';

  @override
  String get seanceChomee => 'Jour chômé';

  @override
  String get seanceRattrapage => 'Rattrapage';

  @override
  String get seanceTroncCommun => 'Tronc commun';

  @override
  String notificationsNonLues(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre notifications non lues',
      one: '1 notification non lue',
    );
    return '$_temp0';
  }

  @override
  String get informations => 'Informations';

  @override
  String get aucuneInformation => 'Aucune information au dossier.';

  @override
  String get email => 'Adresse e-mail';

  @override
  String get telephone => 'Téléphone';

  @override
  String get dateNaissance => 'Date de naissance';

  @override
  String get genre => 'Genre';

  @override
  String get residence => 'Résidence';

  @override
  String get statut => 'Statut';

  @override
  String get securite => 'Sécurité du compte';

  @override
  String get doubleAuthentification => 'Double authentification';

  @override
  String get doubleAuthentificationAide =>
      'Un code envoyé par e-mail est demandé à chaque connexion.';

  @override
  String get activerDoubleAuthentification =>
      'Activer la double authentification';

  @override
  String get desactiverDoubleAuthentification =>
      'Désactiver la double authentification';

  @override
  String get confirmerParMotDePasse => 'Confirmez avec votre mot de passe.';

  @override
  String get langue => 'Langue';

  @override
  String get langueAide => 'Votre choix vaut aussi pour le portail web.';

  @override
  String get connexionsRecentes => 'Connexions récentes';

  @override
  String get aImplementer => 'Bientôt dans l\'application';

  @override
  String get aImplementerDetail =>
      'En attendant, cette rubrique reste disponible sur le portail web.';

  @override
  String get chargement => 'Chargement…';

  @override
  String get reessayer => 'Réessayer';

  @override
  String get erreurInattendue => 'Une erreur inattendue est survenue.';

  @override
  String get notificationsToutes => 'Toutes';

  @override
  String get notificationsFiltreNonLues => 'Non lues';

  @override
  String get toutMarquerLu => 'Tout marquer comme lu';

  @override
  String get aucuneNotification => 'Aucune notification pour l\'instant.';

  @override
  String get aucuneNotificationNonLue => 'Vous avez tout lu.';

  @override
  String get marquerLue => 'Marquer comme lue';

  @override
  String get marquerNonLue => 'Marquer comme non lue';

  @override
  String get supprimer => 'Supprimer';

  @override
  String get notificationSupprimee => 'Notification supprimée.';

  @override
  String get ouvrir => 'Ouvrir';

  @override
  String get fermer => 'Fermer';

  @override
  String get emploiDuTemps => 'Emploi du temps';

  @override
  String get calendrier => 'Calendrier';

  @override
  String get parcours => 'Parcours';

  @override
  String get semainePrecedente => 'Semaine précédente';

  @override
  String get semaineSuivante => 'Semaine suivante';

  @override
  String get cetteSemaine => 'Cette semaine';

  @override
  String semaineDuAu(String debut, String fin) {
    return 'Du $debut au $fin';
  }

  @override
  String seancesDeLaSemaine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séances',
      one: '1 séance',
      zero: 'Aucune séance',
    );
    return '$_temp0';
  }

  @override
  String get aucuneSeanceSemaine => 'Aucune séance prévue cette semaine.';

  @override
  String get datesPassees => 'Dates passées';

  @override
  String get aucunEvenement => 'Aucune date publiée au calendrier.';

  @override
  String get aucunParcours => 'Aucune inscription enregistrée.';

  @override
  String get inscriptionCourante => 'En cours';

  @override
  String get inscriptionNonFinalisee => 'Inscription non finalisée';

  @override
  String get notesEnAttenteJury => 'En attente du jury';

  @override
  String get aucuneNote => 'Aucune note publiée pour cette année.';

  @override
  String get moyenne => 'Moyenne';

  @override
  String get credits => 'Crédits';

  @override
  String creditsDuCours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count crédits',
      one: '1 crédit',
    );
    return '$_temp0';
  }

  @override
  String get rang => 'Rang';

  @override
  String get resultatAnnuel => 'Résultat de l\'année';

  @override
  String resultatSession(String session) {
    return 'Résultat · $session';
  }

  @override
  String get sessionNormale => 'Session normale';

  @override
  String get sessionRattrapage => 'Rattrapage';

  @override
  String get coursARepasser => 'Cours à repasser';

  @override
  String get relevesDeNotes => 'Relevés de notes';

  @override
  String releveNumero(String numero) {
    return 'Relevé n° $numero';
  }

  @override
  String releveEmisLe(String version, String date) {
    return 'Version $version · émis le $date';
  }

  @override
  String get relevesAuGuichet =>
      'Les relevés se retirent auprès de la scolarité.';

  @override
  String get notesAvantJury =>
      'Les notes de cours s\'affichent une fois les résultats du jury publiés. En attendant, seules les épreuves validées par le service sont visibles.';

  @override
  String get anneeAcademique => 'Année académique';

  @override
  String get totalDu => 'Total dû';

  @override
  String get echeancier => 'Échéancier';

  @override
  String get aucuneTranche => 'Aucune échéance définie pour cette année.';

  @override
  String echeanceLe(String date) {
    return 'Échéance le $date';
  }

  @override
  String payeSur(String paye, String montant) {
    return '$paye payés sur $montant';
  }

  @override
  String get couverteParMoratoire => 'Couverte par un moratoire';

  @override
  String get paiements => 'Paiements';

  @override
  String get aucunPaiement => 'Aucun paiement enregistré pour cette année.';

  @override
  String get moratoiresAccordes => 'Moratoires accordés';

  @override
  String get demandeMoratoireEnCours =>
      'Demande de moratoire en cours d\'examen';

  @override
  String get telechargerRecu => 'Télécharger le reçu';

  @override
  String get telechargerReleve => 'Télécharger le relevé de compte';

  @override
  String get telechargementEnCours => 'Téléchargement…';

  @override
  String get ouvertureImpossible =>
      'Aucune application ne permet d\'ouvrir ce document.';

  @override
  String get aucuneSituation => 'Aucune situation financière pour cette année.';

  @override
  String get sectionScolarite => 'Ma scolarité';

  @override
  String get sectionNotes => 'Mes notes';

  @override
  String get sectionFinances => 'Ma situation financière';

  @override
  String get sectionDocuments => 'Mes documents';

  @override
  String get sectionExamens => 'Planning des examens';

  @override
  String get sectionSupports => 'Mes supports de cours';

  @override
  String get sectionDiscipline => 'Ma discipline';

  @override
  String get aucunDocumentDossier =>
      'Aucun document officiel dans votre dossier.';

  @override
  String get documentsAuGuichet =>
      'Les autres documents se retirent auprès de la scolarité.';

  @override
  String documentEtabliLe(String date) {
    return 'Établi le $date';
  }

  @override
  String documentRetireLe(String date) {
    return 'Retiré le $date';
  }

  @override
  String get telechargerCertificat => 'Télécharger le certificat';

  @override
  String get certificatIndisponible => 'Téléchargement indisponible';

  @override
  String get aucunPlanning =>
      'Aucun planning d\'examens publié pour votre classe.';

  @override
  String get planningEnCours => 'En cours';

  @override
  String get planningTermine => 'Terminé';

  @override
  String get planningAVenir => 'À venir';

  @override
  String nbEpreuves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count épreuves',
      one: '1 épreuve',
      zero: 'Aucune épreuve',
    );
    return '$_temp0';
  }

  @override
  String get telechargerPlanning => 'Télécharger le planning (PDF)';

  @override
  String get pause => 'Pause';

  @override
  String get epreuveConcernee => 'Vous composez';

  @override
  String get aucunSupport =>
      'Aucun plan ni support de cours publié pour l\'instant.';

  @override
  String supportsATelecharger(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents à télécharger',
      one: '1 document à télécharger',
      zero: 'Tout est téléchargé',
    );
    return '$_temp0';
  }

  @override
  String get nouvelleVersion => 'Nouvelle version';

  @override
  String get telecharge => 'Téléchargé';

  @override
  String telechargeLe(String date) {
    return 'Téléchargé le $date';
  }

  @override
  String get aTelecharger => 'À télécharger';

  @override
  String nbFichiers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers',
      one: '1 fichier',
    );
    return '$_temp0';
  }

  @override
  String publieLe(String date) {
    return 'Publié le $date';
  }

  @override
  String misAJourLe(String date) {
    return 'Mis à jour le $date';
  }

  @override
  String get telecharger => 'Télécharger';

  @override
  String get aucunDossierDiscipline =>
      'Aucun suivi d\'assiduité pour cette année.';

  @override
  String get tauxPresence => 'Taux de présence';

  @override
  String seancesPrevuesNombre(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séances prévues à ce jour',
      one: '1 séance prévue à ce jour',
      zero: 'Aucune séance prévue à ce jour',
    );
    return '$_temp0';
  }

  @override
  String seuilExamens(String seuil) {
    return 'Seuil d\'accès aux examens : $seuil';
  }

  @override
  String get absences => 'Absences';

  @override
  String get retards => 'Retards';

  @override
  String absencesNonJustifiees(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dont $count non justifiées',
      one: 'dont 1 non justifiée',
      zero: 'toutes justifiées',
    );
    return '$_temp0';
  }

  @override
  String retardsNonJustifies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dont $count non justifiés',
      one: 'dont 1 non justifié',
      zero: 'tous justifiés',
    );
    return '$_temp0';
  }

  @override
  String get assiduiteParException =>
      'Une partie de vos séances a été relevée par exception (seuls les manquements sont saisis) : le taux se lit avec prudence.';

  @override
  String get assiduiteParCours => 'Assiduité par cours';

  @override
  String absencesSurSeances(int absences, int seances) {
    String _temp0 = intl.Intl.pluralLogic(
      absences,
      locale: localeName,
      other: '$absences absences',
      one: '1 absence',
      zero: 'Aucune absence',
    );
    return '$_temp0 sur $seances';
  }

  @override
  String get absencesEtRetards => 'Absences et retards';

  @override
  String get aucunManquement =>
      'Aucune absence ni aucun retard relevé cette année.';

  @override
  String minutesDeRetard(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes de retard',
      one: '1 minute de retard',
    );
    return '$_temp0';
  }

  @override
  String justificatifAvant(String date) {
    return 'Justificatif à produire avant le $date';
  }

  @override
  String get sanctions => 'Sanctions';

  @override
  String aCompterDu(String date) {
    return 'À compter du $date';
  }

  @override
  String get tenueVestimentaire => 'Tenue vestimentaire';

  @override
  String aRegulariserAvant(String date) {
    return 'À régulariser avant le $date';
  }

  @override
  String get sectionMoratoires => 'Mes moratoires';

  @override
  String get sectionPermissions => 'Mes permissions';

  @override
  String get mesDemandes => 'Mes demandes';

  @override
  String get nouvelleDemande => 'Nouvelle demande';

  @override
  String get demandeMoratoire => 'Demande de moratoire';

  @override
  String get nouvelleDemandeMoratoire => 'Demander un moratoire';

  @override
  String get aucuneDemandeMoratoire =>
      'Vous n\'avez déposé aucune demande de moratoire.';

  @override
  String get montantDemandable => 'Montant qui peut encore être couvert';

  @override
  String get moratoireExplication =>
      'Un moratoire repousse le règlement d\'une partie de ce que vous devez. Votre demande ne change rien à votre situation tant que la scolarité ne l\'a pas acceptée.';

  @override
  String moratoireAttendreDecision(String reference) {
    return 'La demande $reference est en cours d\'examen : attendez la décision de la scolarité avant d\'en déposer une autre.';
  }

  @override
  String get moratoireRienACouvrir =>
      'Votre situation ne laisse aucun montant à couvrir : une demande de moratoire est sans objet pour cette année.';

  @override
  String get moratoireSansAnnee =>
      'Aucune année académique n\'est ouverte : rapprochez-vous de la scolarité.';

  @override
  String get montantSollicite => 'Montant sollicité';

  @override
  String auPlus(String montant) {
    return 'Au plus $montant';
  }

  @override
  String get tout => 'Tout';

  @override
  String get montantInvalide => 'Indiquez un montant supérieur à zéro.';

  @override
  String get dateReglementSouhaitee => 'Date de règlement souhaitée';

  @override
  String get dateRequise => 'Choisissez une date.';

  @override
  String reglementSouhaiteLe(String date) {
    return 'Règlement souhaité le $date';
  }

  @override
  String get motifDeLaDemande => 'Motif de la demande';

  @override
  String get motifMoratoireAide =>
      'Expliquez votre situation (retard de bourse, difficulté familiale…)';

  @override
  String get motifRequis => 'Expliquez votre demande.';

  @override
  String get pieceJustificativeFacultative =>
      'Pièce justificative (facultative)';

  @override
  String get pieceJustificativeObligatoire =>
      'Pièce justificative (obligatoire pour une absence)';

  @override
  String get formatsPieces => 'PDF ou photo (JPG, PNG), 5 Mo au plus.';

  @override
  String get choisirFichier => 'Choisir un fichier';

  @override
  String get remplacerFichier => 'Remplacer';

  @override
  String get retirerFichier => 'Retirer le fichier';

  @override
  String get pieceTropLourde =>
      'Ce fichier dépasse 5 Mo : choisissez-en un plus léger.';

  @override
  String get pieceJointeFournie => 'Pièce justificative jointe';

  @override
  String get envoyerDemande => 'Envoyer la demande';

  @override
  String envoyerDemandeSeances(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Envoyer la demande ($n séances)',
      one: 'Envoyer la demande (1 séance)',
    );
    return '$_temp0';
  }

  @override
  String deposeeLe(String date) {
    return 'Déposée le $date';
  }

  @override
  String get reponseDuService => 'Réponse du service';

  @override
  String reponseDuServiceLe(String date) {
    return 'Réponse du service, le $date';
  }

  @override
  String get retirerDemande => 'Retirer la demande';

  @override
  String get retirer => 'Retirer';

  @override
  String retirerMoratoireConfirmation(String reference) {
    return 'La demande $reference sera retirée : la scolarité ne l\'examinera pas. Vous pourrez en déposer une autre.';
  }

  @override
  String get retirerPermissionConfirmation =>
      'La demande sera retirée : le service ne l\'examinera pas. Vous pourrez en déposer une autre.';

  @override
  String get demanderPermission => 'Demander une permission';

  @override
  String get depotPermissionsFerme =>
      'Le dépôt des demandes de permission est fermé par le service.';

  @override
  String get permissionExplication =>
      'Annoncez ici une absence ou un retard, séance par séance. Votre demande ne vous décharge de rien tant que le service ne l\'a pas accordée.';

  @override
  String get aucuneDemandePermission =>
      'Vous n\'avez déposé aucune demande de permission.';

  @override
  String nbEnAttente(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n en attente',
      one: '1 en attente',
    );
    return '$_temp0';
  }

  @override
  String permissionDe(String type) {
    return 'Permission : $type';
  }

  @override
  String get saisieAuBureau => 'Saisie au bureau du service';

  @override
  String arriveeAnnoncee(String heure) {
    return 'Arrivée annoncée à $heure';
  }

  @override
  String get objetDeLaDemande => 'Objet de la demande';

  @override
  String get absence => 'Absence';

  @override
  String get retard => 'Retard';

  @override
  String get seancesConcernees => 'Séances concernées';

  @override
  String get jourChome => 'Jour sans cours';

  @override
  String get dejaAccordee => 'Déjà accordée';

  @override
  String preavisPermission(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Déposez votre demande au moins $n heures avant la séance. Une demande tardive reste possible : le service le verra.',
      one:
          'Déposez votre demande au moins 1 heure avant la séance. Une demande tardive reste possible : le service le verra.',
    );
    return '$_temp0';
  }

  @override
  String get heureArriveeAnnoncee => 'Heure d\'arrivée annoncée';

  @override
  String get heureArriveeRequise =>
      'Annoncez l\'heure à laquelle vous comptez arriver.';

  @override
  String get motif => 'Motif';

  @override
  String get motifNonListe => '— Motif non listé —';

  @override
  String get explication => 'Explication';

  @override
  String get explicationPermissionAide =>
      'Dites en quelques lignes ce qui vous empêche d\'être là.';

  @override
  String get explicationRequise =>
      'Expliquez votre demande : c\'est sur cette explication que le service se prononce.';

  @override
  String get demandesDeMoratoire => 'Demandes de moratoire';

  @override
  String get sectionMessages => 'Mes messages';

  @override
  String get sectionSuggestions => 'Boîte à suggestions';

  @override
  String get repondre => 'Répondre';

  @override
  String get jaime => 'J\'aime';

  @override
  String get jaimePas => 'Je n\'aime pas';

  @override
  String get retirerJaime => 'Retirer « J\'aime »';

  @override
  String get retirerJaimePas => 'Retirer « Je n\'aime pas »';

  @override
  String get copier => 'Copier le texte';

  @override
  String get serviceEnLigne => 'Un agent est en ligne';

  @override
  String get serviceHorsLigne => 'Aucun agent en ligne';

  @override
  String get filVide =>
      'Écrivez à la scolarité : votre question arrive au guichet, et l\'agent qui la prend vous répond ici.';

  @override
  String get messagesPlusAnciens => 'Messages plus anciens';

  @override
  String get envoye => 'Envoyé';

  @override
  String get luParLeService => 'Lu par le service';

  @override
  String reponseA(String auteur) {
    return 'En réponse à $auteur';
  }

  @override
  String get joindreFichier => 'Joindre un fichier';

  @override
  String get ecrireMessage => 'Votre message…';

  @override
  String get envoyer => 'Envoyer';

  @override
  String get ajouterFichiers => 'Ajouter des fichiers';

  @override
  String piecesAuPlus(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n fichiers au plus.',
      one: 'Un fichier au plus.',
    );
    return '$_temp0';
  }

  @override
  String get nouvelleSuggestion => 'Nouvelle suggestion';

  @override
  String get mesSuggestions => 'Mes suggestions';

  @override
  String get aucuneSuggestion => 'Vous n\'avez déposé aucune suggestion.';

  @override
  String get suggestionAnonyme => 'Anonyme pour le service';

  @override
  String get suggestionExplication =>
      'Vous suivez ici l\'état de vos suggestions ; la suite donnée reste interne au service.';

  @override
  String get solutionProposee => 'Solution proposée';

  @override
  String nbPreuves(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n preuves jointes',
      one: '1 preuve jointe',
    );
    return '$_temp0';
  }

  @override
  String get votreSuggestion => 'Votre suggestion';

  @override
  String get votreSuggestionAide =>
      'Ce que vous proposez d\'améliorer, et pourquoi.';

  @override
  String get suggestionRequise => 'Écrivez votre suggestion.';

  @override
  String get solutionProposeeAide =>
      'Comment y remédier concrètement, selon vous.';

  @override
  String get solutionRequise => 'Indiquez la solution que vous proposez.';

  @override
  String get preuvesFacultatives => 'Preuves (facultatives)';

  @override
  String get deposerSuggestion => 'Déposer la suggestion';

  @override
  String get sectionReinscription => 'Ma réinscription';

  @override
  String get inscriptionPrononcee => 'Inscription prononcée';

  @override
  String get reinscriptionAFaire => 'Réinscription à demander';

  @override
  String get reinscriptionIndisponible => 'Réinscription en ligne indisponible';

  @override
  String get programme => 'Programme';

  @override
  String get niveauEtSpecialite => 'Niveau et spécialité';

  @override
  String demandeeLe(String date) {
    return 'Demandée le $date';
  }

  @override
  String parDemandeur(String nom) {
    return 'par $nom';
  }

  @override
  String get reinscriptionAttentePaiement =>
      'Votre réinscription sera prononcée dès que la première tranche sera soldée (ou couverte par un moratoire accordé).';

  @override
  String get choisirSpecialite => 'Choisissez votre spécialité.';

  @override
  String get modifierMaDemande => 'Modifier ma demande';

  @override
  String get demanderReinscription => 'Demander ma réinscription';

  @override
  String get niveauSelonJury =>
      'Votre niveau est fixé par la décision du jury.';

  @override
  String niveauSelonDecision(String decision) {
    return 'Décision du jury : $decision. Votre niveau en découle.';
  }

  @override
  String get niveau => 'Niveau';

  @override
  String get specialite => 'Spécialité';

  @override
  String get reinscriptionModifiable =>
      'Niveau et spécialité restent modifiables tant qu\'aucun versement n\'est déclaré ni enregistré.';

  @override
  String get enregistrerModification => 'Enregistrer la modification';

  @override
  String get premiereTranche => 'Première tranche';

  @override
  String get trancheCouverte => 'Couverte';

  @override
  String get trancheNonConfiguree =>
      'L\'échéancier de votre niveau n\'est pas encore publié : rapprochez-vous de la caisse.';

  @override
  String get montantDu => 'Montant';

  @override
  String get dejaPaye => 'Déjà payé';

  @override
  String get declarerUnVersement => 'Déclarer un versement';

  @override
  String get trancheACaisse =>
      'La déclaration en ligne n\'est pas ouverte : la tranche se règle à la caisse, et la réinscription est prononcée à l\'encaissement.';

  @override
  String get versementsDeclares => 'Versements déclarés';

  @override
  String get versementsFermes =>
      'La déclaration des versements en ligne n\'est pas ouverte.';

  @override
  String get versementExplication =>
      'Versez à la banque sur l\'un des comptes ci-dessous, puis déclarez le versement avec le reçu. Il ne compte qu\'une fois vérifié par le service des paiements sur le relevé de la banque.';

  @override
  String get mesDeclarations => 'Mes déclarations';

  @override
  String get aucuneDeclaration => 'Aucun versement déclaré pour cette année.';

  @override
  String get resteADeclarer => 'Reste à déclarer';

  @override
  String get enVerification => 'En vérification';

  @override
  String get copierNumero => 'Copier le numéro de compte';

  @override
  String get numeroCopie => 'Numéro de compte copié.';

  @override
  String get retirerDeclaration => 'Retirer la déclaration';

  @override
  String retirerDeclarationConfirmation(String reference) {
    return 'La déclaration $reference sera retirée : le service ne la vérifiera pas.';
  }

  @override
  String montantRetenu(String montant) {
    return 'Montant retenu au relevé : $montant';
  }

  @override
  String verseLe(String date) {
    return 'Versé le $date';
  }

  @override
  String trancheVisee(String tranche) {
    return 'Tranche : $tranche';
  }

  @override
  String declarePar(String nom, String espace) {
    return 'Déclaré par $nom ($espace)';
  }

  @override
  String get motifDuRejet => 'Motif du rejet';

  @override
  String get recuDeLaBanque => 'Reçu de la banque';

  @override
  String get recuDePaiement => 'Reçu de paiement';

  @override
  String get compteCredite => 'Compte crédité';

  @override
  String get choisirCompte =>
      'Choisissez le compte sur lequel vous avez versé.';

  @override
  String get trancheReglee => 'Tranche réglée';

  @override
  String get repartirSurTranches => 'Répartir sur les tranches dans leur ordre';

  @override
  String trancheReste(String tranche, String reste) {
    return '$tranche — reste $reste';
  }

  @override
  String get montantVerse => 'Montant versé';

  @override
  String get laTranche => 'La tranche';

  @override
  String get dateDuVersement => 'Date du versement';

  @override
  String get referenceOperation => 'Référence de l\'opération';

  @override
  String get referenceOperationAide =>
      'N° de bordereau ou référence du virement';

  @override
  String get referenceRequise => 'Indiquez la référence portée sur le reçu.';

  @override
  String get recuRequis => 'Joignez le reçu de la banque.';

  @override
  String get formatsRecu =>
      'PDF ou photo (JPG, PNG, WEBP, HEIC), 5 Mo au plus.';

  @override
  String get commentaireFacultatif => 'Commentaire (facultatif)';

  @override
  String get declarerLeVersement => 'Déclarer le versement';

  @override
  String couverteParMoratoireRef(String reference) {
    return 'Couverte par le moratoire $reference';
  }

  @override
  String get sectionDiscussions => 'Discussions de classe';

  @override
  String get discussionVide =>
      'Aucun message dans cette discussion. Le premier lance le groupe de la classe.';

  @override
  String get discussionLectureSeule =>
      'Discussion passée : vous ne faites plus partie de cette classe. Elle se relit, elle ne s\'écrit plus.';

  @override
  String get enseignantEnLigne => 'enseignant en ligne';

  @override
  String get enseignantHorsLigne => 'enseignant hors ligne';

  @override
  String get rechercherClasse => 'Rechercher un cours, une classe…';

  @override
  String get aucuneDiscussion =>
      'Aucune classe ne vous est rattachée pour l\'instant : les discussions s\'ouvrent avec les emplois du temps publiés.';

  @override
  String get discussionsPassees => 'Discussions passées';

  @override
  String get discussionsPasseesAide =>
      'Classes que vous avez quittées : en lecture seule.';

  @override
  String get aucunMessagePourLInstant => 'Aucun message pour l\'instant';

  @override
  String get sectionBibliotheque => 'Bibliothèque universitaire';

  @override
  String get rechercherBibliotheque => 'Titre, auteur, sujet…';

  @override
  String get effacer => 'Effacer';

  @override
  String nbResultats(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n résultats',
      one: '1 résultat',
      zero: 'Aucun résultat',
    );
    return '$_temp0';
  }

  @override
  String get aucunResultat => 'Aucun document ne correspond à votre recherche.';

  @override
  String get dossierVide => 'Ce dossier est vide.';

  @override
  String get afficherPlus => 'Afficher plus';

  @override
  String nbDossiers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dossiers',
      one: '1 dossier',
    );
    return '$_temp0';
  }

  @override
  String ajouteLe(String date) {
    return 'ajouté le $date';
  }

  @override
  String get sectionArchives => 'Archives';

  @override
  String get anciennesEpreuves => 'Anciennes épreuves';

  @override
  String get supportsPasses => 'Supports passés';

  @override
  String get toutesLesAnnees => 'Toutes les années';

  @override
  String get aucuneAnnale =>
      'Aucune ancienne épreuve publiée pour votre classe.';

  @override
  String get aucunSupportArchive =>
      'Aucun support des années passées pour votre classe.';

  @override
  String get annalesExplication =>
      'Le sujet seul est remis, jamais le corrigé.';

  @override
  String dureeMinutes(int n) {
    return '$n min';
  }

  @override
  String get telechargerSujet => 'Télécharger le sujet';

  @override
  String get nonPublie => 'Non publié';

  @override
  String get sectionPromotion => 'Ma promotion';

  @override
  String get aucunePromotion =>
      'Aucun résultat arrêté pour votre promotion pour l\'instant.';

  @override
  String get majorsDeLAnnee => 'Majors de l\'année';

  @override
  String get majorsDesAnneesPassees => 'Majors des années passées';

  @override
  String get effectifInsuffisant => 'Effectif insuffisant';

  @override
  String plancherEffectif(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Une moyenne de classe n’est montrée qu’à partir de $n étudiants, pour ne désigner personne.',
      one: 'Une moyenne de classe n’est montrée qu’à partir de 1 étudiant.',
    );
    return '$_temp0';
  }

  @override
  String nbEtudiants(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n étudiants',
      one: '1 étudiant',
    );
    return '$_temp0';
  }

  @override
  String get premierePlacePartagee => 'Première place partagée.';

  @override
  String get sectionAssociation => 'Association des étudiants';

  @override
  String get sectionAssociationHistorique => 'Listes élues';

  @override
  String get aucuneCampagne => 'Aucune campagne électorale n\'est ouverte.';

  @override
  String get resultats => 'Résultats';

  @override
  String get depouillement => 'Dépouillement';

  @override
  String get enDirect => 'En direct';

  @override
  String participation(String taux, int votants, int inscrits) {
    return 'Participation : $taux % ($votants votants sur $inscrits inscrits)';
  }

  @override
  String get elu => 'Élue';

  @override
  String nbVoix(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n voix',
      one: '1 voix',
      zero: '0 voix',
    );
    return '$_temp0';
  }

  @override
  String get ballottage =>
      'Égalité en tête : aucune liste n\'est élue. C\'est à l\'établissement de trancher.';

  @override
  String get aucunSuffrage => 'Aucun suffrage pour le moment.';

  @override
  String candidat(String nom) {
    return 'Candidat : $nom';
  }

  @override
  String get lireLeProgramme => 'Lire le programme';

  @override
  String get programmeDeLaListe => 'Programme';

  @override
  String get programmeNonRedige =>
      'Le programme de cette liste n\'a pas été rédigé.';

  @override
  String get equipe => 'Équipe';

  @override
  String get scrutinAnnule => 'Scrutin annulé';

  @override
  String get urnesOuvertes => 'Urnes ouvertes';

  @override
  String get voteTermine => 'Vote terminé';

  @override
  String get urnesAVenir => 'Vote à venir';

  @override
  String get vousAvezVote => 'Vous avez voté';

  @override
  String get voteAnonyme =>
      'Le vote est anonyme : le système sait que vous avez voté, jamais pour qui.';

  @override
  String get listesCandidates => 'Listes candidates';

  @override
  String get votreBulletin => 'Votre bulletin';

  @override
  String get confirmerVote => 'Confirmer votre vote';

  @override
  String confirmerVoteTexte(String liste) {
    return 'Vous votez pour « $liste ». Un vote ne se reprend pas.';
  }

  @override
  String get voter => 'Voter';

  @override
  String get validerMonVote => 'Valider mon vote';

  @override
  String get aucunScrutinPasse => 'Aucun scrutin n\'est encore terminé.';

  @override
  String presidentElu(String nom) {
    return 'Président élu : $nom';
  }

  @override
  String get sectionDelegation => 'Ma délégation';

  @override
  String get aucuneSeanceCeJour => 'Aucune séance de votre classe ce jour-là.';

  @override
  String get circuitService => 'validé par le service';

  @override
  String get circuitEnseignant => 'signé par l\'enseignant';

  @override
  String get circuitEnseignantService =>
      'signé par l\'enseignant puis validé par le service';

  @override
  String get circuitAutomatique => 'validé d’office';

  @override
  String circuitDeLAppel(String circuit) {
    return 'Appel : $circuit.';
  }

  @override
  String circuitDuCahier(String circuit) {
    return 'Cahier de texte : $circuit.';
  }

  @override
  String get appelNonAutorise =>
      'L\'appel ne vous est pas ouvert : votre délégué principal ou le service peut l\'ouvrir.';

  @override
  String get positionExigee =>
      'L\'établissement exige votre position au moment d\'enregistrer : faites-le depuis la salle.';

  @override
  String get jourPrecedent => 'Jour précédent';

  @override
  String get jourSuivant => 'Jour suivant';

  @override
  String get aujourdhui => 'Aujourd\'hui';

  @override
  String get aFaire => 'À faire';

  @override
  String get renvoyeAuDelegue => 'À corriger';

  @override
  String get signeParEnseignant => 'Signé par l\'enseignant';

  @override
  String get valideParService => 'Validé par le service';

  @override
  String get fenetreAVenir => 'Pas encore ouvert';

  @override
  String get fenetreFermee => 'Fenêtre fermée';

  @override
  String get coursNonTenu => 'Cours relevé non tenu';

  @override
  String get horsPlanning => 'Hors planning';

  @override
  String fenetreDeA(String debut, String fin) {
    return 'Ouvert de $debut à $fin';
  }

  @override
  String get faire => 'Faire';

  @override
  String get corriger => 'Corriger';

  @override
  String get rouvertParLeService => 'Rouvert par le service';

  @override
  String get motifDuRenvoi => 'Motif du renvoi';

  @override
  String get appel => 'Appel';

  @override
  String get cahierDeTexte => 'Cahier de texte';

  @override
  String get seancesRouvertes => 'Séances rouvertes par le service';

  @override
  String jusquAu(String date) {
    return 'jusqu\'au $date';
  }

  @override
  String get mesAssistants => 'Mes assistants';

  @override
  String get assistantsAide =>
      'Vous décidez lesquels de vos assistants peuvent faire l\'appel à votre place.';

  @override
  String get releveDePosition => 'Relevé de votre position…';

  @override
  String get positionIndisponible => 'Position indisponible';

  @override
  String get positionServiceDesactive =>
      'La localisation du téléphone est désactivée : activez-la, puis réessayez.';

  @override
  String get positionRefusee =>
      'L\'application n\'a pas l\'autorisation de lire votre position : acceptez la demande, puis réessayez.';

  @override
  String get positionRefuseeReglages =>
      'L\'accès à la position est refusé : autorisez-le pour YSEM dans les réglages du téléphone.';

  @override
  String get positionDelai =>
      'La position n\'a pas pu être relevée à temps : placez-vous près d\'une fenêtre et réessayez.';

  @override
  String get compris => 'Compris';

  @override
  String get enregistrerLAppel => 'Enregistrer l\'appel';

  @override
  String confirmerAppel(int absents, int effectif) {
    String _temp0 = intl.Intl.pluralLogic(
      absents,
      locale: localeName,
      other: '$absents absents sur $effectif étudiants.',
      one: '1 absent sur $effectif étudiants.',
      zero: 'Aucun absent sur $effectif étudiants.',
    );
    return '$_temp0 Confirmer ?';
  }

  @override
  String get appelDeLaSeance => 'Appel de la séance';

  @override
  String get appelExplication =>
      'Cochez seulement les absents : les autres sont comptés présents. Une ligne verrouillée est couverte par une permission accordée.';

  @override
  String couvertParPermission(String type) {
    return 'Permission accordée ($type)';
  }

  @override
  String nbAbsentsSur(int absents, int effectif) {
    String _temp0 = intl.Intl.pluralLogic(
      absents,
      locale: localeName,
      other: '$absents absents',
      one: '1 absent',
      zero: '0 absent',
    );
    return '$_temp0 / $effectif';
  }

  @override
  String get contenuPrevu => 'Contenu prévu au plan';

  @override
  String get aucunPlanDeCours =>
      'Aucun plan de cours n\'est rattaché à cette séance.';

  @override
  String get contenuFait => 'Contenu fait';

  @override
  String blocN(int n) {
    return 'Bloc $n';
  }

  @override
  String seanceNumero(int n) {
    return 'Séance $n';
  }

  @override
  String get ajouterUneSeanceFaite => 'Ajouter une séance faite';

  @override
  String get blocsAide =>
      'Une séance double couvre souvent deux séances du plan : ajoutez un bloc par séance faite.';

  @override
  String get activitesPedagogiques => 'Activités pédagogiques';

  @override
  String get nonRenseigne => 'Non renseigné';

  @override
  String get enregistrerLeCahier => 'Enregistrer le cahier de texte';

  @override
  String get connexionEnseignantConsigne =>
      'Connectez-vous avec l\'adresse e-mail et le mot de passe du portail enseignant.';

  @override
  String get connexionEnseignantAide =>
      'Pas encore de compte ou compte non activé ? L\'inscription et l\'activation se font sur le portail enseignant web.';

  @override
  String get emailInvalide => 'Adresse e-mail invalide.';

  @override
  String get motDePasseOublie => 'Mot de passe oublié ?';

  @override
  String get motDePasseOublieConsigne =>
      'Saisissez l\'adresse de votre compte : un lien vous sera envoyé pour choisir un nouveau mot de passe sur le portail web.';

  @override
  String get envoyerLeLien => 'Envoyer le lien';

  @override
  String get maCandidature => 'Ma candidature';

  @override
  String get candidatureSoumise => 'Soumise';

  @override
  String candidatureEtape(int etape, int etapes) {
    return 'Étape $etape sur $etapes';
  }

  @override
  String candidatureSoumiseLe(String date) {
    return 'Candidature soumise le $date. L\'établissement l\'examine.';
  }

  @override
  String candidatureAPoursuivre(int etape) {
    return 'Votre dossier de candidature est à poursuivre à l\'étape $etape.';
  }

  @override
  String get candidatureSurLeWeb =>
      'Le dossier de candidature se remplit sur le portail enseignant web.';

  @override
  String get candidatureAcceptee => 'Candidature acceptée';

  @override
  String get candidatureAccepteeTexte =>
      'Bienvenue dans le corps enseignant ! Vos services sont désormais ouverts dans l\'application.';

  @override
  String get motifDuRefus => 'Motif du refus';

  @override
  String get rienEnAttente =>
      'Rien n\'attend votre intervention pour l\'instant.';

  @override
  String fichesASignerNombre(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre fiches du délégué à signer',
      one: '1 fiche du délégué à signer',
    );
    return '$_temp0';
  }

  @override
  String rattrapagesOuvertsNombre(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre rattrapages dus',
      one: '1 rattrapage dû',
    );
    return '$_temp0';
  }

  @override
  String fichesATransmettreNombre(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre fiches d\'émargement à transmettre',
      one: '1 fiche d\'émargement à transmettre',
    );
    return '$_temp0';
  }

  @override
  String messagesNonLusNombre(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre messages non lus dans vos classes',
      one: '1 message non lu dans vos classes',
    );
    return '$_temp0';
  }

  @override
  String get monDossier => 'Mon dossier';

  @override
  String get monDossierAide =>
      'État civil, cursus, expériences et validations du service.';

  @override
  String get profilProfessionnel => 'Profil';

  @override
  String get dernierDiplome => 'Dernier diplôme obtenu';

  @override
  String get dateRecrutement => 'Date de recrutement';

  @override
  String get permanent => 'Permanent';

  @override
  String get vacataire => 'Vacataire';

  @override
  String get dossierIncomplet => 'Votre dossier est incomplet';

  @override
  String get dossierModifierSurLeWeb =>
      'Pour modifier votre dossier, utilisez « Mon dossier » sur le portail enseignant web. Le grade, les domaines et les cours sont fixés par le service.';

  @override
  String get etatCivil => 'État civil';

  @override
  String get nationalite => 'Nationalité';

  @override
  String get regionOrigine => 'Région d\'origine';

  @override
  String get situationMatrimoniale => 'Situation matrimoniale';

  @override
  String enfantsACharge(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre enfants à charge',
      one: '1 enfant à charge',
    );
    return '$_temp0';
  }

  @override
  String get cni => 'Carte nationale d\'identité';

  @override
  String get niu => 'Numéro d\'identifiant unique (NIU)';

  @override
  String get universiteRattachement => 'Université de rattachement';

  @override
  String get cv => 'Curriculum vitæ';

  @override
  String get depose => 'Déposé';

  @override
  String get nonDepose => 'Non déposé';

  @override
  String get coordonnees => 'Coordonnées';

  @override
  String get adresse => 'Adresse';

  @override
  String get contactUrgence => 'Contact d\'urgence';

  @override
  String get cursusEtCertifications => 'Cursus et certifications';

  @override
  String get aucunDiplome => 'Aucun diplôme renseigné.';

  @override
  String get justificatifDepose => 'Justificatif déposé';

  @override
  String get certifications => 'Certifications';

  @override
  String get experiencesEnseignement => 'Expériences dans l\'enseignement';

  @override
  String get experiencesEntreprise => 'Expériences en entreprise';

  @override
  String get aucuneExperience => 'Aucune expérience renseignée.';

  @override
  String nombreAnnees(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre ans',
      one: '1 an',
    );
    return '$_temp0';
  }

  @override
  String nombreMois(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre mois',
    );
    return '$_temp0';
  }

  @override
  String get domainesEnseignement => 'Domaines d\'enseignement';

  @override
  String get coursProposes => 'Cours proposés';

  @override
  String get aucunElement => 'Aucun élément.';

  @override
  String get sectionFichesASigner => 'Fiches à signer';

  @override
  String get sectionRattrapages => 'Mes rattrapages';

  @override
  String get sectionClasses => 'Mes classes';

  @override
  String get fichesASignerExplication =>
      'Les appels et cahiers de texte saisis par les délégués attendent votre signature. Signer vaut validation ; renvoyez au délégué ce qui est à corriger, en disant pourquoi.';

  @override
  String get aucuneFicheASigner => 'Aucune fiche n\'attend votre signature.';

  @override
  String signerToutesLesFiches(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: 'Signer les $nombre fiches',
      one: 'Signer la fiche',
    );
    return '$_temp0';
  }

  @override
  String get signerToutConfirmation =>
      'Chaque fiche signée est validée, ou part à la validation du service selon le circuit de l\'année.';

  @override
  String get signer => 'Signer';

  @override
  String get renvoyer => 'Renvoyer';

  @override
  String get renvoyerAuDelegue => 'Renvoyer au délégué';

  @override
  String get renvoyerAuDelegueAide =>
      'Dites au délégué ce qu\'il doit corriger : il en est informé et peut reprendre sa fiche.';

  @override
  String get dernieresFiches => 'Dernières fiches traitées';

  @override
  String get ficheAppel => 'Appel du délégué';

  @override
  String get ficheCahierDeTexte => 'Cahier de texte';

  @override
  String saisiPar(String nom) {
    return 'Saisi par $nom';
  }

  @override
  String get enAttenteValidationService =>
      'Signée — en attente de la validation du service.';

  @override
  String nbAbsents(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre absents',
      one: '1 absent',
      zero: 'Aucun absent',
    );
    return '$_temp0';
  }

  @override
  String get cahierSansContenu => 'Aucun contenu consigné.';

  @override
  String get rattrapagesExplication =>
      'Proposez une date pour une séance à rattraper : elle n\'est annoncée aux étudiants qu\'une fois approuvée par le service. Une séance déjà programmée se déplace par le service.';

  @override
  String get aucunRattrapage => 'Aucune séance à rattraper.';

  @override
  String get rattrapagesClos => 'Rattrapages clos';

  @override
  String seanceDuJour(String date) {
    return 'Séance du $date';
  }

  @override
  String aRattraperAvant(String date) {
    return 'À rattraper avant le $date';
  }

  @override
  String get dateEnAttenteArbitrage =>
      'Date proposée, en attente de l\'approbation du service.';

  @override
  String rattrapeLe(String date) {
    return 'Rattrapé le $date';
  }

  @override
  String get dateRefusee => 'Date refusée';

  @override
  String get proposerUneDate => 'Proposer une date';

  @override
  String get propositionAide =>
      'La date reste une proposition tant que le service ne l\'a pas approuvée.';

  @override
  String get dateProposee => 'Date proposée';

  @override
  String get creneau => 'Créneau';

  @override
  String get salleFacultative => 'Salle (facultative)';

  @override
  String get aucuneSalle => 'Aucune salle précise';

  @override
  String get transmettreAuService => 'Transmettre au service';

  @override
  String get aucuneClasse =>
      'Aucune classe ne vous est attribuée dans les emplois du temps publiés.';

  @override
  String nbClasses(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre classes',
      one: '1 classe',
    );
    return '$_temp0';
  }

  @override
  String nbCours(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre cours',
      one: '1 cours',
    );
    return '$_temp0';
  }

  @override
  String nbSansDelegue(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre classes sans délégué',
      one: '1 classe sans délégué',
    );
    return '$_temp0';
  }

  @override
  String get sansDeleguePrincipal => 'Pas de délégué principal';

  @override
  String deleguePrincipal(String noms) {
    return 'Délégué : $noms';
  }

  @override
  String get exporterLaListe => 'Exporter la liste (Excel)';

  @override
  String get listeDesInscrits => 'Liste des inscrits';

  @override
  String get rechercherEtudiant => 'Nom ou matricule';

  @override
  String get aucunInscrit => 'Aucun inscrit dans cette classe.';

  @override
  String get aucunEtudiantTrouve =>
      'Aucun étudiant ne correspond à votre recherche.';

  @override
  String get inscrits => 'Inscrits';

  @override
  String get femmesHommes => 'Femmes / hommes';

  @override
  String get seancesRelevees => 'Séances relevées';

  @override
  String get etudiantsAbsents => 'Avec absence';

  @override
  String planDeCoursStatut(String statut) {
    return 'Plan de cours : $statut';
  }

  @override
  String get deleguesDeLaClasse => 'Délégués de la classe';

  @override
  String get aucunDelegue => 'Aucun délégué nommé pour cette classe.';

  @override
  String nbAbsences(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre absences',
      one: '1 absence',
    );
    return '$_temp0';
  }

  @override
  String nbRetards(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre retards',
      one: '1 retard',
    );
    return '$_temp0';
  }

  @override
  String nbNonJustifiees(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre non justifiées',
      one: '1 non justifiée',
    );
    return '$_temp0';
  }

  @override
  String get delegue => 'Délégué';
}
