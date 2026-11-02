import 'json.dart';
import 'messagerie.dart';

/// Modèles de `discussions/` : le groupe de chaque classe (un cours × une
/// cohorte), où se retrouvent l'enseignant et les inscrits.
/// Les discussions passées (année close, réorientation) se relisent.

class EnseignantDiscussion {
  const EnseignantDiscussion({this.nom = '', this.enLigne = false});

  final String nom;
  final bool enLigne;
}

class ClasseDiscussion {
  const ClasseDiscussion({
    required this.cle,
    this.coursCode = '',
    this.coursIntitule = '',
    this.cohorte = '',
    this.enseignants = const [],
    this.effectif,
    this.ouverte = true,
    this.nonLus = 0,
    this.dernierMessageLe,
    this.dernierMessage,
  });

  /// La clé que le web emploie : elle désigne la classe, la garde reste
  /// l'appartenance.
  final String cle;
  final String coursCode;
  final String coursIntitule;
  final String cohorte;
  final List<EnseignantDiscussion> enseignants;

  /// Inscrits de la classe : rendu à l'enseignant, pas à l'étudiant.
  final int? effectif;

  /// Faux pour une discussion passée : lecture seule.
  final bool ouverte;
  final int nonLus;
  final DateTime? dernierMessageLe;
  final MessageFil? dernierMessage;

  factory ClasseDiscussion.depuisJson(Json json) {
    final groupe = json.objet('groupe');
    final dernier = groupe?.objet('dernier_message');
    return ClasseDiscussion(
      cle: json.texte('cle'),
      coursCode: json.objet('cours')?.texte('code') ?? '',
      coursIntitule: json.objet('cours')?.texte('intitule') ?? '',
      cohorte: json.texte('cohorte'),
      enseignants: json.liste(
          'enseignants',
          (e) => EnseignantDiscussion(
              nom: e.texte('nom'), enLigne: e.booleen('en_ligne'))),
      effectif: json.entier('effectif'),
      ouverte: json['ouverte'] != false,
      nonLus: groupe?.entier('non_lus') ?? 0,
      dernierMessageLe: groupe?.date('dernier_message_le'),
      dernierMessage: dernier == null ? null : MessageFil.depuisJson(dernier),
    );
  }
}

class Discussions {
  const Discussions({this.classes = const [], this.passees = const []});

  final List<ClasseDiscussion> classes;
  final List<ClasseDiscussion> passees;

  factory Discussions.depuisJson(Json json) => Discussions(
        classes: json.liste('classes', ClasseDiscussion.depuisJson),
        passees: json.liste('discussions_passees', ClasseDiscussion.depuisJson),
      );
}
