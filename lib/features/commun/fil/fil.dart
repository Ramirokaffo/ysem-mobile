import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/espace.dart';
import '../../../core/models/discussions.dart';
import '../../../core/models/messagerie.dart';
import '../../../core/providers.dart';
import '../../etudiant/data/etudiant_repository.dart';
import '../piece_jointe.dart';

/// Désigne un fil : le guichet de la scolarité, ou la discussion d'une classe
/// vue de l'un des deux espaces. C'est la clé de la famille [filProvider].
class SourceFil {
  const SourceFil._();

  static const guichet = 'messagerie';
  static String classe(String cle) => 'classe:$cle';
  static String classeEnseignant(String cle) => 'enseignant:$cle';

  /// La discussion d'une classe, depuis l'espace qui la lit.
  static String classeDe(Espace espace, String cle) => switch (espace) {
        Espace.etudiant => classe(cle),
        Espace.enseignant => classeEnseignant(cle),
      };

  /// L'espace à qui appartient le fil : c'est sa pastille que la lecture fait
  /// bouger.
  static Espace espaceDe(String source) => source.startsWith('enseignant:')
      ? Espace.enseignant
      : Espace.etudiant;
}

/// Les gestes d'une discussion de classe, les mêmes dans les deux API.
abstract interface class DepotDiscussions {
  Future<Discussions> discussions({String? recherche});

  Future<FilMessages> messagesDiscussion(String cle, {int? avant});

  Future<MessageFil> envoyerDiscussion(
    String cle, {
    required String corps,
    List<PieceAJoindre> pieces = const [],
    int? repondA,
  });

  Future<Map<String, ResumeReaction>> reagirDiscussion(int id, String valeur);

  Future<File> pieceDiscussion(PieceMessage piece);
}

/// Les appels propres à un fil : les chats ont les mêmes gestes, sur des
/// routes différentes.
abstract interface class AccesFil {
  Future<FilMessages> lire({int? avant});

  Future<MessageFil> envoyer({
    required String corps,
    List<PieceAJoindre> pieces = const [],
    int? repondA,
  });

  Future<Map<String, ResumeReaction>> reagir(int id, String valeur);

  Future<File> piece(PieceMessage piece);
}

class _AccesGuichet implements AccesFil {
  _AccesGuichet(this._depot);

  final EtudiantRepository _depot;

  @override
  Future<FilMessages> lire({int? avant}) => _depot.messages(avant: avant);

  @override
  Future<MessageFil> envoyer({
    required String corps,
    List<PieceAJoindre> pieces = const [],
    int? repondA,
  }) =>
      _depot.envoyerMessage(corps: corps, pieces: pieces, repondA: repondA);

  @override
  Future<Map<String, ResumeReaction>> reagir(int id, String valeur) =>
      _depot.reagirMessage(id, valeur);

  @override
  Future<File> piece(PieceMessage piece) => _depot.pieceMessage(piece);
}

class _AccesClasse implements AccesFil {
  _AccesClasse(this._depot, this._cle);

  final DepotDiscussions _depot;
  final String _cle;

  @override
  Future<FilMessages> lire({int? avant}) =>
      _depot.messagesDiscussion(_cle, avant: avant);

  @override
  Future<MessageFil> envoyer({
    required String corps,
    List<PieceAJoindre> pieces = const [],
    int? repondA,
  }) =>
      _depot.envoyerDiscussion(_cle,
          corps: corps, pieces: pieces, repondA: repondA);

  @override
  Future<Map<String, ResumeReaction>> reagir(int id, String valeur) =>
      _depot.reagirDiscussion(id, valeur);

  @override
  Future<File> piece(PieceMessage piece) => _depot.pieceDiscussion(piece);
}

/// Le dépôt des discussions de chaque espace.
final depotDiscussionsProvider = Provider.family<DepotDiscussions, Espace>(
  (ref, espace) => switch (espace) {
    Espace.etudiant => ref.watch(etudiantRepositoryProvider),
    Espace.enseignant => ref.watch(enseignantRepositoryProvider),
  },
);

/// Les appels d'un fil, d'après sa source.
final accesFilProvider = Provider.family<AccesFil, String>((ref, source) {
  if (source == SourceFil.guichet) {
    return _AccesGuichet(ref.watch(etudiantRepositoryProvider));
  }
  return _AccesClasse(
    ref.watch(depotDiscussionsProvider(SourceFil.espaceDe(source))),
    source.substring(source.indexOf(':') + 1),
  );
});

/// Taille d'un lot du serveur : un lot plein laisse supposer des messages
/// plus anciens.
const tailleLotMessages = 50;

class EtatFil {
  const EtatFil({
    required this.fil,
    required this.messages,
    this.plusAnciens = false,
    this.chargementAnciens = false,
  });

  /// Ce que le serveur dit du fil (interlocuteur, présence, pièces).
  final FilMessages fil;

  /// Tous les messages chargés, dans l'ordre chronologique.
  final List<MessageFil> messages;
  final bool plusAnciens;
  final bool chargementAnciens;

  EtatFil copie({
    FilMessages? fil,
    List<MessageFil>? messages,
    bool? plusAnciens,
    bool? chargementAnciens,
  }) =>
      EtatFil(
        fil: fil ?? this.fil,
        messages: messages ?? this.messages,
        plusAnciens: plusAnciens ?? this.plusAnciens,
        chargementAnciens: chargementAnciens ?? this.chargementAnciens,
      );
}

/// Fusionne deux lots par identifiant : un message relu remplace l'ancien
/// (accusé de lecture, réactions), un nouveau s'ajoute. Les identifiants
/// suivent l'ordre d'envoi.
List<MessageFil> fusionnerMessages(
    List<MessageFil> actuels, List<MessageFil> recus) {
  final parId = {for (final m in actuels) m.id: m};
  for (final m in recus) {
    parId[m.id] = m;
  }
  return parId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
}

/// Un fil (guichet ou classe). Le websocket du fil, tenu par la page, ne fait
/// que **signaler** : un message, une réaction ou un accusé de lecture
/// annoncés font relire le dernier lot par l'API, qui reste la seule source
/// des messages — pas de second rendu d'un payload à tenir en phase avec le
/// premier. Socket tombé, la page relit à intervalle régulier.
class FilController extends AutoDisposeFamilyAsyncNotifier<EtatFil, String> {
  AccesFil get _acces => ref.read(accesFilProvider(arg));

  @override
  Future<EtatFil> build(String source) async {
    final fil = await _acces.lire();
    return EtatFil(
      fil: fil,
      messages: fil.messages,
      plusAnciens: fil.messages.length >= tailleLotMessages,
    );
  }

  /// Relit les derniers messages. Rend le nombre de messages nouveaux venus
  /// des autres ; une erreur réseau est ignorée (on réessaiera).
  Future<int> actualiser() async {
    final actuel = state.valueOrNull;
    if (actuel == null) return 0;
    try {
      final fil = await _acces.lire();
      final connus = {for (final m in actuel.messages) m.id};
      final nouveaux = fil.messages
          .where((m) => !connus.contains(m.id) && !m.estDe(fil.lecteur))
          .length;
      final courant = state.valueOrNull ?? actuel;
      state = AsyncData(courant.copie(
        fil: fil,
        messages: fusionnerMessages(courant.messages, fil.messages),
      ));
      return nouveaux;
    } catch (_) {
      return 0;
    }
  }

  Future<void> chargerAnciens() async {
    final actuel = state.valueOrNull;
    if (actuel == null ||
        !actuel.plusAnciens ||
        actuel.chargementAnciens ||
        actuel.messages.isEmpty) {
      return;
    }
    state = AsyncData(actuel.copie(chargementAnciens: true));
    try {
      final lot = await _acces.lire(avant: actuel.messages.first.id);
      final courant = state.valueOrNull ?? actuel;
      state = AsyncData(courant.copie(
        messages: fusionnerMessages(courant.messages, lot.messages),
        plusAnciens: lot.messages.length >= tailleLotMessages,
        chargementAnciens: false,
      ));
    } catch (_) {
      final courant = state.valueOrNull ?? actuel;
      state = AsyncData(courant.copie(chargementAnciens: false));
      rethrow;
    }
  }

  /// Envoie, puis ajoute le message rendu par le serveur. Les erreurs
  /// (`ApiException`) remontent au composeur, qui garde la saisie.
  Future<void> envoyer({
    required String corps,
    List<PieceAJoindre> pieces = const [],
    int? repondA,
  }) async {
    final message =
        await _acces.envoyer(corps: corps, pieces: pieces, repondA: repondA);
    final courant = state.valueOrNull;
    if (courant == null) return;
    state = AsyncData(courant.copie(
      messages: fusionnerMessages(courant.messages, [message]),
    ));
    // Le fil vient de naître avec ce premier message : on relit pour en
    // apprendre l'identifiant, c'est lui qui ouvre le websocket.
    if (courant.fil.conversation == null) await actualiser();
  }

  /// L'interlocuteur vient d'apparaître ou de disparaître (websocket).
  void reporterPresence(bool enLigne) {
    final courant = state.valueOrNull;
    if (courant == null || courant.fil.enLigne == enLigne) return;
    state = AsyncData(courant.copie(fil: courant.fil.avecPresence(enLigne)));
  }

  /// Pose, remplace ou retire mon avis (le serveur tranche, d'un même geste).
  Future<void> reagir(MessageFil message, String valeur) async {
    final reactions = await _acces.reagir(message.id, valeur);
    final courant = state.valueOrNull;
    if (courant == null) return;
    state = AsyncData(courant.copie(messages: [
      for (final m in courant.messages)
        m.id == message.id ? m.avecReactions(reactions) : m,
    ]));
  }
}

/// Un fil par source ([SourceFil.guichet], [SourceFil.classe]).
final filProvider = AsyncNotifierProvider.autoDispose
    .family<FilController, EtatFil, String>(FilController.new);
