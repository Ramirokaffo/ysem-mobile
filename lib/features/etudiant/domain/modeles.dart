import '../../../core/models/etudiant.dart';
import '../../../core/models/agenda.dart';
import '../../../core/models/json.dart';

export '../../../core/models/agenda.dart';
export '../../../core/models/navigation.dart';

/// Modèles de l'espace étudiant, lus depuis les réponses de
/// `student_portal/api/serializers.py`. Ils ne recalculent rien : ce sont les
/// chiffres du service, mis en forme.

class Inscription {
  const Inscription({
    this.annee,
    this.niveau,
    this.programme,
    this.specialite,
    this.section = '',
    this.sectionLibelle = '',
    this.classe = '',
    this.inscrit = false,
    this.actif = false,
  });

  final AnneeAcademique? annee;
  final Reference? niveau;
  final Reference? programme;
  final Reference? specialite;
  final String section;
  final String sectionLibelle;
  final String classe;
  final bool inscrit;

  /// Inscription courante de l'étudiant (`StudentLevel.is_active`).
  final bool actif;

  /// « Licence 2 · Gestion · Section francophone ».
  String resume(String langue) => [
        niveau?.libelle(langue),
        programme?.libelle(langue),
        specialite?.libelle(langue),
        if (sectionLibelle.isNotEmpty) sectionLibelle,
      ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

  static Inscription? depuisJson(Json? json) => json == null
      ? null
      : Inscription(
          annee: AnneeAcademique.depuisJson(json.objet('annee')),
          niveau: Reference.depuisJson(json.objet('niveau')),
          programme: Reference.depuisJson(json.objet('programme')),
          specialite: Reference.depuisJson(json.objet('specialite')),
          section: json.texte('section'),
          sectionLibelle: json.texte('section_libelle'),
          classe: json.texte('classe'),
          inscrit: json.booleen('inscrit'),
          actif: json.booleen('actif'),
        );
}

class TotauxFinanciers {
  const TotauxFinanciers({
    this.totalDu = 0,
    this.paye = 0,
    this.resteAPayer = 0,
    this.echu = 0,
    this.couvertureMoratoires = 0,
  });

  final double totalDu;
  final double paye;
  final double resteAPayer;
  final double echu;
  final double couvertureMoratoires;

  factory TotauxFinanciers.depuisJson(Json json) => TotauxFinanciers(
        totalDu: json.nombre('total_du') ?? 0,
        paye: json.nombre('paye') ?? 0,
        resteAPayer: json.nombre('reste_a_payer') ?? 0,
        echu: json.nombre('echu') ?? 0,
        couvertureMoratoires: json.nombre('couverture_moratoires') ?? 0,
      );
}

class SituationFinanciere {
  const SituationFinanciere({
    required this.statut,
    required this.statutLibelle,
    required this.avancement,
    required this.totaux,
  });

  /// `up_to_date`, `overdue` ou `moratorium` (`payments.utils`).
  final String statut;
  final String statutLibelle;

  /// Part payée de l'exigible annuel, de 0 à 100.
  final int avancement;
  final TotauxFinanciers totaux;

  static SituationFinanciere? depuisJson(Json? json) => json == null
      ? null
      : SituationFinanciere(
          statut: json.texte('statut'),
          statutLibelle: json.texte('statut_libelle'),
          avancement: (json.entier('avancement') ?? 0).clamp(0, 100),
          totaux: TotauxFinanciers.depuisJson(json.objet('totaux') ?? const {}),
        );
}

class DocumentOfficiel {
  const DocumentOfficiel({
    required this.id,
    required this.typeLibelle,
    this.type = '',
    this.reference = '',
    this.statut = '',
    this.statutLibelle = '',
    this.creeLe,
    this.dechargeLe,
    this.annee = '',
    this.telechargeable = false,
    this.autorise = false,
    this.motifBlocage = '',
  });

  final int? id;
  final String type;
  final String typeLibelle;
  final String reference;
  final String statut;
  final String statutLibelle;
  final DateTime? creeLe;
  final DateTime? dechargeLe;

  /// Année académique de l'inscription à laquelle le document se rattache.
  final String annee;

  /// Le portail remet ce document (le certificat de scolarité seul).
  final bool telechargeable;

  /// La remise est permise ; sinon [motifBlocage] dit ce qui la retient
  /// (la situation financière de l'année).
  final bool autorise;
  final String motifBlocage;

  factory DocumentOfficiel.depuisJson(Json json) {
    final remise = json.objet('telechargement');
    return DocumentOfficiel(
      id: json.entier('id'),
      type: json.texte('type'),
      typeLibelle: json.texte('type_libelle'),
      reference: json.texte('reference'),
      statut: json.texte('statut'),
      statutLibelle: json.texte('statut_libelle'),
      creeLe: json.date('cree_le'),
      dechargeLe: json.date('decharge_le'),
      annee: json.objet('inscription')?.objet('annee')?.texte('nom') ?? '',
      telechargeable: remise != null,
      autorise: remise?.booleen('autorise') ?? false,
      motifBlocage: remise?.texte('motif_blocage') ?? '',
    );
  }
}

/// Réponse de `tableau-de-bord/`.
class TableauDeBord {
  const TableauDeBord({
    required this.etudiant,
    this.annee,
    this.inscription,
    this.situationFinanciere,
    this.prochainesSeances = const [],
    this.prochainesDates = const [],
    this.documentsRecents = const [],
  });

  final Etudiant etudiant;
  final AnneeAcademique? annee;
  final Inscription? inscription;
  final SituationFinanciere? situationFinanciere;
  final List<Seance> prochainesSeances;
  final List<EvenementCalendrier> prochainesDates;
  final List<DocumentOfficiel> documentsRecents;

  factory TableauDeBord.depuisJson(Json json) => TableauDeBord(
        etudiant: Etudiant.depuisJson(json.objet('etudiant') ?? const {}),
        annee: AnneeAcademique.depuisJson(json.objet('annee')),
        inscription: Inscription.depuisJson(json.objet('inscription')),
        situationFinanciere:
            SituationFinanciere.depuisJson(json.objet('situation_financiere')),
        prochainesSeances: json.liste('prochaines_seances', Seance.depuisJson),
        prochainesDates:
            json.liste('prochaines_dates', EvenementCalendrier.depuisJson),
        documentsRecents:
            json.liste('documents_recents', DocumentOfficiel.depuisJson),
      );
}

class ConnexionRecente {
  const ConnexionRecente({
    this.date,
    this.appareil = '',
    this.canalLibelle = '',
    this.appareilConnu = true,
  });

  final DateTime? date;
  final String appareil;
  final String canalLibelle;
  final bool appareilConnu;

  factory ConnexionRecente.depuisJson(Json json) => ConnexionRecente(
        date: json.date('date'),
        appareil: json.texte('appareil'),
        canalLibelle: json.texte('canal_libelle'),
        appareilConnu: json.booleen('appareil_connu'),
      );
}

/// Réponse de `profil/`.
class Profil {
  const Profil({
    required this.etudiant,
    this.villeResidence = '',
    this.quartierResidence = '',
    this.paysOrigine = '',
    this.regionOrigine = '',
    this.inscriptionCourante,
    this.connexionsRecentes = const [],
  });

  final Etudiant etudiant;
  final String villeResidence;
  final String quartierResidence;
  final String paysOrigine;
  final String regionOrigine;
  final Inscription? inscriptionCourante;
  final List<ConnexionRecente> connexionsRecentes;

  factory Profil.depuisJson(Json json) {
    final profil = json.objet('profil') ?? const {};
    final etatCivil = profil.objet('etat_civil') ?? const {};
    return Profil(
      etudiant: Etudiant.depuisJson(profil),
      villeResidence: etatCivil.texte('ville_residence'),
      quartierResidence: etatCivil.texte('quartier_residence'),
      paysOrigine: etatCivil.texte('pays_origine'),
      regionOrigine: etatCivil.texte('region_origine'),
      inscriptionCourante:
          Inscription.depuisJson(json.objet('inscription_courante')),
      connexionsRecentes:
          json.liste('connexions_recentes', ConnexionRecente.depuisJson),
    );
  }
}
