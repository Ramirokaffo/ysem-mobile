import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../application/lectures.dart';
import '../../application/messagerie.dart';
import '../../domain/discussions.dart';
import '../messagerie/messagerie_page.dart';

final _discussionsProvider = FutureProvider.autoDispose<Discussions>(
  (ref) => ref.watch(etudiantRepositoryProvider).discussions(),
);

/// « Discussions de classe » : un groupe par classe (un cours × une cohorte),
/// où se retrouvent l'enseignant du cours et les inscrits qui le suivent.
/// Les membres ne se choisissent pas : ils se lisent dans les emplois du
/// temps. Les discussions passées se relisent sans s'écrire.
class DiscussionsPage extends ConsumerStatefulWidget {
  const DiscussionsPage({super.key, this.titre});

  final String? titre;

  @override
  ConsumerState<DiscussionsPage> createState() => _DiscussionsPageState();
}

class _DiscussionsPageState extends ConsumerState<DiscussionsPage> {
  String _recherche = '';

  Future<void> _ouvrir(ClasseDiscussion classe) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FilPage(
          source: SourceFil.classe(classe.cle), titre: classe.coursIntitule),
    ));
    if (!mounted) return;
    // Le fil a été lu : compteurs de la liste et pastille du menu.
    ref.invalidate(_discussionsProvider);
    ref.invalidate(navigationProvider);
  }

  bool _correspond(ClasseDiscussion c) {
    final q = _recherche.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [c.coursIntitule, c.coursCode, c.cohorte, ...c.enseignants.map((e) => e.nom)]
        .any((texte) => texte.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.titre ?? t.sectionDiscussions)),
      body: VueAsynchrone<Discussions>(
        valeur: ref.watch(_discussionsProvider),
        surRafraichir: () => ref.refresh(_discussionsProvider.future),
        constructeur: (etat) {
          final classes = etat.classes.where(_correspond).toList();
          final passees = etat.passees.where(_correspond).toList();
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (etat.classes.length + etat.passees.length > 4) ...[
                TextField(
                  decoration: InputDecoration(
                    hintText: t.rechercherClasse,
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _recherche = v),
                ),
                const SizedBox(height: 12),
              ],
              if (etat.classes.isEmpty && etat.passees.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EtatVide(
                      message: t.aucuneDiscussion,
                      icone: Icons.groups_outlined),
                ),
              for (final classe in classes) ...[
                _TuileClasse(classe: classe, surOuvrir: () => _ouvrir(classe)),
                const SizedBox(height: 10),
              ],
              if (passees.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(t.discussionsPassees, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(t.discussionsPasseesAide,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                for (final classe in passees) ...[
                  _TuileClasse(
                      classe: classe, surOuvrir: () => _ouvrir(classe)),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TuileClasse extends StatelessWidget {
  const _TuileClasse({required this.classe, required this.surOuvrir});

  final ClasseDiscussion classe;
  final VoidCallback surOuvrir;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final jetons = YsemTokens.of(context);
    final langue = langueCourante(context);
    final dernier = classe.dernierMessage;
    final enLigne = classe.enseignants.any((e) => e.enLigne);
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    String quand() {
      final date = classe.dernierMessageLe?.toLocal();
      if (date == null) return '';
      final aujourdhui = DateUtils.dateOnly(DateTime.now());
      return DateUtils.dateOnly(date) == aujourdhui
          ? DateFormat.Hm(langue).format(date)
          : Formats.jourMois(date, langue);
    }

    return CarteYsem(
      onTap: surOuvrir,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: classe.ouverte
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHigh,
                child: Icon(
                  classe.ouverte ? Icons.groups_rounded : Icons.history_rounded,
                  color: classe.ouverte
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (enLigne)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: jetons.succes,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: theme.colorScheme.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(classe.coursIntitule,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall),
                    ),
                    Text(quand(), style: secondaire),
                  ],
                ),
                Text(
                  [
                    if (classe.cohorte.isNotEmpty) classe.cohorte,
                    if (classe.enseignants.isNotEmpty)
                      classe.enseignants.map((e) => e.nom).join(', '),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: secondaire,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dernier == null
                            ? t.aucunMessagePourLInstant
                            : '${dernier.auteur} : ${dernier.extrait}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: classe.nonLus > 0 ? FontWeight.w700 : null,
                          color: classe.nonLus > 0
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (classe.nonLus > 0) ...[
                      const SizedBox(width: 8),
                      Badge(
                        label: Text('${classe.nonLus}'),
                        backgroundColor: theme.colorScheme.primary,
                        textColor: theme.colorScheme.onPrimary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
