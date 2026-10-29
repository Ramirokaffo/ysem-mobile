import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/formulaire.dart';
import '../../../commun/langue.dart';
import '../../../commun/piece_jointe.dart';
import '../../application/sections.dart';
import '../../domain/permissions.dart';

/// Dépôt d'une demande de permission. L'étudiant coche des **séances** de son
/// emploi du temps, semaine par semaine : le serveur ne reconnaît que les
/// jetons de la semaine consultée, si bien que changer de semaine vide la
/// sélection. Le préavis est signalé, jamais opposé. Rend le message du
/// serveur au retour.
class NouvellePermissionPage extends ConsumerStatefulWidget {
  const NouvellePermissionPage({super.key});

  @override
  ConsumerState<NouvellePermissionPage> createState() =>
      _NouvellePermissionPageState();
}

class _NouvellePermissionPageState
    extends ConsumerState<NouvellePermissionPage> {
  static const _champs = {
    'type_demande',
    'seances',
    'motif',
    'motif_libre',
    'heure_arrivee_prevue',
    'justificatif',
  };

  final _cle = GlobalKey<FormState>();
  final _explication = TextEditingController();

  /// `null` : semaine courante.
  String? _semaine;
  Permissions? _derniere;
  final Set<String> _choisies = {};
  String _type = 'absence';
  String _motif = '';
  TimeOfDay? _arrivee;
  PieceAJoindre? _justificatif;
  bool _envoi = false;
  ApiException? _erreur;

  @override
  void dispose() {
    _explication.dispose();
    super.dispose();
  }

  void _allerA(DateTime? semaine) {
    if (semaine == null) return;
    setState(() {
      _semaine = Formats.iso(semaine);
      _choisies.clear();
    });
  }

  static String _hhmm(TimeOfDay h) =>
      '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';

  Future<void> _choisirArrivee() async {
    final heure = await showTimePicker(
      context: context,
      initialTime: _arrivee ?? const TimeOfDay(hour: 8, minute: 30),
    );
    if (heure != null) setState(() => _arrivee = heure);
  }

  Future<void> _envoyer(Permissions etat) async {
    setState(() => _erreur = null);
    if (!_cle.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      final message =
          await ref.read(etudiantRepositoryProvider).deposerPermission(
                semaine: etat.semaine.debut == null
                    ? _semaine
                    : Formats.iso(etat.semaine.debut!),
                type: _type,
                seances: _choisies.toList(),
                explication: _explication.text.trim(),
                motif: _motif,
                heureArrivee:
                    _type == 'retard' && _arrivee != null ? _hhmm(_arrivee!) : null,
                justificatif: _justificatif,
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
    final valeur = ref.watch(permissionsProvider(_semaine));
    final etat = valeur.valueOrNull ?? _derniere;
    if (valeur.hasValue) _derniere = valeur.value;

    return Scaffold(
      appBar: AppBar(title: Text(t.demanderPermission)),
      body: etat == null
          ? VueAsynchrone<Permissions>(
              valeur: valeur,
              surRafraichir: () =>
                  ref.refresh(permissionsProvider(_semaine).future),
              constructeur: (_) => const SizedBox.shrink(),
            )
          : _formulaire(context, etat, chargement: valeur.isLoading),
    );
  }

  Widget _formulaire(BuildContext context, Permissions etat,
      {required bool chargement}) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final erreur = _erreur;
    final types = etat.types.isEmpty
        ? [Choix('absence', t.absence), Choix('retard', t.retard)]
        : etat.types;
    final justificatifExige =
        etat.justificatifObligatoire && _type == 'absence';

    return Form(
      key: _cle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (!etat.depotOuvert)
            Encadre(
                icone: Icons.lock_outline_rounded,
                texte: t.depotPermissionsFerme)
          else if (etat.preavisHeures != null && etat.preavisHeures! > 0)
            Encadre(
                icone: Icons.timer_outlined,
                texte: t.preavisPermission(etat.preavisHeures!)),
          if (erreur != null) ...[
            const SizedBox(height: 16),
            BandeauErreurs(messages: erreursGlobales(erreur, _champs)),
          ],
          const SizedBox(height: 20),
          Text(t.objetDeLaDemande, style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: [
              for (final c in types)
                ButtonSegment(
                  value: c.valeur,
                  label: Text(c.libelle),
                  icon: Icon(c.valeur == 'retard'
                      ? Icons.schedule_rounded
                      : Icons.event_busy_outlined),
                ),
            ],
            selected: {_type},
            onSelectionChanged:
                _envoi ? null : (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 20),
          _ChoixSeances(
            etat: etat,
            chargement: chargement,
            choisies: _choisies,
            actif: !_envoi,
            erreur: erreur?.erreurDuChamp('seances'),
            surBascule: (jeton) => setState(() {
              if (!_choisies.remove(jeton)) _choisies.add(jeton);
            }),
            surSemaine: _allerA,
          ),
          if (_type == 'retard') ...[
            const SizedBox(height: 16),
            FormField<TimeOfDay>(
              validator: (_) =>
                  erreur?.erreurDuChamp('heure_arrivee_prevue') ??
                  (_arrivee == null ? t.heureArriveeRequise : null),
              builder: (champ) => InkWell(
                onTap: _envoi ? null : _choisirArrivee,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: t.heureArriveeAnnoncee,
                    errorText: champ.errorText,
                    suffixIcon: const Icon(Icons.access_time_rounded),
                  ),
                  child: Text(_arrivee == null ? '' : _hhmm(_arrivee!),
                      style: theme.textTheme.bodyLarge),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _motif,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: t.motif,
              errorText: erreur?.erreurDuChamp('motif'),
            ),
            items: [
              DropdownMenuItem(value: '', child: Text(t.motifNonListe)),
              for (final m in etat.motifs)
                DropdownMenuItem(
                  value: m.valeur,
                  child: Text(m.libelle, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _envoi ? null : (v) => setState(() => _motif = v ?? ''),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _explication,
            enabled: !_envoi,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: t.explication,
              hintText: t.explicationPermissionAide,
              alignLabelWithHint: true,
            ),
            validator: (v) =>
                erreur?.erreurDuChamp('motif_libre') ??
                ((v ?? '').trim().isEmpty ? t.explicationRequise : null),
          ),
          const SizedBox(height: 16),
          ChampPieceJointe(
            libelle: justificatifExige
                ? t.pieceJustificativeObligatoire
                : t.pieceJustificativeFacultative,
            aide: t.formatsPieces,
            erreur: erreur?.erreurDuChamp('justificatif'),
            piece: _justificatif,
            actif: !_envoi,
            surChoix: (p) => setState(() => _justificatif = p),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _envoi || chargement || !etat.depotOuvert
                ? null
                : () => _envoyer(etat),
            icon: _envoi
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
            label: Text(_choisies.isEmpty
                ? t.envoyerDemande
                : t.envoyerDemandeSeances(_choisies.length)),
          ),
        ],
      ),
    );
  }
}

/// Les séances de la semaine, à cocher. Une séance annulée ou chômée reste
/// affichée — c'est ce qui dit pourquoi tel jour ne propose rien — mais ne
/// se coche pas.
class _ChoixSeances extends StatelessWidget {
  const _ChoixSeances({
    required this.etat,
    required this.chargement,
    required this.choisies,
    required this.actif,
    required this.surBascule,
    required this.surSemaine,
    this.erreur,
  });

  final Permissions etat;
  final bool chargement;
  final Set<String> choisies;
  final bool actif;
  final String? erreur;
  final ValueChanged<String> surBascule;
  final ValueChanged<DateTime?> surSemaine;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final semaine = etat.semaine;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: erreur != null
              ? theme.colorScheme.error
              : theme.colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(YsemTokens.rayon),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: t.semainePrecedente,
                  onPressed: actif && !chargement
                      ? () => surSemaine(semaine.precedente)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(t.seancesConcernees,
                          style: theme.textTheme.labelLarge),
                      Text(
                        t.semaineDuAu(Formats.jourMois(semaine.debut, langue),
                            Formats.jourMois(semaine.fin, langue)),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: t.semaineSuivante,
                  onPressed: actif && !chargement
                      ? () => surSemaine(semaine.suivante)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          if (!semaine.estCourante)
            Center(
              child: TextButton(
                onPressed: actif && !chargement
                    ? () => surSemaine(semaine.courante)
                    : null,
                child: Text(t.cetteSemaine),
              ),
            ),
          if (chargement) const LinearProgressIndicator(minHeight: 2),
          if (etat.journees.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(t.aucuneSeanceSemaine,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
          for (final (date, seances) in etat.journees) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
              child: Text(Formats.jourLong(date, langue),
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.primary)),
            ),
            for (final seance in seances)
              _LigneSeance(
                seance: seance,
                choisie: choisies.contains(seance.jeton),
                actif: actif && !chargement && seance.demandable,
                surBascule: () => surBascule(seance.jeton),
              ),
          ],
          if (erreur != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(erreur!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error)),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LigneSeance extends StatelessWidget {
  const _LigneSeance({
    required this.seance,
    required this.choisie,
    required this.actif,
    required this.surBascule,
  });

  final SeanceDemandable seance;
  final bool choisie;
  final bool actif;
  final VoidCallback surBascule;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final details = [
      if (seance.salle.isNotEmpty) seance.salle,
      if (seance.enseignant.isNotEmpty) seance.enseignant,
    ].join(' · ');

    return CheckboxListTile(
      value: choisie,
      onChanged: actif ? (_) => surBascule() : null,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: const EdgeInsets.only(left: 8, right: 16),
      title: Text(
        [Formats.plage(seance.debut, seance.fin), seance.intitule(langue)]
            .where((s) => s.isNotEmpty)
            .join(' · '),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          decoration: seance.demandable ? null : TextDecoration.lineThrough,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (details.isNotEmpty) Text(details, style: secondaire),
          if (seance.annulee || seance.chomee || seance.dejaCouverte != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Pastille(
                seance.annulee
                    ? t.seanceAnnulee
                    : seance.chomee
                        ? t.jourChome
                        : t.dejaAccordee,
                ton: seance.dejaCouverte != null &&
                        !seance.annulee &&
                        !seance.chomee
                    ? TonPastille.succes
                    : TonPastille.neutre,
              ),
            ),
        ],
      ),
    );
  }
}
