import '../../../core/models/agenda.dart';
import '../../../core/models/champs.dart';
import '../../../core/models/json.dart';

// Feuilles de notes de l'enseignant (`lecturers/api/serializers.py`) : les
// chiffres du service, épreuve par épreuve. Le statut d'une épreuve, ses
// comptes et ce qui se modifie viennent du serveur, jamais d'un calcul d'ici.

/// Les quatre états d'une épreuve (`notes.choices.StatutEpreuve`).
class StatutsEpreuve {
  const StatutsEpreuve._();

  static const aVenir = 'a_venir';
  static const ouverte = 'ouverte';
  static const rendue = 'rendue';
  static const validee = 'validee';
}

/// Valeurs de statut d'une note dont le client tient compte en saisie.
class StatutsNote {
  const StatutsNote._();

  static const saisie = 'saisie';
  static const attendue = 'attendue';
}

/// Une épreuve d'une feuille : contrôle continu, intra, examen.
class EpreuveFeuille {
  const EpreuveFeuille({
    required this.type,
    this.typeLibelle = '',
    this.statut = '',
    this.anonyme = false,
    this.controleContinu = false,
    this.saisissable = false,
    this.dateLimite,
    this.commentaire = '',
    this.total = 0,
    this.saisies = 0,
    this.manquantes = 0,
    this.nbControles,
    this.copies = const [],
  });

  /// `cc`, `intra`, `examen`… : ce qui désigne l'épreuve à l'envoi.
  final String type;
  final String typeLibelle;
  final String statut;
  final bool anonyme;
  final bool controleContinu;
  final bool saisissable;
  final DateTime? dateLimite;

  /// Message du service (motif d'un renvoi).
  final String commentaire;
  final int total;
  final int saisies;
  final int manquantes;
  final int? nbControles;

  /// La grille par code d'une épreuve anonyme ouverte ; aucun nom.
  final List<LigneNote> copies;

  bool get estOuverte => statut == StatutsEpreuve.ouverte;

  factory EpreuveFeuille.depuisJson(Json json) => EpreuveFeuille(
        type: json.texte('type'),
        typeLibelle: json.texte('type_libelle'),
        statut: json.texte('statut'),
        anonyme: json.booleen('anonyme'),
        controleContinu: json.booleen('controle_continu'),
        saisissable: json.booleen('saisissable'),
        dateLimite: json.date('date_limite'),
        commentaire: json.texte('commentaire'),
        total: json.entier('total') ?? 0,
        saisies: json.entier('saisies') ?? 0,
        manquantes: json.entier('manquantes') ?? 0,
        nbControles: json.entier('nb_controles'),
        copies: json.liste('copies', LigneNote.depuisCopie),
      );
}

/// Une feuille de notes : un cours, une cohorte, une session.
class FeuilleNotes {
  const FeuilleNotes({
    required this.id,
    this.cours = const CoursRef(),
    this.niveau = '',
    this.programme = '',
    this.specialite = '',
    this.classe = '',
    this.semestre = '',
    this.sessionLibelle = '',
    this.statut = '',
    this.modifiable = true,
    this.epreuves = const [],
  });

  final int id;
  final CoursRef cours;
  final String niveau;
  final String programme;
  final String specialite;
  final String classe;
  final String semestre;
  final String sessionLibelle;
  final String statut;

  /// Faux une fois la feuille verrouillée par une délibération.
  final bool modifiable;
  final List<EpreuveFeuille> epreuves;

  /// « Licence 2 · Finance · Section francophone ».
  String get cohorte => [
        niveau,
        if (specialite.isNotEmpty) specialite else programme,
        classe,
      ].where((s) => s.isNotEmpty).join(' · ');

  factory FeuilleNotes.depuisJson(Json json) => FeuilleNotes(
        id: json.entier('id') ?? 0,
        cours: CoursRef.depuisJson(json.objet('cours')),
        niveau: json.objet('niveau')?.texte('nom') ?? '',
        programme: json.objet('programme')?.texte('nom') ?? '',
        specialite: json.objet('specialite')?.texte('nom') ?? '',
        classe: json.texte('classe'),
        semestre: json.objet('semestre')?.texte('nom') ?? '',
        sessionLibelle: json.texte('session_libelle'),
        statut: json.texte('statut'),
        modifiable: json['modifiable'] != false,
        epreuves: json.liste('epreuves', EpreuveFeuille.depuisJson),
      );
}

/// Réponse de `feuilles-de-notes/`.
class FeuillesDeNotes {
  const FeuillesDeNotes({this.feuilles = const [], this.aSaisir = 0});

  final List<FeuilleNotes> feuilles;
  final int aSaisir;

  factory FeuillesDeNotes.depuisJson(Json json) => FeuillesDeNotes(
        feuilles: json.liste('feuilles', FeuilleNotes.depuisJson),
        aSaisir: json.entier('a_saisir') ?? 0,
      );
}

/// Un contrôle continu déclaré.
class ControleDeFeuille {
  const ControleDeFeuille({
    required this.id,
    this.libelle = '',
    this.date,
    this.ponderation,
  });

  final int id;
  final String libelle;
  final DateTime? date;
  final double? ponderation;

  factory ControleDeFeuille.depuisJson(Json json) => ControleDeFeuille(
        id: json.entier('id') ?? 0,
        libelle: json.texte('libelle'),
        date: json.date('date'),
        ponderation: json.nombre('ponderation'),
      );
}

/// Une case de grille. Sur une copie anonyme, [titre] est le code et rien ne
/// nomme l'étudiant : le serveur ne l'envoie pas.
class LigneNote {
  const LigneNote({
    required this.id,
    required this.titre,
    this.sousTitre = '',
    this.valeur,
    this.statut = StatutsNote.attendue,
  });

  final int id;
  final String titre;
  final String sousTitre;
  final double? valeur;
  final String statut;

  factory LigneNote.depuisCopie(Json json) => LigneNote(
        id: json.entier('id') ?? 0,
        titre: json.texte('code'),
        valeur: json.nombre('valeur'),
        statut: json.texteOuNul('statut') ?? StatutsNote.attendue,
      );

  factory LigneNote.depuisControle(Json json) {
    final etudiant = json.objet('etudiant') ?? const {};
    return LigneNote(
      id: json.entier('id') ?? 0,
      titre: etudiant.texte('nom_complet'),
      sousTitre: etudiant.texte('matricule'),
      valeur: json.nombre('valeur'),
      statut: json.texteOuNul('statut') ?? StatutsNote.attendue,
    );
  }
}

/// Une case modifiée, telle qu'elle part au serveur. Une ligne absente de
/// l'envoi garde sa valeur.
class NoteAEnvoyer {
  const NoteAEnvoyer({required this.id, this.valeur, required this.statut});

  final int id;

  /// `12.5`, ou `null` pour une case vide.
  final String? valeur;
  final String statut;

  Json versJson() => {'id': id, 'valeur': valeur, 'statut': statut};
}

/// Lit une note saisie au téléphone : la virgule du clavier français vaut un
/// point. `null` pour un texte qui n'est pas un nombre positif.
double? lireNote(String texte) {
  final valeur = double.tryParse(texte.trim().replaceAll(',', '.'));
  return valeur == null || valeur < 0 ? null : valeur;
}

/// Réponse de `feuilles-de-notes/<id>/`.
class DetailFeuille {
  const DetailFeuille({
    required this.feuille,
    this.noteMax = 20,
    this.statutsDeNote = const [],
    this.ccModifiable = false,
    this.aUnControleContinu = false,
    this.controles = const [],
    this.formulaireControle = const DescriptionFormulaire([]),
    this.epreuvesAnonymes = const [],
  });

  final FeuilleNotes feuille;
  final double noteMax;
  final List<OptionChamp> statutsDeNote;
  final bool ccModifiable;
  final bool aUnControleContinu;
  final List<ControleDeFeuille> controles;
  final DescriptionFormulaire formulaireControle;
  final List<EpreuveFeuille> epreuvesAnonymes;

  EpreuveFeuille? get epreuveCc =>
      feuille.epreuves.where((e) => e.controleContinu).firstOrNull;

  factory DetailFeuille.depuisJson(Json json) {
    final cc = json.objet('controle_continu');
    return DetailFeuille(
      feuille: FeuilleNotes.depuisJson(json.objet('feuille') ?? const {}),
      noteMax: json.nombre('note_max') ?? 20,
      statutsDeNote: json.liste('statuts_de_note', OptionChamp.depuisJson),
      aUnControleContinu: cc != null,
      ccModifiable: cc?.booleen('modifiable') ?? false,
      controles: cc?.liste('controles', ControleDeFeuille.depuisJson) ?? const [],
      formulaireControle: cc == null
          ? const DescriptionFormulaire([])
          : DescriptionFormulaire.depuisJson(cc, 'champs'),
      epreuvesAnonymes:
          json.liste('epreuves_anonymes', EpreuveFeuille.depuisJson),
    );
  }
}

/// Réponse de `feuilles-de-notes/<id>/controles/<id>/`.
class DetailControle {
  const DetailControle({
    required this.controle,
    this.modifiable = false,
    this.noteMax = 20,
    this.statutsDeNote = const [],
    this.notes = const [],
  });

  final ControleDeFeuille controle;
  final bool modifiable;
  final double noteMax;
  final List<OptionChamp> statutsDeNote;
  final List<LigneNote> notes;

  factory DetailControle.depuisJson(Json json) => DetailControle(
        controle:
            ControleDeFeuille.depuisJson(json.objet('controle') ?? const {}),
        modifiable: json.booleen('modifiable'),
        noteMax: json.nombre('note_max') ?? 20,
        statutsDeNote: json.liste('statuts_de_note', OptionChamp.depuisJson),
        notes: json.liste('notes', LigneNote.depuisControle),
      );
}

/// Erreurs d'un envoi refusé, ligne par ligne, dans l'ordre de la grille
/// (`erreurs_tableaux.notes.lignes`).
List<Map<String, List<String>>> erreursDesLignes(Map<String, dynamic> corps) {
  final tableaux = corps['erreurs_tableaux'];
  final notes = tableaux is Map ? tableaux['notes'] : null;
  final lignes = notes is Map ? notes['lignes'] : null;
  if (lignes is! List) return const [];
  return [
    for (final ligne in lignes)
      if (ligne is Map)
        {
          for (final MapEntry(:key, :value) in ligne.entries)
            '$key': value is List ? [for (final m in value) '$m'] : ['$value'],
        }
      else
        const <String, List<String>>{},
  ];
}

/// Erreurs qui ne visent aucune ligne (`erreurs_tableaux.notes.ensemble`).
List<String> erreursDeLEnsemble(Map<String, dynamic> corps) {
  final tableaux = corps['erreurs_tableaux'];
  final notes = tableaux is Map ? tableaux['notes'] : null;
  final ensemble = notes is Map ? notes['ensemble'] : null;
  return ensemble is List ? [for (final m in ensemble) '$m'] : const [];
}
