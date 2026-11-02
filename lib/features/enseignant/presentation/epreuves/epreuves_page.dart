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
import '../../../commun/telechargement.dart';
import '../../application/lectures.dart';
import '../../domain/documents.dart';
import '../../domain/epreuves.dart';

/// Ce que dit une épreuve de son état : le délai, puis l'arbitrage du service.
List<(String, TonPastille)> etatDeLaDemande(
    AppLocalizations t, DepotEpreuve d) {
  return [
    if (d.complet)
      (d.statutDelaiLibelle, TonPastille.succes)
    else if (d.enRetard)
      (t.enRetardDeJours(d.joursDeRetard), TonPastille.alerte)
    else
      (t.depotAttendu, TonPastille.neutre),
    if (d.statutValidation == 'accepted')
      (t.sujetsAcceptes, TonPastille.succes)
    else if (d.statutValidation == 'revision')
      (t.aReprendre, TonPastille.alerte),
  ];
}

/// « Mes épreuves d'examen » : les sujets que le service attend.
class EpreuvesPage extends ConsumerWidget {
  const EpreuvesPage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.sectionEpreuves)),
      body: VueAsynchrone<MesEpreuves>(
        valeur: ref.watch(mesEpreuvesProvider),
        surRafraichir: () => ref.refresh(mesEpreuvesProvider.future),
        constructeur: (m) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (m.depots.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EtatVide(
                  message: t.aucuneEpreuveDemandee,
                  icone: Icons.description_outlined,
                ),
              )
            else ...[
              Text(
                t.epreuvesBilan(m.depots.length, m.completes, m.enRetard),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => telechargerEtOuvrir(
                  context,
                  () => ref
                      .read(enseignantRepositoryProvider)
                      .telechargerModelesEpreuves(),
                ),
                icon: const Icon(Icons.folder_zip_outlined),
                label: Text(t.tousMesModeles),
              ),
              const SizedBox(height: 12),
            ],
            for (final d in m.depots) ...[
              CarteYsem(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => DepotEpreuvePage(
                      depot: d.id, titre: d.cours.libelle(langue)),
                )),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(d.cours.libelle(langue),
                        style: theme.textTheme.titleSmall),
                    Text(
                      [d.cohorte, d.campagne.intitule]
                          .where((s) => s.isNotEmpty)
                          .join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final (texte, ton) in etatDeLaDemande(t, d))
                          Pastille(texte, ton: ton),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        t.sujetsCompletsSur(
                            d.sujetsComplets, d.campagne.nbSujetsRequis),
                        if (d.echeance != null)
                          t.aDeposerAvant(
                              Formats.dateLongue(d.echeance, langue)),
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

/// Une épreuve : consignes, puis un bloc par sujet demandé.
class DepotEpreuvePage extends ConsumerStatefulWidget {
  const DepotEpreuvePage({super.key, required this.depot, this.titre});

  final int depot;
  final String? titre;

  @override
  ConsumerState<DepotEpreuvePage> createState() => _DepotEpreuvePageState();
}

class _DepotEpreuvePageState extends ConsumerState<DepotEpreuvePage> {
  bool _enCours = false;

  void _relire() {
    ref.invalidate(mesEpreuvesProvider);
    ref.read(menuEnseignantProvider.notifier).rafraichir();
  }

  Future<void> _retirer(PieceDeDepot piece) async {
    final t = AppLocalizations.of(context);
    final messager = ScaffoldMessenger.of(context);
    final ok = await confirmer(
      context,
      titre: t.retirerCettePiece,
      texte: t.retirerPieceConfirmation(piece.nom),
      action: t.retirer,
    );
    if (!ok || !mounted) return;
    setState(() => _enCours = true);
    try {
      final message = await ref
          .read(enseignantRepositoryProvider)
          .retirerPieceEpreuve(piece.id);
      _relire();
      messager.showSnackBar(SnackBar(content: Text(message)));
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _deposer(
      MesEpreuves m, DepotEpreuve depot, SujetEpreuve sujet) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _DepotSujet(
        depot: depot,
        sujet: sujet,
        formats: m.formatsAcceptes,
        extensions: m.extensionsAcceptees.isEmpty
            ? extensionsDocumentsCours
            : m.extensionsAcceptees,
      ),
    );
    if (message == null || !mounted) return;
    _relire();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.titre ?? t.sectionEpreuves)),
      body: VueAsynchrone<MesEpreuves>(
        valeur: ref.watch(mesEpreuvesProvider),
        surRafraichir: () => ref.refresh(mesEpreuvesProvider.future),
        constructeur: (m) {
          final d = m.depot(widget.depot);
          if (d == null) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: EtatVide(
                    message: t.aucuneEpreuveDemandee,
                    icone: Icons.description_outlined,
                  ),
                ),
              ],
            );
          }
          final secondaire = theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                [d.cohorte, d.campagne.intitule]
                    .where((s) => s.isNotEmpty)
                    .join(' · '),
                style: secondaire,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final (texte, ton) in etatDeLaDemande(t, d))
                    Pastille(texte, ton: ton),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if (d.echeance != null)
                    t.aDeposerAvant(Formats.dateLongue(d.echeance, langue)),
                  if (d.moratoire) t.moratoireAccorde,
                  t.sujetsCompletsSur(
                      d.sujetsComplets, d.campagne.nbSujetsRequis),
                ].join(' · '),
                style: secondaire,
              ),
              const SizedBox(height: 12),
              if (d.motifReprise.isNotEmpty &&
                  d.statutValidation == 'revision') ...[
                Encadre(
                  titre: t.motifDeReprise,
                  texte: d.motifReprise,
                  icone: Icons.reply_rounded,
                ),
                const SizedBox(height: 12),
              ],
              if (d.bilingue) ...[
                Encadre(
                  titre: t.sujetFrancaisAnglais,
                  texte: t.sujetFrancaisAnglaisTexte,
                  icone: Icons.translate_rounded,
                ),
                const SizedBox(height: 12),
              ],
              if (d.campagne.consignes.isNotEmpty) ...[
                Encadre(
                  titre: t.consignesDuService,
                  texte: d.campagne.consignes,
                  icone: Icons.campaign_outlined,
                ),
                const SizedBox(height: 12),
              ],
              for (final sujet in d.sujets) ...[
                _CarteSujet(
                  depot: d,
                  sujet: sujet,
                  actif: !_enCours,
                  surRetrait: _retirer,
                  surDepot: () => _deposer(m, d, sujet),
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

class _CarteSujet extends ConsumerWidget {
  const _CarteSujet({
    required this.depot,
    required this.sujet,
    required this.actif,
    required this.surRetrait,
    required this.surDepot,
  });

  final DepotEpreuve depot;
  final SujetEpreuve sujet;
  final bool actif;
  final ValueChanged<PieceDeDepot> surRetrait;
  final VoidCallback surDepot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = sujet;
    final ouverte = depot.campagne.ouverte;
    final retirable = ouverte && s.modifiable && actif;
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final modeles = depot.modelesDu(s.numero);

    return CarteYsem(
      titre: t.sujetNumero(s.numero),
      icone: Icons.article_outlined,
      action: s.acceptee
          ? Pastille(t.accepte, ton: TonPastille.succes)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (s.intitule.isNotEmpty)
            Text(s.intitule,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          if (s.dureeMinutes != null || s.commentaire.isNotEmpty)
            Text(
              [
                if (s.dureeMinutes != null) Formats.duree(s.dureeMinutes!),
                s.commentaire,
              ].where((v) => v.isNotEmpty).join(' · '),
              style: secondaire,
            ),
          if (modeles.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(t.modeleARemplir, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final m in modeles)
                  ActionChip(
                    avatar: const Icon(Icons.description_outlined, size: 18),
                    label: Text(
                        m.langue == 'en' ? t.anglaisWord : t.francaisWord),
                    onPressed: () => telechargerEtOuvrir(
                      context,
                      () => ref
                          .read(enseignantRepositoryProvider)
                          .telechargerModeleEpreuve(
                              depot.id, m.numero, m.langue),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          if (depot.bilingue && s.versions.isNotEmpty)
            for (final v in s.versions)
              _BlocPieces(
                titre: t.sujetVersion(v.libelle),
                manque: v.exigee ? t.manquantExige : t.nonDepose,
                manqueEnAlerte: v.exigee,
                pieces: v.pieces,
                retirable: retirable,
                surRetrait: surRetrait,
              )
          else
            _BlocPieces(
              titre: t.sujet,
              manque: t.nonDepose,
              manqueEnAlerte: true,
              pieces: s.piecesSujet,
              retirable: retirable,
              surRetrait: surRetrait,
            ),
          _BlocPieces(
            titre: t.corrige,
            manque: depot.campagne.corrigeObligatoire
                ? t.manquantExige
                : t.facultatifPourCetteCampagne,
            manqueEnAlerte: depot.campagne.corrigeObligatoire,
            pieces: s.piecesCorrige,
            retirable: retirable,
            surRetrait: surRetrait,
          ),
          const SizedBox(height: 8),
          if (!s.modifiable)
            _Fermeture(t.sujetAccepteFige)
          else if (!ouverte)
            _Fermeture(t.depotClos)
          else
            FilledButton.tonalIcon(
              onPressed: actif ? surDepot : null,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(s.aSujet ? t.ajouterOuModifier : t.deposerCeSujet),
            ),
        ],
      ),
    );
  }
}

class _Fermeture extends StatelessWidget {
  const _Fermeture(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.lock_outline_rounded,
            size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texte,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      ],
    );
  }
}

/// Les pièces d'une nature : ouvrir, retirer, et ce que dit leur absence.
class _BlocPieces extends ConsumerWidget {
  const _BlocPieces({
    required this.titre,
    required this.manque,
    required this.manqueEnAlerte,
    required this.pieces,
    required this.retirable,
    required this.surRetrait,
  });

  final String titre;
  final String manque;
  final bool manqueEnAlerte;
  final List<PieceDeDepot> pieces;
  final bool retirable;
  final ValueChanged<PieceDeDepot> surRetrait;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              Text(titre, style: theme.textTheme.labelLarge),
              if (pieces.isEmpty)
                Text(
                  manque,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: manqueEnAlerte
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          for (final piece in pieces)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(iconeDeFichier(piece.nom)),
              title: Text(piece.nom,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(tailleLisible(piece.taille, langue)),
              onTap: () => telechargerEtOuvrir(
                context,
                () => ref
                    .read(enseignantRepositoryProvider)
                    .telechargerPieceEpreuve(piece),
              ),
              trailing: retirable
                  ? IconButton(
                      tooltip: t.retirer,
                      onPressed: () => surRetrait(piece),
                      icon: const Icon(Icons.delete_outline_rounded),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}

/// Le dépôt d'un sujet : toutes ses pièces d'un seul envoi, le serveur refusant
/// un sujet laissé sans son corrigé exigé ou sans sa seconde langue. Les pièces
/// choisies s'ajoutent à celles déjà déposées.
class _DepotSujet extends ConsumerStatefulWidget {
  const _DepotSujet({
    required this.depot,
    required this.sujet,
    required this.formats,
    required this.extensions,
  });

  final DepotEpreuve depot;
  final SujetEpreuve sujet;
  final String formats;
  final List<String> extensions;

  @override
  ConsumerState<_DepotSujet> createState() => _DepotSujetState();
}

class _DepotSujetState extends ConsumerState<_DepotSujet> {
  static const _champsAffiches = {'intitule', 'duree_minutes', 'commentaire'};

  late final _intitule = TextEditingController(text: widget.sujet.intitule);
  late final _duree = TextEditingController(
      text: widget.sujet.dureeMinutes?.toString() ?? '');
  late final _commentaire =
      TextEditingController(text: widget.sujet.commentaire);
  List<PieceAJoindre> _sujet = const [];
  List<PieceAJoindre> _sujetEn = const [];
  List<PieceAJoindre> _corrige = const [];
  bool _enCours = false;
  ApiException? _erreur;

  @override
  void dispose() {
    _intitule.dispose();
    _duree.dispose();
    _commentaire.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final message =
          await ref.read(enseignantRepositoryProvider).deposerSujet(
                widget.sujet.id,
                fichiersSujet: _sujet,
                fichiersSujetEn: _sujetEn,
                fichiersCorrige: _corrige,
                intitule: _intitule.text.trim(),
                dureeMinutes: _duree.text.trim(),
                commentaire: _commentaire.text.trim(),
              );
      if (mounted) Navigator.of(context).pop(message);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = e);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  /// Ce que le sujet peut encore recevoir, au regard des dix pièces permises.
  /// Ses deux versions comptent ensemble, comme au serveur.
  int get _restantSujet =>
      (piecesParSujetMax - widget.sujet.piecesSujet.length)
          .clamp(0, piecesParSujetMax);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final erreur = _erreur;
    final bilingue = widget.depot.bilingue;
    final aide = widget.formats.isEmpty
        ? t.piecesSajoutent
        : '${t.piecesSajoutent} ${t.formatsAcceptes(widget.formats)}';
    final restantCorrige =
        (piecesParSujetMax - widget.sujet.piecesCorrige.length)
            .clamp(0, piecesParSujetMax);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.sujetNumero(widget.sujet.numero),
                style: theme.textTheme.titleLarge),
            if (erreur != null) ...[
              const SizedBox(height: 16),
              BandeauErreurs(
                  messages: erreursGlobales(erreur, _champsAffiches)),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _intitule,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.intituleDuSujetFacultatif,
                errorText: erreur?.erreurDuChamp('intitule'),
              ),
            ),
            const SizedBox(height: 16),
            ChampPiecesJointes(
              libelle:
                  bilingue ? t.fichiersSujetFrancais : t.fichiersDuSujet,
              aide: aide,
              pieces: _sujet,
              maximum: _restantSujet,
              extensions: widget.extensions,
              actif: !_enCours,
              surChangement: (p) => setState(() => _sujet = p),
            ),
            if (bilingue) ...[
              const SizedBox(height: 16),
              ChampPiecesJointes(
                libelle: t.fichiersSujetAnglais,
                aide: t.memeSujetTraduit,
                pieces: _sujetEn,
                maximum: (_restantSujet - _sujet.length)
                    .clamp(0, piecesParSujetMax),
                extensions: widget.extensions,
                actif: !_enCours,
                surChangement: (p) => setState(() => _sujetEn = p),
              ),
            ],
            const SizedBox(height: 16),
            ChampPiecesJointes(
              libelle: widget.depot.campagne.corrigeObligatoire
                  ? t.fichiersCorrigeExige
                  : t.fichiersCorrigeFacultatif,
              aide: widget.formats.isEmpty
                  ? null
                  : t.formatsAcceptes(widget.formats),
              pieces: _corrige,
              maximum: restantCorrige,
              extensions: widget.extensions,
              actif: !_enCours,
              surChangement: (p) => setState(() => _corrige = p),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _duree,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t.dureeProposeeMinutes,
                errorText: erreur?.erreurDuChamp('duree_minutes'),
                errorMaxLines: 3,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentaire,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.commentaireFacultatif,
                hintText: t.commentaireSujetAide,
                errorText: erreur?.erreurDuChamp('commentaire'),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _enCours ? null : _envoyer,
              icon: _enCours
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(widget.sujet.aSujet ? t.enregistrer : t.deposer),
            ),
          ],
        ),
      ),
    );
  }
}
