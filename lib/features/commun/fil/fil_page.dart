import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/charte/charte.dart';
import '../../../core/format/formats.dart';
import '../../../core/models/messagerie.dart';
import '../../../core/network/api_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../espace/menu.dart';
import '../langue.dart';
import '../piece_jointe.dart';
import '../telechargement.dart';
import 'fil.dart';

/// Délai de relecture du fil tant que l'écran est ouvert : l'application
/// n'ouvre pas de websocket, elle interroge comme le repli du web.
const _intervalleRelecture = Duration(seconds: 15);

/// Un fil de messages : le guichet de la scolarité, ou la discussion d'une
/// classe ([SourceFil]). Même rendu, mêmes gestes ; seuls changent ce qui
/// désigne le lecteur, les coches de lecture et la lecture seule.
class FilPage extends ConsumerStatefulWidget {
  const FilPage({super.key, required this.source, this.titre});

  final String source;
  final String? titre;

  @override
  ConsumerState<FilPage> createState() => _FilPageState();
}

class _FilPageState extends ConsumerState<FilPage> {
  bool get _estClasse => widget.source != SourceFil.guichet;

  Timer? _minuterie;
  AppLifecycleListener? _cycle;
  MessageFil? _repondA;

  @override
  void initState() {
    super.initState();
    _minuterie = Timer.periodic(_intervalleRelecture, (_) => _relire());
    _cycle = AppLifecycleListener(onResume: _relire);
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    _cycle?.dispose();
    super.dispose();
  }

  Future<void> _relire() async {
    if (!mounted) return;
    final nouveaux = await ref.read(filProvider(widget.source).notifier).actualiser();
    // Lire le fil accuse réception : la pastille du menu doit le suivre.
    if (nouveaux > 0 && mounted) ref.invalidate(menuProvider(SourceFil.espaceDe(widget.source)));
  }

  Future<void> _actions(MessageFil message, String lecteur) async {
    final t = AppLocalizations.of(context);
    final mienne = message.reactionDe(lecteur);
    final choix = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: Text(t.repondre),
              onTap: () => Navigator.pop(context, 'repondre'),
            ),
            ListTile(
              leading: Icon(mienne == reactionJaime
                  ? Icons.thumb_up_alt_rounded
                  : Icons.thumb_up_alt_outlined),
              title: Text(mienne == reactionJaime ? t.retirerJaime : t.jaime),
              onTap: () => Navigator.pop(context, reactionJaime),
            ),
            ListTile(
              leading: Icon(mienne == reactionJaimePas
                  ? Icons.thumb_down_alt_rounded
                  : Icons.thumb_down_alt_outlined),
              title: Text(mienne == reactionJaimePas
                  ? t.retirerJaimePas
                  : t.jaimePas),
              onTap: () => Navigator.pop(context, reactionJaimePas),
            ),
            if (message.corps.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: Text(t.copier),
                onTap: () => Navigator.pop(context, 'copier'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || choix == null) return;
    switch (choix) {
      case 'repondre':
        setState(() => _repondA = message);
      case 'copier':
        await Clipboard.setData(ClipboardData(text: message.corps));
      default:
        await _reagir(message, choix);
    }
  }

  Future<void> _reagir(MessageFil message, String valeur) async {
    final messager = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(filProvider(widget.source).notifier)
          .reagir(message, valeur);
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final valeur = ref.watch(filProvider(widget.source));
    final etat = valeur.valueOrNull;
    final fil = etat?.fil;

    // Le fil vient d'être lu : la pastille du menu se met à jour.
    ref.listen(filProvider(widget.source), (avant, apres) {
      if (avant?.hasValue != true && apres.hasValue) {
        ref.invalidate(menuProvider(SourceFil.espaceDe(widget.source)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _Entete(
          titre: fil?.interlocuteur.isNotEmpty == true
              ? fil!.interlocuteur
              : widget.titre ?? t.sectionMessages,
          sousTitre: fil?.sousTitre ?? '',
          classe: _estClasse,
          enLigne: fil?.enLigne,
        ),
      ),
      body: VueAsynchrone<EtatFil>(
        valeur: valeur,
        surRafraichir: () => ref.refresh(filProvider(widget.source).future),
        constructeur: (etat) => Column(
          children: [
            Expanded(
              child: _Fil(
                source: widget.source,
                etat: etat,
                messageVide: _estClasse ? t.discussionVide : t.filVide,
                surActions: (m) => _actions(m, etat.fil.lecteur),
                surReaction: _reagir,
              ),
            ),
            if (etat.fil.lectureSeule)
              _BandeauLectureSeule(texte: t.discussionLectureSeule)
            else
              _Composeur(
                source: widget.source,
                fil: etat.fil,
                repondA: _repondA,
                surAnnulerReponse: () => setState(() => _repondA = null),
                surEnvoye: () => setState(() => _repondA = null),
              ),
          ],
        ),
      ),
    );
  }
}

class _Entete extends StatelessWidget {
  const _Entete({
    required this.titre,
    this.sousTitre = '',
    this.classe = false,
    this.enLigne,
  });

  final String titre;
  final String sousTitre;
  final bool classe;
  final bool? enLigne;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final jetons = YsemTokens.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(classe ? Icons.groups_rounded : Icons.support_agent_rounded,
              size: 20, color: theme.colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(titre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium),
              if (enLigne != null || sousTitre.isNotEmpty)
                Row(
                  children: [
                    if (enLigne != null) ...[
                      Icon(Icons.circle,
                          size: 8,
                          color: enLigne! ? jetons.succes : jetons.neutre),
                      const SizedBox(width: 5),
                    ],
                    Flexible(
                      child: Text(
                        [
                          if (sousTitre.isNotEmpty) sousTitre,
                          if (enLigne != null)
                            classe
                                ? (enLigne!
                                    ? t.enseignantEnLigne
                                    : t.enseignantHorsLigne)
                                : (enLigne!
                                    ? t.serviceEnLigne
                                    : t.serviceHorsLigne),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Le fil, du plus récent (en bas) au plus ancien, séparé par journée.
class _Fil extends ConsumerWidget {
  const _Fil({
    required this.source,
    required this.etat,
    required this.messageVide,
    required this.surActions,
    required this.surReaction,
  });

  final String source;
  final EtatFil etat;
  final String messageVide;
  final ValueChanged<MessageFil> surActions;
  final void Function(MessageFil, String) surReaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final langue = langueCourante(context);

    if (etat.messages.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          EtatVide(
            message: messageVide,
            icone: Icons.forum_outlined,
          ),
        ],
      );
    }

    // Éléments dans l'ordre chronologique : séparateurs de jour et messages.
    final elements = <Object>[];
    DateTime? jourPrecedent;
    for (final message in etat.messages) {
      final local = message.envoyeLe?.toLocal();
      final jour = local == null ? null : DateUtils.dateOnly(local);
      if (jour != null && jour != jourPrecedent) {
        elements.add(jour);
        jourPrecedent = jour;
      }
      elements.add(message);
    }
    final avecAnciens = etat.plusAnciens ? 1 : 0;

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      itemCount: elements.length + avecAnciens,
      itemBuilder: (context, i) {
        if (i == elements.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: etat.chargementAnciens
                  ? const CircularProgressIndicator()
                  : TextButton.icon(
                      onPressed: () async {
                        final messager = ScaffoldMessenger.of(context);
                        try {
                          await ref
                              .read(filProvider(source).notifier)
                              .chargerAnciens();
                        } on ApiException catch (e) {
                          messager.showSnackBar(
                              SnackBar(content: Text(e.message)));
                        }
                      },
                      icon: const Icon(Icons.history_rounded),
                      label: Text(t.messagesPlusAnciens),
                    ),
            ),
          );
        }
        final element = elements[elements.length - 1 - i];
        if (element is DateTime) {
          return _SeparateurJour(texte: Formats.jourLong(element, langue));
        }
        final message = element as MessageFil;
        return _Bulle(
          source: source,
          lecteur: etat.fil.lecteur,
          accuse: etat.fil.accuse,
          message: message,
          surActions: () => surActions(message),
          surReaction: (valeur) => surReaction(message, valeur),
        );
      },
    );
  }
}

class _SeparateurJour extends StatelessWidget {
  const _SeparateurJour({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(texte,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      ),
    );
  }
}

class _Bulle extends ConsumerWidget {
  const _Bulle({
    required this.source,
    required this.lecteur,
    required this.accuse,
    required this.message,
    required this.surActions,
    required this.surReaction,
  });

  final String source;
  final String lecteur;
  final bool accuse;
  final MessageFil message;
  final VoidCallback surActions;
  final ValueChanged<String> surReaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final moi = message.estDe(lecteur);
    final maReaction = message.reactionDe(lecteur);
    final fond = moi
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final encre = moi
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    final discret = encre.withValues(alpha: 0.7);
    final heure = message.envoyeLe == null
        ? ''
        : DateFormat.Hm(langue).format(message.envoyeLe!.toLocal());

    final bulle = GestureDetector(
      onLongPress: surActions,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: fond,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(moi ? 18 : 4),
            bottomRight: Radius.circular(moi ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!moi && message.auteur.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(message.auteur,
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800)),
              ),
            if (message.repondA != null)
              _CitationBulle(citation: message.repondA!, encre: encre),
            if (message.corps.isNotEmpty)
              Text(message.corps,
                  style: theme.textTheme.bodyMedium?.copyWith(color: encre)),
            if (message.apercu != null)
              _ApercuBulle(apercu: message.apercu!, encre: encre),
            for (final piece in message.pieces)
              _PieceBulle(source: source, piece: piece, encre: encre),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(heure,
                    style: theme.textTheme.labelSmall?.copyWith(color: discret)),
                if (moi && accuse) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: message.luLe == null ? t.envoye : t.luParLeService,
                    child: Icon(
                      message.luLe == null
                          ? Icons.done_rounded
                          : Icons.done_all_rounded,
                      size: 15,
                      color: message.luLe == null
                          ? discret
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    final reactions = [
      for (final valeur in const [reactionJaime, reactionJaimePas])
        if ((message.reactions[valeur]?.nombre ?? 0) > 0)
          _PuceReaction(
            valeur: valeur,
            nombre: message.reactions[valeur]!.nombre,
            mienne: maReaction == valeur,
            surTape: () => surReaction(valeur),
          ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment:
            moi ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          bulle,
          if (reactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Wrap(spacing: 4, children: reactions),
            ),
        ],
      ),
    );
  }
}

class _CitationBulle extends StatelessWidget {
  const _CitationBulle({required this.citation, required this.encre});

  final Citation citation;
  final Color encre;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: encre.withValues(alpha: 0.06),
        border: Border(
            left: BorderSide(color: theme.colorScheme.primary, width: 3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(citation.auteur,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800)),
          Text(citation.extrait,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: encre.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

class _ApercuBulle extends StatelessWidget {
  const _ApercuBulle({required this.apercu, required this.encre});

  final ApercuLien apercu;
  final Color encre;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: encre.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.link_rounded, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (apercu.site.isNotEmpty)
                  Text(apercu.site,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: encre.withValues(alpha: 0.7))),
                if (apercu.titre.isNotEmpty)
                  Text(apercu.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: encre, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PieceBulle extends ConsumerWidget {
  const _PieceBulle(
      {required this.source, required this.piece, required this.encre});

  final String source;
  final PieceMessage piece;
  final Color encre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: encre.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => telechargerEtOuvrir(
            context,
            () => ref.read(accesFilProvider(source)).piece(piece),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconeDeFichier(piece.nom),
                    size: 22, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(piece.nom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: encre, fontWeight: FontWeight.w700)),
                      if (piece.tailleLisible.isNotEmpty)
                        Text(piece.tailleLisible,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: encre.withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.download_rounded,
                    size: 18, color: encre.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PuceReaction extends StatelessWidget {
  const _PuceReaction({
    required this.valeur,
    required this.nombre,
    required this.mienne,
    required this.surTape,
  });

  final String valeur;
  final int nombre;
  final bool mienne;
  final VoidCallback surTape;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final couleur =
        mienne ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      label: valeur == reactionJaime ? t.jaime : t.jaimePas,
      child: InkWell(
        onTap: surTape,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: mienne
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
                color: mienne
                    ? theme.colorScheme.primary.withValues(alpha: 0.4)
                    : Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                valeur == reactionJaime
                    ? Icons.thumb_up_alt_rounded
                    : Icons.thumb_down_alt_rounded,
                size: 14,
                color: couleur,
              ),
              const SizedBox(width: 4),
              Text('$nombre',
                  style: theme.textTheme.labelSmall?.copyWith(color: couleur)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Saisie d'un message : citation éventuelle, pièces, texte. La saisie est
/// gardée tant que l'envoi n'a pas abouti.
class _Composeur extends ConsumerStatefulWidget {
  const _Composeur({
    required this.source,
    required this.fil,
    required this.repondA,
    required this.surAnnulerReponse,
    required this.surEnvoye,
  });

  final String source;
  final FilMessages fil;
  final MessageFil? repondA;
  final VoidCallback surAnnulerReponse;
  final VoidCallback surEnvoye;

  @override
  ConsumerState<_Composeur> createState() => _ComposeurState();
}

class _ComposeurState extends ConsumerState<_Composeur> {
  final _texte = TextEditingController();
  final _pieces = <PieceAJoindre>[];
  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _texte.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  bool get _envoyable =>
      !_envoi && (_texte.text.trim().isNotEmpty || _pieces.isNotEmpty);

  Future<void> _joindre() async {
    final ajoutees = await choisirPieces(
      context,
      extensions: widget.fil.extensions.isEmpty
          ? extensionsPieces
          : widget.fil.extensions,
      restant: widget.fil.piecesMax - _pieces.length,
    );
    if (ajoutees.isNotEmpty) setState(() => _pieces.addAll(ajoutees));
  }

  Future<void> _envoyer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref.read(filProvider(widget.source).notifier).envoyer(
            corps: _texte.text.trim(),
            pieces: List.of(_pieces),
            repondA: widget.repondA?.id,
          );
      _texte.clear();
      setState(() {
        _pieces.clear();
        _envoi = false;
      });
      widget.surEnvoye();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _envoi = false;
          _erreur = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final repondA = widget.repondA;
    final pleines = _pieces.length >= widget.fil.piecesMax;

    return Material(
      color: theme.colorScheme.surface,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (repondA != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                  padding: const EdgeInsets.fromLTRB(10, 4, 0, 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    border: Border(
                        left: BorderSide(
                            color: theme.colorScheme.primary, width: 3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.reponseA(repondA.auteur),
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w800)),
                            Text(repondA.extrait,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: t.annuler,
                        visualDensity: VisualDensity.compact,
                        onPressed: _envoi ? null : widget.surAnnulerReponse,
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              if (_pieces.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final piece in _pieces)
                        PucePiece(
                          piece: piece,
                          surRetrait: _envoi
                              ? null
                              : () => setState(() => _pieces.remove(piece)),
                        ),
                    ],
                  ),
                ),
              if (_erreur != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                  child: Text(_erreur!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error)),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: t.joindreFichier,
                    onPressed: _envoi || pleines ? null : _joindre,
                    icon: const Icon(Icons.attach_file_rounded),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _texte,
                      enabled: !_envoi,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: t.ecrireMessage,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    tooltip: t.envoyer,
                    onPressed: _envoyable ? _envoyer : null,
                    icon: _envoi
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
              if (widget.fil.avertissement.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      Icon(Icons.lock_open_rounded,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(widget.fil.avertissement,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BandeauLectureSeule extends StatelessWidget {
  const _BandeauLectureSeule({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(texte,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
