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
import '../../domain/feuilles.dart';
import 'grille_notes.dart';

/// Les notes d'un contrôle continu, en clair : la liste d'appel de l'enseignant,
/// dans l'ordre alphabétique. Elles se modifient tant que le contrôle continu
/// n'a pas été rendu.
class ControlePage extends ConsumerStatefulWidget {
  const ControlePage({super.key, required this.feuille, required this.controle});

  final int feuille;
  final int controle;

  @override
  ConsumerState<ControlePage> createState() => _ControlePageState();
}

class _ControlePageState extends ConsumerState<ControlePage> {
  final _grille = GlobalKey<GrilleNotesState>();

  (int, int) get _cle => (widget.feuille, widget.controle);

  void _relireFeuille() {
    ref.invalidate(detailFeuilleProvider(widget.feuille));
    ref.invalidate(feuillesDeNotesProvider);
  }

  Future<void> _supprimer(DetailControle detail) async {
    final t = AppLocalizations.of(context);
    final messager = ScaffoldMessenger.of(context);
    final navigateur = Navigator.of(context);
    final ok = await confirmer(
      context,
      titre: t.supprimerControle,
      texte: t.supprimerControleConfirmation(detail.controle.libelle),
      action: t.supprimer,
    );
    if (!ok) return;
    try {
      await ref
          .read(enseignantRepositoryProvider)
          .supprimerControle(widget.feuille, widget.controle);
      _relireFeuille();
      navigateur.pop();
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final valeur = ref.watch(detailControleProvider(_cle));
    final detail = valeur.valueOrNull;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (aQuitte, _) async {
        if (aQuitte) return;
        final navigateur = Navigator.of(context);
        final modifie = _grille.currentState?.aDesModifications ?? false;
        if (!modifie || await confirmerAbandon(context)) navigateur.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(detail?.controle.libelle ?? t.chargement),
          actions: [
            if (detail?.modifiable == true)
              IconButton(
                tooltip: t.supprimerControle,
                onPressed: () => _supprimer(detail!),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
        body: VueAsynchrone<DetailControle>(
          valeur: valeur,
          surRafraichir: () => ref.refresh(detailControleProvider(_cle).future),
          constructeur: (d) => GrilleNotes(
            key: _grille,
            lignes: d.notes,
            statuts: d.statutsDeNote,
            noteMax: d.noteMax,
            modifiable: d.modifiable,
            surEnregistrer: (notes) async {
              final resultat = await ref
                  .read(enseignantRepositoryProvider)
                  .enregistrerNotesControle(
                      widget.feuille, widget.controle, notes);
              _relireFeuille();
              return resultat;
            },
            enTete: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  [
                    Formats.dateLongue(d.controle.date, langue),
                    if (d.controle.ponderation != null)
                      t.ponderationDe(
                          Formats.coefficient(d.controle.ponderation!, langue)),
                    t.notesSur(Formats.coefficient(d.noteMax, langue)),
                  ].where((s) => s.isNotEmpty).join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              if (!d.modifiable)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Encadre(
                    texte: t.controleContinuRenduLecture,
                    icone: Icons.lock_outline_rounded,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
