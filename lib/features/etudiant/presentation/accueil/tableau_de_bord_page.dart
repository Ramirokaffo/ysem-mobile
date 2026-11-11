import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/charte/charte.dart';
import '../../../../app/router.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/navigation/icones_sections.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/avatar_etudiant.dart';
import '../../../commun/espace/bouton_discussions.dart';
import '../../../commun/langue.dart';
import '../../application/lectures.dart';
import '../../domain/modeles.dart';
import '../sections.dart';
import '../../../commun/tuile_seance.dart';

/// Accueil de l'espace étudiant : un aperçu, comme le tableau de bord du
/// portail web — chaque rubrique a sa page et l'accueil y renvoie.
class TableauDeBordPage extends ConsumerWidget {
  const TableauDeBordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableau = ref.watch(tableauDeBordProvider);
    final navigation = ref.watch(navigationProvider).valueOrNull;

    Future<void> rafraichir() async {
      await Future.wait([
        ref.refresh(tableauDeBordProvider.future),
        ref.read(navigationProvider.notifier).rafraichir(),
      ]);
    }

    return Scaffold(
      body: VueAsynchrone<TableauDeBord>(
        valeur: tableau,
        surRafraichir: rafraichir,
        constructeur: (donnees) => ListView(
          padding: EdgeInsets.zero,
          children: [
            _Bandeau(donnees: donnees, navigation: navigation),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (navigation != null &&
                      navigation.accesRapides.isNotEmpty) ...[
                    _AccesRapides(sections: navigation.accesRapides),
                    const SizedBox(height: 16),
                  ],
                  if (donnees.situationFinanciere != null) ...[
                    _CarteFinances(situation: donnees.situationFinanciere!),
                    const SizedBox(height: 16),
                  ],
                  _CarteSeances(seances: donnees.prochainesSeances),
                  const SizedBox(height: 16),
                  _CarteDates(evenements: donnees.prochainesDates),
                  const SizedBox(height: 16),
                  _CarteDocuments(documents: donnees.documentsRecents),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bandeau extends StatelessWidget {
  const _Bandeau({required this.donnees, required this.navigation});

  final TableauDeBord donnees;
  final Navigation? navigation;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final etudiant = donnees.etudiant;
    final cohorte = donnees.inscription?.resume(langue) ?? '';
    final blancDoux = Colors.white.withValues(alpha: 0.88);

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
              const SizedBox(width: 8),
              BoutonDiscussions(
                navigation: navigation,
                ouvrir: () => ouvrirSection(context, codeSectionDiscussions),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              GestureDetector(
                onTap: () => context.go(Routes.profilEtudiant),
                child: AvatarEtudiant(etudiant: etudiant, rayon: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.bonjour(etudiant.prenom.isEmpty
                          ? etudiant.nomComplet
                          : etudiant.prenom),
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: Colors.white),
                    ),
                    Text(
                      etudiant.matricule,
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
          if (cohorte.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.school_outlined, size: 18, color: blancDoux),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cohorte,
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

class _AccesRapides extends StatelessWidget {
  const _AccesRapides({required this.sections});

  final List<SectionNavigation> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, contraintes) {
      // Quatre tuiles par ligne tronqueraient les libellés sur un téléphone
      // étroit (« Planning des examens ») : trois en dessous de 400 dp.
      final parLigne = contraintes.maxWidth < 400 ? 3 : 4;
      const espace = 10.0;
      final largeur =
          (contraintes.maxWidth - espace * (parLigne - 1)) / parLigne;
      return Wrap(
        spacing: espace,
        runSpacing: espace,
        children: [
          for (final section in sections)
            SizedBox(
              width: largeur,
              child: Material(
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(YsemTokens.rayon),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => ouvrirSection(context, section.code),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 4),
                    child: Column(
                      children: [
                        Badge(
                          isLabelVisible: (section.badge ?? 0) > 0,
                          label: Text('${section.badge}'),
                          child: Icon(iconeDeSection(section.icone),
                              color: theme.colorScheme.secondary, size: 26),
                        ),
                        const SizedBox(height: 6),
                        // Deux lignes réservées : toutes les tuiles ont
                        // la même hauteur, quel que soit le libellé.
                        SizedBox(
                          height: 32,
                          child: Center(
                            child: Text(
                              section.libelle,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700, height: 1.2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _CarteFinances extends StatelessWidget {
  const _CarteFinances({required this.situation});

  final SituationFinanciere situation;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final jetons = YsemTokens.of(context);
    final langue = langueCourante(context);
    final totaux = situation.totaux;

    Widget ligne(String libelle, double valeur, {Color? couleur}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(libelle,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
              Text(
                Formats.montant(valeur, langue),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: couleur,
                ),
              ),
            ],
          ),
        );

    return CarteYsem(
      titre: t.situationFinanciere,
      icone: Icons.account_balance_wallet_outlined,
      action: Pastille(
        situation.statutLibelle,
        ton: Pastille.tonDuStatut(situation.statut),
      ),
      onTap: () => ouvrirSection(context, 'finances'),
      child: Row(
        children: [
          AnneauAvancement(
            pourcentage: situation.avancement,
            couleur: situation.statut == 'overdue'
                ? jetons.danger
                : theme.colorScheme.secondary,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                ligne(t.montantPaye, totaux.paye, couleur: jetons.succes),
                ligne(t.resteAPayer, totaux.resteAPayer),
                ligne(
                  t.montantEchu,
                  totaux.echu,
                  couleur: totaux.echu > 0 ? jetons.danger : null,
                ),
              ],
            ),
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
      action: _LienToutVoir(section: 'academics'),
      child: seances.isEmpty
          ? EtatVide(message: t.aucuneSeance, icone: Icons.event_busy_outlined)
          : Column(
              children: [
                for (final (i, seance) in seances.indexed) ...[
                  if (i > 0) const Divider(),
                  TuileSeance(seance: seance),
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

class _CarteDocuments extends StatelessWidget {
  const _CarteDocuments({required this.documents});

  final List<DocumentOfficiel> documents;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return CarteYsem(
      titre: t.documentsRecents,
      icone: Icons.description_outlined,
      action: _LienToutVoir(section: 'documents'),
      child: documents.isEmpty
          ? EtatVide(message: t.aucunDocument, icone: Icons.folder_off_outlined)
          : Column(
              children: [
                for (final d in documents)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(Icons.insert_drive_file_outlined,
                        color: theme.colorScheme.secondary),
                    title: Text(d.typeLibelle,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    subtitle: d.reference.isEmpty ? null : Text(d.reference),
                    trailing: d.statutLibelle.isEmpty
                        ? null
                        : Pastille(d.statutLibelle,
                            ton: Pastille.tonDuStatut(d.statut)),
                  ),
              ],
            ),
    );
  }
}

/// « Tout voir » en tête de carte, compact pour ne pas grandir l'en-tête.
class _LienToutVoir extends StatelessWidget {
  const _LienToutVoir({required this.section});

  final String section;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      onPressed: () => ouvrirSection(context, section),
      child: Text(AppLocalizations.of(context).toutVoir),
    );
  }
}
