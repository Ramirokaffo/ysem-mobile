import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/charte/charte.dart';
import '../../../../app/router.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../../commun/telechargement.dart';
import '../../application/sections.dart';
import '../../domain/finances.dart';
import '../../domain/modeles.dart';
import '../reinscription/versements_page.dart';

/// « Ma situation financière » : le relevé d'une année, ses échéances, ses
/// paiements (avec reçu) et le relevé de compte PDF — les chiffres du
/// guichet, jamais recalculés.
class FinancesPage extends ConsumerStatefulWidget {
  const FinancesPage({super.key, this.titre});

  final String? titre;

  @override
  ConsumerState<FinancesPage> createState() => _FinancesPageState();
}

class _FinancesPageState extends ConsumerState<FinancesPage> {
  /// Année choisie ; `null` : l'année active, choisie par le serveur.
  int? _annee;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.titre ?? t.sectionFinances)),
      body: VueAsynchrone<Finances>(
        valeur: ref.watch(financesProvider(_annee)),
        surRafraichir: () => ref.refresh(financesProvider(_annee).future),
        constructeur: (finances) => _Contenu(
          finances: finances,
          surAnnee: (id) => setState(() => _annee = id),
        ),
      ),
    );
  }
}

class _Contenu extends ConsumerWidget {
  const _Contenu({required this.finances, required this.surAnnee});

  final Finances finances;
  final ValueChanged<int?> surAnnee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final releve = finances.releve;
    final annee = finances.annee;
    final depot = ref.read(etudiantRepositoryProvider);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (finances.anneesDisponibles.length > 1) ...[
          _ChoixAnnee(
            annees: finances.anneesDisponibles,
            choisie: annee?.id,
            surAnnee: surAnnee,
          ),
          const SizedBox(height: 12),
        ],
        if (releve == null)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: EtatVide(
              message: t.aucuneSituation,
              icone: Icons.account_balance_wallet_outlined,
            ),
          )
        else ...[
          _CarteSituation(releve: releve, annee: annee),
          if (finances.demandeEnAttente != null) ...[
            const SizedBox(height: 16),
            _DemandeEnCours(demande: finances.demandeEnAttente!),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: () =>
                    context.push(Routes.sectionEtudiant('moratoriums')),
                icon: const Icon(Icons.handshake_outlined),
                label: Text(t.demandesDeMoratoire),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const VersementsPage())),
                icon: const Icon(Icons.account_balance_outlined),
                label: Text(t.versementsDeclares),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CarteEcheancier(tranches: releve.tranches),
          const SizedBox(height: 16),
          _CartePaiements(paiements: releve.paiements),
          if (releve.moratoires.isNotEmpty) ...[
            const SizedBox(height: 16),
            _CarteMoratoires(moratoires: releve.moratoires),
          ],
          if (releve.releveDisponible && annee?.id != null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => telechargerEtOuvrir(
                  context, () => depot.releveCompte(annee!.id!)),
              icon: const Icon(Icons.download_rounded),
              label: Text(t.telechargerReleve),
            ),
          ],
        ],
      ],
    );
  }
}

class _ChoixAnnee extends StatelessWidget {
  const _ChoixAnnee({
    required this.annees,
    required this.choisie,
    required this.surAnnee,
  });

  final List<AnneeAcademique> annees;
  final int? choisie;
  final ValueChanged<int?> surAnnee;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final annee in annees)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(annee.nom),
                selected: annee.id == choisie,
                onSelected: (_) => surAnnee(annee.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _CarteSituation extends StatelessWidget {
  const _CarteSituation({required this.releve, required this.annee});

  final ReleveFinancier releve;
  final AnneeAcademique? annee;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final jetons = YsemTokens.of(context);
    final langue = langueCourante(context);
    final resume = releve.resume;
    final totaux = resume.totaux;

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
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w800, color: couleur),
              ),
            ],
          ),
        );

    return CarteYsem(
      titre: annee?.nom ?? t.situationFinanciere,
      icone: Icons.account_balance_wallet_outlined,
      action: resume.statutLibelle.isEmpty
          ? null
          : Pastille(resume.statutLibelle,
              ton: Pastille.tonDuStatut(resume.statut)),
      child: Row(
        children: [
          AnneauAvancement(
            pourcentage: resume.avancement,
            couleur: resume.statut == 'overdue'
                ? jetons.danger
                : theme.colorScheme.secondary,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                ligne(t.totalDu, totaux.totalDu),
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

class _DemandeEnCours extends StatelessWidget {
  const _DemandeEnCours({required this.demande});

  final DemandeMoratoire demande;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final langue = langueCourante(context);
    return Encadre(
      icone: Icons.hourglass_top_rounded,
      titre: t.demandeMoratoireEnCours,
      texte: [
        if (demande.reference.isNotEmpty) demande.reference,
        Formats.montant(demande.montant, langue),
        if (demande.dateSouhaitee != null)
          t.echeanceLe(Formats.dateLongue(demande.dateSouhaitee, langue)),
      ].join(' · '),
    );
  }
}

class _CarteEcheancier extends StatelessWidget {
  const _CarteEcheancier({required this.tranches});

  final List<Tranche> tranches;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final jetons = YsemTokens.of(context);
    final langue = langueCourante(context);

    return CarteYsem(
      titre: t.echeancier,
      icone: Icons.event_repeat_outlined,
      child: tranches.isEmpty
          ? EtatVide(message: t.aucuneTranche, icone: Icons.event_busy_outlined)
          : Column(
              children: [
                for (final (i, tranche) in tranches.indexed) ...[
                  if (i > 0) const Divider(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(tranche.libelle,
                                style: theme.textTheme.titleSmall),
                          ),
                          if (tranche.statutLibelle.isNotEmpty)
                            Pastille(tranche.statutLibelle,
                                ton: Pastille.tonDuStatut(tranche.etat)),
                        ],
                      ),
                      if (tranche.echeance != null)
                        Text(
                          t.echeanceLe(
                              Formats.dateLongue(tranche.echeance, langue)),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tranche.echue && !tranche.soldee
                                ? jetons.danger
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: tranche.montant <= 0
                              ? 0
                              : (tranche.montantPaye / tranche.montant)
                                  .clamp(0, 1),
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: tranche.soldee
                              ? jetons.succes
                              : (tranche.echue ? jetons.danger : null),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.payeSur(Formats.montant(tranche.montantPaye, langue),
                            Formats.montant(tranche.montant, langue)),
                        style: theme.textTheme.bodySmall,
                      ),
                      if (tranche.couverteParMoratoire)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Pastille(t.couverteParMoratoire,
                                ton: TonPastille.info,
                                icone: Icons.shield_outlined),
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

class _CartePaiements extends ConsumerWidget {
  const _CartePaiements({required this.paiements});

  final List<Paiement> paiements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final jetons = YsemTokens.of(context);
    final langue = langueCourante(context);
    final depot = ref.read(etudiantRepositoryProvider);

    return CarteYsem(
      titre: t.paiements,
      icone: Icons.receipt_long_outlined,
      child: paiements.isEmpty
          ? EtatVide(message: t.aucunPaiement, icone: Icons.receipt_outlined)
          : Column(
              children: [
                for (final p in paiements)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: jetons.succes.withValues(alpha: 0.12),
                      child: Icon(Icons.check_rounded, color: jetons.succes),
                    ),
                    title: Text(
                      Formats.montant(p.montant, langue),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text([
                      Formats.dateLongue(p.date, langue),
                      if (p.tranche.isNotEmpty) p.tranche,
                      if (p.sourceLibelle.isNotEmpty) p.sourceLibelle,
                      if (p.reference.isNotEmpty) p.reference,
                    ].where((s) => s.isNotEmpty).join(' · ')),
                    trailing: p.aUnRecu
                        ? IconButton(
                            tooltip: t.telechargerRecu,
                            icon: Icon(Icons.download_rounded,
                                color: theme.colorScheme.primary),
                            onPressed: () => telechargerEtOuvrir(
                                context, () => depot.recuPaiement(p.id)),
                          )
                        : null,
                  ),
              ],
            ),
    );
  }
}

class _CarteMoratoires extends StatelessWidget {
  const _CarteMoratoires({required this.moratoires});

  final List<MoratoireAccorde> moratoires;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    return CarteYsem(
      titre: t.moratoiresAccordes,
      icone: Icons.shield_outlined,
      child: Column(
        children: [
          for (final m in moratoires)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(Formats.montant(m.montant, langue),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              subtitle: m.echeance == null
                  ? null
                  : Text(t.echeanceLe(Formats.dateLongue(m.echeance, langue))),
              trailing: m.statutLibelle.isEmpty
                  ? null
                  : Pastille(m.statutLibelle,
                      ton: m.actif ? TonPastille.info : TonPastille.neutre),
            ),
        ],
      ),
    );
  }
}
