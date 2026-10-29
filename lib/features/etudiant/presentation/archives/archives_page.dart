import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../../commun/telechargement.dart';
import '../../domain/archives.dart';

/// « Archives » de la classe : les anciennes épreuves publiées — le sujet
/// seul, jamais le corrigé — et les plans et supports des années passées.
class ArchivesPage extends ConsumerStatefulWidget {
  const ArchivesPage({super.key, this.titre});

  final String? titre;

  @override
  ConsumerState<ArchivesPage> createState() => _ArchivesPageState();
}

class _ArchivesPageState extends ConsumerState<ArchivesPage> {
  Archives? _archives;
  List<Annale> _annales = const [];
  List<SupportArchive> _supports = const [];
  Object? _erreur;
  bool _chargement = true;
  bool _suite = false;
  int? _annee;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final archives =
          await ref.read(etudiantRepositoryProvider).archives(annee: _annee);
      if (!mounted) return;
      setState(() {
        _archives = archives;
        _annales = archives.annales;
        _supports = archives.supports;
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

  /// Page suivante d'une des deux listes (`annales` vrai : les épreuves).
  Future<void> _chargerSuite({required bool annales}) async {
    final actuel = _archives;
    if (actuel == null || _suite) return;
    setState(() => _suite = true);
    final messager = ScaffoldMessenger.of(context);
    try {
      final lot = await ref.read(etudiantRepositoryProvider).archives(
            annee: _annee,
            pageAnnales: annales
                ? actuel.paginationAnnales.pageSuivante ?? 1
                : actuel.paginationAnnales.page,
            pageSupports: annales
                ? actuel.paginationSupports.page
                : actuel.paginationSupports.pageSuivante ?? 1,
          );
      if (!mounted) return;
      setState(() {
        if (annales) {
          _annales = [..._annales, ...lot.annales];
          _archives = Archives(
            annales: _annales,
            paginationAnnales: lot.paginationAnnales,
            supports: actuel.supports,
            paginationSupports: actuel.paginationSupports,
            annees: actuel.annees,
          );
        } else {
          _supports = [..._supports, ...lot.supports];
          _archives = Archives(
            annales: actuel.annales,
            paginationAnnales: actuel.paginationAnnales,
            supports: _supports,
            paginationSupports: lot.paginationSupports,
            annees: actuel.annees,
          );
        }
      });
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _suite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final archives = _archives;

    Widget liste(List<Widget> elements, {required bool annales}) {
      final pagination = annales
          ? archives!.paginationAnnales
          : archives!.paginationSupports;
      return RefreshIndicator(
        onRefresh: _charger,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (archives.annees.length > 1) ...[
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(t.toutesLesAnnees),
                        selected: _annee == null,
                        onSelected: (_) {
                          _annee = null;
                          _charger();
                        },
                      ),
                    ),
                    for (final a in archives.annees)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(a.nom),
                          selected: _annee == a.id,
                          onSelected: (_) {
                            _annee = a.id;
                            _charger();
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_chargement) const LinearProgressIndicator(minHeight: 2),
            if (elements.isEmpty && !_chargement)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EtatVide(
                  message: annales ? t.aucuneAnnale : t.aucunSupportArchive,
                  icone: Icons.inventory_2_outlined,
                ),
              ),
            ...elements,
            if (pagination.aUneSuite)
              Center(
                child: _suite
                    ? const CircularProgressIndicator()
                    : OutlinedButton.icon(
                        onPressed: () => _chargerSuite(annales: annales),
                        icon: const Icon(Icons.expand_more_rounded),
                        label: Text(t.afficherPlus),
                      ),
              ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.titre ?? t.sectionArchives),
          bottom: TabBar(tabs: [
            Tab(text: t.anciennesEpreuves),
            Tab(text: t.supportsPasses),
          ]),
        ),
        body: archives == null
            ? (_chargement
                ? const Center(child: CircularProgressIndicator())
                : EtatErreur(erreur: _erreur!, surReessayer: _charger))
            : TabBarView(children: [
                liste([
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Encadre(texte: t.annalesExplication),
                  ),
                  for (final a in _annales) _TuileAnnale(annale: a),
                ], annales: true),
                liste([for (final s in _supports) _TuileSupport(support: s)],
                    annales: false),
              ]),
      ),
    );
  }
}

class _TuileAnnale extends ConsumerWidget {
  const _TuileAnnale({required this.annale});

  final Annale annale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final details = [
      annale.annee,
      if (annale.typeExamenLibelle.isNotEmpty) annale.typeExamenLibelle,
      if (annale.semestre != null) annale.semestre!.nom,
      if (annale.dureeMinutes != null) t.dureeMinutes(annale.dureeMinutes!),
    ].where((s) => s.isNotEmpty).join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.description_outlined,
            color: theme.colorScheme.secondary),
        title: Text(annale.cours.libelle(langue),
            style: theme.textTheme.titleSmall),
        subtitle: Text([
          if (annale.intitule.isNotEmpty) annale.intitule,
          details,
        ].join('\n')),
        isThreeLine: annale.intitule.isNotEmpty,
        trailing: annale.url == null
            ? null
            : IconButton(
                tooltip: t.telechargerSujet,
                onPressed: () => telechargerEtOuvrir(
                  context,
                  () => ref.read(etudiantRepositoryProvider).documentDuChemin(
                      annale.url!,
                      nom: 'sujet_${annale.id}'),
                ),
                icon: const Icon(Icons.download_rounded),
              ),
      ),
    );
  }
}

class _TuileSupport extends ConsumerWidget {
  const _TuileSupport({required this.support});

  final SupportArchive support;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          support.type == 'plan'
              ? Icons.assignment_outlined
              : Icons.slideshow_outlined,
          color: theme.colorScheme.secondary,
        ),
        title: Text(support.cours.libelle(langue),
            style: theme.textTheme.titleSmall),
        subtitle: Text([
          support.typeLibelle,
          support.annee,
          if (support.enseignant.isNotEmpty) support.enseignant,
        ].where((s) => s.isNotEmpty).join(' · ')),
        trailing: support.url == null
            ? Tooltip(
                message: t.nonPublie,
                child: Icon(Icons.lock_outline_rounded,
                    color: theme.colorScheme.onSurfaceVariant),
              )
            : IconButton(
                tooltip: t.telecharger,
                onPressed: () => telechargerEtOuvrir(
                  context,
                  () => ref.read(etudiantRepositoryProvider).documentDuChemin(
                      support.url!,
                      nom: 'support_${support.id}'),
                ),
                icon: const Icon(Icons.download_rounded),
              ),
      ),
    );
  }
}
