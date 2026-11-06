import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/formulaire.dart';
import '../../../commun/piece_jointe.dart';

/// Dépôt d'une suggestion. La solution proposée est exigée en plus du texte :
/// c'est ce qui distingue une suggestion d'une doléance. Rend le message du
/// serveur au retour.
class NouvelleSuggestionPage extends ConsumerStatefulWidget {
  const NouvelleSuggestionPage({
    super.key,
    required this.preuvesMax,
    required this.champPreuves,
    this.anonymat = '',
  });

  final int preuvesMax;
  final String champPreuves;
  final String anonymat;

  @override
  ConsumerState<NouvelleSuggestionPage> createState() =>
      _NouvelleSuggestionPageState();
}

class _NouvelleSuggestionPageState
    extends ConsumerState<NouvelleSuggestionPage> {
  static const _champs = {'texte', 'solution_proposee'};

  final _cle = GlobalKey<FormState>();
  final _texte = TextEditingController();
  final _solution = TextEditingController();
  List<PieceAJoindre> _preuves = const [];
  bool _envoi = false;
  ApiException? _erreur;

  @override
  void dispose() {
    _texte.dispose();
    _solution.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    setState(() => _erreur = null);
    if (!_cle.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      final message =
          await ref.read(etudiantRepositoryProvider).deposerSuggestion(
                texte: _texte.text.trim(),
                solution: _solution.text.trim(),
                preuves: _preuves,
                champPreuves: widget.champPreuves,
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
    final erreur = _erreur;

    return Scaffold(
      appBar: AppBar(title: Text(t.nouvelleSuggestion)),
      body: Form(
        key: _cle,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Encadre(
              icone: Icons.visibility_off_outlined,
              texte: widget.anonymat.isEmpty
                  ? t.suggestionExplication
                  : widget.anonymat,
            ),
            EmplacementErreurs(
              messages: erreur == null ? null : erreursGlobales(erreur, _champs),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _texte,
              enabled: !_envoi,
              minLines: 4,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.votreSuggestion,
                hintText: t.votreSuggestionAide,
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  _erreur?.erreurDuChamp('texte') ??
                  ((v ?? '').trim().isEmpty ? t.suggestionRequise : null),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _solution,
              enabled: !_envoi,
              minLines: 3,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.solutionProposee,
                hintText: t.solutionProposeeAide,
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  _erreur?.erreurDuChamp('solution_proposee') ??
                  ((v ?? '').trim().isEmpty ? t.solutionRequise : null),
            ),
            const SizedBox(height: 16),
            ChampPiecesJointes(
              libelle: t.preuvesFacultatives,
              pieces: _preuves,
              maximum: widget.preuvesMax,
              actif: !_envoi,
              aide: '${t.piecesAuPlus(widget.preuvesMax)} ${t.formatsPieces}',
              surChangement: (pieces) => setState(() => _preuves = pieces),
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
              label: Text(t.deposerSuggestion),
            ),
          ],
        ),
      ),
    );
  }
}
