import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/models/champs.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/formulaire.dart';
import '../../../commun/langue.dart';
import '../../application/lectures.dart';
import '../../domain/feuilles.dart';
import 'grille_notes.dart';

/// La saisie d'une épreuve anonyme : une ligne par code, sans nom ni matricule.
/// La correspondance n'est connue que du service, et le serveur ne l'envoie pas.
class CopiesPage extends ConsumerStatefulWidget {
  const CopiesPage({
    super.key,
    required this.feuille,
    required this.epreuve,
    required this.statuts,
    required this.noteMax,
  });

  final int feuille;
  final EpreuveFeuille epreuve;
  final List<OptionChamp> statuts;
  final double noteMax;

  @override
  ConsumerState<CopiesPage> createState() => _CopiesPageState();
}

class _CopiesPageState extends ConsumerState<CopiesPage> {
  final _grille = GlobalKey<GrilleNotesState>();
  bool _rendu = false;

  void _relireFeuille() {
    ref.invalidate(detailFeuilleProvider(widget.feuille));
    ref.invalidate(feuillesDeNotesProvider);
  }

  Future<void> _rendre(
    List<NoteAEnvoyer> Function() modifications,
    bool Function() valider,
    void Function(ApiException) surErreur,
  ) async {
    if (!valider()) return;
    final t = AppLocalizations.of(context);
    final messager = ScaffoldMessenger.of(context);
    final navigateur = Navigator.of(context);
    final ok = await confirmer(
      context,
      titre: t.rendreLesNotes(widget.epreuve.typeLibelle),
      texte: t.rendreEpreuveConfirmation,
      action: t.rendre,
    );
    if (!ok || !mounted) return;
    setState(() => _rendu = true);
    try {
      final message = await ref.read(enseignantRepositoryProvider).rendreEpreuve(
            widget.feuille,
            widget.epreuve.type,
            modifications(),
          );
      _relireFeuille();
      ref.read(menuEnseignantProvider.notifier).rafraichir();
      messager.showSnackBar(SnackBar(content: Text(message)));
      navigateur.pop();
    } on ApiException catch (e) {
      // Les notes ont pu être enregistrées avant le refus de rendre : la fiche
      // est relue, la saisie reste à l'écran.
      _relireFeuille();
      if (mounted) surErreur(e);
    } finally {
      if (mounted) setState(() => _rendu = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final e = widget.epreuve;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (aQuitte, _) async {
        if (aQuitte) return;
        final navigateur = Navigator.of(context);
        final modifie = _grille.currentState?.aDesModifications ?? false;
        if (!modifie || await confirmerAbandon(context)) navigateur.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(e.typeLibelle)),
        body: GrilleNotes(
          key: _grille,
          anonyme: true,
          lignes: e.copies,
          statuts: widget.statuts,
          noteMax: widget.noteMax,
          modifiable: e.saisissable,
          surEnregistrer: (notes) async {
            final resultat = await ref
                .read(enseignantRepositoryProvider)
                .enregistrerCopies(widget.feuille, e.type, notes);
            _relireFeuille();
            return resultat;
          },
          actionPied: (context, modifications, valider, surErreur) =>
              FilledButton.icon(
            onPressed: _rendu
                ? null
                : () => _rendre(modifications, valider, surErreur),
            icon: _rendu
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(t.rendreLesNotes(e.typeLibelle)),
          ),
          enTete: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Encadre(
                texte: t.saisieParCodeExplication,
                icone: Icons.lock_person_outlined,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                [
                  if (e.dateLimite != null)
                    t.aRendreAvant(Formats.dateLongue(e.dateLimite, langue)),
                  t.notesSur(Formats.coefficient(widget.noteMax, langue)),
                ].join(' · '),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
