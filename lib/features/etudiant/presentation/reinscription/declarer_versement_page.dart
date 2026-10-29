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
import '../../../commun/piece_jointe.dart';
import '../../domain/reinscription.dart';

/// Les reçus de banque acceptés par le serveur (`DeclarationPaiementForm`).
const _extensionsRecu = ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'heic'];

/// Déclaration d'un versement bancaire, avec le reçu de la banque. Les
/// contrôles sont ceux du formulaire du portail, rejoués par le serveur ;
/// l'écran n'en devance que les plus simples. Rend le message du serveur.
class DeclarerVersementPage extends ConsumerStatefulWidget {
  const DeclarerVersementPage({super.key, required this.etat, this.trancheVisee});

  final Versements etat;
  final int? trancheVisee;

  @override
  ConsumerState<DeclarerVersementPage> createState() =>
      _DeclarerVersementPageState();
}

class _DeclarerVersementPageState extends ConsumerState<DeclarerVersementPage> {
  static const _champs = {
    'compte',
    'montant',
    'date_operation',
    'reference_operation',
    'piece',
    'commentaire',
    'installment',
  };

  final _cle = GlobalKey<FormState>();
  final _montant = TextEditingController();
  final _reference = TextEditingController();
  final _commentaire = TextEditingController();
  int? _compte;
  int? _tranche;
  DateTime? _date;
  PieceAJoindre? _recu;
  bool _envoi = false;
  ApiException? _erreur;

  @override
  void initState() {
    super.initState();
    final etat = widget.etat;
    _compte = etat.comptes.length == 1 ? etat.comptes.first.id : null;
    _tranche = etat.tranchesOuvertes.any((t) => t.id == widget.trancheVisee)
        ? widget.trancheVisee
        : null;
    _date = DateUtils.dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _montant.dispose();
    _reference.dispose();
    _commentaire.dispose();
    super.dispose();
  }

  static String _normaliser(String saisie) =>
      saisie.replaceAll(RegExp(r'[\s  ]'), '').replaceAll(',', '.');

  Future<void> _choisirDate() async {
    final aujourdhui = DateUtils.dateOnly(DateTime.now());
    final choisie = await showDatePicker(
      context: context,
      initialDate: _date ?? aujourdhui,
      firstDate: aujourdhui.subtract(const Duration(days: 400)),
      lastDate: aujourdhui,
    );
    if (choisie != null) setState(() => _date = choisie);
  }

  Future<void> _envoyer() async {
    setState(() => _erreur = null);
    if (!_cle.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      final (message, _) =
          await ref.read(etudiantRepositoryProvider).declarerVersement(
                compte: _compte!,
                montant: _normaliser(_montant.text),
                dateOperation: _date!,
                referenceOperation: _reference.text.trim(),
                recu: _recu!,
                tranche: _tranche,
                commentaire: _commentaire.text.trim(),
              );
      if (mounted) Navigator.of(context).pop(message);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e;
        _envoi = false;
      });
      _cle.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final etat = widget.etat;
    final plafond = etat.montantDeclarable;
    final erreur = _erreur;
    final trancheChoisie = etat.tranchesOuvertes
        .where((tr) => tr.id == _tranche)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(t.declarerUnVersement)),
      body: Form(
        key: _cle,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Encadre(texte: t.versementExplication),
            if (erreur != null) ...[
              const SizedBox(height: 16),
              BandeauErreurs(messages: erreursGlobales(erreur, _champs)),
            ],
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              initialValue: _compte,
              isExpanded: true,
              decoration: InputDecoration(labelText: t.compteCredite),
              items: [
                for (final c in etat.comptes)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.banque} · ${c.numero}',
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
              validator: (v) =>
                  erreur?.erreurDuChamp('compte') ??
                  (v == null ? t.choisirCompte : null),
              onChanged: _envoi ? null : (v) => setState(() => _compte = v),
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
                for (final tr in etat.tranchesOuvertes)
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
              onChanged: _envoi ? null : (v) => setState(() => _tranche = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _montant,
              enabled: !_envoi,
              keyboardType: const TextInputType.numberWithOptions(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
              ],
              decoration: InputDecoration(
                labelText: t.montantVerse,
                suffixText: 'FCFA',
                helperText: plafond == null
                    ? null
                    : t.auPlus(Formats.montant(plafond, langue)),
                suffixIcon: trancheChoisie == null
                    ? null
                    : TextButton(
                        onPressed: _envoi
                            ? null
                            : () => _montant.text =
                                trancheChoisie.resteAPayer.round().toString(),
                        child: Text(t.laTranche),
                      ),
              ),
              validator: (v) {
                final serveur = erreur?.erreurDuChamp('montant');
                if (serveur != null) return serveur;
                final montant = double.tryParse(_normaliser(v ?? ''));
                if (montant == null || montant <= 0) return t.montantInvalide;
                if (plafond != null && montant > plafond) {
                  return t.auPlus(Formats.montant(plafond, langue));
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FormField<DateTime>(
              validator: (_) =>
                  erreur?.erreurDuChamp('date_operation') ??
                  (_date == null ? t.dateRequise : null),
              builder: (champ) => InkWell(
                onTap: _envoi ? null : _choisirDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: t.dateDuVersement,
                    errorText: champ.errorText,
                    suffixIcon: const Icon(Icons.calendar_month_outlined),
                  ),
                  child: Text(
                    _date == null ? '' : Formats.dateLongue(_date, langue),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reference,
              enabled: !_envoi,
              decoration: InputDecoration(
                labelText: t.referenceOperation,
                hintText: t.referenceOperationAide,
              ),
              validator: (v) =>
                  erreur?.erreurDuChamp('reference_operation') ??
                  ((v ?? '').trim().isEmpty ? t.referenceRequise : null),
            ),
            const SizedBox(height: 16),
            FormField<PieceAJoindre>(
              validator: (_) =>
                  erreur?.erreurDuChamp('piece') ??
                  (_recu == null ? t.recuRequis : null),
              builder: (champ) => ChampPieceJointe(
                libelle: t.recuDeLaBanque,
                aide: t.formatsRecu,
                erreur: champ.errorText,
                piece: _recu,
                actif: !_envoi,
                extensions: _extensionsRecu,
                surChoix: (p) {
                  setState(() => _recu = p);
                  champ.didChange(p);
                },
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commentaire,
              enabled: !_envoi,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: t.commentaireFacultatif,
                errorText: erreur?.erreurDuChamp('commentaire'),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _envoi ? null : _envoyer,
              icon: _envoi
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(t.declarerLeVersement),
            ),
          ],
        ),
      ),
    );
  }
}
