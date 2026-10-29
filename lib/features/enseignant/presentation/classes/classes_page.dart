import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../application/lectures.dart';
import '../../domain/cours.dart';
import 'classe_page.dart';

/// « Mes classes » : une carte par cours et par cohorte, comme
/// `lecturers:mes_classes` — effectif, créneaux, délégués.
class ClassesPage extends ConsumerWidget {
  const ClassesPage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionClasses)),
      body: VueAsynchrone<MesClasses>(
        valeur: ref.watch(classesProvider),
        surRafraichir: () => ref.refresh(classesProvider.future),
        constructeur: (donnees) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _Synthese(donnees: donnees),
            const SizedBox(height: 16),
            if (donnees.classes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: EtatVide(
                  message: t.aucuneClasse,
                  icone: Icons.groups_outlined,
                ),
              ),
            for (final classe in donnees.classes) ...[
              _CarteClasse(classe: classe),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _Synthese extends StatelessWidget {
  const _Synthese({required this.donnees});

  final MesClasses donnees;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Pastille(t.nbClasses(donnees.nbClasses), ton: TonPastille.marque),
        Pastille(t.nbCours(donnees.nbCours), ton: TonPastille.info),
        Pastille(t.nbEtudiants(donnees.nbEtudiants), ton: TonPastille.info),
        if (donnees.nbSansDelegue > 0)
          Pastille(t.nbSansDelegue(donnees.nbSansDelegue),
              ton: TonPastille.alerte),
      ],
    );
  }
}

class _CarteClasse extends StatelessWidget {
  const _CarteClasse({required this.classe});

  final ClasseEnseignant classe;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final principaux =
        classe.delegues.where((d) => d.principal).map((d) => d.nomComplet);

    return CarteYsem(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ClassePage(cle: classe.cle, titre: classe.intitule(langue)),
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(classe.intitule(langue),
                        style: theme.textTheme.titleMedium),
                    Text(
                      [classe.coursCode, classe.cohorte]
                          .where((s) => s.isNotEmpty)
                          .join(' · '),
                      style: secondaire,
                    ),
                  ],
                ),
              ),
              Pastille(t.nbEtudiants(classe.effectif), ton: TonPastille.marque),
            ],
          ),
          if (classe.classe.isNotEmpty || classe.semestre.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (classe.classe.isNotEmpty) Pastille(classe.classe),
                if (classe.semestre.isNotEmpty) Pastille(classe.semestre),
              ],
            ),
          ],
          if (classe.creneaux.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final c in classe.creneaux)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 16, color: theme.colorScheme.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        [c.jourLibelle, Formats.plage(c.debut, c.fin), c.salle]
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                classe.sansDeleguePrincipal
                    ? Icons.person_off_outlined
                    : Icons.record_voice_over_outlined,
                size: 16,
                color: classe.sansDeleguePrincipal
                    ? YsemTokens.of(context).alerte
                    : theme.colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  classe.sansDeleguePrincipal
                      ? t.sansDeleguePrincipal
                      : t.deleguePrincipal(principaux.join(', ')),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}
