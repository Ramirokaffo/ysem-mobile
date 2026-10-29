import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../../commun/piece_jointe.dart';
import '../../../commun/telechargement.dart';
import '../../domain/bibliotheque.dart';
import '../../domain/pagination.dart';

/// « Bibliothèque universitaire » : l'arborescence de dossiers composée par
/// le service, ouverte à tous les étudiants. Un dossier s'ouvre en page ; à
/// la racine, la recherche et les catégories portent sur toute la
/// bibliothèque.
class BibliothequePage extends ConsumerStatefulWidget {
  const BibliothequePage({super.key, this.titre, this.dossier});

  final String? titre;

  /// `null` : la racine.
  final DossierBibliotheque? dossier;

  @override
  ConsumerState<BibliothequePage> createState() => _BibliothequePageState();
}

class _BibliothequePageState extends ConsumerState<BibliothequePage> {
  final _saisie = TextEditingController();
  Timer? _frappe;

  VueBibliotheque? _vue;
  List<DossierBibliotheque> _dossiers = const [];
  List<DocumentBibliotheque> _documents = const [];
  Pagination _paginationDossiers = const Pagination();
  Pagination _pagination = const Pagination();
  Object? _erreur;
  bool _chargement = true;
  bool _suite = false;
  String _recherche = '';
  int? _categorie;

  bool get _estRacine => widget.dossier == null;
  bool get _filtre => _recherche.isNotEmpty || _categorie != null;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _frappe?.cancel();
    _saisie.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final vue = await ref.read(etudiantRepositoryProvider).bibliotheque(
            dossier: _filtre ? null : widget.dossier?.id,
            recherche: _recherche,
            categorie: _categorie,
          );
      if (!mounted) return;
      setState(() {
        _vue = vue;
        _dossiers = vue.dossiers;
        _documents = vue.documents;
        _paginationDossiers = vue.paginationDossiers;
        _pagination = vue.pagination;
        _chargement = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _erreur = e;
          _chargement = false;
        });
      }
    }
  }

  /// Page suivante des dossiers et/ou des documents, ajoutée à la liste.
  Future<void> _chargerSuite() async {
    if (_suite) return;
    setState(() => _suite = true);
    final messager = ScaffoldMessenger.of(context);
    try {
      final vue = await ref.read(etudiantRepositoryProvider).bibliotheque(
            dossier: _filtre ? null : widget.dossier?.id,
            recherche: _recherche,
            categorie: _categorie,
            page: _pagination.pageSuivante ?? _pagination.page,
            pageDossiers:
                _paginationDossiers.pageSuivante ?? _paginationDossiers.page,
          );
      if (!mounted) return;
      setState(() {
        if (_paginationDossiers.aUneSuite) {
          _dossiers = [..._dossiers, ...vue.dossiers];
          _paginationDossiers = vue.paginationDossiers;
        }
        if (_pagination.aUneSuite) {
          _documents = [..._documents, ...vue.documents];
          _pagination = vue.pagination;
        }
      });
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _suite = false);
    }
  }

  void _surSaisie(String valeur) {
    _frappe?.cancel();
    _frappe = Timer(const Duration(milliseconds: 400), () {
      if (valeur.trim() == _recherche) return;
      _recherche = valeur.trim();
      _charger();
    });
  }

  void _ouvrirDossier(DossierBibliotheque dossier) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BibliothequePage(dossier: dossier),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vue = _vue;
    final titre = widget.dossier?.nom ?? widget.titre ?? t.sectionBibliotheque;

    Widget corps;
    if (vue == null && _chargement) {
      corps = const Center(child: CircularProgressIndicator());
    } else if (vue == null) {
      corps = EtatErreur(erreur: _erreur!, surReessayer: _charger);
    } else {
      corps = RefreshIndicator(
        onRefresh: _charger,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (_estRacine) ...[
              TextField(
                controller: _saisie,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: t.rechercherBibliotheque,
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  suffixIcon: _saisie.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: t.effacer,
                          onPressed: () {
                            _saisie.clear();
                            _surSaisie('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
                onChanged: (v) {
                  setState(() {});
                  _surSaisie(v);
                },
              ),
              if (vue.categories.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final c in vue.categories)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(c.nom),
                            selected: _categorie == c.id,
                            onSelected: (choisie) {
                              _categorie = choisie ? c.id : null;
                              _charger();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ] else if (vue.chemin.length > 1) ...[
              Text(
                vue.chemin.map((d) => d.nom).join(' › '),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
            ],
            if (!_estRacine && (widget.dossier!.description.isNotEmpty)) ...[
              Text(widget.dossier!.description,
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
            ],
            if (_chargement) const LinearProgressIndicator(minHeight: 2),
            if (_filtre)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(t.nbResultats(_pagination.total + _paginationDossiers.total),
                    style: theme.textTheme.labelLarge),
              ),
            if (_dossiers.isEmpty && _documents.isEmpty && !_chargement)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: EtatVide(
                  message: _filtre ? t.aucunResultat : t.dossierVide,
                  icone: Icons.folder_open_outlined,
                ),
              ),
            for (final dossier in _dossiers)
              _TuileDossier(dossier: dossier, surOuvrir: () => _ouvrirDossier(dossier)),
            if (_dossiers.isNotEmpty && _documents.isNotEmpty)
              const SizedBox(height: 8),
            for (final document in _documents) _TuileDocument(document: document),
            if (_pagination.aUneSuite || _paginationDossiers.aUneSuite)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: _suite
                      ? const CircularProgressIndicator()
                      : OutlinedButton.icon(
                          onPressed: _chargerSuite,
                          icon: const Icon(Icons.expand_more_rounded),
                          label: Text(t.afficherPlus),
                        ),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(appBar: AppBar(title: Text(titre)), body: corps);
  }
}

class _TuileDossier extends StatelessWidget {
  const _TuileDossier({required this.dossier, required this.surOuvrir});

  final DossierBibliotheque dossier;
  final VoidCallback surOuvrir;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final contenu = [
      if ((dossier.nbSousDossiers ?? 0) > 0) t.nbDossiers(dossier.nbSousDossiers!),
      if (dossier.nbDocuments != null) t.nbFichiers(dossier.nbDocuments!),
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: surOuvrir,
        leading: Icon(Icons.folder_rounded,
            size: 32, color: theme.colorScheme.secondary),
        title: Text(dossier.nom, style: theme.textTheme.titleSmall),
        subtitle: contenu.isEmpty ? null : Text(contenu),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _TuileDocument extends ConsumerWidget {
  const _TuileDocument({required this.document});

  final DocumentBibliotheque document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final ligne = [
      if (document.auteurs.isNotEmpty) document.auteurs,
      if (document.annee != null) '${document.annee}',
    ].join(' · ');
    final meta = [
      if (document.extension.isNotEmpty) document.extension.toUpperCase(),
      if (document.tailleLisible.isNotEmpty) document.tailleLisible,
      if (document.deposeLe != null)
        t.ajouteLe(Formats.dateLongue(document.deposeLe, langue)),
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(YsemTokens.rayon),
        onTap: () => telechargerEtOuvrir(
          context,
          () => ref.read(etudiantRepositoryProvider).documentBibliotheque(document),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(iconeDeFichier('x.${document.extension}'),
                  size: 30, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(document.titre, style: theme.textTheme.titleSmall),
                    if (ligne.isNotEmpty)
                      Text(ligne, style: theme.textTheme.bodySmall),
                    if (document.description.isNotEmpty)
                      Text(document.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: secondaire),
                    const SizedBox(height: 2),
                    Text(meta, style: secondaire),
                    if (document.categories.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final c in document.categories)
                            Pastille(c.nom, ton: TonPastille.info),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: t.telecharger,
                onPressed: () => telechargerEtOuvrir(
                  context,
                  () => ref
                      .read(etudiantRepositoryProvider)
                      .documentBibliotheque(document),
                ),
                icon: const Icon(Icons.download_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
