import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/models/devoirs.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../application/lectures.dart';
import 'devoir_enseignant_page.dart';
import 'formulaire_devoir_page.dart';
import 'groupements_page.dart';

/// « Devoirs » : ce que l'enseignant a donné à ses classes, et ce qui attend
/// sa correction. On donne un devoir, ou on compose des groupes, en
/// choisissant d'abord la classe — celle de « Mes classes ».
class DevoirsEnseignantPage extends ConsumerWidget {
  const DevoirsEnseignantPage({super.key, this.titre});

  final String? titre;

  Future<ClasseDevoir?> _choisirClasse(BuildContext context, List<ClasseDevoir> classes) {
    final t = AppLocalizations.of(context);
    return showModalBottomSheet<ClasseDevoir>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (contexte) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(t.devoirsChoisirClasse,
                  style: Theme.of(contexte).textTheme.titleMedium),
            ),
            if (classes.isEmpty)
              Padding(padding: const EdgeInsets.all(16), child: Text(t.devoirsAucuneClasse)),
            for (final classe in classes)
              ListTile(
                title: Text(classe.coursIntitule),
                subtitle: Text(classe.cohorte),
                trailing: Text('${classe.effectif}'),
                onTap: () => Navigator.of(contexte).pop(classe),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final valeur = ref.watch(devoirsEnseignantProvider);
    final etat = valeur.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(titre ?? t.sectionDevoirs),
        actions: [
          if (etat != null)
            IconButton(
              tooltip: t.devoirsGroupesDeTravail,
              icon: const Icon(Icons.groups_outlined),
              onPressed: () async {
                final classe = await _choisirClasse(context, etat.classes);
                if (classe == null || !context.mounted) return;
                await Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => GroupementsPage(classe: classe),
                ));
              },
            ),
        ],
      ),
      floatingActionButton: etat == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final classe = await _choisirClasse(context, etat.classes);
                if (classe == null || !context.mounted) return;
                final id = await Navigator.of(context).push<int>(MaterialPageRoute(
                  builder: (_) => FormulaireDevoirPage(classe: classe, limites: etat.limites),
                ));
                ref.invalidate(devoirsEnseignantProvider);
                if (id != null && context.mounted) {
                  await Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => DevoirEnseignantPage(id: id),
                  ));
                  ref.invalidate(devoirsEnseignantProvider);
                }
              },
              icon: const Icon(Icons.add_task_rounded),
              label: Text(t.devoirsDonner),
            ),
      body: VueAsynchrone<DevoirsEnseignant>(
        valeur: valeur,
        surRafraichir: () => ref.refresh(devoirsEnseignantProvider.future),
        constructeur: (etat) => etat.devoirs.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  EtatVide(message: t.devoirAucun, icone: Icons.assignment_outlined),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: etat.devoirs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, index) => _CarteDevoir(resume: etat.devoirs[index]),
              ),
      ),
    );
  }
}

TonPastille tonDuStatutDevoir(String statut) => switch (statut) {
      'brouillon' => TonPastille.neutre,
      'publie' => TonPastille.info,
      _ => TonPastille.succes,
    };

class _CarteDevoir extends ConsumerWidget {
  const _CarteDevoir({required this.resume});

  final DevoirResume resume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final devoir = resume.devoir;
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return CarteYsem(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => DevoirEnseignantPage(id: devoir.id, titre: devoir.titre),
        ));
        ref.invalidate(devoirsEnseignantProvider);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: Text(devoir.titre, style: theme.textTheme.titleSmall)),
            Pastille(devoir.statutLibelle, ton: tonDuStatutDevoir(devoir.statut)),
          ]),
          const SizedBox(height: 4),
          Text('${devoir.coursIntitule} · ${devoir.cohorte}', style: secondaire),
          if (devoir.dateLimite != null)
            Text(t.devoirARendreAvant(Formats.horodatage(devoir.dateLimite, langue)),
                style: secondaire),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 6, children: [
            Pastille(t.devoirRendusSur('${resume.rendus}', '${resume.attendus}'),
                icone: Icons.inbox_outlined),
            if (resume.aCorriger > 0)
              Pastille(t.devoirACorriger('${resume.aCorriger}'), ton: TonPastille.alerte),
            if (devoir.estDeGroupe)
              Pastille(devoir.groupementNom, icone: Icons.groups_outlined),
          ]),
        ],
      ),
    );
  }
}
