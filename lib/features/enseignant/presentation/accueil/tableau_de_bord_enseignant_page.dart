import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/charte/charte.dart';
import '../../../../app/router.dart';
import '../../../../core/format/formats.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../../commun/tuile_seance.dart';
import '../../application/lectures.dart';
import '../../domain/modeles.dart';
import '../avatar_enseignant.dart';
import '../sections.dart';

/// Accueil de l'espace enseignant, comme le tableau de bord du portail web :
/// pour un candidat, où en est sa candidature ; pour un recruté, ce qui
/// l'attend et ses prochaines séances.
class TableauDeBordEnseignantPage extends ConsumerWidget {
  const TableauDeBordEnseignantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableau = ref.watch(tableauDeBordEnseignantProvider);

    Future<void> rafraichir() async {
      await Future.wait([
        ref.refresh(tableauDeBordEnseignantProvider.future),
        ref.read(menuEnseignantProvider.notifier).rafraichir(),
      ]);
    }

    return Scaffold(
      body: VueAsynchrone<TableauDeBordEnseignant>(
        valeur: tableau,
        surRafraichir: rafraichir,
        constructeur: (donnees) {
          final recrute = donnees.enseignant.recrute;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _Bandeau(donnees: donnees),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (donnees.candidature.afficher) ...[
                      _CarteCandidature(
                        candidature: donnees.candidature,
                        recrute: recrute,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (recrute) ...[
                      _CarteAFaire(donnees: donnees),
                      const SizedBox(height: 16),
                      _CarteSeances(seances: donnees.prochainesSeances),
                      const SizedBox(height: 16),
                      _CarteDates(evenements: donnees.prochainesDates),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Bandeau extends StatelessWidget {
  const _Bandeau({required this.donnees});

  final TableauDeBordEnseignant donnees;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final enseignant = donnees.enseignant;
    final blancDoux = Colors.white.withValues(alpha: 0.88);
    final rattachement = [enseignant.gradeLibelle, enseignant.departement]
        .where((s) => s.isNotEmpty)
        .join(' · ');

    return BandeauMarque(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.paddingOf(context).top + 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const YsemLogo(variante: VarianteLogo.embleme, hauteur: 30),
              const Spacer(),
              if (donnees.annee != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    donnees.annee!.nom,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              GestureDetector(
                onTap: () => context.go(Routes.profilEnseignant),
                child: AvatarEnseignant(enseignant: enseignant, rayon: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.bonjour(enseignant.prenom.isEmpty
                          ? enseignant.nomComplet
                          : enseignant.prenom),
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: Colors.white),
                    ),
                    Text(
                      enseignant.matricule,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: blancDoux,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (rattachement.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.co_present_outlined, size: 18, color: blancDoux),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rattachement,
                    style:
                        theme.textTheme.bodyMedium?.copyWith(color: blancDoux),
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

/// Où en est la candidature — ou la bienvenue, une seule fois, quand elle
/// vient d'être acceptée.
class _CarteCandidature extends StatelessWidget {
  const _CarteCandidature({required this.candidature, required this.recrute});

  final Candidature candidature;
  final bool recrute;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);

    if (recrute) {
      return CarteYsem(
        titre: t.candidatureAcceptee,
        icone: Icons.celebration_outlined,
        child: Text(t.candidatureAccepteeTexte,
            style: theme.textTheme.bodyMedium),
      );
    }

    final refusee = candidature.motifDernierRefus.isNotEmpty;
    return CarteYsem(
      titre: t.maCandidature,
      icone: Icons.assignment_ind_outlined,
      action: Pastille(
        candidature.soumise
            ? t.candidatureSoumise
            : t.candidatureEtape(candidature.etape, candidature.etapes),
        ton: candidature.soumise ? TonPastille.info : TonPastille.alerte,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AnneauAvancement(
                pourcentage: candidature.progression,
                couleur: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  candidature.soumise
                      ? t.candidatureSoumiseLe(
                          Formats.dateLongue(candidature.soumiseLe, langue))
                      : t.candidatureAPoursuivre(candidature.prochaineEtape),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (refusee) ...[
            const SizedBox(height: 14),
            Encadre(
              titre: t.motifDuRefus,
              texte: candidature.motifDernierRefus,
              icone: Icons.info_outline_rounded,
            ),
          ],
          const SizedBox(height: 14),
          Text(
            t.candidatureSurLeWeb,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Ce qui attend un geste de l'enseignant : les pastilles immédiates du
/// menu, chacune menant à son écran.
class _CarteAFaire extends StatelessWidget {
  const _CarteAFaire({required this.donnees});

  final TableauDeBordEnseignant donnees;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lignes = [
      (
        donnees.compteur('nav_fiches_a_signer'),
        t.fichesASignerNombre(donnees.compteur('nav_fiches_a_signer')),
        Icons.draw_outlined,
        'fiches_a_signer',
      ),
      (
        donnees.compteur('nav_rattrapages_ouverts'),
        t.rattrapagesOuvertsNombre(donnees.compteur('nav_rattrapages_ouverts')),
        Icons.replay_rounded,
        'rattrapages',
      ),
      (
        donnees.compteur('nav_fiches_a_transmettre'),
        t.fichesATransmettreNombre(
            donnees.compteur('nav_fiches_a_transmettre')),
        Icons.send_outlined,
        'vacations',
      ),
      (
        donnees.compteur('nav_discussions_enseignant_non_lues'),
        t.messagesNonLusNombre(
            donnees.compteur('nav_discussions_enseignant_non_lues')),
        Icons.forum_outlined,
        'discussions',
      ),
    ].where((l) => l.$1 > 0).toList();

    return CarteYsem(
      titre: t.aFaire,
      icone: Icons.task_alt_rounded,
      child: lignes.isEmpty
          ? EtatVide(message: t.rienEnAttente, icone: Icons.done_all_rounded)
          : Column(
              children: [
                for (final (_, libelle, icone, section) in lignes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Icon(icone,
                          size: 20,
                          color: theme.colorScheme.onSecondaryContainer),
                    ),
                    title: Text(libelle,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant),
                    onTap: () => ouvrirSectionEnseignant(context, section),
                  ),
              ],
            ),
    );
  }
}

class _CarteSeances extends StatelessWidget {
  const _CarteSeances({required this.seances});

  final List<Seance> seances;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return CarteYsem(
      titre: t.prochainesSeances,
      icone: Icons.calendar_today_outlined,
      action: TextButton(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        onPressed: () => ouvrirSectionEnseignant(context, 'emploi_du_temps'),
        child: Text(t.toutVoir),
      ),
      child: seances.isEmpty
          ? EtatVide(message: t.aucuneSeance, icone: Icons.event_busy_outlined)
          : Column(
              children: [
                for (final (i, seance) in seances.indexed) ...[
                  if (i > 0) const Divider(),
                  TuileSeance(seance: seance, vueEnseignant: true),
                ],
              ],
            ),
    );
  }
}

class _CarteDates extends StatelessWidget {
  const _CarteDates({required this.evenements});

  final List<EvenementCalendrier> evenements;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    return CarteYsem(
      titre: t.datesAVenir,
      icone: Icons.event_note_outlined,
      child: evenements.isEmpty
          ? EtatVide(message: t.aucuneDate, icone: Icons.event_outlined)
          : Column(
              children: [
                for (final e in evenements)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Icon(Icons.flag_outlined,
                          size: 20,
                          color: theme.colorScheme.onSecondaryContainer),
                    ),
                    title: Text(e.titre,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    subtitle: Text(e.libelleDate.isNotEmpty
                        ? e.libelleDate
                        : Formats.dateLongue(e.debut, langue)),
                  ),
              ],
            ),
    );
  }
}
