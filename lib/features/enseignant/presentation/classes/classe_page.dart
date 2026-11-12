import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/models/devoirs.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/fil/fil.dart';
import '../../../commun/fil/fil_page.dart';
import '../../../commun/telechargement.dart';
import '../../application/lectures.dart';
import '../../domain/cours.dart';
import '../devoirs/devoir_enseignant_page.dart';
import '../devoirs/devoirs_enseignant_page.dart';
import '../devoirs/formulaire_devoir_page.dart';
import '../devoirs/groupements_page.dart';

ClasseDevoir _classeDevoir(DetailClasse detail) => ClasseDevoir(
      cle: detail.cleDiscussion,
      coursIntitule: detail.classe.coursIntitule,
      cohorte: detail.classe.cohorte,
      effectif: detail.effectif,
    );

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

  /// Donner un devoir à la classe, puis ouvrir sa fiche — comme depuis
  /// « Devoirs ».
  Future<void> _donnerUnDevoir(DetailClasse detail) async {
    final limites = ref.read(devoirsDeClasseProvider(detail.cleDiscussion)).valueOrNull?.limites;
    final id = await Navigator.of(context).push<int>(MaterialPageRoute(
      builder: (_) => FormulaireDevoirPage(
        classe: _classeDevoir(detail),
        limites: limites ?? const LimitesPieces(),
      ),
    ));
    ref.invalidate(devoirsDeClasseProvider(detail.cleDiscussion));
    if (id == null || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => DevoirEnseignantPage(id: id),
    ));
    ref.invalidate(devoirsDeClasseProvider(detail.cleDiscussion));
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
              const SizedBox(height: 12),
              if (detail.cleDiscussion.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => FilPage(
                      source: SourceFil.classeEnseignant(detail.cleDiscussion),
                      titre: widget.titre,
                    ),
                  )),
                  icon: const Icon(Icons.forum_outlined),
                  label: Text(t.discussionDeLaClasse),
                ),
                const SizedBox(height: 8),
                // Même clé que la discussion : celle de la classe pour les
                // devoirs et les groupes de travail.
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _donnerUnDevoir(detail),
                      icon: const Icon(Icons.add_task_rounded),
                      label: Text(t.devoirsDonner),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => GroupementsPage(classe: _classeDevoir(detail)),
                      )),
                      icon: const Icon(Icons.groups_outlined),
                      label: Text(t.devoirsGroupesDeTravail),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _DevoirsDeLaClasse(cle: detail.cleDiscussion),
                const SizedBox(height: 16),
              ],
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

/// Les devoirs déjà donnés à la classe, du plus récent au plus ancien
/// (l'ordre du serveur). Une erreur de lecture ne masque pas la fiche.
class _DevoirsDeLaClasse extends ConsumerWidget {
  const _DevoirsDeLaClasse({required this.cle});

  final String cle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final devoirs = ref.watch(devoirsDeClasseProvider(cle)).valueOrNull?.devoirs;
    if (devoirs == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.devoirsDeLaClasse, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (devoirs.isEmpty)
          Text(t.devoirsAucunDeLaClasse,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (final (i, resume) in devoirs.indexed) ...[
                if (i > 0) const Divider(indent: 16, endIndent: 16),
                ListTile(
                  title: Text(resume.devoir.titre, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(t.devoirRendusSur('${resume.rendus}', '${resume.attendus}')),
                  trailing: resume.aCorriger > 0
                      ? Pastille(t.devoirACorriger('${resume.aCorriger}'), ton: TonPastille.alerte)
                      : Pastille(resume.devoir.statutLibelle,
                          ton: tonDuStatutDevoir(resume.devoir.statut)),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => DevoirEnseignantPage(id: resume.devoir.id, titre: resume.devoir.titre),
                    ));
                    ref.invalidate(devoirsDeClasseProvider(cle));
                  },
                ),
              ],
            ]),
          ),
      ],
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
