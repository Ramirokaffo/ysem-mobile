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
import '../../domain/situation.dart';

/// « Mes disponibilités » : ce que l'enseignant déclare, créneau par créneau,
/// pour l'année active. La planification en est prévenue : c'est elle qui
/// compose les grilles avec.
class DisponibilitesPage extends ConsumerWidget {
  const DisponibilitesPage({super.key, this.titre});

  final String? titre;

  Future<void> _editer(
    BuildContext context,
    WidgetRef ref,
    DescriptionFormulaire formulaire, [
    Disponibilite? existante,
  ]) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _Formulaire(formulaire: formulaire, existante: existante),
    );
    if (message == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    ref.invalidate(disponibilitesProvider);
  }

  Future<void> _retirer(
      BuildContext context, WidgetRef ref, Disponibilite d) async {
    final t = AppLocalizations.of(context);
    final messager = ScaffoldMessenger.of(context);
    final ok = await confirmer(
      context,
      titre: t.retirerDisponibilite,
      texte: t.retirerDisponibiliteConfirmation(d.creneauLibelle),
      action: t.retirer,
    );
    if (!ok) return;
    try {
      await ref.read(enseignantRepositoryProvider).retirerDisponibilite(d.id);
      ref.invalidate(disponibilitesProvider);
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final valeur = ref.watch(disponibilitesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionDisponibilites)),
      floatingActionButton: valeur.valueOrNull == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  _editer(context, ref, valeur.value!.formulaire),
              icon: const Icon(Icons.add_rounded),
              label: Text(t.declarerDisponibilite),
            ),
      body: VueAsynchrone<Disponibilites>(
        valeur: valeur,
        surRafraichir: () => ref.refresh(disponibilitesProvider.future),
        constructeur: (donnees) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Encadre(
              texte: t.disponibilitesExplication,
              icone: Icons.info_outline_rounded,
            ),
            const SizedBox(height: 16),
            if (donnees.disponibilites.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: EtatVide(
                  message: t.aucuneDisponibilite,
                  icone: Icons.edit_calendar_outlined,
                ),
              ),
            for (final d in donnees.disponibilites) ...[
              _CarteDisponibilite(
                disponibilite: d,
                surModifier: () =>
                    _editer(context, ref, donnees.formulaire, d),
                surRetirer: () => _retirer(context, ref, d),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

TonPastille _tonDeDisponibilite(String statut) => switch (statut) {
      'available' => TonPastille.succes,
      'preferred' => TonPastille.marque,
      'unavailable' => TonPastille.danger,
      _ => TonPastille.neutre,
    };

class _CarteDisponibilite extends StatelessWidget {
  const _CarteDisponibilite({
    required this.disponibilite,
    required this.surModifier,
    required this.surRetirer,
  });

  final Disponibilite disponibilite;
  final VoidCallback surModifier;
  final VoidCallback surRetirer;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final d = disponibilite;
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return CarteYsem(
      padding: const EdgeInsets.fromLTRB(16, 14, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.creneauLibelle.isNotEmpty
                      ? d.creneauLibelle
                      : Formats.plage(d.debutCreneau, d.finCreneau),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Pastille(d.statutLibelle, ton: _tonDeDisponibilite(d.statut)),
                const SizedBox(height: 6),
                Text(
                  d.debut == null
                      ? t.touteLAnnee
                      : t.semaineDuAu(Formats.dateLongue(d.debut, langue),
                          Formats.dateLongue(d.fin, langue)),
                  style: secondaire,
                ),
                if (d.notes.isNotEmpty) Text(d.notes, style: secondaire),
              ],
            ),
          ),
          IconButton(
            tooltip: t.modifier,
            onPressed: surModifier,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: t.retirer,
            onPressed: surRetirer,
            icon: Icon(Icons.delete_outline_rounded,
                color: theme.colorScheme.error),
          ),
        ],
      ),
    );
  }
}

/// Déclaration ou modification : les champs et les choix sont ceux du
/// formulaire du web, et c'est lui qui valide (doublon, dates).
class _Formulaire extends ConsumerStatefulWidget {
  const _Formulaire({required this.formulaire, this.existante});

  final DescriptionFormulaire formulaire;
  final Disponibilite? existante;

  @override
  ConsumerState<_Formulaire> createState() => _FormulaireState();
}

class _FormulaireState extends ConsumerState<_Formulaire> {
  static const _champsAffiches = {
    'time_slot',
    'status',
    'start_date',
    'end_date',
    'notes',
  };

  late String? _creneau = widget.existante?.creneauId?.toString();
  late String? _statut = widget.existante?.statut;
  late DateTime? _debut = widget.existante?.debut;
  late DateTime? _fin = widget.existante?.fin;
  late final _notes = TextEditingController(text: widget.existante?.notes);
  bool _enCours = false;
  bool _tente = false;
  ApiException? _erreur;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    setState(() => _tente = true);
    if (_creneau == null || _statut == null) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final message =
          await ref.read(enseignantRepositoryProvider).enregistrerDisponibilite(
                id: widget.existante?.id,
                creneau: _creneau!,
                statut: _statut!,
                debut: _debut,
                fin: _fin,
                notes: _notes.text.trim(),
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
    final f = widget.formulaire;
    final erreur = _erreur;
    final creneaux = f['time_slot']?.choix ?? const <OptionChamp>[];
    final statuts = f['status']?.choix ?? const <OptionChamp>[];
    final annee = DateTime.now().year;
    final premiere = DateTime(annee - 1);
    final derniere = DateTime(annee + 2, 12, 31);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existante == null
                  ? t.declarerDisponibilite
                  : t.modifierDisponibilite,
              style: theme.textTheme.titleLarge,
            ),
            if (erreur != null) ...[
              const SizedBox(height: 16),
              BandeauErreurs(
                  messages: erreursGlobales(erreur, _champsAffiches)),
            ],
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              // Un créneau déjà porté par la ligne reste proposé par le web.
              initialValue: creneaux.any((c) => c.valeur == _creneau)
                  ? _creneau
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: f['time_slot']?.libelle ?? t.creneau,
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
              initialValue:
                  statuts.any((s) => s.valeur == _statut) ? _statut : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: f['status']?.libelle ?? t.statut,
                prefixIcon: const Icon(Icons.event_available_outlined),
                errorText: erreur?.erreurDuChamp('status') ??
                    (_tente && _statut == null ? t.champObligatoire : null),
              ),
              items: [
                for (final s in statuts)
                  DropdownMenuItem(value: s.valeur, child: Text(s.libelle)),
              ],
              onChanged: (v) => setState(() => _statut = v),
            ),
            const SizedBox(height: 16),
            ChampDate(
              libelle: f['start_date']?.libelle ?? '',
              valeur: _debut,
              premiere: premiere,
              derniere: derniere,
              effacable: true,
              surChoix: (d) => setState(() => _debut = d),
              erreur: erreur?.erreurDuChamp('start_date'),
            ),
            const SizedBox(height: 16),
            ChampDate(
              libelle: f['end_date']?.libelle ?? '',
              valeur: _fin,
              premiere: premiere,
              derniere: derniere,
              effacable: true,
              surChoix: (d) => setState(() => _fin = d),
              erreur: erreur?.erreurDuChamp('end_date'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: f['notes']?.libelle ?? t.commentaireFacultatif,
                errorText: erreur?.erreurDuChamp('notes'),
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
                  : const Icon(Icons.check_rounded),
              label: Text(t.enregistrer),
            ),
          ],
        ),
      ),
    );
  }
}
