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

  @override
  String get sectionDisponibilites => 'My availability';

  @override
  String get sectionPonctualite => 'My punctuality';

  @override
  String get sectionVacations => 'My teaching fees';

  @override
  String get modifier => 'Edit';

  @override
  String get disponibilitesExplication =>
      'Tell the planning office which time slots suit you, which you prefer and which you cannot do. They are notified and build the timetables with this.';

  @override
  String get aucuneDisponibilite =>
      'You have not declared any availability for this year.';

  @override
  String get declarerDisponibilite => 'Declare availability';

  @override
  String get modifierDisponibilite => 'Edit availability';

  @override
  String get retirerDisponibilite => 'Remove availability';

  @override
  String retirerDisponibiliteConfirmation(String creneau) {
    return 'Remove your declaration for \"$creneau\"? The planning office will be notified.';
  }

  @override
  String get touteLAnnee => 'All year';

  @override
  String get aucunPlanningEnseignant =>
      'No published exam schedule involves you at the moment.';

  @override
  String get votreEpreuve => 'Your exam';

  @override
  String reglesPonctualite(int avance, int tolerance) {
    return 'Expected arrival $avance min before the class starts; lateness counts beyond a $tolerance min allowance.';
  }

  @override
  String get aucuneSeanceRelevee =>
      'No session has been recorded in class yet.';

  @override
  String get heuresDispensees => 'Time taught';

  @override
  String get heuresPerdues => 'Time lost';

  @override
  String get tempsRetenu => 'Time deducted';

  @override
  String arriveeA(String heure) {
    return 'Arrived at $heure';
  }

  @override
  String finA(String heure) {
    return 'ended at $heure';
  }

  @override
  String retardDe(String duree) {
    return '$duree late';
  }

  @override
  String retenue(String duree) {
    return '$duree deducted';
  }

  @override
  String get finConstateeDOffice =>
      'End time set automatically at midnight: it was not recorded.';

  @override
  String get fichesEmargement => 'Attendance sheets';

  @override
  String get fichesEmargementExplication =>
      'Sessions recorded in class are added automatically. Submit each sheet at the end of the month: only sheets validated by the office count towards pay.';

  @override
  String get aucuneFicheEmargement => 'No attendance sheet for this year.';

  @override
  String get detailDesSeances => 'Session details';

  @override
  String get transmettre => 'Submit';

  @override
  String get transmettreLaFiche => 'Submit the sheet';

  @override
  String transmettreFicheConfirmation(String cours, String mois) {
    return 'Submit the sheet for \"$cours\" for $mois to the office? It can no longer change unless the office sends it back.';
  }

  @override
  String get aucunEtatPaiement => 'No payment statement issued for this year.';

  @override
  String get heuresEffectuees => 'Hours taught';

  @override
  String get heuresDeRattrapage => 'of which make-up';

  @override
  String get heuresRetenues => 'Hours deducted';

  @override
  String get montantBrut => 'Gross amount';

  @override
  String get montantNet => 'Net payable';

  @override
  String get precompte => 'Withholding';

  @override
  String precompteAuTaux(String taux) {
    return 'Withholding ($taux%)';
  }

  @override
  String get precompteExonere => 'Withholding (exempt)';

  @override
  String payeLe(String date) {
    return 'Paid on $date';
  }

  @override
  String get paiementBloque => 'Payment on hold';

  @override
  String get reservesDuMois => 'Reservations for the month';

  @override
  String get vacationsExamen => 'Exam duties';

  @override
  String get commissions => 'Committees';

  @override
  String get surveillance => 'Invigilation';

  @override
  String get sectionEnseignements => 'My teaching';

  @override
  String get avancementDeMesCours => 'Progress of my courses';

  @override
  String get aucunCoursAffecte =>
      'No course is assigned to you for this academic year.';

  @override
  String get seancesObservees => 'Sessions observed';

  @override
  String get seancesObserveesAide =>
      'What the office recorded when visiting the classroom.';

  @override
  String get aucuneSeanceObservee => 'No session observed yet.';

  @override
  String get absencesConstatees => 'Absences recorded';

  @override
  String get rattrapagesOuverts => 'Open make-up sessions';

  @override
  String get chapitres => 'Chapters';

  @override
  String get seances => 'Sessions';

  @override
  String seancesNonSuivies(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre scheduled sessions not recorded',
      one: '1 scheduled session not recorded',
    );
    return '$_temp0';
  }

  @override
  String derniereSeance(String date) {
    return 'Last session: $date';
  }

  @override
  String get retoursEtudiants => 'Student feedback';

  @override
  String get retoursEtudiantsAide =>
      'Summaries the office chose to share with you.';

  @override
  String chapitreAtteint(int numero) {
    return 'Chapter reached: $numero';
  }

  @override
  String suiteADonner(String suite) {
    return 'Follow-up: $suite';
  }

  @override
  String get seanceCertifieeDOffice =>
      'Recorded automatically when the day closed: nobody recorded this session.';

  @override
  String get discussionDeLaClasse => 'Class discussion';

  @override
  String get sectionFeuillesDeNotes => 'My grade sheets';

  @override
  String get aucuneFeuilleDeNotes =>
      'No grade sheet is assigned to you for the moment.';

  @override
  String get feuilleDeliberee => 'Deliberated — no longer editable';

  @override
  String get feuilleVerrouillee =>
      'This sheet has been deliberated: its marks can no longer be changed.';

  @override
  String get caseVideTitre => 'An empty box is not a zero';

  @override
  String get caseVideExplication =>
      'If the assessment did not take place for a student, choose the status that explains why: an excused absence or an exemption removes it from the calculation and redistributes its weight, while an unexcused absence counts as zero.';

  @override
  String get controleContinu => 'Continuous assessment';

  @override
  String get controleContinuExplication =>
      'Declare each test when you hold it. Your tests of the same type are averaged together, then each type weighs what the office has set. Hand it in to the office when you have finished: you will no longer be able to add or change a test, but the office can send it back to you if needed.';

  @override
  String get controleContinuRenduLecture =>
      'The continuous assessment has been handed in to the office: its marks can no longer be changed from here.';

  @override
  String get aucunControle => 'No test declared yet.';

  @override
  String get nouveauControle => 'New test';

  @override
  String get ajouterLeControle => 'Add the test';

  @override
  String get typeDeControle => 'Type of test';

  @override
  String get date => 'Date';

  @override
  String get supprimerControle => 'Delete this test';

  @override
  String supprimerControleConfirmation(String libelle) {
    return 'Delete “$libelle” and its marks?';
  }

  @override
  String get rendreControleContinu => 'Hand in the continuous assessment';

  @override
  String get rendreCcConfirmation =>
      'Once handed in, you can no longer add or change a test — the office can send it back to you if needed.';

  @override
  String get rendre => 'Hand in';

  @override
  String rendreLesNotes(String epreuve) {
    return 'Hand in the marks ($epreuve)';
  }

  @override
  String get rendreEpreuveConfirmation =>
      'Once handed in, the assessment goes to the office and you can no longer change it — the office can send it back to you if needed.';

  @override
  String get epreuveAVenir => 'Upcoming';

  @override
  String get epreuveAVenirExplication =>
      'Entry opens after the sitting, once the scripts have been anonymised.';

  @override
  String get epreuveValidee => 'Validated by the office';

  @override
  String get epreuveRendue => 'Handed in, awaiting validation';

  @override
  String controlesARendre(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre tests — hand in when finished',
      one: '1 test — hand in when finished',
      zero: 'No test — hand in when finished',
    );
    return '$_temp0';
  }

  @override
  String notesASaisirSur(int manquantes, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      manquantes,
      locale: localeName,
      other: '$manquantes marks still to enter out of $total',
      one: '1 mark still to enter out of $total',
    );
    return '$_temp0';
  }

  @override
  String get saisieCompleteARendre => 'Entry complete — still to hand in';

  @override
  String get saisieComplete => 'Entry complete';

  @override
  String notesEncoreAttendues(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre marks still expected',
      one: '1 mark still expected',
    );
    return '$_temp0';
  }

  @override
  String aRendreAvant(String date) {
    return 'To hand in by $date';
  }

  @override
  String get messageDuService => 'Message from the office';

  @override
  String get notesSaisies => 'Marks entered';

  @override
  String notesSur(String max) {
    return 'Marks out of $max';
  }

  @override
  String ponderationDe(String valeur) {
    return 'Weight $valeur';
  }

  @override
  String get saisirParCode => 'Enter by anonymity code';

  @override
  String get saisieParCodeExplication =>
      'Scripts only carry their anonymity code: enter each mark against the code written on the script. The link between a code and a student is known only to the office.';

  @override
  String get rechercherCode => 'Search for a code';

  @override
  String get aucuneCopieCodee => 'No coded script. Please tell the office.';

  @override
  String get aucunEtudiantSurFeuille =>
      'No student on this sheet. Please tell the office.';

  @override
  String get noteSaisie => 'Mark entered';

  @override
  String get noteInvalide => 'Enter a number.';

  @override
  String noteTropHaute(String max) {
    return 'The mark cannot exceed $max.';
  }

  @override
  String get enregistrerLesNotes => 'Save the marks';

  @override
  String get aucuneModification => 'No change to save.';

  @override
  String get notesNonEnregistrees => 'Unsaved marks';

  @override
  String get notesNonEnregistreesTexte =>
      'Some marks on this page have not been saved. Discard them?';

  @override
  String get quitterSansEnregistrer => 'Leave without saving';

  @override
  String get enregistrerSansRendre => 'Save without handing in';

  @override
  String get sectionDocumentsDeCours => 'My course documents';

  @override
  String get documentsCoursExplication =>
      'The course plan and materials the office asks you for, course by course. Nothing is visible to students before the office validates it.';

  @override
  String documentsACorriger(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre documents have been sent back to you for correction.',
      one: '1 document has been sent back to you for correction.',
    );
    return '$_temp0';
  }

  @override
  String get aucunDocumentDemande =>
      'No document is requested from you for now. The office opens the expected submissions at the start of the semester.';

  @override
  String get planDeCours => 'Course plan';

  @override
  String get supportDeCours => 'Course materials';

  @override
  String get publieAuxEtudiants => 'Published to students';

  @override
  String get aCorriger => 'To correct';

  @override
  String get transmisAuService => 'Sent to the office';

  @override
  String get fichierRecuPlanATransmettre =>
      'File received — plan to check and send';

  @override
  String get aRemplirEtATransmettre => 'To fill in and send';

  @override
  String get pasEncoreRemis => 'Not yet submitted';

  @override
  String enRetardDeJours(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre days late',
      one: '1 day late',
    );
    return '$_temp0';
  }

  @override
  String get attendu => 'Expected';

  @override
  String get enAttenteDeValidation => 'Awaiting validation';

  @override
  String attenduAvantLe(String date) {
    return 'Expected by $date';
  }

  @override
  String get moratoireAccorde => 'Extension granted';

  @override
  String deposeLeDate(String date) {
    return 'Submitted on $date';
  }

  @override
  String misAJourLeDate(String date) {
    return 'Updated on $date';
  }

  @override
  String renvoyePourCorrectionLe(String date) {
    return 'Sent back for correction on $date';
  }

  @override
  String get fichierSeulNeVautPasDepot =>
      'The file alone does not count as a submission: fill in the plan online, then send it.';

  @override
  String get remplirDepuisFichierDepose =>
      'Fill in the plan from the submitted file';

  @override
  String get deposerLeFichierDuPlan => 'Submit the plan file';

  @override
  String planPagesAuPlus(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: 'A plan is $nombre pages at most.',
      one: 'A plan is 1 page at most.',
    );
    return '$_temp0';
  }

  @override
  String get ouRemplirEnLigne => 'Or fill in online, by hand';

  @override
  String get remplirEnLigne => 'Fill in online';

  @override
  String get modifierLePlanEnLigne => 'Edit the plan online';

  @override
  String get consulter => 'View';

  @override
  String get planPublieModifiable =>
      'Plan validated and published: the office lets you edit it. Students are told of every update.';

  @override
  String get planPublieFige =>
      'Plan validated and published: it can no longer be edited. Contact the office to reopen it.';

  @override
  String get planTransmisExamine =>
      'Plan sent: the office is reviewing it. It will be sent back to you if it needs changes.';

  @override
  String get projetFinDeCours => 'End-of-course project';

  @override
  String get deposerDesFichiers => 'Submit files';

  @override
  String get ajouterDesFichiers => 'Add files';

  @override
  String piecesLimites(int nombre) {
    return '$nombre files at most, 5 MB each. Files are added to those already submitted.';
  }

  @override
  String get commentaireEtProjet => 'Comment and end-of-course project';

  @override
  String get supportPublieModifiable =>
      'Materials validated and published: the office lets you edit them. Students are told of every update.';

  @override
  String get supportPublieFige =>
      'Materials validated and published: they can no longer be edited. Contact the office to reopen the submission.';

  @override
  String get retirerCettePiece => 'Remove this file';

  @override
  String retirerPieceConfirmation(String nom) {
    return 'Remove “$nom” from this submission?';
  }

  @override
  String get projetFinDeCoursQuestion =>
      'This course has a project to submit at the end';

  @override
  String get descriptionDuProjet => 'Project description';

  @override
  String get descriptionDuProjetAide =>
      'Topic, expected deliverables, deadline…';

  @override
  String get remplacerFichierDuProjet => 'Replace the project file';

  @override
  String get fichierDuProjetFacultatif => 'Project file (optional)';

  @override
  String get transmettreLePlan => 'Send the plan';

  @override
  String get transmettrePlanConfirmation =>
      'Once sent, the plan goes to the office and can no longer be edited here. It will be sent back to you if it needs changes.';

  @override
  String get remplacerLaSaisie => 'Replace your entries?';

  @override
  String get remplacerLaSaisieTexte =>
      'The assistant\'s proposal will overwrite lines you have just changed without saving.';

  @override
  String get continuer => 'Continue';

  @override
  String get analyseEnCours =>
      'Analysis in progress — this can take a minute. Do not leave the page.';

  @override
  String get documentAssistantTropLourd =>
      'This document exceeds 10 MB: choose a lighter one.';

  @override
  String get planNonEnregistre => 'Plan not saved';

  @override
  String get planNonEnregistreTexte =>
      'Your plan entries have not been saved. Discard them?';

  @override
  String get planGeneral => 'General';

  @override
  String get travaux => 'Assignments';

  @override
  String seancesProgrammeesSur(int nombre, int total) {
    return '$nombre session(s) scheduled out of $total expected';
  }

  @override
  String get planACorrigerConsigne =>
      'Correct the plan then send it again: the office will be told.';

  @override
  String get planAttendu => 'Plan expected';

  @override
  String planAttenduExplication(int nombre) {
    return 'The academic monitoring office expects this plan: fill in the sections then send it. It has $nombre sessions, all to be scheduled before it can be sent; student assignments are optional. Your plan file is not enough: sending the plan filled in online is what counts as the submission.';
  }

  @override
  String get propositionAVerifier => 'AI assistant\'s proposal — to check';

  @override
  String get propositionAVerifierTexte =>
      'Check each section and correct it if needed: nothing is saved until you press “Save” or “Send”.';

  @override
  String get abandonnerLaProposition => 'Discard the proposal';

  @override
  String get remplirDepuisVotreFichier => 'Fill in from your file';

  @override
  String get assistantPlanExplication =>
      'The AI assistant reads your plan and fills in the objectives, chapters, assignments and session schedule. You check, then save or send: nothing is saved before that. The document is sent to Claude (Anthropic) for analysis.';

  @override
  String extraireContenuDe(String nom) {
    return 'Extract the content of “$nom”';
  }

  @override
  String get analyserUnAutreFichier => 'Analyse another file';

  @override
  String documentSourceDuPlan(String nom, String date) {
    return 'Source document of the pre-fill: $nom, analysed on $date.';
  }

  @override
  String get objectifsDuCours => 'Course objectives';

  @override
  String get objectifsAide =>
      '“By the end of this course, the student will be able to…” — one objective per line.';

  @override
  String get aucunObjectif => 'No objective entered.';

  @override
  String get chapitresAide =>
      'The teaching content, chapter by chapter. A chapter can be chosen in the sessions once it has been saved.';

  @override
  String programmeAide(int nombre) {
    return 'One line per session, from 1 to $nombre. All $nombre sessions are required to send the plan.';
  }

  @override
  String get travauxAide => 'Student assignments: an optional section.';

  @override
  String get rienPourLeMoment => 'Nothing yet.';

  @override
  String get ajouterUnChapitre => 'Add a chapter';

  @override
  String get ajouterUnTravail => 'Add an assignment';

  @override
  String chapitreNumero(String numero, String titre) {
    return 'Chapter $numero: $titre';
  }

  @override
  String get seanceARemplir => 'To fill in';

  @override
  String get aucun => 'None';

  @override
  String get valider => 'Confirm';

  @override
  String get retirerCetteLigne => 'Remove this line';

  @override
  String get numeroAbrege => 'No.';

  @override
  String get intitule => 'Title';

  @override
  String get theme => 'Topic';

  @override
  String get elementsATraiter => 'Items to cover';

  @override
  String get competenceVisee => 'Target skill';

  @override
  String get competences => 'Skills';

  @override
  String get contenus => 'Content';

  @override
  String get lecturePreparatoire => 'Preparatory reading';

  @override
  String get activiteDominante => 'Main activity';

  @override
  String get datePrevue => 'Planned date';

  @override
  String get dateDeRemise => 'Due date';

  @override
  String get bareme => 'Marks';

  @override
  String get sectionEpreuves => 'My exam papers';

  @override
  String get aucuneEpreuveDemandee =>
      'No exam paper is requested from you for the moment. You will be notified as soon as the office opens submissions.';

  @override
  String epreuvesBilan(int demandees, int completes, int retard) {
    return '$demandees requested · $completes complete · $retard late';
  }

  @override
  String get tousMesModeles => 'All my exam paper templates (ZIP)';

  @override
  String get depotAttendu => 'Submission expected';

  @override
  String get sujetsAcceptes => 'Papers accepted';

  @override
  String get aReprendre => 'To rework';

  @override
  String sujetsCompletsSur(int completes, int requis) {
    return '$completes complete paper(s) out of $requis';
  }

  @override
  String aDeposerAvant(String date) {
    return 'To submit by $date';
  }

  @override
  String get motifDeReprise => 'Reason for rework';

  @override
  String get sujetFrancaisAnglais => 'Paper in French and English';

  @override
  String get sujetFrancaisAnglaisTexte =>
      'This exam is sat by the French-speaking and English-speaking classes: each paper is submitted in both languages, and the submission is complete only once both versions are in.';

  @override
  String get consignesDuService => 'Instructions from the office';

  @override
  String sujetNumero(int numero) {
    return 'Paper no. $numero';
  }

  @override
  String get accepte => 'Accepted';

  @override
  String get modeleARemplir => 'Template to fill in';

  @override
  String get anglaisWord => 'English (Word)';

  @override
  String get francaisWord => 'French (Word)';

  @override
  String sujetVersion(String version) {
    return 'Paper — $version';
  }

  @override
  String get sujet => 'Paper';

  @override
  String get corrige => 'Answer key';

  @override
  String get manquantExige => 'Missing, required';

  @override
  String get facultatifPourCetteCampagne => 'Optional for this campaign';

  @override
  String get sujetAccepteFige =>
      'Paper accepted by the office: it can no longer be changed.';

  @override
  String get depotClos => 'Submissions are closed for this campaign.';

  @override
  String get ajouterOuModifier => 'Add files or edit';

  @override
  String get deposerCeSujet => 'Submit this paper';

  @override
  String get deposer => 'Submit';

  @override
  String get piecesSajoutent =>
      'Question paper, appendices, data set: submit each file. Files are added, none is replaced.';

  @override
  String formatsAcceptes(String formats) {
    return 'Accepted formats: $formats.';
  }

  @override
  String get intituleDuSujetFacultatif => 'Paper title (optional)';

  @override
  String get fichiersDuSujet => 'Paper files';

  @override
  String get fichiersSujetFrancais => 'Paper files — French version';

  @override
  String get fichiersSujetAnglais => 'Paper files — English version';

  @override
  String get memeSujetTraduit =>
      'The same paper, translated for the English-speaking class.';

  @override
  String get fichiersCorrigeExige => 'Answer key files (required)';

  @override
  String get fichiersCorrigeFacultatif => 'Answer key files (optional)';

  @override
  String get dureeProposeeMinutes => 'Proposed duration (min)';

  @override
  String get commentaireSujetAide => 'Permitted materials, remarks…';

  @override
  String get informationsPersonnelles => 'Personal information';

  @override
  String get coordonneesEtUrgence => 'Contact details and emergency contact';

  @override
  String get informationsProfessionnelles => 'Professional information';

  @override
  String get dossierAideProfessionnel =>
      'Your academic background determines which courses can be assigned to you; the office revalidates your fields after any change.';

  @override
  String get dossierTenuParLeService =>
      'The academic monitoring office is informed of your changes. Rank, department, fields and courses are set by the office: contact it if any of them is wrong.';

  @override
  String get ajouterUnDiplome => 'Add a degree';

  @override
  String get modifierLeDiplome => 'Edit degree';

  @override
  String get ajouterUneCertification => 'Add a certification';

  @override
  String get modifierLaCertification => 'Edit certification';

  @override
  String get ajouterUneExperience => 'Add an experience';

  @override
  String get modifierLExperience => 'Edit experience';

  @override
  String get supprimerCetteLigne => 'Delete this entry?';

  @override
  String get supprimerCetteLigneTexte =>
      'It will be removed from your file, along with its supporting document.';

  @override
  String get changerLaPhoto => 'Change photo';

  @override
  String get ajouterUnePhoto => 'Add a photo';

  @override
  String get photoDossierAide => 'Recent ID photo, in JPG or PNG format.';

  @override
  String get pieceDejaDeposee =>
      'A file is already on record: choose another one to replace it.';

  @override
  String get retirerLeFichierActuel => 'Remove the current file';

  @override
  String get fichierRetireALEnregistrement =>
      'The current file will be removed when you save.';

  @override
  String get conserverLeFichier => 'Keep it';

  @override
  String get effacerLaSelection => 'Clear selection';

  @override
  String get rechercherDansLaListe => 'Search the list';

  @override
  String get aucunChoixTrouve => 'No matching choice.';

  @override
  String get cursusAcademique => 'Academic background';

  @override
  String get telephoneSecondaire => 'Second phone';

  @override
  String get disponibleHorsLigne => 'Available offline';

  @override
  String get horsLigne => 'Offline';

  @override
  String get envoyerMaintenant => 'Send now';

  @override
  String get saisieEnAttenteEnvoi => 'On this phone, waiting to be sent';

  @override
  String get saisieTransmise => 'Sent';

  @override
  String get saisieAArbitrer => 'Awaiting a decision from the office';

  @override
  String get saisieEcartee => 'Set aside by the office';

  @override
  String get saisieRefusee => 'Refused, to be redone';

  @override
  String get saisieGardeeSurLeTelephone =>
      'Saved on this phone. It will be sent automatically as soon as the network is back.';

  @override
  String get saisieTransmiseAuService =>
      'Sent to the office, which will decide.';

  @override
  String get saisieEnregistree => 'Saved and sent.';

  @override
  String horsLigneJusquAu(String date) {
    return 'Until $date';
  }

  @override
  String horsLigneMisAJour(String date) {
    return 'Updated on $date';
  }

  @override
  String saisiesAEnvoyer(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre entries to send',
      one: '1 entry to send',
    );
    return '$_temp0';
  }

  @override
  String deconnexionAvecSaisies(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other:
          '$nombre entries have not been sent yet: they will wait for your next sign-in and will not be sent until then. Sign out anyway?',
      one:
          '1 entry has not been sent yet: it will wait for your next sign-in and will not be sent until then. Sign out anyway?',
    );
    return '$_temp0';
  }

  @override
  String positionTropImprecise(int precision, int max) {
    return 'Position too imprecise ($precision m, $max m at most). Move closer to a window or go outside, then try again.';
  }

  @override
  String get payerParMobileMoney => 'Pay by Mobile Money';

  @override
  String get paiementsMobileMoney => 'Mobile Money payments';

  @override
  String get paiementMobileMoney => 'Mobile Money payment';

  @override
  String get payerCetteTranche => 'Pay this instalment';

  @override
  String get mobileMoneyFerme =>
      'Mobile Money payment is not open at the moment.';

  @override
  String get mobileMoneyTest =>
      'Test environment: no real money is charged. Only test numbers are accepted: 670000000 (MTN) and 690000000 (Orange) succeed, 670000001 (MTN) and 690000001 (Orange) fail.';

  @override
  String get montantPayableMaintenant => 'Amount payable now';

  @override
  String get rienAPayerMobile =>
      'Nothing is left to pay for the year, payments under review included.';

  @override
  String get operateur => 'Operator';

  @override
  String get choisirOperateur => 'Choose the operator.';

  @override
  String get numeroMobileMoney => 'Mobile Money number';

  @override
  String get numeroMobileMoneyAide =>
      'The number that will be charged: yours, or that of whoever is paying for you.';

  @override
  String get numeroMobileMoneyInvalide =>
      'Enter a nine-digit Cameroonian number starting with 6.';

  @override
  String get montantARegler => 'Amount to pay';

  @override
  String get montantRegle => 'Amount paid';

  @override
  String get fraisDeTransaction => 'Transaction fees';

  @override
  String get totalDebite => 'Total charged';

  @override
  String get lancerLePaiement => 'Start the payment';

  @override
  String get inviteTelephone =>
      'A prompt will appear on the phone: confirm it with your secret code.';

  @override
  String get paiementDejaEnCours =>
      'A payment is awaiting its outcome. You can start another one afterwards.';

  @override
  String get suivreLePaiement => 'Follow the payment';

  @override
  String get reponsePerdue =>
      'The server\'s reply did not arrive: the payment may have gone through. Check below and on your phone before trying again.';

  @override
  String get aucunPaiementMobile => 'No Mobile Money payment this year.';

  @override
  String get quitterEcranPaiement =>
      'You can leave this screen: the payment continues, and a notification will tell you how it ends.';

  @override
  String get annulerLePaiement => 'Cancel the payment';

  @override
  String get paiementAnnule => 'The payment is cancelled: nothing was charged.';

  @override
  String lancePar(String nom) {
    return 'Started by $nom';
  }

  @override
  String annulerPaiementConfirmation(String reference) {
    return 'Give up payment $reference? Nothing will be charged.';
  }
}
