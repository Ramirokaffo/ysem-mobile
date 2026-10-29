import '../../../core/models/json.dart';
import 'modeles.dart';

/// Modèles de `notes/` (`student_portal/api/serializers.py::ligne_de_note`
/// et suivants).
///
/// **Une seule note par cours : la note retenue**, et seulement une fois la
/// délibération publiée. Avant le jury, seules les épreuves que le service a
/// validées (contrôle continu, intra) sont rendues ; rien ici ne doit dire
/// qu'une note a été révisée — le serveur ne l'envoie d'ailleurs pas.

class SemestreRef {
  const SemestreRef({this.id, this.nom = '', this.numero});

  final int? id;
  final String nom;
  final int? numero;

  static SemestreRef? depuisJson(Json? json) => json == null
      ? null
      : SemestreRef(
          id: json.entier('id'),
          nom: json.texte('nom'),
          numero: json.entier('numero'),
        );
}

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

class NoteControle {
  const NoteControle({
    this.libelle = '',
    this.date,
    this.typeLibelle = '',
    this.ponderation,
    this.note,
    this.statut = '',
    this.statutLibelle = '',
  });

  final String libelle;
  final DateTime? date;
  final String typeLibelle;
  final double? ponderation;
  final double? note;
  final String statut;
  final String statutLibelle;

  factory NoteControle.depuisJson(Json json) => NoteControle(
        libelle: json.texte('libelle'),
        date: json.date('date'),
        typeLibelle: json.texte('type_libelle'),
        ponderation: json.nombre('ponderation') ?? json.nombre('coefficient'),
        note: json.nombre('note'),
        statut: json.texte('statut'),
        statutLibelle: json.texte('statut_libelle'),
      );
}

/// Une épreuve validée par le service (contrôle continu, intra).
class EpreuveVisible {
  const EpreuveVisible({
    this.type = '',
    this.libelle = '',
    this.note,
    this.statut = '',
    this.statutLibelle = '',
    this.controles = const [],
  });

  final String type;
  final String libelle;
  final double? note;
  final String statut;
  final String statutLibelle;
  final List<NoteControle> controles;

  factory EpreuveVisible.depuisJson(Json json) => EpreuveVisible(
        type: json.texte('type'),
        libelle: json.texte('libelle'),
        note: json.nombre('note'),
        statut: json.texte('statut'),
        statutLibelle: json.texte('statut_libelle'),
        controles: json.liste('controles', NoteControle.depuisJson),
      );
}

class LigneNote {
  const LigneNote({
    required this.id,
    this.cours = const CoursRef(),
    this.uniteEnseignement = '',
    this.session = '',
    this.sessionLibelle = '',
    this.note,
    this.notePubliee = false,
    this.epreuves = const [],
    this.statut = '',
    this.statutLibelle = '',
    this.observation = '',
  });

  final int id;
  final CoursRef cours;

  /// Nom de l'unité d'enseignement, vide hors UE.
  final String uniteEnseignement;

  /// `normale` ou `rattrapage`.
  final String session;
  final String sessionLibelle;

  /// Note retenue, `null` tant que la délibération n'est pas publiée.
  final double? note;
  final bool notePubliee;
  final List<EpreuveVisible> epreuves;
  final String statut;
  final String statutLibelle;
  final String observation;

  bool get estRattrapage => session == 'rattrapage';

  factory LigneNote.depuisJson(Json json) => LigneNote(
        id: json.entier('id') ?? 0,
        cours: CoursRef.depuisJson(json.objet('cours')),
        uniteEnseignement:
            json.objet('unite_enseignement')?.texte('nom') ?? '',
        session: json.texte('session'),
        sessionLibelle: json.texte('session_libelle'),
        note: json.nombre('note'),
        notePubliee: json.booleen('note_publiee'),
        epreuves: json.liste('epreuves', EpreuveVisible.depuisJson),
        statut: json.texte('statut'),
        statutLibelle: json.texte('statut_libelle'),
        observation: json.texte('observation'),
      );
}

class SemestreNotes {
  const SemestreNotes({this.semestre, this.notes = const []});

  final SemestreRef? semestre;
  final List<LigneNote> notes;

  factory SemestreNotes.depuisJson(Json json) => SemestreNotes(
        semestre: SemestreRef.depuisJson(json.objet('semestre')),
        notes: json.liste('notes', LigneNote.depuisJson),
      );
}

/// Résultat figé par une délibération (semestre ou année).
class ResultatJury {
  const ResultatJury({
    this.semestre,
    this.session = '',
    this.moyenne,
    this.creditsAcquis,
    this.creditsRequis,
    this.grade = '',
    this.mention = '',
    this.decision = '',
    this.decisionLibelle = '',
    this.rang,
    this.effectif,
    this.coursARattraper = const [],
    this.observations = '',
    this.sessionClose = false,
  });

  final SemestreRef? semestre;
  final String session;
  final double? moyenne;
  final int? creditsAcquis;
  final int? creditsRequis;
  final String grade;
  final String mention;

  /// `AD`, `RAT`, `AJ` (semestre) ; `AD`, `ADD`, `RED`, `AJ`, `EXC` (année).
  final String decision;
  final String decisionLibelle;
  final int? rang;
  final int? effectif;

  /// Codes des cours à repasser (session normale).
  final List<String> coursARattraper;
  final String observations;

  /// La délibération finale du semestre est publiée : la liste des cours à
  /// repasser de la session normale n'a plus rien à annoncer.
  final bool sessionClose;

  bool get estRattrapage => session == 'rattrapage';

  factory ResultatJury.depuisJson(Json json) => ResultatJury(
        semestre: SemestreRef.depuisJson(json.objet('semestre')),
        session: json.texte('session'),
        moyenne: json.nombre('moyenne'),
        creditsAcquis: json.entier('credits_acquis'),
        creditsRequis: json.entier('credits_requis'),
        grade: json.texte('grade'),
        mention: json.texte('mention'),
        decision: json.texte('decision'),
        decisionLibelle: json.texte('decision_libelle'),
        rang: json.entier('rang'),
        effectif: json.entier('effectif'),
        coursARattraper: [
          for (final c in (json['cours_a_rattraper'] as List?) ?? const [])
            if ('$c'.trim().isNotEmpty) '$c'.trim(),
        ],
        observations: json.texte('observations'),
        sessionClose: json.booleen('session_close'),
      );
}

class ReleveDeNotes {
  const ReleveDeNotes({
    this.numero = '',
    this.version,
    this.emisLe,
    this.niveau = '',
    this.annee = '',
  });

  final String numero;
  final int? version;
  final DateTime? emisLe;
  final String niveau;
  final String annee;

  factory ReleveDeNotes.depuisJson(Json json) => ReleveDeNotes(
        numero: json.texte('numero'),
        version: json.entier('version'),
        emisLe: json.date('emis_le'),
        niveau: json.objet('niveau')?.texte('nom') ?? '',
        annee: json.objet('annee')?.texte('nom') ?? '',
      );
}

/// Réponse de `notes/`.
class Notes {
  const Notes({
    this.annee,
    this.semestres = const [],
    this.resultatsSemestre = const [],
    this.resultatAnnuel,
    this.releves = const [],
  });

  final AnneeAcademique? annee;
  final List<SemestreNotes> semestres;
  final List<ResultatJury> resultatsSemestre;
  final ResultatJury? resultatAnnuel;
  final List<ReleveDeNotes> releves;

  bool get estVide =>
      semestres.every((s) => s.notes.isEmpty) &&
      resultatsSemestre.isEmpty &&
      resultatAnnuel == null;

  /// Résultats d'un semestre, session normale d'abord.
  List<ResultatJury> resultatsDe(SemestreRef? semestre) {
    final lignes = resultatsSemestre
        .where((r) => r.semestre?.id == semestre?.id)
        .toList()
      ..sort((a, b) => (a.estRattrapage ? 1 : 0) - (b.estRattrapage ? 1 : 0));
    return lignes;
  }

  factory Notes.depuisJson(Json json) {
    final annuel = json.objet('resultat_annuel');
    return Notes(
      annee: AnneeAcademique.depuisJson(json.objet('annee')),
      semestres: json.liste('semestres', SemestreNotes.depuisJson),
      resultatsSemestre:
          json.liste('resultats_semestre', ResultatJury.depuisJson),
      resultatAnnuel: annuel == null ? null : ResultatJury.depuisJson(annuel),
      releves: json.liste('releves', ReleveDeNotes.depuisJson),
    );
  }
}
