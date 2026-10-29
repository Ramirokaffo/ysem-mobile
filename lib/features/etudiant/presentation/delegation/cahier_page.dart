import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/formulaire.dart';
import '../../../commun/langue.dart';
import '../../domain/delegation.dart';
import 'releve_position.dart';

/// Le cahier de texte d'une séance : ce qui a été fait (séances du plan de
/// cours) et les activités pédagogiques. Le contenu prévu est repris du plan,
/// jamais saisi. Rend le message du serveur au retour.
class CahierPage extends ConsumerStatefulWidget {
  const CahierPage({super.key, required this.seance});

  final SeanceDelegue seance;

  @override
  ConsumerState<CahierPage> createState() => _CahierPageState();
}

class _CahierPageState extends ConsumerState<CahierPage> {
  late Future<FeuilleCahier> _feuille =
      ref.read(etudiantRepositoryProvider).feuilleCahier(widget.seance);
  List<int>? _faites;
  Map<String, String>? _activites;
  bool _envoi = false;
  ApiException? _erreur;

  Future<void> _enregistrer(FeuilleCahier feuille) async {
    final (continuer, position) =
        await positionPourEnvoi(context, feuille.positionExigee);
    if (!continuer || !mounted) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final message = await ref.read(etudiantRepositoryProvider).enregistrerCahier(
            widget.seance,
            activites: {
              for (final g in feuille.groupes) g.champ: _activites![g.champ] ?? '',
            },
            seancesFaites: _faites!,
            position: position,
          );
      if (mounted) Navigator.of(context).pop(message);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _erreur = e;
          _envoi = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final seance = widget.seance;

    return Scaffold(
      appBar: AppBar(title: Text(t.cahierDeTexte)),
      body: FutureBuilder<FeuilleCahier>(
        future: _feuille,
        builder: (context, instantane) {
          if (instantane.hasError) {
            return EtatErreur(
              erreur: instantane.error!,
              surReessayer: () => setState(() => _feuille = ref
                  .read(etudiantRepositoryProvider)
                  .feuilleCahier(widget.seance)),
            );
          }
          final feuille = instantane.data;
          if (feuille == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final faites = _faites ??= feuille.blocsFaits.isNotEmpty
              ? List.of(feuille.blocsFaits)
              : [
                  if (feuille.contenusPrevus.isNotEmpty)
                    feuille.contenusPrevus.first.id,
                ];
          final activites = _activites ??= Map.of(feuille.activites);
          final erreur = _erreur;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(seance.cours.libelle(langue),
                  style: theme.textTheme.titleMedium),
              Text(
                [
                  Formats.jourLong(seance.date, langue),
                  Formats.plage(seance.debut, seance.fin),
                  if (seance.enseignant.isNotEmpty) seance.enseignant,
                ].join(' · '),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (feuille.cahier?.motifRenvoi.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Encadre(
                  icone: Icons.undo_rounded,
                  titre: t.motifDuRenvoi,
                  texte: feuille.cahier!.motifRenvoi,
                ),
              ],
              if (erreur != null) ...[
                const SizedBox(height: 12),
                BandeauErreurs(
                    messages: [
                  erreur.message,
                  ...?erreur.erreurs['blocs'],
                ]),
              ],
              const SizedBox(height: 16),
              CarteYsem(
                titre: t.contenuPrevu,
                icone: Icons.event_note_outlined,
                child: feuille.contenusPrevus.isEmpty
                    ? Text(t.aucunPlanDeCours,
                        style: theme.textTheme.bodySmall)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final p in feuille.contenusPrevus)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _SeancePlanTexte(seance: p),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              CarteYsem(
                titre: t.contenuFait,
                icone: Icons.task_alt_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, id) in faites.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: id,
                                isExpanded: true,
                                decoration: InputDecoration(
                                    labelText: t.blocN(i + 1), isDense: true),
                                items: [
                                  for (final p in feuille.seancesPlan)
                                    DropdownMenuItem(
                                      value: p.id,
                                      child: Text(
                                        p.libelle.isNotEmpty
                                            ? p.libelle
                                            : t.seanceNumero(p.numero ?? 0),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                                onChanged: _envoi
                                    ? null
                                    : (v) => setState(() => faites[i] = v ?? id),
                              ),
                            ),
                            IconButton(
                              tooltip: t.retirer,
                              onPressed: _envoi
                                  ? null
                                  : () => setState(() => faites.removeAt(i)),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    if (feuille.seancesPlan.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _envoi
                              ? null
                              : () => setState(() => faites.add(
                                  feuille.seancesPlan[faites.isEmpty
                                          ? 0
                                          : (feuille.seancesPlan.indexWhere(
                                                      (p) => p.id == faites.last) +
                                                  1)
                                              .clamp(0, feuille.seancesPlan.length - 1)]
                                      .id)),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(t.ajouterUneSeanceFaite),
                        ),
                      ),
                    Text(t.blocsAide,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CarteYsem(
                titre: t.activitesPedagogiques,
                icone: Icons.school_outlined,
                child: Column(
                  children: [
                    for (final g in feuille.groupes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String>(
                          initialValue: activites[g.champ] ?? '',
                          isExpanded: true,
                          decoration: InputDecoration(labelText: g.libelle),
                          items: [
                            DropdownMenuItem(
                                value: '', child: Text(t.nonRenseigne)),
                            for (final (valeur, libelle) in g.options)
                              DropdownMenuItem(
                                value: valeur,
                                child: Text(libelle,
                                    overflow: TextOverflow.ellipsis),
                              ),
                          ],
                          onChanged: _envoi
                              ? null
                              : (v) =>
                                  setState(() => activites[g.champ] = v ?? ''),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _envoi ? null : () => _enregistrer(feuille),
                icon: _envoi
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(feuille.positionExigee
                        ? Icons.my_location_rounded
                        : Icons.save_rounded),
                label: Text(t.enregistrerLeCahier),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SeancePlanTexte extends StatelessWidget {
  const _SeancePlanTexte({required this.seance});

  final SeancePlan seance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(seance.libelle, style: theme.textTheme.titleSmall),
        if (seance.chapitre.isNotEmpty)
          Text(seance.chapitre,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.primary)),
        if (seance.contenu.isNotEmpty)
          Text(seance.contenu, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
