import '../../../core/models/agenda.dart';
import '../../../core/models/enseignant.dart';
import '../../../core/models/json.dart';
import 'dossier.dart';

export '../../../core/models/agenda.dart';
export '../../../core/models/enseignant.dart';
export '../../../core/models/navigation.dart';

// Modèles de l'espace enseignant, lus depuis `lecturers/api/serializers.py`.
// Comme côté étudiant, ils ne recalculent rien.

/// Où en est la candidature (bloc du tableau de bord d'un candidat, ou
/// bienvenue d'un recrutement, affichée une seule fois).
class Candidature {
  const Candidature({
    this.afficher = false,
    this.etape = 0,
    this.etapes = 5,
    this.prochaineEtape = 1,
    this.progression = 0,
    this.soumise = false,
    this.soumiseLe,
    this.peutEtreResoumise = false,
    this.motifDernierRefus = '',
  });

  final bool afficher;
  final int etape;
  final int etapes;
  final int prochaineEtape;

  /// De 0 à 100.
  final int progression;
  final bool soumise;
  final DateTime? soumiseLe;
  final bool peutEtreResoumise;
  final String motifDernierRefus;

  factory Candidature.depuisJson(Json json) => Candidature(
        afficher: json.booleen('afficher'),
        etape: json.entier('etape') ?? 0,
        etapes: json.entier('etapes') ?? 5,
        prochaineEtape: json.entier('prochaine_etape') ?? 1,
        progression: (json.entier('progression') ?? 0).clamp(0, 100),
        soumise: json.booleen('soumise'),
        soumiseLe: json.date('soumise_le'),
        peutEtreResoumise: json.booleen('peut_etre_resoumise'),
        motifDernierRefus: json.objet('dernier_refus')?.texte('motif') ?? '',
      );
}

/// Réponse de `tableau-de-bord/`.
class TableauDeBordEnseignant {
  const TableauDeBordEnseignant({
    required this.enseignant,
    this.annee,
    this.candidature = const Candidature(),
    this.compteurs = const {},
    this.prochainesSeances = const [],
    this.prochainesDates = const [],
  });

  final Enseignant enseignant;
  final AnneeAcademique? annee;
  final Candidature candidature;

  /// Les pastilles immédiates du menu (`nav_fiches_a_signer`…).
  final Json compteurs;
  final List<Seance> prochainesSeances;
  final List<EvenementCalendrier> prochainesDates;

  int compteur(String cle) => compteurs.entier(cle) ?? 0;

  factory TableauDeBordEnseignant.depuisJson(Json json) =>
      TableauDeBordEnseignant(
        enseignant: Enseignant.depuisJson(json.objet('enseignant') ?? const {}),
        annee: AnneeAcademique.depuisJson(json.objet('annee')),
        candidature:
            Candidature.depuisJson(json.objet('candidature') ?? const {}),
        compteurs: json.objet('compteurs') ?? const {},
        prochainesSeances: json.liste('prochaines_seances', Seance.depuisJson),
        prochainesDates:
            json.liste('prochaines_dates', EvenementCalendrier.depuisJson),
      );
}

/// Un diplôme du cursus.
class LigneCursus {
  const LigneCursus({
    this.id = 0,
    required this.diplome,
    this.specialisation = '',
    this.etablissement = '',
    this.annee,
    this.pays = '',
    this.justificatif = false,
  });

  final int id;
  final String diplome;
  final String specialisation;
  final String etablissement;
  final int? annee;
  final String pays;
  final bool justificatif;

  factory LigneCursus.depuisJson(Json json) => LigneCursus(
        id: json.entier('id') ?? 0,
        diplome: json.texteOuNul('diplome_libelle') ?? json.texte('diplome'),
        specialisation: json.texte('specialization'),
        etablissement: json.texte('establishment'),
        annee: json.entier('year_obtained'),
        pays: json.texte('country'),
        justificatif: json.booleen('proof_document_depose'),
      );
}

/// Une certification.
class LigneCertification {
  const LigneCertification({
    this.id = 0,
    required this.intitule,
    this.organisme = '',
    this.annee,
    this.domaine = '',
  });

  final int id;
  final String intitule;
  final String organisme;
  final int? annee;
  final String domaine;

  factory LigneCertification.depuisJson(Json json) => LigneCertification(
        id: json.entier('id') ?? 0,
        intitule: json.texte('title'),
        organisme: json.texte('organisme'),
        annee: json.entier('year_obtained'),
        domaine: json.texte('domaine'),
      );
}

/// Une expérience, dans l'enseignement (`establishment`) ou en entreprise
/// (`company`, `position`).
class LigneExperience {
  const LigneExperience({
    this.id = 0,
    required this.organisme,
    this.poste = '',
    this.annees = 0,
    this.mois = 0,
    this.ville = '',
    this.pays = '',
    this.debut,
    this.fin,
  });

  final int id;
  final String organisme;
  final String poste;
  final int annees;
  final int mois;
  final String ville;
  final String pays;
  final DateTime? debut;
  final DateTime? fin;

  factory LigneExperience.depuisJson(Json json) => LigneExperience(
        id: json.entier('id') ?? 0,
        organisme: json.texteOuNul('establishment') ?? json.texte('company'),
        poste: json.texte('position'),
        annees: json.entier('years') ?? 0,
        mois: json.entier('months') ?? 0,
        ville: json.texte('city'),
        pays: json.texte('country'),
        debut: json.date('start_date'),
        fin: json.date('end_date'),
      );
}

/// Un domaine d'enseignement ou un cours proposé, et ce qu'en a décidé le
/// service.
class LigneValidee {
  const LigneValidee({
    required this.libelle,
    this.code = '',
    this.statut = '',
    this.statutLibelle = '',
  });

  final String libelle;
  final String code;
  final String statut;
  final String statutLibelle;
}

/// Réponse de `profil/` : le dossier et ce qui y manque.
class DossierEnseignant {
  const DossierEnseignant({
    required this.enseignant,
    this.dateNaissance,
    this.lieuNaissance = '',
    this.nationalite = '',
    this.regionOrigine = '',
    this.situationMatrimoniale = '',
    this.enfantsACharge,
    this.adresse = '',
    this.cni = '',
    this.niu = '',
    this.universiteRattachement = '',
    this.contactUrgenceNom = '',
    this.contactUrgenceTelephone = '',
    this.contactUrgenceRelation = '',
    this.cvDepose = false,
    this.cursus = const [],
    this.certifications = const [],
    this.experiencesEnseignement = const [],
    this.experiencesEntreprise = const [],
    this.domaines = const [],
    this.coursProposes = const [],
    this.piecesACompleter = const [],
    this.formulaires,
  });

  final Enseignant enseignant;
  final DateTime? dateNaissance;
  final String lieuNaissance;
  final String nationalite;
  final String regionOrigine;
  final String situationMatrimoniale;
  final int? enfantsACharge;
  final String adresse;
  final String cni;
  final String niu;
  final String universiteRattachement;
  final String contactUrgenceNom;
  final String contactUrgenceTelephone;
  final String contactUrgenceRelation;
  final bool cvDepose;
  final List<LigneCursus> cursus;
  final List<LigneCertification> certifications;
  final List<LigneExperience> experiencesEnseignement;
  final List<LigneExperience> experiencesEntreprise;
  final List<LigneValidee> domaines;
  final List<LigneValidee> coursProposes;

  /// Ce que le dossier attend encore — signalé, jamais opposé.
  final List<String> piecesACompleter;

  /// De quoi composer les écrans de saisie ; `null` face à un serveur qui ne
  /// les rend pas encore, et le dossier reste alors en lecture.
  final FormulairesDossier? formulaires;

  factory DossierEnseignant.depuisJson(Json json) {
    final d = json.objet('dossier') ?? const {};
    final urgence = d.objet('contact_urgence') ?? const {};
    final pieces = json['pieces_a_completer'];
    return DossierEnseignant(
      enseignant: Enseignant.depuisJson(d),
      dateNaissance: d.date('date_naissance'),
      lieuNaissance: d.texte('lieu_naissance'),
      nationalite: d.texte('nationalite'),
      regionOrigine: d.texteOuNul('region_origine_libelle') ??
          d.texte('region_origine'),
      situationMatrimoniale: d.texteOuNul('situation_matrimoniale_libelle') ??
          d.texte('situation_matrimoniale'),
      enfantsACharge: d.entier('enfants_a_charge'),
      adresse: d.texte('adresse'),
      cni: d.texte('cni'),
      niu: d.texte('niu'),
      universiteRattachement: d.texte('universite_rattachement'),
      contactUrgenceNom: urgence.texte('nom'),
      contactUrgenceTelephone: urgence.texte('telephone'),
      contactUrgenceRelation: urgence.texte('relation'),
      cvDepose: d.booleen('cv_depose'),
      cursus: d.liste('cursus', LigneCursus.depuisJson),
      certifications: d.liste('certifications', LigneCertification.depuisJson),
      experiencesEnseignement:
          d.liste('experiences_enseignement', LigneExperience.depuisJson),
      experiencesEntreprise:
          d.liste('experiences_entreprise', LigneExperience.depuisJson),
      domaines: d.liste(
        'domaines',
        (j) => LigneValidee(
          libelle: j.texte('domaine'),
          statut: j.texte('statut'),
          statutLibelle: j.texte('statut_libelle'),
        ),
      ),
      coursProposes: d.liste('cours_proposes', (j) {
        final cours = j.objet('cours') ?? const {};
        return LigneValidee(
          libelle: cours.texte('intitule'),
          code: cours.texte('code_affiche'),
          statut: j.texte('statut'),
          statutLibelle: j.texte('statut_libelle'),
        );
      }),
      piecesACompleter: pieces is List
          ? [for (final p in pieces) p.toString()]
          : const [],
      formulaires: FormulairesDossier.depuisJson(json),
    );
  }
}
