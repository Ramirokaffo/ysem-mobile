import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/models/devoirs.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/formulaire.dart';
import '../../../commun/langue.dart';
import '../../../commun/piece_jointe.dart';
import '../../../commun/telechargement.dart';

final _preparationProvider =
    FutureProvider.autoDispose.family<PreparationDevoir, String>(
  (ref, cle) => ref.watch(enseignantRepositoryProvider).preparationDevoir(cle),
);

/// Donner un devoir à une classe, ou le modifier ([devoir]). La date limite
/// est **proposée** par le serveur — le début de la prochaine séance — et les
/// prochaines séances sont offertes en raccourcis. Rend l'identifiant du
/// devoir enregistré.
class FormulaireDevoirPage extends ConsumerStatefulWidget {
  const FormulaireDevoirPage({
    super.key,
    required this.classe,
    this.devoir,
    this.fige = false,
    this.limites = const LimitesPieces(),
  });

  final ClasseDevoir classe;
  final DevoirComplet? devoir;
  final bool fige;
  final LimitesPieces limites;

  @override
  ConsumerState<FormulaireDevoirPage> createState() => _FormulaireDevoirPageState();
}

class _FormulaireDevoirPageState extends ConsumerState<FormulaireDevoirPage> {
  static const _champs = {'titre', 'consignes', 'date_limite', 'mode', 'groupement', 'note_sur'};

  final _cle = GlobalKey<FormState>();
  late final _titre = TextEditingController(text: widget.devoir?.devoir.titre ?? '');
  late final _consignes = TextEditingController(text: widget.devoir?.devoir.consignes ?? '');
  late final _noteSur = TextEditingController(
      text: widget.devoir?.devoir.noteSur?.toStringAsFixed(0) ?? '20');
  final Map<int, TextEditingController> _sujets = {};
  DateTime? _dateLimite;
  late String _mode = widget.devoir?.devoir.mode ?? 'individuel';
  late int? _groupement = widget.devoir?.devoir.groupementId;
  late Set<int> _groupes = {
    for (final ligne in widget.devoir?.lignes ?? const <LigneCorrection>[])
      if (ligne.groupe != null) ligne.groupe!.id,
  };
  late bool _noter = widget.devoir?.devoir.estNote ?? false;
  List<PieceAJoindre> _pieces = const [];

  /// Pièces des consignes déjà enregistrées (modification) : chacune se
  /// retire à part, sans attendre « Enregistrer ».
  late List<PieceDevoir> _jointes = [...?widget.devoir?.devoir.pieces];
  bool _retrait = false;
  bool _envoi = false;
  ApiException? _erreur;

  @override
  void initState() {
    super.initState();
    _dateLimite = widget.devoir?.devoir.dateLimite?.toLocal();
    for (final ligne in widget.devoir?.lignes ?? const <LigneCorrection>[]) {
      if (ligne.groupe != null) {
        _sujets[ligne.groupe!.id] = TextEditingController(text: ligne.sujet);
      }
    }
  }

  @override
  void dispose() {
    _titre.dispose();
    _consignes.dispose();
    _noteSur.dispose();
    for (final controleur in _sujets.values) {
      controleur.dispose();
    }
    super.dispose();
  }

  TextEditingController _sujet(int groupe) =>
      _sujets.putIfAbsent(groupe, TextEditingController.new);

  Future<void> _choisirDate(BuildContext context) async {
    final depart = _dateLimite ?? DateTime.now().add(const Duration(days: 7));
    final jour = await showDatePicker(
      context: context,
      initialDate: depart,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (jour == null || !context.mounted) return;
    final heure = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(depart));
    if (heure == null) return;
    setState(() => _dateLimite = DateTime(jour.year, jour.month, jour.day, heure.hour, heure.minute));
  }

  Future<void> _retirerJointe(PieceDevoir piece) async {
    final t = AppLocalizations.of(context);
    final messager = ScaffoldMessenger.of(context);
    final ok = await confirmer(
      context,
      titre: t.retirer,
      texte: t.devoirPieceRetirerConfirmer(piece.nom),
      action: t.retirer,
    );
    if (!ok) return;
    setState(() => _retrait = true);
    try {
      await ref.read(enseignantRepositoryProvider).retirerPieceDevoir(piece.id);
      if (!mounted) return;
      setState(() => _jointes = [for (final p in _jointes) if (p.id != piece.id) p]);
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _retrait = false);
    }
  }

  Map<String, dynamic> _corps({required bool publier}) => {
        if (widget.devoir == null) 'classe': widget.classe.cle,
        'titre': _titre.text.trim(),
        'consignes': _consignes.text.trim(),
        'date_limite': _dateLimite == null ? '' : DateFormat("yyyy-MM-dd'T'HH:mm").format(_dateLimite!),
        'mode': _mode,
        'groupement': _mode == 'groupe' ? (_groupement ?? '') : '',
        'groupes': _mode == 'groupe' ? _groupes.toList() : <int>[],
        'sujets': {
          if (_mode == 'groupe')
            for (final MapEntry(key: groupe, value: controleur) in _sujets.entries)
              '$groupe': controleur.text.trim(),
        },
        'noter': _noter,
        'note_sur': _noter ? _noteSur.text.trim() : '',
        if (publier) 'publier': true,
      };

  Future<void> _envoyer({required bool publier}) async {
    setState(() => _erreur = null);
    if (!_cle.currentState!.validate()) return;
    setState(() => _envoi = true);
    final depot = ref.read(enseignantRepositoryProvider);
    try {
      final DevoirComplet resultat;
      if (widget.devoir == null) {
        resultat = await depot.creerDevoir(_corps(publier: publier), pieces: _pieces);
      } else {
        resultat = await depot.modifierDevoir(widget.devoir!.devoir.id, _corps(publier: false),
            pieces: _pieces);
      }
      if (!mounted) return;
      if (resultat.avertissement != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(resultat.avertissement!)));
      }
      Navigator.of(context).pop(resultat.devoir.id);
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
    final langue = langueCourante(context);
    final preparation = ref.watch(_preparationProvider(widget.classe.cle));
    final etat = preparation.valueOrNull;
    if (_dateLimite == null && etat?.dateProposee != null) {
      _dateLimite = etat!.dateProposee!.toLocal();
    }
    final groupements = etat?.groupements ?? const <Groupement>[];
    final groupement = groupements.where((g) => g.id == _groupement).firstOrNull;
    final erreur = _erreur;
    final dejaJointes = _jointes.length;
    final restant = (widget.limites.maximum - dejaJointes).clamp(0, widget.limites.maximum);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.devoir == null ? t.devoirsDonner : t.modifier),
      ),
      body: Form(
        key: _cle,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(widget.classe.libelle, style: Theme.of(context).textTheme.bodySmall),
            EmplacementErreurs(
              messages: erreur == null ? null : erreursGlobales(erreur, _champs),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titre,
              enabled: !_envoi,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: t.devoirTitre),
              validator: (v) =>
                  _erreur?.erreurDuChamp('titre') ??
                  ((v ?? '').trim().isEmpty ? t.devoirTitreRequis : null),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _consignes,
              enabled: !_envoi,
              minLines: 3,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.devoirConsignesFacultatives,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Text(t.devoirDateLimite, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: _envoi ? null : () => _choisirDate(context),
              icon: const Icon(Icons.event_rounded),
              label: Text(_dateLimite == null ? '—' : Formats.horodatage(_dateLimite, langue)),
            ),
            if (_erreur?.erreurDuChamp('date_limite') != null)
              Text(_erreur!.erreurDuChamp('date_limite')!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (etat != null && etat.seances.isEmpty)
              Text(t.devoirAucuneSeance, style: Theme.of(context).textTheme.bodySmall),
            if (etat != null && etat.seances.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(t.devoirProchainesSeances, style: Theme.of(context).textTheme.bodySmall),
              Wrap(
                spacing: 8,
                children: [
                  for (final seance in etat.seances)
                    ChoiceChip(
                      label: Text(
                        '${Formats.horodatage(seance.debut, langue)}'
                        '${seance.rattrapage ? ' · ${t.devoirRattrapage}' : ''}',
                      ),
                      selected: _dateLimite != null &&
                          _dateLimite!.isAtSameMomentAs(seance.debut.toLocal()),
                      onSelected: _envoi
                          ? null
                          : (_) => setState(() => _dateLimite = seance.debut.toLocal()),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (widget.fige)
              Encadre(texte: t.devoirFige, icone: Icons.lock_outline_rounded),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'individuel', label: Text(t.devoirModeIndividuel),
                    icon: const Icon(Icons.person_outline_rounded)),
                ButtonSegment(value: 'groupe', label: Text(t.devoirModeGroupe),
                    icon: const Icon(Icons.groups_outlined)),
              ],
              selected: {_mode},
              onSelectionChanged: _envoi || widget.fige
                  ? null
                  : (choix) => setState(() => _mode = choix.first),
            ),
            if (_mode == 'groupe') ...[
              const SizedBox(height: 12),
              if (groupements.isEmpty)
                Encadre(texte: t.devoirAucunGroupement)
              else ...[
                DropdownButtonFormField<int>(
                  key: ValueKey('groupement-${groupements.length}'),
                  initialValue: groupement?.id,
                  decoration: InputDecoration(labelText: t.devoirGroupement),
                  items: [
                    for (final g in groupements)
                      DropdownMenuItem(value: g.id, child: Text(g.nom)),
                  ],
                  onChanged: _envoi || widget.fige
                      ? null
                      : (id) => setState(() {
                            _groupement = id;
                            _groupes = {};
                          }),
                  validator: (v) =>
                      _erreur?.erreurDuChamp('groupement') ?? (v == null ? t.devoirGroupement : null),
                ),
                if (groupement != null) ...[
                  const SizedBox(height: 8),
                  Text(t.devoirGroupesConcernes, style: Theme.of(context).textTheme.bodySmall),
                  for (final groupe in groupement.groupes) ...[
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _groupes.contains(groupe.id),
                      onChanged: _envoi || widget.fige
                          ? null
                          : (coche) => setState(() {
                                coche == true ? _groupes.add(groupe.id) : _groupes.remove(groupe.id);
                              }),
                      title: Text(groupe.nom),
                      subtitle: Text(
                        groupe.membres.isEmpty
                            ? t.groupeAucunMembre
                            : groupe.membres.map((m) => m.nom).join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextFormField(
                      controller: _sujet(groupe.id),
                      enabled: !_envoi,
                      decoration: InputDecoration(
                        labelText: t.devoirSujetFacultatif,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            ],
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _noter,
              onChanged: _envoi ? null : (v) => setState(() => _noter = v),
              title: Text(t.devoirNoter),
            ),
            if (_noter)
              TextFormField(
                controller: _noteSur,
                enabled: !_envoi,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: t.devoirNoteSurChamp),
                validator: (v) => _erreur?.erreurDuChamp('note_sur'),
              ),
            const SizedBox(height: 16),
            if (_jointes.isNotEmpty) ...[
              Text(t.devoirPiecesDejaJointes, style: Theme.of(context).textTheme.labelLarge),
              for (final piece in _jointes)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(iconeDeFichier(piece.nom)),
                  title: Text(piece.nom, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: piece.tailleLisible.isEmpty ? null : Text(piece.tailleLisible),
                  onTap: () => telechargerEtOuvrir(
                      context, () => ref.read(enseignantRepositoryProvider).pieceDevoir(piece)),
                  trailing: IconButton(
                    tooltip: t.retirer,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _envoi || _retrait ? null : () => _retirerJointe(piece),
                  ),
                ),
              const SizedBox(height: 8),
            ],
            ChampPiecesJointes(
              libelle: t.devoirPieces,
              pieces: _pieces,
              maximum: restant,
              actif: !_envoi && restant > 0,
              extensions: widget.limites.extensions.isEmpty
                  ? extensionsPieces
                  : widget.limites.extensions,
              aide: t.piecesAuPlus(widget.limites.maximum),
              surChangement: (pieces) => setState(() => _pieces = pieces),
            ),
            const SizedBox(height: 24),
            if (widget.devoir == null) ...[
              OutlinedButton.icon(
                onPressed: _envoi ? null : () => _envoyer(publier: false),
                icon: const Icon(Icons.save_outlined),
                label: Text(t.devoirBrouillon),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _envoi ? null : () => _envoyer(publier: true),
                icon: const Icon(Icons.send_rounded),
                label: Text(t.devoirPublier),
              ),
            ] else
              FilledButton.icon(
                onPressed: _envoi ? null : () => _envoyer(publier: false),
                icon: const Icon(Icons.save_rounded),
                label: Text(t.enregistrer),
              ),
          ],
        ),
      ),
    );
  }
}
