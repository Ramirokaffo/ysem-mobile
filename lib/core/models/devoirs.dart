import 'json.dart';

/// Modèles des devoirs, communs aux espaces étudiant et enseignant
/// (`devoirs.serializers` côté serveur). La correction n'est rendue à
/// l'étudiant qu'une fois publiée par l'enseignant : c'est le serveur qui
/// décide de ce qui figure dans la charge, l'application l'affiche tel quel.

class PieceDevoir {
  const PieceDevoir({
    required this.id,
    this.nom = '',
    this.tailleLisible = '',
    this.previsualisable = false,
  });

  final int id;
  final String nom;
  final String tailleLisible;
  final bool previsualisable;

  factory PieceDevoir.depuisJson(Json json) => PieceDevoir(
        id: json.entier('id') ?? 0,
        nom: json.texte('nom'),
        tailleLisible: json.texte('taille_lisible'),
        previsualisable: json.booleen('previsualisable'),
      );
}

class PersonneDevoir {
  const PersonneDevoir({
    required this.id,
    this.matricule = '',
    this.nom = '',
    this.prenom = '',
  });

  final int id;
  final String matricule;
  final String nom;
  final String prenom;

  String get nomComplet => '$nom $prenom'.trim();

  factory PersonneDevoir.depuisJson(Json json) => PersonneDevoir(
        id: json.entier('id') ?? 0,
        matricule: json.texte('matricule'),
        nom: json.texte('nom'),
        prenom: json.texte('prenom'),
      );
}

class GroupeDeTravail {
  const GroupeDeTravail({required this.id, this.nom = '', this.membres = const []});

  final int id;
  final String nom;
  final List<PersonneDevoir> membres;

  factory GroupeDeTravail.depuisJson(Json json) => GroupeDeTravail(
        id: json.entier('id') ?? 0,
        nom: json.texte('nom'),
        membres: json.liste('membres', PersonneDevoir.depuisJson),
      );
}

class Devoir {
  const Devoir({
    required this.id,
    this.titre = '',
    this.consignes = '',
    this.cleClasse = '',
    this.coursIntitule = '',
    this.coursCode = '',
    this.cohorte = '',
    this.enseignant = '',
    this.dateLimite,
    this.echeancePassee = false,
    this.mode = 'individuel',
    this.modeLibelle = '',
    this.groupementId,
    this.groupementNom = '',
    this.noteSur,
    this.statut = '',
    this.statutLibelle = '',
    this.correctionsPublieesLe,
    this.pieces = const [],
  });

  final int id;
  final String titre;
  final String consignes;
  final String cleClasse;
  final String coursIntitule;
  final String coursCode;
  final String cohorte;
  final String enseignant;
  final DateTime? dateLimite;
  final bool echeancePassee;

  /// `individuel` ou `groupe`.
  final String mode;
  final String modeLibelle;
  final int? groupementId;
  final String groupementNom;

  /// `null` : le devoir n'est pas noté.
  final double? noteSur;

  /// `brouillon`, `publie`, `ferme`.
  final String statut;
  final String statutLibelle;
  final DateTime? correctionsPublieesLe;
  final List<PieceDevoir> pieces;

  bool get estDeGroupe => mode == 'groupe';
  bool get estNote => noteSur != null;
  bool get estBrouillon => statut == 'brouillon';
  bool get estOuvert => statut == 'publie';
  bool get correctionsPubliees => correctionsPublieesLe != null;

  factory Devoir.depuisJson(Json json) {
    final classe = json.objet('classe') ?? const {};
    final cours = classe.objet('cours') ?? const {};
    final groupement = json.objet('groupement');
    return Devoir(
      id: json.entier('id') ?? 0,
      titre: json.texte('titre'),
      consignes: json.texte('consignes'),
      cleClasse: classe.texte('cle'),
      coursIntitule: cours.texte('intitule'),
      coursCode: cours.texte('code'),
      cohorte: classe.texte('cohorte'),
      enseignant: json.texte('enseignant'),
      dateLimite: json.date('date_limite'),
      echeancePassee: json.booleen('echeance_passee'),
      mode: json.texte('mode'),
      modeLibelle: json.texte('mode_libelle'),
      groupementId: groupement?.entier('id'),
      groupementNom: groupement?.texte('nom') ?? '',
      noteSur: json.nombre('note_sur'),
      statut: json.texte('statut'),
      statutLibelle: json.texte('statut_libelle'),
      correctionsPublieesLe: json.date('corrections_publiees_le'),
      pieces: json.liste('pieces', PieceDevoir.depuisJson),
    );
  }
}

class RenduDevoir {
  const RenduDevoir({
    required this.id,
    this.texte = '',
    this.renduLe,
    this.misAJourLe,
    this.enRetard = false,
    this.deposePar = '',
    this.pieces = const [],
    this.nbPieces = 0,
    this.statutCorrection = '',
    this.statutCorrectionLibelle = '',
    this.note,
    this.commentaire = '',
  });

  final int id;
  final String texte;
  final DateTime? renduLe;
  final DateTime? misAJourLe;
  final bool enRetard;
  final String deposePar;
  final List<PieceDevoir> pieces;
  final int nbPieces;

  /// `a_corriger`, `corrige`, `non_rendu`, `dispense` — vide quand la
  /// correction n'est pas transmise.
  final String statutCorrection;
  final String statutCorrectionLibelle;
  final double? note;
  final String commentaire;

  bool get estRendu => renduLe != null;

  factory RenduDevoir.depuisJson(Json json) => RenduDevoir(
        id: json.entier('id') ?? 0,
        texte: json.texte('texte'),
        renduLe: json.date('rendu_le'),
        misAJourLe: json.date('mis_a_jour_le'),
        enRetard: json.booleen('en_retard'),
        deposePar: json.texte('depose_par'),
        pieces: json.liste('pieces', PieceDevoir.depuisJson),
        nbPieces: json.entier('nb_pieces') ?? 0,
        statutCorrection: json.texte('statut_correction'),
        statutCorrectionLibelle: json.texte('statut_correction_libelle'),
        note: json.nombre('note'),
        commentaire: json.texte('commentaire'),
      );
}

/// Les limites des pièces jointes, telles que le serveur les annonce.
class LimitesPieces {
  const LimitesPieces({this.maximum = 5, this.extensions = const [], this.champ = 'fichiers'});

  final int maximum;
  final List<String> extensions;
  final String champ;

  factory LimitesPieces.depuisJson(Json? json) => json == null
      ? const LimitesPieces()
      : LimitesPieces(
          maximum: json.entier('maximum') ?? 5,
          extensions: [
            for (final e in (json['extensions'] as List? ?? const [])) e.toString(),
          ],
          champ: json.texte('champ').isEmpty ? 'fichiers' : json.texte('champ'),
        );
}

// --------------------------------------------------------------------------
// Espace étudiant
// --------------------------------------------------------------------------

class EntreeDevoir {
  const EntreeDevoir({
    required this.devoir,
    this.etat = '',
    this.etatLibelle = '',
    this.groupe,
    this.sujet = '',
    this.rendu,
    this.correctionVisible = false,
    this.correction,
    this.modifiable = false,
    this.limites = const LimitesPieces(),
  });

  final Devoir devoir;

  /// `a_rendre`, `en_retard`, `rendu`, `corrige`, `ferme`.
  final String etat;
  final String etatLibelle;
  final GroupeDeTravail? groupe;
  final String sujet;
  final RenduDevoir? rendu;
  final bool correctionVisible;
  final RenduDevoir? correction;
  final bool modifiable;
  final LimitesPieces limites;

  factory EntreeDevoir.depuisJson(Json json) {
    final groupe = json.objet('groupe');
    final rendu = json.objet('rendu');
    final correction = json.objet('correction');
    return EntreeDevoir(
      devoir: Devoir.depuisJson(json.objet('devoir') ?? const {}),
      etat: json.texte('etat'),
      etatLibelle: json.texte('etat_libelle'),
      groupe: groupe == null ? null : GroupeDeTravail.depuisJson(groupe),
      sujet: json.texte('sujet'),
      rendu: rendu == null ? null : RenduDevoir.depuisJson(rendu),
      correctionVisible: json.booleen('correction_visible'),
      correction: correction == null ? null : RenduDevoir.depuisJson(correction),
      modifiable: json.booleen('modifiable'),
      limites: LimitesPieces.depuisJson(json.objet('pieces_jointes')),
    );
  }
}

class BlocDevoirs {
  const BlocDevoirs({this.cle = '', this.titre = '', this.vide = '', this.devoirs = const []});

  final String cle;
  final String titre;
  final String vide;
  final List<EntreeDevoir> devoirs;

  factory BlocDevoirs.depuisJson(Json json) => BlocDevoirs(
        cle: json.texte('cle'),
        titre: json.texte('titre'),
        vide: json.texte('vide'),
        devoirs: json.liste('devoirs', EntreeDevoir.depuisJson),
      );
}

class DevoirsEtudiant {
  const DevoirsEtudiant({this.blocs = const [], this.aRendre = 0});

  final List<BlocDevoirs> blocs;
  final int aRendre;

  factory DevoirsEtudiant.depuisJson(Json json) => DevoirsEtudiant(
        blocs: json.liste('blocs', BlocDevoirs.depuisJson),
        aRendre: json.entier('a_rendre') ?? 0,
      );
}

// --------------------------------------------------------------------------
// Espace enseignant
// --------------------------------------------------------------------------

class ClasseDevoir {
  const ClasseDevoir({required this.cle, this.coursIntitule = '', this.cohorte = '', this.effectif = 0});

  final String cle;
  final String coursIntitule;
  final String cohorte;
  final int effectif;

  String get libelle => '$coursIntitule — $cohorte';

  factory ClasseDevoir.depuisJson(Json json) => ClasseDevoir(
        cle: json.texte('cle'),
        coursIntitule: json.objet('cours')?.texte('intitule') ?? '',
        cohorte: json.texte('cohorte'),
        effectif: json.entier('effectif') ?? 0,
      );
}

class DevoirResume {
  const DevoirResume({required this.devoir, this.rendus = 0, this.aCorriger = 0, this.attendus = 0});

  final Devoir devoir;
  final int rendus;
  final int aCorriger;
  final int attendus;

  factory DevoirResume.depuisJson(Json json) => DevoirResume(
        devoir: Devoir.depuisJson(json),
        rendus: json.entier('rendus') ?? 0,
        aCorriger: json.entier('a_corriger') ?? 0,
        attendus: json.entier('attendus') ?? 0,
      );
}

class DevoirsEnseignant {
  const DevoirsEnseignant({
    this.classes = const [],
    this.devoirs = const [],
    this.aCorriger = 0,
    this.limites = const LimitesPieces(),
  });

  final List<ClasseDevoir> classes;
  final List<DevoirResume> devoirs;
  final int aCorriger;
  final LimitesPieces limites;

  factory DevoirsEnseignant.depuisJson(Json json) => DevoirsEnseignant(
        classes: json.liste('classes', ClasseDevoir.depuisJson),
        devoirs: json.liste('devoirs', DevoirResume.depuisJson),
        aCorriger: json.entier('a_corriger') ?? 0,
        limites: LimitesPieces.depuisJson(json.objet('pieces_jointes')),
      );
}

class LigneCorrection {
  const LigneCorrection({
    required this.cible,
    this.libelle = '',
    this.etudiant,
    this.groupe,
    this.sujet = '',
    this.rendu,
  });

  /// `s<id>` (étudiant) ou `g<id>` (groupe).
  final String cible;
  final String libelle;
  final PersonneDevoir? etudiant;
  final GroupeDeTravail? groupe;
  final String sujet;
  final RenduDevoir? rendu;

  factory LigneCorrection.depuisJson(Json json) {
    final etudiant = json.objet('etudiant');
    final groupe = json.objet('groupe');
    final rendu = json.objet('rendu');
    return LigneCorrection(
      cible: json.texte('cible'),
      libelle: json.texte('libelle'),
      etudiant: etudiant == null ? null : PersonneDevoir.depuisJson(etudiant),
      groupe: groupe == null ? null : GroupeDeTravail.depuisJson(groupe),
      sujet: json.texte('sujet'),
      rendu: rendu == null ? null : RenduDevoir.depuisJson(rendu),
    );
  }
}

class Choix {
  const Choix({required this.id, this.libelle = ''});

  final int id;
  final String libelle;

  factory Choix.depuisJson(Json json) =>
      Choix(id: json.entier('id') ?? 0, libelle: json.texte('libelle'));
}

class DevoirComplet {
  const DevoirComplet({
    required this.devoir,
    this.attendus = 0,
    this.rendus = 0,
    this.enRetard = 0,
    this.aCorriger = 0,
    this.lignes = const [],
    this.fige = false,
    this.sansGroupe = const [],
    this.controleVerse,
    this.feuilles = const [],
    this.typesControle = const [],
    this.avertissement,
  });

  final Devoir devoir;
  final int attendus;
  final int rendus;
  final int enRetard;
  final int aCorriger;
  final List<LigneCorrection> lignes;
  final bool fige;
  final List<PersonneDevoir> sansGroupe;
  final Choix? controleVerse;
  final List<Choix> feuilles;
  final List<Choix> typesControle;
  final String? avertissement;

  factory DevoirComplet.depuisJson(Json json) {
    final synthese = json.objet('synthese') ?? const {};
    final versement = json.objet('versement') ?? const {};
    final controle = versement.objet('controle');
    return DevoirComplet(
      devoir: Devoir.depuisJson(json),
      attendus: synthese.entier('attendus') ?? 0,
      rendus: synthese.entier('rendus') ?? 0,
      enRetard: synthese.entier('en_retard') ?? 0,
      aCorriger: synthese.entier('a_corriger') ?? 0,
      lignes: json.liste('lignes', LigneCorrection.depuisJson),
      fige: json.booleen('fige'),
      sansGroupe: json.liste('etudiants_sans_groupe', PersonneDevoir.depuisJson),
      controleVerse: controle == null ? null : Choix.depuisJson(controle),
      feuilles: versement.liste('feuilles', Choix.depuisJson),
      typesControle: versement.liste('types_controle', Choix.depuisJson),
      avertissement: json.objet('avertissement')?.texteOuNul('detail'),
    );
  }
}

class SeanceProposee {
  const SeanceProposee({required this.debut, this.salle = '', this.rattrapage = false});

  final DateTime debut;
  final String salle;
  final bool rattrapage;
}

class Groupement {
  const Groupement({
    required this.id,
    this.nom = '',
    this.cleClasse = '',
    this.coursIntitule = '',
    this.cohorte = '',
    this.groupes = const [],
    this.nbDevoirs = 0,
    this.etudiants = const [],
    this.compositionFigee = false,
  });

  final int id;
  final String nom;
  final String cleClasse;
  final String coursIntitule;
  final String cohorte;
  final List<GroupeDeTravail> groupes;
  final int nbDevoirs;

  /// Inscrits de la classe et leur groupe (`null` : aucun).
  final List<(PersonneDevoir, int?)> etudiants;
  final bool compositionFigee;

  factory Groupement.depuisJson(Json json) {
    final classe = json.objet('classe') ?? const {};
    return Groupement(
      id: json.entier('id') ?? 0,
      nom: json.texte('nom'),
      cleClasse: classe.texte('cle'),
      coursIntitule: classe.objet('cours')?.texte('intitule') ?? '',
      cohorte: classe.texte('cohorte'),
      groupes: json.liste('groupes', GroupeDeTravail.depuisJson),
      nbDevoirs: json.entier('nb_devoirs') ?? 0,
      etudiants: json.liste(
        'etudiants',
        (e) => (PersonneDevoir.depuisJson(e), e.entier('groupe')),
      ),
      compositionFigee: json.booleen('composition_figee'),
    );
  }
}

class PreparationDevoir {
  const PreparationDevoir({this.dateProposee, this.seances = const [], this.groupements = const []});

  final DateTime? dateProposee;
  final List<SeanceProposee> seances;
  final List<Groupement> groupements;

  factory PreparationDevoir.depuisJson(Json json) => PreparationDevoir(
        dateProposee: json.date('date_limite_proposee'),
        seances: json.liste(
          'seances',
          (s) => SeanceProposee(
            debut: s.date('debut') ?? DateTime.now(),
            salle: s.texte('salle'),
            rattrapage: s.booleen('rattrapage'),
          ),
        ),
        groupements: json.liste('groupements', Groupement.depuisJson),
      );
}
