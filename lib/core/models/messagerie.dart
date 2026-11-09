import 'json.dart';

/// Modèles d'un fil de messages : le fil de l'étudiant avec le guichet de la
/// scolarité (`messages/`) et les discussions de classe des deux espaces
/// (`discussions/<cle>/messages/`). La charge d'un message est **celle que le
/// websocket pousse au navigateur** (`Message.as_payload`), commune aux chats :
/// web et mobile lisent le même message.

/// Côté du guichet de l'étudiant, et sa clé de lecteur dans les réactions.
const campEtudiant = 'student';

const reactionJaime = 'like';
const reactionJaimePas = 'dislike';

class PieceMessage {
  const PieceMessage({
    required this.id,
    this.nom = '',
    this.taille = 0,
    this.tailleLisible = '',
    this.estImage = false,
    this.estPdf = false,
  });

  final int id;
  final String nom;
  final int taille;
  final String tailleLisible;
  final bool estImage;
  final bool estPdf;

  factory PieceMessage.depuisJson(Json json) => PieceMessage(
        id: json.entier('id') ?? 0,
        nom: json.texte('nom'),
        taille: json.entier('taille') ?? 0,
        tailleLisible: json.texte('taille_lisible'),
        estImage: json.booleen('est_image'),
        estPdf: json.booleen('est_pdf'),
      );
}

/// Le message auquel on répond, tel que la bulle le cite.
class Citation {
  const Citation({required this.id, this.auteur = '', this.extrait = ''});

  final int id;
  final String auteur;
  final String extrait;

  static Citation? depuisJson(Json? json) => json == null
      ? null
      : Citation(
          id: json.entier('id') ?? 0,
          auteur: json.texte('auteur'),
          extrait: json.texte('extrait'),
        );
}

/// Comptes d'une réaction. Le résumé est impersonnel : chacun reconnaît la
/// sienne à sa clé de lecteur (`student` pour l'étudiant).
class ResumeReaction {
  const ResumeReaction({this.nombre = 0, this.lecteurs = const []});

  final int nombre;
  final List<String> lecteurs;

  factory ResumeReaction.depuisJson(Json json) => ResumeReaction(
        nombre: json.entier('nombre') ?? 0,
        lecteurs: [
          for (final l in (json['lecteurs'] as List? ?? const [])) '$l',
        ],
      );
}

Map<String, ResumeReaction> lireReactions(Object? brut) {
  if (brut is! Map) return const {};
  return {
    for (final MapEntry(:key, :value) in brut.entries)
      if (value is Map)
        '$key': ResumeReaction.depuisJson(Map<String, dynamic>.from(value)),
  };
}

/// Aperçu d'un lien déjà relevé par le serveur (l'image n'est pas reprise :
/// elle n'est servie qu'à une session de navigateur).
class ApercuLien {
  const ApercuLien({this.url = '', this.titre = '', this.site = ''});

  final String url;
  final String titre;
  final String site;

  static ApercuLien? depuisJson(Json? json) {
    if (json == null) return null;
    final apercu = ApercuLien(
      url: json.texte('url'),
      titre: json.texte('titre'),
      site: json.texte('site'),
    );
    return apercu.titre.isEmpty && apercu.site.isEmpty ? null : apercu;
  }
}

class MessageFil {
  const MessageFil({
    required this.id,
    this.camp = '',
    this.auteur = '',
    this.auteurCle = '',
    this.corps = '',
    this.envoyeLe,
    this.luLe,
    this.pieces = const [],
    this.repondA,
    this.reactions = const {},
    this.apercu,
  });

  final int id;

  /// `student` ou `scolarite`.
  final String camp;
  final String auteur;

  /// Clé de l'auteur dans une discussion de classe (`student:<pk>`) : un
  /// camarade est du même camp que le lecteur, pas lui. Vide au guichet.
  final String auteurCle;
  final String corps;
  final DateTime? envoyeLe;

  /// Lu par l'autre côté du guichet (coches de lecture).
  final DateTime? luLe;
  final List<PieceMessage> pieces;
  final Citation? repondA;
  final Map<String, ResumeReaction> reactions;
  final ApercuLien? apercu;

  /// Le message est-il du lecteur ? Par sa clé d'auteur dans un groupe, par
  /// son camp au guichet (où le lecteur est `student`).
  bool estDe(String lecteur) =>
      auteurCle.isNotEmpty ? auteurCle == lecteur : camp == lecteur;

  /// La réaction du lecteur (`like`, `dislike`), `null` sans avis.
  String? reactionDe(String lecteur) {
    for (final MapEntry(:key, :value) in reactions.entries) {
      if (value.lecteurs.contains(lecteur)) return key;
    }
    return null;
  }

  /// Ce qu'une citation reprend de ce message.
  String get extrait {
    final texte = corps.split(RegExp(r'\s+')).where((m) => m.isNotEmpty).join(' ');
    if (texte.isEmpty) return pieces.isEmpty ? '' : pieces.first.nom;
    return texte.length <= 140 ? texte : '${texte.substring(0, 139)}…';
  }

  MessageFil avecReactions(Map<String, ResumeReaction> nouvelles) => MessageFil(
        id: id,
        camp: camp,
        auteur: auteur,
        auteurCle: auteurCle,
        corps: corps,
        envoyeLe: envoyeLe,
        luLe: luLe,
        pieces: pieces,
        repondA: repondA,
        reactions: nouvelles,
        apercu: apercu,
      );

  factory MessageFil.depuisJson(Json json) => MessageFil(
        id: json.entier('id') ?? 0,
        camp: json.texte('camp'),
        auteur: json.texte('auteur'),
        auteurCle: json.texte('auteur_cle'),
        corps: json.texte('corps'),
        envoyeLe: json.date('envoye_le'),
        luLe: json.date('lu_le'),
        pieces: json.liste('pieces_jointes', PieceMessage.depuisJson),
        repondA: Citation.depuisJson(json.objet('repond_a')),
        reactions: lireReactions(json['reactions']),
        apercu: ApercuLien.depuisJson(json.objet('apercu')),
      );
}

class FilMessages {
  const FilMessages({
    this.conversation,
    this.interlocuteur = '',
    this.sousTitre = '',
    this.enLigne,
    this.messages = const [],
    this.lecteur = campEtudiant,
    this.accuse = true,
    this.lectureSeule = false,
    this.piecesMax = 5,
    this.extensions = const [],
    this.avertissement = '',
  });

  /// `null` tant qu'aucun message n'a été échangé : le fil naît au premier.
  final int? conversation;

  /// Le guichet (« Service de la scolarité ») ou l'intitulé du cours.
  final String interlocuteur;

  /// La cohorte d'une discussion de classe, vide au guichet.
  final String sousTitre;

  /// Quelqu'un est-il en ligne de l'autre côté ? `null` : on ne le sait pas.
  final bool? enLigne;

  /// Ordre chronologique, au plus 50 par lot.
  final List<MessageFil> messages;

  /// Clé du lecteur : ce qui fait reconnaître ses messages et ses réactions.
  final String lecteur;

  /// Coches de lecture : au guichet seulement, un groupe n'a pas de « lu ».
  final bool accuse;

  /// Ancienne classe : le fil se relit, il ne s'écrit plus.
  final bool lectureSeule;
  final int piecesMax;
  final List<String> extensions;
  final String avertissement;

  FilMessages avecMessages(List<MessageFil> autres) => FilMessages(
        conversation: conversation,
        interlocuteur: interlocuteur,
        sousTitre: sousTitre,
        enLigne: enLigne,
        messages: autres,
        lecteur: lecteur,
        accuse: accuse,
        lectureSeule: lectureSeule,
        piecesMax: piecesMax,
        extensions: extensions,
        avertissement: avertissement,
      );

  /// Le même fil, l'interlocuteur venant d'apparaître ou de disparaître
  /// (évènement de présence du websocket).
  FilMessages avecPresence(bool? autre) => FilMessages(
        conversation: conversation,
        interlocuteur: interlocuteur,
        sousTitre: sousTitre,
        enLigne: autre,
        messages: messages,
        lecteur: lecteur,
        accuse: accuse,
        lectureSeule: lectureSeule,
        piecesMax: piecesMax,
        extensions: extensions,
        avertissement: avertissement,
      );

  static int _piecesMax(Json? pieces) => pieces?.entier('maximum') ?? 5;
  static List<String> _extensions(Json? pieces) => [
        for (final e in (pieces?['extensions'] as List? ?? const [])) '$e',
      ];

  /// Le fil du guichet de la scolarité (`messages/`).
  factory FilMessages.depuisJson(Json json) {
    final pieces = json.objet('pieces_jointes');
    return FilMessages(
      conversation: json.objet('conversation')?.entier('id'),
      interlocuteur: json.objet('interlocuteur')?.texte('nom') ?? '',
      enLigne: json.objet('interlocuteur')?.booleen('en_ligne') ?? false,
      messages: json.liste('messages', MessageFil.depuisJson),
      piecesMax: _piecesMax(pieces),
      extensions: _extensions(pieces),
      avertissement: json.texte('avertissement'),
    );
  }

  /// Le fil d'une discussion de classe (`discussions/<cle>/messages/`).
  factory FilMessages.depuisDiscussion(Json json) {
    final pieces = json.objet('pieces_jointes');
    final classe = json.objet('classe');
    final enseignants = classe?.liste('enseignants', (e) => e) ?? const [];
    return FilMessages(
      conversation: classe?.objet('groupe')?.entier('id'),
      interlocuteur: classe?.objet('cours')?.texte('intitule') ?? '',
      sousTitre: classe?.texte('cohorte') ?? '',
      enLigne: enseignants.isEmpty
          ? null
          : enseignants.any((e) => e.booleen('en_ligne')),
      messages: json.liste('messages', MessageFil.depuisJson),
      lecteur: json.texte('lecteur'),
      accuse: false,
      lectureSeule: classe?['ouverte'] == false,
      piecesMax: _piecesMax(pieces),
      extensions: _extensions(pieces),
      avertissement: json.texte('avertissement'),
    );
  }
}
