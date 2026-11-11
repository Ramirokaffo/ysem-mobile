import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/models/devoirs.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/formulaire.dart';
import '../../../commun/langue.dart';
import '../../../commun/piece_jointe.dart';
import '../../../commun/telechargement.dart';
import '../../application/sections.dart';
import 'devoirs_page.dart';

/// Un devoir : consignes, mon groupe, mon rendu (ou celui du groupe) et la
/// correction une fois publiée. Le rendu se fait ici, tant qu'il est
/// modifiable — même règle que le portail web, tenue par le serveur.
class DevoirPage extends ConsumerWidget {
  const DevoirPage({super.key, required this.id, this.titre});

  final int id;
  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final valeur = ref.watch(devoirProvider(id));
    final entree = valeur.valueOrNull;
    final peutRendre = entree != null &&
        entree.modifiable &&
        !(entree.devoir.estDeGroupe && entree.groupe == null);

    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionDevoirs)),
      floatingActionButton: !peutRendre
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final message = await Navigator.of(context).push<String>(
                  MaterialPageRoute(builder: (_) => _RenduPage(entree: entree)),
                );
                if (message == null || !context.mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(message)));
                ref.invalidate(devoirProvider(id));
              },
              icon: const Icon(Icons.upload_rounded),
              label: Text(entree.rendu?.estRendu == true ? t.devoirMettreAJour : t.devoirRendre),
            ),
      body: VueAsynchrone<EntreeDevoir>(
        valeur: valeur,
        surRafraichir: () => ref.refresh(devoirProvider(id).future),
        constructeur: (entree) => _Contenu(entree: entree),
      ),
    );
  }
}

class _Contenu extends ConsumerWidget {
  const _Contenu({required this.entree});

  final EntreeDevoir entree;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final devoir = entree.devoir;
    final rendu = entree.rendu;
    final correction = entree.correction;
    final depot = ref.read(etudiantRepositoryProvider);
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        CarteYsem(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(child: Text(devoir.titre, style: theme.textTheme.titleMedium)),
                Pastille(entree.etatLibelle, ton: tonDeLEtat(entree.etat)),
              ]),
              const SizedBox(height: 4),
              Text('${devoir.coursIntitule} · ${devoir.enseignant}', style: secondaire),
              if (devoir.dateLimite != null)
                Text(
                  t.devoirARendreAvant(Formats.horodatage(devoir.dateLimite, langue)),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: devoir.echeancePassee ? theme.colorScheme.error : null,
                  ),
                ),
              Text(
                '${devoir.estDeGroupe ? t.devoirModeGroupe : t.devoirModeIndividuel} · '
                '${devoir.noteSur == null ? t.devoirNonNote : t.devoirNoteSur(Formats.note(devoir.noteSur, langue))}',
                style: secondaire,
              ),
            ],
          ),
        ),
        if (entree.groupe != null) ...[
          const SizedBox(height: 12),
          CarteYsem(
            titre: '${t.devoirMonGroupe} : ${entree.groupe!.nom}',
            icone: Icons.groups_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(entree.groupe!.membres.map((m) => m.nomComplet).join(', ')),
                if (entree.sujet.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(t.devoirSujetGroupe, style: theme.textTheme.labelLarge),
                  Text(entree.sujet),
                ],
              ],
            ),
          ),
        ],
        if (devoir.consignes.isNotEmpty || devoir.pieces.isNotEmpty) ...[
          const SizedBox(height: 12),
          CarteYsem(
            titre: t.devoirConsignes,
            icone: Icons.assignment_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (devoir.consignes.isNotEmpty) Text(devoir.consignes),
                for (final piece in devoir.pieces)
                  _LignePiece(
                    piece: piece,
                    surOuvrir: () => telechargerEtOuvrir(context, () => depot.pieceDevoir(piece)),
                  ),
              ],
            ),
          ),
        ],
        if (entree.correctionVisible && correction != null) ...[
          const SizedBox(height: 12),
          CarteYsem(
            titre: t.devoirCorrection,
            icone: Icons.grading_outlined,
            action: Pastille(correction.statutCorrectionLibelle, ton: TonPastille.marque),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (correction.note != null && devoir.noteSur != null)
                  Text(
                    '${Formats.note(correction.note, langue)} / ${Formats.note(devoir.noteSur, langue)}',
                    style: theme.textTheme.headlineSmall,
                  ),
                if (correction.commentaire.isNotEmpty) Text(correction.commentaire),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        CarteYsem(
          titre: entree.groupe != null ? t.devoirRenduGroupe : t.devoirMonRendu,
          icone: Icons.inbox_outlined,
          action: rendu?.enRetard == true
              ? Pastille(t.devoirEnRetard, ton: TonPastille.danger)
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (rendu == null || !rendu.estRendu)
                Text(t.devoirRienRendu, style: secondaire)
              else ...[
                Text(
                  [
                    t.devoirRenduLe(Formats.horodatage(rendu.renduLe, langue)),
                    if (entree.groupe != null && rendu.deposePar.isNotEmpty)
                      t.devoirParAuteur(rendu.deposePar),
                  ].join(' · '),
                  style: secondaire,
                ),
                if (rendu.texte.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(rendu.texte),
                ],
                for (final piece in rendu.pieces)
                  _LignePiece(
                    piece: piece,
                    surOuvrir: () => telechargerEtOuvrir(context, () => depot.pieceRendu(piece)),
                    surRetirer: entree.modifiable
                        ? () => _retirer(context, ref, piece)
                        : null,
                  ),
              ],
              if (!entree.modifiable) ...[
                const SizedBox(height: 8),
                if (devoir.estDeGroupe && entree.groupe == null)
                  Text(t.devoirSansGroupe, style: secondaire)
                else if (!devoir.estOuvert && !entree.correctionVisible)
                  Text(t.devoirFerme, style: secondaire)
                else if (rendu != null &&
                    rendu.estRendu &&
                    !entree.correctionVisible &&
                    devoir.estOuvert)
                  Text(t.devoirCorrigeNonPublie, style: secondaire),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _retirer(BuildContext context, WidgetRef ref, PieceDevoir piece) async {
    final messager = ScaffoldMessenger.of(context);
    try {
      await ref.read(etudiantRepositoryProvider).retirerPieceRendu(entree.devoir.id, piece.id);
      ref.invalidate(devoirProvider(entree.devoir.id));
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _LignePiece extends StatelessWidget {
  const _LignePiece({required this.piece, required this.surOuvrir, this.surRetirer});

  final PieceDevoir piece;
  final VoidCallback surOuvrir;
  final VoidCallback? surRetirer;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(iconeDeFichier(piece.nom)),
      title: Text(piece.nom, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: piece.tailleLisible.isEmpty ? null : Text(piece.tailleLisible),
      onTap: surOuvrir,
      trailing: surRetirer == null
          ? null
          : IconButton(
              tooltip: t.retirer,
              icon: const Icon(Icons.close_rounded),
              onPressed: surRetirer,
            ),
    );
  }
}

/// Le formulaire de rendu : un texte et des pièces. Le texte remplace celui
/// déjà rendu, les pièces s'ajoutent.
class _RenduPage extends ConsumerStatefulWidget {
  const _RenduPage({required this.entree});

  final EntreeDevoir entree;

  @override
  ConsumerState<_RenduPage> createState() => _RenduPageState();
}

class _RenduPageState extends ConsumerState<_RenduPage> {
  static const _champs = {'texte'};

  final _cle = GlobalKey<FormState>();
  late final _texte = TextEditingController(text: widget.entree.rendu?.texte ?? '');
  List<PieceAJoindre> _pieces = const [];
  bool _envoi = false;
  ApiException? _erreur;

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  int get _dejaJointes => widget.entree.rendu?.pieces.length ?? 0;

  Future<void> _envoyer() async {
    final t = AppLocalizations.of(context);
    setState(() => _erreur = null);
    if (!_cle.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      await ref.read(etudiantRepositoryProvider).rendreDevoir(
            widget.entree.devoir.id,
            texte: _texte.text.trim(),
            pieces: _pieces,
            champ: widget.entree.limites.champ,
          );
      if (mounted) Navigator.of(context).pop(t.devoirRenduEnregistre);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e;
        _envoi = false;
      });
      _cle.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final limites = widget.entree.limites;
    final restant = (limites.maximum - _dejaJointes).clamp(0, limites.maximum);
    final erreur = _erreur;

    return Scaffold(
      appBar: AppBar(title: Text(widget.entree.devoir.titre)),
      body: Form(
        key: _cle,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            EmplacementErreurs(
              messages: erreur == null ? null : erreursGlobales(erreur, _champs),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _texte,
              enabled: !_envoi,
              minLines: 5,
              maxLines: 14,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.devoirVotreReponse,
                hintText: t.devoirReponseAide,
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  _erreur?.erreurDuChamp('texte') ??
                  (((v ?? '').trim().isEmpty && _pieces.isEmpty && _dejaJointes == 0)
                      ? t.devoirReponseRequise
                      : null),
            ),
            const SizedBox(height: 16),
            ChampPiecesJointes(
              libelle: t.devoirFichiers,
              pieces: _pieces,
              maximum: restant,
              actif: !_envoi && restant > 0,
              extensions: limites.extensions.isEmpty ? extensionsPieces : limites.extensions,
              aide: t.piecesAuPlus(limites.maximum),
              surChangement: (pieces) => setState(() => _pieces = pieces),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _envoi ? null : _envoyer,
              icon: _envoi
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(widget.entree.rendu?.estRendu == true ? t.devoirMettreAJour : t.devoirRendre),
            ),
          ],
        ),
      ),
    );
  }
}
