import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'YSEM'**
  String get appTitle;

  /// No description provided for @bienvenue.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue à YSEM'**
  String get bienvenue;

  /// No description provided for @choisirEspace.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre espace pour continuer.'**
  String get choisirEspace;

  /// No description provided for @espaceEtudiant.
  ///
  /// In fr, this message translates to:
  /// **'Espace étudiant'**
  String get espaceEtudiant;

  /// No description provided for @espaceEtudiantDescription.
  ///
  /// In fr, this message translates to:
  /// **'Emploi du temps, notes, finances et documents.'**
  String get espaceEtudiantDescription;

  /// No description provided for @espaceEnseignant.
  ///
  /// In fr, this message translates to:
  /// **'Espace enseignant'**
  String get espaceEnseignant;

  /// No description provided for @espaceEnseignantDescription.
  ///
  /// In fr, this message translates to:
  /// **'Cours, séances, notes et vacations.'**
  String get espaceEnseignantDescription;

  /// No description provided for @bientotDisponible.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get bientotDisponible;

  /// No description provided for @connexion.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get connexion;

  /// No description provided for @seConnecter.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get seConnecter;

  /// No description provided for @deconnexion.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get deconnexion;

  /// No description provided for @deconnexionConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Vous devrez saisir à nouveau votre matricule et votre mot de passe pour revenir.'**
  String get deconnexionConfirmation;

  /// No description provided for @connexionEtudiantConsigne.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous avec votre matricule et le mot de passe du portail étudiant.'**
  String get connexionEtudiantConsigne;

  /// No description provided for @connexionAide.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ou accès non configuré ? Rapprochez-vous de la scolarité.'**
  String get connexionAide;

  /// No description provided for @matricule.
  ///
  /// In fr, this message translates to:
  /// **'Matricule'**
  String get matricule;

  /// No description provided for @motDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get motDePasse;

  /// No description provided for @afficher.
  ///
  /// In fr, this message translates to:
  /// **'Afficher'**
  String get afficher;

  /// No description provided for @masquer.
  ///
  /// In fr, this message translates to:
  /// **'Masquer'**
  String get masquer;

  /// No description provided for @champObligatoire.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire.'**
  String get champObligatoire;

  /// No description provided for @verificationTitre.
  ///
  /// In fr, this message translates to:
  /// **'Vérification'**
  String get verificationTitre;

  /// No description provided for @verificationConsigne.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code à six chiffres reçu par e-mail.'**
  String get verificationConsigne;

  /// No description provided for @verificationConsigneAdresse.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code à six chiffres envoyé à {adresse}.'**
  String verificationConsigneAdresse(String adresse);

  /// No description provided for @verificationAide.
  ///
  /// In fr, this message translates to:
  /// **'Pensez à vérifier vos courriers indésirables.'**
  String get verificationAide;

  /// No description provided for @codeVerification.
  ///
  /// In fr, this message translates to:
  /// **'Code de vérification'**
  String get codeVerification;

  /// No description provided for @codeExpireDans.
  ///
  /// In fr, this message translates to:
  /// **'Le code expire dans {duree}'**
  String codeExpireDans(String duree);

  /// No description provided for @codeExpire.
  ///
  /// In fr, this message translates to:
  /// **'Le code a expiré : demandez-en un nouveau.'**
  String get codeExpire;

  /// No description provided for @verifier.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get verifier;

  /// No description provided for @renvoyerCode.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get renvoyerCode;

  /// No description provided for @tentativesRestantes.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{Encore 1 essai.} other{Encore {nombre} essais.}}'**
  String tentativesRestantes(int nombre);

  /// No description provided for @changerMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get changerMotDePasse;

  /// No description provided for @motDePasseImposeConsigne.
  ///
  /// In fr, this message translates to:
  /// **'Pour votre sécurité, choisissez un nouveau mot de passe avant de continuer.'**
  String get motDePasseImposeConsigne;

  /// No description provided for @motDePasseVolontaireConsigne.
  ///
  /// In fr, this message translates to:
  /// **'Le nouveau mot de passe vaut aussi pour le portail web.'**
  String get motDePasseVolontaireConsigne;

  /// No description provided for @motDePasseActuel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get motDePasseActuel;

  /// No description provided for @nouveauMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get nouveauMotDePasse;

  /// No description provided for @confirmationMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le nouveau mot de passe'**
  String get confirmationMotDePasse;

  /// No description provided for @confirmationDifferente.
  ///
  /// In fr, this message translates to:
  /// **'Les deux mots de passe ne correspondent pas.'**
  String get confirmationDifferente;

  /// No description provided for @enregistrer.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get enregistrer;

  /// No description provided for @annuler.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get annuler;

  /// No description provided for @confirmer.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirmer;

  /// No description provided for @ongletAccueil.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get ongletAccueil;

  /// No description provided for @ongletServices.
  ///
  /// In fr, this message translates to:
  /// **'Services'**
  String get ongletServices;

  /// No description provided for @ongletNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get ongletNotifications;

  /// No description provided for @ongletProfil.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get ongletProfil;

  /// No description provided for @bonjour.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, {nom}'**
  String bonjour(String nom);

  /// No description provided for @situationFinanciere.
  ///
  /// In fr, this message translates to:
  /// **'Situation financière'**
  String get situationFinanciere;

  /// No description provided for @montantPaye.
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get montantPaye;

  /// No description provided for @resteAPayer.
  ///
  /// In fr, this message translates to:
  /// **'Reste à payer'**
  String get resteAPayer;

  /// No description provided for @montantEchu.
  ///
  /// In fr, this message translates to:
  /// **'Échu'**
  String get montantEchu;

  /// No description provided for @prochainesSeances.
  ///
  /// In fr, this message translates to:
  /// **'Prochaines séances'**
  String get prochainesSeances;

  /// No description provided for @aucuneSeance.
  ///
  /// In fr, this message translates to:
  /// **'Aucune séance à venir cette semaine.'**
  String get aucuneSeance;

  /// No description provided for @datesAVenir.
  ///
  /// In fr, this message translates to:
  /// **'Dates à venir'**
  String get datesAVenir;

  /// No description provided for @aucuneDate.
  ///
  /// In fr, this message translates to:
  /// **'Aucune date annoncée au calendrier.'**
  String get aucuneDate;

  /// No description provided for @documentsRecents.
  ///
  /// In fr, this message translates to:
  /// **'Documents récents'**
  String get documentsRecents;

  /// No description provided for @aucunDocument.
  ///
  /// In fr, this message translates to:
  /// **'Aucun document pour le moment.'**
  String get aucunDocument;

  /// No description provided for @toutVoir.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get toutVoir;

  /// No description provided for @seanceAnnulee.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get seanceAnnulee;

  /// No description provided for @seanceChomee.
  ///
  /// In fr, this message translates to:
  /// **'Jour chômé'**
  String get seanceChomee;

  /// No description provided for @seanceRattrapage.
  ///
  /// In fr, this message translates to:
  /// **'Rattrapage'**
  String get seanceRattrapage;

  /// No description provided for @seanceTroncCommun.
  ///
  /// In fr, this message translates to:
  /// **'Tronc commun'**
  String get seanceTroncCommun;

  /// No description provided for @notificationsNonLues.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{1 notification non lue} other{{nombre} notifications non lues}}'**
  String notificationsNonLues(int nombre);

  /// No description provided for @informations.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get informations;

  /// No description provided for @aucuneInformation.
  ///
  /// In fr, this message translates to:
  /// **'Aucune information au dossier.'**
  String get aucuneInformation;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get email;

  /// No description provided for @telephone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get telephone;

  /// No description provided for @dateNaissance.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance'**
  String get dateNaissance;

  /// No description provided for @genre.
  ///
  /// In fr, this message translates to:
  /// **'Genre'**
  String get genre;

  /// No description provided for @residence.
  ///
  /// In fr, this message translates to:
  /// **'Résidence'**
  String get residence;

  /// No description provided for @statut.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get statut;

  /// No description provided for @securite.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité du compte'**
  String get securite;

  /// No description provided for @doubleAuthentification.
  ///
  /// In fr, this message translates to:
  /// **'Double authentification'**
  String get doubleAuthentification;

  /// No description provided for @doubleAuthentificationAide.
  ///
  /// In fr, this message translates to:
  /// **'Un code envoyé par e-mail est demandé à chaque connexion.'**
  String get doubleAuthentificationAide;

  /// No description provided for @activerDoubleAuthentification.
  ///
  /// In fr, this message translates to:
  /// **'Activer la double authentification'**
  String get activerDoubleAuthentification;

  /// No description provided for @desactiverDoubleAuthentification.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver la double authentification'**
  String get desactiverDoubleAuthentification;

  /// No description provided for @confirmerParMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez avec votre mot de passe.'**
  String get confirmerParMotDePasse;

  /// No description provided for @langue.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get langue;

  /// No description provided for @langueAide.
  ///
  /// In fr, this message translates to:
  /// **'Votre choix vaut aussi pour le portail web.'**
  String get langueAide;

  /// No description provided for @connexionsRecentes.
  ///
  /// In fr, this message translates to:
  /// **'Connexions récentes'**
  String get connexionsRecentes;

  /// No description provided for @aImplementer.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt dans l\'application'**
  String get aImplementer;

  /// No description provided for @aImplementerDetail.
  ///
  /// In fr, this message translates to:
  /// **'En attendant, cette rubrique reste disponible sur le portail web.'**
  String get aImplementerDetail;

  /// No description provided for @chargement.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get chargement;

  /// No description provided for @reessayer.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get reessayer;

  /// No description provided for @erreurInattendue.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur inattendue est survenue.'**
  String get erreurInattendue;

  /// No description provided for @notificationsToutes.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get notificationsToutes;

  /// No description provided for @notificationsFiltreNonLues.
  ///
  /// In fr, this message translates to:
  /// **'Non lues'**
  String get notificationsFiltreNonLues;

  /// No description provided for @toutMarquerLu.
  ///
  /// In fr, this message translates to:
  /// **'Tout marquer comme lu'**
  String get toutMarquerLu;

  /// No description provided for @aucuneNotification.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification pour l\'instant.'**
  String get aucuneNotification;

  /// No description provided for @aucuneNotificationNonLue.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez tout lu.'**
  String get aucuneNotificationNonLue;

  /// No description provided for @marquerLue.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme lue'**
  String get marquerLue;

  /// No description provided for @marquerNonLue.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme non lue'**
  String get marquerNonLue;

  /// No description provided for @supprimer.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get supprimer;

  /// No description provided for @notificationSupprimee.
  ///
  /// In fr, this message translates to:
  /// **'Notification supprimée.'**
  String get notificationSupprimee;

  /// No description provided for @ouvrir.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get ouvrir;

  /// No description provided for @fermer.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get fermer;

  /// No description provided for @emploiDuTemps.
  ///
  /// In fr, this message translates to:
  /// **'Emploi du temps'**
  String get emploiDuTemps;

  /// No description provided for @calendrier.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get calendrier;

  /// No description provided for @parcours.
  ///
  /// In fr, this message translates to:
  /// **'Parcours'**
  String get parcours;

  /// No description provided for @semainePrecedente.
  ///
  /// In fr, this message translates to:
  /// **'Semaine précédente'**
  String get semainePrecedente;

  /// No description provided for @semaineSuivante.
  ///
  /// In fr, this message translates to:
  /// **'Semaine suivante'**
  String get semaineSuivante;

  /// No description provided for @cetteSemaine.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get cetteSemaine;

  /// No description provided for @semaineDuAu.
  ///
  /// In fr, this message translates to:
  /// **'Du {debut} au {fin}'**
  String semaineDuAu(String debut, String fin);

  /// No description provided for @seancesDeLaSemaine.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune séance} =1{1 séance} other{{count} séances}}'**
  String seancesDeLaSemaine(int count);

  /// No description provided for @aucuneSeanceSemaine.
  ///
  /// In fr, this message translates to:
  /// **'Aucune séance prévue cette semaine.'**
  String get aucuneSeanceSemaine;

  /// No description provided for @datesPassees.
  ///
  /// In fr, this message translates to:
  /// **'Dates passées'**
  String get datesPassees;

  /// No description provided for @aucunEvenement.
  ///
  /// In fr, this message translates to:
  /// **'Aucune date publiée au calendrier.'**
  String get aucunEvenement;

  /// No description provided for @aucunParcours.
  ///
  /// In fr, this message translates to:
  /// **'Aucune inscription enregistrée.'**
  String get aucunParcours;

  /// No description provided for @inscriptionCourante.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get inscriptionCourante;

  /// No description provided for @inscriptionNonFinalisee.
  ///
  /// In fr, this message translates to:
  /// **'Inscription non finalisée'**
  String get inscriptionNonFinalisee;

  /// No description provided for @notesEnAttenteJury.
  ///
  /// In fr, this message translates to:
  /// **'En attente du jury'**
  String get notesEnAttenteJury;

  /// No description provided for @aucuneNote.
  ///
  /// In fr, this message translates to:
  /// **'Aucune note publiée pour cette année.'**
  String get aucuneNote;

  /// No description provided for @moyenne.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne'**
  String get moyenne;

  /// No description provided for @credits.
  ///
  /// In fr, this message translates to:
  /// **'Crédits'**
  String get credits;

  /// No description provided for @creditsDuCours.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 crédit} other{{count} crédits}}'**
  String creditsDuCours(int count);

  /// No description provided for @rang.
  ///
  /// In fr, this message translates to:
  /// **'Rang'**
  String get rang;

  /// No description provided for @resultatAnnuel.
  ///
  /// In fr, this message translates to:
  /// **'Résultat de l\'année'**
  String get resultatAnnuel;

  /// No description provided for @resultatSession.
  ///
  /// In fr, this message translates to:
  /// **'Résultat · {session}'**
  String resultatSession(String session);

  /// No description provided for @sessionNormale.
  ///
  /// In fr, this message translates to:
  /// **'Session normale'**
  String get sessionNormale;

  /// No description provided for @sessionRattrapage.
  ///
  /// In fr, this message translates to:
  /// **'Rattrapage'**
  String get sessionRattrapage;

  /// No description provided for @coursARepasser.
  ///
  /// In fr, this message translates to:
  /// **'Cours à repasser'**
  String get coursARepasser;

  /// No description provided for @relevesDeNotes.
  ///
  /// In fr, this message translates to:
  /// **'Relevés de notes'**
  String get relevesDeNotes;

  /// No description provided for @releveNumero.
  ///
  /// In fr, this message translates to:
  /// **'Relevé n° {numero}'**
  String releveNumero(String numero);

  /// No description provided for @releveEmisLe.
  ///
  /// In fr, this message translates to:
  /// **'Version {version} · émis le {date}'**
  String releveEmisLe(String version, String date);

  /// No description provided for @relevesAuGuichet.
  ///
  /// In fr, this message translates to:
  /// **'Les relevés se retirent auprès de la scolarité.'**
  String get relevesAuGuichet;

  /// No description provided for @notesAvantJury.
  ///
  /// In fr, this message translates to:
  /// **'Les notes de cours s\'affichent une fois les résultats du jury publiés. En attendant, seules les épreuves validées par le service sont visibles.'**
  String get notesAvantJury;

  /// No description provided for @anneeAcademique.
  ///
  /// In fr, this message translates to:
  /// **'Année académique'**
  String get anneeAcademique;

  /// No description provided for @totalDu.
  ///
  /// In fr, this message translates to:
  /// **'Total dû'**
  String get totalDu;

  /// No description provided for @echeancier.
  ///
  /// In fr, this message translates to:
  /// **'Échéancier'**
  String get echeancier;

  /// No description provided for @aucuneTranche.
  ///
  /// In fr, this message translates to:
  /// **'Aucune échéance définie pour cette année.'**
  String get aucuneTranche;

  /// No description provided for @echeanceLe.
  ///
  /// In fr, this message translates to:
  /// **'Échéance le {date}'**
  String echeanceLe(String date);

  /// No description provided for @payeSur.
  ///
  /// In fr, this message translates to:
  /// **'{paye} payés sur {montant}'**
  String payeSur(String paye, String montant);

  /// No description provided for @couverteParMoratoire.
  ///
  /// In fr, this message translates to:
  /// **'Couverte par un moratoire'**
  String get couverteParMoratoire;

  /// No description provided for @paiements.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get paiements;

  /// No description provided for @aucunPaiement.
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement enregistré pour cette année.'**
  String get aucunPaiement;

  /// No description provided for @moratoiresAccordes.
  ///
  /// In fr, this message translates to:
  /// **'Moratoires accordés'**
  String get moratoiresAccordes;

  /// No description provided for @demandeMoratoireEnCours.
  ///
  /// In fr, this message translates to:
  /// **'Demande de moratoire en cours d\'examen'**
  String get demandeMoratoireEnCours;

  /// No description provided for @telechargerRecu.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le reçu'**
  String get telechargerRecu;

  /// No description provided for @telechargerReleve.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le relevé de compte'**
  String get telechargerReleve;

  /// No description provided for @telechargementEnCours.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement…'**
  String get telechargementEnCours;

  /// No description provided for @ouvertureImpossible.
  ///
  /// In fr, this message translates to:
  /// **'Aucune application ne permet d\'ouvrir ce document.'**
  String get ouvertureImpossible;

  /// No description provided for @aucuneSituation.
  ///
  /// In fr, this message translates to:
  /// **'Aucune situation financière pour cette année.'**
  String get aucuneSituation;

  /// No description provided for @sectionScolarite.
  ///
  /// In fr, this message translates to:
  /// **'Ma scolarité'**
  String get sectionScolarite;

  /// No description provided for @sectionNotes.
  ///
  /// In fr, this message translates to:
  /// **'Mes notes'**
  String get sectionNotes;

  /// No description provided for @sectionFinances.
  ///
  /// In fr, this message translates to:
  /// **'Ma situation financière'**
  String get sectionFinances;

  /// No description provided for @sectionDocuments.
  ///
  /// In fr, this message translates to:
  /// **'Mes documents'**
  String get sectionDocuments;

  /// No description provided for @sectionExamens.
  ///
  /// In fr, this message translates to:
  /// **'Planning des examens'**
  String get sectionExamens;

  /// No description provided for @sectionSupports.
  ///
  /// In fr, this message translates to:
  /// **'Mes supports de cours'**
  String get sectionSupports;

  /// No description provided for @sectionDiscipline.
  ///
  /// In fr, this message translates to:
  /// **'Ma discipline'**
  String get sectionDiscipline;

  /// No description provided for @aucunDocumentDossier.
  ///
  /// In fr, this message translates to:
  /// **'Aucun document officiel dans votre dossier.'**
  String get aucunDocumentDossier;

  /// No description provided for @documentsAuGuichet.
  ///
  /// In fr, this message translates to:
  /// **'Les autres documents se retirent auprès de la scolarité.'**
  String get documentsAuGuichet;

  /// No description provided for @documentEtabliLe.
  ///
  /// In fr, this message translates to:
  /// **'Établi le {date}'**
  String documentEtabliLe(String date);

  /// No description provided for @documentRetireLe.
  ///
  /// In fr, this message translates to:
  /// **'Retiré le {date}'**
  String documentRetireLe(String date);

  /// No description provided for @telechargerCertificat.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le certificat'**
  String get telechargerCertificat;

  /// No description provided for @certificatIndisponible.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement indisponible'**
  String get certificatIndisponible;

  /// No description provided for @aucunPlanning.
  ///
  /// In fr, this message translates to:
  /// **'Aucun planning d\'examens publié pour votre classe.'**
  String get aucunPlanning;

  /// No description provided for @planningEnCours.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get planningEnCours;

  /// No description provided for @planningTermine.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get planningTermine;

  /// No description provided for @planningAVenir.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get planningAVenir;

  /// No description provided for @nbEpreuves.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune épreuve} =1{1 épreuve} other{{count} épreuves}}'**
  String nbEpreuves(int count);

  /// No description provided for @telechargerPlanning.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le planning (PDF)'**
  String get telechargerPlanning;

  /// No description provided for @pause.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @epreuveConcernee.
  ///
  /// In fr, this message translates to:
  /// **'Vous composez'**
  String get epreuveConcernee;

  /// No description provided for @aucunSupport.
  ///
  /// In fr, this message translates to:
  /// **'Aucun plan ni support de cours publié pour l\'instant.'**
  String get aucunSupport;

  /// No description provided for @supportsATelecharger.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Tout est téléchargé} =1{1 document à télécharger} other{{count} documents à télécharger}}'**
  String supportsATelecharger(int count);

  /// No description provided for @nouvelleVersion.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle version'**
  String get nouvelleVersion;

  /// No description provided for @telecharge.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargé'**
  String get telecharge;

  /// No description provided for @telechargeLe.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargé le {date}'**
  String telechargeLe(String date);

  /// No description provided for @aTelecharger.
  ///
  /// In fr, this message translates to:
  /// **'À télécharger'**
  String get aTelecharger;

  /// No description provided for @nbFichiers.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 fichier} other{{count} fichiers}}'**
  String nbFichiers(int count);

  /// No description provided for @publieLe.
  ///
  /// In fr, this message translates to:
  /// **'Publié le {date}'**
  String publieLe(String date);

  /// No description provided for @misAJourLe.
  ///
  /// In fr, this message translates to:
  /// **'Mis à jour le {date}'**
  String misAJourLe(String date);

  /// No description provided for @telecharger.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get telecharger;

  /// No description provided for @aucunDossierDiscipline.
  ///
  /// In fr, this message translates to:
  /// **'Aucun suivi d\'assiduité pour cette année.'**
  String get aucunDossierDiscipline;

  /// No description provided for @tauxPresence.
  ///
  /// In fr, this message translates to:
  /// **'Taux de présence'**
  String get tauxPresence;

  /// No description provided for @seancesPrevuesNombre.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune séance prévue à ce jour} =1{1 séance prévue à ce jour} other{{count} séances prévues à ce jour}}'**
  String seancesPrevuesNombre(int count);

  /// No description provided for @seuilExamens.
  ///
  /// In fr, this message translates to:
  /// **'Seuil d\'accès aux examens : {seuil}'**
  String seuilExamens(String seuil);

  /// No description provided for @absences.
  ///
  /// In fr, this message translates to:
  /// **'Absences'**
  String get absences;

  /// No description provided for @retards.
  ///
  /// In fr, this message translates to:
  /// **'Retards'**
  String get retards;

  /// No description provided for @absencesNonJustifiees.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{toutes justifiées} =1{dont 1 non justifiée} other{dont {count} non justifiées}}'**
  String absencesNonJustifiees(int count);

  /// No description provided for @retardsNonJustifies.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{tous justifiés} =1{dont 1 non justifié} other{dont {count} non justifiés}}'**
  String retardsNonJustifies(int count);

  /// No description provided for @assiduiteParException.
  ///
  /// In fr, this message translates to:
  /// **'Une partie de vos séances a été relevée par exception (seuls les manquements sont saisis) : le taux se lit avec prudence.'**
  String get assiduiteParException;

  /// No description provided for @assiduiteParCours.
  ///
  /// In fr, this message translates to:
  /// **'Assiduité par cours'**
  String get assiduiteParCours;

  /// No description provided for @absencesSurSeances.
  ///
  /// In fr, this message translates to:
  /// **'{absences, plural, =0{Aucune absence} =1{1 absence} other{{absences} absences}} sur {seances}'**
  String absencesSurSeances(int absences, int seances);

  /// No description provided for @absencesEtRetards.
  ///
  /// In fr, this message translates to:
  /// **'Absences et retards'**
  String get absencesEtRetards;

  /// No description provided for @aucunManquement.
  ///
  /// In fr, this message translates to:
  /// **'Aucune absence ni aucun retard relevé cette année.'**
  String get aucunManquement;

  /// No description provided for @minutesDeRetard.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 minute de retard} other{{count} minutes de retard}}'**
  String minutesDeRetard(int count);

  /// No description provided for @justificatifAvant.
  ///
  /// In fr, this message translates to:
  /// **'Justificatif à produire avant le {date}'**
  String justificatifAvant(String date);

  /// No description provided for @sanctions.
  ///
  /// In fr, this message translates to:
  /// **'Sanctions'**
  String get sanctions;

  /// No description provided for @aCompterDu.
  ///
  /// In fr, this message translates to:
  /// **'À compter du {date}'**
  String aCompterDu(String date);

  /// No description provided for @tenueVestimentaire.
  ///
  /// In fr, this message translates to:
  /// **'Tenue vestimentaire'**
  String get tenueVestimentaire;

  /// No description provided for @aRegulariserAvant.
  ///
  /// In fr, this message translates to:
  /// **'À régulariser avant le {date}'**
  String aRegulariserAvant(String date);

  /// No description provided for @sectionMoratoires.
  ///
  /// In fr, this message translates to:
  /// **'Mes moratoires'**
  String get sectionMoratoires;

  /// No description provided for @sectionPermissions.
  ///
  /// In fr, this message translates to:
  /// **'Mes permissions'**
  String get sectionPermissions;

  /// No description provided for @mesDemandes.
  ///
  /// In fr, this message translates to:
  /// **'Mes demandes'**
  String get mesDemandes;

  /// No description provided for @nouvelleDemande.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle demande'**
  String get nouvelleDemande;

  /// No description provided for @demandeMoratoire.
  ///
  /// In fr, this message translates to:
  /// **'Demande de moratoire'**
  String get demandeMoratoire;

  /// No description provided for @nouvelleDemandeMoratoire.
  ///
  /// In fr, this message translates to:
  /// **'Demander un moratoire'**
  String get nouvelleDemandeMoratoire;

  /// No description provided for @aucuneDemandeMoratoire.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez déposé aucune demande de moratoire.'**
  String get aucuneDemandeMoratoire;

  /// No description provided for @montantDemandable.
  ///
  /// In fr, this message translates to:
  /// **'Montant qui peut encore être couvert'**
  String get montantDemandable;

  /// No description provided for @moratoireExplication.
  ///
  /// In fr, this message translates to:
  /// **'Un moratoire repousse le règlement d\'une partie de ce que vous devez. Votre demande ne change rien à votre situation tant que la scolarité ne l\'a pas acceptée.'**
  String get moratoireExplication;

  /// No description provided for @moratoireAttendreDecision.
  ///
  /// In fr, this message translates to:
  /// **'La demande {reference} est en cours d\'examen : attendez la décision de la scolarité avant d\'en déposer une autre.'**
  String moratoireAttendreDecision(String reference);

  /// No description provided for @moratoireRienACouvrir.
  ///
  /// In fr, this message translates to:
  /// **'Votre situation ne laisse aucun montant à couvrir : une demande de moratoire est sans objet pour cette année.'**
  String get moratoireRienACouvrir;

  /// No description provided for @moratoireSansAnnee.
  ///
  /// In fr, this message translates to:
  /// **'Aucune année académique n\'est ouverte : rapprochez-vous de la scolarité.'**
  String get moratoireSansAnnee;

  /// No description provided for @montantSollicite.
  ///
  /// In fr, this message translates to:
  /// **'Montant sollicité'**
  String get montantSollicite;

  /// No description provided for @auPlus.
  ///
  /// In fr, this message translates to:
  /// **'Au plus {montant}'**
  String auPlus(String montant);

  /// No description provided for @tout.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get tout;

  /// No description provided for @montantInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un montant supérieur à zéro.'**
  String get montantInvalide;

  /// No description provided for @dateReglementSouhaitee.
  ///
  /// In fr, this message translates to:
  /// **'Date de règlement souhaitée'**
  String get dateReglementSouhaitee;

  /// No description provided for @dateRequise.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une date.'**
  String get dateRequise;

  /// No description provided for @reglementSouhaiteLe.
  ///
  /// In fr, this message translates to:
  /// **'Règlement souhaité le {date}'**
  String reglementSouhaiteLe(String date);

  /// No description provided for @motifDeLaDemande.
  ///
  /// In fr, this message translates to:
  /// **'Motif de la demande'**
  String get motifDeLaDemande;

  /// No description provided for @motifMoratoireAide.
  ///
  /// In fr, this message translates to:
  /// **'Expliquez votre situation (retard de bourse, difficulté familiale…)'**
  String get motifMoratoireAide;

  /// No description provided for @motifRequis.
  ///
  /// In fr, this message translates to:
  /// **'Expliquez votre demande.'**
  String get motifRequis;

  /// No description provided for @pieceJustificativeFacultative.
  ///
  /// In fr, this message translates to:
  /// **'Pièce justificative (facultative)'**
  String get pieceJustificativeFacultative;

  /// No description provided for @pieceJustificativeObligatoire.
  ///
  /// In fr, this message translates to:
  /// **'Pièce justificative (obligatoire pour une absence)'**
  String get pieceJustificativeObligatoire;

  /// No description provided for @formatsPieces.
  ///
  /// In fr, this message translates to:
  /// **'PDF ou photo (JPG, PNG), 5 Mo au plus.'**
  String get formatsPieces;

  /// No description provided for @choisirFichier.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un fichier'**
  String get choisirFichier;

  /// No description provided for @remplacerFichier.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer'**
  String get remplacerFichier;

  /// No description provided for @retirerFichier.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le fichier'**
  String get retirerFichier;

  /// No description provided for @pieceTropLourde.
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier dépasse 5 Mo : choisissez-en un plus léger.'**
  String get pieceTropLourde;

  /// No description provided for @pieceJointeFournie.
  ///
  /// In fr, this message translates to:
  /// **'Pièce justificative jointe'**
  String get pieceJointeFournie;

  /// No description provided for @envoyerDemande.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la demande'**
  String get envoyerDemande;

  /// No description provided for @envoyerDemandeSeances.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Envoyer la demande (1 séance)} other{Envoyer la demande ({n} séances)}}'**
  String envoyerDemandeSeances(int n);

  /// No description provided for @deposeeLe.
  ///
  /// In fr, this message translates to:
  /// **'Déposée le {date}'**
  String deposeeLe(String date);

  /// No description provided for @reponseDuService.
  ///
  /// In fr, this message translates to:
  /// **'Réponse du service'**
  String get reponseDuService;

  /// No description provided for @reponseDuServiceLe.
  ///
  /// In fr, this message translates to:
  /// **'Réponse du service, le {date}'**
  String reponseDuServiceLe(String date);

  /// No description provided for @retirerDemande.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la demande'**
  String get retirerDemande;

  /// No description provided for @retirer.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get retirer;

  /// No description provided for @retirerMoratoireConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'La demande {reference} sera retirée : la scolarité ne l\'examinera pas. Vous pourrez en déposer une autre.'**
  String retirerMoratoireConfirmation(String reference);

  /// No description provided for @retirerPermissionConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'La demande sera retirée : le service ne l\'examinera pas. Vous pourrez en déposer une autre.'**
  String get retirerPermissionConfirmation;

  /// No description provided for @demanderPermission.
  ///
  /// In fr, this message translates to:
  /// **'Demander une permission'**
  String get demanderPermission;

  /// No description provided for @depotPermissionsFerme.
  ///
  /// In fr, this message translates to:
  /// **'Le dépôt des demandes de permission est fermé par le service.'**
  String get depotPermissionsFerme;

  /// No description provided for @permissionExplication.
  ///
  /// In fr, this message translates to:
  /// **'Annoncez ici une absence ou un retard, séance par séance. Votre demande ne vous décharge de rien tant que le service ne l\'a pas accordée.'**
  String get permissionExplication;

  /// No description provided for @aucuneDemandePermission.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez déposé aucune demande de permission.'**
  String get aucuneDemandePermission;

  /// No description provided for @nbEnAttente.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 en attente} other{{n} en attente}}'**
  String nbEnAttente(int n);

  /// No description provided for @permissionDe.
  ///
  /// In fr, this message translates to:
  /// **'Permission : {type}'**
  String permissionDe(String type);

  /// No description provided for @saisieAuBureau.
  ///
  /// In fr, this message translates to:
  /// **'Saisie au bureau du service'**
  String get saisieAuBureau;

  /// No description provided for @arriveeAnnoncee.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée annoncée à {heure}'**
  String arriveeAnnoncee(String heure);

  /// No description provided for @objetDeLaDemande.
  ///
  /// In fr, this message translates to:
  /// **'Objet de la demande'**
  String get objetDeLaDemande;

  /// No description provided for @absence.
  ///
  /// In fr, this message translates to:
  /// **'Absence'**
  String get absence;

  /// No description provided for @retard.
  ///
  /// In fr, this message translates to:
  /// **'Retard'**
  String get retard;

  /// No description provided for @seancesConcernees.
  ///
  /// In fr, this message translates to:
  /// **'Séances concernées'**
  String get seancesConcernees;

  /// No description provided for @jourChome.
  ///
  /// In fr, this message translates to:
  /// **'Jour sans cours'**
  String get jourChome;

  /// No description provided for @dejaAccordee.
  ///
  /// In fr, this message translates to:
  /// **'Déjà accordée'**
  String get dejaAccordee;

  /// No description provided for @preavisPermission.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Déposez votre demande au moins 1 heure avant la séance. Une demande tardive reste possible : le service le verra.} other{Déposez votre demande au moins {n} heures avant la séance. Une demande tardive reste possible : le service le verra.}}'**
  String preavisPermission(int n);

  /// No description provided for @heureArriveeAnnoncee.
  ///
  /// In fr, this message translates to:
  /// **'Heure d\'arrivée annoncée'**
  String get heureArriveeAnnoncee;

  /// No description provided for @heureArriveeRequise.
  ///
  /// In fr, this message translates to:
  /// **'Annoncez l\'heure à laquelle vous comptez arriver.'**
  String get heureArriveeRequise;

  /// No description provided for @motif.
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get motif;

  /// No description provided for @motifNonListe.
  ///
  /// In fr, this message translates to:
  /// **'— Motif non listé —'**
  String get motifNonListe;

  /// No description provided for @explication.
  ///
  /// In fr, this message translates to:
  /// **'Explication'**
  String get explication;

  /// No description provided for @explicationPermissionAide.
  ///
  /// In fr, this message translates to:
  /// **'Dites en quelques lignes ce qui vous empêche d\'être là.'**
  String get explicationPermissionAide;

  /// No description provided for @explicationRequise.
  ///
  /// In fr, this message translates to:
  /// **'Expliquez votre demande : c\'est sur cette explication que le service se prononce.'**
  String get explicationRequise;

  /// No description provided for @demandesDeMoratoire.
  ///
  /// In fr, this message translates to:
  /// **'Demandes de moratoire'**
  String get demandesDeMoratoire;

  /// No description provided for @sectionMessages.
  ///
  /// In fr, this message translates to:
  /// **'Mes messages'**
  String get sectionMessages;

  /// No description provided for @sectionSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Boîte à suggestions'**
  String get sectionSuggestions;

  /// No description provided for @repondre.
  ///
  /// In fr, this message translates to:
  /// **'Répondre'**
  String get repondre;

  /// No description provided for @jaime.
  ///
  /// In fr, this message translates to:
  /// **'J\'aime'**
  String get jaime;

  /// No description provided for @jaimePas.
  ///
  /// In fr, this message translates to:
  /// **'Je n\'aime pas'**
  String get jaimePas;

  /// No description provided for @retirerJaime.
  ///
  /// In fr, this message translates to:
  /// **'Retirer « J\'aime »'**
  String get retirerJaime;

  /// No description provided for @retirerJaimePas.
  ///
  /// In fr, this message translates to:
  /// **'Retirer « Je n\'aime pas »'**
  String get retirerJaimePas;

  /// No description provided for @copier.
  ///
  /// In fr, this message translates to:
  /// **'Copier le texte'**
  String get copier;

  /// No description provided for @serviceEnLigne.
  ///
  /// In fr, this message translates to:
  /// **'Un agent est en ligne'**
  String get serviceEnLigne;

  /// No description provided for @serviceHorsLigne.
  ///
  /// In fr, this message translates to:
  /// **'Aucun agent en ligne'**
  String get serviceHorsLigne;

  /// No description provided for @filVide.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez à la scolarité : votre question arrive au guichet, et l\'agent qui la prend vous répond ici.'**
  String get filVide;

  /// No description provided for @messagesPlusAnciens.
  ///
  /// In fr, this message translates to:
  /// **'Messages plus anciens'**
  String get messagesPlusAnciens;

  /// No description provided for @envoye.
  ///
  /// In fr, this message translates to:
  /// **'Envoyé'**
  String get envoye;

  /// No description provided for @luParLeService.
  ///
  /// In fr, this message translates to:
  /// **'Lu par le service'**
  String get luParLeService;

  /// No description provided for @reponseA.
  ///
  /// In fr, this message translates to:
  /// **'En réponse à {auteur}'**
  String reponseA(String auteur);

  /// No description provided for @joindreFichier.
  ///
  /// In fr, this message translates to:
  /// **'Joindre un fichier'**
  String get joindreFichier;

  /// No description provided for @ecrireMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre message…'**
  String get ecrireMessage;

  /// No description provided for @envoyer.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get envoyer;

  /// No description provided for @ajouterFichiers.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des fichiers'**
  String get ajouterFichiers;

  /// No description provided for @piecesAuPlus.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Un fichier au plus.} other{{n} fichiers au plus.}}'**
  String piecesAuPlus(int n);

  /// No description provided for @nouvelleSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle suggestion'**
  String get nouvelleSuggestion;

  /// No description provided for @mesSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Mes suggestions'**
  String get mesSuggestions;

  /// No description provided for @aucuneSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez déposé aucune suggestion.'**
  String get aucuneSuggestion;

  /// No description provided for @suggestionAnonyme.
  ///
  /// In fr, this message translates to:
  /// **'Anonyme pour le service'**
  String get suggestionAnonyme;

  /// No description provided for @suggestionExplication.
  ///
  /// In fr, this message translates to:
  /// **'Vous suivez ici l\'état de vos suggestions ; la suite donnée reste interne au service.'**
  String get suggestionExplication;

  /// No description provided for @solutionProposee.
  ///
  /// In fr, this message translates to:
  /// **'Solution proposée'**
  String get solutionProposee;

  /// No description provided for @nbPreuves.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 preuve jointe} other{{n} preuves jointes}}'**
  String nbPreuves(int n);

  /// No description provided for @votreSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Votre suggestion'**
  String get votreSuggestion;

  /// No description provided for @votreSuggestionAide.
  ///
  /// In fr, this message translates to:
  /// **'Ce que vous proposez d\'améliorer, et pourquoi.'**
  String get votreSuggestionAide;

  /// No description provided for @suggestionRequise.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez votre suggestion.'**
  String get suggestionRequise;

  /// No description provided for @solutionProposeeAide.
  ///
  /// In fr, this message translates to:
  /// **'Comment y remédier concrètement, selon vous.'**
  String get solutionProposeeAide;

  /// No description provided for @solutionRequise.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez la solution que vous proposez.'**
  String get solutionRequise;

  /// No description provided for @preuvesFacultatives.
  ///
  /// In fr, this message translates to:
  /// **'Preuves (facultatives)'**
  String get preuvesFacultatives;

  /// No description provided for @deposerSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Déposer la suggestion'**
  String get deposerSuggestion;

  /// No description provided for @sectionReinscription.
  ///
  /// In fr, this message translates to:
  /// **'Ma réinscription'**
  String get sectionReinscription;

  /// No description provided for @inscriptionPrononcee.
  ///
  /// In fr, this message translates to:
  /// **'Inscription prononcée'**
  String get inscriptionPrononcee;

  /// No description provided for @reinscriptionAFaire.
  ///
  /// In fr, this message translates to:
  /// **'Réinscription à demander'**
  String get reinscriptionAFaire;

  /// No description provided for @reinscriptionIndisponible.
  ///
  /// In fr, this message translates to:
  /// **'Réinscription en ligne indisponible'**
  String get reinscriptionIndisponible;

  /// No description provided for @programme.
  ///
  /// In fr, this message translates to:
  /// **'Programme'**
  String get programme;

  /// No description provided for @niveauEtSpecialite.
  ///
  /// In fr, this message translates to:
  /// **'Niveau et spécialité'**
  String get niveauEtSpecialite;

  /// No description provided for @demandeeLe.
  ///
  /// In fr, this message translates to:
  /// **'Demandée le {date}'**
  String demandeeLe(String date);

  /// No description provided for @parDemandeur.
  ///
  /// In fr, this message translates to:
  /// **'par {nom}'**
  String parDemandeur(String nom);

  /// No description provided for @reinscriptionAttentePaiement.
  ///
  /// In fr, this message translates to:
  /// **'Votre réinscription sera prononcée dès que la première tranche sera soldée (ou couverte par un moratoire accordé).'**
  String get reinscriptionAttentePaiement;

  /// No description provided for @choisirSpecialite.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre spécialité.'**
  String get choisirSpecialite;

  /// No description provided for @modifierMaDemande.
  ///
  /// In fr, this message translates to:
  /// **'Modifier ma demande'**
  String get modifierMaDemande;

  /// No description provided for @demanderReinscription.
  ///
  /// In fr, this message translates to:
  /// **'Demander ma réinscription'**
  String get demanderReinscription;

  /// No description provided for @niveauSelonJury.
  ///
  /// In fr, this message translates to:
  /// **'Votre niveau est fixé par la décision du jury.'**
  String get niveauSelonJury;

  /// No description provided for @niveauSelonDecision.
  ///
  /// In fr, this message translates to:
  /// **'Décision du jury : {decision}. Votre niveau en découle.'**
  String niveauSelonDecision(String decision);

  /// No description provided for @niveau.
  ///
  /// In fr, this message translates to:
  /// **'Niveau'**
  String get niveau;

  /// No description provided for @specialite.
  ///
  /// In fr, this message translates to:
  /// **'Spécialité'**
  String get specialite;

  /// No description provided for @reinscriptionModifiable.
  ///
  /// In fr, this message translates to:
  /// **'Niveau et spécialité restent modifiables tant qu\'aucun versement n\'est déclaré ni enregistré.'**
  String get reinscriptionModifiable;

  /// No description provided for @enregistrerModification.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la modification'**
  String get enregistrerModification;

  /// No description provided for @premiereTranche.
  ///
  /// In fr, this message translates to:
  /// **'Première tranche'**
  String get premiereTranche;

  /// No description provided for @trancheCouverte.
  ///
  /// In fr, this message translates to:
  /// **'Couverte'**
  String get trancheCouverte;

  /// No description provided for @trancheNonConfiguree.
  ///
  /// In fr, this message translates to:
  /// **'L\'échéancier de votre niveau n\'est pas encore publié : rapprochez-vous de la caisse.'**
  String get trancheNonConfiguree;

  /// No description provided for @montantDu.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get montantDu;

  /// No description provided for @dejaPaye.
  ///
  /// In fr, this message translates to:
  /// **'Déjà payé'**
  String get dejaPaye;

  /// No description provided for @declarerUnVersement.
  ///
  /// In fr, this message translates to:
  /// **'Déclarer un versement'**
  String get declarerUnVersement;

  /// No description provided for @trancheACaisse.
  ///
  /// In fr, this message translates to:
  /// **'La déclaration en ligne n\'est pas ouverte : la tranche se règle à la caisse, et la réinscription est prononcée à l\'encaissement.'**
  String get trancheACaisse;

  /// No description provided for @versementsDeclares.
  ///
  /// In fr, this message translates to:
  /// **'Versements déclarés'**
  String get versementsDeclares;

  /// No description provided for @versementsFermes.
  ///
  /// In fr, this message translates to:
  /// **'La déclaration des versements en ligne n\'est pas ouverte.'**
  String get versementsFermes;

  /// No description provided for @versementExplication.
  ///
  /// In fr, this message translates to:
  /// **'Versez à la banque sur l\'un des comptes ci-dessous, puis déclarez le versement avec le reçu. Il ne compte qu\'une fois vérifié par le service des paiements sur le relevé de la banque.'**
  String get versementExplication;

  /// No description provided for @mesDeclarations.
  ///
  /// In fr, this message translates to:
  /// **'Mes déclarations'**
  String get mesDeclarations;

  /// No description provided for @aucuneDeclaration.
  ///
  /// In fr, this message translates to:
  /// **'Aucun versement déclaré pour cette année.'**
  String get aucuneDeclaration;

  /// No description provided for @resteADeclarer.
  ///
  /// In fr, this message translates to:
  /// **'Reste à déclarer'**
  String get resteADeclarer;

  /// No description provided for @enVerification.
  ///
  /// In fr, this message translates to:
  /// **'En vérification'**
  String get enVerification;

  /// No description provided for @copierNumero.
  ///
  /// In fr, this message translates to:
  /// **'Copier le numéro de compte'**
  String get copierNumero;

  /// No description provided for @numeroCopie.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de compte copié.'**
  String get numeroCopie;

  /// No description provided for @retirerDeclaration.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la déclaration'**
  String get retirerDeclaration;

  /// No description provided for @retirerDeclarationConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'La déclaration {reference} sera retirée : le service ne la vérifiera pas.'**
  String retirerDeclarationConfirmation(String reference);

  /// No description provided for @montantRetenu.
  ///
  /// In fr, this message translates to:
  /// **'Montant retenu au relevé : {montant}'**
  String montantRetenu(String montant);

  /// No description provided for @verseLe.
  ///
  /// In fr, this message translates to:
  /// **'Versé le {date}'**
  String verseLe(String date);

  /// No description provided for @trancheVisee.
  ///
  /// In fr, this message translates to:
  /// **'Tranche : {tranche}'**
  String trancheVisee(String tranche);

  /// No description provided for @declarePar.
  ///
  /// In fr, this message translates to:
  /// **'Déclaré par {nom} ({espace})'**
  String declarePar(String nom, String espace);

  /// No description provided for @motifDuRejet.
  ///
  /// In fr, this message translates to:
  /// **'Motif du rejet'**
  String get motifDuRejet;

  /// No description provided for @recuDeLaBanque.
  ///
  /// In fr, this message translates to:
  /// **'Reçu de la banque'**
  String get recuDeLaBanque;

  /// No description provided for @recuDePaiement.
  ///
  /// In fr, this message translates to:
  /// **'Reçu de paiement'**
  String get recuDePaiement;

  /// No description provided for @compteCredite.
  ///
  /// In fr, this message translates to:
  /// **'Compte crédité'**
  String get compteCredite;

  /// No description provided for @choisirCompte.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le compte sur lequel vous avez versé.'**
  String get choisirCompte;

  /// No description provided for @trancheReglee.
  ///
  /// In fr, this message translates to:
  /// **'Tranche réglée'**
  String get trancheReglee;

  /// No description provided for @repartirSurTranches.
  ///
  /// In fr, this message translates to:
  /// **'Répartir sur les tranches dans leur ordre'**
  String get repartirSurTranches;

  /// No description provided for @trancheReste.
  ///
  /// In fr, this message translates to:
  /// **'{tranche} — reste {reste}'**
  String trancheReste(String tranche, String reste);

  /// No description provided for @montantVerse.
  ///
  /// In fr, this message translates to:
  /// **'Montant versé'**
  String get montantVerse;

  /// No description provided for @laTranche.
  ///
  /// In fr, this message translates to:
  /// **'La tranche'**
  String get laTranche;

  /// No description provided for @dateDuVersement.
  ///
  /// In fr, this message translates to:
  /// **'Date du versement'**
  String get dateDuVersement;

  /// No description provided for @referenceOperation.
  ///
  /// In fr, this message translates to:
  /// **'Référence de l\'opération'**
  String get referenceOperation;

  /// No description provided for @referenceOperationAide.
  ///
  /// In fr, this message translates to:
  /// **'N° de bordereau ou référence du virement'**
  String get referenceOperationAide;

  /// No description provided for @referenceRequise.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez la référence portée sur le reçu.'**
  String get referenceRequise;

  /// No description provided for @recuRequis.
  ///
  /// In fr, this message translates to:
  /// **'Joignez le reçu de la banque.'**
  String get recuRequis;

  /// No description provided for @formatsRecu.
  ///
  /// In fr, this message translates to:
  /// **'PDF ou photo (JPG, PNG, WEBP, HEIC), 5 Mo au plus.'**
  String get formatsRecu;

  /// No description provided for @commentaireFacultatif.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire (facultatif)'**
  String get commentaireFacultatif;

  /// No description provided for @declarerLeVersement.
  ///
  /// In fr, this message translates to:
  /// **'Déclarer le versement'**
  String get declarerLeVersement;

  /// No description provided for @couverteParMoratoireRef.
  ///
  /// In fr, this message translates to:
  /// **'Couverte par le moratoire {reference}'**
  String couverteParMoratoireRef(String reference);

  /// No description provided for @sectionDiscussions.
  ///
  /// In fr, this message translates to:
  /// **'Discussions de classe'**
  String get sectionDiscussions;

  /// No description provided for @discussionVide.
  ///
  /// In fr, this message translates to:
  /// **'Aucun message dans cette discussion. Le premier lance le groupe de la classe.'**
  String get discussionVide;

  /// No description provided for @discussionLectureSeule.
  ///
  /// In fr, this message translates to:
  /// **'Discussion passée : vous ne faites plus partie de cette classe. Elle se relit, elle ne s\'écrit plus.'**
  String get discussionLectureSeule;

  /// No description provided for @enseignantEnLigne.
  ///
  /// In fr, this message translates to:
  /// **'enseignant en ligne'**
  String get enseignantEnLigne;

  /// No description provided for @enseignantHorsLigne.
  ///
  /// In fr, this message translates to:
  /// **'enseignant hors ligne'**
  String get enseignantHorsLigne;

  /// No description provided for @rechercherClasse.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un cours, une classe…'**
  String get rechercherClasse;

  /// No description provided for @aucuneDiscussion.
  ///
  /// In fr, this message translates to:
  /// **'Aucune classe ne vous est rattachée pour l\'instant : les discussions s\'ouvrent avec les emplois du temps publiés.'**
  String get aucuneDiscussion;

  /// No description provided for @discussionsPassees.
  ///
  /// In fr, this message translates to:
  /// **'Discussions passées'**
  String get discussionsPassees;

  /// No description provided for @discussionsPasseesAide.
  ///
  /// In fr, this message translates to:
  /// **'Classes que vous avez quittées : en lecture seule.'**
  String get discussionsPasseesAide;

  /// No description provided for @aucunMessagePourLInstant.
  ///
  /// In fr, this message translates to:
  /// **'Aucun message pour l\'instant'**
  String get aucunMessagePourLInstant;

  /// No description provided for @sectionBibliotheque.
  ///
  /// In fr, this message translates to:
  /// **'Bibliothèque universitaire'**
  String get sectionBibliotheque;

  /// No description provided for @rechercherBibliotheque.
  ///
  /// In fr, this message translates to:
  /// **'Titre, auteur, sujet…'**
  String get rechercherBibliotheque;

  /// No description provided for @effacer.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get effacer;

  /// No description provided for @nbResultats.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucun résultat} =1{1 résultat} other{{n} résultats}}'**
  String nbResultats(int n);

  /// No description provided for @aucunResultat.
  ///
  /// In fr, this message translates to:
  /// **'Aucun document ne correspond à votre recherche.'**
  String get aucunResultat;

  /// No description provided for @dossierVide.
  ///
  /// In fr, this message translates to:
  /// **'Ce dossier est vide.'**
  String get dossierVide;

  /// No description provided for @afficherPlus.
  ///
  /// In fr, this message translates to:
  /// **'Afficher plus'**
  String get afficherPlus;

  /// No description provided for @nbDossiers.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 dossier} other{{n} dossiers}}'**
  String nbDossiers(int n);

  /// No description provided for @ajouteLe.
  ///
  /// In fr, this message translates to:
  /// **'ajouté le {date}'**
  String ajouteLe(String date);

  /// No description provided for @sectionArchives.
  ///
  /// In fr, this message translates to:
  /// **'Archives'**
  String get sectionArchives;

  /// No description provided for @anciennesEpreuves.
  ///
  /// In fr, this message translates to:
  /// **'Anciennes épreuves'**
  String get anciennesEpreuves;

  /// No description provided for @supportsPasses.
  ///
  /// In fr, this message translates to:
  /// **'Supports passés'**
  String get supportsPasses;

  /// No description provided for @toutesLesAnnees.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les années'**
  String get toutesLesAnnees;

  /// No description provided for @aucuneAnnale.
  ///
  /// In fr, this message translates to:
  /// **'Aucune ancienne épreuve publiée pour votre classe.'**
  String get aucuneAnnale;

  /// No description provided for @aucunSupportArchive.
  ///
  /// In fr, this message translates to:
  /// **'Aucun support des années passées pour votre classe.'**
  String get aucunSupportArchive;

  /// No description provided for @annalesExplication.
  ///
  /// In fr, this message translates to:
  /// **'Le sujet seul est remis, jamais le corrigé.'**
  String get annalesExplication;

  /// No description provided for @dureeMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{n} min'**
  String dureeMinutes(int n);

  /// No description provided for @telechargerSujet.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le sujet'**
  String get telechargerSujet;

  /// No description provided for @nonPublie.
  ///
  /// In fr, this message translates to:
  /// **'Non publié'**
  String get nonPublie;

  /// No description provided for @sectionPromotion.
  ///
  /// In fr, this message translates to:
  /// **'Ma promotion'**
  String get sectionPromotion;

  /// No description provided for @aucunePromotion.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat arrêté pour votre promotion pour l\'instant.'**
  String get aucunePromotion;

  /// No description provided for @majorsDeLAnnee.
  ///
  /// In fr, this message translates to:
  /// **'Majors de l\'année'**
  String get majorsDeLAnnee;

  /// No description provided for @majorsDesAnneesPassees.
  ///
  /// In fr, this message translates to:
  /// **'Majors des années passées'**
  String get majorsDesAnneesPassees;

  /// No description provided for @effectifInsuffisant.
  ///
  /// In fr, this message translates to:
  /// **'Effectif insuffisant'**
  String get effectifInsuffisant;

  /// No description provided for @plancherEffectif.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Une moyenne de classe n’est montrée qu’à partir de 1 étudiant.} other{Une moyenne de classe n’est montrée qu’à partir de {n} étudiants, pour ne désigner personne.}}'**
  String plancherEffectif(int n);

  /// No description provided for @nbEtudiants.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 étudiant} other{{n} étudiants}}'**
  String nbEtudiants(int n);

  /// No description provided for @premierePlacePartagee.
  ///
  /// In fr, this message translates to:
  /// **'Première place partagée.'**
  String get premierePlacePartagee;

  /// No description provided for @sectionAssociation.
  ///
  /// In fr, this message translates to:
  /// **'Association des étudiants'**
  String get sectionAssociation;

  /// No description provided for @sectionAssociationHistorique.
  ///
  /// In fr, this message translates to:
  /// **'Listes élues'**
  String get sectionAssociationHistorique;

  /// No description provided for @aucuneCampagne.
  ///
  /// In fr, this message translates to:
  /// **'Aucune campagne électorale n\'est ouverte.'**
  String get aucuneCampagne;

  /// No description provided for @resultats.
  ///
  /// In fr, this message translates to:
  /// **'Résultats'**
  String get resultats;

  /// No description provided for @depouillement.
  ///
  /// In fr, this message translates to:
  /// **'Dépouillement'**
  String get depouillement;

  /// No description provided for @enDirect.
  ///
  /// In fr, this message translates to:
  /// **'En direct'**
  String get enDirect;

  /// No description provided for @participation.
  ///
  /// In fr, this message translates to:
  /// **'Participation : {taux} % ({votants} votants sur {inscrits} inscrits)'**
  String participation(String taux, int votants, int inscrits);

  /// No description provided for @elu.
  ///
  /// In fr, this message translates to:
  /// **'Élue'**
  String get elu;

  /// No description provided for @nbVoix.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{0 voix} =1{1 voix} other{{n} voix}}'**
  String nbVoix(int n);

  /// No description provided for @ballottage.
  ///
  /// In fr, this message translates to:
  /// **'Égalité en tête : aucune liste n\'est élue. C\'est à l\'établissement de trancher.'**
  String get ballottage;

  /// No description provided for @aucunSuffrage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun suffrage pour le moment.'**
  String get aucunSuffrage;

  /// No description provided for @candidat.
  ///
  /// In fr, this message translates to:
  /// **'Candidat : {nom}'**
  String candidat(String nom);

  /// No description provided for @lireLeProgramme.
  ///
  /// In fr, this message translates to:
  /// **'Lire le programme'**
  String get lireLeProgramme;

  /// No description provided for @programmeDeLaListe.
  ///
  /// In fr, this message translates to:
  /// **'Programme'**
  String get programmeDeLaListe;

  /// No description provided for @programmeNonRedige.
  ///
  /// In fr, this message translates to:
  /// **'Le programme de cette liste n\'a pas été rédigé.'**
  String get programmeNonRedige;

  /// No description provided for @equipe.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get equipe;

  /// No description provided for @scrutinAnnule.
  ///
  /// In fr, this message translates to:
  /// **'Scrutin annulé'**
  String get scrutinAnnule;

  /// No description provided for @urnesOuvertes.
  ///
  /// In fr, this message translates to:
  /// **'Urnes ouvertes'**
  String get urnesOuvertes;

  /// No description provided for @voteTermine.
  ///
  /// In fr, this message translates to:
  /// **'Vote terminé'**
  String get voteTermine;

  /// No description provided for @urnesAVenir.
  ///
  /// In fr, this message translates to:
  /// **'Vote à venir'**
  String get urnesAVenir;

  /// No description provided for @vousAvezVote.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez voté'**
  String get vousAvezVote;

  /// No description provided for @voteAnonyme.
  ///
  /// In fr, this message translates to:
  /// **'Le vote est anonyme : le système sait que vous avez voté, jamais pour qui.'**
  String get voteAnonyme;

  /// No description provided for @listesCandidates.
  ///
  /// In fr, this message translates to:
  /// **'Listes candidates'**
  String get listesCandidates;

  /// No description provided for @votreBulletin.
  ///
  /// In fr, this message translates to:
  /// **'Votre bulletin'**
  String get votreBulletin;

  /// No description provided for @confirmerVote.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer votre vote'**
  String get confirmerVote;

  /// No description provided for @confirmerVoteTexte.
  ///
  /// In fr, this message translates to:
  /// **'Vous votez pour « {liste} ». Un vote ne se reprend pas.'**
  String confirmerVoteTexte(String liste);

  /// No description provided for @voter.
  ///
  /// In fr, this message translates to:
  /// **'Voter'**
  String get voter;

  /// No description provided for @validerMonVote.
  ///
  /// In fr, this message translates to:
  /// **'Valider mon vote'**
  String get validerMonVote;

  /// No description provided for @aucunScrutinPasse.
  ///
  /// In fr, this message translates to:
  /// **'Aucun scrutin n\'est encore terminé.'**
  String get aucunScrutinPasse;

  /// No description provided for @presidentElu.
  ///
  /// In fr, this message translates to:
  /// **'Président élu : {nom}'**
  String presidentElu(String nom);

  /// No description provided for @sectionDelegation.
  ///
  /// In fr, this message translates to:
  /// **'Ma délégation'**
  String get sectionDelegation;

  /// No description provided for @aucuneSeanceCeJour.
  ///
  /// In fr, this message translates to:
  /// **'Aucune séance de votre classe ce jour-là.'**
  String get aucuneSeanceCeJour;

  /// No description provided for @circuitService.
  ///
  /// In fr, this message translates to:
  /// **'validé par le service'**
  String get circuitService;

  /// No description provided for @circuitEnseignant.
  ///
  /// In fr, this message translates to:
  /// **'signé par l\'enseignant'**
  String get circuitEnseignant;

  /// No description provided for @circuitEnseignantService.
  ///
  /// In fr, this message translates to:
  /// **'signé par l\'enseignant puis validé par le service'**
  String get circuitEnseignantService;

  /// No description provided for @circuitAutomatique.
  ///
  /// In fr, this message translates to:
  /// **'validé d’office'**
  String get circuitAutomatique;

  /// No description provided for @circuitDeLAppel.
  ///
  /// In fr, this message translates to:
  /// **'Appel : {circuit}.'**
  String circuitDeLAppel(String circuit);

  /// No description provided for @circuitDuCahier.
  ///
  /// In fr, this message translates to:
  /// **'Cahier de texte : {circuit}.'**
  String circuitDuCahier(String circuit);

  /// No description provided for @appelNonAutorise.
  ///
  /// In fr, this message translates to:
  /// **'L\'appel ne vous est pas ouvert : votre délégué principal ou le service peut l\'ouvrir.'**
  String get appelNonAutorise;

  /// No description provided for @positionExigee.
  ///
  /// In fr, this message translates to:
  /// **'L\'établissement exige votre position au moment d\'enregistrer : faites-le depuis la salle.'**
  String get positionExigee;

  /// No description provided for @jourPrecedent.
  ///
  /// In fr, this message translates to:
  /// **'Jour précédent'**
  String get jourPrecedent;

  /// No description provided for @jourSuivant.
  ///
  /// In fr, this message translates to:
  /// **'Jour suivant'**
  String get jourSuivant;

  /// No description provided for @aujourdhui.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get aujourdhui;

  /// No description provided for @aFaire.
  ///
  /// In fr, this message translates to:
  /// **'À faire'**
  String get aFaire;

  /// No description provided for @renvoyeAuDelegue.
  ///
  /// In fr, this message translates to:
  /// **'À corriger'**
  String get renvoyeAuDelegue;

  /// No description provided for @signeParEnseignant.
  ///
  /// In fr, this message translates to:
  /// **'Signé par l\'enseignant'**
  String get signeParEnseignant;

  /// No description provided for @valideParService.
  ///
  /// In fr, this message translates to:
  /// **'Validé par le service'**
  String get valideParService;

  /// No description provided for @fenetreAVenir.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore ouvert'**
  String get fenetreAVenir;

  /// No description provided for @fenetreFermee.
  ///
  /// In fr, this message translates to:
  /// **'Fenêtre fermée'**
  String get fenetreFermee;

  /// No description provided for @coursNonTenu.
  ///
  /// In fr, this message translates to:
  /// **'Cours relevé non tenu'**
  String get coursNonTenu;

  /// No description provided for @horsPlanning.
  ///
  /// In fr, this message translates to:
  /// **'Hors planning'**
  String get horsPlanning;

  /// No description provided for @fenetreDeA.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert de {debut} à {fin}'**
  String fenetreDeA(String debut, String fin);

  /// No description provided for @faire.
  ///
  /// In fr, this message translates to:
  /// **'Faire'**
  String get faire;

  /// No description provided for @corriger.
  ///
  /// In fr, this message translates to:
  /// **'Corriger'**
  String get corriger;

  /// No description provided for @rouvertParLeService.
  ///
  /// In fr, this message translates to:
  /// **'Rouvert par le service'**
  String get rouvertParLeService;

  /// No description provided for @motifDuRenvoi.
  ///
  /// In fr, this message translates to:
  /// **'Motif du renvoi'**
  String get motifDuRenvoi;

  /// No description provided for @appel.
  ///
  /// In fr, this message translates to:
  /// **'Appel'**
  String get appel;

  /// No description provided for @cahierDeTexte.
  ///
  /// In fr, this message translates to:
  /// **'Cahier de texte'**
  String get cahierDeTexte;

  /// No description provided for @seancesRouvertes.
  ///
  /// In fr, this message translates to:
  /// **'Séances rouvertes par le service'**
  String get seancesRouvertes;

  /// No description provided for @jusquAu.
  ///
  /// In fr, this message translates to:
  /// **'jusqu\'au {date}'**
  String jusquAu(String date);

  /// No description provided for @mesAssistants.
  ///
  /// In fr, this message translates to:
  /// **'Mes assistants'**
  String get mesAssistants;

  /// No description provided for @assistantsAide.
  ///
  /// In fr, this message translates to:
  /// **'Vous décidez lesquels de vos assistants peuvent faire l\'appel à votre place.'**
  String get assistantsAide;

  /// No description provided for @releveDePosition.
  ///
  /// In fr, this message translates to:
  /// **'Relevé de votre position…'**
  String get releveDePosition;

  /// No description provided for @positionIndisponible.
  ///
  /// In fr, this message translates to:
  /// **'Position indisponible'**
  String get positionIndisponible;

  /// No description provided for @positionServiceDesactive.
  ///
  /// In fr, this message translates to:
  /// **'La localisation du téléphone est désactivée : activez-la, puis réessayez.'**
  String get positionServiceDesactive;

  /// No description provided for @positionRefusee.
  ///
  /// In fr, this message translates to:
  /// **'L\'application n\'a pas l\'autorisation de lire votre position : acceptez la demande, puis réessayez.'**
  String get positionRefusee;

  /// No description provided for @positionRefuseeReglages.
  ///
  /// In fr, this message translates to:
  /// **'L\'accès à la position est refusé : autorisez-le pour YSEM dans les réglages du téléphone.'**
  String get positionRefuseeReglages;

  /// No description provided for @positionDelai.
  ///
  /// In fr, this message translates to:
  /// **'La position n\'a pas pu être relevée à temps : placez-vous près d\'une fenêtre et réessayez.'**
  String get positionDelai;

  /// No description provided for @compris.
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get compris;

  /// No description provided for @enregistrerLAppel.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer l\'appel'**
  String get enregistrerLAppel;

  /// No description provided for @confirmerAppel.
  ///
  /// In fr, this message translates to:
  /// **'{absents, plural, =0{Aucun absent sur {effectif} étudiants.} =1{1 absent sur {effectif} étudiants.} other{{absents} absents sur {effectif} étudiants.}} Confirmer ?'**
  String confirmerAppel(int absents, int effectif);

  /// No description provided for @appelDeLaSeance.
  ///
  /// In fr, this message translates to:
  /// **'Appel de la séance'**
  String get appelDeLaSeance;

  /// No description provided for @appelExplication.
  ///
  /// In fr, this message translates to:
  /// **'Cochez seulement les absents : les autres sont comptés présents. Une ligne verrouillée est couverte par une permission accordée.'**
  String get appelExplication;

  /// No description provided for @couvertParPermission.
  ///
  /// In fr, this message translates to:
  /// **'Permission accordée ({type})'**
  String couvertParPermission(String type);

  /// No description provided for @nbAbsentsSur.
  ///
  /// In fr, this message translates to:
  /// **'{absents, plural, =0{0 absent} =1{1 absent} other{{absents} absents}} / {effectif}'**
  String nbAbsentsSur(int absents, int effectif);

  /// No description provided for @contenuPrevu.
  ///
  /// In fr, this message translates to:
  /// **'Contenu prévu au plan'**
  String get contenuPrevu;

  /// No description provided for @aucunPlanDeCours.
  ///
  /// In fr, this message translates to:
  /// **'Aucun plan de cours n\'est rattaché à cette séance.'**
  String get aucunPlanDeCours;

  /// No description provided for @contenuFait.
  ///
  /// In fr, this message translates to:
  /// **'Contenu fait'**
  String get contenuFait;

  /// No description provided for @blocN.
  ///
  /// In fr, this message translates to:
  /// **'Bloc {n}'**
  String blocN(int n);

  /// No description provided for @seanceNumero.
  ///
  /// In fr, this message translates to:
  /// **'Séance {n}'**
  String seanceNumero(int n);

  /// No description provided for @ajouterUneSeanceFaite.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une séance faite'**
  String get ajouterUneSeanceFaite;

  /// No description provided for @blocsAide.
  ///
  /// In fr, this message translates to:
  /// **'Une séance double couvre souvent deux séances du plan : ajoutez un bloc par séance faite.'**
  String get blocsAide;

  /// No description provided for @activitesPedagogiques.
  ///
  /// In fr, this message translates to:
  /// **'Activités pédagogiques'**
  String get activitesPedagogiques;

  /// No description provided for @nonRenseigne.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get nonRenseigne;

  /// No description provided for @enregistrerLeCahier.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le cahier de texte'**
  String get enregistrerLeCahier;

  /// No description provided for @connexionEnseignantConsigne.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous avec l\'adresse e-mail et le mot de passe du portail enseignant.'**
  String get connexionEnseignantConsigne;

  /// No description provided for @connexionEnseignantAide.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ou compte non activé ? L\'inscription et l\'activation se font sur le portail enseignant web.'**
  String get connexionEnseignantAide;

  /// No description provided for @emailInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide.'**
  String get emailInvalide;

  /// No description provided for @motDePasseOublie.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get motDePasseOublie;

  /// No description provided for @motDePasseOublieConsigne.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez l\'adresse de votre compte : un lien vous sera envoyé pour choisir un nouveau mot de passe sur le portail web.'**
  String get motDePasseOublieConsigne;

  /// No description provided for @envoyerLeLien.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get envoyerLeLien;

  /// No description provided for @maCandidature.
  ///
  /// In fr, this message translates to:
  /// **'Ma candidature'**
  String get maCandidature;

  /// No description provided for @candidatureSoumise.
  ///
  /// In fr, this message translates to:
  /// **'Soumise'**
  String get candidatureSoumise;

  /// No description provided for @candidatureEtape.
  ///
  /// In fr, this message translates to:
  /// **'Étape {etape} sur {etapes}'**
  String candidatureEtape(int etape, int etapes);

  /// No description provided for @candidatureSoumiseLe.
  ///
  /// In fr, this message translates to:
  /// **'Candidature soumise le {date}. L\'établissement l\'examine.'**
  String candidatureSoumiseLe(String date);

  /// No description provided for @candidatureAPoursuivre.
  ///
  /// In fr, this message translates to:
  /// **'Votre dossier de candidature est à poursuivre à l\'étape {etape}.'**
  String candidatureAPoursuivre(int etape);

  /// No description provided for @candidatureSurLeWeb.
  ///
  /// In fr, this message translates to:
  /// **'Le dossier de candidature se remplit sur le portail enseignant web.'**
  String get candidatureSurLeWeb;

  /// No description provided for @candidatureAcceptee.
  ///
  /// In fr, this message translates to:
  /// **'Candidature acceptée'**
  String get candidatureAcceptee;

  /// No description provided for @candidatureAccepteeTexte.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans le corps enseignant ! Vos services sont désormais ouverts dans l\'application.'**
  String get candidatureAccepteeTexte;

  /// No description provided for @motifDuRefus.
  ///
  /// In fr, this message translates to:
  /// **'Motif du refus'**
  String get motifDuRefus;

  /// No description provided for @rienEnAttente.
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'attend votre intervention pour l\'instant.'**
  String get rienEnAttente;

  /// No description provided for @fichesASignerNombre.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{1 fiche du délégué à signer} other{{nombre} fiches du délégué à signer}}'**
  String fichesASignerNombre(int nombre);

  /// No description provided for @rattrapagesOuvertsNombre.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{1 rattrapage dû} other{{nombre} rattrapages dus}}'**
  String rattrapagesOuvertsNombre(int nombre);

  /// No description provided for @fichesATransmettreNombre.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{1 fiche d\'émargement à transmettre} other{{nombre} fiches d\'émargement à transmettre}}'**
  String fichesATransmettreNombre(int nombre);

  /// No description provided for @messagesNonLusNombre.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{1 message non lu dans vos classes} other{{nombre} messages non lus dans vos classes}}'**
  String messagesNonLusNombre(int nombre);

  /// No description provided for @monDossier.
  ///
  /// In fr, this message translates to:
  /// **'Mon dossier'**
  String get monDossier;

  /// No description provided for @monDossierAide.
  ///
  /// In fr, this message translates to:
  /// **'État civil, cursus, expériences et validations du service.'**
  String get monDossierAide;

  /// No description provided for @profilProfessionnel.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profilProfessionnel;

  /// No description provided for @dernierDiplome.
  ///
  /// In fr, this message translates to:
  /// **'Dernier diplôme obtenu'**
  String get dernierDiplome;

  /// No description provided for @dateRecrutement.
  ///
  /// In fr, this message translates to:
  /// **'Date de recrutement'**
  String get dateRecrutement;

  /// No description provided for @permanent.
  ///
  /// In fr, this message translates to:
  /// **'Permanent'**
  String get permanent;

  /// No description provided for @vacataire.
  ///
  /// In fr, this message translates to:
  /// **'Vacataire'**
  String get vacataire;

  /// No description provided for @dossierIncomplet.
  ///
  /// In fr, this message translates to:
  /// **'Votre dossier est incomplet'**
  String get dossierIncomplet;

  /// No description provided for @dossierModifierSurLeWeb.
  ///
  /// In fr, this message translates to:
  /// **'Pour modifier votre dossier, utilisez « Mon dossier » sur le portail enseignant web. Le grade, les domaines et les cours sont fixés par le service.'**
  String get dossierModifierSurLeWeb;

  /// No description provided for @etatCivil.
  ///
  /// In fr, this message translates to:
  /// **'État civil'**
  String get etatCivil;

  /// No description provided for @nationalite.
  ///
  /// In fr, this message translates to:
  /// **'Nationalité'**
  String get nationalite;

  /// No description provided for @regionOrigine.
  ///
  /// In fr, this message translates to:
  /// **'Région d\'origine'**
  String get regionOrigine;

  /// No description provided for @situationMatrimoniale.
  ///
  /// In fr, this message translates to:
  /// **'Situation matrimoniale'**
  String get situationMatrimoniale;

  /// No description provided for @enfantsACharge.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{1 enfant à charge} other{{nombre} enfants à charge}}'**
  String enfantsACharge(int nombre);

  /// No description provided for @cni.
  ///
  /// In fr, this message translates to:
  /// **'Carte nationale d\'identité'**
  String get cni;

  /// No description provided for @niu.
  ///
  /// In fr, this message translates to:
  /// **'Numéro d\'identifiant unique (NIU)'**
  String get niu;

  /// No description provided for @universiteRattachement.
  ///
  /// In fr, this message translates to:
  /// **'Université de rattachement'**
  String get universiteRattachement;

  /// No description provided for @cv.
  ///
  /// In fr, this message translates to:
  /// **'Curriculum vitæ'**
  String get cv;

  /// No description provided for @depose.
  ///
  /// In fr, this message translates to:
  /// **'Déposé'**
  String get depose;

  /// No description provided for @nonDepose.
  ///
  /// In fr, this message translates to:
  /// **'Non déposé'**
  String get nonDepose;

  /// No description provided for @coordonnees.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées'**
  String get coordonnees;

  /// No description provided for @adresse.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get adresse;

  /// No description provided for @contactUrgence.
  ///
  /// In fr, this message translates to:
  /// **'Contact d\'urgence'**
  String get contactUrgence;

  /// No description provided for @cursusEtCertifications.
  ///
  /// In fr, this message translates to:
  /// **'Cursus et certifications'**
  String get cursusEtCertifications;

  /// No description provided for @aucunDiplome.
  ///
  /// In fr, this message translates to:
  /// **'Aucun diplôme renseigné.'**
  String get aucunDiplome;

  /// No description provided for @justificatifDepose.
  ///
  /// In fr, this message translates to:
  /// **'Justificatif déposé'**
  String get justificatifDepose;

  /// No description provided for @certifications.
  ///
  /// In fr, this message translates to:
  /// **'Certifications'**
  String get certifications;

  /// No description provided for @experiencesEnseignement.
  ///
  /// In fr, this message translates to:
  /// **'Expériences dans l\'enseignement'**
  String get experiencesEnseignement;

  /// No description provided for @experiencesEntreprise.
  ///
  /// In fr, this message translates to:
  /// **'Expériences en entreprise'**
  String get experiencesEntreprise;

  /// No description provided for @aucuneExperience.
  ///
  /// In fr, this message translates to:
  /// **'Aucune expérience renseignée.'**
  String get aucuneExperience;

  /// No description provided for @nombreAnnees.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{1 an} other{{nombre} ans}}'**
  String nombreAnnees(int nombre);

  /// No description provided for @nombreMois.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, other{{nombre} mois}}'**
  String nombreMois(int nombre);

  /// No description provided for @domainesEnseignement.
  ///
  /// In fr, this message translates to:
  /// **'Domaines d\'enseignement'**
  String get domainesEnseignement;

  /// No description provided for @coursProposes.
  ///
  /// In fr, this message translates to:
  /// **'Cours proposés'**
  String get coursProposes;

  /// No description provided for @aucunElement.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élément.'**
  String get aucunElement;

  /// No description provided for @sectionFichesASigner.
  ///
  /// In fr, this message translates to:
  /// **'Fiches à signer'**
  String get sectionFichesASigner;

  /// No description provided for @sectionRattrapages.
  ///
  /// In fr, this message translates to:
  /// **'Mes rattrapages'**
  String get sectionRattrapages;

  /// No description provided for @sectionClasses.
  ///
  /// In fr, this message translates to:
  /// **'Mes classes'**
  String get sectionClasses;

  /// No description provided for @fichesASignerExplication.
  ///
  /// In fr, this message translates to:
  /// **'Les appels et cahiers de texte saisis par les délégués attendent votre signature. Signer vaut validation ; renvoyez au délégué ce qui est à corriger, en disant pourquoi.'**
  String get fichesASignerExplication;

  /// No description provided for @aucuneFicheASigner.
  ///
  /// In fr, this message translates to:
  /// **'Aucune fiche n\'attend votre signature.'**
  String get aucuneFicheASigner;

  /// No description provided for @signerToutesLesFiches.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{Signer la fiche} other{Signer les {nombre} fiches}}'**
  String signerToutesLesFiches(int nombre);

  /// No description provided for @signerToutConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Chaque fiche signée est validée, ou part à la validation du service selon le circuit de l\'année.'**
  String get signerToutConfirmation;

  /// No description provided for @signer.
  ///
  /// In fr, this message translates to:
  /// **'Signer'**
  String get signer;

  /// No description provided for @renvoyer.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer'**
  String get renvoyer;

  /// No description provided for @renvoyerAuDelegue.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer au délégué'**
  String get renvoyerAuDelegue;

  /// No description provided for @renvoyerAuDelegueAide.
  ///
  /// In fr, this message translates to:
  /// **'Dites au délégué ce qu\'il doit corriger : il en est informé et peut reprendre sa fiche.'**
  String get renvoyerAuDelegueAide;

  /// No description provided for @dernieresFiches.
  ///
  /// In fr, this message translates to:
  /// **'Dernières fiches traitées'**
  String get dernieresFiches;

  /// No description provided for @ficheAppel.
  ///
  /// In fr, this message translates to:
  /// **'Appel du délégué'**
  String get ficheAppel;

  /// No description provided for @ficheCahierDeTexte.
  ///
  /// In fr, this message translates to:
  /// **'Cahier de texte'**
  String get ficheCahierDeTexte;

  /// No description provided for @saisiPar.
  ///
  /// In fr, this message translates to:
  /// **'Saisi par {nom}'**
  String saisiPar(String nom);

  /// No description provided for @enAttenteValidationService.
  ///
  /// In fr, this message translates to:
  /// **'Signée — en attente de la validation du service.'**
  String get enAttenteValidationService;

  /// No description provided for @nbAbsents.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =0{Aucun absent} =1{1 absent} other{{nombre} absents}}'**
  String nbAbsents(int nombre);

  /// No description provided for @cahierSansContenu.
  ///
  /// In fr, this message translates to:
  /// **'Aucun contenu consigné.'**
  String get cahierSansContenu;

  /// No description provided for @rattrapagesExplication.
  ///
  /// In fr, this message translates to:
  /// **'Proposez une date pour une séance à rattraper : elle n\'est annoncée aux étudiants qu\'une fois approuvée par le service. Une séance déjà programmée se déplace par le service.'**
  String get rattrapagesExplication;

  /// No description provided for @aucunRattrapage.
  ///
  /// In fr, this message translates to:
  /// **'Aucune séance à rattraper.'**
  String get aucunRattrapage;

  /// No description provided for @rattrapagesClos.
  ///
  /// In fr, this message translates to:
  /// **'Rattrapages clos'**
  String get rattrapagesClos;

  /// No description provided for @seanceDuJour.
  ///
  /// In fr, this message translates to:
  /// **'Séance du {date}'**
  String seanceDuJour(String date);

  /// No description provided for @aRattraperAvant.
  ///
  /// In fr, this message translates to:
  /// **'À rattraper avant le {date}'**
  String aRattraperAvant(String date);

  /// No description provided for @dateEnAttenteArbitrage.
  ///
  /// In fr, this message translates to:
  /// **'Date proposée, en attente de l\'approbation du service.'**
  String get dateEnAttenteArbitrage;

  /// No description provided for @rattrapeLe.
  ///
  /// In fr, this message translates to:
  /// **'Rattrapé le {date}'**
  String rattrapeLe(String date);

  /// No description provided for @dateRefusee.
  ///
  /// In fr, this message translates to:
  /// **'Date refusée'**
  String get dateRefusee;

  /// No description provided for @proposerUneDate.
  ///
  /// In fr, this message translates to:
  /// **'Proposer une date'**
  String get proposerUneDate;

  /// No description provided for @propositionAide.
  ///
  /// In fr, this message translates to:
  /// **'La date reste une proposition tant que le service ne l\'a pas approuvée.'**
  String get propositionAide;

  /// No description provided for @dateProposee.
  ///
  /// In fr, this message translates to:
  /// **'Date proposée'**
  String get dateProposee;

  /// No description provided for @creneau.
  ///
  /// In fr, this message translates to:
  /// **'Créneau'**
  String get creneau;

  /// No description provided for @salleFacultative.
  ///
  /// In fr, this message translates to:
  /// **'Salle (facultative)'**
  String get salleFacultative;

  /// No description provided for @aucuneSalle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune salle précise'**
  String get aucuneSalle;

  /// No description provided for @transmettreAuService.
  ///
  /// In fr, this message translates to:
  /// **'Transmettre au service'**
  String get transmettreAuService;

  /// No description provided for @aucuneClasse.
  ///
  /// In fr, this message translates to:
  /// **'Aucune classe ne vous est attribuée dans les emplois du temps publiés.'**
  String get aucuneClasse;

  /// No description provided for @nbClasses.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{1 classe} other{{nombre} classes}}'**
  String nbClasses(int nombre);

  /// No description provided for @nbCours.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{1 cours} other{{nombre} cours}}'**
  String nbCours(int nombre);

  /// No description provided for @nbSansDelegue.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{1 classe sans délégué} other{{nombre} classes sans délégué}}'**
  String nbSansDelegue(int nombre);

  /// No description provided for @sansDeleguePrincipal.
  ///
  /// In fr, this message translates to:
  /// **'Pas de délégué principal'**
  String get sansDeleguePrincipal;

  /// No description provided for @deleguePrincipal.
  ///
  /// In fr, this message translates to:
  /// **'Délégué : {noms}'**
  String deleguePrincipal(String noms);

  /// No description provided for @exporterLaListe.
  ///
  /// In fr, this message translates to:
  /// **'Exporter la liste (Excel)'**
  String get exporterLaListe;

  /// No description provided for @listeDesInscrits.
  ///
  /// In fr, this message translates to:
  /// **'Liste des inscrits'**
  String get listeDesInscrits;

  /// No description provided for @rechercherEtudiant.
  ///
  /// In fr, this message translates to:
  /// **'Nom ou matricule'**
  String get rechercherEtudiant;

  /// No description provided for @aucunInscrit.
  ///
  /// In fr, this message translates to:
  /// **'Aucun inscrit dans cette classe.'**
  String get aucunInscrit;

  /// No description provided for @aucunEtudiantTrouve.
  ///
  /// In fr, this message translates to:
  /// **'Aucun étudiant ne correspond à votre recherche.'**
  String get aucunEtudiantTrouve;

  /// No description provided for @inscrits.
  ///
  /// In fr, this message translates to:
  /// **'Inscrits'**
  String get inscrits;

  /// No description provided for @femmesHommes.
  ///
  /// In fr, this message translates to:
  /// **'Femmes / hommes'**
  String get femmesHommes;

  /// No description provided for @seancesRelevees.
  ///
  /// In fr, this message translates to:
  /// **'Séances relevées'**
  String get seancesRelevees;

  /// No description provided for @etudiantsAbsents.
  ///
  /// In fr, this message translates to:
  /// **'Avec absence'**
  String get etudiantsAbsents;

  /// No description provided for @planDeCoursStatut.
  ///
  /// In fr, this message translates to:
  /// **'Plan de cours : {statut}'**
  String planDeCoursStatut(String statut);

  /// No description provided for @deleguesDeLaClasse.
  ///
  /// In fr, this message translates to:
  /// **'Délégués de la classe'**
  String get deleguesDeLaClasse;

  /// No description provided for @aucunDelegue.
  ///
  /// In fr, this message translates to:
  /// **'Aucun délégué nommé pour cette classe.'**
  String get aucunDelegue;

  /// No description provided for @nbAbsences.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{1 absence} other{{nombre} absences}}'**
  String nbAbsences(int nombre);

  /// No description provided for @nbRetards.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{1 retard} other{{nombre} retards}}'**
  String nbRetards(int nombre);

  /// No description provided for @nbNonJustifiees.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{1 non justifiée} other{{nombre} non justifiées}}'**
  String nbNonJustifiees(int nombre);

  /// No description provided for @delegue.
  ///
  /// In fr, this message translates to:
  /// **'Délégué'**
  String get delegue;

  /// No description provided for @sectionDisponibilites.
  ///
  /// In fr, this message translates to:
  /// **'Mes disponibilités'**
  String get sectionDisponibilites;

  /// No description provided for @sectionPonctualite.
  ///
  /// In fr, this message translates to:
  /// **'Ma ponctualité'**
  String get sectionPonctualite;

  /// No description provided for @sectionVacations.
  ///
  /// In fr, this message translates to:
  /// **'Mes vacations'**
  String get sectionVacations;

  /// No description provided for @modifier.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get modifier;

  /// No description provided for @disponibilitesExplication.
  ///
  /// In fr, this message translates to:
  /// **'Dites à la planification les créneaux où vous êtes disponible, ceux que vous préférez et ceux où vous ne l\'êtes pas. Elle en est prévenue et compose les emplois du temps avec.'**
  String get disponibilitesExplication;

  /// No description provided for @aucuneDisponibilite.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez déclaré aucune disponibilité pour cette année.'**
  String get aucuneDisponibilite;

  /// No description provided for @declarerDisponibilite.
  ///
  /// In fr, this message translates to:
  /// **'Déclarer une disponibilité'**
  String get declarerDisponibilite;

  /// No description provided for @modifierDisponibilite.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la disponibilité'**
  String get modifierDisponibilite;

  /// No description provided for @retirerDisponibilite.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la disponibilité'**
  String get retirerDisponibilite;

  /// No description provided for @retirerDisponibiliteConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Retirer votre déclaration pour « {creneau} » ? La planification en sera prévenue.'**
  String retirerDisponibiliteConfirmation(String creneau);

  /// No description provided for @touteLAnnee.
  ///
  /// In fr, this message translates to:
  /// **'Toute l\'année'**
  String get touteLAnnee;

  /// No description provided for @aucunPlanningEnseignant.
  ///
  /// In fr, this message translates to:
  /// **'Aucun planning d\'examens publié ne vous attend pour l\'instant.'**
  String get aucunPlanningEnseignant;

  /// No description provided for @votreEpreuve.
  ///
  /// In fr, this message translates to:
  /// **'Votre épreuve'**
  String get votreEpreuve;

  /// No description provided for @reglesPonctualite.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée attendue {avance} min avant le début du cours ; le retard compte au-delà de {tolerance} min de tolérance.'**
  String reglesPonctualite(int avance, int tolerance);

  /// No description provided for @aucuneSeanceRelevee.
  ///
  /// In fr, this message translates to:
  /// **'Aucune séance n\'a encore été relevée en salle.'**
  String get aucuneSeanceRelevee;

  /// No description provided for @heuresDispensees.
  ///
  /// In fr, this message translates to:
  /// **'Temps dispensé'**
  String get heuresDispensees;

  /// No description provided for @heuresPerdues.
  ///
  /// In fr, this message translates to:
  /// **'Temps perdu'**
  String get heuresPerdues;

  /// No description provided for @tempsRetenu.
  ///
  /// In fr, this message translates to:
  /// **'Temps retenu'**
  String get tempsRetenu;

  /// No description provided for @arriveeA.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée à {heure}'**
  String arriveeA(String heure);

  /// No description provided for @finA.
  ///
  /// In fr, this message translates to:
  /// **'fin à {heure}'**
  String finA(String heure);

  /// No description provided for @retardDe.
  ///
  /// In fr, this message translates to:
  /// **'Retard de {duree}'**
  String retardDe(String duree);

  /// No description provided for @retenue.
  ///
  /// In fr, this message translates to:
  /// **'Retenue de {duree}'**
  String retenue(String duree);

  /// No description provided for @finConstateeDOffice.
  ///
  /// In fr, this message translates to:
  /// **'Heure de fin posée d\'office à minuit : elle n\'a pas été relevée.'**
  String get finConstateeDOffice;

  /// No description provided for @fichesEmargement.
  ///
  /// In fr, this message translates to:
  /// **'Émargement'**
  String get fichesEmargement;

  /// No description provided for @fichesEmargementExplication.
  ///
  /// In fr, this message translates to:
  /// **'Vos séances relevées en salle s\'y reportent d\'elles-mêmes. Transmettez chaque fiche à la fin du mois : seules les fiches validées par le service entrent dans la paie.'**
  String get fichesEmargementExplication;

  /// No description provided for @aucuneFicheEmargement.
  ///
  /// In fr, this message translates to:
  /// **'Aucune fiche d\'émargement pour cette année.'**
  String get aucuneFicheEmargement;

  /// No description provided for @detailDesSeances.
  ///
  /// In fr, this message translates to:
  /// **'Détail des séances'**
  String get detailDesSeances;

  /// No description provided for @transmettre.
  ///
  /// In fr, this message translates to:
  /// **'Transmettre'**
  String get transmettre;

  /// No description provided for @transmettreLaFiche.
  ///
  /// In fr, this message translates to:
  /// **'Transmettre la fiche'**
  String get transmettreLaFiche;

  /// No description provided for @transmettreFicheConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Transmettre au service la fiche de « {cours} » pour {mois} ? Elle ne sera plus modifiable tant qu\'il ne vous l\'aura pas renvoyée.'**
  String transmettreFicheConfirmation(String cours, String mois);

  /// No description provided for @aucunEtatPaiement.
  ///
  /// In fr, this message translates to:
  /// **'Aucun état de paiement arrêté pour cette année.'**
  String get aucunEtatPaiement;

  /// No description provided for @heuresEffectuees.
  ///
  /// In fr, this message translates to:
  /// **'Heures effectuées'**
  String get heuresEffectuees;

  /// No description provided for @heuresDeRattrapage.
  ///
  /// In fr, this message translates to:
  /// **'dont rattrapage'**
  String get heuresDeRattrapage;

  /// No description provided for @heuresRetenues.
  ///
  /// In fr, this message translates to:
  /// **'Heures retenues'**
  String get heuresRetenues;

  /// No description provided for @montantBrut.
  ///
  /// In fr, this message translates to:
  /// **'Montant brut'**
  String get montantBrut;

  /// No description provided for @montantNet.
  ///
  /// In fr, this message translates to:
  /// **'Net à payer'**
  String get montantNet;

  /// No description provided for @precompte.
  ///
  /// In fr, this message translates to:
  /// **'Précompte'**
  String get precompte;

  /// No description provided for @precompteAuTaux.
  ///
  /// In fr, this message translates to:
  /// **'Précompte ({taux} %)'**
  String precompteAuTaux(String taux);

  /// No description provided for @precompteExonere.
  ///
  /// In fr, this message translates to:
  /// **'Précompte (exonéré)'**
  String get precompteExonere;

  /// No description provided for @payeLe.
  ///
  /// In fr, this message translates to:
  /// **'Payé le {date}'**
  String payeLe(String date);

  /// No description provided for @paiementBloque.
  ///
  /// In fr, this message translates to:
  /// **'Paiement bloqué'**
  String get paiementBloque;

  /// No description provided for @reservesDuMois.
  ///
  /// In fr, this message translates to:
  /// **'Réserves du mois'**
  String get reservesDuMois;

  /// No description provided for @vacationsExamen.
  ///
  /// In fr, this message translates to:
  /// **'Vacations d\'examen'**
  String get vacationsExamen;

  /// No description provided for @commissions.
  ///
  /// In fr, this message translates to:
  /// **'Commissions'**
  String get commissions;

  /// No description provided for @surveillance.
  ///
  /// In fr, this message translates to:
  /// **'Surveillance'**
  String get surveillance;

  /// No description provided for @sectionEnseignements.
  ///
  /// In fr, this message translates to:
  /// **'Mes enseignements'**
  String get sectionEnseignements;

  /// No description provided for @avancementDeMesCours.
  ///
  /// In fr, this message translates to:
  /// **'Avancement de mes cours'**
  String get avancementDeMesCours;

  /// No description provided for @aucunCoursAffecte.
  ///
  /// In fr, this message translates to:
  /// **'Aucun cours ne vous est affecté pour cette année académique.'**
  String get aucunCoursAffecte;

  /// No description provided for @seancesObservees.
  ///
  /// In fr, this message translates to:
  /// **'Séances observées'**
  String get seancesObservees;

  /// No description provided for @seancesObserveesAide.
  ///
  /// In fr, this message translates to:
  /// **'Ce que le service a relevé lors de ses passages en salle.'**
  String get seancesObserveesAide;

  /// No description provided for @aucuneSeanceObservee.
  ///
  /// In fr, this message translates to:
  /// **'Aucune séance observée pour le moment.'**
  String get aucuneSeanceObservee;

  /// No description provided for @absencesConstatees.
  ///
  /// In fr, this message translates to:
  /// **'Absences constatées'**
  String get absencesConstatees;

  /// No description provided for @rattrapagesOuverts.
  ///
  /// In fr, this message translates to:
  /// **'Rattrapages ouverts'**
  String get rattrapagesOuverts;

  /// No description provided for @chapitres.
  ///
  /// In fr, this message translates to:
  /// **'Chapitres'**
  String get chapitres;

  /// No description provided for @seances.
  ///
  /// In fr, this message translates to:
  /// **'Séances'**
  String get seances;

  /// No description provided for @seancesNonSuivies.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{1 séance prévue non relevée} other{{nombre} séances prévues non relevées}}'**
  String seancesNonSuivies(int nombre);

  /// No description provided for @derniereSeance.
  ///
  /// In fr, this message translates to:
  /// **'Dernière séance : {date}'**
  String derniereSeance(String date);

  /// No description provided for @retoursEtudiants.
  ///
  /// In fr, this message translates to:
  /// **'Retours des étudiants'**
  String get retoursEtudiants;

  /// No description provided for @retoursEtudiantsAide.
  ///
  /// In fr, this message translates to:
  /// **'Synthèses que le service a choisi de partager avec vous.'**
  String get retoursEtudiantsAide;

  /// No description provided for @chapitreAtteint.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre atteint : {numero}'**
  String chapitreAtteint(int numero);

  /// No description provided for @suiteADonner.
  ///
  /// In fr, this message translates to:
  /// **'Suite à donner : {suite}'**
  String suiteADonner(String suite);

  /// No description provided for @seanceCertifieeDOffice.
  ///
  /// In fr, this message translates to:
  /// **'Constat posé d\'office à la clôture de la journée : personne n\'a relevé cette séance.'**
  String get seanceCertifieeDOffice;

  /// No description provided for @discussionDeLaClasse.
  ///
  /// In fr, this message translates to:
  /// **'Discussion de la classe'**
  String get discussionDeLaClasse;

  /// No description provided for @sectionFeuillesDeNotes.
  ///
  /// In fr, this message translates to:
  /// **'Mes feuilles de notes'**
  String get sectionFeuillesDeNotes;

  /// No description provided for @aucuneFeuilleDeNotes.
  ///
  /// In fr, this message translates to:
  /// **'Aucune feuille de notes ne vous est attribuée pour le moment.'**
  String get aucuneFeuilleDeNotes;

  /// No description provided for @feuilleDeliberee.
  ///
  /// In fr, this message translates to:
  /// **'Délibérée — plus modifiable'**
  String get feuilleDeliberee;

  /// No description provided for @feuilleVerrouillee.
  ///
  /// In fr, this message translates to:
  /// **'Cette feuille a été délibérée : ses notes ne se modifient plus.'**
  String get feuilleVerrouillee;

  /// No description provided for @caseVideTitre.
  ///
  /// In fr, this message translates to:
  /// **'Une case vide n\'est pas un zéro'**
  String get caseVideTitre;

  /// No description provided for @caseVideExplication.
  ///
  /// In fr, this message translates to:
  /// **'Si l\'épreuve n\'a pas eu lieu pour un étudiant, choisissez le statut qui l\'explique : une absence justifiée ou une dispense retire l\'épreuve du calcul et redistribue son poids, tandis qu\'une absence non justifiée compte pour zéro.'**
  String get caseVideExplication;

  /// No description provided for @controleContinu.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle continu'**
  String get controleContinu;

  /// No description provided for @controleContinuExplication.
  ///
  /// In fr, this message translates to:
  /// **'Déclarez chaque contrôle quand vous le tenez. Vos contrôles d\'un même type sont moyennés entre eux, puis chaque type pèse de la pondération fixée par le service. Rendez-le au service quand vous avez terminé : vous ne pourrez plus ajouter ni modifier de contrôle, mais le service peut vous le renvoyer si besoin.'**
  String get controleContinuExplication;

  /// No description provided for @controleContinuRenduLecture.
  ///
  /// In fr, this message translates to:
  /// **'Le contrôle continu a été rendu au service : ses notes ne se modifient plus d\'ici.'**
  String get controleContinuRenduLecture;

  /// No description provided for @aucunControle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun contrôle déclaré pour le moment.'**
  String get aucunControle;

  /// No description provided for @nouveauControle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau contrôle'**
  String get nouveauControle;

  /// No description provided for @ajouterLeControle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter le contrôle'**
  String get ajouterLeControle;

  /// No description provided for @typeDeControle.
  ///
  /// In fr, this message translates to:
  /// **'Type de contrôle'**
  String get typeDeControle;

  /// No description provided for @date.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @supprimerControle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce contrôle'**
  String get supprimerControle;

  /// No description provided for @supprimerControleConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {libelle} » et ses notes ?'**
  String supprimerControleConfirmation(String libelle);

  /// No description provided for @rendreControleContinu.
  ///
  /// In fr, this message translates to:
  /// **'Rendre le contrôle continu'**
  String get rendreControleContinu;

  /// No description provided for @rendreCcConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Une fois rendu, vous ne pouvez plus ajouter ni modifier de contrôle — le service peut vous le renvoyer si besoin.'**
  String get rendreCcConfirmation;

  /// No description provided for @rendre.
  ///
  /// In fr, this message translates to:
  /// **'Rendre'**
  String get rendre;

  /// No description provided for @rendreLesNotes.
  ///
  /// In fr, this message translates to:
  /// **'Rendre les notes ({epreuve})'**
  String rendreLesNotes(String epreuve);

  /// No description provided for @rendreEpreuveConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Une fois rendue, l\'épreuve passe au service et vous ne pouvez plus la modifier — il peut vous la renvoyer si besoin.'**
  String get rendreEpreuveConfirmation;

  /// No description provided for @epreuveAVenir.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get epreuveAVenir;

  /// No description provided for @epreuveAVenirExplication.
  ///
  /// In fr, this message translates to:
  /// **'La saisie s\'ouvre après la composition, une fois les copies anonymées.'**
  String get epreuveAVenirExplication;

  /// No description provided for @epreuveValidee.
  ///
  /// In fr, this message translates to:
  /// **'Validée par le service'**
  String get epreuveValidee;

  /// No description provided for @epreuveRendue.
  ///
  /// In fr, this message translates to:
  /// **'Rendue, en attente de validation'**
  String get epreuveRendue;

  /// No description provided for @controlesARendre.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =0{Aucun contrôle — à rendre quand vous avez terminé} =1{1 contrôle — à rendre quand vous avez terminé} other{{nombre} contrôles — à rendre quand vous avez terminé}}'**
  String controlesARendre(int nombre);

  /// No description provided for @notesASaisirSur.
  ///
  /// In fr, this message translates to:
  /// **'{manquantes, plural, =1{1 note encore à saisir sur {total}} other{{manquantes} notes encore à saisir sur {total}}}'**
  String notesASaisirSur(int manquantes, int total);

  /// No description provided for @saisieCompleteARendre.
  ///
  /// In fr, this message translates to:
  /// **'Saisie complète — reste à rendre'**
  String get saisieCompleteARendre;

  /// No description provided for @saisieComplete.
  ///
  /// In fr, this message translates to:
  /// **'Saisie complète'**
  String get saisieComplete;

  /// No description provided for @notesEncoreAttendues.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{1 note encore attendue} other{{nombre} notes encore attendues}}'**
  String notesEncoreAttendues(int nombre);

  /// No description provided for @aRendreAvant.
  ///
  /// In fr, this message translates to:
  /// **'À rendre avant le {date}'**
  String aRendreAvant(String date);

  /// No description provided for @messageDuService.
  ///
  /// In fr, this message translates to:
  /// **'Message du service'**
  String get messageDuService;

  /// No description provided for @notesSaisies.
  ///
  /// In fr, this message translates to:
  /// **'Notes saisies'**
  String get notesSaisies;

  /// No description provided for @notesSur.
  ///
  /// In fr, this message translates to:
  /// **'Notes sur {max}'**
  String notesSur(String max);

  /// No description provided for @ponderationDe.
  ///
  /// In fr, this message translates to:
  /// **'Pondération {valeur}'**
  String ponderationDe(String valeur);

  /// No description provided for @saisirParCode.
  ///
  /// In fr, this message translates to:
  /// **'Saisir par code d\'anonymat'**
  String get saisirParCode;

  /// No description provided for @saisieParCodeExplication.
  ///
  /// In fr, this message translates to:
  /// **'Les copies ne portent que leur code d\'anonymat : portez chaque note en face du code inscrit sur la copie. La correspondance entre un code et un étudiant n\'est connue que du service.'**
  String get saisieParCodeExplication;

  /// No description provided for @rechercherCode.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un code'**
  String get rechercherCode;

  /// No description provided for @aucuneCopieCodee.
  ///
  /// In fr, this message translates to:
  /// **'Aucune copie codée. Signalez-le au service.'**
  String get aucuneCopieCodee;

  /// No description provided for @aucunEtudiantSurFeuille.
  ///
  /// In fr, this message translates to:
  /// **'Aucun étudiant sur cette feuille. Signalez-le au service.'**
  String get aucunEtudiantSurFeuille;

  /// No description provided for @noteSaisie.
  ///
  /// In fr, this message translates to:
  /// **'Note saisie'**
  String get noteSaisie;

  /// No description provided for @noteInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un nombre.'**
  String get noteInvalide;

  /// No description provided for @noteTropHaute.
  ///
  /// In fr, this message translates to:
  /// **'La note ne peut pas dépasser {max}.'**
  String noteTropHaute(String max);

  /// No description provided for @enregistrerLesNotes.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les notes'**
  String get enregistrerLesNotes;

  /// No description provided for @aucuneModification.
  ///
  /// In fr, this message translates to:
  /// **'Aucune modification à enregistrer.'**
  String get aucuneModification;

  /// No description provided for @notesNonEnregistrees.
  ///
  /// In fr, this message translates to:
  /// **'Notes non enregistrées'**
  String get notesNonEnregistrees;

  /// No description provided for @notesNonEnregistreesTexte.
  ///
  /// In fr, this message translates to:
  /// **'Des notes de cette page n\'ont pas été enregistrées. Les abandonner ?'**
  String get notesNonEnregistreesTexte;

  /// No description provided for @quitterSansEnregistrer.
  ///
  /// In fr, this message translates to:
  /// **'Quitter sans enregistrer'**
  String get quitterSansEnregistrer;

  /// No description provided for @enregistrerSansRendre.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer sans rendre'**
  String get enregistrerSansRendre;

  /// No description provided for @sectionDocumentsDeCours.
  ///
  /// In fr, this message translates to:
  /// **'Mes documents de cours'**
  String get sectionDocumentsDeCours;

  /// No description provided for @documentsCoursExplication.
  ///
  /// In fr, this message translates to:
  /// **'Le plan de cours et le support que le service vous demande, cours par cours. Rien n\'est visible des étudiants avant validation par le service.'**
  String get documentsCoursExplication;

  /// No description provided for @documentsACorriger.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{1 document vous a été renvoyé pour correction.} other{{nombre} documents vous ont été renvoyés pour correction.}}'**
  String documentsACorriger(int nombre);

  /// No description provided for @aucunDocumentDemande.
  ///
  /// In fr, this message translates to:
  /// **'Aucun document ne vous est demandé pour l\'instant. Le service ouvre les dépôts attendus en début de semestre.'**
  String get aucunDocumentDemande;

  /// No description provided for @planDeCours.
  ///
  /// In fr, this message translates to:
  /// **'Plan de cours'**
  String get planDeCours;

  /// No description provided for @supportDeCours.
  ///
  /// In fr, this message translates to:
  /// **'Support de cours'**
  String get supportDeCours;

  /// No description provided for @publieAuxEtudiants.
  ///
  /// In fr, this message translates to:
  /// **'Publié aux étudiants'**
  String get publieAuxEtudiants;

  /// No description provided for @aCorriger.
  ///
  /// In fr, this message translates to:
  /// **'À corriger'**
  String get aCorriger;

  /// No description provided for @transmisAuService.
  ///
  /// In fr, this message translates to:
  /// **'Transmis au service'**
  String get transmisAuService;

  /// No description provided for @fichierRecuPlanATransmettre.
  ///
  /// In fr, this message translates to:
  /// **'Fichier reçu — plan à vérifier et transmettre'**
  String get fichierRecuPlanATransmettre;

  /// No description provided for @aRemplirEtATransmettre.
  ///
  /// In fr, this message translates to:
  /// **'À remplir et à transmettre'**
  String get aRemplirEtATransmettre;

  /// No description provided for @pasEncoreRemis.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore remis'**
  String get pasEncoreRemis;

  /// No description provided for @enRetardDeJours.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{En retard de 1 jour} other{En retard de {nombre} jours}}'**
  String enRetardDeJours(int nombre);

  /// No description provided for @attendu.
  ///
  /// In fr, this message translates to:
  /// **'Attendu'**
  String get attendu;

  /// No description provided for @enAttenteDeValidation.
  ///
  /// In fr, this message translates to:
  /// **'En attente de validation'**
  String get enAttenteDeValidation;

  /// No description provided for @attenduAvantLe.
  ///
  /// In fr, this message translates to:
  /// **'Attendu avant le {date}'**
  String attenduAvantLe(String date);

  /// No description provided for @moratoireAccorde.
  ///
  /// In fr, this message translates to:
  /// **'Moratoire accordé'**
  String get moratoireAccorde;

  /// No description provided for @deposeLeDate.
  ///
  /// In fr, this message translates to:
  /// **'Déposé le {date}'**
  String deposeLeDate(String date);

  /// No description provided for @misAJourLeDate.
  ///
  /// In fr, this message translates to:
  /// **'Mis à jour le {date}'**
  String misAJourLeDate(String date);

  /// No description provided for @renvoyePourCorrectionLe.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyé pour correction le {date}'**
  String renvoyePourCorrectionLe(String date);

  /// No description provided for @fichierSeulNeVautPasDepot.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier seul ne vaut pas dépôt : remplissez le plan en ligne puis transmettez-le.'**
  String get fichierSeulNeVautPasDepot;

  /// No description provided for @remplirDepuisFichierDepose.
  ///
  /// In fr, this message translates to:
  /// **'Remplir le plan depuis le fichier déposé'**
  String get remplirDepuisFichierDepose;

  /// No description provided for @deposerLeFichierDuPlan.
  ///
  /// In fr, this message translates to:
  /// **'Déposer le fichier du plan'**
  String get deposerLeFichierDuPlan;

  /// No description provided for @planPagesAuPlus.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{Un plan tient en 1 page au plus.} other{Un plan tient en {nombre} pages au plus.}}'**
  String planPagesAuPlus(int nombre);

  /// No description provided for @ouRemplirEnLigne.
  ///
  /// In fr, this message translates to:
  /// **'Ou remplir en ligne, à la main'**
  String get ouRemplirEnLigne;

  /// No description provided for @remplirEnLigne.
  ///
  /// In fr, this message translates to:
  /// **'Remplir en ligne'**
  String get remplirEnLigne;

  /// No description provided for @modifierLePlanEnLigne.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le plan en ligne'**
  String get modifierLePlanEnLigne;

  /// No description provided for @consulter.
  ///
  /// In fr, this message translates to:
  /// **'Consulter'**
  String get consulter;

  /// No description provided for @planPublieModifiable.
  ///
  /// In fr, this message translates to:
  /// **'Plan validé et publié : le service vous laisse le modifier. Les étudiants sont informés de chaque mise à jour.'**
  String get planPublieModifiable;

  /// No description provided for @planPublieFige.
  ///
  /// In fr, this message translates to:
  /// **'Plan validé et publié : il ne se modifie plus. Contactez le service pour le rouvrir.'**
  String get planPublieFige;

  /// No description provided for @planTransmisExamine.
  ///
  /// In fr, this message translates to:
  /// **'Plan transmis : le service l\'examine. Il vous sera renvoyé s\'il faut le reprendre.'**
  String get planTransmisExamine;

  /// No description provided for @projetFinDeCours.
  ///
  /// In fr, this message translates to:
  /// **'Projet de fin de cours'**
  String get projetFinDeCours;

  /// No description provided for @deposerDesFichiers.
  ///
  /// In fr, this message translates to:
  /// **'Déposer des fichiers'**
  String get deposerDesFichiers;

  /// No description provided for @ajouterDesFichiers.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des fichiers'**
  String get ajouterDesFichiers;

  /// No description provided for @piecesLimites.
  ///
  /// In fr, this message translates to:
  /// **'{nombre} fichiers au plus, 5 Mo chacun. Les fichiers s\'ajoutent à ceux déjà déposés.'**
  String piecesLimites(int nombre);

  /// No description provided for @commentaireEtProjet.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire et projet de fin de cours'**
  String get commentaireEtProjet;

  /// No description provided for @supportPublieModifiable.
  ///
  /// In fr, this message translates to:
  /// **'Support validé et publié : le service vous laisse le modifier. Les étudiants sont informés de chaque mise à jour.'**
  String get supportPublieModifiable;

  /// No description provided for @supportPublieFige.
  ///
  /// In fr, this message translates to:
  /// **'Support validé et publié : il ne se modifie plus. Contactez le service pour rouvrir le dépôt.'**
  String get supportPublieFige;

  /// No description provided for @retirerCettePiece.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cette pièce'**
  String get retirerCettePiece;

  /// No description provided for @retirerPieceConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Retirer « {nom} » de ce dépôt ?'**
  String retirerPieceConfirmation(String nom);

  /// No description provided for @projetFinDeCoursQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Ce cours comporte un projet à déposer à la fin du cours'**
  String get projetFinDeCoursQuestion;

  /// No description provided for @descriptionDuProjet.
  ///
  /// In fr, this message translates to:
  /// **'Description du projet'**
  String get descriptionDuProjet;

  /// No description provided for @descriptionDuProjetAide.
  ///
  /// In fr, this message translates to:
  /// **'Sujet, livrables attendus, échéance…'**
  String get descriptionDuProjetAide;

  /// No description provided for @remplacerFichierDuProjet.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer le fichier du projet'**
  String get remplacerFichierDuProjet;

  /// No description provided for @fichierDuProjetFacultatif.
  ///
  /// In fr, this message translates to:
  /// **'Fichier du projet (facultatif)'**
  String get fichierDuProjetFacultatif;

  /// No description provided for @transmettreLePlan.
  ///
  /// In fr, this message translates to:
  /// **'Transmettre le plan'**
  String get transmettreLePlan;

  /// No description provided for @transmettrePlanConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Une fois transmis, le plan passe au service et ne se modifie plus d\'ici. Il vous sera renvoyé s\'il faut le reprendre.'**
  String get transmettrePlanConfirmation;

  /// No description provided for @remplacerLaSaisie.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer la saisie ?'**
  String get remplacerLaSaisie;

  /// No description provided for @remplacerLaSaisieTexte.
  ///
  /// In fr, this message translates to:
  /// **'La proposition de l\'assistant réécrira des lignes que vous venez de modifier sans les enregistrer.'**
  String get remplacerLaSaisieTexte;

  /// No description provided for @continuer.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continuer;

  /// No description provided for @analyseEnCours.
  ///
  /// In fr, this message translates to:
  /// **'Analyse en cours — cela peut prendre une minute. Ne quittez pas la page.'**
  String get analyseEnCours;

  /// No description provided for @documentAssistantTropLourd.
  ///
  /// In fr, this message translates to:
  /// **'Ce document dépasse 10 Mo : choisissez-en un plus léger.'**
  String get documentAssistantTropLourd;

  /// No description provided for @planNonEnregistre.
  ///
  /// In fr, this message translates to:
  /// **'Plan non enregistré'**
  String get planNonEnregistre;

  /// No description provided for @planNonEnregistreTexte.
  ///
  /// In fr, this message translates to:
  /// **'Votre saisie du plan n\'a pas été enregistrée. L\'abandonner ?'**
  String get planNonEnregistreTexte;

  /// No description provided for @planGeneral.
  ///
  /// In fr, this message translates to:
  /// **'Général'**
  String get planGeneral;

  /// No description provided for @travaux.
  ///
  /// In fr, this message translates to:
  /// **'Travaux'**
  String get travaux;

  /// No description provided for @seancesProgrammeesSur.
  ///
  /// In fr, this message translates to:
  /// **'{nombre} séance(s) programmée(s) sur {total} attendue(s)'**
  String seancesProgrammeesSur(int nombre, int total);

  /// No description provided for @planACorrigerConsigne.
  ///
  /// In fr, this message translates to:
  /// **'Corrigez le plan puis transmettez-le de nouveau : le service en sera prévenu.'**
  String get planACorrigerConsigne;

  /// No description provided for @planAttendu.
  ///
  /// In fr, this message translates to:
  /// **'Plan attendu'**
  String get planAttendu;

  /// No description provided for @planAttenduExplication.
  ///
  /// In fr, this message translates to:
  /// **'Le service de suivi académique attend ce plan : remplissez les rubriques puis transmettez-le. Il compte {nombre} séances, toutes à programmer avant de pouvoir être transmis ; les travaux à faire par l\'étudiant sont facultatifs. Le fichier de votre plan ne suffit pas : c\'est la transmission du plan rempli en ligne qui vaut dépôt.'**
  String planAttenduExplication(int nombre);

  /// No description provided for @propositionAVerifier.
  ///
  /// In fr, this message translates to:
  /// **'Proposition de l\'assistant d\'IA — à vérifier'**
  String get propositionAVerifier;

  /// No description provided for @propositionAVerifierTexte.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez chaque rubrique et corrigez-la au besoin : rien n\'est enregistré tant que vous n\'avez pas appuyé sur « Enregistrer » ou « Transmettre ».'**
  String get propositionAVerifierTexte;

  /// No description provided for @abandonnerLaProposition.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner la proposition'**
  String get abandonnerLaProposition;

  /// No description provided for @remplirDepuisVotreFichier.
  ///
  /// In fr, this message translates to:
  /// **'Remplir depuis votre fichier'**
  String get remplirDepuisVotreFichier;

  /// No description provided for @assistantPlanExplication.
  ///
  /// In fr, this message translates to:
  /// **'L\'assistant d\'IA lit votre plan et remplit les objectifs, les chapitres, les travaux et le programme des séances. Vous vérifiez, puis enregistrez ou transmettez : rien n\'est enregistré avant. Le document est transmis à Claude (Anthropic) pour l\'analyse.'**
  String get assistantPlanExplication;

  /// No description provided for @extraireContenuDe.
  ///
  /// In fr, this message translates to:
  /// **'Extraire le contenu de « {nom} »'**
  String extraireContenuDe(String nom);

  /// No description provided for @analyserUnAutreFichier.
  ///
  /// In fr, this message translates to:
  /// **'Analyser un autre fichier'**
  String get analyserUnAutreFichier;

  /// No description provided for @documentSourceDuPlan.
  ///
  /// In fr, this message translates to:
  /// **'Document source du pré-remplissage : {nom}, analysé le {date}.'**
  String documentSourceDuPlan(String nom, String date);

  /// No description provided for @objectifsDuCours.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs du cours'**
  String get objectifsDuCours;

  /// No description provided for @objectifsAide.
  ///
  /// In fr, this message translates to:
  /// **'« À la fin de ce cours, l\'étudiant sera capable de… » — un objectif par ligne.'**
  String get objectifsAide;

  /// No description provided for @aucunObjectif.
  ///
  /// In fr, this message translates to:
  /// **'Aucun objectif renseigné.'**
  String get aucunObjectif;

  /// No description provided for @chapitresAide.
  ///
  /// In fr, this message translates to:
  /// **'Le contenu de l\'enseignement, chapitre par chapitre. Un chapitre devient choisissable dans les séances une fois enregistré.'**
  String get chapitresAide;

  /// No description provided for @programmeAide.
  ///
  /// In fr, this message translates to:
  /// **'Une ligne par séance, de 1 à {nombre}. Les {nombre} séances sont exigées pour transmettre le plan.'**
  String programmeAide(int nombre);

  /// No description provided for @travauxAide.
  ///
  /// In fr, this message translates to:
  /// **'Les travaux à faire par l\'étudiant : une rubrique facultative.'**
  String get travauxAide;

  /// No description provided for @rienPourLeMoment.
  ///
  /// In fr, this message translates to:
  /// **'Rien pour le moment.'**
  String get rienPourLeMoment;

  /// No description provided for @ajouterUnChapitre.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un chapitre'**
  String get ajouterUnChapitre;

  /// No description provided for @ajouterUnTravail.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un travail'**
  String get ajouterUnTravail;

  /// No description provided for @chapitreNumero.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre {numero} : {titre}'**
  String chapitreNumero(String numero, String titre);

  /// No description provided for @seanceARemplir.
  ///
  /// In fr, this message translates to:
  /// **'À remplir'**
  String get seanceARemplir;

  /// No description provided for @aucun.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get aucun;

  /// No description provided for @valider.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get valider;

  /// No description provided for @retirerCetteLigne.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cette ligne'**
  String get retirerCetteLigne;

  /// No description provided for @numeroAbrege.
  ///
  /// In fr, this message translates to:
  /// **'N°'**
  String get numeroAbrege;

  /// No description provided for @intitule.
  ///
  /// In fr, this message translates to:
  /// **'Intitulé'**
  String get intitule;

  /// No description provided for @theme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get theme;

  /// No description provided for @elementsATraiter.
  ///
  /// In fr, this message translates to:
  /// **'Éléments à traiter'**
  String get elementsATraiter;

  /// No description provided for @competenceVisee.
  ///
  /// In fr, this message translates to:
  /// **'Compétence visée'**
  String get competenceVisee;

  /// No description provided for @competences.
  ///
  /// In fr, this message translates to:
  /// **'Compétences'**
  String get competences;

  /// No description provided for @contenus.
  ///
  /// In fr, this message translates to:
  /// **'Contenus'**
  String get contenus;

  /// No description provided for @lecturePreparatoire.
  ///
  /// In fr, this message translates to:
  /// **'Lecture préparatoire'**
  String get lecturePreparatoire;

  /// No description provided for @activiteDominante.
  ///
  /// In fr, this message translates to:
  /// **'Activité dominante'**
  String get activiteDominante;

  /// No description provided for @datePrevue.
  ///
  /// In fr, this message translates to:
  /// **'Date prévue'**
  String get datePrevue;

  /// No description provided for @dateDeRemise.
  ///
  /// In fr, this message translates to:
  /// **'Date de remise'**
  String get dateDeRemise;

  /// No description provided for @bareme.
  ///
  /// In fr, this message translates to:
  /// **'Barème'**
  String get bareme;

  /// No description provided for @sectionEpreuves.
  ///
  /// In fr, this message translates to:
  /// **'Mes épreuves d\'examen'**
  String get sectionEpreuves;

  /// No description provided for @aucuneEpreuveDemandee.
  ///
  /// In fr, this message translates to:
  /// **'Aucune épreuve ne vous est demandée pour le moment. Vous serez notifié dès que le service ouvrira le dépôt.'**
  String get aucuneEpreuveDemandee;

  /// No description provided for @epreuvesBilan.
  ///
  /// In fr, this message translates to:
  /// **'{demandees} demandée(s) · {completes} complète(s) · {retard} en retard'**
  String epreuvesBilan(int demandees, int completes, int retard);

  /// No description provided for @tousMesModeles.
  ///
  /// In fr, this message translates to:
  /// **'Tous mes modèles d\'épreuve (ZIP)'**
  String get tousMesModeles;

  /// No description provided for @depotAttendu.
  ///
  /// In fr, this message translates to:
  /// **'Dépôt attendu'**
  String get depotAttendu;

  /// No description provided for @sujetsAcceptes.
  ///
  /// In fr, this message translates to:
  /// **'Sujets acceptés'**
  String get sujetsAcceptes;

  /// No description provided for @aReprendre.
  ///
  /// In fr, this message translates to:
  /// **'À reprendre'**
  String get aReprendre;

  /// No description provided for @sujetsCompletsSur.
  ///
  /// In fr, this message translates to:
  /// **'{completes} sujet(s) complet(s) sur {requis}'**
  String sujetsCompletsSur(int completes, int requis);

  /// No description provided for @aDeposerAvant.
  ///
  /// In fr, this message translates to:
  /// **'À déposer avant le {date}'**
  String aDeposerAvant(String date);

  /// No description provided for @motifDeReprise.
  ///
  /// In fr, this message translates to:
  /// **'Motif de reprise'**
  String get motifDeReprise;

  /// No description provided for @sujetFrancaisAnglais.
  ///
  /// In fr, this message translates to:
  /// **'Sujet en français et en anglais'**
  String get sujetFrancaisAnglais;

  /// No description provided for @sujetFrancaisAnglaisTexte.
  ///
  /// In fr, this message translates to:
  /// **'Cette épreuve est composée par la classe francophone et la classe anglophone : chaque sujet se dépose dans les deux langues, et le dépôt n\'est complet qu\'une fois les deux versions remises.'**
  String get sujetFrancaisAnglaisTexte;

  /// No description provided for @consignesDuService.
  ///
  /// In fr, this message translates to:
  /// **'Consignes du service'**
  String get consignesDuService;

  /// No description provided for @sujetNumero.
  ///
  /// In fr, this message translates to:
  /// **'Sujet n° {numero}'**
  String sujetNumero(int numero);

  /// No description provided for @accepte.
  ///
  /// In fr, this message translates to:
  /// **'Accepté'**
  String get accepte;

  /// No description provided for @modeleARemplir.
  ///
  /// In fr, this message translates to:
  /// **'Modèle à remplir'**
  String get modeleARemplir;

  /// No description provided for @anglaisWord.
  ///
  /// In fr, this message translates to:
  /// **'Anglais (Word)'**
  String get anglaisWord;

  /// No description provided for @francaisWord.
  ///
  /// In fr, this message translates to:
  /// **'Français (Word)'**
  String get francaisWord;

  /// No description provided for @sujetVersion.
  ///
  /// In fr, this message translates to:
  /// **'Sujet — {version}'**
  String sujetVersion(String version);

  /// No description provided for @sujet.
  ///
  /// In fr, this message translates to:
  /// **'Sujet'**
  String get sujet;

  /// No description provided for @corrige.
  ///
  /// In fr, this message translates to:
  /// **'Corrigé'**
  String get corrige;

  /// No description provided for @manquantExige.
  ///
  /// In fr, this message translates to:
  /// **'Manquant, exigé'**
  String get manquantExige;

  /// No description provided for @facultatifPourCetteCampagne.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif pour cette campagne'**
  String get facultatifPourCetteCampagne;

  /// No description provided for @sujetAccepteFige.
  ///
  /// In fr, this message translates to:
  /// **'Sujet accepté par le service : il ne peut plus être modifié.'**
  String get sujetAccepteFige;

  /// No description provided for @depotClos.
  ///
  /// In fr, this message translates to:
  /// **'Le dépôt est clos pour cette campagne.'**
  String get depotClos;

  /// No description provided for @ajouterOuModifier.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des pièces ou modifier'**
  String get ajouterOuModifier;

  /// No description provided for @deposerCeSujet.
  ///
  /// In fr, this message translates to:
  /// **'Déposer ce sujet'**
  String get deposerCeSujet;

  /// No description provided for @deposer.
  ///
  /// In fr, this message translates to:
  /// **'Déposer'**
  String get deposer;

  /// No description provided for @piecesSajoutent.
  ///
  /// In fr, this message translates to:
  /// **'Énoncé, annexes, jeu de données : déposez chaque pièce. Les fichiers s\'ajoutent, aucun n\'est remplacé.'**
  String get piecesSajoutent;

  /// No description provided for @formatsAcceptes.
  ///
  /// In fr, this message translates to:
  /// **'Formats acceptés : {formats}.'**
  String formatsAcceptes(String formats);

  /// No description provided for @intituleDuSujetFacultatif.
  ///
  /// In fr, this message translates to:
  /// **'Intitulé du sujet (facultatif)'**
  String get intituleDuSujetFacultatif;

  /// No description provided for @fichiersDuSujet.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers du sujet'**
  String get fichiersDuSujet;

  /// No description provided for @fichiersSujetFrancais.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers du sujet — version française'**
  String get fichiersSujetFrancais;

  /// No description provided for @fichiersSujetAnglais.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers du sujet — version anglaise'**
  String get fichiersSujetAnglais;

  /// No description provided for @memeSujetTraduit.
  ///
  /// In fr, this message translates to:
  /// **'Le même sujet, traduit pour la classe anglophone.'**
  String get memeSujetTraduit;

  /// No description provided for @fichiersCorrigeExige.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers du corrigé (exigé)'**
  String get fichiersCorrigeExige;

  /// No description provided for @fichiersCorrigeFacultatif.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers du corrigé (facultatif)'**
  String get fichiersCorrigeFacultatif;

  /// No description provided for @dureeProposeeMinutes.
  ///
  /// In fr, this message translates to:
  /// **'Durée proposée (min)'**
  String get dureeProposeeMinutes;

  /// No description provided for @commentaireSujetAide.
  ///
  /// In fr, this message translates to:
  /// **'Matériel autorisé, remarques…'**
  String get commentaireSujetAide;

  /// No description provided for @informationsPersonnelles.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get informationsPersonnelles;

  /// No description provided for @coordonneesEtUrgence.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées et contact d\'urgence'**
  String get coordonneesEtUrgence;

  /// No description provided for @informationsProfessionnelles.
  ///
  /// In fr, this message translates to:
  /// **'Informations professionnelles'**
  String get informationsProfessionnelles;

  /// No description provided for @dossierAideProfessionnel.
  ///
  /// In fr, this message translates to:
  /// **'Votre cursus conditionne les cours qui peuvent vous être confiés ; le service revalide vos domaines après tout changement.'**
  String get dossierAideProfessionnel;

  /// No description provided for @dossierTenuParLeService.
  ///
  /// In fr, this message translates to:
  /// **'Le service de suivi académique est informé de vos modifications. Le grade, le département, les domaines et les cours sont fixés par le service : contactez-le si l\'un d\'eux est inexact.'**
  String get dossierTenuParLeService;

  /// No description provided for @ajouterUnDiplome.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un diplôme'**
  String get ajouterUnDiplome;

  /// No description provided for @modifierLeDiplome.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le diplôme'**
  String get modifierLeDiplome;

  /// No description provided for @ajouterUneCertification.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une certification'**
  String get ajouterUneCertification;

  /// No description provided for @modifierLaCertification.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la certification'**
  String get modifierLaCertification;

  /// No description provided for @ajouterUneExperience.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une expérience'**
  String get ajouterUneExperience;

  /// No description provided for @modifierLExperience.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'expérience'**
  String get modifierLExperience;

  /// No description provided for @supprimerCetteLigne.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette ligne ?'**
  String get supprimerCetteLigne;

  /// No description provided for @supprimerCetteLigneTexte.
  ///
  /// In fr, this message translates to:
  /// **'Elle sera retirée de votre dossier, avec sa pièce justificative.'**
  String get supprimerCetteLigneTexte;

  /// No description provided for @changerLaPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get changerLaPhoto;

  /// No description provided for @ajouterUnePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get ajouterUnePhoto;

  /// No description provided for @photoDossierAide.
  ///
  /// In fr, this message translates to:
  /// **'Photo d\'identité récente, au format JPG ou PNG.'**
  String get photoDossierAide;

  /// No description provided for @pieceDejaDeposee.
  ///
  /// In fr, this message translates to:
  /// **'Fichier déjà déposé : choisissez-en un autre pour le remplacer.'**
  String get pieceDejaDeposee;

  /// No description provided for @retirerLeFichierActuel.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le fichier actuel'**
  String get retirerLeFichierActuel;

  /// No description provided for @fichierRetireALEnregistrement.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier actuel sera retiré à l\'enregistrement.'**
  String get fichierRetireALEnregistrement;

  /// No description provided for @conserverLeFichier.
  ///
  /// In fr, this message translates to:
  /// **'Le conserver'**
  String get conserverLeFichier;

  /// No description provided for @effacerLaSelection.
  ///
  /// In fr, this message translates to:
  /// **'Effacer la sélection'**
  String get effacerLaSelection;

  /// No description provided for @rechercherDansLaListe.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher dans la liste'**
  String get rechercherDansLaListe;

  /// No description provided for @aucunChoixTrouve.
  ///
  /// In fr, this message translates to:
  /// **'Aucun choix ne correspond.'**
  String get aucunChoixTrouve;

  /// No description provided for @cursusAcademique.
  ///
  /// In fr, this message translates to:
  /// **'Cursus académique'**
  String get cursusAcademique;

  /// No description provided for @telephoneSecondaire.
  ///
  /// In fr, this message translates to:
  /// **'Second téléphone'**
  String get telephoneSecondaire;

  /// No description provided for @disponibleHorsLigne.
  ///
  /// In fr, this message translates to:
  /// **'Disponible hors ligne'**
  String get disponibleHorsLigne;

  /// No description provided for @horsLigne.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get horsLigne;

  /// No description provided for @envoyerMaintenant.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer maintenant'**
  String get envoyerMaintenant;

  /// No description provided for @saisieEnAttenteEnvoi.
  ///
  /// In fr, this message translates to:
  /// **'Sur le téléphone, en attente d\'envoi'**
  String get saisieEnAttenteEnvoi;

  /// No description provided for @saisieTransmise.
  ///
  /// In fr, this message translates to:
  /// **'Transmis'**
  String get saisieTransmise;

  /// No description provided for @saisieAArbitrer.
  ///
  /// In fr, this message translates to:
  /// **'À arbitrer par le service'**
  String get saisieAArbitrer;

  /// No description provided for @saisieEcartee.
  ///
  /// In fr, this message translates to:
  /// **'Écartée par le service'**
  String get saisieEcartee;

  /// No description provided for @saisieRefusee.
  ///
  /// In fr, this message translates to:
  /// **'Refusée, à refaire'**
  String get saisieRefusee;

  /// No description provided for @saisieGardeeSurLeTelephone.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré sur le téléphone. L\'envoi se fera tout seul dès le retour du réseau.'**
  String get saisieGardeeSurLeTelephone;

  /// No description provided for @saisieTransmiseAuService.
  ///
  /// In fr, this message translates to:
  /// **'Transmis au service, qui va trancher.'**
  String get saisieTransmiseAuService;

  /// No description provided for @saisieEnregistree.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré et transmis.'**
  String get saisieEnregistree;

  /// No description provided for @horsLigneJusquAu.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'au {date}'**
  String horsLigneJusquAu(String date);

  /// No description provided for @horsLigneMisAJour.
  ///
  /// In fr, this message translates to:
  /// **'Mis à jour le {date}'**
  String horsLigneMisAJour(String date);

  /// No description provided for @saisiesAEnvoyer.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{1 saisie à envoyer} other{{nombre} saisies à envoyer}}'**
  String saisiesAEnvoyer(int nombre);

  /// No description provided for @deconnexionAvecSaisies.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =1{1 saisie n\'a pas encore été envoyée : elle attendra votre prochaine connexion et ne partira pas d\'ici là. Vous déconnecter quand même ?} other{{nombre} saisies n\'ont pas encore été envoyées : elles attendront votre prochaine connexion et ne partiront pas d\'ici là. Vous déconnecter quand même ?}}'**
  String deconnexionAvecSaisies(int nombre);

  /// No description provided for @positionTropImprecise.
  ///
  /// In fr, this message translates to:
  /// **'Position trop imprécise ({precision} m, {max} m au plus). Rapprochez-vous d\'une fenêtre ou sortez à découvert, puis réessayez.'**
  String positionTropImprecise(int precision, int max);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
