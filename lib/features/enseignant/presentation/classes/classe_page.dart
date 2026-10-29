import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/telechargement.dart';
import '../../application/lectures.dart';
import '../../domain/cours.dart';

/// La liste d'une classe : effectif, délégués et leurs coordonnées — le point
/// de contact de la classe —, puis les inscrits et leurs manquements sur ce
/// cours. C'est la liste d'appel que l'enseignant tenait sur papier, celle
/// qui reçoit l'emploi du temps et figure sur la feuille de notes.
class ClassePage extends ConsumerStatefulWidget {
  const ClassePage({super.key, required this.cle, this.titre});

  final String cle;
  final String? titre;

  @override
  ConsumerState<ClassePage> createState() => _ClassePageState();
}

class _ClassePageState extends ConsumerState<ClassePage> {
  String _recherche = '';

  bool _retenu(EtudiantDeClasse e) {
    final q = _recherche.trim().toLowerCase();
    if (q.isEmpty) return true;
    return e.nomComplet.toLowerCase().contains(q) ||
        e.matricule.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titre ?? t.sectionClasses),
        actions: [
          IconButton(
            tooltip: t.exporterLaListe,
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => telechargerEtOuvrir(
              context,
              () => ref
                  .read(enseignantRepositoryProvider)
                  .exporterClasse(widget.cle),
            ),
          ),
        ],
      ),
      body: VueAsynchrone<DetailClasse>(
        valeur: ref.watch(detailClasseProvider(widget.cle)),
        surRafraichir: () =>
            ref.refresh(detailClasseProvider(widget.cle).future),
        constructeur: (detail) {
          final etudiants = detail.etudiants.where(_retenu).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _EnTete(detail: detail),
              const SizedBox(height: 16),
              _Delegues(delegues: detail.classe.delegues),
              const SizedBox(height: 16),
              Text(t.listeDesInscrits,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: t.rechercherEtudiant,
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _recherche = v),
              ),
              const SizedBox(height: 8),
              if (etudiants.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: EtatVide(
                    message: detail.etudiants.isEmpty
                        ? t.aucunInscrit
                        : t.aucunEtudiantTrouve,
                    icone: Icons.person_search_outlined,
                  ),
                )
              else
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final (i, e) in etudiants.indexed) ...[
                        if (i > 0) const Divider(indent: 16, endIndent: 16),
                        _TuileEtudiant(etudiant: e),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EnTete extends StatelessWidget {
  const _EnTete({required this.detail});

  final DetailClasse detail;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final classe = detail.classe;

    Widget chiffre(String valeur, String libelle) => Expanded(
          child: Column(
            children: [
              Text(valeur,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: theme.colorScheme.primary)),
              Text(libelle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        );

    return CarteYsem(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            [classe.coursCode, classe.cohorte, classe.classe]
                .where((s) => s.isNotEmpty)
                .join(' · '),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              chiffre('${detail.effectif}', t.inscrits),
              chiffre('${detail.nbFemmes} / ${detail.nbHommes}', t.femmesHommes),
              chiffre('${detail.nbReleves}', t.seancesRelevees),
              chiffre('${detail.nbAbsents}', t.etudiantsAbsents),
            ],
          ),
          if (detail.planStatutLibelle.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.description_outlined,
                    size: 18, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(t.planDeCoursStatut(detail.planStatutLibelle),
                        style: theme.textTheme.bodySmall)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Delegues extends StatelessWidget {
  const _Delegues({required this.delegues});

  final List<DelegueDeClasse> delegues;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return CarteYsem(
      titre: t.deleguesDeLaClasse,
      icone: Icons.record_voice_over_outlined,
      child: delegues.isEmpty
          ? EtatVide(message: t.aucunDelegue, icone: Icons.person_off_outlined)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final d in delegues)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: d.principal
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHigh,
                          child: Icon(Icons.person_rounded,
                              size: 20,
                              color: d.principal
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.nomComplet,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              Text(
                                [d.roleLibelle, d.precision]
                                    .where((s) => s.isNotEmpty)
                                    .join(' · '),
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                              if (d.telephone.isNotEmpty)
                                SelectableText(d.telephone,
                                    style: theme.textTheme.bodySmall),
                              if (d.email.isNotEmpty)
                                SelectableText(d.email,
                                    style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _TuileEtudiant extends StatelessWidget {
  const _TuileEtudiant({required this.etudiant});

  final EtudiantDeClasse etudiant;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final e = etudiant;
    final manquements = [
      if (e.absences > 0) t.nbAbsences(e.absences),
      if (e.retards > 0) t.nbRetards(e.retards),
    ].join(' · ');

    return ListTile(
      dense: true,
      title: Text(e.nomComplet,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w700)),
      subtitle: Text(
          [e.matricule, manquements].where((s) => s.isNotEmpty).join(' · ')),
      trailing: e.delegation.isEmpty
          ? (e.absencesNonJustifiees > 0
              ? Pastille(t.nbNonJustifiees(e.absencesNonJustifiees),
                  ton: TonPastille.alerte)
              : null)
          : Pastille(t.delegue, ton: TonPastille.marque),
    );
  }
}
