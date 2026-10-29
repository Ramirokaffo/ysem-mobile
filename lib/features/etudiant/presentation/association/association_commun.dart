import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/format/texte_html.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../domain/association.dart';

/// Couleur d'une liste (`#RRGGBB`), ou celle de la marque à défaut.
Color couleurDeListe(BuildContext context, String couleur) {
  final hex = couleur.replaceAll('#', '');
  final valeur = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
  return valeur == null
      ? Theme.of(context).colorScheme.primary
      : Color(valeur);
}

/// Pastille d'initiales d'une liste, à sa couleur.
class InitialesListe extends StatelessWidget {
  const InitialesListe({super.key, required this.liste, this.rayon = 22});

  final ListeCandidate liste;
  final double rayon;

  @override
  Widget build(BuildContext context) {
    final couleur = couleurDeListe(context, liste.couleur);
    final mots = liste.nom.split(RegExp(r'\s+')).where((m) => m.isNotEmpty);
    final initiales = mots.take(2).map((m) => m[0].toUpperCase()).join();
    return CircleAvatar(
      radius: rayon,
      backgroundColor: couleur,
      child: Text(initiales,
          style: TextStyle(
              color: couleur.computeLuminance() > 0.5
                  ? Colors.black
                  : Colors.white,
              fontWeight: FontWeight.w800)),
    );
  }
}

/// Le dépouillement : participation, puis une barre par liste. Les mêmes
/// nombres que l'écran du service, au même instant.
class CarteResultats extends StatelessWidget {
  const CarteResultats({super.key, required this.resultats, this.enDirect = false});

  final Resultats resultats;
  final bool enDirect;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final jetons = YsemTokens.of(context);
    final langue = langueCourante(context);

    return CarteYsem(
      titre: resultats.voteTermine ? t.resultats : t.depouillement,
      icone: Icons.bar_chart_rounded,
      action: enDirect
          ? Pastille(t.enDirect, ton: TonPastille.danger, icone: Icons.circle)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.participation(
              Formats.coefficient(resultats.participation, langue),
              resultats.votants,
              resultats.inscrits,
            ),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          for (final ligne in resultats.lignes) ...[
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: ligne.nom,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (ligne.candidat.isNotEmpty)
                        TextSpan(
                            text: ' · ${ligne.candidat}',
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant)),
                    ]),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (resultats.elu == ligne.liste)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Pastille(t.elu,
                        ton: TonPastille.succes,
                        icone: Icons.emoji_events_rounded),
                  ),
                const SizedBox(width: 8),
                Text(
                  '${t.nbVoix(ligne.voix)} · ${Formats.coefficient(ligne.part, langue)} %',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (ligne.part / 100).clamp(0, 1),
                minHeight: 10,
                color: couleurDeListe(context, ligne.couleur),
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (resultats.ballottage)
            Encadre(
                icone: Icons.balance_rounded,
                texte: t.ballottage),
          if (resultats.lignes.isEmpty)
            Text(t.aucunSuffrage,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: jetons.neutre)),
        ],
      ),
    );
  }
}

/// Une liste candidate : candidat, slogan, équipe, et le programme à lire.
class CarteListe extends StatelessWidget {
  const CarteListe({super.key, required this.liste, required this.lireProgramme});

  final ListeCandidate liste;
  final Future<ListeCandidate> Function() lireProgramme;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return CarteYsem(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InitialesListe(liste: liste),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(liste.nom, style: theme.textTheme.titleSmall),
                    if (liste.candidat.isNotEmpty)
                      Text(t.candidat(liste.candidat), style: secondaire),
                  ],
                ),
              ),
            ],
          ),
          if (liste.slogan.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('« ${liste.slogan} »',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontStyle: FontStyle.italic)),
          ],
          if (liste.membres.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final m in liste.membres)
              Text('${m.posteLibelle} : ${m.nom}', style: secondaire),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    ProgrammePage(liste: liste, lire: lireProgramme),
              )),
              icon: const Icon(Icons.article_outlined),
              label: Text(t.lireLeProgramme),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le programme d'une liste, en entier.
class ProgrammePage extends ConsumerStatefulWidget {
  const ProgrammePage({super.key, required this.liste, required this.lire});

  final ListeCandidate liste;
  final Future<ListeCandidate> Function() lire;

  @override
  ConsumerState<ProgrammePage> createState() => _ProgrammePageState();
}

class _ProgrammePageState extends ConsumerState<ProgrammePage> {
  late Future<ListeCandidate> _liste = widget.lire();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.liste.nom)),
      body: FutureBuilder<ListeCandidate>(
        future: _liste,
        builder: (context, instantane) {
          if (instantane.hasError) {
            return EtatErreur(
              erreur: instantane.error!,
              surReessayer: () => setState(() => _liste = widget.lire()),
            );
          }
          final liste = instantane.data;
          if (liste == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final programme = texteDuHtml(liste.programme ?? '');
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Row(
                children: [
                  InitialesListe(liste: liste, rayon: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(liste.nom, style: theme.textTheme.titleLarge),
                        if (liste.candidat.isNotEmpty)
                          Text(t.candidat(liste.candidat),
                              style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              if (liste.slogan.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('« ${liste.slogan} »',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 20),
              Text(t.programmeDeLaListe, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (programme.isEmpty)
                Text(t.programmeNonRedige,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant))
              else
                SelectableText(programme, style: theme.textTheme.bodyMedium),
              if (liste.membres.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(t.equipe, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final m in liste.membres)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline_rounded),
                    title: Text(m.nom),
                    subtitle: Text(m.posteLibelle),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
