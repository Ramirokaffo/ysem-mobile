import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/formulaire.dart';
import '../../../commun/langue.dart';
import '../../../commun/piece_jointe.dart';
import '../../../commun/telechargement.dart';
import '../../application/lectures.dart';
import '../../domain/documents.dart';
import 'plan_page.dart';

/// Ce que dit l'état du plan, dans l'ordre du portail web : la décision du
/// service d'abord, puis ce qu'il reste à faire.
List<(String, TonPastille)> etatDuPlan(AppLocalizations t, LigneDocuments l) {
  final plan = l.plan;
  if (plan.statut == StatutsPlan.valide) {
    return [
      (plan.statutLibelle, TonPastille.succes),
      (t.publieAuxEtudiants, TonPastille.succes),
    ];
  }
  if (plan.enCorrection) return [(t.aCorriger, TonPastille.alerte)];
  if (plan.statut == StatutsPlan.propose) {
    return [(t.transmisAuService, TonPastille.succes)];
  }
  final depot = l.depotPlan;
  if (plan.saisieAttendue) {
    return [
      (
        depot != null && depot.pieces.isNotEmpty
            ? t.fichierRecuPlanATransmettre
            : t.aRemplirEtATransmettre,
        TonPastille.alerte,
      ),
    ];
  }
  if (depot?.deposeLe == null) return [(t.pasEncoreRemis, TonPastille.neutre)];
  return [(depot!.statutLibelle, TonPastille.succes)];
}

/// L'état d'un support : délai d'abord, puis la décision du service.
List<(String, TonPastille)> etatDuSupport(AppLocalizations t, DepotDocument d) {
  if (d.deposeLe == null) {
    return [
      d.enRetard
          ? (t.enRetardDeJours(d.joursDeRetard), TonPastille.alerte)
          : (t.attendu, TonPastille.neutre),
    ];
  }
  return [
    (
      d.statutLibelle,
      d.statut == 'hors_delai' ? TonPastille.alerte : TonPastille.succes,
    ),
    if (d.valide)
      (t.publieAuxEtudiants, TonPastille.succes)
    else if (d.enCorrection)
      (t.aCorriger, TonPastille.alerte)
    else
      (t.enAttenteDeValidation, TonPastille.info),
  ];
}

/// « Mes documents de cours » : une carte par cours, le plan et le support.
/// Rien n'est visible des étudiants avant validation par le service.
class DocumentsCoursPage extends ConsumerWidget {
  const DocumentsCoursPage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionDocumentsDeCours)),
      body: VueAsynchrone<DocumentsDeCours>(
        valeur: ref.watch(documentsCoursProvider),
        surRafraichir: () => ref.refresh(documentsCoursProvider.future),
        constructeur: (d) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Encadre(
              texte: t.documentsCoursExplication,
              icone: Icons.info_outline_rounded,
            ),
            const SizedBox(height: 12),
            if (d.documentsACorriger > 0) ...[
              Encadre(
                texte: t.documentsACorriger(d.documentsACorriger),
                icone: Icons.reply_rounded,
              ),
              const SizedBox(height: 12),
            ],
            if (d.lignes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: EtatVide(
                  message: t.aucunDocumentDemande,
                  icone: Icons.folder_open_outlined,
                ),
              ),
            for (final ligne in d.lignes) ...[
              _CarteCours(ligne: ligne),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _CarteCours extends StatelessWidget {
  const _CarteCours({required this.ligne});

  final LigneDocuments ligne;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final l = ligne;
    return CarteYsem(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => DocumentsDuCoursPage(
            plan: l.plan.id, titre: l.cours.libelle(langue)),
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.cours.libelle(langue), style: theme.textTheme.titleSmall),
          if (l.cohorte.isNotEmpty)
            Text(l.cohorte,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          _LigneEtat(libelle: t.planDeCours, etats: etatDuPlan(t, l)),
          if (l.depotSupport != null) ...[
            const SizedBox(height: 6),
            _LigneEtat(
              libelle: t.supportDeCours,
              etats: etatDuSupport(t, l.depotSupport!),
            ),
          ],
        ],
      ),
    );
  }
}

class _LigneEtat extends StatelessWidget {
  const _LigneEtat({required this.libelle, required this.etats});

  final String libelle;
  final List<(String, TonPastille)> etats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(libelle,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        for (final (texte, ton) in etats) Pastille(texte, ton: ton),
      ],
    );
  }
}

/// Le plan et le support d'un cours : ce qui est remis, ce qu'il reste à faire.
class DocumentsDuCoursPage extends ConsumerStatefulWidget {
  const DocumentsDuCoursPage({super.key, required this.plan, this.titre});

  final int plan;
  final String? titre;

  @override
  ConsumerState<DocumentsDuCoursPage> createState() =>
      _DocumentsDuCoursPageState();
}

class _DocumentsDuCoursPageState extends ConsumerState<DocumentsDuCoursPage> {
  bool _enCours = false;

  void _relire() {
    ref.invalidate(documentsCoursProvider);
    ref.read(menuEnseignantProvider.notifier).rafraichir();
  }

  void _ouvrirPlan({int? piece}) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PlanPage(
          plan: widget.plan, titre: widget.titre, pieceAExtraire: piece),
    ));
  }

  /// Toute écriture : un seul envoi à la fois, le refus du serveur est lu.
  Future<void> _geste(Future<void> Function() action) async {
    if (_enCours) return;
    final messager = ScaffoldMessenger.of(context);
    setState(() => _enCours = true);
    try {
      await action();
    } on ApiException catch (e) {
      final champs = e.erreurs.values.expand((m) => m).join('\n');
      messager.showSnackBar(
          SnackBar(content: Text(champs.isNotEmpty ? champs : e.message)));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _deposer(
    DepotDocument depot, {
    required List<String> extensions,
    required int restant,
  }) async {
    final pieces =
        await choisirPieces(context, extensions: extensions, restant: restant);
    if (pieces.isEmpty || !mounted) return;
    final messager = ScaffoldMessenger.of(context);
    await _geste(() async {
      final resultat = await ref
          .read(enseignantRepositoryProvider)
          .deposerDocument(depot.id, pieces: pieces);
      _relire();
      messager.showSnackBar(SnackBar(content: Text(resultat.detail)));
      // Le fichier du plan est la porte d'entrée de la saisie : on y mène,
      // comme le portail web.
      final suite = resultat.suite;
      if (suite != null && mounted) _ouvrirPlan(piece: suite.pieceALire);
    });
  }

  Future<void> _retirer(PieceDeDepot piece) async {
    final t = AppLocalizations.of(context);
    final messager = ScaffoldMessenger.of(context);
    final ok = await confirmer(
      context,
      titre: t.retirerCettePiece,
      texte: t.retirerPieceConfirmation(piece.nom),
      action: t.retirer,
    );
    if (!ok) return;
    await _geste(() async {
      final message = await ref
          .read(enseignantRepositoryProvider)
          .retirerPieceDocument(piece.id);
      _relire();
      messager.showSnackBar(SnackBar(content: Text(message)));
    });
  }

  Future<void> _modifierInformations(DepotDocument depot) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _InformationsSupport(depot: depot),
    );
    if (message == null || !mounted) return;
    _relire();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.titre ?? t.sectionDocumentsDeCours)),
      body: VueAsynchrone<DocumentsDeCours>(
        valeur: ref.watch(documentsCoursProvider),
        surRafraichir: () => ref.refresh(documentsCoursProvider.future),
        constructeur: (d) {
          final ligne = d.lignePourPlan(widget.plan);
          if (ligne == null) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: EtatVide(
                    message: t.aucunDocumentDemande,
                    icone: Icons.folder_open_outlined,
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (ligne.cohorte.isNotEmpty) ...[
                Text(ligne.cohorte,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 12),
              ],
              _cartePlan(context, d, ligne),
              if (ligne.depotSupport != null) ...[
                const SizedBox(height: 16),
                _carteSupport(context, ligne.depotSupport!),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _cartePlan(
      BuildContext context, DocumentsDeCours d, LigneDocuments ligne) {
    final t = AppLocalizations.of(context);
    final plan = ligne.plan;
    final depot = ligne.depotPlan;
    final deposer = depot != null && depot.modifiable;
    final extensions = d.planExtensions.isEmpty
        ? extensionsDocumentsCours
        : d.planExtensions;
    return CarteYsem(
      titre: t.planDeCours,
      icone: Icons.description_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Etats(etats: etatDuPlan(t, ligne)),
          _Echeance(depot: depot),
          if (plan.renvoi != null) ...[
            const SizedBox(height: 10),
            _Renvoi(renvoi: plan.renvoi!),
          ],
          if (plan.saisieAttendue &&
              depot != null &&
              depot.pieces.isNotEmpty &&
              plan.modifiable) ...[
            const SizedBox(height: 8),
            _Note(t.fichierSeulNeVautPasDepot),
          ],
          if (depot != null && depot.pieces.isNotEmpty) ...[
            const SizedBox(height: 8),
            _Pieces(
              pieces: depot.pieces,
              modifiable: depot.modifiable && !_enCours,
              surRetrait: _retirer,
            ),
          ],
          const SizedBox(height: 12),
          if (plan.modifiable) ...[
            if (d.assistantPlan && plan.pieceLisible != null) ...[
              FilledButton.icon(
                onPressed: () => _ouvrirPlan(piece: plan.pieceLisible),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(t.remplirDepuisFichierDepose),
              ),
              const SizedBox(height: 8),
            ],
            if (deposer) ...[
              _BoutonDeposer(
                libelle: t.deposerLeFichierDuPlan,
                enCours: _enCours,
                surAppui: () =>
                    _deposer(depot, extensions: extensions, restant: 1),
              ),
              if (d.planPagesMax != null) ...[
                const SizedBox(height: 4),
                _Note(t.planPagesAuPlus(d.planPagesMax!)),
              ],
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: _ouvrirPlan,
              icon: const Icon(Icons.edit_outlined),
              label: Text(deposer ? t.ouRemplirEnLigne : t.remplirEnLigne),
            ),
          ] else if (plan.modificationApresValidation) ...[
            if (depot != null && depot.modifiable) ...[
              _BoutonDeposer(
                libelle: t.deposerLeFichierDuPlan,
                enCours: _enCours,
                surAppui: () =>
                    _deposer(depot, extensions: extensions, restant: 1),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: _ouvrirPlan,
              icon: const Icon(Icons.edit_outlined),
              label: Text(t.modifierLePlanEnLigne),
            ),
            const SizedBox(height: 8),
            _Note(t.planPublieModifiable),
          ] else ...[
            OutlinedButton.icon(
              onPressed: _ouvrirPlan,
              icon: const Icon(Icons.visibility_outlined),
              label: Text(t.consulter),
            ),
            const SizedBox(height: 8),
            _Note(plan.statut == StatutsPlan.valide
                ? t.planPublieFige
                : t.planTransmisExamine),
          ],
        ],
      ),
    );
  }

  Widget _carteSupport(BuildContext context, DepotDocument depot) {
    final t = AppLocalizations.of(context);
    final projet = depot.projet;
    return CarteYsem(
      titre: t.supportDeCours,
      icone: Icons.slideshow_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Etats(etats: etatDuSupport(t, depot)),
          _Echeance(depot: depot),
          if (depot.renvoi != null) ...[
            const SizedBox(height: 10),
            _Renvoi(renvoi: depot.renvoi!),
          ],
          if (depot.pieces.isNotEmpty) ...[
            const SizedBox(height: 8),
            _Pieces(
              pieces: depot.pieces,
              modifiable: depot.modifiable && !_enCours,
              surRetrait: _retirer,
            ),
          ],
          if (projet != null && projet.prevu) ...[
            const SizedBox(height: 8),
            _Note('${t.projetFinDeCours} : ${projet.description}'),
          ],
          const SizedBox(height: 12),
          if (depot.modifiable) ...[
            _BoutonDeposer(
              libelle: depot.pieces.isEmpty
                  ? t.deposerDesFichiers
                  : t.ajouterDesFichiers,
              enCours: _enCours,
              surAppui: depot.pieces.length >= piecesParDepotMax
                  ? null
                  : () => _deposer(
                        depot,
                        extensions: extensionsDocumentsCours,
                        restant: piecesParDepotMax - depot.pieces.length,
                      ),
            ),
            const SizedBox(height: 4),
            _Note(t.piecesLimites(piecesParDepotMax)),
            if (depot.pieces.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _modifierInformations(depot),
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(t.commentaireEtProjet),
              ),
            ],
            if (depot.modificationApresValidation) ...[
              const SizedBox(height: 8),
              _Note(t.supportPublieModifiable),
            ],
          ] else
            _Note(t.supportPublieFige),
        ],
      ),
    );
  }
}

class _Etats extends StatelessWidget {
  const _Etats({required this.etats});

  final List<(String, TonPastille)> etats;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final (texte, ton) in etats) Pastille(texte, ton: ton),
        ],
      );
}

class _Echeance extends StatelessWidget {
  const _Echeance({required this.depot});

  final DepotDocument? depot;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final langue = langueCourante(context);
    final d = depot;
    if (d == null) return const SizedBox.shrink();
    final lignes = [
      if (d.echeance != null)
        t.attenduAvantLe(Formats.dateLongue(d.echeance, langue)),
      if (d.moratoire) t.moratoireAccorde,
      if (d.deposeLe != null)
        t.deposeLeDate(Formats.dateLongue(d.deposeLe, langue)),
      if (d.misAJourLe != null)
        t.misAJourLeDate(Formats.dateLongue(d.misAJourLe, langue)),
    ];
    if (lignes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: _Note(lignes.join(' · ')),
    );
  }
}

class _Renvoi extends StatelessWidget {
  const _Renvoi({required this.renvoi});

  final RenvoiDocument renvoi;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final langue = langueCourante(context);
    return Encadre(
      titre: t.renvoyePourCorrectionLe(
          Formats.dateLongue(renvoi.renvoyeLe, langue)),
      texte: renvoi.motif,
      icone: Icons.reply_rounded,
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(texte,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
  }
}

class _BoutonDeposer extends StatelessWidget {
  const _BoutonDeposer({
    required this.libelle,
    required this.enCours,
    required this.surAppui,
  });

  final String libelle;
  final bool enCours;
  final VoidCallback? surAppui;

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
        onPressed: enCours ? null : surAppui,
        icon: enCours
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : const Icon(Icons.upload_file_rounded),
        label: Text(libelle),
      );
}

class _Pieces extends ConsumerWidget {
  const _Pieces({
    required this.pieces,
    required this.modifiable,
    required this.surRetrait,
  });

  final List<PieceDeDepot> pieces;
  final bool modifiable;
  final ValueChanged<PieceDeDepot> surRetrait;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final langue = langueCourante(context);
    return Column(
      children: [
        for (final piece in pieces)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(iconeDeFichier(piece.nom)),
            title: Text(piece.nom,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(tailleLisible(piece.taille, langue)),
            onTap: () => telechargerEtOuvrir(
              context,
              () => ref
                  .read(enseignantRepositoryProvider)
                  .telechargerPieceDocument(piece),
            ),
            trailing: modifiable
                ? IconButton(
                    tooltip: t.retirer,
                    onPressed: () => surRetrait(piece),
                    icon: const Icon(Icons.delete_outline_rounded),
                  )
                : null,
          ),
      ],
    );
  }
}

/// Commentaire et projet de fin de cours : un fait du cours, demandé une fois,
/// au dépôt du support.
class _InformationsSupport extends ConsumerStatefulWidget {
  const _InformationsSupport({required this.depot});

  final DepotDocument depot;

  @override
  ConsumerState<_InformationsSupport> createState() =>
      _InformationsSupportState();
}

class _InformationsSupportState extends ConsumerState<_InformationsSupport> {
  static const _champs = {
    'commentaire',
    'projet_fin_cours_description',
    'projet_fin_cours_fichier',
  };

  late final _commentaire =
      TextEditingController(text: widget.depot.commentaire);
  late final _description =
      TextEditingController(text: widget.depot.projet?.description ?? '');
  late bool _prevu = widget.depot.projet?.prevu ?? false;
  PieceAJoindre? _fichier;
  bool _enCours = false;
  ApiException? _erreur;

  @override
  void dispose() {
    _commentaire.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _choisirFichier() async {
    final pieces =
        await choisirPieces(context, extensions: extensionsDocumentsCours);
    if (pieces.isNotEmpty && mounted) setState(() => _fichier = pieces.first);
  }

  Future<void> _envoyer() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final resultat =
          await ref.read(enseignantRepositoryProvider).deposerDocument(
                widget.depot.id,
                commentaire: _commentaire.text.trim(),
                projetPrevu: _prevu,
                projetDescription: _prevu ? _description.text.trim() : '',
                projetFichier: _prevu ? _fichier : null,
              );
      if (mounted) Navigator.of(context).pop(resultat.detail);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = e);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final erreur = _erreur;
    final projet = widget.depot.projet;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.commentaireEtProjet, style: theme.textTheme.titleLarge),
            if (erreur != null) ...[
              const SizedBox(height: 16),
              BandeauErreurs(messages: erreursGlobales(erreur, _champs)),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _commentaire,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.commentaireFacultatif,
                errorText: erreur?.erreurDuChamp('commentaire'),
              ),
            ),
            if (projet != null) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _prevu,
                title: Text(t.projetFinDeCoursQuestion),
                onChanged: (v) => setState(() => _prevu = v),
              ),
              if (_prevu) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _description,
                  minLines: 2,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: t.descriptionDuProjet,
                    hintText: t.descriptionDuProjetAide,
                    errorText:
                        erreur?.erreurDuChamp('projet_fin_cours_description'),
                    errorMaxLines: 3,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _choisirFichier,
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text(_fichier?.nom ??
                      (projet.fichierDepose
                          ? t.remplacerFichierDuProjet
                          : t.fichierDuProjetFacultatif)),
                ),
                if (erreur?.erreurDuChamp('projet_fin_cours_fichier')
                    case final message?)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(message,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error)),
                  ),
              ],
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _enCours ? null : _envoyer,
              icon: _enCours
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(t.enregistrer),
            ),
          ],
        ),
      ),
    );
  }
}
