import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../application/lectures.dart';
import '../../domain/cours.dart';
import '../sections.dart';

/// « Mes enseignements » : exactement les chiffres du service — cette symétrie
/// fait la crédibilité du suivi. Les retours des étudiants n'y figurent que si
/// le service a choisi d'en partager la suite, jamais les verbatims.
class EnseignementsPage extends ConsumerWidget {
  const EnseignementsPage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionEnseignements)),
      body: VueAsynchrone<Enseignements>(
        valeur: ref.watch(enseignementsProvider),
        surRafraichir: () => ref.refresh(enseignementsProvider.future),
        constructeur: (donnees) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _CarteCoupDoeil(donnees: donnees),
            const SizedBox(height: 16),
            Text(t.avancementDeMesCours, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (donnees.avancement.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: EtatVide(
                  message: t.aucunCoursAffecte,
                  icone: Icons.menu_book_outlined,
                ),
              ),
            for (final ligne in donnees.avancement) ...[
              _CarteAvancement(ligne: ligne),
              const SizedBox(height: 10),
            ],
            if (donnees.retours.isNotEmpty) ...[
              const SizedBox(height: 6),
              _CarteRetours(retours: donnees.retours),
            ],
            const SizedBox(height: 16),
            Text(t.seancesObservees, style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(t.seancesObserveesAide,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            if (donnees.seances.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: EtatVide(
                  message: t.aucuneSeanceObservee,
                  icone: Icons.visibility_outlined,
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

class _CarteCoupDoeil extends StatelessWidget {
  const _CarteCoupDoeil({required this.donnees});

  final Enseignements donnees;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    Widget chiffre(String valeur, String libelle) => Expanded(
          child: Column(
            children: [
              Text(valeur,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: theme.colorScheme.primary)),
              Text(libelle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        );

    return CarteYsem(
      onTap: donnees.rattrapagesOuverts > 0
          ? () => ouvrirSectionEnseignant(context, 'rattrapages')
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          chiffre('${donnees.nbSeances}', t.seancesObservees),
          chiffre('${donnees.nbAbsences}', t.absencesConstatees),
          chiffre('${donnees.rattrapagesOuverts}', t.rattrapagesOuverts),
        ],
      ),
    );
  }
}

TonPastille _tonDeTonalite(String tonalite) => switch (tonalite) {
      'success' => TonPastille.succes,
      'warning' => TonPastille.alerte,
      'danger' => TonPastille.danger,
      'info' || 'primary' => TonPastille.info,
      _ => TonPastille.neutre,
    };

class _CarteAvancement extends StatelessWidget {
  const _CarteAvancement({required this.ligne});

  final LigneAvancement ligne;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final l = ligne;
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    Widget jauge(String libelle, int faits, int prevus, double? taux) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(libelle, style: secondaire)),
                  Text('$faits / $prevus',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: (taux ?? 0).clamp(0.0, 1.0),
                ),
              ),
            ],
          ),
        );

    return CarteYsem(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(l.cours.libelle(langue),
                    style: theme.textTheme.titleSmall),
              ),
              if (l.interpretationLibelle.isNotEmpty) ...[
                const SizedBox(width: 8),
                Pastille(l.interpretationLibelle,
                    ton: _tonDeTonalite(l.tonalite)),
              ],
            ],
          ),
          Text(
            [l.niveau, l.classe, l.semestre]
                .where((s) => s.isNotEmpty)
                .join(' · '),
            style: secondaire,
          ),
          jauge(t.chapitres, l.chapitresFaits, l.chapitresPrevus, l.tauxChapitres),
          jauge(t.seances, l.seancesFaites, l.seancesPrevues, l.tauxSeances),
          if (l.seancesNonSuivies > 0) ...[
            const SizedBox(height: 6),
            Text(t.seancesNonSuivies(l.seancesNonSuivies), style: secondaire),
          ],
          if (l.derniereSeance != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                  t.derniereSeance(Formats.dateLongue(l.derniereSeance, langue)),
                  style: secondaire),
            ),
        ],
      ),
    );
  }
}

class _CarteRetours extends StatelessWidget {
  const _CarteRetours({required this.retours});

  final List<RetourPartage> retours;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return CarteYsem(
      titre: t.retoursEtudiants,
      icone: Icons.forum_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.retoursEtudiantsAide,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          for (final r in retours)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (r.cours.isNotEmpty)
                    Text(r.cours,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(r.constat, style: theme.textTheme.bodySmall),
                  if (r.actionMenee.isNotEmpty)
                    Text(r.actionMenee,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CarteSeance extends StatelessWidget {
  const _CarteSeance({required this.seance});

  final SeanceObservee seance;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final s = seance;
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
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
              if (s.statutLibelle.isNotEmpty) ...[
                const SizedBox(width: 8),
                Pastille(s.statutLibelle),
              ],
            ],
          ),
          Text(
            [
              Formats.jourCourt(s.date, langue),
              Formats.plage(s.debut, s.fin),
              s.salle,
              s.niveau,
            ].where((x) => x.isNotEmpty).join(' · '),
            style: secondaire,
          ),
          if (s.chapitreAtteint != null)
            Text(t.chapitreAtteint(s.chapitreAtteint!),
                style: theme.textTheme.bodySmall),
          if (s.constatLibelle.isNotEmpty || s.observation.isNotEmpty)
            Text(
              [s.constatLibelle, s.observation]
                  .where((x) => x.isNotEmpty)
                  .join(' · '),
              style: theme.textTheme.bodySmall,
            ),
          if (s.resolutionLibelle.isNotEmpty)
            Text(t.suiteADonner(s.resolutionLibelle), style: secondaire),
          if (s.clotureeAutomatiquement) ...[
            const SizedBox(height: 6),
            Text(t.seanceCertifieeDOffice,
                style: secondaire?.copyWith(fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}
