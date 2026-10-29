import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../application/sections.dart';
import '../../domain/scolarite.dart';
import '../../../commun/semaine.dart';

/// « Ma scolarité » : emploi du temps semaine par semaine, calendrier
/// académique et parcours — les trois volets de `student_portal:academics`,
/// servis par une seule lecture (`scolarite/?semaine=`).
class ScolaritePage extends ConsumerStatefulWidget {
  const ScolaritePage({super.key, this.titre});

  /// Libellé du registre du portail ; repli traduit sinon.
  final String? titre;

  @override
  ConsumerState<ScolaritePage> createState() => _ScolaritePageState();
}

class _ScolaritePageState extends ConsumerState<ScolaritePage> {
  /// Semaine demandée (`AAAA-MM-JJ`), `null` pour la semaine courante.
  String? _semaine;

  /// Dernière lecture réussie : gardée à l'écran pendant qu'une autre
  /// semaine se charge, pour que le calendrier et le parcours ne clignotent
  /// pas à chaque changement de semaine.
  Scolarite? _derniere;

  void _allerA(DateTime? jour) {
    if (jour == null) return;
    setState(() => _semaine = Formats.iso(jour));
  }

  Future<void> _rafraichir() =>
      ref.refresh(scolariteProvider(_semaine).future);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final valeur = ref.watch(scolariteProvider(_semaine));
    if (valeur.hasValue) _derniere = valeur.value;
    final donnees = valeur.valueOrNull ?? _derniere;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.titre ?? t.sectionScolarite),
          bottom: TabBar(
            // Onglets à la largeur de leur libellé : trois parts égales
            // couperaient « Emploi du temps » sur un écran de 360 dp.
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelPadding: const EdgeInsets.symmetric(horizontal: 14),
            labelStyle: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
            unselectedLabelStyle: Theme.of(context).textTheme.titleSmall,
            tabs: [
              Tab(text: t.emploiDuTemps),
              Tab(text: t.calendrier),
              Tab(text: t.parcours),
            ],
          ),
        ),
        body: donnees == null
            ? VueAsynchrone<Scolarite>(
                valeur: valeur,
                surRafraichir: _rafraichir,
                constructeur: (_) => const SizedBox.shrink(),
              )
            : TabBarView(
                children: [
                  _EmploiDuTemps(
                    donnees: donnees,
                    chargement: valeur.isLoading,
                    erreur: valeur.hasError ? valeur.error : null,
                    surSemaine: _allerA,
                    surRafraichir: _rafraichir,
                  ),
                  _Calendrier(donnees: donnees, surRafraichir: _rafraichir),
                  _Parcours(donnees: donnees, surRafraichir: _rafraichir),
                ],
              ),
      ),
    );
  }
}

/// Liste défilante qui accepte toujours « tirer pour rafraîchir ».
class _Rafraichissable extends StatelessWidget {
  const _Rafraichissable({required this.surRafraichir, required this.enfants});

  final Future<void> Function() surRafraichir;
  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: surRafraichir,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: enfants,
        ),
      );
}

class _EmploiDuTemps extends StatelessWidget {
  const _EmploiDuTemps({
    required this.donnees,
    required this.chargement,
    required this.erreur,
    required this.surSemaine,
    required this.surRafraichir,
  });

  final Scolarite donnees;
  final bool chargement;
  final Object? erreur;
  final ValueChanged<DateTime?> surSemaine;
  final Future<void> Function() surRafraichir;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final semaine = donnees.semaine;

    return Column(
      children: [
        BarreSemaine(
          semaine: semaine,
          nombre: donnees.nombreDeSeances,
          surSemaine: chargement ? null : surSemaine,
        ),
        SizedBox(
          height: 3,
          child: chargement ? const LinearProgressIndicator() : null,
        ),
        Expanded(
          child: _Rafraichissable(
            surRafraichir: surRafraichir,
            enfants: [
              if (erreur != null)
                EtatErreur(erreur: erreur!, surReessayer: surRafraichir)
              else if (donnees.journees.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: EtatVide(
                    message: t.aucuneSeanceSemaine,
                    icone: Icons.event_busy_outlined,
                  ),
                )
              else
                for (final journee in donnees.journees) ...[
                  CarteJournee(journee: journee),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Calendrier extends StatelessWidget {
  const _Calendrier({required this.donnees, required this.surRafraichir});

  final Scolarite donnees;
  final Future<void> Function() surRafraichir;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _Rafraichissable(
      surRafraichir: surRafraichir,
      enfants: [
        CarteYsem(
          titre: t.datesAVenir,
          icone: Icons.event_note_outlined,
          child: donnees.calendrier.isEmpty
              ? EtatVide(message: t.aucunEvenement, icone: Icons.event_outlined)
              : Column(
                  children: [
                    for (final e in donnees.calendrier) TuileEvenement(e),
                  ],
                ),
        ),
        if (donnees.calendrierPasse.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Icon(Icons.history_rounded,
                    color: theme.colorScheme.secondary),
                title: Text(t.datesPassees, style: theme.textTheme.titleMedium),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                children: [
                  for (final e in donnees.calendrierPasse)
                    TuileEvenement(e, passe: true),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Parcours extends StatelessWidget {
  const _Parcours({required this.donnees, required this.surRafraichir});

  final Scolarite donnees;
  final Future<void> Function() surRafraichir;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    return _Rafraichissable(
      surRafraichir: surRafraichir,
      enfants: [
        if (donnees.parcours.isEmpty)
          EtatVide(message: t.aucunParcours, icone: Icons.school_outlined)
        else
          for (final inscription in donnees.parcours) ...[
            CarteYsem(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: inscription.actif
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHigh,
                    child: Icon(
                      Icons.school_rounded,
                      color: inscription.actif
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(inscription.annee?.nom ?? '',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          inscription.resume(langue),
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        if (inscription.classe.isNotEmpty)
                          Text(
                            inscription.classe,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        if (inscription.actif || !inscription.inscrit) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (inscription.actif)
                                Pastille(t.inscriptionCourante,
                                    ton: TonPastille.marque),
                              if (!inscription.inscrit)
                                Pastille(t.inscriptionNonFinalisee,
                                    ton: TonPastille.alerte),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}
