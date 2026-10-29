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
import '../../domain/planning.dart';

/// « Mes rattrapages » : les séances que l'enseignant doit rattraper.
///
/// Il peut **proposer** une date ; elle ne paraît nulle part — ni sur la
/// tournée, ni au portail étudiant — tant que le service ne l'a pas
/// approuvée. Une séance déjà programmée ne se déplace pas d'ici : les
/// étudiants en ont été prévenus, c'est au service de la renvoyer.
class RattrapagesPage extends ConsumerWidget {
  const RattrapagesPage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionRattrapages)),
      body: VueAsynchrone<Rattrapages>(
        valeur: ref.watch(rattrapagesProvider),
        surRafraichir: () => ref.refresh(rattrapagesProvider.future),
        constructeur: (donnees) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Encadre(
              texte: t.rattrapagesExplication,
              icone: Icons.info_outline_rounded,
            ),
            const SizedBox(height: 16),
            if (donnees.rattrapages.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: EtatVide(
                  message: t.aucunRattrapage,
                  icone: Icons.event_available_outlined,
                ),
              ),
            for (final r in donnees.enCours) ...[
              _CarteRattrapage(rattrapage: r, formulaire: donnees.formulaire),
              const SizedBox(height: 12),
            ],
            if (donnees.clos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(t.rattrapagesClos,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final r in donnees.clos) ...[
                _CarteRattrapage(rattrapage: r, formulaire: donnees.formulaire),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CarteRattrapage extends ConsumerWidget {
  const _CarteRattrapage({required this.rattrapage, required this.formulaire});

  final Rattrapage rattrapage;
  final DescriptionFormulaire formulaire;

  Future<void> _proposer(BuildContext context, WidgetRef ref) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _PropositionDate(rattrapage: rattrapage, formulaire: formulaire),
    );
    if (message == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    ref.invalidate(rattrapagesProvider);
    ref.read(menuEnseignantProvider.notifier).rafraichir();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final r = rattrapage;
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final cohorte =
        [r.niveau, r.classe].where((s) => s.isNotEmpty).join(' · ');

    // La date en jeu, et d'où elle vient.
    final date = r.datePrevue == null
        ? null
        : [
            Formats.jourLong(r.datePrevue, langue),
            Formats.plage(r.debut, r.fin),
            r.salle,
          ].where((s) => s.isNotEmpty).join(' · ');

    return CarteYsem(
      titre: r.cours,
      icone: Icons.replay_rounded,
      action: r.statutLibelle.isEmpty
          ? null
          : Pastille(r.statutLibelle, ton: _tonDuStatut(r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cohorte.isNotEmpty) Text(cohorte, style: secondaire),
          if (r.seanceManquee != null)
            Text(t.seanceDuJour(Formats.dateLongue(r.seanceManquee, langue)),
                style: secondaire),
          if (r.motif.isNotEmpty || r.origineLibelle.isNotEmpty)
            Text(r.motif.isNotEmpty ? r.motif : r.origineLibelle,
                style: secondaire),
          if (r.echeance != null && r.ouverte)
            Text(t.aRattraperAvant(Formats.dateLongue(r.echeance, langue)),
                style: secondaire?.copyWith(fontWeight: FontWeight.w700)),
          if (date != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  r.enAttenteArbitrage
                      ? Icons.hourglass_top_rounded
                      : Icons.event_rounded,
                  size: 18,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(date,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700))),
              ],
            ),
            if (r.enAttenteArbitrage)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(t.dateEnAttenteArbitrage, style: secondaire),
              ),
          ],
          if (r.rattrapeLe != null) ...[
            const SizedBox(height: 8),
            Text(t.rattrapeLe(Formats.dateLongue(r.rattrapeLe, langue)),
                style: secondaire),
          ],
          if (r.refusee && r.motifRefus.isNotEmpty) ...[
            const SizedBox(height: 12),
            Encadre(
              titre: t.dateRefusee,
              texte: r.motifRefus,
              icone: Icons.event_busy_outlined,
            ),
          ],
          if (r.dateProposable) ...[
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: () => _proposer(context, ref),
              icon: const Icon(Icons.edit_calendar_rounded),
              label: Text(t.proposerUneDate),
            ),
          ],
        ],
      ),
    );
  }

  static TonPastille _tonDuStatut(Rattrapage r) {
    if (!r.ouverte) return TonPastille.succes;
    if (r.enAttenteArbitrage || r.programmee) return TonPastille.info;
    return TonPastille.alerte;
  }
}

/// Proposition d'une date : jour, créneau, salle facultative, précision.
/// Les créneaux et salles sont ceux du formulaire du web.
class _PropositionDate extends ConsumerStatefulWidget {
  const _PropositionDate({required this.rattrapage, required this.formulaire});

  final Rattrapage rattrapage;
  final DescriptionFormulaire formulaire;

  @override
  ConsumerState<_PropositionDate> createState() => _PropositionDateState();
}

class _PropositionDateState extends ConsumerState<_PropositionDate> {
  static const _champsAffiches = {
    'date_prevue',
    'time_slot',
    'classroom',
    'commentaire',
  };

  DateTime? _date;
  String? _creneau;
  String? _salle;
  final _commentaire = TextEditingController();
  bool _enCours = false;
  ApiException? _erreur;
  bool _tente = false;

  @override
  void dispose() {
    _commentaire.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final aujourdhui = DateTime.now();
    final choisie = await showDatePicker(
      context: context,
      initialDate: _date ?? aujourdhui,
      firstDate: DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day),
      lastDate: aujourdhui.add(const Duration(days: 365)),
    );
    if (choisie != null) setState(() => _date = choisie);
  }

  Future<void> _envoyer() async {
    setState(() => _tente = true);
    if (_date == null || _creneau == null) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final (message, _) =
          await ref.read(enseignantRepositoryProvider).proposerRattrapage(
                widget.rattrapage.id,
                date: _date!,
                creneau: _creneau!,
                salle: _salle,
                commentaire: _commentaire.text.trim(),
              );
      if (mounted) Navigator.of(context).pop(message);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = e);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final creneaux = widget.formulaire['time_slot']?.choix ?? const [];
    final salles = widget.formulaire['classroom']?.choix ?? const [];
    final erreur = _erreur;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.proposerUneDate, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(widget.rattrapage.cours,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text(t.propositionAide,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (erreur != null) ...[
              const SizedBox(height: 16),
              BandeauErreurs(
                  messages: erreursGlobales(erreur, _champsAffiches)),
            ],
            const SizedBox(height: 20),
            InkWell(
              onTap: _choisirDate,
              borderRadius: BorderRadius.circular(YsemTokens.rayon),
              child: InputDecorator(
                isEmpty: _date == null,
                decoration: InputDecoration(
                  labelText: t.dateProposee,
                  prefixIcon: const Icon(Icons.event_rounded),
                  errorText: erreur?.erreurDuChamp('date_prevue') ??
                      (_tente && _date == null ? t.champObligatoire : null),
                ),
                child: Text(_date == null
                    ? ''
                    : Formats.dateLongue(_date, langue)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _creneau,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: t.creneau,
                prefixIcon: const Icon(Icons.schedule_rounded),
                errorText: erreur?.erreurDuChamp('time_slot') ??
                    (_tente && _creneau == null ? t.champObligatoire : null),
              ),
              items: [
                for (final c in creneaux)
                  DropdownMenuItem(value: c.valeur, child: Text(c.libelle)),
              ],
              onChanged: (v) => setState(() => _creneau = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _salle,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: t.salleFacultative,
                prefixIcon: const Icon(Icons.meeting_room_outlined),
                errorText: erreur?.erreurDuChamp('classroom'),
              ),
              items: [
                DropdownMenuItem<String>(value: null, child: Text(t.aucuneSalle)),
                for (final s in salles)
                  DropdownMenuItem(value: s.valeur, child: Text(s.libelle)),
              ],
              onChanged: (v) => setState(() => _salle = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentaire,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: widget.formulaire['commentaire']?.libelle ??
                    t.commentaireFacultatif,
                errorText: erreur?.erreurDuChamp('commentaire'),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _enCours ? null : _envoyer,
              icon: _enCours
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(t.transmettreAuService),
            ),
          ],
        ),
      ),
    );
  }
}
