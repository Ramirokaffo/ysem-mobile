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
import '../../application/sections.dart';
import '../../domain/reinscription.dart';
import '../mobile_money/mobile_money_page.dart';
import 'versements_page.dart';

/// « Ma réinscription » pour l'année active. La demande pose l'inscription
/// de l'année **non prononcée** ; elle l'est dès que la première tranche est
/// soldée (ou couverte par un moratoire accordé). Le niveau suit la décision
/// du jury quand elle est publiée.
class ReinscriptionPage extends ConsumerWidget {
  const ReinscriptionPage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionReinscription)),
      body: VueAsynchrone<Reinscription>(
        valeur: ref.watch(reinscriptionProvider),
        surRafraichir: () => ref.refresh(reinscriptionProvider.future),
        constructeur: (etat) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _CarteEtat(etat: etat),
            if (etat.demandePossible) ...[
              const SizedBox(height: 16),
              _FormulaireDemande(etat: etat),
            ],
            if (etat.aUneDemande || etat.enAttenteDePaiement) ...[
              const SizedBox(height: 16),
              _CartePremiereTranche(etat: etat),
            ],
          ],
        ),
      ),
    );
  }
}

class _CarteEtat extends StatelessWidget {
  const _CarteEtat({required this.etat});

  final Reinscription etat;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    final (etatLibelle, ton, icone) = etat.dejaInscrit
        ? (t.inscriptionPrononcee, TonPastille.succes, Icons.verified_rounded)
        : etat.aUneDemande
            ? (etat.demandeStatutLibelle, TonPastille.alerte,
                Icons.hourglass_top_rounded)
            : etat.demandePossible
                ? (t.reinscriptionAFaire, TonPastille.marque,
                    Icons.edit_calendar_outlined)
                : (t.reinscriptionIndisponible, TonPastille.neutre,
                    Icons.event_busy_outlined);

    return CarteYsem(
      titre: etat.annee == null
          ? t.sectionReinscription
          : '${t.anneeAcademique} ${etat.annee!.nom}',
      icone: Icons.how_to_reg_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Pastille(etatLibelle, ton: ton, icone: icone),
          ),
          if (etat.programme != null) ...[
            const SizedBox(height: 10),
            Text(t.programme, style: secondaire),
            Text(etat.programme!.libelle(langue),
                style: theme.textTheme.titleSmall),
          ],
          if (etat.niveauInscrit != null) ...[
            const SizedBox(height: 8),
            Text(t.niveauEtSpecialite, style: secondaire),
            Text(
              [
                etat.niveauInscrit!.libelle(langue),
                if (etat.specialiteInscrite != null)
                  etat.specialiteInscrite!.libelle(langue),
              ].join(' · '),
              style: theme.textTheme.titleSmall,
            ),
          ],
          if (etat.demandeeLe != null) ...[
            const SizedBox(height: 8),
            Text(
              [
                t.demandeeLe(Formats.horodatage(etat.demandeeLe, langue)),
                if (etat.demandeur.isNotEmpty) t.parDemandeur(etat.demandeur),
              ].join(' · '),
              style: secondaire,
            ),
          ],
          if (etat.motif.isNotEmpty && !etat.dejaInscrit) ...[
            const SizedBox(height: 12),
            Encadre(icone: Icons.info_outline_rounded, texte: etat.motif),
          ] else if (etat.enAttenteDePaiement) ...[
            const SizedBox(height: 12),
            Encadre(
              icone: Icons.payments_outlined,
              texte: t.reinscriptionAttentePaiement,
            ),
          ],
        ],
      ),
    );
  }
}

/// Niveau et spécialité : le niveau n'est au choix que lorsqu'aucune
/// décision de jury ne le fixe.
class _FormulaireDemande extends ConsumerStatefulWidget {
  const _FormulaireDemande({required this.etat});

  final Reinscription etat;

  @override
  ConsumerState<_FormulaireDemande> createState() => _FormulaireDemandeState();
}

class _FormulaireDemandeState extends ConsumerState<_FormulaireDemande> {
  int? _niveau;
  int? _specialite;
  bool _envoi = false;
  ApiException? _erreur;

  @override
  void initState() {
    super.initState();
    final etat = widget.etat;
    _niveau = etat.niveauInscrit?.id ??
        etat.niveauParDefaut?.id ??
        (etat.niveaux.isEmpty ? null : etat.niveaux.first.id);
    if (!etat.niveaux.any((n) => n.id == _niveau)) {
      _niveau = etat.niveaux.isEmpty ? null : etat.niveaux.first.id;
    }
    final specialite = etat.specialiteInscrite?.id;
    _specialite =
        etat.specialites.any((s) => s.id == specialite) ? specialite : null;
  }

  Future<void> _envoyer() async {
    final t = AppLocalizations.of(context);
    if (_niveau == null) return;
    if (widget.etat.specialites.isNotEmpty && _specialite == null) {
      setState(() => _erreur = ApiException(
          code: 'formulaire_invalide',
          message: t.choisirSpecialite,
          erreurs: {'speciality': [t.choisirSpecialite]}));
      return;
    }
    final messager = ScaffoldMessenger.of(context);
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final (message, _) = await ref
          .read(etudiantRepositoryProvider)
          .demanderReinscription(niveau: _niveau!, specialite: _specialite);
      messager.showSnackBar(SnackBar(content: Text(message)));
      ref.invalidate(reinscriptionProvider);
      ref.invalidate(navigationProvider);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = e);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final langue = langueCourante(context);
    final etat = widget.etat;
    final erreur = _erreur;
    final niveauFige = etat.niveauSelonJury && etat.niveaux.length <= 1;

    return CarteYsem(
      titre: etat.aUneDemande ? t.modifierMaDemande : t.demanderReinscription,
      icone: Icons.edit_note_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (erreur != null) ...[
            BandeauErreurs(
                messages: erreursGlobales(erreur, const {'level', 'speciality'})),
            const SizedBox(height: 12),
          ],
          if (etat.niveauSelonJury)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Encadre(
                icone: Icons.gavel_rounded,
                texte: etat.decisionJury.isEmpty
                    ? t.niveauSelonJury
                    : t.niveauSelonDecision(etat.decisionJury),
              ),
            ),
          DropdownButtonFormField<int>(
            initialValue: _niveau,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: t.niveau,
              errorText: erreur?.erreurDuChamp('level'),
            ),
            items: [
              for (final n in etat.niveaux)
                DropdownMenuItem(value: n.id, child: Text(n.libelle(langue))),
            ],
            onChanged: _envoi || niveauFige
                ? null
                : (v) => setState(() => _niveau = v),
          ),
          if (etat.specialites.isNotEmpty) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _specialite,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: t.specialite,
                errorText: erreur?.erreurDuChamp('speciality'),
              ),
              items: [
                for (final s in etat.specialites)
                  DropdownMenuItem(
                    value: s.id,
                    child: Text(s.libelle(langue),
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged:
                  _envoi ? null : (v) => setState(() => _specialite = v),
            ),
          ],
          const SizedBox(height: 8),
          Text(t.reinscriptionModifiable,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _envoi || _niveau == null ? null : _envoyer,
            icon: _envoi
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
            label: Text(etat.aUneDemande
                ? t.enregistrerModification
                : t.demanderReinscription),
          ),
        ],
      ),
    );
  }
}

class _CartePremiereTranche extends StatelessWidget {
  const _CartePremiereTranche({required this.etat});

  final Reinscription etat;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final tranche = etat.premiereTranche;

    Widget ligne(String libelle, double valeur, {bool fort = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(child: Text(libelle, style: theme.textTheme.bodyMedium)),
              Text(Formats.montant(valeur, langue),
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: fort ? FontWeight.w800 : FontWeight.w600,
                      color: fort ? theme.colorScheme.primary : null)),
            ],
          ),
        );

    return CarteYsem(
      titre: t.premiereTranche,
      icone: Icons.payments_outlined,
      action: tranche.couverte
          ? Pastille(t.trancheCouverte, ton: TonPastille.succes)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!tranche.configuree)
            Encadre(texte: t.trancheNonConfiguree)
          else ...[
            ligne(t.montantDu, tranche.montant),
            ligne(t.dejaPaye, tranche.paye),
            const Divider(height: 16),
            ligne(t.resteAPayer, tranche.reste, fort: true),
            if (tranche.moratoire.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(t.couverteParMoratoireRef(tranche.moratoire),
                  style: theme.textTheme.bodySmall),
            ],
          ],
          if (!tranche.couverte) ...[
            const SizedBox(height: 14),
            if (etat.paiementMobileOuvert) ...[
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        MobileMoneyPage(trancheVisee: tranche.trancheId),
                  ),
                ),
                icon: const Icon(Icons.phone_android_rounded),
                label: Text(t.payerParMobileMoney),
              ),
              const SizedBox(height: 8),
            ],
            if (etat.paiementEnLigneOuvert)
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        VersementsPage(trancheVisee: tranche.trancheId),
                  ),
                ),
                icon: const Icon(Icons.account_balance_outlined),
                label: Text(t.declarerUnVersement),
              )
            else if (!etat.paiementMobileOuvert)
              Encadre(
                  icone: Icons.storefront_outlined,
                  texte: t.trancheACaisse),
          ],
        ],
      ),
    );
  }
}
