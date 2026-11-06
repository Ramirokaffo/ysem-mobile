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

/// Dépôt d'une demande de moratoire pour l'année active. Les contrôles sont
/// ceux du formulaire du portail, rejoués par le serveur (montant plafonné au
/// reste dû, date à venir, une seule demande en instruction) ; l'écran n'en
/// devance que les plus simples. Rend le message du serveur au retour.
class NouvelleDemandeMoratoirePage extends ConsumerStatefulWidget {
  const NouvelleDemandeMoratoirePage({
    super.key,
    required this.montantDemandable,
    required this.annee,
  });

  final double? montantDemandable;
  final String annee;

  @override
  ConsumerState<NouvelleDemandeMoratoirePage> createState() =>
      _NouvelleDemandeMoratoirePageState();
}

class _NouvelleDemandeMoratoirePageState
    extends ConsumerState<NouvelleDemandeMoratoirePage> {
  static const _champs = {'amount', 'requested_due_date', 'reason', 'attachment'};

  final _cle = GlobalKey<FormState>();
  final _montant = TextEditingController();
  final _motif = TextEditingController();
  DateTime? _date;
  PieceAJoindre? _piece;
  bool _envoi = false;
  ApiException? _erreur;

  @override
  void dispose() {
    _montant.dispose();
    _motif.dispose();
    super.dispose();
  }

  /// `125 000`, `125000,50` → `125000.50`, l'écriture que le serveur lit.
  static String _normaliser(String saisie) =>
      saisie.replaceAll(RegExp(r'[\s  ]'), '').replaceAll(',', '.');

  Future<void> _choisirDate() async {
    final demain = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
    final choisie = await showDatePicker(
      context: context,
      initialDate: _date ?? demain,
      firstDate: demain,
      lastDate: demain.add(const Duration(days: 366)),
    );
    if (choisie != null) setState(() => _date = choisie);
  }

  Future<void> _envoyer() async {
    setState(() => _erreur = null);
    if (!_cle.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      final (message, _) =
          await ref.read(etudiantRepositoryProvider).deposerMoratoire(
                montant: _normaliser(_montant.text),
                dateSouhaitee: _date!,
                motif: _motif.text.trim(),
                piece: _piece,
              );
      if (mounted) Navigator.of(context).pop(message);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e;
        _envoi = false;
      });
      // Les validateurs lisent `_erreur` et non une copie du dernier build :
      // `validate()` part avant la reconstruction.
      _cle.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final plafond = widget.montantDemandable;
    final erreur = _erreur;

    return Scaffold(
      appBar: AppBar(title: Text(t.nouvelleDemandeMoratoire)),
      body: Form(
        key: _cle,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Encadre(texte: t.moratoireExplication),
            EmplacementErreurs(
              messages: erreur == null ? null : erreursGlobales(erreur, _champs),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _montant,
              enabled: !_envoi,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9 ,.]')),
              ],
              decoration: InputDecoration(
                labelText: t.montantSollicite,
                suffixText: 'FCFA',
                helperText: plafond == null
                    ? null
                    : t.auPlus(Formats.montant(plafond, langue)),
                suffixIcon: plafond == null || plafond <= 0
                    ? null
                    : TextButton(
                        onPressed: _envoi
                            ? null
                            : () => _montant.text = plafond
                                .toStringAsFixed(plafond % 1 == 0 ? 0 : 2),
                        child: Text(t.tout),
                      ),
              ),
              validator: (v) {
                final serveur = _erreur?.erreurDuChamp('amount');
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
                  _erreur?.erreurDuChamp('requested_due_date') ??
                  (_date == null ? t.dateRequise : null),
              builder: (champ) => InkWell(
                onTap: _envoi ? null : _choisirDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: t.dateReglementSouhaitee,
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
              controller: _motif,
              enabled: !_envoi,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.motifDeLaDemande,
                hintText: t.motifMoratoireAide,
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  _erreur?.erreurDuChamp('reason') ??
                  ((v ?? '').trim().isEmpty ? t.motifRequis : null),
            ),
            const SizedBox(height: 16),
            ChampPieceJointe(
              libelle: t.pieceJustificativeFacultative,
              aide: t.formatsPieces,
              erreur: erreur?.erreurDuChamp('attachment'),
              piece: _piece,
              actif: !_envoi,
              surChoix: (p) => setState(() => _piece = p),
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
              label: Text(t.envoyerDemande),
            ),
          ],
        ),
      ),
    );
  }
}
