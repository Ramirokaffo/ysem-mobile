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
import 'controle_page.dart';
import 'copies_page.dart';

/// « Mes feuilles de notes » : ce que le service attend, épreuve par épreuve.
/// Le contrôle continu se tient au fil des séances ; l'intra et l'examen
/// s'ouvrent une fois composés et anonymés.
class FeuillesPage extends ConsumerWidget {
  const FeuillesPage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionFeuillesDeNotes)),
      body: VueAsynchrone<FeuillesDeNotes>(
        valeur: ref.watch(feuillesDeNotesProvider),
        surRafraichir: () => ref.refresh(feuillesDeNotesProvider.future),
        constructeur: (donnees) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (donnees.feuilles.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EtatVide(
                  message: t.aucuneFeuilleDeNotes,
                  icone: Icons.fact_check_outlined,
                ),
              ),
            for (final feuille in donnees.feuilles) ...[
              _CarteFeuille(feuille: feuille),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ce que dit une épreuve de son état, comme la liste du portail web.
(String, TonPastille) etatDeLEpreuve(AppLocalizations t, EpreuveFeuille e) {
  return switch (e.statut) {
    StatutsEpreuve.aVenir => (t.epreuveAVenir, TonPastille.neutre),
    StatutsEpreuve.validee => (t.epreuveValidee, TonPastille.succes),
    StatutsEpreuve.rendue => (t.epreuveRendue, TonPastille.info),
    _ when e.controleContinu => (
        t.controlesARendre(e.nbControles ?? 0),
        TonPastille.alerte,
      ),
    _ when e.manquantes > 0 => (
        t.notesASaisirSur(e.manquantes, e.total),
        TonPastille.alerte,
      ),
    _ => (t.saisieCompleteARendre, TonPastille.succes),
  };
}

class _CarteFeuille extends StatelessWidget {
  const _CarteFeuille({required this.feuille});

  final FeuilleNotes feuille;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final f = feuille;
    return CarteYsem(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => FeuillePage(feuille: f.id, titre: f.cours.libelle(langue)),
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(f.cours.libelle(langue), style: theme.textTheme.titleSmall),
          Text(
            [f.cohorte, f.semestre, f.sessionLibelle]
                .where((s) => s.isNotEmpty)
                .join(' · '),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (!f.modifiable) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Pastille(t.feuilleDeliberee,
                  ton: TonPastille.neutre,
                  icone: Icons.lock_outline_rounded),
            ),
          ],
          const SizedBox(height: 8),
          for (final e in f.epreuves)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: _LigneEpreuve(epreuve: e),
            ),
        ],
      ),
    );
  }
}

class _LigneEpreuve extends StatelessWidget {
  const _LigneEpreuve({required this.epreuve});

  final EpreuveFeuille epreuve;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (etat, ton) = etatDeLEpreuve(t, epreuve);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(epreuve.typeLibelle,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        Pastille(etat, ton: ton),
      ],
    );
  }
}

/// Une feuille : son contrôle continu, puis ses épreuves anonymes.
class FeuillePage extends ConsumerWidget {
  const FeuillePage({super.key, required this.feuille, this.titre});

  final int feuille;
  final String? titre;

  void _relire(WidgetRef ref) {
    ref.invalidate(detailFeuilleProvider(feuille));
    ref.invalidate(feuillesDeNotesProvider);
    ref.read(menuEnseignantProvider.notifier).rafraichir();
  }

  Future<void> _ajouterControle(
      BuildContext context, WidgetRef ref, DetailFeuille detail) async {
    final navigateur = Navigator.of(context);
    final cree = await showModalBottomSheet<ControleDeFeuille>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NouveauControle(feuille: feuille, detail: detail),
    );
    if (cree == null) return;
    _relire(ref);
    // Un contrôle déclaré est un contrôle à noter : on y mène directement.
    navigateur.push(MaterialPageRoute<void>(
      builder: (_) => ControlePage(feuille: feuille, controle: cree.id),
    ));
  }

  Future<void> _rendreCc(
      BuildContext context, WidgetRef ref, EpreuveFeuille cc) async {
    final t = AppLocalizations.of(context);
    final messager = ScaffoldMessenger.of(context);
    final ok = await confirmer(
      context,
      titre: t.rendreControleContinu,
      texte: cc.manquantes > 0
          ? '${t.notesEncoreAttendues(cc.manquantes)}\n\n${t.rendreCcConfirmation}'
          : t.rendreCcConfirmation,
      action: t.rendre,
    );
    if (!ok) return;
    try {
      final message = await ref
          .read(enseignantRepositoryProvider)
          .rendreControleContinu(feuille);
      messager.showSnackBar(SnackBar(content: Text(message)));
      _relire(ref);
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionFeuillesDeNotes)),
      body: VueAsynchrone<DetailFeuille>(
        valeur: ref.watch(detailFeuilleProvider(feuille)),
        surRafraichir: () => ref.refresh(detailFeuilleProvider(feuille).future),
        constructeur: (d) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              [
                d.feuille.cohorte,
                d.feuille.semestre,
                d.feuille.sessionLibelle,
                t.notesSur(Formats.coefficient(d.noteMax, langue)),
              ].where((s) => s.isNotEmpty).join(' · '),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (!d.feuille.modifiable) ...[
              Encadre(
                texte: t.feuilleVerrouillee,
                icone: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 12),
            ],
            Encadre(
              titre: t.caseVideTitre,
              texte: t.caseVideExplication,
              icone: Icons.info_outline_rounded,
            ),
            const SizedBox(height: 16),
            if (d.aUnControleContinu) ...[
              _CarteControleContinu(
                feuille: feuille,
                detail: d,
                surAjouter: () => _ajouterControle(context, ref, d),
                surRendre: (cc) => _rendreCc(context, ref, cc),
              ),
              const SizedBox(height: 16),
            ],
            for (final e in d.epreuvesAnonymes) ...[
              _CarteEpreuveAnonyme(feuille: feuille, detail: d, epreuve: e),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _CarteControleContinu extends StatelessWidget {
  const _CarteControleContinu({
    required this.feuille,
    required this.detail,
    required this.surAjouter,
    required this.surRendre,
  });

  final int feuille;
  final DetailFeuille detail;
  final VoidCallback surAjouter;
  final ValueChanged<EpreuveFeuille> surRendre;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final cc = detail.epreuveCc;
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final etat = cc == null ? null : etatDeLEpreuve(t, cc);

    return CarteYsem(
      titre: t.controleContinu,
      icone: Icons.checklist_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (etat != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Pastille(etat.$1, ton: etat.$2),
            ),
          if (cc?.dateLimite != null && cc!.estOuverte) ...[
            const SizedBox(height: 6),
            Text(t.aRendreAvant(Formats.dateLongue(cc.dateLimite, langue)),
                style: secondaire),
          ],
          if (cc != null && cc.commentaire.isNotEmpty && cc.estOuverte) ...[
            const SizedBox(height: 8),
            Encadre(
              titre: t.messageDuService,
              texte: cc.commentaire,
              icone: Icons.reply_rounded,
            ),
          ],
          if (cc != null && cc.total > 0) ...[
            const SizedBox(height: 10),
            _Progression(epreuve: cc),
          ],
          const SizedBox(height: 8),
          Text(t.controleContinuExplication, style: secondaire),
          const SizedBox(height: 8),
          if (detail.controles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(t.aucunControle,
                  textAlign: TextAlign.center, style: secondaire),
            ),
          for (final c in detail.controles)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(c.libelle,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              subtitle: Text([
                Formats.dateLongue(c.date, langue),
                if (c.ponderation != null)
                  t.ponderationDe(Formats.coefficient(c.ponderation!, langue)),
              ].where((s) => s.isNotEmpty).join(' · ')),
              trailing: Icon(
                  detail.ccModifiable
                      ? Icons.edit_outlined
                      : Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) =>
                    ControlePage(feuille: feuille, controle: c.id),
              )),
            ),
          if (detail.ccModifiable) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: surAjouter,
              icon: const Icon(Icons.add_rounded),
              label: Text(t.nouveauControle),
            ),
            if (cc != null) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => surRendre(cc),
                icon: const Icon(Icons.send_rounded),
                label: Text(t.rendreControleContinu),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Progression extends StatelessWidget {
  const _Progression({required this.epreuve});

  final EpreuveFeuille epreuve;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final e = epreuve;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(t.notesSaisies,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
            Text('${e.saisies} / ${e.total}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: e.total == 0 ? 0 : e.saisies / e.total,
          ),
        ),
      ],
    );
  }
}

class _CarteEpreuveAnonyme extends StatelessWidget {
  const _CarteEpreuveAnonyme({
    required this.feuille,
    required this.detail,
    required this.epreuve,
  });

  final int feuille;
  final DetailFeuille detail;
  final EpreuveFeuille epreuve;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final e = epreuve;
    final (etat, ton) = etatDeLEpreuve(t, e);
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return CarteYsem(
      titre: e.typeLibelle,
      icone: Icons.lock_person_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Pastille(etat, ton: ton),
          ),
          if (e.statut == StatutsEpreuve.aVenir) ...[
            const SizedBox(height: 8),
            Text(t.epreuveAVenirExplication, style: secondaire),
          ],
          if (e.dateLimite != null && e.estOuverte) ...[
            const SizedBox(height: 6),
            Text(t.aRendreAvant(Formats.dateLongue(e.dateLimite, langue)),
                style: secondaire),
          ],
          if (e.commentaire.isNotEmpty && e.estOuverte) ...[
            const SizedBox(height: 8),
            Encadre(
              titre: t.messageDuService,
              texte: e.commentaire,
              icone: Icons.reply_rounded,
            ),
          ],
          if (e.statut != StatutsEpreuve.aVenir && e.total > 0) ...[
            const SizedBox(height: 10),
            _Progression(epreuve: e),
          ],
          if (e.saisissable) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => CopiesPage(
                  feuille: feuille,
                  epreuve: e,
                  statuts: detail.statutsDeNote,
                  noteMax: detail.noteMax,
                ),
              )),
              icon: const Icon(Icons.edit_note_rounded),
              label: Text(t.saisirParCode),
            ),
          ],
        ],
      ),
    );
  }
}

/// Déclaration d'un contrôle : son type et sa date. Les types proposés sont
/// ceux du formulaire du web, qui écarte ce qui ne s'évalue qu'une fois.
class _NouveauControle extends ConsumerStatefulWidget {
  const _NouveauControle({required this.feuille, required this.detail});

  final int feuille;
  final DetailFeuille detail;

  @override
  ConsumerState<_NouveauControle> createState() => _NouveauControleState();
}

class _NouveauControleState extends ConsumerState<_NouveauControle> {
  String? _type;
  DateTime? _date = DateTime.now();
  bool _enCours = false;
  bool _tente = false;
  ApiException? _erreur;

  Future<void> _envoyer() async {
    setState(() => _tente = true);
    if (_type == null || _date == null) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    final messager = ScaffoldMessenger.of(context);
    try {
      final (message, controle) = await ref
          .read(enseignantRepositoryProvider)
          .creerControle(widget.feuille, type: _type!, date: _date!);
      messager.showSnackBar(SnackBar(content: Text(message)));
      if (mounted) Navigator.of(context).pop(controle);
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
    final f = widget.detail.formulaireControle;
    final types = f['type_controle']?.choix ?? const [];
    final erreur = _erreur;
    final maintenant = DateTime.now();
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.nouveauControle, style: theme.textTheme.titleLarge),
          if (erreur != null) ...[
            const SizedBox(height: 16),
            BandeauErreurs(
                messages:
                    erreursGlobales(erreur, const {'type_controle', 'date'})),
          ],
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _type,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: f['type_controle']?.libelle ?? t.typeDeControle,
              prefixIcon: const Icon(Icons.checklist_rounded),
              errorText: erreur?.erreurDuChamp('type_controle') ??
                  (_tente && _type == null ? t.champObligatoire : null),
              errorMaxLines: 3,
            ),
            items: [
              for (final c in types)
                DropdownMenuItem(
                  value: c.valeur,
                  child: Text(c.libelle, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: 16),
          ChampDate(
            libelle: f['date']?.libelle ?? t.date,
            valeur: _date,
            premiere: DateTime(maintenant.year - 1),
            derniere: DateTime(maintenant.year + 1, 12, 31),
            surChoix: (d) => setState(() => _date = d),
            erreur: erreur?.erreurDuChamp('date') ??
                (_tente && _date == null ? t.champObligatoire : null),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _enCours ? null : _envoyer,
            icon: _enCours
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Icon(Icons.add_rounded),
            label: Text(t.ajouterLeControle),
          ),
        ],
      ),
    );
  }
}
