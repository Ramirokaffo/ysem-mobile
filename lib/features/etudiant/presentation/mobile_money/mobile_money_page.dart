import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/formulaire.dart';
import '../../../commun/langue.dart';
import '../../application/sections.dart';
import '../../domain/mobile_money.dart';
import 'suivi_paiement_mobile_page.dart';

/// Régler par Mobile Money : le formulaire et les transactions de l'année.
/// Une transaction en attente prend la place du formulaire, comme le portail
/// web y mène : elle réserve son montant, et un étudiant n'en a qu'une ouverte.
class MobileMoneyPage extends ConsumerWidget {
  const MobileMoneyPage({super.key, this.trancheVisee, this.tout = false});

  /// Tranche proposée : le montant reprend son reste.
  final int? trancheVisee;

  /// Propose tout ce qui reste à payer, réparti dans l'ordre des tranches.
  final bool tout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.payerParMobileMoney)),
      body: VueAsynchrone<MobileMoney>(
        valeur: ref.watch(mobileMoneyProvider),
        surRafraichir: () => ref.refresh(mobileMoneyProvider.future),
        constructeur: (etat) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (!etat.ouvert)
              Encadre(
                icone: Icons.storefront_outlined,
                texte: etat.motif.isEmpty ? t.mobileMoneyFerme : etat.motif,
              )
            else ...[
              if (etat.test) ...[
                Encadre(icone: Icons.science_outlined, texte: t.mobileMoneyTest),
                const SizedBox(height: 16),
              ],
              if (etat.enCours != null)
                _CarteEnCours(paiement: etat.enCours!)
              else if (!etat.payable)
                Encadre(
                  icone: Icons.check_circle_outline_rounded,
                  texte: t.rienAPayerMobile,
                )
              else
                _Formulaire(
                    etat: etat, trancheVisee: trancheVisee, tout: tout),
            ],
            const SizedBox(height: 24),
            Text(t.paiementsMobileMoney,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (etat.paiements.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: EtatVide(
                  message: t.aucunPaiementMobile,
                  icone: Icons.phone_android_rounded,
                ),
              ),
            for (final paiement in etat.paiements) ...[
              _LignePaiement(paiement: paiement),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ouvre le suivi d'une transaction, puis relit l'état au retour.
Future<void> ouvrirSuivi(
    BuildContext context, WidgetRef ref, PaiementMobile paiement) async {
  await Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => SuiviPaiementMobilePage(paiement: paiement),
  ));
  ref.invalidate(mobileMoneyProvider);
}

class _CarteEnCours extends ConsumerWidget {
  const _CarteEnCours({required this.paiement});

  final PaiementMobile paiement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final langue = langueCourante(context);
    return CarteYsem(
      titre: paiement.statutLibelle,
      icone: Icons.hourglass_top_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.paiementDejaEnCours),
          const SizedBox(height: 6),
          Text(
            [
              Formats.montant(paiement.montantDebite, langue),
              paiement.operateurLibelle,
              paiement.telephone,
            ].where((s) => s.isNotEmpty).join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => ouvrirSuivi(context, ref, paiement),
            icon: const Icon(Icons.visibility_outlined),
            label: Text(t.suivreLePaiement),
          ),
        ],
      ),
    );
  }
}

class _Formulaire extends ConsumerStatefulWidget {
  const _Formulaire({required this.etat, this.trancheVisee, this.tout = false});

  final MobileMoney etat;
  final int? trancheVisee;
  final bool tout;

  @override
  ConsumerState<_Formulaire> createState() => _FormulaireState();
}

class _FormulaireState extends ConsumerState<_Formulaire> {
  static const _champs = {'montant', 'operateur', 'telephone', 'installment'};

  /// Le serveur calcule les frais : on attend que la frappe se pose.
  static const _delaiApercu = Duration(milliseconds: 400);

  final _cle = GlobalKey<FormState>();
  late final TextEditingController _montant;
  late final TextEditingController _telephone;
  String? _operateur;
  int? _tranche;
  bool _envoi = false;
  ApiException? _erreur;
  bool _reponsePerdue = false;
  ApercuFrais? _apercu;
  Timer? _attenteApercu;

  @override
  void initState() {
    super.initState();
    final etat = widget.etat;
    final ligne =
        etat.tranches.where((tr) => tr.id == widget.trancheVisee).firstOrNull;
    _tranche = ligne?.id;
    final propose = ligne?.resteAPayer ??
        (widget.tout ? etat.montantPayable : null);
    _montant = TextEditingController(
        text: propose == null ? '' : '${propose.round()}');
    _telephone = TextEditingController(text: etat.telephonePropose);
    _montant.addListener(_demanderApercu);
    if (etat.operateurs.length == 1) _operateur = etat.operateurs.first.code;
    if (propose != null) _lireApercu();
  }

  @override
  void dispose() {
    _attenteApercu?.cancel();
    _montant.dispose();
    _telephone.dispose();
    super.dispose();
  }

  int? get _valeur => int.tryParse(_montant.text.replaceAll(' ', ''));

  void _demanderApercu() {
    _attenteApercu?.cancel();
    if ((_valeur ?? 0) <= 0) {
      if (_apercu != null) setState(() => _apercu = null);
      return;
    }
    _attenteApercu = Timer(_delaiApercu, _lireApercu);
  }

  Future<void> _lireApercu() async {
    final montant = _valeur;
    if (montant == null || montant <= 0) return;
    try {
      final etat = await ref
          .read(etudiantRepositoryProvider)
          .mobileMoney(montant: montant);
      // Une réponse tardive ne décrit plus le montant saisi.
      if (mounted && _valeur == montant) {
        setState(() => _apercu = etat.apercu);
      }
    } on ApiException {
      // L'aperçu n'est qu'indicatif : le téléphone montre le total exact.
    }
  }

  void _choisirTranche(int? id) {
    final ligne = widget.etat.tranches.where((tr) => tr.id == id).firstOrNull;
    setState(() => _tranche = id);
    if (ligne != null) _montant.text = '${ligne.resteAPayer.round()}';
  }

  Future<void> _lancer() async {
    setState(() {
      _erreur = null;
      _reponsePerdue = false;
    });
    if (!_cle.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      final paiement =
          await ref.read(etudiantRepositoryProvider).lancerPaiementMobile(
                montant: _valeur!,
                operateur: _operateur!,
                telephone: _telephone.text.trim(),
                tranche: _tranche,
              );
      if (!mounted) return;
      setState(() => _envoi = false);
      await ouvrirSuivi(context, ref, paiement);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _envoi = false);
      final enCours = e.donnees['paiement'];
      if (e.code == 'paiement_mobile_en_cours' && enCours is Map) {
        await ouvrirSuivi(context, ref,
            PaiementMobile.depuisJson(Map<String, dynamic>.from(enCours)));
        return;
      }
      setState(() {
        _erreur = e;
        // Sans réponse, le serveur a peut-être ouvert la transaction : relire
        // l'état plutôt que de laisser relancer, sans quoi le geste suivant
        // buterait sur un paiement que l'écran ne montre pas.
        _reponsePerdue = e.estErreurReseau;
      });
      if (e.estErreurReseau) ref.invalidate(mobileMoneyProvider);
      // Les validateurs lisent `_erreur` et non une copie du dernier build :
      // ils tournent ici, avant la reconstruction.
      _cle.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final etat = widget.etat;
    final plafond = etat.montantPayable;
    final erreur = _erreur;
    final apercu = _apercu;

    return Form(
      key: _cle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CarteYsem(
            child: Row(
              children: [
                Expanded(
                  child: Text(t.montantPayableMaintenant,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
                Text(Formats.montant(plafond ?? 0, langue),
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Encadre(
              icone: Icons.phone_android_rounded, texte: t.inviteTelephone),
          if (erreur != null) ...[
            const SizedBox(height: 16),
            BandeauErreurs(
              messages: _reponsePerdue
                  ? [t.reponsePerdue]
                  : erreursGlobales(erreur, _champs),
            ),
          ],
          const SizedBox(height: 20),
          FormField<String>(
            validator: (_) =>
                _erreur?.erreurDuChamp('operateur') ??
                (_operateur == null ? t.choisirOperateur : null),
            builder: (champ) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.operateur, style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final o in etat.operateurs)
                      ChoiceChip(
                        label: Text(o.libelle),
                        selected: _operateur == o.code,
                        onSelected: _envoi
                            ? null
                            : (_) {
                                setState(() => _operateur = o.code);
                                champ.didChange(o.code);
                              },
                      ),
                  ],
                ),
                if (champ.hasError) ...[
                  const SizedBox(height: 4),
                  Text(champ.errorText!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _telephone,
            enabled: !_envoi,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 +]')),
            ],
            decoration: InputDecoration(
              labelText: t.numeroMobileMoney,
              hintText: '6XXXXXXXX',
              helperText: t.numeroMobileMoneyAide,
              helperMaxLines: 2,
              errorMaxLines: 2,
            ),
            validator: (v) {
              final serveur = _erreur?.erreurDuChamp('telephone');
              if (serveur != null) return serveur;
              final numero = (v ?? '').replaceAll(RegExp(r'[\s+]'), '');
              return RegExp(r'^(00237|237)?6\d{8}$').hasMatch(numero)
                  ? null
                  : t.numeroMobileMoneyInvalide;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            initialValue: _tranche,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: t.trancheReglee,
              errorText: erreur?.erreurDuChamp('installment'),
            ),
            items: [
              DropdownMenuItem<int?>(
                  value: null, child: Text(t.repartirSurTranches)),
              for (final tr in etat.tranches)
                DropdownMenuItem<int?>(
                  value: tr.id,
                  child: Text(
                    t.trancheReste(
                        tr.libelle.isEmpty ? '${tr.ordre ?? ''}' : tr.libelle,
                        Formats.montant(tr.resteAPayer, langue)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _envoi ? null : _choisirTranche,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _montant,
            enabled: !_envoi,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: t.montantARegler,
              suffixText: 'FCFA',
              helperText:
                  plafond == null ? null : t.auPlus(Formats.montant(plafond, langue)),
            ),
            validator: (v) {
              final serveur = _erreur?.erreurDuChamp('montant');
              if (serveur != null) return serveur;
              final montant = int.tryParse(v ?? '');
              if (montant == null || montant <= 0) return t.montantInvalide;
              if (plafond != null && montant > plafond) {
                return t.auPlus(Formats.montant(plafond, langue));
              }
              return null;
            },
          ),
          if (apercu != null && apercu.frais > 0) ...[
            const SizedBox(height: 12),
            _LigneMontant(t.fraisDeTransaction, apercu.frais),
            _LigneMontant(t.totalDebite, apercu.montantDebite, gras: true),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _envoi ? null : _lancer,
            icon: _envoi
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
            label: Text(t.lancerLePaiement),
          ),
        ],
      ),
    );
  }
}

/// Une ligne « libellé — montant » d'un récapitulatif.
class _LigneMontant extends StatelessWidget {
  const _LigneMontant(this.libelle, this.valeur, {this.gras = false});

  final String libelle;
  final double valeur;
  final bool gras;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(libelle, style: theme.textTheme.bodyMedium)),
          Text(
            Formats.montant(valeur, langueCourante(context)),
            style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: gras ? FontWeight.w800 : FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _LignePaiement extends ConsumerWidget {
  const _LignePaiement({required this.paiement});

  final PaiementMobile paiement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    return CarteYsem(
      child: InkWell(
        onTap: () => ouvrirSuivi(context, ref, paiement),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(paiement.reference,
                      style: theme.textTheme.titleSmall),
                ),
                Pastille(paiement.statutLibelle,
                    ton: tonDuPaiement(paiement.statut)),
              ],
            ),
            const SizedBox(height: 6),
            Text(Formats.montant(paiement.montant, langue),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text(
              [
                if (paiement.ouvertLe != null)
                  Formats.dateLongue(paiement.ouvertLe, langue),
                paiement.operateurLibelle,
                paiement.tranche,
                if (paiement.lanceParUnParent && paiement.payeur.isNotEmpty)
                  t.lancePar(paiement.payeur),
              ].where((s) => s.isNotEmpty).join(' · '),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
