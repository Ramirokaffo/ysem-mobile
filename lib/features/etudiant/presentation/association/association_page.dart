import 'dart:async';

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
import '../../domain/association.dart';
import 'association_commun.dart';

final _associationProvider = FutureProvider.autoDispose<Association>(
  (ref) => ref.watch(etudiantRepositoryProvider).association(),
);

/// Relecture du dépouillement pendant le vote, faute de websocket.
const _intervalleDirect = Duration(seconds: 20);

/// « Association des étudiants » : la campagne publiée, ses listes, le vote
/// quand les urnes sont ouvertes, et le dépouillement en direct. C'est le
/// scrutin qui dit lequel des trois moments s'offre, jamais l'application.
class AssociationPage extends ConsumerStatefulWidget {
  const AssociationPage({super.key, this.titre});

  final String? titre;

  @override
  ConsumerState<AssociationPage> createState() => _AssociationPageState();
}

class _AssociationPageState extends ConsumerState<AssociationPage> {
  Timer? _minuterie;
  Resultats? _direct;

  @override
  void initState() {
    super.initState();
    _minuterie = Timer.periodic(_intervalleDirect, (_) => _relireResultats());
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    super.dispose();
  }

  Future<void> _relireResultats() async {
    final etat = ref.read(_associationProvider).valueOrNull;
    final scrutin = etat?.scrutin;
    if (scrutin == null || !scrutin.urnesOuvertes) return;
    try {
      final resultats =
          await ref.read(etudiantRepositoryProvider).resultatsScrutin(scrutin.id);
      if (!mounted || resultats == null) return;
      setState(() => _direct = resultats);
      // La fermeture des urnes change ce qui s'offre : on relit tout.
      if (resultats.voteTermine) ref.invalidate(_associationProvider);
    } catch (_) {
      // Réessayé au prochain battement.
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final depot = ref.read(etudiantRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(widget.titre ?? t.sectionAssociation)),
      body: VueAsynchrone<Association>(
        valeur: ref.watch(_associationProvider),
        surRafraichir: () {
          _direct = null;
          return ref.refresh(_associationProvider.future);
        },
        constructeur: (etat) {
          final scrutin = etat.scrutin;
          if (scrutin == null) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 40),
                EtatVide(
                    message: t.aucuneCampagne,
                    icone: Icons.how_to_vote_outlined),
              ],
            );
          }
          final resultats = _direct ?? etat.resultats;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _CarteScrutin(scrutin: scrutin, aVote: etat.aVote),
              if (etat.refus.isNotEmpty && !etat.aVote) ...[
                const SizedBox(height: 12),
                Encadre(icone: Icons.block_rounded, texte: etat.refus),
              ],
              if (etat.peutVoter) ...[
                const SizedBox(height: 16),
                _Bulletin(
                  listes: etat.listes,
                  surVote: (r) {
                    setState(() => _direct = r);
                    ref.invalidate(_associationProvider);
                    ref.invalidate(navigationProvider);
                  },
                ),
              ],
              if (resultats != null &&
                  (scrutin.urnesOuvertes || scrutin.voteTermine)) ...[
                const SizedBox(height: 16),
                CarteResultats(
                    resultats: resultats, enDirect: scrutin.urnesOuvertes),
              ],
              const SizedBox(height: 20),
              Text(t.listesCandidates, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final liste in etat.listes) ...[
                CarteListe(
                  liste: liste,
                  lireProgramme: () => depot.listeCandidate(liste.id),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CarteScrutin extends StatelessWidget {
  const _CarteScrutin({required this.scrutin, required this.aVote});

  final Scrutin scrutin;
  final bool aVote;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);

    final (etat, ton) = scrutin.annule
        ? (t.scrutinAnnule, TonPastille.danger)
        : scrutin.urnesOuvertes
            ? (t.urnesOuvertes, TonPastille.succes)
            : scrutin.voteTermine
                ? (t.voteTermine, TonPastille.neutre)
                : (t.urnesAVenir, TonPastille.info);

    return CarteYsem(
      titre: scrutin.libelle,
      icone: Icons.how_to_vote_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Pastille(etat, ton: ton),
              if (aVote)
                Pastille(t.vousAvezVote,
                    ton: TonPastille.succes, icone: Icons.check_rounded),
            ],
          ),
          if (scrutin.dateVote != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.event_outlined,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    [
                      Formats.jourLong(scrutin.dateVote, langue),
                      Formats.plage(scrutin.ouvertureUrnes, scrutin.fermetureUrnes),
                    ].where((s) => s.isNotEmpty).join(' · '),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
          if (scrutin.annule && scrutin.motifAnnulation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Encadre(icone: Icons.cancel_outlined, texte: scrutin.motifAnnulation),
          ],
          if (scrutin.consignes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(scrutin.consignes, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 10),
          Text(t.voteAnonyme,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Le bulletin : un choix, et un seul, confirmé avant l'envoi — un vote ne
/// se reprend pas.
class _Bulletin extends ConsumerStatefulWidget {
  const _Bulletin({required this.listes, required this.surVote});

  final List<ListeCandidate> listes;
  final ValueChanged<Resultats?> surVote;

  @override
  ConsumerState<_Bulletin> createState() => _BulletinState();
}

class _BulletinState extends ConsumerState<_Bulletin> {
  int? _choix;
  bool _envoi = false;

  Future<void> _voter() async {
    final t = AppLocalizations.of(context);
    final liste = widget.listes.firstWhere((l) => l.id == _choix);
    final ok = await confirmer(
      context,
      titre: t.confirmerVote,
      texte: t.confirmerVoteTexte(liste.nom),
      action: t.voter,
    );
    if (!ok || !mounted) return;
    final messager = ScaffoldMessenger.of(context);
    setState(() => _envoi = true);
    try {
      final (message, resultats) =
          await ref.read(etudiantRepositoryProvider).voter(liste.id);
      messager.showSnackBar(SnackBar(content: Text(message)));
      widget.surVote(resultats);
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return CarteYsem(
      titre: t.votreBulletin,
      icone: Icons.ballot_outlined,
      child: RadioGroup<int>(
        groupValue: _choix,
        onChanged: (v) {
          if (!_envoi) setState(() => _choix = v);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final liste in widget.listes)
              RadioListTile<int>(
                value: liste.id,
                contentPadding: EdgeInsets.zero,
                secondary: InitialesListe(liste: liste, rayon: 18),
                title: Text(liste.nom, style: theme.textTheme.titleSmall),
                subtitle:
                    liste.candidat.isEmpty ? null : Text(liste.candidat),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _choix == null || _envoi ? null : _voter,
              icon: _envoi
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.how_to_vote_rounded),
              label: Text(t.validerMonVote),
            ),
          ],
        ),
      ),
    );
  }
}
