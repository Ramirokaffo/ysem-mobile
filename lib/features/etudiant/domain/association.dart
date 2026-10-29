import '../../../core/models/json.dart';

/// Modèles de `association/` : la campagne de l'élection du président de
/// l'association, ses listes, le vote et le dépouillement. Le vote est
/// anonyme par construction : le système sait qu'un électeur a voté, jamais
/// pour qui. Le dépouillement ne contient que des nombres.

class Scrutin {
  const Scrutin({
    required this.id,
    this.libelle = '',
    this.statut = '',
    this.statutLibelle = '',
    this.dateVote,
    this.ouvertureUrnes,
    this.fermetureUrnes,
    this.consignes = '',
    this.urnesOuvertes = false,
    this.urnesAVenir = false,
    this.voteTermine = false,
    this.annule = false,
    this.motifAnnulation = '',
  });

  final int id;
  final String libelle;
  final String statut;
  final String statutLibelle;
  final DateTime? dateVote;
  final String? ouvertureUrnes;
  final String? fermetureUrnes;
  final String consignes;
  final bool urnesOuvertes;
  final bool urnesAVenir;
  final bool voteTermine;
  final bool annule;
  final String motifAnnulation;

  static Scrutin? depuisJson(Json? json) => json == null
      ? null
      : Scrutin(
          id: json.entier('id') ?? 0,
          libelle: json.texte('libelle'),
          statut: json.texte('statut'),
          statutLibelle: json.texte('statut_libelle'),
          dateVote: json.date('date_vote'),
          ouvertureUrnes: json.texteOuNul('ouverture_urnes'),
          fermetureUrnes: json.texteOuNul('fermeture_urnes'),
          consignes: json.texte('consignes'),
          urnesOuvertes: json.booleen('urnes_ouvertes'),
          urnesAVenir: json.booleen('urnes_a_venir'),
          voteTermine: json.booleen('vote_termine'),
          annule: json.booleen('annule'),
          motifAnnulation: json.texte('motif_annulation'),
        );
}

class MembreListe {
  const MembreListe({this.posteLibelle = '', this.nom = ''});

  final String posteLibelle;
  final String nom;
}

/// Une liste candidate (un « bureau ») : un candidat, son équipe, son
/// programme — rendu en entier sur sa propre ressource seulement.
class ListeCandidate {
  const ListeCandidate({
    required this.id,
    this.nom = '',
    this.slogan = '',
    this.candidat = '',
    this.couleur = '',
    this.membres = const [],
    this.programme,
    this.url,
  });

  final int id;
  final String nom;
  final String slogan;
  final String candidat;

  /// `#RRGGBB`, ou vide.
  final String couleur;
  final List<MembreListe> membres;

  /// HTML (éditeur du service) ; `null` hors de la ressource de la liste.
  final String? programme;

  /// Chemin de la liste d'un scrutin passé (historique).
  final String? url;

  factory ListeCandidate.depuisJson(Json json) => ListeCandidate(
        id: json.entier('id') ?? 0,
        nom: json.texte('nom'),
        slogan: json.texte('slogan'),
        candidat: json.texte('candidat'),
        couleur: json.texte('couleur'),
        membres: json.liste(
            'membres',
            (m) => MembreListe(
                posteLibelle: m.texte('poste_libelle'), nom: m.texte('nom'))),
        programme: json.texteOuNul('programme'),
        url: json.texteOuNul('url'),
      );
}

class LigneResultat {
  const LigneResultat({
    required this.liste,
    this.nom = '',
    this.candidat = '',
    this.couleur = '',
    this.voix = 0,
    this.part = 0,
  });

  final int liste;
  final String nom;
  final String candidat;
  final String couleur;
  final int voix;

  /// Part des suffrages exprimés, de 0 à 100.
  final double part;

  factory LigneResultat.depuisJson(Json json) => LigneResultat(
        liste: json.entier('bureau') ?? 0,
        nom: json.texte('nom'),
        candidat: json.texte('candidat'),
        couleur: json.texte('couleur'),
        voix: json.entier('voix') ?? 0,
        part: json.nombre('part') ?? 0,
      );
}

class Resultats {
  const Resultats({
    this.urnesOuvertes = false,
    this.voteTermine = false,
    this.inscrits = 0,
    this.votants = 0,
    this.exprimes = 0,
    this.participation = 0,
    this.lignes = const [],
    this.enTete = const [],
    this.elu,
  });

  final bool urnesOuvertes;
  final bool voteTermine;
  final int inscrits;
  final int votants;
  final int exprimes;

  /// De 0 à 100.
  final double participation;

  /// Classées par voix décroissantes.
  final List<LigneResultat> lignes;
  final List<int> enTete;

  /// La liste élue : un seul en tête, vote terminé. Égalité : aucun élu.
  final int? elu;

  bool get ballottage => voteTermine && elu == null && enTete.length > 1;

  static Resultats? depuisJson(Json? json) => json == null
      ? null
      : Resultats(
          urnesOuvertes: json.booleen('urnes_ouvertes'),
          voteTermine: json.booleen('vote_termine'),
          inscrits: json.entier('inscrits') ?? 0,
          votants: json.entier('votants') ?? 0,
          exprimes: json.entier('exprimes') ?? 0,
          participation: json.nombre('participation') ?? 0,
          lignes: json.liste('lignes', LigneResultat.depuisJson),
          enTete: [
            for (final v in (json['en_tete'] as List? ?? const []))
              if (v is int) v,
          ],
          elu: json.entier('elu'),
        );
}

class Association {
  const Association({
    this.scrutin,
    this.listes = const [],
    this.resultats,
    this.aVote = false,
    this.refus = '',
  });

  /// `null` : aucune campagne publiée.
  final Scrutin? scrutin;
  final List<ListeCandidate> listes;
  final Resultats? resultats;
  final bool aVote;

  /// Ce qui empêche de voter maintenant, ou vide.
  final String refus;

  bool get peutVoter =>
      scrutin != null && scrutin!.urnesOuvertes && !aVote && refus.isEmpty;

  factory Association.depuisJson(Json json) => Association(
        scrutin: Scrutin.depuisJson(json.objet('scrutin')),
        listes: json.liste('listes', ListeCandidate.depuisJson),
        resultats: Resultats.depuisJson(json.objet('resultats')),
        aVote: json.booleen('a_vote'),
        refus: json.texte('refus'),
      );
}

/// Un scrutin terminé de l'historique.
class ScrutinPasse {
  const ScrutinPasse({
    required this.scrutin,
    this.elu,
    this.ballottage = false,
    this.listes = const [],
    this.resultats,
  });

  final Scrutin scrutin;
  final int? elu;
  final bool ballottage;
  final List<ListeCandidate> listes;
  final Resultats? resultats;

  ListeCandidate? get listeElue {
    for (final l in listes) {
      if (l.id == elu) return l;
    }
    return null;
  }

  factory ScrutinPasse.depuisJson(Json json) => ScrutinPasse(
        scrutin: Scrutin.depuisJson(json.objet('scrutin')) ??
            const Scrutin(id: 0),
        elu: json.entier('elu'),
        ballottage: json.booleen('ballottage'),
        listes: json.liste('listes', ListeCandidate.depuisJson),
        resultats: Resultats.depuisJson(json.objet('resultats')),
      );
}
