import '../../../core/models/json.dart';
import 'modeles.dart';
import 'notes.dart';

/// Modèles de `examens/` (`serializers.planning_examens`, `creneau_examen`).

class CreneauExamen {
  const CreneauExamen({
    this.date,
    this.debut,
    this.fin,
    this.duree = '',
    this.intitule = '',
    this.pause = false,
    this.cours = const CoursRef(),
    this.salle = '',
    this.concerne = false,
  });

  final DateTime? date;
  final String? debut;
  final String? fin;
  final String duree;

  /// Intitulé porté par la ligne du planning, repli quand le cours manque.
  final String intitule;

  /// Ligne « Pause » du document.
  final bool pause;
  final CoursRef cours;
  final String salle;

  /// Épreuve que l'étudiant compose (planning de rattrapage : celles qu'il
  /// repasse).
  final bool concerne;

  String libelle(String langue) {
    final cours = this.cours.libelle(langue);
    return cours.isNotEmpty ? cours : intitule;
  }

  factory CreneauExamen.depuisJson(Json json) {
    final creneau = json.objet('creneau');
    return CreneauExamen(
      date: json.date('date'),
      debut: creneau?.texteOuNul('debut'),
      fin: creneau?.texteOuNul('fin'),
      duree: json.texte('duree'),
      intitule: json.texte('intitule'),
      pause: json.booleen('pause'),
      cours: CoursRef.depuisJson(json.objet('cours')),
      salle: json.objet('salle')?.texte('nom') ?? '',
      concerne: json.booleen('concerne'),
    );
  }
}

class PlanningExamens {
  const PlanningExamens({
    required this.id,
    this.titre = '',
    this.titreEn = '',
    this.session = '',
    this.sessionLibelle = '',
    this.typeExamenLibelle = '',
    this.cohorte = '',
    this.debut,
    this.fin,
    this.enCours = false,
    this.termine = false,
    this.nbEpreuves = 0,
    this.aUnPdf = false,
    this.creneaux = const [],
  });

  final int id;
  final String titre;
  final String titreEn;

  /// `normale` ou `rattrapage`.
  final String session;
  final String sessionLibelle;
  final String typeExamenLibelle;
  final String cohorte;
  final DateTime? debut;
  final DateTime? fin;
  final bool enCours;
  final bool termine;
  final int nbEpreuves;
  final bool aUnPdf;
  final List<CreneauExamen> creneaux;

  bool get estRattrapage => session == 'rattrapage';

  String libelle(String langue) =>
      langue == 'en' && titreEn.isNotEmpty ? titreEn : titre;

  /// Les lignes regroupées par journée, dans l'ordre du document.
  List<(DateTime?, List<CreneauExamen>)> get journees {
    final resultat = <(DateTime?, List<CreneauExamen>)>[];
    for (final ligne in creneaux) {
      if (resultat.isEmpty || resultat.last.$1 != ligne.date) {
        resultat.add((ligne.date, [ligne]));
      } else {
        resultat.last.$2.add(ligne);
      }
    }
    return resultat;
  }

  factory PlanningExamens.depuisJson(Json json) => PlanningExamens(
        id: json.entier('id') ?? 0,
        titre: json.texte('titre'),
        titreEn: json.texte('titre_en'),
        session: json.texte('session'),
        sessionLibelle: json.texte('session_libelle'),
        typeExamenLibelle: json.texte('type_examen_libelle'),
        cohorte: json.texte('cohorte'),
        debut: json.date('debut'),
        fin: json.date('fin'),
        enCours: json.booleen('en_cours'),
        termine: json.booleen('termine'),
        nbEpreuves: json.entier('nb_epreuves') ?? 0,
        aUnPdf: json.texteOuNul('pdf') != null,
        creneaux: json.liste('creneaux', CreneauExamen.depuisJson),
      );
}

/// Réponse de `examens/`.
class Examens {
  const Examens({this.annee, this.plannings = const []});

  final AnneeAcademique? annee;
  final List<PlanningExamens> plannings;

  factory Examens.depuisJson(Json json) => Examens(
        annee: AnneeAcademique.depuisJson(json.objet('annee')),
        plannings: json.liste('plannings', PlanningExamens.depuisJson),
      );
}
