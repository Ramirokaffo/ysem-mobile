import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/models/devoirs.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../../commun/piece_jointe.dart';
import '../../../commun/telechargement.dart';
import '../../application/lectures.dart';
import 'devoirs_enseignant_page.dart';
import 'formulaire_devoir_page.dart';

/// La fiche d'un devoir : état des rendus, correction ligne par ligne, et les
/// gestes — publier, fermer, publier les corrections, verser au contrôle
/// continu. La classe ne voit rien de la correction avant sa publication.
class DevoirEnseignantPage extends ConsumerWidget {
  const DevoirEnseignantPage({super.key, required this.id, this.titre});

  final int id;
  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final valeur = ref.watch(devoirEnseignantProvider(id));
    final etat = valeur.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(titre ?? etat?.devoir.titre ?? t.sectionDevoirs),
        actions: [
          if (etat != null && !etat.devoir.correctionsPubliees)
            IconButton(
              tooltip: t.modifier,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final devoir = etat.devoir;
                await Navigator.of(context).push<int>(MaterialPageRoute(
                  builder: (_) => FormulaireDevoirPage(
                    classe: ClasseDevoir(
                      cle: devoir.cleClasse,
                      coursIntitule: devoir.coursIntitule,
                      cohorte: devoir.cohorte,
                    ),
                    devoir: etat,
                    fige: etat.fige,
                  ),
                ));
                ref.invalidate(devoirEnseignantProvider(id));
              },
            ),
          if (etat != null && etat.rendus == 0)
            IconButton(
              tooltip: t.supprimer,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                final ok = await _confirmer(context, t.devoirSupprimerConfirmer);
                if (!ok || !context.mounted) return;
                try {
                  await ref.read(enseignantRepositoryProvider).supprimerDevoir(id);
                  if (context.mounted) Navigator.of(context).pop();
                } on ApiException catch (e) {
                  if (context.mounted) _message(context, e.message);
                }
              },
            ),
        ],
      ),
      body: VueAsynchrone<DevoirComplet>(
        valeur: valeur,
        surRafraichir: () => ref.refresh(devoirEnseignantProvider(id).future),
        constructeur: (etat) => _Contenu(etat: etat),
      ),
    );
  }
}

Future<bool> _confirmer(BuildContext context, String texte) async {
  final t = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (contexte) => AlertDialog(
          content: Text(texte),
          actions: [
            TextButton(onPressed: () => Navigator.of(contexte).pop(false), child: Text(t.annuler)),
            FilledButton(onPressed: () => Navigator.of(contexte).pop(true), child: Text(t.confirmer)),
          ],
        ),
      ) ??
      false;
}

void _message(BuildContext context, String texte) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));

class _Contenu extends ConsumerWidget {
  const _Contenu({required this.etat});

  final DevoirComplet etat;

  Future<void> _geste(BuildContext context, WidgetRef ref, String geste,
      {Map<String, dynamic>? donnees, String? confirmation}) async {
    if (confirmation != null && !await _confirmer(context, confirmation)) return;
    try {
      final reponse = await ref
          .read(enseignantRepositoryProvider)
          .gesteDevoir(etat.devoir.id, geste, donnees: donnees);
      if (geste == 'verser' && context.mounted) {
        _message(context,
            AppLocalizations.of(context).devoirNotesVersees('${reponse['reportes'] ?? 0}'));
      }
    } on ApiException catch (e) {
      if (context.mounted) _message(context, e.message);
    }
    ref.invalidate(devoirEnseignantProvider(etat.devoir.id));
    ref.invalidate(devoirsEnseignantProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final devoir = etat.devoir;
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        CarteYsem(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(child: Text(devoir.titre, style: theme.textTheme.titleMedium)),
                Pastille(devoir.statutLibelle, ton: tonDuStatutDevoir(devoir.statut)),
              ]),
              Text('${devoir.coursIntitule} · ${devoir.cohorte}', style: secondaire),
              if (devoir.dateLimite != null)
                Text(t.devoirARendreAvant(Formats.horodatage(devoir.dateLimite, langue)),
                    style: theme.textTheme.bodyMedium),
              Text(
                '${devoir.estDeGroupe ? '${t.devoirModeGroupe} (${devoir.groupementNom})' : t.devoirModeIndividuel} · '
                '${devoir.noteSur == null ? t.devoirNonNote : t.devoirNoteSur(Formats.note(devoir.noteSur, langue))}',
                style: secondaire,
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, children: [
                Pastille(t.devoirRendusSur('${etat.rendus}', '${etat.attendus}'), icone: Icons.inbox_outlined),
                if (etat.enRetard > 0) Pastille('${t.devoirEnRetard} : ${etat.enRetard}', ton: TonPastille.danger),
                if (etat.aCorriger > 0) Pastille(t.devoirACorriger('${etat.aCorriger}'), ton: TonPastille.alerte),
              ]),
              if (devoir.consignes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(devoir.consignes),
              ],
              for (final piece in devoir.pieces)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(iconeDeFichier(piece.nom)),
                  title: Text(piece.nom, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => telechargerEtOuvrir(
                      context, () => ref.read(enseignantRepositoryProvider).pieceDevoir(piece)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (devoir.estBrouillon) ...[
          Encadre(texte: t.devoirBrouillonInfo, icone: Icons.visibility_off_outlined),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _geste(context, ref, 'publier'),
            icon: const Icon(Icons.send_rounded),
            label: Text(t.devoirPublier),
          ),
        ] else if (devoir.estOuvert)
          OutlinedButton.icon(
            onPressed: () => _geste(context, ref, 'fermer', confirmation: t.devoirFermerConfirmer),
            icon: const Icon(Icons.lock_outline_rounded),
            label: Text(t.devoirFermer),
          )
        else if (!devoir.correctionsPubliees)
          OutlinedButton.icon(
            onPressed: () => _geste(context, ref, 'rouvrir'),
            icon: const Icon(Icons.lock_open_rounded),
            label: Text(t.devoirRouvrir),
          ),
        if (etat.sansGroupe.isNotEmpty) ...[
          const SizedBox(height: 12),
          Encadre(
            titre: t.devoirInscritsSansGroupe,
            texte: etat.sansGroupe.map((p) => p.nomComplet).join(', '),
            icone: Icons.person_off_outlined,
          ),
        ],
        if (!devoir.estBrouillon) ...[
          const SizedBox(height: 16),
          Text(t.devoirCorrection, style: theme.textTheme.titleMedium),
          if (!devoir.correctionsPubliees)
            Text(t.devoirCorrectionsAide, style: secondaire),
          const SizedBox(height: 8),
          for (final ligne in etat.lignes) ...[
            _LigneRendu(etat: etat, ligne: ligne),
            const SizedBox(height: 8),
          ],
          if (!devoir.correctionsPubliees && etat.lignes.isNotEmpty)
            FilledButton.icon(
              onPressed: () => _geste(context, ref, 'publier-corrections',
                  confirmation: t.devoirPublierCorrectionsConfirmer),
              icon: const Icon(Icons.campaign_outlined),
              label: Text(t.devoirPublierCorrections),
            ),
          if (devoir.estNote && devoir.correctionsPubliees) ...[
            const SizedBox(height: 16),
            _Versement(etat: etat, surVerser: (donnees) => _geste(context, ref, 'verser', donnees: donnees)),
          ],
        ],
      ],
    );
  }
}

TonPastille _tonCorrection(String statut) => switch (statut) {
      'corrige' => TonPastille.succes,
      'non_rendu' => TonPastille.danger,
      'dispense' => TonPastille.neutre,
      _ => TonPastille.alerte,
    };

class _LigneRendu extends ConsumerWidget {
  const _LigneRendu({required this.etat, required this.ligne});

  final DevoirComplet etat;
  final LigneCorrection ligne;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final rendu = ligne.rendu;
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return CarteYsem(
      onTap: () async {
        final modifie = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _FeuilleCorrection(etat: etat, ligne: ligne),
        );
        if (modifie == true) ref.invalidate(devoirEnseignantProvider(etat.devoir.id));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: Text(ligne.libelle, style: theme.textTheme.titleSmall)),
            if (rendu != null && rendu.statutCorrection.isNotEmpty)
              Pastille(rendu.statutCorrectionLibelle, ton: _tonCorrection(rendu.statutCorrection)),
          ]),
          if (ligne.groupe != null && ligne.groupe!.membres.isNotEmpty)
            Text(ligne.groupe!.membres.map((m) => m.nomComplet).join(', '), style: secondaire),
          if (ligne.sujet.isNotEmpty) Text(ligne.sujet, style: secondaire),
          const SizedBox(height: 4),
          if (rendu == null || !rendu.estRendu)
            Text(t.devoirRienDeRendu, style: secondaire)
          else
            Text(
              '${t.devoirRenduLe(Formats.horodatage(rendu.renduLe, langue))}'
              '${rendu.enRetard ? ' · ${t.devoirEnRetard}' : ''}'
              '${rendu.nbPieces > 0 ? ' · ${rendu.nbPieces} 📎' : ''}',
              style: secondaire?.copyWith(color: rendu.enRetard ? theme.colorScheme.error : null),
            ),
          if (rendu?.note != null && etat.devoir.noteSur != null)
            Text('${Formats.note(rendu!.note, langue)} / ${Formats.note(etat.devoir.noteSur, langue)}',
                style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

/// Lire le rendu et poser sa correction : statut, note, commentaire.
class _FeuilleCorrection extends ConsumerStatefulWidget {
  const _FeuilleCorrection({required this.etat, required this.ligne});

  final DevoirComplet etat;
  final LigneCorrection ligne;

  @override
  ConsumerState<_FeuilleCorrection> createState() => _FeuilleCorrectionState();
}

class _FeuilleCorrectionState extends ConsumerState<_FeuilleCorrection> {
  late String _statut = (widget.ligne.rendu?.statutCorrection.isNotEmpty ?? false)
      ? widget.ligne.rendu!.statutCorrection
      : (widget.ligne.rendu?.estRendu ?? false ? 'a_corriger' : 'non_rendu');
  late final _note = TextEditingController(
      text: widget.ligne.rendu?.note == null ? '' : '${widget.ligne.rendu!.note}');
  late final _commentaire = TextEditingController(text: widget.ligne.rendu?.commentaire ?? '');
  bool _envoi = false;

  @override
  void dispose() {
    _note.dispose();
    _commentaire.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    setState(() => _envoi = true);
    final note = _note.text.trim().replaceAll(',', '.');
    var statut = _statut;
    if (note.isNotEmpty && statut == 'a_corriger') statut = 'corrige';
    try {
      await ref.read(enseignantRepositoryProvider).corrigerDevoir(widget.etat.devoir.id, [
        {
          'cible': widget.ligne.cible,
          'statut': statut,
          'note': note.isEmpty ? null : note,
          'commentaire': _commentaire.text.trim(),
        },
      ]);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _envoi = false);
      _message(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rendu = widget.ligne.rendu;
    final estNote = widget.etat.devoir.estNote;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(widget.ligne.libelle, style: theme.textTheme.titleMedium),
            if (rendu != null && rendu.texte.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(rendu.texte),
            ],
            for (final piece in rendu?.pieces ?? const <PieceDevoir>[])
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(iconeDeFichier(piece.nom)),
                title: Text(piece.nom, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => telechargerEtOuvrir(
                    context, () => ref.read(enseignantRepositoryProvider).pieceRendu(piece)),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _statut,
              decoration: InputDecoration(labelText: t.devoirCorrection),
              items: [
                DropdownMenuItem(value: 'a_corriger', child: Text(t.devoirStatutACorriger)),
                DropdownMenuItem(value: 'corrige', child: Text(t.devoirStatutCorrige)),
                DropdownMenuItem(value: 'non_rendu', child: Text(t.devoirStatutNonRendu)),
                DropdownMenuItem(value: 'dispense', child: Text(t.devoirStatutDispense)),
              ],
              onChanged: _envoi ? null : (v) => setState(() => _statut = v ?? _statut),
            ),
            if (estNote && (_statut == 'corrige' || _statut == 'a_corriger')) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                enabled: !_envoi,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: t.devoirNote,
                  suffixText: '/ ${widget.etat.devoir.noteSur?.toStringAsFixed(0)}',
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _commentaire,
              enabled: !_envoi,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(labelText: t.devoirCommentaire, alignLabelWithHint: true),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _envoi ? null : _enregistrer,
              icon: const Icon(Icons.save_rounded),
              label: Text(t.enregistrer),
            ),
          ],
        ),
      ),
    );
  }
}

class _Versement extends StatefulWidget {
  const _Versement({required this.etat, required this.surVerser});

  final DevoirComplet etat;
  final void Function(Map<String, dynamic>) surVerser;

  @override
  State<_Versement> createState() => _VersementState();
}

class _VersementState extends State<_Versement> {
  late int? _feuille = widget.etat.feuilles.firstOrNull?.id;
  late int? _type = widget.etat.typesControle.firstOrNull?.id;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final etat = widget.etat;
    return CarteYsem(
      titre: t.devoirVerser,
      icone: Icons.move_to_inbox_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.devoirVerserAide, style: Theme.of(context).textTheme.bodySmall),
          if (etat.controleVerse != null) ...[
            const SizedBox(height: 6),
            Text(t.devoirDejaVerse(etat.controleVerse!.libelle)),
          ],
          const SizedBox(height: 8),
          if (etat.feuilles.isEmpty)
            Text(t.devoirAucuneFeuille)
          else ...[
            DropdownButtonFormField<int>(
              initialValue: _feuille,
              isExpanded: true,
              decoration: InputDecoration(labelText: t.devoirFeuille),
              items: [
                for (final f in etat.feuilles)
                  DropdownMenuItem(value: f.id, child: Text(f.libelle, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _feuille = v),
            ),
            if (etat.controleVerse == null) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _type,
                isExpanded: true,
                decoration: InputDecoration(labelText: t.devoirTypeControle),
                items: [
                  for (final type in etat.typesControle)
                    DropdownMenuItem(value: type.id, child: Text(type.libelle)),
                ],
                onChanged: (v) => setState(() => _type = v),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _feuille == null
                  ? null
                  : () => widget.surVerser({'feuille': _feuille, 'type_controle': _type}),
              icon: const Icon(Icons.file_download_done_rounded),
              label: Text(t.devoirVerserBouton),
            ),
          ],
        ],
      ),
    );
  }
}
