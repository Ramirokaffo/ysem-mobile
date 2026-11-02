import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/format/formats.dart';
import '../../../../core/models/champs.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/formulaire.dart';
import '../../../commun/langue.dart';
import '../../domain/feuilles.dart';

/// Ce qu'une grille sait faire : enregistrer, et rendre pour une épreuve.
typedef EnvoiGrille = Future<(String, List<LigneNote>)> Function(
    List<NoteAEnvoyer> notes);

/// La grille de saisie, commune à un contrôle continu (en clair) et à une
/// épreuve anonyme (par code) : il n'y a pas deux façons de noter selon ce
/// qu'on note.
///
/// **Une case vide n'est pas un zéro** : sans note, c'est le statut qui dit
/// pourquoi. La saisie tient les deux ensemble — une note posée vaut « note
/// saisie », choisir une absence vide la case —, ce que le serveur exigerait
/// de toute façon (`notes.forms.RegleCaseMixin`) et qu'il vérifie encore.
class GrilleNotes extends StatefulWidget {
  const GrilleNotes({
    super.key,
    required this.lignes,
    required this.statuts,
    required this.noteMax,
    required this.modifiable,
    required this.surEnregistrer,
    this.anonyme = false,
    this.enTete = const [],
    this.actionPied,
  });

  final List<LigneNote> lignes;
  final List<OptionChamp> statuts;
  final double noteMax;
  final bool modifiable;
  final EnvoiGrille surEnregistrer;

  /// Recherche et libellés par code d'anonymat.
  final bool anonyme;

  /// Ce qui précède la grille dans la liste (consignes, compteurs).
  final List<Widget> enTete;

  /// Un second geste au pied (« Rendre »), à qui l'on remet les cases modifiées.
  final Widget Function(
    BuildContext context,
    List<NoteAEnvoyer> Function() modifications,
    bool Function() valider,
    void Function(ApiException erreur) surErreur,
  )? actionPied;

  @override
  State<GrilleNotes> createState() => GrilleNotesState();
}

class GrilleNotesState extends State<GrilleNotes> {
  late List<LigneNote> _lignes = widget.lignes;
  final _champs = <int, TextEditingController>{};
  final _statuts = <int, String>{};
  Map<int, Map<String, List<String>>> _erreurs = const {};
  ApiException? _erreurGlobale;
  String _recherche = '';
  bool _enCours = false;

  @override
  void dispose() {
    for (final champ in _champs.values) {
      champ.dispose();
    }
    super.dispose();
  }

  void _charger(List<LigneNote> lignes) {
    _lignes = lignes;
    for (final ligne in lignes) {
      final texte = ligne.valeur == null
          ? ''
          : Formats.coefficient(ligne.valeur!, _langue);
      (_champs[ligne.id] ??= TextEditingController()).text = texte;
      _statuts[ligne.id] = ligne.statut;
    }
  }

  /// La langue de l'interface, qui écrit les notes (`12,5` / `12.5`) : elle
  /// n'est lisible qu'une fois les dépendances disponibles, d'où le premier
  /// chargement ici plutôt que dans `initState`.
  String? _langueLue;
  String get _langue => _langueLue ?? 'fr';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final langue = langueCourante(context);
    if (langue == _langueLue) return;
    final premiere = _langueLue == null;
    _langueLue = langue;
    if (premiere) _charger(_lignes);
  }

  /// Un rafraîchissement apporte les valeurs du serveur, sans jamais écraser
  /// une saisie en cours.
  @override
  void didUpdateWidget(GrilleNotes ancien) {
    super.didUpdateWidget(ancien);
    if (!identical(ancien.lignes, widget.lignes) && !aDesModifications) {
      _charger(widget.lignes);
    }
  }

  double? _valeurDe(LigneNote ligne) =>
      lireNote(_champs[ligne.id]?.text ?? '');

  bool _caseVide(LigneNote ligne) =>
      (_champs[ligne.id]?.text ?? '').trim().isEmpty;

  bool _modifiee(LigneNote ligne) {
    final texte = _champs[ligne.id]?.text ?? '';
    final valeur = texte.trim().isEmpty ? null : lireNote(texte);
    if (texte.trim().isNotEmpty && valeur == null) return true;
    return valeur != ligne.valeur || _statuts[ligne.id] != ligne.statut;
  }

  /// Des cases diffèrent de ce que le serveur a enregistré.
  bool get aDesModifications => _lignes.any(_modifiee);

  /// Seules les cases touchées partent : une ligne absente garde sa valeur,
  /// et le service a pu en corriger une autre entre-temps.
  List<NoteAEnvoyer> modifications() => [
        for (final ligne in _lignes)
          if (_modifiee(ligne))
            NoteAEnvoyer(
              id: ligne.id,
              valeur:
                  _caseVide(ligne) ? null : _valeurDe(ligne)?.toString(),
              statut: _statuts[ligne.id] ?? ligne.statut,
            ),
      ];

  /// Contrôle de forme avant l'envoi ; le serveur reste juge du reste.
  bool valider() {
    final t = AppLocalizations.of(context);
    final erreurs = <int, Map<String, List<String>>>{};
    for (final ligne in _lignes) {
      if (_caseVide(ligne)) continue;
      final valeur = _valeurDe(ligne);
      if (valeur == null) {
        erreurs[ligne.id] = {
          'valeur': [t.noteInvalide],
        };
      } else if (valeur > widget.noteMax) {
        erreurs[ligne.id] = {
          'valeur': [t.noteTropHaute(Formats.coefficient(widget.noteMax, _langue))],
        };
      }
    }
    setState(() {
      _erreurs = erreurs;
      _erreurGlobale = null;
      if (erreurs.isNotEmpty) _recherche = '';
    });
    return erreurs.isEmpty;
  }

  /// Rapporte un refus du serveur : les erreurs viennent dans l'ordre de la
  /// grille, la saisie reste à l'écran.
  void signalerErreur(ApiException erreur) {
    final lignes = erreursDesLignes(erreur.donnees);
    setState(() {
      _erreurGlobale = erreur;
      _erreurs = {
        for (final (i, messages) in lignes.indexed)
          if (i < _lignes.length && messages.isNotEmpty)
            _lignes[i].id: messages,
      };
      if (_erreurs.isNotEmpty) _recherche = '';
    });
  }

  Future<void> _enregistrer() async {
    if (!valider()) return;
    final notes = modifications();
    final t = AppLocalizations.of(context);
    final messager = ScaffoldMessenger.of(context);
    if (notes.isEmpty) {
      messager.showSnackBar(SnackBar(content: Text(t.aucuneModification)));
      return;
    }
    setState(() => _enCours = true);
    try {
      final (message, lignes) = await widget.surEnregistrer(notes);
      messager.showSnackBar(SnackBar(content: Text(message)));
      if (mounted) setState(() => _charger(lignes));
    } on ApiException catch (e) {
      if (mounted) signalerErreur(e);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  /// La case et le statut se tiennent : une note posée vaut « note saisie »,
  /// une case vidée redevient attendue.
  void _surNote(LigneNote ligne, String texte) {
    setState(() {
      _erreurs = {..._erreurs}..remove(ligne.id);
      if (texte.trim().isNotEmpty) {
        _statuts[ligne.id] = StatutsNote.saisie;
      } else if (_statuts[ligne.id] == StatutsNote.saisie) {
        _statuts[ligne.id] = StatutsNote.attendue;
      }
    });
  }

  void _surStatut(LigneNote ligne, String? statut) {
    if (statut == null) return;
    setState(() {
      _statuts[ligne.id] = statut;
      _champs[ligne.id]?.clear();
      _erreurs = {..._erreurs}..remove(ligne.id);
    });
  }

  bool _retenue(LigneNote ligne) {
    final q = _recherche.trim().toLowerCase();
    if (q.isEmpty) return true;
    return ligne.titre.toLowerCase().contains(q) ||
        ligne.sousTitre.toLowerCase().contains(q);
  }

  /// Cases encore attendues à l'écran : ni note, ni statut qui l'explique.
  int get _manquantes => _lignes
      .where((l) => _caseVide(l) && _statuts[l.id] == StatutsNote.attendue)
      .length;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final visibles = _lignes.where(_retenue).toList();
    final erreur = _erreurGlobale;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: widget.enTete.length + 1 + visibles.length,
            itemBuilder: (context, i) {
              if (i < widget.enTete.length) return widget.enTete[i];
              if (i == widget.enTete.length) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (erreur != null) ...[
                        BandeauErreurs(messages: [
                          erreur.message,
                          ...erreursDeLEnsemble(erreur.donnees),
                        ]),
                        const SizedBox(height: 8),
                      ],
                      if (_lignes.length > 8)
                        TextField(
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: widget.anonyme
                                ? t.rechercherCode
                                : t.rechercherEtudiant,
                            prefixIcon: const Icon(Icons.search_rounded),
                          ),
                          onChanged: (v) => setState(() => _recherche = v),
                        ),
                      if (_lignes.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text(
                            widget.anonyme
                                ? t.aucuneCopieCodee
                                : t.aucunEtudiantSurFeuille,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ),
                );
              }
              final ligne = visibles[i - widget.enTete.length - 1];
              return _LigneGrille(
                key: ValueKey(ligne.id),
                ligne: ligne,
                champ: _champs[ligne.id]!,
                statut: _statuts[ligne.id] ?? ligne.statut,
                statuts: widget.statuts,
                actif: widget.modifiable && !_enCours,
                erreurs: _erreurs[ligne.id] ?? const {},
                surNote: (v) => _surNote(ligne, v),
                surStatut: (v) => _surStatut(ligne, v),
              );
            },
          ),
        ),
        if (widget.modifiable && _lignes.isNotEmpty)
          Material(
            elevation: 6,
            color: theme.colorScheme.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _manquantes == 0
                          ? t.saisieComplete
                          : t.notesEncoreAttendues(_manquantes),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: _enCours ? null : _enregistrer,
                      icon: _enCours
                          ? const SizedBox.square(
                              dimension: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(widget.actionPied == null
                          ? t.enregistrerLesNotes
                          : t.enregistrerSansRendre),
                    ),
                    if (widget.actionPied != null) ...[
                      const SizedBox(height: 8),
                      widget.actionPied!(
                          context, modifications, valider, signalerErreur),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LigneGrille extends StatelessWidget {
  const _LigneGrille({
    super.key,
    required this.ligne,
    required this.champ,
    required this.statut,
    required this.statuts,
    required this.actif,
    required this.erreurs,
    required this.surNote,
    required this.surStatut,
  });

  final LigneNote ligne;
  final TextEditingController champ;
  final String statut;
  final List<OptionChamp> statuts;
  final bool actif;
  final Map<String, List<String>> erreurs;
  final ValueChanged<String> surNote;
  final ValueChanged<String?> surStatut;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final aUneNote = champ.text.trim().isNotEmpty;
    // « Note saisie » se constate, il ne se choisit pas : sans note, le
    // serveur le refuserait. Vide, la case propose ce qui explique le manque.
    final options = statuts.where((s) => s.valeur != StatutsNote.saisie).toList();
    final erreurStatut = erreurs['statut']?.join(' ');
    final erreurValeur = erreurs['valeur']?.join(' ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ligne.titre,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        if (ligne.sousTitre.isNotEmpty)
                          Text(ligne.sousTitre,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        if (aUneNote)
                          Text(
                              statuts
                                      .where((s) => s.valeur == statut)
                                      .firstOrNull
                                      ?.libelle ??
                                  t.noteSaisie,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant))
                        else
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: options.any((s) => s.valeur == statut)
                                  ? statut
                                  : null,
                              isDense: true,
                              isExpanded: true,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface),
                              items: [
                                for (final s in options)
                                  DropdownMenuItem(
                                    value: s.valeur,
                                    child: Text(s.libelle,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                              ],
                              onChanged: actif ? surStatut : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 84,
                    child: TextField(
                      controller: champ,
                      enabled: actif,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '—',
                        error: erreurValeur == null
                            ? null
                            : const SizedBox.shrink(),
                      ),
                      onChanged: surNote,
                    ),
                  ),
                ],
              ),
              for (final message in [?erreurValeur, ?erreurStatut])
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(message,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avant de quitter une grille où des notes n'ont pas été enregistrées.
Future<bool> confirmerAbandon(BuildContext context) {
  final t = AppLocalizations.of(context);
  return confirmer(
    context,
    titre: t.notesNonEnregistrees,
    texte: t.notesNonEnregistreesTexte,
    action: t.quitterSansEnregistrer,
  );
}
