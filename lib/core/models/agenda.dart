// Briques d'agenda que les deux API rendent avec les mêmes fonctions
// (`student_portal/api/serializers.py`, reprises par l'API enseignant) : une
// séance ne se lit pas autrement selon l'espace qui l'affiche.

import 'json.dart';

class AnneeAcademique {
  const AnneeAcademique({required this.id, required this.nom, this.debut, this.fin});

  final int? id;
  final String nom;
  final DateTime? debut;
  final DateTime? fin;

  static AnneeAcademique? depuisJson(Json? json) => json == null
      ? null
      : AnneeAcademique(
          id: json.entier('id'),
          nom: json.texte('nom'),
          debut: json.date('debut'),
          fin: json.date('fin'),
        );
}

class Seance {
  const Seance({
    this.date,
    this.jourLibelle = '',
    this.debut,
    this.fin,
    this.coursCode = '',
    this.coursIntitule = '',
    this.coursIntituleEn = '',
    this.enseignant = '',
    this.salle = '',
    this.typeSeance = '',
    this.annulee = false,
    this.chomee = false,
    this.rattrapage = false,
    this.remplacement = false,
    this.langueLibelle = '',
    this.troncCommun = false,
    this.periode = '',
    this.classe = '',
    this.cohorte = '',
  });

  final DateTime? date;
  final String jourLibelle;

  /// `HH:MM`.
  final String? debut;
  final String? fin;
  final String coursCode;
  final String coursIntitule;
  final String coursIntituleEn;
  final String enseignant;
  final String salle;
  final String typeSeance;
  final bool annulee;
  final bool chomee;
  final bool rattrapage;
  final bool remplacement;
  final String langueLibelle;
  final bool troncCommun;

  /// Congé ou jour férié qui explique une séance chômée.
  final String periode;

  /// Nom de la classe (vide pour une séance commune à toute la cohorte).
  final String classe;

  /// « Licence 2 · Gestion · Finance » : à qui l'enseignant fait cours.
  final String cohorte;

  String intitule(String langue) =>
      langue == 'en' && coursIntituleEn.isNotEmpty ? coursIntituleEn : coursIntitule;

  factory Seance.depuisJson(Json json) {
    final creneau = json.objet('creneau');
    final cours = json.objet('cours');
    return Seance(
      date: json.date('date'),
      jourLibelle: json.texte('jour_libelle'),
      debut: creneau?.texteOuNul('debut'),
      fin: creneau?.texteOuNul('fin'),
      coursCode: cours?.texte('code_affiche') ?? '',
      coursIntitule: cours?.texte('intitule') ?? '',
      coursIntituleEn: cours?.texte('intitule_en') ?? '',
      enseignant: json.objet('enseignant')?.texte('nom') ?? '',
      salle: json.objet('salle')?.texte('nom') ?? '',
      typeSeance: json.texte('type_seance'),
      annulee: json.booleen('annulee'),
      chomee: json.booleen('chomee'),
      rattrapage: json.booleen('rattrapage'),
      remplacement: json.booleen('remplacement'),
      langueLibelle: json.texte('langue_libelle'),
      troncCommun: json.booleen('tronc_commun'),
      periode: json.objet('periode')?.texte('nom') ?? '',
      classe: json.texte('classe'),
      cohorte: json.texte('cohorte'),
    );
  }
}

class EvenementCalendrier {
  const EvenementCalendrier({
    required this.titre,
    this.categorie = '',
    this.debut,
    this.fin,
    this.libelleDate = '',
  });

  final String titre;
  final String categorie;
  final DateTime? debut;
  final DateTime? fin;

  /// Libellé de date composé par le serveur, dans la langue de l'étudiant.
  final String libelleDate;

  factory EvenementCalendrier.depuisJson(Json json) => EvenementCalendrier(
        titre: json.texte('titre'),
        categorie: json.texte('categorie'),
        debut: json.date('debut'),
        fin: json.date('fin'),
        libelleDate: json.texte('libelle_date'),
      );
}

/// La semaine affichée et ses voisines (bloc `semaine` des emplois du
/// temps des deux portails).
class SemaineScolarite {
  const SemaineScolarite({
    this.debut,
    this.fin,
    this.precedente,
    this.suivante,
    this.courante,
    this.estCourante = true,
  });

  final DateTime? debut;
  final DateTime? fin;
  final DateTime? precedente;
  final DateTime? suivante;
  final DateTime? courante;
  final bool estCourante;

  factory SemaineScolarite.depuisJson(Json? json) => json == null
      ? const SemaineScolarite()
      : SemaineScolarite(
          debut: json.date('debut'),
          fin: json.date('fin'),
          precedente: json.date('precedente'),
          suivante: json.date('suivante'),
          courante: json.date('courante'),
          estCourante: json.booleen('est_semaine_courante'),
        );
}

class Journee {
  const Journee({this.date, this.libelle = '', this.seances = const []});

  final DateTime? date;
  final String libelle;
  final List<Seance> seances;

  factory Journee.depuisJson(Json json) => Journee(
        date: json.date('date'),
        libelle: json.texte('libelle'),
        seances: json.liste('seances', Seance.depuisJson),
      );
}

/// Un cours tel que les API le rendent : `code` identifie, `code_affiche` se lit.
class CoursRef {
  const CoursRef({
    this.code = '',
    this.codeAffiche = '',
    this.intitule = '',
    this.intituleEn = '',
    this.credits,
  });

  /// Identifiant interne : ne s'affiche pas.
  final String code;
  final String codeAffiche;
  final String intitule;
  final String intituleEn;
  final int? credits;

  String libelle(String langue) =>
      langue == 'en' && intituleEn.isNotEmpty ? intituleEn : intitule;

  factory CoursRef.depuisJson(Json? json) => json == null
      ? const CoursRef()
      : CoursRef(
          code: json.texte('code'),
          codeAffiche: json.texte('code_affiche'),
          intitule: json.texte('intitule'),
          intituleEn: json.texte('intitule_en'),
          credits: json.entier('credits'),
        );
}
