// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'YSEM';

  @override
  String get bienvenue => 'Welcome to YSEM';

  @override
  String get choisirEspace => 'Choose your space to continue.';

  @override
  String get espaceEtudiant => 'Student space';

  @override
  String get espaceEtudiantDescription =>
      'Timetable, grades, finances and documents.';

  @override
  String get espaceEnseignant => 'Lecturer space';

  @override
  String get espaceEnseignantDescription =>
      'Courses, sessions, grades and fees.';

  @override
  String get bientotDisponible => 'Coming soon';

  @override
  String get connexion => 'Sign in';

  @override
  String get seConnecter => 'Sign in';

  @override
  String get deconnexion => 'Sign out';

  @override
  String get deconnexionConfirmation =>
      'You will need to enter your registration number and password again to come back.';

  @override
  String get connexionEtudiantConsigne =>
      'Sign in with your registration number and student portal password.';

  @override
  String get connexionAide =>
      'Forgotten password or access not set up? Please contact the registrar\'s office.';

  @override
  String get matricule => 'Registration number';

  @override
  String get motDePasse => 'Password';

  @override
  String get afficher => 'Show';

  @override
  String get masquer => 'Hide';

  @override
  String get champObligatoire => 'This field is required.';

  @override
  String get verificationTitre => 'Verification';

  @override
  String get verificationConsigne =>
      'Enter the six-digit code you received by email.';

  @override
  String verificationConsigneAdresse(String adresse) {
    return 'Enter the six-digit code sent to $adresse.';
  }

  @override
  String get verificationAide => 'Remember to check your spam folder.';

  @override
  String get codeVerification => 'Verification code';

  @override
  String codeExpireDans(String duree) {
    return 'The code expires in $duree';
  }

  @override
  String get codeExpire => 'The code has expired: request a new one.';

  @override
  String get verifier => 'Verify';

  @override
  String get renvoyerCode => 'Resend the code';

  @override
  String tentativesRestantes(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre attempts left.',
      one: '1 attempt left.',
    );
    return '$_temp0';
  }

  @override
  String get changerMotDePasse => 'Change password';

  @override
  String get motDePasseImposeConsigne =>
      'For your security, choose a new password before continuing.';

  @override
  String get motDePasseVolontaireConsigne =>
      'The new password also applies to the web portal.';

  @override
  String get motDePasseActuel => 'Current password';

  @override
  String get nouveauMotDePasse => 'New password';

  @override
  String get confirmationMotDePasse => 'Confirm the new password';

  @override
  String get confirmationDifferente => 'The two passwords do not match.';

  @override
  String get enregistrer => 'Save';

  @override
  String get annuler => 'Cancel';

  @override
  String get confirmer => 'Confirm';

  @override
  String get ongletAccueil => 'Home';

  @override
  String get ongletServices => 'Services';

  @override
  String get ongletNotifications => 'Notifications';

  @override
  String get ongletProfil => 'Profile';

  @override
  String bonjour(String nom) {
    return 'Hello, $nom';
  }

  @override
  String get situationFinanciere => 'Financial standing';

  @override
  String get montantPaye => 'Paid';

  @override
  String get resteAPayer => 'Balance due';

  @override
  String get montantEchu => 'Overdue';

  @override
  String get prochainesSeances => 'Upcoming sessions';

  @override
  String get aucuneSeance => 'No upcoming sessions this week.';

  @override
  String get datesAVenir => 'Upcoming dates';

  @override
  String get aucuneDate => 'No dates announced in the calendar.';

  @override
  String get documentsRecents => 'Recent documents';

  @override
  String get aucunDocument => 'No documents yet.';

  @override
  String get toutVoir => 'See all';

  @override
  String get seanceAnnulee => 'Cancelled';

  @override
  String get seanceChomee => 'Day off';

  @override
  String get seanceRattrapage => 'Make-up session';

  @override
  String get seanceTroncCommun => 'Joint session';

  @override
  String notificationsNonLues(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre unread notifications',
      one: '1 unread notification',
    );
    return '$_temp0';
  }

  @override
  String get informations => 'Information';

  @override
  String get aucuneInformation => 'No information on file.';

  @override
  String get email => 'Email address';

  @override
  String get telephone => 'Phone';

  @override
  String get dateNaissance => 'Date of birth';

  @override
  String get genre => 'Gender';

  @override
  String get residence => 'Residence';

  @override
  String get statut => 'Status';

  @override
  String get securite => 'Account security';

  @override
  String get doubleAuthentification => 'Two-factor authentication';

  @override
  String get doubleAuthentificationAide =>
      'A code sent by email is required at each sign-in.';

  @override
  String get activerDoubleAuthentification =>
      'Turn on two-factor authentication';

  @override
  String get desactiverDoubleAuthentification =>
      'Turn off two-factor authentication';

  @override
  String get confirmerParMotDePasse => 'Confirm with your password.';

  @override
  String get langue => 'Language';

  @override
  String get langueAide => 'Your choice also applies to the web portal.';

  @override
  String get connexionsRecentes => 'Recent sign-ins';

  @override
  String get aImplementer => 'Coming soon to the app';

  @override
  String get aImplementerDetail =>
      'In the meantime, this section is available on the web portal.';

  @override
  String get chargement => 'Loading…';

  @override
  String get reessayer => 'Try again';

  @override
  String get erreurInattendue => 'An unexpected error occurred.';

  @override
  String get notificationsToutes => 'All';

  @override
  String get notificationsFiltreNonLues => 'Unread';

  @override
  String get toutMarquerLu => 'Mark all as read';

  @override
  String get aucuneNotification => 'No notifications yet.';

  @override
  String get aucuneNotificationNonLue => 'You\'re all caught up.';

  @override
  String get marquerLue => 'Mark as read';

  @override
  String get marquerNonLue => 'Mark as unread';

  @override
  String get supprimer => 'Delete';

  @override
  String get notificationSupprimee => 'Notification deleted.';

  @override
  String get ouvrir => 'Open';

  @override
  String get fermer => 'Close';

  @override
  String get emploiDuTemps => 'Timetable';

  @override
  String get calendrier => 'Calendar';

  @override
  String get parcours => 'Academic path';

  @override
  String get semainePrecedente => 'Previous week';

  @override
  String get semaineSuivante => 'Next week';

  @override
  String get cetteSemaine => 'This week';

  @override
  String semaineDuAu(String debut, String fin) {
    return '$debut – $fin';
  }

  @override
  String seancesDeLaSemaine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count classes',
      one: '1 class',
      zero: 'No classes',
    );
    return '$_temp0';
  }

  @override
  String get aucuneSeanceSemaine => 'No classes scheduled this week.';

  @override
  String get datesPassees => 'Past dates';

  @override
  String get aucunEvenement => 'No dates published on the calendar.';

  @override
  String get aucunParcours => 'No enrolment recorded.';

  @override
  String get inscriptionCourante => 'Current';

  @override
  String get inscriptionNonFinalisee => 'Enrolment not finalised';

  @override
  String get notesEnAttenteJury => 'Awaiting the board';

  @override
  String get aucuneNote => 'No grades published for this year.';

  @override
  String get moyenne => 'Average';

  @override
  String get credits => 'Credits';

  @override
  String creditsDuCours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count credits',
      one: '1 credit',
    );
    return '$_temp0';
  }

  @override
  String get rang => 'Rank';

  @override
  String get resultatAnnuel => 'Annual result';

  @override
  String resultatSession(String session) {
    return 'Result · $session';
  }

  @override
  String get sessionNormale => 'Regular session';

  @override
  String get sessionRattrapage => 'Resit';

  @override
  String get coursARepasser => 'Courses to retake';

  @override
  String get relevesDeNotes => 'Transcripts';

  @override
  String releveNumero(String numero) {
    return 'Transcript no. $numero';
  }

  @override
  String releveEmisLe(String version, String date) {
    return 'Version $version · issued $date';
  }

  @override
  String get relevesAuGuichet =>
      'Transcripts are collected from the registrar\'s office.';

  @override
  String get notesAvantJury =>
      'Course grades appear once the board\'s results are published. Until then, only assessments validated by the office are shown.';

  @override
  String get anneeAcademique => 'Academic year';

  @override
  String get totalDu => 'Total due';

  @override
  String get echeancier => 'Payment schedule';

  @override
  String get aucuneTranche => 'No instalments set for this year.';

  @override
  String echeanceLe(String date) {
    return 'Due $date';
  }

  @override
  String payeSur(String paye, String montant) {
    return '$paye paid of $montant';
  }

  @override
  String get couverteParMoratoire => 'Covered by a payment extension';

  @override
  String get paiements => 'Payments';

  @override
  String get aucunPaiement => 'No payments recorded for this year.';

  @override
  String get moratoiresAccordes => 'Granted payment extensions';

  @override
  String get demandeMoratoireEnCours =>
      'Payment extension request under review';

  @override
  String get telechargerRecu => 'Download receipt';

  @override
  String get telechargerReleve => 'Download account statement';

  @override
  String get telechargementEnCours => 'Downloading…';

  @override
  String get ouvertureImpossible => 'No app can open this document.';

  @override
  String get aucuneSituation => 'No financial statement for this year.';

  @override
  String get sectionScolarite => 'My studies';

  @override
  String get sectionNotes => 'My grades';

  @override
  String get sectionFinances => 'My finances';

  @override
  String get sectionDocuments => 'My documents';

  @override
  String get sectionExamens => 'Exam schedule';

  @override
  String get sectionSupports => 'My course materials';

  @override
  String get sectionDiscipline => 'My attendance';

  @override
  String get aucunDocumentDossier => 'No official documents in your file.';

  @override
  String get documentsAuGuichet =>
      'Other documents are collected from the registrar\'s office.';

  @override
  String documentEtabliLe(String date) {
    return 'Issued $date';
  }

  @override
  String documentRetireLe(String date) {
    return 'Collected $date';
  }

  @override
  String get telechargerCertificat => 'Download the certificate';

  @override
  String get certificatIndisponible => 'Download unavailable';

  @override
  String get aucunPlanning => 'No exam schedule published for your class.';

  @override
  String get planningEnCours => 'In progress';

  @override
  String get planningTermine => 'Finished';

  @override
  String get planningAVenir => 'Upcoming';

  @override
  String nbEpreuves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exams',
      one: '1 exam',
      zero: 'No exams',
    );
    return '$_temp0';
  }

  @override
  String get telechargerPlanning => 'Download the schedule (PDF)';

  @override
  String get pause => 'Break';

  @override
  String get epreuveConcernee => 'You sit this exam';

  @override
  String get aucunSupport => 'No course outline or materials published yet.';

  @override
  String supportsATelecharger(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents to download',
      one: '1 document to download',
      zero: 'Everything is downloaded',
    );
    return '$_temp0';
  }

  @override
  String get nouvelleVersion => 'New version';

  @override
  String get telecharge => 'Downloaded';

  @override
  String telechargeLe(String date) {
    return 'Downloaded $date';
  }

  @override
  String get aTelecharger => 'To download';

  @override
  String nbFichiers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String publieLe(String date) {
    return 'Published $date';
  }

  @override
  String misAJourLe(String date) {
    return 'Updated $date';
  }

  @override
  String get telecharger => 'Download';

  @override
  String get aucunDossierDiscipline => 'No attendance record for this year.';

  @override
  String get tauxPresence => 'Attendance rate';

  @override
  String seancesPrevuesNombre(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count classes scheduled so far',
      one: '1 class scheduled so far',
      zero: 'No classes scheduled so far',
    );
    return '$_temp0';
  }

  @override
  String seuilExamens(String seuil) {
    return 'Exam eligibility threshold: $seuil';
  }

  @override
  String get absences => 'Absences';

  @override
  String get retards => 'Late arrivals';

  @override
  String absencesNonJustifiees(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unexcused',
      one: '1 unexcused',
      zero: 'all excused',
    );
    return '$_temp0';
  }

  @override
  String retardsNonJustifies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unexcused',
      one: '1 unexcused',
      zero: 'all excused',
    );
    return '$_temp0';
  }

  @override
  String get assiduiteParException =>
      'Some of your classes were recorded by exception (only absences are entered): read the rate with care.';

  @override
  String get assiduiteParCours => 'Attendance by course';

  @override
  String absencesSurSeances(int absences, int seances) {
    String _temp0 = intl.Intl.pluralLogic(
      absences,
      locale: localeName,
      other: '$absences absences',
      one: '1 absence',
      zero: 'No absences',
    );
    return '$_temp0 out of $seances';
  }

  @override
  String get absencesEtRetards => 'Absences and late arrivals';

  @override
  String get aucunManquement =>
      'No absences or late arrivals recorded this year.';

  @override
  String minutesDeRetard(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes late',
      one: '1 minute late',
    );
    return '$_temp0';
  }

  @override
  String justificatifAvant(String date) {
    return 'Supporting document due by $date';
  }

  @override
  String get sanctions => 'Sanctions';

  @override
  String aCompterDu(String date) {
    return 'From $date';
  }

  @override
  String get tenueVestimentaire => 'Dress code';

  @override
  String aRegulariserAvant(String date) {
    return 'To be resolved by $date';
  }

  @override
  String get sectionMoratoires => 'My payment extensions';

  @override
  String get sectionPermissions => 'My permissions';

  @override
  String get mesDemandes => 'My requests';

  @override
  String get nouvelleDemande => 'New request';

  @override
  String get demandeMoratoire => 'Payment extension request';

  @override
  String get nouvelleDemandeMoratoire => 'Request a payment extension';

  @override
  String get aucuneDemandeMoratoire =>
      'You haven\'t submitted any payment extension request.';

  @override
  String get montantDemandable => 'Amount that can still be covered';

  @override
  String get moratoireExplication =>
      'A payment extension postpones part of what you owe. Your request changes nothing to your account until the registrar\'s office accepts it.';

  @override
  String moratoireAttendreDecision(String reference) {
    return 'Request $reference is being reviewed: wait for the registrar\'s decision before submitting another one.';
  }

  @override
  String get moratoireRienACouvrir =>
      'Your account leaves nothing to cover: a payment extension request has no purpose this year.';

  @override
  String get moratoireSansAnnee =>
      'No academic year is open: please contact the registrar\'s office.';

  @override
  String get montantSollicite => 'Amount requested';

  @override
  String auPlus(String montant) {
    return 'At most $montant';
  }

  @override
  String get tout => 'All';

  @override
  String get montantInvalide => 'Enter an amount greater than zero.';

  @override
  String get dateReglementSouhaitee => 'Requested payment date';

  @override
  String get dateRequise => 'Choose a date.';

  @override
  String reglementSouhaiteLe(String date) {
    return 'Payment requested by $date';
  }

  @override
  String get motifDeLaDemande => 'Reason for the request';

  @override
  String get motifMoratoireAide =>
      'Explain your situation (late scholarship, family difficulty…)';

  @override
  String get motifRequis => 'Explain your request.';

  @override
  String get pieceJustificativeFacultative => 'Supporting document (optional)';

  @override
  String get pieceJustificativeObligatoire =>
      'Supporting document (required for an absence)';

  @override
  String get formatsPieces => 'PDF or photo (JPG, PNG), 5 MB maximum.';

  @override
  String get choisirFichier => 'Choose a file';

  @override
  String get remplacerFichier => 'Replace';

  @override
  String get retirerFichier => 'Remove the file';

  @override
  String get pieceTropLourde => 'This file exceeds 5 MB: choose a smaller one.';

  @override
  String get pieceJointeFournie => 'Supporting document attached';

  @override
  String get envoyerDemande => 'Send the request';

  @override
  String envoyerDemandeSeances(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Send the request ($n sessions)',
      one: 'Send the request (1 session)',
    );
    return '$_temp0';
  }

  @override
  String deposeeLe(String date) {
    return 'Submitted on $date';
  }

  @override
  String get reponseDuService => 'Office\'s answer';

  @override
  String reponseDuServiceLe(String date) {
    return 'Office\'s answer, $date';
  }

  @override
  String get retirerDemande => 'Withdraw the request';

  @override
  String get retirer => 'Withdraw';

  @override
  String retirerMoratoireConfirmation(String reference) {
    return 'Request $reference will be withdrawn: the registrar will not review it. You can submit another one.';
  }

  @override
  String get retirerPermissionConfirmation =>
      'The request will be withdrawn: the office will not review it. You can submit another one.';

  @override
  String get demanderPermission => 'Request a permission';

  @override
  String get depotPermissionsFerme =>
      'The office has closed permission requests.';

  @override
  String get permissionExplication =>
      'Report an absence or a late arrival here, session by session. Your request excuses nothing until the office grants it.';

  @override
  String get aucuneDemandePermission =>
      'You haven\'t submitted any permission request.';

  @override
  String nbEnAttente(int n) {
    return '$n pending';
  }

  @override
  String permissionDe(String type) {
    return 'Permission: $type';
  }

  @override
  String get saisieAuBureau => 'Recorded at the office';

  @override
  String arriveeAnnoncee(String heure) {
    return 'Arrival announced at $heure';
  }

  @override
  String get objetDeLaDemande => 'Request type';

  @override
  String get absence => 'Absence';

  @override
  String get retard => 'Late arrival';

  @override
  String get seancesConcernees => 'Sessions concerned';

  @override
  String get jourChome => 'No classes';

  @override
  String get dejaAccordee => 'Already granted';

  @override
  String preavisPermission(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Submit your request at least $n hours before the session. A late request is still possible: the office will see it.',
      one:
          'Submit your request at least 1 hour before the session. A late request is still possible: the office will see it.',
    );
    return '$_temp0';
  }

  @override
  String get heureArriveeAnnoncee => 'Announced arrival time';

  @override
  String get heureArriveeRequise => 'Announce the time you expect to arrive.';

  @override
  String get motif => 'Reason';

  @override
  String get motifNonListe => '— Reason not listed —';

  @override
  String get explication => 'Explanation';

  @override
  String get explicationPermissionAide =>
      'Explain in a few lines what prevents you from attending.';

  @override
  String get explicationRequise =>
      'Explain your request: the office decides on this explanation.';

  @override
  String get demandesDeMoratoire => 'Payment extension requests';

  @override
  String get sectionMessages => 'My messages';

  @override
  String get sectionSuggestions => 'Suggestion box';

  @override
  String get repondre => 'Reply';

  @override
  String get jaime => 'Like';

  @override
  String get jaimePas => 'Dislike';

  @override
  String get retirerJaime => 'Remove “Like”';

  @override
  String get retirerJaimePas => 'Remove “Dislike”';

  @override
  String get copier => 'Copy text';

  @override
  String get serviceEnLigne => 'An agent is online';

  @override
  String get serviceHorsLigne => 'No agent online';

  @override
  String get filVide =>
      'Write to the registrar\'s office: your question reaches the desk, and the agent who takes it answers here.';

  @override
  String get messagesPlusAnciens => 'Older messages';

  @override
  String get envoye => 'Sent';

  @override
  String get luParLeService => 'Read by the office';

  @override
  String reponseA(String auteur) {
    return 'Replying to $auteur';
  }

  @override
  String get joindreFichier => 'Attach a file';

  @override
  String get ecrireMessage => 'Your message…';

  @override
  String get envoyer => 'Send';

  @override
  String get ajouterFichiers => 'Add files';

  @override
  String piecesAuPlus(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n files at most.',
      one: 'One file at most.',
    );
    return '$_temp0';
  }

  @override
  String get nouvelleSuggestion => 'New suggestion';

  @override
  String get mesSuggestions => 'My suggestions';

  @override
  String get aucuneSuggestion => 'You haven\'t submitted any suggestion.';

  @override
  String get suggestionAnonyme => 'Anonymous for the office';

  @override
  String get suggestionExplication =>
      'You follow the status of your suggestions here; the follow-up stays internal to the office.';

  @override
  String get solutionProposee => 'Proposed solution';

  @override
  String nbPreuves(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n proofs attached',
      one: '1 proof attached',
    );
    return '$_temp0';
  }

  @override
  String get votreSuggestion => 'Your suggestion';

  @override
  String get votreSuggestionAide => 'What you suggest improving, and why.';

  @override
  String get suggestionRequise => 'Write your suggestion.';

  @override
  String get solutionProposeeAide => 'How you would fix it, concretely.';

  @override
  String get solutionRequise => 'State the solution you propose.';

  @override
  String get preuvesFacultatives => 'Proofs (optional)';

  @override
  String get deposerSuggestion => 'Submit the suggestion';

  @override
  String get sectionReinscription => 'My re-enrolment';

  @override
  String get inscriptionPrononcee => 'Enrolment confirmed';

  @override
  String get reinscriptionAFaire => 'Re-enrolment to request';

  @override
  String get reinscriptionIndisponible => 'Online re-enrolment unavailable';

  @override
  String get programme => 'Programme';

  @override
  String get niveauEtSpecialite => 'Level and specialisation';

  @override
  String demandeeLe(String date) {
    return 'Requested on $date';
  }

  @override
  String parDemandeur(String nom) {
    return 'by $nom';
  }

  @override
  String get reinscriptionAttentePaiement =>
      'Your re-enrolment will be confirmed as soon as the first instalment is paid (or covered by a granted extension).';

  @override
  String get choisirSpecialite => 'Choose your specialisation.';

  @override
  String get modifierMaDemande => 'Change my request';

  @override
  String get demanderReinscription => 'Request my re-enrolment';

  @override
  String get niveauSelonJury => 'Your level is set by the board decision.';

  @override
  String niveauSelonDecision(String decision) {
    return 'Board decision: $decision. Your level follows from it.';
  }

  @override
  String get niveau => 'Level';

  @override
  String get specialite => 'Specialisation';

  @override
  String get reinscriptionModifiable =>
      'Level and specialisation can be changed until a payment is declared or recorded.';

  @override
  String get enregistrerModification => 'Save the change';

  @override
  String get premiereTranche => 'First instalment';

  @override
  String get trancheCouverte => 'Covered';

  @override
  String get trancheNonConfiguree =>
      'The payment schedule for your level is not published yet: contact the cashier.';

  @override
  String get montantDu => 'Amount';

  @override
  String get dejaPaye => 'Already paid';

  @override
  String get declarerUnVersement => 'Declare a payment';

  @override
  String get trancheACaisse =>
      'Online declaration is not open: pay the instalment at the cashier; re-enrolment is confirmed on payment.';

  @override
  String get versementsDeclares => 'Declared payments';

  @override
  String get versementsFermes => 'Online payment declaration is not open.';

  @override
  String get versementExplication =>
      'Pay at the bank into one of the accounts below, then declare the payment with the receipt. It only counts once the payments office has checked it on the bank statement.';

  @override
  String get mesDeclarations => 'My declarations';

  @override
  String get aucuneDeclaration => 'No payment declared this year.';

  @override
  String get resteADeclarer => 'Left to declare';

  @override
  String get enVerification => 'Being checked';

  @override
  String get copierNumero => 'Copy the account number';

  @override
  String get numeroCopie => 'Account number copied.';

  @override
  String get retirerDeclaration => 'Withdraw the declaration';

  @override
  String retirerDeclarationConfirmation(String reference) {
    return 'Declaration $reference will be withdrawn: the office will not check it.';
  }

  @override
  String montantRetenu(String montant) {
    return 'Amount found on the statement: $montant';
  }

  @override
  String verseLe(String date) {
    return 'Paid on $date';
  }

  @override
  String trancheVisee(String tranche) {
    return 'Instalment: $tranche';
  }

  @override
  String declarePar(String nom, String espace) {
    return 'Declared by $nom ($espace)';
  }

  @override
  String get motifDuRejet => 'Reason for rejection';

  @override
  String get recuDeLaBanque => 'Bank receipt';

  @override
  String get recuDePaiement => 'Payment receipt';

  @override
  String get compteCredite => 'Account credited';

  @override
  String get choisirCompte => 'Choose the account you paid into.';

  @override
  String get trancheReglee => 'Instalment paid';

  @override
  String get repartirSurTranches => 'Spread over the instalments in order';

  @override
  String trancheReste(String tranche, String reste) {
    return '$tranche — $reste left';
  }

  @override
  String get montantVerse => 'Amount paid';

  @override
  String get laTranche => 'Instalment';

  @override
  String get dateDuVersement => 'Payment date';

  @override
  String get referenceOperation => 'Transaction reference';

  @override
  String get referenceOperationAide => 'Slip number or transfer reference';

  @override
  String get referenceRequise => 'Enter the reference shown on the receipt.';

  @override
  String get recuRequis => 'Attach the bank receipt.';

  @override
  String get formatsRecu =>
      'PDF or photo (JPG, PNG, WEBP, HEIC), 5 MB maximum.';

  @override
  String get commentaireFacultatif => 'Comment (optional)';

  @override
  String get declarerLeVersement => 'Declare the payment';

  @override
  String couverteParMoratoireRef(String reference) {
    return 'Covered by extension $reference';
  }

  @override
  String get sectionDiscussions => 'Class discussions';

  @override
  String get discussionVide =>
      'No message in this discussion yet. The first one starts the class group.';

  @override
  String get discussionLectureSeule =>
      'Past discussion: you are no longer in this class. You can read it but not write.';

  @override
  String get enseignantEnLigne => 'teacher online';

  @override
  String get enseignantHorsLigne => 'teacher offline';

  @override
  String get rechercherClasse => 'Search a course, a class…';

  @override
  String get aucuneDiscussion =>
      'No class is linked to you yet: discussions open with published timetables.';

  @override
  String get discussionsPassees => 'Past discussions';

  @override
  String get discussionsPasseesAide => 'Classes you have left: read only.';

  @override
  String get aucunMessagePourLInstant => 'No message yet';

  @override
  String get sectionBibliotheque => 'University library';

  @override
  String get rechercherBibliotheque => 'Title, author, topic…';

  @override
  String get effacer => 'Clear';

  @override
  String nbResultats(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n results',
      one: '1 result',
      zero: 'No result',
    );
    return '$_temp0';
  }

  @override
  String get aucunResultat => 'No document matches your search.';

  @override
  String get dossierVide => 'This folder is empty.';

  @override
  String get afficherPlus => 'Show more';

  @override
  String nbDossiers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n folders',
      one: '1 folder',
    );
    return '$_temp0';
  }

  @override
  String ajouteLe(String date) {
    return 'added on $date';
  }

  @override
  String get sectionArchives => 'Archives';

  @override
  String get anciennesEpreuves => 'Past exam papers';

  @override
  String get supportsPasses => 'Past course materials';

  @override
  String get toutesLesAnnees => 'All years';

  @override
  String get aucuneAnnale => 'No past exam paper published for your class.';

  @override
  String get aucunSupportArchive =>
      'No course material from past years for your class.';

  @override
  String get annalesExplication =>
      'Only the paper is provided, never the answer key.';

  @override
  String dureeMinutes(int n) {
    return '$n min';
  }

  @override
  String get telechargerSujet => 'Download the paper';

  @override
  String get nonPublie => 'Not published';

  @override
  String get sectionPromotion => 'My class';

  @override
  String get aucunePromotion => 'No confirmed result for your class yet.';

  @override
  String get majorsDeLAnnee => 'Top students this year';

  @override
  String get majorsDesAnneesPassees => 'Top students of past years';

  @override
  String get effectifInsuffisant => 'Too few students';

  @override
  String plancherEffectif(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'A class average is only shown from $n students, so that it points to nobody.',
      one: 'A class average is only shown from 1 student.',
    );
    return '$_temp0';
  }

  @override
  String nbEtudiants(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n students',
      one: '1 student',
    );
    return '$_temp0';
  }

  @override
  String get premierePlacePartagee => 'First place shared.';

  @override
  String get sectionAssociation => 'Student association';

  @override
  String get sectionAssociationHistorique => 'Elected lists';

  @override
  String get aucuneCampagne => 'No election campaign is open.';

  @override
  String get resultats => 'Results';

  @override
  String get depouillement => 'Vote count';

  @override
  String get enDirect => 'Live';

  @override
  String participation(String taux, int votants, int inscrits) {
    return 'Turnout: $taux% ($votants voters out of $inscrits registered)';
  }

  @override
  String get elu => 'Elected';

  @override
  String nbVoix(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n votes',
      one: '1 vote',
      zero: '0 votes',
    );
    return '$_temp0';
  }

  @override
  String get ballottage =>
      'Tie at the top: no list is elected. The institution will decide.';

  @override
  String get aucunSuffrage => 'No vote yet.';

  @override
  String candidat(String nom) {
    return 'Candidate: $nom';
  }

  @override
  String get lireLeProgramme => 'Read the programme';

  @override
  String get programmeDeLaListe => 'Programme';

  @override
  String get programmeNonRedige => 'This list has not written its programme.';

  @override
  String get equipe => 'Team';

  @override
  String get scrutinAnnule => 'Election cancelled';

  @override
  String get urnesOuvertes => 'Polls open';

  @override
  String get voteTermine => 'Voting closed';

  @override
  String get urnesAVenir => 'Voting to come';

  @override
  String get vousAvezVote => 'You have voted';

  @override
  String get voteAnonyme =>
      'Voting is anonymous: the system knows you voted, never for whom.';

  @override
  String get listesCandidates => 'Candidate lists';

  @override
  String get votreBulletin => 'Your ballot';

  @override
  String get confirmerVote => 'Confirm your vote';

  @override
  String confirmerVoteTexte(String liste) {
    return 'You are voting for “$liste”. A vote cannot be changed.';
  }

  @override
  String get voter => 'Vote';

  @override
  String get validerMonVote => 'Cast my vote';

  @override
  String get aucunScrutinPasse => 'No election has ended yet.';

  @override
  String presidentElu(String nom) {
    return 'Elected president: $nom';
  }

  @override
  String get sectionDelegation => 'My class delegation';

  @override
  String get aucuneSeanceCeJour => 'No session for your class that day.';

  @override
  String get circuitService => 'approved by the office';

  @override
  String get circuitEnseignant => 'signed by the teacher';

  @override
  String get circuitEnseignantService =>
      'signed by the teacher, then approved by the office';

  @override
  String get circuitAutomatique => 'approved automatically';

  @override
  String circuitDeLAppel(String circuit) {
    return 'Attendance: $circuit.';
  }

  @override
  String circuitDuCahier(String circuit) {
    return 'Class log: $circuit.';
  }

  @override
  String get appelNonAutorise =>
      'Attendance is not open to you: your head delegate or the office can open it.';

  @override
  String get positionExigee =>
      'The school requires your location when saving: do it from the classroom.';

  @override
  String get jourPrecedent => 'Previous day';

  @override
  String get jourSuivant => 'Next day';

  @override
  String get aujourdhui => 'Today';

  @override
  String get aFaire => 'To do';

  @override
  String get renvoyeAuDelegue => 'To correct';

  @override
  String get signeParEnseignant => 'Signed by the teacher';

  @override
  String get valideParService => 'Approved by the office';

  @override
  String get fenetreAVenir => 'Not open yet';

  @override
  String get fenetreFermee => 'Window closed';

  @override
  String get coursNonTenu => 'Class recorded as not held';

  @override
  String get horsPlanning => 'Outside the timetable';

  @override
  String fenetreDeA(String debut, String fin) {
    return 'Open from $debut to $fin';
  }

  @override
  String get faire => 'Do it';

  @override
  String get corriger => 'Correct';

  @override
  String get rouvertParLeService => 'Reopened by the office';

  @override
  String get motifDuRenvoi => 'Reason for return';

  @override
  String get appel => 'Attendance';

  @override
  String get cahierDeTexte => 'Class log';

  @override
  String get seancesRouvertes => 'Sessions reopened by the office';

  @override
  String jusquAu(String date) {
    return 'until $date';
  }

  @override
  String get mesAssistants => 'My assistants';

  @override
  String get assistantsAide =>
      'You decide which assistants can take attendance in your place.';

  @override
  String get releveDePosition => 'Getting your location…';

  @override
  String get positionIndisponible => 'Location unavailable';

  @override
  String get positionServiceDesactive =>
      'The phone\'s location is turned off: turn it on, then try again.';

  @override
  String get positionRefusee =>
      'The app is not allowed to read your location: accept the request, then try again.';

  @override
  String get positionRefuseeReglages =>
      'Location access is denied: allow it for YSEM in the phone settings.';

  @override
  String get positionDelai =>
      'Your location could not be obtained in time: move near a window and try again.';

  @override
  String get compris => 'Got it';

  @override
  String get enregistrerLAppel => 'Save attendance';

  @override
  String confirmerAppel(int absents, int effectif) {
    String _temp0 = intl.Intl.pluralLogic(
      absents,
      locale: localeName,
      other: '$absents absentees out of $effectif students.',
      one: '1 absentee out of $effectif students.',
      zero: 'No absentee out of $effectif students.',
    );
    return '$_temp0 Confirm?';
  }

  @override
  String get appelDeLaSeance => 'Session attendance';

  @override
  String get appelExplication =>
      'Only tick the absentees: the others count as present. A locked line is covered by a granted permission.';

  @override
  String couvertParPermission(String type) {
    return 'Permission granted ($type)';
  }

  @override
  String nbAbsentsSur(int absents, int effectif) {
    return '$absents absent / $effectif';
  }

  @override
  String get contenuPrevu => 'Planned content';

  @override
  String get aucunPlanDeCours => 'No course plan is linked to this session.';

  @override
  String get contenuFait => 'Content covered';

  @override
  String blocN(int n) {
    return 'Block $n';
  }

  @override
  String seanceNumero(int n) {
    return 'Session $n';
  }

  @override
  String get ajouterUneSeanceFaite => 'Add a covered session';

  @override
  String get blocsAide =>
      'A double session often covers two plan sessions: add one block per covered session.';

  @override
  String get activitesPedagogiques => 'Teaching activities';

  @override
  String get nonRenseigne => 'Not specified';

  @override
  String get enregistrerLeCahier => 'Save the class log';

  @override
  String get connexionEnseignantConsigne =>
      'Sign in with the email address and password of the lecturer portal.';

  @override
  String get connexionEnseignantAide =>
      'No account yet, or account not activated? Sign-up and activation are done on the lecturer web portal.';

  @override
  String get emailInvalide => 'Invalid email address.';

  @override
  String get motDePasseOublie => 'Forgot your password?';

  @override
  String get motDePasseOublieConsigne =>
      'Enter your account address: a link will be sent to you to choose a new password on the web portal.';

  @override
  String get envoyerLeLien => 'Send the link';

  @override
  String get maCandidature => 'My application';

  @override
  String get candidatureSoumise => 'Submitted';

  @override
  String candidatureEtape(int etape, int etapes) {
    return 'Step $etape of $etapes';
  }

  @override
  String candidatureSoumiseLe(String date) {
    return 'Application submitted on $date. The institution is reviewing it.';
  }

  @override
  String candidatureAPoursuivre(int etape) {
    return 'Your application is to be continued at step $etape.';
  }

  @override
  String get candidatureSurLeWeb =>
      'The application form is filled in on the lecturer web portal.';

  @override
  String get candidatureAcceptee => 'Application accepted';

  @override
  String get candidatureAccepteeTexte =>
      'Welcome to the teaching staff! Your services are now open in the app.';

  @override
  String get motifDuRefus => 'Reason for refusal';

  @override
  String get rienEnAttente => 'Nothing needs your attention right now.';

  @override
  String fichesASignerNombre(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre delegate sheets to sign',
      one: '1 delegate sheet to sign',
    );
    return '$_temp0';
  }

  @override
  String rattrapagesOuvertsNombre(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre make-up sessions due',
      one: '1 make-up session due',
    );
    return '$_temp0';
  }

  @override
  String fichesATransmettreNombre(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre attendance sheets to submit',
      one: '1 attendance sheet to submit',
    );
    return '$_temp0';
  }

  @override
  String messagesNonLusNombre(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre unread messages in your classes',
      one: '1 unread message in your classes',
    );
    return '$_temp0';
  }

  @override
  String get monDossier => 'My file';

  @override
  String get monDossierAide =>
      'Personal details, degrees, experience and validations.';

  @override
  String get profilProfessionnel => 'Profile';

  @override
  String get dernierDiplome => 'Highest degree obtained';

  @override
  String get dateRecrutement => 'Hiring date';

  @override
  String get permanent => 'Permanent';

  @override
  String get vacataire => 'Part-time lecturer';

  @override
  String get dossierIncomplet => 'Your file is incomplete';

  @override
  String get dossierModifierSurLeWeb =>
      'To update your file, use \"My file\" on the lecturer web portal. Rank, fields and courses are set by the office.';

  @override
  String get etatCivil => 'Personal details';

  @override
  String get nationalite => 'Nationality';

  @override
  String get regionOrigine => 'Region of origin';

  @override
  String get situationMatrimoniale => 'Marital status';

  @override
  String enfantsACharge(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre dependent children',
      one: '1 dependent child',
    );
    return '$_temp0';
  }

  @override
  String get cni => 'National ID card';

  @override
  String get niu => 'Taxpayer number (NIU)';

  @override
  String get universiteRattachement => 'Affiliated university';

  @override
  String get cv => 'Curriculum vitae';

  @override
  String get depose => 'Uploaded';

  @override
  String get nonDepose => 'Not uploaded';

  @override
  String get coordonnees => 'Contact details';

  @override
  String get adresse => 'Address';

  @override
  String get contactUrgence => 'Emergency contact';

  @override
  String get cursusEtCertifications => 'Degrees and certifications';

  @override
  String get aucunDiplome => 'No degree recorded.';

  @override
  String get justificatifDepose => 'Supporting document uploaded';

  @override
  String get certifications => 'Certifications';

  @override
  String get experiencesEnseignement => 'Teaching experience';

  @override
  String get experiencesEntreprise => 'Professional experience';

  @override
  String get aucuneExperience => 'No experience recorded.';

  @override
  String nombreAnnees(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String nombreMois(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get domainesEnseignement => 'Teaching fields';

  @override
  String get coursProposes => 'Proposed courses';

  @override
  String get aucunElement => 'Nothing yet.';

  @override
  String get sectionFichesASigner => 'Sheets to sign';

  @override
  String get sectionRattrapages => 'My make-up sessions';

  @override
  String get sectionClasses => 'My classes';

  @override
  String get fichesASignerExplication =>
      'Roll calls and class logs entered by class representatives await your signature. Signing validates them; send back to the representative anything that needs correcting, saying why.';

  @override
  String get aucuneFicheASigner => 'No sheet awaits your signature.';

  @override
  String signerToutesLesFiches(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: 'Sign all $nombre sheets',
      one: 'Sign the sheet',
    );
    return '$_temp0';
  }

  @override
  String get signerToutConfirmation =>
      'Each signed sheet is validated, or goes on to the office for validation depending on this year\'s workflow.';

  @override
  String get signer => 'Sign';

  @override
  String get renvoyer => 'Send back';

  @override
  String get renvoyerAuDelegue => 'Send back to the representative';

  @override
  String get renvoyerAuDelegueAide =>
      'Tell the representative what to correct: they are notified and can rework the sheet.';

  @override
  String get dernieresFiches => 'Recently processed sheets';

  @override
  String get ficheAppel => 'Representative\'s roll call';

  @override
  String get ficheCahierDeTexte => 'Class log';

  @override
  String saisiPar(String nom) {
    return 'Entered by $nom';
  }

  @override
  String get enAttenteValidationService =>
      'Signed — awaiting the office\'s validation.';

  @override
  String nbAbsents(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre absentees',
      one: '1 absentee',
      zero: 'No absentees',
    );
    return '$_temp0';
  }

  @override
  String get cahierSansContenu => 'No content recorded.';

  @override
  String get rattrapagesExplication =>
      'Propose a date for a session to make up: students are told only once the office approves it. A session already scheduled is moved by the office.';

  @override
  String get aucunRattrapage => 'No sessions to make up.';

  @override
  String get rattrapagesClos => 'Closed make-up sessions';

  @override
  String seanceDuJour(String date) {
    return 'Session of $date';
  }

  @override
  String aRattraperAvant(String date) {
    return 'To make up before $date';
  }

  @override
  String get dateEnAttenteArbitrage =>
      'Proposed date, awaiting the office\'s approval.';

  @override
  String rattrapeLe(String date) {
    return 'Made up on $date';
  }

  @override
  String get dateRefusee => 'Date refused';

  @override
  String get proposerUneDate => 'Propose a date';

  @override
  String get propositionAide =>
      'The date remains a proposal until the office approves it.';

  @override
  String get dateProposee => 'Proposed date';

  @override
  String get creneau => 'Time slot';

  @override
  String get salleFacultative => 'Room (optional)';

  @override
  String get aucuneSalle => 'No specific room';

  @override
  String get transmettreAuService => 'Send to the office';

  @override
  String get aucuneClasse =>
      'No class is assigned to you in the published timetables.';

  @override
  String nbClasses(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre classes',
      one: '1 class',
    );
    return '$_temp0';
  }

  @override
  String nbCours(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre courses',
      one: '1 course',
    );
    return '$_temp0';
  }

  @override
  String nbSansDelegue(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre classes without a representative',
      one: '1 class without a representative',
    );
    return '$_temp0';
  }

  @override
  String get sansDeleguePrincipal => 'No main representative';

  @override
  String deleguePrincipal(String noms) {
    return 'Representative: $noms';
  }

  @override
  String get exporterLaListe => 'Export the list (Excel)';

  @override
  String get listeDesInscrits => 'Enrolled students';

  @override
  String get rechercherEtudiant => 'Name or student ID';

  @override
  String get aucunInscrit => 'No students enrolled in this class.';

  @override
  String get aucunEtudiantTrouve => 'No student matches your search.';

  @override
  String get inscrits => 'Enrolled';

  @override
  String get femmesHommes => 'Women / men';

  @override
  String get seancesRelevees => 'Sessions recorded';

  @override
  String get etudiantsAbsents => 'With an absence';

  @override
  String planDeCoursStatut(String statut) {
    return 'Course plan: $statut';
  }

  @override
  String get deleguesDeLaClasse => 'Class representatives';

  @override
  String get aucunDelegue => 'No representative appointed for this class.';

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
      other: '$nombre late arrivals',
      one: '1 late arrival',
    );
    return '$_temp0';
  }

  @override
  String nbNonJustifiees(int nombre) {
    return '$nombre unexcused';
  }

  @override
  String get delegue => 'Representative';
}
