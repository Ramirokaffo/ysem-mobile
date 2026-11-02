import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/formulaire.dart';
import '../../../commun/langue.dart';
import '../../application/lectures.dart';
import '../../domain/situation.dart';

/// « Mes vacations » : les fiches d'émargement, que l'enseignant transmet sans
/// jamais les valider, et ce que le service en a arrêté. Un état encore en
/// brouillon n'y paraît pas : il ne dit rien de ce qui sera versé.
class VacationsPage extends ConsumerWidget {
  const VacationsPage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(titre ?? t.sectionVacations),
          bottom: TabBar(
            tabs: [Tab(text: t.fichesEmargement), Tab(text: t.paiements)],
          ),
        ),
        body: VueAsynchrone<Vacations>(
          valeur: ref.watch(vacationsProvider),
          surRafraichir: () => ref.refresh(vacationsProvider.future),
          constructeur: (donnees) => TabBarView(
            children: [
              _ListeFiches(donnees: donnees),
              _ListePaiements(donnees: donnees),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListeFiches extends ConsumerWidget {
  const _ListeFiches({required this.donnees});

  final Vacations donnees;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(vacationsProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Encadre(
            texte: t.fichesEmargementExplication,
            icone: Icons.info_outline_rounded,
          ),
          const SizedBox(height: 16),
          if (donnees.fiches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: EtatVide(
                message: t.aucuneFicheEmargement,
                icone: Icons.description_outlined,
              ),
            ),
          for (final fiche in donnees.fiches) ...[
            _CarteFiche(fiche: fiche),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _CarteFiche extends ConsumerStatefulWidget {
  const _CarteFiche({required this.fiche});

  final FicheEmargement fiche;

  @override
  ConsumerState<_CarteFiche> createState() => _CarteFicheState();
}

class _CarteFicheState extends ConsumerState<_CarteFiche> {
  bool _enCours = false;

  Future<void> _transmettre() async {
    final t = AppLocalizations.of(context);
    final langue = langueCourante(context);
    final messager = ScaffoldMessenger.of(context);
    final ok = await confirmer(
      context,
      titre: t.transmettreLaFiche,
      texte: t.transmettreFicheConfirmation(
        widget.fiche.cours.libelle(langue),
        Formats.moisAnnee(widget.fiche.mois, langue),
      ),
      action: t.transmettre,
    );
    if (!ok || !mounted) return;
    setState(() => _enCours = true);
    try {
      final message = await ref
          .read(enseignantRepositoryProvider)
          .transmettreFiche(widget.fiche.id);
      messager.showSnackBar(SnackBar(content: Text(message)));
      ref.invalidate(vacationsProvider);
      ref.read(menuEnseignantProvider.notifier).rafraichir();
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final f = widget.fiche;
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return CarteYsem(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(f.cours.libelle(langue), style: theme.textTheme.titleSmall),
          Text(
            [Formats.moisAnnee(f.mois, langue), f.cohorte]
                .where((x) => x.isNotEmpty)
                .join(' · '),
            style: secondaire,
          ),
          const SizedBox(height: 4),
          Text(
            '${t.seancesDeLaSemaine(f.nbSeances)} · '
            '${Formats.heures(f.heuresEffectives, langue)}',
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          // Sur sa ligne : les libellés de statut sont longs (« Validée par
          // les Affaires Académiques ») et seraient tronqués à côté du cours.
          Align(
            alignment: Alignment.centerLeft,
            child: Pastille(f.statutLibelle,
                ton: f.transmissible
                    ? TonPastille.alerte
                    : Pastille.tonDuStatut(f.statut)),
          ),
          if (f.motifRejet.isNotEmpty) ...[
            const SizedBox(height: 10),
            Encadre(
              titre: t.motifDuRenvoi,
              texte: f.motifRejet,
              icone: Icons.reply_rounded,
            ),
          ],
          if (f.seances.isNotEmpty)
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(t.detailDesSeances,
                    style: theme.textTheme.labelLarge),
                children: [
                  for (final l in f.seances)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              [
                                Formats.jourCourt(l.date, langue),
                                Formats.plage(l.arrivee, l.depart),
                                if (l.rattrapage) t.seanceRattrapage,
                              ].where((x) => x.isNotEmpty).join(' · '),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          Text(Formats.heures(l.heures, langue),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (f.transmissible) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _enCours ? null : _transmettre,
              icon: _enCours
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(t.transmettreLaFiche),
            ),
          ],
        ],
      ),
    );
  }
}

class _ListePaiements extends ConsumerWidget {
  const _ListePaiements({required this.donnees});

  final Vacations donnees;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final vide = donnees.etats.isEmpty && donnees.vacationsExamen.isEmpty;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(vacationsProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (vide)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: EtatVide(
                message: t.aucunEtatPaiement,
                icone: Icons.payments_outlined,
              ),
            ),
          for (final etat in donnees.etats) ...[
            _CarteEtat(etat: etat),
            const SizedBox(height: 12),
          ],
          if (donnees.vacationsExamen.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(t.vacationsExamen,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final v in donnees.vacationsExamen) ...[
              _CarteVacationExamen(vacation: v),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

/// Une ligne « libellé … montant » d'un décompte.
class _LigneMontant extends StatelessWidget {
  const _LigneMontant(this.libelle, this.valeur, {this.fort = false});

  final String libelle;
  final String valeur;
  final bool fort;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              libelle,
              style: fort
                  ? theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w800)
                  : theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Text(
            valeur,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: fort ? FontWeight.w800 : FontWeight.w600,
              color: fort ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteEtat extends StatelessWidget {
  const _CarteEtat({required this.etat});

  final EtatPaiement etat;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final e = etat;
    final bloque = e.statut == 'bloque';
    return CarteYsem(
      titre: Formats.moisAnnee(e.mois, langue),
      icone: Icons.receipt_long_outlined,
      action: Pastille(e.statutLibelle, ton: Pastille.tonDuStatut(e.statut)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LigneMontant(
              t.heuresEffectuees, Formats.heures(e.heuresEffectives, langue)),
          if ((e.heuresRattrapage ?? 0) > 0)
            _LigneMontant(t.heuresDeRattrapage,
                Formats.heures(e.heuresRattrapage, langue)),
          if ((e.heuresRetenues ?? 0) > 0)
            _LigneMontant(
                t.heuresRetenues, Formats.heures(e.heuresRetenues, langue)),
          // Un état bloqué ne porte aucun montant.
          if (!bloque) ...[
            const Divider(),
            _LigneMontant(t.montantBrut, Formats.montant(e.montantBrut, langue)),
            _LigneMontant(
              e.exonere
                  ? t.precompteExonere
                  : t.precompteAuTaux(
                      Formats.coefficient(e.tauxPrecompte ?? 0, langue)),
              Formats.montant(e.montantPrecompte, langue),
            ),
            _LigneMontant(t.montantNet, Formats.montant(e.montantNet, langue),
                fort: true),
          ],
          if (e.payeLe != null) ...[
            const SizedBox(height: 6),
            Text(t.payeLe(Formats.dateLongue(e.payeLe, langue)),
                style: theme.textTheme.bodySmall?.copyWith(
                    color: YsemTokens.of(context).succes,
                    fontWeight: FontWeight.w700)),
          ],
          if (e.motifBlocage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Encadre(
              titre: t.paiementBloque,
              texte: e.motifBlocage,
              icone: Icons.block_rounded,
            ),
          ],
          if (e.reserves.isNotEmpty) ...[
            const SizedBox(height: 10),
            Encadre(
              titre: t.reservesDuMois,
              texte: e.reserves.map((r) => '• $r').join('\n'),
              icone: Icons.assignment_late_outlined,
            ),
          ],
        ],
      ),
    );
  }
}

class _CarteVacationExamen extends StatelessWidget {
  const _CarteVacationExamen({required this.vacation});

  final VacationExamen vacation;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final v = vacation;
    return CarteYsem(
      titre: v.session,
      icone: Icons.assignment_outlined,
      action: Pastille(v.statutLibelle, ton: Pastille.tonDuStatut(v.statut)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LigneMontant(t.commissions, Formats.montant(v.commissions, langue)),
          _LigneMontant(t.surveillance, Formats.montant(v.surveillance, langue)),
          const Divider(),
          _LigneMontant(t.montantBrut, Formats.montant(v.brut, langue)),
          if ((v.precompte ?? 0) > 0)
            _LigneMontant(t.precompte, Formats.montant(v.precompte, langue)),
          _LigneMontant(t.montantNet, Formats.montant(v.net, langue), fort: true),
          if (v.payeLe != null) ...[
            const SizedBox(height: 6),
            Text(t.payeLe(Formats.dateLongue(v.payeLe, langue)),
                style: theme.textTheme.bodySmall?.copyWith(
                    color: YsemTokens.of(context).succes,
                    fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}
