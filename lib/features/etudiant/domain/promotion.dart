import '../../../core/models/json.dart';

/// Modèles de `promotion/` : les moyennes **arrêtées** de la classe et ses
/// majors. Aucune moyenne d'étudiant identifiable ; une moyenne de classe
/// sous le plancher d'effectif est rendue vide, jamais à zéro.

class SerieMoyenne {
  const SerieMoyenne({
    this.annee = '',
    this.libelle = '',
    this.moyenne,
    this.effectif = 0,
    this.suffisant = true,
  });

  final String annee;
  final String libelle;
  final double? moyenne;
  final int effectif;

  /// Faux : effectif sous le plancher, la moyenne n'est pas montrée.
  final bool suffisant;

  factory SerieMoyenne.depuisJson(Json json) => SerieMoyenne(
        annee: json.objet('annee')?.texte('nom') ?? '',
        libelle: json.texte('libelle'),
        moyenne: json.nombre('moyenne'),
        effectif: json.entier('effectif') ?? 0,
        suffisant: json['suffisant'] != false,
      );
}

class MoyennesNiveau {
  const MoyennesNiveau({
    this.libelle = '',
    this.series = const [],
    this.tendance,
    this.ecart,
    this.depuis = '',
    this.jusqua = '',
  });

  final String libelle;
  final List<SerieMoyenne> series;

  /// `hausse`, `baisse`, `stable`, ou `null` sans comparaison possible.
  final String? tendance;
  final double? ecart;
  final String depuis;
  final String jusqua;

  factory MoyennesNiveau.depuisJson(Json json) {
    final tendance = json.objet('tendance');
    return MoyennesNiveau(
      libelle: json.texte('libelle'),
      series: json.liste('series', SerieMoyenne.depuisJson),
      tendance: tendance?.texteOuNul('sens'),
      ecart: tendance?.nombre('ecart'),
      depuis: tendance?.objet('depuis')?.texte('nom') ?? '',
      jusqua: tendance?.objet('jusqu_a')?.texte('nom') ?? '',
    );
  }
}

class Major {
  const Major({this.nom = '', this.rang});

  final String nom;
  final int? rang;
}

class MajorsPromotion {
  const MajorsPromotion({
    this.annee = '',
    this.semestre = '',
    this.cohorte = '',
    this.session = '',
    this.sessionLibelle = '',
    this.majors = const [],
    this.effectif,
    this.partage = false,
  });

  final String annee;
  final String semestre;
  final String cohorte;
  final String session;
  final String sessionLibelle;
  final List<Major> majors;
  final int? effectif;

  /// Plusieurs étudiants partagent la première place.
  final bool partage;

  factory MajorsPromotion.depuisJson(Json json) => MajorsPromotion(
        annee: json.objet('annee')?.texte('nom') ?? '',
        semestre: json.objet('semestre')?.texte('nom') ?? '',
        cohorte: json.texte('cohorte'),
        session: json.texte('session'),
        sessionLibelle: json.texte('session_libelle'),
        majors: json.liste(
            'majors', (m) => Major(nom: m.texte('nom'), rang: m.entier('rang'))),
        effectif: json.entier('effectif'),
        partage: json.booleen('partage'),
      );
}

class Promotion {
  const Promotion({
    this.effectifMinimum = 0,
    this.niveaux = const [],
    this.majorsAnnee = const [],
    this.majorsHistoire = const [],
  });

  final int effectifMinimum;
  final List<MoyennesNiveau> niveaux;
  final List<MajorsPromotion> majorsAnnee;
  final List<MajorsPromotion> majorsHistoire;

  bool get estVide =>
      niveaux.isEmpty && majorsAnnee.isEmpty && majorsHistoire.isEmpty;

  factory Promotion.depuisJson(Json json) => Promotion(
        effectifMinimum: json.entier('effectif_minimum') ?? 0,
        niveaux: json.liste('niveaux', MoyennesNiveau.depuisJson),
        majorsAnnee: json.liste('majors_annee', MajorsPromotion.depuisJson),
        majorsHistoire:
            json.liste('majors_histoire', MajorsPromotion.depuisJson),
      );
}
