import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/models/champs.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/formulaire.dart';
import '../../../commun/langue.dart';
import '../../../commun/piece_jointe.dart';
import '../../application/lectures.dart';
import '../../domain/documents.dart';

/// Le plan de cours : à lire, ou à saisir tant que le service le laisse ouvert.
///
/// La saisie reste en mémoire jusqu'à « Enregistrer ». **L'IA propose,
/// l'enseignant décide** : une proposition de l'assistant remplit l'écran, et
/// rien n'est écrit au serveur avant l'enregistrement ordinaire.
class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({
    super.key,
    required this.plan,
    this.titre,
    this.pieceAExtraire,
  });

  final int plan;
  final String? titre;

  /// La pièce qu'on vient de déposer : l'extraire est le geste proposé.
  final int? pieceAExtraire;

  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> {
  BrouillonPlan? _brouillon;

  /// Change à chaque rechargement : le champ des objectifs se réinitialise.
  int _version = 0;
  bool _enCours = false;
  bool _proposition = false;
  ApiException? _erreur;
  Map<String, int> _erreursParTable = const {};
  List<String> _manques = const [];

  void _recharger(PlanEnLigne plan) {
    setState(() {
      _brouillon = BrouillonPlan.depuis(plan);
      _version++;
      _proposition = false;
      _erreur = null;
      _erreursParTable = const {};
    });
  }

  Future<void> _rafraichir() async {
    final plan = await ref.refresh(planCoursProvider(widget.plan).future);
    // Un rafraîchissement n'efface jamais une saisie en cours.
    if (mounted && !(_brouillon?.modifie ?? false)) _recharger(plan);
  }

  Future<void> _enregistrer({required bool transmettre}) async {
    final b = _brouillon!;
    final t = AppLocalizations.of(context);
    final messager = ScaffoldMessenger.of(context);
    final navigateur = Navigator.of(context);
    if (transmettre) {
      final ok = await confirmer(
        context,
        titre: t.transmettreLePlan,
        texte: t.transmettrePlanConfirmation,
        action: t.transmettre,
      );
      if (!ok || !mounted) return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
      _manques = const [];
    });
    try {
      final resultat = await ref
          .read(enseignantRepositoryProvider)
          .enregistrerPlan(widget.plan, b.envoi(transmettre: transmettre));
      ref.invalidate(documentsCoursProvider);
      ref.read(menuEnseignantProvider.notifier).rafraichir();
      messager.showSnackBar(SnackBar(content: Text(resultat.detail)));
      if (resultat.transmis) {
        ref.invalidate(planCoursProvider(widget.plan));
        navigateur.pop();
        return;
      }
      // Relu du serveur : un chapitre enregistré devient choisissable.
      final plan = await ref.refresh(planCoursProvider(widget.plan).future);
      if (!mounted) return;
      _recharger(plan);
      setState(() => _manques = resultat.manques);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _erreur = e;
          _erreursParTable = b.poserErreurs(e.donnees);
        });
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _extraire({int? document, PieceAJoindre? fichier}) async {
    final b = _brouillon!;
    final t = AppLocalizations.of(context);
    final messager = ScaffoldMessenger.of(context);
    final navigateur = Navigator.of(context, rootNavigator: true);
    if (b.modifie) {
      final ok = await confirmer(
        context,
        titre: t.remplacerLaSaisie,
        texte: t.remplacerLaSaisieTexte,
        action: t.continuer,
      );
      if (!ok || !mounted) return;
    }
    // La lecture prend souvent une minute : on le dit, et on empêche de quitter.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(t.analyseEnCours)),
            ],
          ),
        ),
      ),
    );
    try {
      final (message, proposition) = await ref
          .read(enseignantRepositoryProvider)
          .importerPlan(widget.plan, document: document, fichier: fichier);
      navigateur.pop();
      if (!mounted) return;
      setState(() {
        b.appliquerProposition(proposition);
        _version++;
        _proposition = true;
        _erreur = null;
        _erreursParTable = const {};
      });
      messager.showSnackBar(SnackBar(content: Text(message)));
    } on ApiException catch (e) {
      navigateur.pop();
      messager.showSnackBar(SnackBar(content: Text(
          e.erreurDuChamp('fichier') ?? e.message)));
    }
  }

  Future<void> _extraireFichier(PlanEnLigne plan) async {
    final t = AppLocalizations.of(context);
    final pieces = await choisirPieces(
      context,
      extensions: plan.extensionsAssistant,
      tailleMax: tailleMaxDocumentAssistant,
      messageTropLourd: t.documentAssistantTropLourd,
    );
    if (pieces.isNotEmpty && mounted) _extraire(fichier: pieces.first);
  }

  Future<void> _editerLigne(
    PlanEnLigne plan,
    String table, {
    LigneBrouillon? ligne,
  }) async {
    final b = _brouillon!;
    final ouverte = plan.saisieOuverte;
    final cleNumero = TablesPlan.cleNumero(table);
    final issue = await showModalBottomSheet<_IssueLigne>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _EditeurLigne(
        description: plan.champsTables[table]!,
        valeurs: ligne?.valeurs ?? {cleNumero: b.prochainNumero(table)},
        erreurs: ligne?.erreurs ?? const {},
        numeroFige: table == TablesPlan.programme,
        cleNumero: cleNumero,
        lectureSeule: !ouverte,
        retirable: ouverte &&
            ligne != null &&
            !(ligne.id == null && ligne.estVierge(cleNumero)),
      ),
    );
    if (issue == null || !mounted) return;
    setState(() {
      if (issue.retirer) {
        if (ligne != null) b.retirer(table, ligne);
      } else if (ligne != null) {
        ligne
          ..valeurs = issue.valeurs!
          ..erreurs = const {};
      } else {
        b.ajouter(table, issue.valeurs!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final valeur = ref.watch(planCoursProvider(widget.plan));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (aQuitte, _) async {
        if (aQuitte) return;
        final navigateur = Navigator.of(context);
        final modifie = _brouillon?.modifie ?? false;
        final ok = !modifie ||
            await confirmer(
              context,
              titre: t.planNonEnregistre,
              texte: t.planNonEnregistreTexte,
              action: t.quitterSansEnregistrer,
            );
        if (ok) navigateur.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.titre ?? t.planDeCours)),
        body: VueAsynchrone<PlanEnLigne>(
          valeur: valeur,
          surRafraichir: _rafraichir,
          constructeur: (plan) {
            _brouillon ??= BrouillonPlan.depuis(plan);
            return _corps(context, plan, _brouillon!);
          },
        ),
      ),
    );
  }

  Widget _corps(BuildContext context, PlanEnLigne plan, BrouillonPlan b) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final erreur = _erreur;

    Widget onglet(String libelle, String? table) {
      final nb = table == null ? 0 : (_erreursParTable[table] ?? 0);
      return Tab(
        child: Badge(
          isLabelVisible: nb > 0,
          label: Text('$nb'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(libelle),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              onglet(t.planGeneral, null),
              onglet(t.chapitres, TablesPlan.chapitres),
              onglet(t.seances, TablesPlan.programme),
              onglet(t.travaux, TablesPlan.travaux),
            ],
          ),
          if (erreur != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: BandeauErreurs(messages: [
                erreur.message,
                ...erreur.erreurs.values.expand((m) => m),
                ...BrouillonPlan.erreursDEnsemble(erreur.donnees),
              ]),
            ),
          Expanded(
            child: TabBarView(
              children: [
                _ongletGeneral(context, plan, b),
                _ongletTable(context, plan, b, TablesPlan.chapitres),
                _ongletTable(context, plan, b, TablesPlan.programme),
                _ongletTable(context, plan, b, TablesPlan.travaux),
              ],
            ),
          ),
          if (plan.saisieOuverte)
            Material(
              elevation: 6,
              color: theme.colorScheme.surface,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        t.seancesProgrammeesSur(
                            b.seancesRemplies, plan.nbSeancesAttendues),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: _enCours
                                  ? null
                                  : () => _enregistrer(transmettre: false),
                              child: Text(t.enregistrer),
                            ),
                          ),
                          if (plan.modifiable) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: _enCours
                                    ? null
                                    : () => _enregistrer(transmettre: true),
                                child: Text(t.transmettre),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ongletGeneral(
      BuildContext context, PlanEnLigne plan, BrouillonPlan b) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final manques = _manques.isNotEmpty ? _manques : const <String>[];
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Pastille(plan.statutLibelle,
              ton: plan.statut == StatutsPlan.valide
                  ? TonPastille.succes
                  : plan.statut == StatutsPlan.propose
                      ? TonPastille.info
                      : TonPastille.neutre),
        ),
        const SizedBox(height: 12),
        if (plan.renvoi != null) ...[
          Encadre(
            titre: t.renvoyePourCorrectionLe(
                Formats.dateLongue(plan.renvoi!.renvoyeLe, langue)),
            texte: '${plan.renvoi!.motif}\n\n${t.planACorrigerConsigne}',
            icone: Icons.reply_rounded,
          ),
          const SizedBox(height: 12),
        ],
        if (plan.saisieExigee && !plan.transmis) ...[
          Encadre(
            titre: t.planAttendu,
            texte: t.planAttenduExplication(plan.nbSeancesAttendues),
            icone: Icons.assignment_late_outlined,
          ),
          const SizedBox(height: 12),
        ],
        if (plan.modificationApresValidation) ...[
          Encadre(
            texte: t.planPublieModifiable,
            icone: Icons.campaign_outlined,
          ),
          const SizedBox(height: 12),
        ],
        if (!plan.saisieOuverte) ...[
          Encadre(
            texte: plan.statut == StatutsPlan.valide
                ? t.planPublieFige
                : t.planTransmisExamine,
            icone: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 12),
        ],
        if (manques.isNotEmpty) ...[
          BandeauErreurs(messages: manques),
          const SizedBox(height: 12),
        ],
        if (_proposition) ...[
          Encadre(
            titre: t.propositionAVerifier,
            texte: t.propositionAVerifierTexte,
            icone: Icons.auto_awesome_rounded,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _recharger(plan),
              child: Text(t.abandonnerLaProposition),
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (plan.assistantDisponible) ...[
          CarteYsem(
            titre: t.remplirDepuisVotreFichier,
            icone: Icons.auto_awesome_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.assistantPlanExplication, style: secondaire),
                const SizedBox(height: 10),
                for (final piece in plan.piecesLisibles) ...[
                  piece.id == widget.pieceAExtraire
                      ? FilledButton.icon(
                          onPressed: () => _extraire(document: piece.id),
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: Text(t.extraireContenuDe(piece.nom)),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => _extraire(document: piece.id),
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: Text(t.extraireContenuDe(piece.nom)),
                        ),
                  const SizedBox(height: 8),
                ],
                OutlinedButton.icon(
                  onPressed: () => _extraireFichier(plan),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(t.analyserUnAutreFichier),
                ),
                if (plan.pagesMax != null) ...[
                  const SizedBox(height: 6),
                  Text(t.planPagesAuPlus(plan.pagesMax!), style: secondaire),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (plan.documentSourceNom.isNotEmpty) ...[
          Text(
            t.documentSourceDuPlan(plan.documentSourceNom,
                Formats.dateLongue(plan.documentSourceLe, langue)),
            style: secondaire,
          ),
          const SizedBox(height: 12),
        ],
        Text(t.objectifsDuCours, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        if (plan.saisieOuverte) ...[
          Text(t.objectifsAide, style: secondaire),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('objectifs-$_version'),
            initialValue: b.objectifs,
            minLines: 4,
            maxLines: 12,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: t.objectifsDuCours,
              alignLabelWithHint: true,
              errorText: _erreur?.erreurDuChamp('objectifs'),
              errorMaxLines: 3,
            ),
            onChanged: (v) => setState(() => b.objectifs = v),
          ),
        ] else
          Text(b.objectifs.isEmpty ? t.aucunObjectif : b.objectifs),
      ],
    );
  }

  Widget _ongletTable(BuildContext context, PlanEnLigne plan, BrouillonPlan b,
      String table) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lignes = b.lignesTriees(table);
    final ajoutable = plan.saisieOuverte && table != TablesPlan.programme;
    final consigne = switch (table) {
      TablesPlan.chapitres => t.chapitresAide,
      TablesPlan.programme => t.programmeAide(plan.nbSeancesAttendues),
      _ => t.travauxAide,
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(consigne,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 10),
        if (lignes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(t.rienPourLeMoment,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium),
          ),
        for (final ligne in lignes) ...[
          _CarteLigne(
            table: table,
            ligne: ligne,
            plan: plan,
            surAppui: ligne.supprimee
                ? null
                : () => _editerLigne(plan, table, ligne: ligne),
            surRestaurer: () => setState(() => ligne.supprimee = false),
          ),
          const SizedBox(height: 8),
        ],
        if (ajoutable) ...[
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () => _editerLigne(plan, table),
            icon: const Icon(Icons.add_rounded),
            label: Text(table == TablesPlan.chapitres
                ? t.ajouterUnChapitre
                : t.ajouterUnTravail),
          ),
        ],
      ],
    );
  }
}

class _CarteLigne extends StatelessWidget {
  const _CarteLigne({
    required this.table,
    required this.ligne,
    required this.plan,
    required this.surAppui,
    required this.surRestaurer,
  });

  final String table;
  final LigneBrouillon ligne;
  final PlanEnLigne plan;
  final VoidCallback? surAppui;
  final VoidCallback surRestaurer;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final l = ligne;
    final (titre, sousTitre) = switch (table) {
      TablesPlan.chapitres => (
          t.chapitreNumero(l['ordre'], l['titre']),
          l['elements_a_traiter'],
        ),
      TablesPlan.programme => (
          t.seanceNumero(int.tryParse(l['numero']) ?? 0),
          l['theme'].isNotEmpty ? l['theme'] : l['contenus'],
        ),
      _ => (
          [l['ordre'], l['intitule']].where((s) => s.isNotEmpty).join('. '),
          l['competences'],
        ),
    };
    final vierge = l.id == null && l.estVierge(TablesPlan.cleNumero(table));
    final erreurs = l.erreurs.values.expand((m) => m).join(' ');
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: surAppui,
        title: Text(
          titre,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            decoration: l.supprimee ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vierge)
              Text(t.seanceARemplir)
            else if (sousTitre.isNotEmpty)
              Text(sousTitre, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (erreurs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(erreurs,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error)),
              ),
          ],
        ),
        trailing: l.supprimee
            ? TextButton(onPressed: surRestaurer, child: Text(t.annuler))
            : plan.saisieOuverte
                ? Icon(Icons.edit_outlined,
                    color: theme.colorScheme.onSurfaceVariant)
                : Icon(Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _IssueLigne {
  const _IssueLigne.valeurs(Map<String, String> this.valeurs) : retirer = false;
  const _IssueLigne.retrait()
      : valeurs = null,
        retirer = true;

  final Map<String, String>? valeurs;
  final bool retirer;
}

/// Une ligne du plan, composée d'après la description du formulaire du web :
/// aucun champ n'est écrit ici en double.
class _EditeurLigne extends StatefulWidget {
  const _EditeurLigne({
    required this.description,
    required this.valeurs,
    required this.erreurs,
    required this.numeroFige,
    required this.cleNumero,
    required this.lectureSeule,
    required this.retirable,
  });

  final DescriptionFormulaire description;
  final Map<String, String> valeurs;
  final Map<String, List<String>> erreurs;
  final bool numeroFige;
  final String cleNumero;
  final bool lectureSeule;
  final bool retirable;

  @override
  State<_EditeurLigne> createState() => _EditeurLigneState();
}

class _EditeurLigneState extends State<_EditeurLigne> {
  /// Les intitulés courts ; le reste des textes se rédige sur plusieurs lignes.
  static const _uneLigne = {'titre', 'theme', 'intitule', 'regroupement'};

  late final _valeurs = Map<String, String>.of(widget.valeurs);
  final _champs = <String, TextEditingController>{};
  bool _tente = false;

  @override
  void dispose() {
    for (final champ in _champs.values) {
      champ.dispose();
    }
    super.dispose();
  }

  TextEditingController _controleur(String nom) => _champs[nom] ??=
      TextEditingController(text: _valeurs[nom] ?? '');

  void _valider() {
    setState(() => _tente = true);
    final incomplet = widget.description.champs.any(
        (c) => c.obligatoire && (_valeurs[c.nom] ?? '').trim().isEmpty);
    if (incomplet) return;
    Navigator.of(context).pop(_IssueLigne.valeurs(_valeurs));
  }

  String? _erreurDe(ChampFormulaire champ) {
    final serveur = widget.erreurs[champ.nom]?.join(' ');
    if (serveur != null && (_valeurs[champ.nom] == widget.valeurs[champ.nom])) {
      return serveur;
    }
    if (_tente && champ.obligatoire && (_valeurs[champ.nom] ?? '').trim().isEmpty) {
      return AppLocalizations.of(context).champObligatoire;
    }
    return null;
  }

  Widget _champ(ChampFormulaire c) {
    final t = AppLocalizations.of(context);
    final actif = !widget.lectureSeule &&
        !(widget.numeroFige && c.nom == widget.cleNumero);
    if (c.choix.isNotEmpty || c.type == 'ModelChoiceField') {
      final valeur = _valeurs[c.nom] ?? '';
      return DropdownButtonFormField<String>(
        initialValue: c.choix.any((o) => o.valeur == valeur) ? valeur : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: c.libelle,
          errorText: _erreurDe(c),
          errorMaxLines: 3,
        ),
        items: [
          if (!c.obligatoire)
            DropdownMenuItem(value: null, child: Text(t.aucun)),
          for (final o in c.choix)
            DropdownMenuItem(
              value: o.valeur,
              child: Text(o.libelle, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: actif
            ? (v) => setState(() => _valeurs[c.nom] = v ?? '')
            : null,
      );
    }
    if (c.type == 'DateField') {
      final maintenant = DateTime.now();
      return ChampDate(
        libelle: c.libelle,
        valeur: DateTime.tryParse(_valeurs[c.nom] ?? ''),
        premiere: DateTime(maintenant.year - 2),
        derniere: DateTime(maintenant.year + 3, 12, 31),
        surChoix: (d) => setState(
            () => _valeurs[c.nom] = d == null ? '' : Formats.iso(d)),
        erreur: _erreurDe(c),
        effacable: !c.obligatoire,
      );
    }
    final nombre = c.type == 'IntegerField' || c.type == 'DecimalField';
    final uneLigne = nombre || _uneLigne.contains(c.nom);
    return TextField(
      controller: _controleur(c.nom),
      enabled: actif,
      minLines: uneLigne ? 1 : 2,
      maxLines: uneLigne ? 1 : 6,
      keyboardType: nombre
          ? TextInputType.numberWithOptions(decimal: c.type == 'DecimalField')
          : uneLigne
              ? TextInputType.text
              : TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: c.libelle,
        helperText: c.aide.isEmpty ? null : c.aide,
        helperMaxLines: 3,
        errorText: _erreurDe(c),
        errorMaxLines: 3,
      ),
      onChanged: (v) => setState(() =>
          _valeurs[c.nom] = nombre ? v.trim().replaceAll(',', '.') : v),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final champ in widget.description.champs) ...[
              _champ(champ),
              const SizedBox(height: 14),
            ],
            if (widget.description.champs.isEmpty)
              for (final MapEntry(:key, :value) in widget.valeurs.entries)
                if (value.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: LectureSimple(cle: key, valeur: value),
                  ),
            if (!widget.lectureSeule) ...[
              FilledButton.icon(
                onPressed: _valider,
                icon: const Icon(Icons.check_rounded),
                label: Text(t.valider),
              ),
              if (widget.retirable) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => Navigator.of(context)
                      .pop(const _IssueLigne.retrait()),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(t.retirerCetteLigne),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Un plan fermé n'apporte aucune description de champs : ses valeurs se lisent
/// telles quelles, sous un intitulé tiré du vocabulaire du plan.
class LectureSimple extends StatelessWidget {
  const LectureSimple({super.key, required this.cle, required this.valeur});

  final String cle;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final libelle = switch (cle) {
      'ordre' || 'numero' => t.numeroAbrege,
      'titre' || 'intitule' => t.intitule,
      'theme' => t.theme,
      'elements_a_traiter' => t.elementsATraiter,
      'competence_visee' => t.competenceVisee,
      'competences' => t.competences,
      'objectifs' => t.objectifsDuCours,
      'contenus' => t.contenus,
      'lectures_preparatoires' => t.lecturePreparatoire,
      'activites_pedagogiques' => t.activiteDominante,
      'date_prevue' => t.datePrevue,
      'date_remise' => t.dateDeRemise,
      'points' => t.bareme,
      _ => null,
    };
    if (libelle == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(libelle,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(valeur, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
