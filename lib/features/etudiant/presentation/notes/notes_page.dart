import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../application/sections.dart';
import '../../domain/notes.dart';

/// « Mes notes » : les chiffres du service, tels que le jury les arrête.
///
/// Une seule note par cours, la note retenue, et seulement une fois la
/// délibération publiée ; avant, les épreuves validées par le service
/// (contrôle continu, intra). Rien ne dit qu'une note a été révisée.
class NotesPage extends ConsumerWidget {
  const NotesPage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionNotes)),
      body: VueAsynchrone<Notes>(
        valeur: ref.watch(notesProvider),
        surRafraichir: () => ref.refresh(notesProvider.future),
        constructeur: (notes) => _Contenu(notes: notes),
      ),
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.notes});

  final Notes notes;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final enAttente = notes.semestres
        .expand((s) => s.notes)
        .any((ligne) => !ligne.notePubliee);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (notes.annee != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Pastille(notes.annee!.nom,
                  ton: TonPastille.marque, icone: Icons.event_rounded),
            ),
          ),
        if (notes.estVide)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: EtatVide(
                message: t.aucuneNote, icone: Icons.fact_check_outlined),
          ),
        if (enAttente) ...[
          Encadre(texte: t.notesAvantJury),
          const SizedBox(height: 16),
        ],
        if (notes.resultatAnnuel != null) ...[
          CarteYsem(
            titre: t.resultatAnnuel,
            icone: Icons.emoji_events_outlined,
            child: _BlocResultat(resultat: notes.resultatAnnuel!),
          ),
          const SizedBox(height: 16),
        ],
        for (final semestre in notes.semestres)
          if (semestre.notes.isNotEmpty ||
              notes.resultatsDe(semestre.semestre).isNotEmpty) ...[
            _CarteSemestre(
              semestre: semestre,
              resultats: notes.resultatsDe(semestre.semestre),
            ),
            const SizedBox(height: 16),
          ],
        if (notes.releves.isNotEmpty) _CarteReleves(releves: notes.releves),
      ],
    );
  }
}

TonPastille _tonDecision(String decision) => switch (decision.toUpperCase()) {
      'AD' || 'ADD' => TonPastille.succes,
      'RAT' => TonPastille.alerte,
      'AJ' || 'RED' || 'EXC' => TonPastille.danger,
      _ => TonPastille.neutre,
    };

/// Moyenne, crédits, rang et décision d'une délibération.
class _BlocResultat extends StatelessWidget {
  const _BlocResultat({required this.resultat, this.avecSession = false});

  final ResultatJury resultat;
  final bool avecSession;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final r = resultat;

    Widget chiffre(String libelle, String valeur, [String suffixe = '']) =>
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(libelle,
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              // Réduit plutôt que coupé sur un écran étroit.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: valeur),
                    if (suffixe.isNotEmpty)
                      TextSpan(
                        text: suffixe,
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ]),
                  maxLines: 1,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );

    final session = r.estRattrapage ? t.sessionRattrapage : t.sessionNormale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (avecSession)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(t.resultatSession(session),
                style: theme.textTheme.titleSmall),
          ),
        Row(
          children: [
            chiffre(t.moyenne, Formats.note(r.moyenne, langue), ' /20'),
            chiffre(
              t.credits,
              r.creditsAcquis == null ? '—' : '${r.creditsAcquis}',
              r.creditsRequis == null ? '' : ' / ${r.creditsRequis}',
            ),
            if (r.rang != null && r.effectif != null)
              chiffre(t.rang, '${r.rang}', ' / ${r.effectif}'),
          ],
        ),
        if (r.decisionLibelle.isNotEmpty || r.mention.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (r.decisionLibelle.isNotEmpty)
                Pastille(r.decisionLibelle, ton: _tonDecision(r.decision)),
              if (r.mention.isNotEmpty) Pastille(r.mention),
              if (r.grade.isNotEmpty) Pastille(r.grade, ton: TonPastille.marque),
            ],
          ),
        ],
        if (!r.estRattrapage &&
            !r.sessionClose &&
            r.coursARattraper.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(t.coursARepasser,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: YsemTokens.of(context).alerte)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final code in r.coursARattraper)
                Pastille(code, ton: TonPastille.alerte),
            ],
          ),
        ],
        if (r.observations.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(r.observations,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ],
    );
  }
}

class _CarteSemestre extends StatelessWidget {
  const _CarteSemestre({required this.semestre, required this.resultats});

  final SemestreNotes semestre;
  final List<ResultatJury> resultats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CarteYsem(
      titre: semestre.semestre?.nom ?? '',
      icone: Icons.fact_check_outlined,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final resultat in resultats) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(YsemTokens.rayonPetit),
              ),
              child: _BlocResultat(
                resultat: resultat,
                avecSession: resultats.length > 1 || resultat.estRattrapage,
              ),
            ),
          ],
          for (final (i, ligne) in semestre.notes.indexed) ...[
            if (i > 0) const Divider(),
            _LigneCours(ligne: ligne),
          ],
        ],
      ),
    );
  }
}

class _LigneCours extends StatelessWidget {
  const _LigneCours({required this.ligne});

  final LigneNote ligne;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final cours = ligne.cours;
    final sousTitre = [
      cours.codeAffiche,
      if (cours.credits != null) t.creditsDuCours(cours.credits!),
      if (ligne.uniteEnseignement.isNotEmpty) ligne.uniteEnseignement,
    ].where((s) => s.isNotEmpty).join(' · ');

    final note = ligne.notePubliee && ligne.note != null
        ? Text(
            Formats.note(ligne.note, langue),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          )
        : Pastille(t.notesEnAttenteJury);

    final entete = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cours.libelle(langue), style: theme.textTheme.titleSmall),
              if (sousTitre.isNotEmpty)
                Text(sousTitre,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              if (ligne.estRattrapage) ...[
                const SizedBox(height: 4),
                Pastille(t.sessionRattrapage, ton: TonPastille.info),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        note,
      ],
    );

    if (ligne.epreuves.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: entete,
      );
    }
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        title: entete,
        children: [
          for (final epreuve in ligne.epreuves) _BlocEpreuve(epreuve: epreuve),
        ],
      ),
    );
  }
}

class _BlocEpreuve extends StatelessWidget {
  const _BlocEpreuve({required this.epreuve});

  final EpreuveVisible epreuve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langue = langueCourante(context);

    String valeur(double? note, String statutLibelle) =>
        note != null ? '${Formats.note(note, langue)} /20' : statutLibelle;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(YsemTokens.rayonPetit),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(epreuve.libelle,
                    style: theme.textTheme.labelLarge),
              ),
              Text(
                valeur(epreuve.note, epreuve.statutLibelle),
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
          for (final controle in epreuve.controles)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        controle.libelle,
                        Formats.jourMois(controle.date, langue),
                        if (controle.ponderation != null)
                          '×${Formats.coefficient(controle.ponderation!, langue)}',
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(valeur(controle.note, controle.statutLibelle),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CarteReleves extends StatelessWidget {
  const _CarteReleves({required this.releves});

  final List<ReleveDeNotes> releves;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    return CarteYsem(
      titre: t.relevesDeNotes,
      icone: Icons.description_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final releve in releves)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(Icons.article_outlined,
                  color: theme.colorScheme.secondary),
              title: Text(t.releveNumero(releve.numero),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              subtitle: Text([
                if (releve.niveau.isNotEmpty) releve.niveau,
                t.releveEmisLe('${releve.version ?? 1}',
                    Formats.dateLongue(releve.emisLe, langue)),
              ].join(' · ')),
            ),
          const SizedBox(height: 4),
          Text(t.relevesAuGuichet,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
