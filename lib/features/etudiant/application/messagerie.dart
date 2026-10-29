import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../commun/piece_jointe.dart';
import '../data/etudiant_repository.dart';
import '../domain/messagerie.dart';

/// Désigne un fil : le guichet de la scolarité, ou la discussion d'une
/// classe. C'est la clé de la famille [filProvider].
class SourceFil {
  const SourceFil._();

  static const guichet = 'messagerie';
  static String classe(String cle) => 'classe:$cle';
}

/// Les appels du dépôt propres à un fil : les deux chats ont les mêmes
/// gestes, sur des routes différentes.
class _AccesFil {
  _AccesFil(this._depot, String source)
      : _classe = source.startsWith('classe:') ? source.substring(7) : null;

  final EtudiantRepository _depot;
  final String? _classe;

  Future<FilMessages> lire({int? avant}) => _classe == null
      ? _depot.messages(avant: avant)
      : _depot.messagesDiscussion(_classe, avant: avant);

  Future<MessageFil> envoyer(
          {required String corps,
          List<PieceAJoindre> pieces = const [],
          int? repondA}) =>
      _classe == null
          ? _depot.envoyerMessage(corps: corps, pieces: pieces, repondA: repondA)
          : _depot.envoyerDiscussion(_classe,
              corps: corps, pieces: pieces, repondA: repondA);

  Future<Map<String, ResumeReaction>> reagir(int id, String valeur) =>
      _classe == null
          ? _depot.reagirMessage(id, valeur)
          : _depot.reagirDiscussion(id, valeur);

  Future<File> piece(PieceMessage piece) => _classe == null
      ? _depot.pieceMessage(piece)
      : _depot.pieceDiscussion(piece);
}

/// Télécharge une pièce d'un fil, par la route de ce fil.
Future<File> telechargerPieceDuFil(
        EtudiantRepository depot, String source, PieceMessage piece) =>
    _AccesFil(depot, source).piece(piece);

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

/// Un fil (guichet ou classe). Pas de websocket côté mobile : la page relit
/// le fil à intervalle régulier, comme le repli du web quand le socket tombe.
class FilController extends AutoDisposeFamilyAsyncNotifier<EtatFil, String> {
  _AccesFil get _acces =>
      _AccesFil(ref.read(etudiantRepositoryProvider), arg);

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
  /// de la scolarité ; une erreur réseau est ignorée (on réessaiera).
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
