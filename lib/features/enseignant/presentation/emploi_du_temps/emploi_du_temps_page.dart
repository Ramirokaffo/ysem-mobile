import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/semaine.dart';
import '../../application/lectures.dart';
import '../../domain/planning.dart';

/// « Mon emploi du temps » : la semaine, navigable, et le calendrier
/// académique — la lecture de `lecturers:mon_emploi_du_temps`, rattrapages
/// programmés compris. Les journées chômées sont montrées avec ce qui les
/// explique : une semaine de congé ne se lit pas comme un emploi du temps vide.
class EmploiDuTempsEnseignantPage extends ConsumerStatefulWidget {
  const EmploiDuTempsEnseignantPage({super.key, this.titre});

  final String? titre;

  @override
  ConsumerState<EmploiDuTempsEnseignantPage> createState() =>
      _EmploiDuTempsEnseignantPageState();
}

class _EmploiDuTempsEnseignantPageState
    extends ConsumerState<EmploiDuTempsEnseignantPage> {
  /// Semaine demandée (`AAAA-MM-JJ`), `null` pour la semaine courante.
  String? _semaine;

  /// Dernière lecture réussie, gardée pendant qu'une autre semaine se charge.
  EmploiDuTemps? _derniere;

  void _allerA(DateTime? jour) {
    if (jour == null) return;
    setState(() => _semaine = Formats.iso(jour));
  }

  Future<void> _rafraichir() =>
      ref.refresh(emploiDuTempsProvider(_semaine).future);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final valeur = ref.watch(emploiDuTempsProvider(_semaine));
    if (valeur.hasValue) _derniere = valeur.value;
    final donnees = valeur.valueOrNull ?? _derniere;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.titre ?? t.emploiDuTemps),
          bottom: TabBar(
            tabs: [Tab(text: t.emploiDuTemps), Tab(text: t.calendrier)],
          ),
        ),
        body: donnees == null
            ? VueAsynchrone<EmploiDuTemps>(
                valeur: valeur,
                surRafraichir: _rafraichir,
                constructeur: (_) => const SizedBox.shrink(),
              )
            : TabBarView(
                children: [
                  _Semaine(
                    donnees: donnees,
                    chargement: valeur.isLoading,
                    erreur: valeur.hasError ? valeur.error : null,
                    surSemaine: _allerA,
                    surRafraichir: _rafraichir,
                  ),
                  RefreshIndicator(
                    onRefresh: _rafraichir,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        CarteYsem(
                          titre: t.datesAVenir,
                          icone: Icons.event_note_outlined,
                          child: donnees.calendrier.isEmpty
                              ? EtatVide(
                                  message: t.aucunEvenement,
                                  icone: Icons.event_outlined)
                              : Column(children: [
                                  for (final e in donnees.calendrier)
                                    TuileEvenement(e, passe: false),
                                ]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Semaine extends StatelessWidget {
  const _Semaine({
    required this.donnees,
    required this.chargement,
    required this.erreur,
    required this.surSemaine,
    required this.surRafraichir,
  });

  final EmploiDuTemps donnees;
  final bool chargement;
  final Object? erreur;
  final ValueChanged<DateTime?> surSemaine;
  final Future<void> Function() surRafraichir;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      children: [
        BarreSemaine(
          semaine: donnees.semaine,
          nombre: donnees.nombreDeSeances,
          surSemaine: chargement ? null : surSemaine,
        ),
        SizedBox(
          height: 3,
          child: chargement ? const LinearProgressIndicator() : null,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: surRafraichir,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
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
                    CarteJournee(journee: journee, vueEnseignant: true),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
