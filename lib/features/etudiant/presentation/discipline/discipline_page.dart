import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../application/sections.dart';
import '../../domain/discipline.dart';

/// « Ma discipline » : l'assiduité **exactement** comme le service la lit —
/// même dénominateur, même seuil d'accès aux examens. C'est cette symétrie
/// qui rend une sanction opposable.
class DisciplinePage extends ConsumerWidget {
  const DisciplinePage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionDiscipline)),
      body: VueAsynchrone<DossierDiscipline>(
        valeur: ref.watch(disciplineProvider),
        surRafraichir: () => ref.refresh(disciplineProvider.future),
        constructeur: (dossier) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: dossier.vide
              ? [
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: EtatVide(
                        message: t.aucunDossierDiscipline,
                        icone: Icons.verified_user_outlined),
                  ),
                ]
              : [
                  _CarteAssiduite(dossier: dossier),
                  if (dossier.sanctions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _CarteSanctions(sanctions: dossier.sanctions),
                  ],
                  if (dossier.parCours.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _CarteParCours(lignes: dossier.parCours),
                  ],
                  const SizedBox(height: 16),
                  _CarteManquements(manquements: dossier.manquements),
                  if (dossier.incidents.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _CarteIncidents(incidents: dossier.incidents),
                  ],
                ],
        ),
      ),
    );
  }
}

TonPastille _tonEligibilite(String eligibilite) => switch (eligibilite) {
      'eligible' => TonPastille.succes,
      'a_risque' => TonPastille.alerte,
      'non_eligible' => TonPastille.danger,
      _ => TonPastille.neutre,
    };

Color _couleurEligibilite(BuildContext context, String eligibilite) {
  final jetons = YsemTokens.of(context);
  return switch (eligibilite) {
    'eligible' => jetons.succes,
    'a_risque' => jetons.alerte,
    'non_eligible' => jetons.danger,
    _ => Theme.of(context).colorScheme.secondary,
  };
}

/// Un taux de 0 à 1 en pourcentage entier ; `—` sans séance prévue.
String _pourcent(double? taux) =>
    taux == null ? '—' : '${(taux * 100).round()} %';

class _CarteAssiduite extends StatelessWidget {
  const _CarteAssiduite({required this.dossier});

  final DossierDiscipline dossier;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final a = dossier.assiduite;

    Widget compteur(String libelle, int valeur, String precision) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(libelle,
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              Text('$valeur',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              if (precision.isNotEmpty)
                Text(precision,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        );

    return CarteYsem(
      titre: t.tauxPresence,
      icone: Icons.how_to_reg_outlined,
      action: a.eligibiliteLibelle.isEmpty
          ? null
          : Pastille(a.eligibiliteLibelle, ton: _tonEligibilite(a.eligibilite)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AnneauAvancement(
                pourcentage:
                    a.tauxPresence == null ? 0 : (a.tauxPresence! * 100).round(),
                couleur: _couleurEligibilite(context, a.eligibilite),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.seancesPrevuesNombre(a.seancesPrevues),
                        style: theme.textTheme.titleSmall),
                    if (dossier.seuilAssiduite != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        t.seuilExamens(_pourcent(dossier.seuilAssiduite)),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              compteur(t.absences, a.absences,
                  a.absences == 0 ? '' : t.absencesNonJustifiees(a.absencesNonJustifiees)),
              compteur(t.retards, a.retards,
                  a.retards == 0 ? '' : t.retardsNonJustifies(a.retardsNonJustifies)),
            ],
          ),
          if (!a.modeFiable) ...[
            const SizedBox(height: 14),
            Encadre(texte: t.assiduiteParException),
          ],
        ],
      ),
    );
  }
}

class _CarteParCours extends StatelessWidget {
  const _CarteParCours({required this.lignes});

  final List<AssiduiteCours> lignes;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    return CarteYsem(
      titre: t.assiduiteParCours,
      icone: Icons.class_outlined,
      child: Column(
        children: [
          for (final (i, ligne) in lignes.indexed) ...[
            if (i > 0) const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ligne.cours.libelle(langue),
                          style: theme.textTheme.titleSmall),
                      Text(
                        t.absencesSurSeances(ligne.absences, ligne.seancesPrevues),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _pourcent(ligne.tauxPresence),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _couleurEligibilite(context, ligne.eligibilite),
                      ),
                    ),
                    if (ligne.eligibilite == 'a_risque' ||
                        ligne.eligibilite == 'non_eligible')
                      Pastille(ligne.eligibiliteLibelle,
                          ton: _tonEligibilite(ligne.eligibilite)),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CarteManquements extends StatelessWidget {
  const _CarteManquements({required this.manquements});

  final List<Manquement> manquements;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final jetons = YsemTokens.of(context);
    final langue = langueCourante(context);

    TonPastille tonJustification(String j) => switch (j) {
          'justifiee' => TonPastille.succes,
          'en_attente' => TonPastille.alerte,
          'non_justifiee' => TonPastille.danger,
          _ => TonPastille.neutre,
        };

    return CarteYsem(
      titre: t.absencesEtRetards,
      icone: Icons.event_busy_outlined,
      child: manquements.isEmpty
          ? EtatVide(
              message: t.aucunManquement, icone: Icons.verified_outlined)
          : Column(
              children: [
                for (final (i, m) in manquements.indexed) ...[
                  if (i > 0) const Divider(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        m.estRetard
                            ? Icons.schedule_rounded
                            : Icons.person_off_outlined,
                        size: 22,
                        color: m.estRetard ? jetons.alerte : jetons.danger,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (m.cours?.libelle(langue) ?? '').isNotEmpty
                                  ? m.cours!.libelle(langue)
                                  : m.statutLibelle,
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              [
                                Formats.jourCourt(m.date, langue),
                                Formats.plage(m.debut, m.fin),
                                if (m.estRetard && (m.minutesRetard ?? 0) > 0)
                                  t.minutesDeRetard(m.minutesRetard!)
                                else
                                  m.statutLibelle,
                              ].where((s) => s.isNotEmpty).join(' · '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                            if (m.motif.isNotEmpty)
                              Text(m.motif,
                                  style: theme.textTheme.bodySmall),
                            if (m.justification == 'en_attente' &&
                                m.dateLimiteJustificatif != null)
                              Text(
                                t.justificatifAvant(Formats.dateLongue(
                                    m.dateLimiteJustificatif, langue)),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: jetons.alerte),
                              ),
                            if (m.justificationLibelle.isNotEmpty &&
                                m.justification != 'sans_objet') ...[
                              const SizedBox(height: 6),
                              Pastille(m.justificationLibelle,
                                  ton: tonJustification(m.justification)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _CarteSanctions extends StatelessWidget {
  const _CarteSanctions({required this.sanctions});

  final List<Sanction> sanctions;

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
          for (final (i, s) in sanctions.indexed) ...[
            if (i > 0) const Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.typeLibelle, style: theme.textTheme.titleSmall),
                      if (s.dateEffet != null)
                        Text(
                          s.dateFinEffet == null
                              ? t.aCompterDu(Formats.dateLongue(s.dateEffet, langue))
                              : t.semaineDuAu(
                                  Formats.dateLongue(s.dateEffet, langue),
                                  Formats.dateLongue(s.dateFinEffet, langue)),
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      if (s.motif.isNotEmpty)
                        Text(s.motif, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Pastille(s.statutLibelle,
                    ton: s.close ? TonPastille.neutre : TonPastille.danger),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CarteIncidents extends StatelessWidget {
  const _CarteIncidents({required this.incidents});

  final List<IncidentVestimentaire> incidents;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final jetons = YsemTokens.of(context);
    final langue = langueCourante(context);
    return CarteYsem(
      titre: t.tenueVestimentaire,
      icone: Icons.checkroom_outlined,
      child: Column(
        children: [
          for (final (i, incident) in incidents.indexed) ...[
            if (i > 0) const Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(incident.typeLibelle,
                          style: theme.textTheme.titleSmall),
                      Text(Formats.dateLongue(incident.date, langue),
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      if (incident.description.isNotEmpty)
                        Text(incident.description,
                            style: theme.textTheme.bodySmall),
                      if (!incident.clos && incident.echeance != null)
                        Text(
                          t.aRegulariserAvant(
                              Formats.dateLongue(incident.echeance, langue)),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: incident.enRetard
                                ? jetons.danger
                                : jetons.alerte,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (incident.evolutionLibelle.isNotEmpty)
                  Pastille(
                    incident.evolutionLibelle,
                    ton: incident.clos
                        ? TonPastille.succes
                        : (incident.enRetard
                            ? TonPastille.danger
                            : TonPastille.alerte),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
