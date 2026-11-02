import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../application/lectures.dart';
import '../../domain/situation.dart';

/// « Ma ponctualité » : les chiffres du service, séance par séance. C'est
/// cette symétrie qui rend une retenue opposable : l'enseignant qui la voit
/// peut la contester à temps. Une sanction seulement proposée n'y paraît pas.
class PonctualitePage extends ConsumerWidget {
  const PonctualitePage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionPonctualite)),
      body: VueAsynchrone<Ponctualite>(
        valeur: ref.watch(ponctualiteProvider),
        surRafraichir: () => ref.refresh(ponctualiteProvider.future),
        constructeur: (donnees) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (donnees.totaux != null) ...[
              _CarteTotaux(totaux: donnees.totaux!),
              const SizedBox(height: 16),
            ],
            if (donnees.avanceAttendue != null) ...[
              Encadre(
                texte: t.reglesPonctualite(
                    donnees.avanceAttendue!, donnees.tolerance ?? 0),
                icone: Icons.info_outline_rounded,
              ),
              const SizedBox(height: 16),
            ],
            if (donnees.sanctions.isNotEmpty) ...[
              _CarteSanctions(sanctions: donnees.sanctions),
              const SizedBox(height: 16),
            ],
            Text(t.seancesRelevees,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (donnees.seances.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: EtatVide(
                  message: t.aucuneSeanceRelevee,
                  icone: Icons.schedule_rounded,
                ),
              ),
            for (final seance in donnees.seances) ...[
              _CarteSeance(seance: seance),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _CarteTotaux extends StatelessWidget {
  const _CarteTotaux({required this.totaux});

  final TotauxPonctualite totaux;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final jetons = YsemTokens.of(context);

    Widget chiffre(String valeur, String libelle, {Color? couleur}) => Expanded(
          child: Column(
            children: [
              Text(valeur,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                      color: couleur ?? theme.colorScheme.primary)),
              Text(libelle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        );

    return CarteYsem(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              chiffre('${totaux.seancesRelevees}', t.seancesRelevees),
              chiffre('${totaux.retards}', t.retards,
                  couleur: totaux.retards > 0 ? jetons.alerte : null),
              chiffre('${totaux.absences}', t.absences,
                  couleur: totaux.absences > 0 ? jetons.danger : null),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              chiffre(Formats.duree(totaux.minutesEffectives),
                  t.heuresDispensees),
              chiffre(Formats.duree(totaux.minutesPerdues), t.heuresPerdues,
                  couleur: totaux.minutesPerdues > 0 ? jetons.alerte : null),
              chiffre(Formats.duree(totaux.minutesRetenues), t.tempsRetenu,
                  couleur: totaux.minutesRetenues > 0 ? jetons.danger : null),
            ],
          ),
        ],
      ),
    );
  }
}

class _CarteSanctions extends StatelessWidget {
  const _CarteSanctions({required this.sanctions});

  final List<SanctionEnseignant> sanctions;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    return CarteYsem(
      titre: t.sanctions,
      icone: Icons.gavel_rounded,
      child: Column(
        children: [
          for (final s in sanctions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(s.typeLibelle,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              subtitle: Text([
                s.motif,
                if (s.notifieeLe != null)
                  Formats.dateLongue(s.notifieeLe, langue),
                if ((s.minutesRetenues ?? 0) > 0)
                  t.retenue(Formats.duree(s.minutesRetenues!)),
              ].where((x) => x.isNotEmpty).join(' · ')),
              trailing: Pastille(s.statutLibelle,
                  ton: Pastille.tonDuStatut(s.statut)),
            ),
        ],
      ),
    );
  }
}

class _CarteSeance extends StatelessWidget {
  const _CarteSeance({required this.seance});

  final SeancePointee seance;

  static TonPastille _ton(String statut) => switch (statut) {
        'present' => TonPastille.succes,
        'retard' => TonPastille.alerte,
        'absent' => TonPastille.danger,
        _ => TonPastille.neutre,
      };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final s = seance;
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final horaire = [
      if (s.heureArrivee != null) t.arriveeA(s.heureArrivee!),
      if (s.heureFin != null) t.finA(s.heureFin!),
    ].join(' · ');
    final manquement = [
      if (s.minutesRetard > 0) t.retardDe(Formats.duree(s.minutesRetard)),
      if (s.minutesRetenues > 0) t.retenue(Formats.duree(s.minutesRetenues)),
    ].join(' · ');

    return CarteYsem(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(s.cours.libelle(langue),
                    style: theme.textTheme.titleSmall),
              ),
              const SizedBox(width: 8),
              Pastille(s.statutLibelle, ton: _ton(s.statut)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            [
              Formats.jourCourt(s.date, langue),
              Formats.plage(s.debut, s.fin),
              s.salle,
            ].where((x) => x.isNotEmpty).join(' · '),
            style: secondaire,
          ),
          if (s.niveau.isNotEmpty || s.classe.isNotEmpty)
            Text(
              [s.niveau, s.classe].where((x) => x.isNotEmpty).join(' · '),
              style: secondaire,
            ),
          if (horaire.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(horaire, style: theme.textTheme.bodySmall),
          ],
          if (manquement.isNotEmpty)
            Text(manquement,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: YsemTokens.of(context).alerte,
                    fontWeight: FontWeight.w700)),
          if (s.justificationLibelle.isNotEmpty || s.motif.isNotEmpty)
            Text(
              [s.justificationLibelle, s.motif]
                  .where((x) => x.isNotEmpty)
                  .join(' · '),
              style: secondaire,
            ),
          if (s.finConstateeAutomatiquement) ...[
            const SizedBox(height: 6),
            Text(t.finConstateeDOffice,
                style: secondaire?.copyWith(fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}
