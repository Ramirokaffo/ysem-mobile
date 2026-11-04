import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/formulaire.dart';
import '../../../commun/langue.dart';
import '../../domain/delegation.dart';
import '../../hors_ligne/providers.dart';
import 'message_saisie.dart';
import 'releve_position.dart';

/// La feuille d'appel d'une séance : toute la cohorte attendue, et l'on ne
/// coche que les absents — le geste réel en salle. Une ligne couverte par
/// une permission accordée est verrouillée : le serveur tranche. Rend le
/// message du serveur au retour.
class AppelPage extends ConsumerStatefulWidget {
  const AppelPage({super.key, required this.seance});

  final SeanceDelegue seance;

  @override
  ConsumerState<AppelPage> createState() => _AppelPageState();
}

class _AppelPageState extends ConsumerState<AppelPage> {
  late Future<FeuilleAppel> _feuille = _charger();
  Set<int>? _absents;
  bool _envoi = false;
  ApiException? _erreur;

  Future<FeuilleAppel> _charger() async =>
      (await ref.read(depotDelegationProvider.future)).feuilleAppel(widget.seance);

  Future<void> _enregistrer(FeuilleAppel feuille) async {
    final t = AppLocalizations.of(context);
    final absents = _absents!;
    final ok = await confirmer(
      context,
      titre: t.enregistrerLAppel,
      texte: t.confirmerAppel(absents.length, feuille.lignes.length),
      action: t.enregistrer,
    );
    if (!ok || !mounted) return;
    final depot = await ref.read(depotDelegationProvider.future);
    final precisionMax = await depot.precisionMax(widget.seance);
    if (!mounted) return;
    final (continuer, position) = await positionPourEnvoi(
      context,
      feuille.positionExigee,
      precisionMax: precisionMax,
      sansReseau: ref.read(reseauProvider).valueOrNull == false,
    );
    if (!continuer || !mounted) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final issue = await depot.enregistrerAppel(
        widget.seance,
        absents: absents.toList(),
        position: position,
      );
      if (mounted) Navigator.of(context).pop(messageDeSaisie(t, issue));
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
      appBar: AppBar(title: Text(t.appelDeLaSeance)),
      body: FutureBuilder<FeuilleAppel>(
        future: _feuille,
        builder: (context, instantane) {
          if (instantane.hasError) {
            return EtatErreur(
              erreur: instantane.error!,
              surReessayer: () => setState(() => _feuille = _charger()),
            );
          }
          final feuille = instantane.data;
          if (feuille == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final absents = _absents ??= {
            for (final l in feuille.lignes)
              if (l.absent) l.etudiantId,
          };
          final erreur = _erreur;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    Text(seance.cours.libelle(langue),
                        style: theme.textTheme.titleMedium),
                    Text(
                      [
                        Formats.jourLong(seance.date, langue),
                        Formats.plage(seance.debut, seance.fin),
                        if (seance.salle.isNotEmpty) seance.salle,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    Encadre(texte: t.appelExplication),
                    if (feuille.appel?.motifRenvoi.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Encadre(
                        icone: Icons.undo_rounded,
                        titre: t.motifDuRenvoi,
                        texte: feuille.appel!.motifRenvoi,
                      ),
                    ],
                    if (erreur != null) ...[
                      const SizedBox(height: 12),
                      BandeauErreurs(messages: [erreur.message]),
                    ],
                    const SizedBox(height: 8),
                    for (final ligne in feuille.lignes)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: ligne.verrouillee || absents.contains(ligne.etudiantId),
                        onChanged: ligne.verrouillee || _envoi
                            ? null
                            : (v) => setState(() {
                                  if (v == true) {
                                    absents.add(ligne.etudiantId);
                                  } else {
                                    absents.remove(ligne.etudiantId);
                                  }
                                }),
                        title: Text(ligne.nom),
                        subtitle: Text(ligne.verrouillee
                            ? t.couvertParPermission(ligne.permission)
                            : ligne.matricule),
                        secondary: ligne.verrouillee
                            ? Icon(Icons.lock_outline_rounded,
                                color: theme.colorScheme.onSurfaceVariant)
                            : null,
                      ),
                  ],
                ),
              ),
              Material(
                elevation: 3,
                color: theme.colorScheme.surface,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.nbAbsentsSur(
                              absents.length +
                                  feuille.lignes
                                      .where((l) =>
                                          l.verrouillee &&
                                          !absents.contains(l.etudiantId))
                                      .length,
                              feuille.lignes.length,
                            ),
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _envoi ? null : () => _enregistrer(feuille),
                          icon: _envoi
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Icon(feuille.positionExigee
                                  ? Icons.my_location_rounded
                                  : Icons.check_rounded),
                          label: Text(t.enregistrer),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
