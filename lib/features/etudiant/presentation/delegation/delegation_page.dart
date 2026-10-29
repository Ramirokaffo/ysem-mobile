import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/langue.dart';
import '../../domain/delegation.dart';
import 'appel_page.dart';
import 'cahier_page.dart';

/// Ma délégation, journée par journée (`null` : aujourd'hui).
final delegationProvider =
    FutureProvider.autoDispose.family<Delegation, String?>(
  (ref, jour) => ref.watch(etudiantRepositoryProvider).delegation(jour: jour),
);

/// « Ma délégation » : les séances de la classe pour la journée, avec, pour
/// chacune, l'appel des absents et le cahier de texte. Les deux gestes
/// s'ouvrent autour de la fin du cours ; ce qu'ils constatent ne compte qu'au
/// bout de leur circuit.
class DelegationPage extends ConsumerStatefulWidget {
  const DelegationPage({super.key, this.titre});

  final String? titre;

  @override
  ConsumerState<DelegationPage> createState() => _DelegationPageState();
}

class _DelegationPageState extends ConsumerState<DelegationPage> {
  String? _jour;
  Delegation? _derniere;

  void _allerA(DateTime? jour, Delegation etat) {
    if (jour == null) return;
    setState(() => _jour = jour == etat.aujourdhui ? null : Formats.iso(jour));
  }

  Future<void> _ouvrir(Widget page) async {
    final message = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => page));
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    ref.invalidate(delegationProvider);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final valeur = ref.watch(delegationProvider(_jour));
    if (valeur.hasValue) _derniere = valeur.value;
    final etat = valeur.valueOrNull ?? _derniere;
    final erreur = valeur.error;

    Widget corps;
    if (erreur is ApiException && erreur.code == 'non_delegue') {
      corps = ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          EtatVide(message: erreur.message, icone: Icons.badge_outlined),
        ],
      );
    } else if (etat == null) {
      corps = VueAsynchrone<Delegation>(
        valeur: valeur,
        surRafraichir: () => ref.refresh(delegationProvider(_jour).future),
        constructeur: (_) => const SizedBox.shrink(),
      );
    } else {
      corps = RefreshIndicator(
        onRefresh: () => ref.refresh(delegationProvider(_jour).future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _CarteClasse(etat: etat),
            const SizedBox(height: 12),
            _BarreJour(
              etat: etat,
              chargement: valeur.isLoading,
              surJour: (j) => _allerA(j, etat),
            ),
            if (valeur.isLoading) const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 8),
            if (etat.seances.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: EtatVide(
                    message: t.aucuneSeanceCeJour,
                    icone: Icons.event_available_outlined),
              ),
            for (final seance in etat.seances) ...[
              _CarteSeance(
                seance: seance,
                appelAutorise: etat.appelAutorise,
                cahierAutorise: etat.cahierAutorise,
                surAppel: () => _ouvrir(AppelPage(seance: seance)),
                surCahier: () => _ouvrir(CahierPage(seance: seance)),
              ),
              const SizedBox(height: 10),
            ],
            if (etat.reouvertures.isNotEmpty) ...[
              const SizedBox(height: 12),
              _CarteReouvertures(
                reouvertures: etat.reouvertures,
                surJour: (j) => _allerA(j, etat),
              ),
            ],
            if (etat.membre.principal && etat.assistants.isNotEmpty) ...[
              const SizedBox(height: 16),
              _CarteAssistants(assistants: etat.assistants),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.titre ?? t.sectionDelegation)),
      body: corps,
    );
  }
}

String _libelleCircuit(AppLocalizations t, String? circuit) => switch (circuit) {
      'service' => t.circuitService,
      'enseignant' => t.circuitEnseignant,
      'enseignant_service' => t.circuitEnseignantService,
      _ => t.circuitAutomatique,
    };

class _CarteClasse extends StatelessWidget {
  const _CarteClasse({required this.etat});

  final Delegation etat;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final classe = [
      if (etat.niveau != null) etat.niveau!.libelle(langue),
      if (etat.programme != null) etat.programme!.libelle(langue),
      if (etat.specialite != null) etat.specialite!.libelle(langue),
    ].join(' · ');
    return CarteYsem(
      titre: etat.membre.roleLibelle,
      icone: Icons.badge_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (classe.isNotEmpty) Text(classe, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          if (etat.appelAutorise)
            Text(t.circuitDeLAppel(_libelleCircuit(t, etat.circuitAppel)),
                style: secondaire)
          else
            Text(t.appelNonAutorise, style: secondaire),
          if (etat.cahierAutorise)
            Text(t.circuitDuCahier(_libelleCircuit(t, etat.circuitCahier)),
                style: secondaire),
          if (etat.positionExigee) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Expanded(child: Text(t.positionExigee, style: secondaire)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BarreJour extends StatelessWidget {
  const _BarreJour({
    required this.etat,
    required this.chargement,
    required this.surJour,
  });

  final Delegation etat;
  final bool chargement;
  final ValueChanged<DateTime?> surJour;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    return Row(
      children: [
        IconButton(
          tooltip: t.jourPrecedent,
          onPressed: chargement ? null : () => surJour(etat.veille),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Column(
            children: [
              Text(Formats.jourLong(etat.jour, langue),
                  style: theme.textTheme.titleSmall),
              if (!etat.estAujourdhui)
                TextButton(
                  onPressed: chargement ? null : () => surJour(etat.aujourdhui),
                  child: Text(t.aujourdhui),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: t.jourSuivant,
          onPressed: chargement ? null : () => surJour(etat.lendemain),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

/// L'état d'un geste : pourquoi il n'est pas offert, ou ce qu'il est devenu.
(String, TonPastille) _etatGeste(AppLocalizations t, String etat, Constat? constat) {
  return switch (etat) {
    'ouverte' => constat == null
        ? (t.aFaire, TonPastille.marque)
        : (constat.statutLibelle, Pastille.tonDuStatut(constat.statut)),
    'renvoye' => (t.renvoyeAuDelegue, TonPastille.danger),
    'signe' => (t.signeParEnseignant, TonPastille.succes),
    'valide' => (t.valideParService, TonPastille.succes),
    'a_venir' => (t.fenetreAVenir, TonPastille.info),
    'close' => constat == null
        ? (t.fenetreFermee, TonPastille.neutre)
        : (constat.statutLibelle, Pastille.tonDuStatut(constat.statut)),
    'annulee' => (t.seanceAnnulee, TonPastille.neutre),
    'chomee' => (t.jourChome, TonPastille.neutre),
    'non_tenue' => (t.coursNonTenu, TonPastille.neutre),
    _ => (t.horsPlanning, TonPastille.neutre),
  };
}

class _CarteSeance extends StatelessWidget {
  const _CarteSeance({
    required this.seance,
    required this.appelAutorise,
    required this.cahierAutorise,
    required this.surAppel,
    required this.surCahier,
  });

  final SeanceDelegue seance;
  final bool appelAutorise;
  final bool cahierAutorise;
  final VoidCallback surAppel;
  final VoidCallback surCahier;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    String heure(DateTime? d) =>
        d == null ? '' : DateFormat.Hm(langue).format(d.toLocal());

    Widget geste({
      required String libelle,
      required IconData icone,
      required String etat,
      required Constat? constat,
      required bool ouvert,
      required bool rouvert,
      required VoidCallback surAction,
      DateTime? ouverture,
      DateTime? fermeture,
    }) {
      final (texte, ton) = _etatGeste(t, etat, constat);
      final fenetre = ouverture != null && fermeture != null &&
              (etat == 'a_venir' || etat == 'ouverte')
          ? t.fenetreDeA(heure(ouverture), heure(fermeture))
          : '';
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child:
                      Icon(icone, size: 18, color: theme.colorScheme.secondary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(libelle, style: theme.textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Pastille(texte, ton: ton),
                      if (fenetre.isNotEmpty || rouvert)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            [
                              if (rouvert) t.rouvertParLeService,
                              if (fenetre.isNotEmpty) fenetre,
                            ].join(' · '),
                            style: secondaire,
                          ),
                        ),
                    ],
                  ),
                ),
                if (ouvert)
                  FilledButton.tonal(
                    onPressed: surAction,
                    child: Text(constat == null ? t.faire : t.corriger),
                  ),
              ],
            ),
            if (constat != null && constat.motifRenvoi.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Encadre(
                  icone: Icons.undo_rounded,
                  titre: t.motifDuRenvoi,
                  texte: constat.motifRenvoi,
                ),
              ),
            if (constat != null && constat.motifRejet.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Encadre(
                  icone: Icons.block_rounded,
                  titre: t.motifDuRejet,
                  texte: constat.motifRejet,
                ),
              ),
          ],
        ),
      );
    }

    return CarteYsem(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(Formats.plage(seance.debut, seance.fin),
              style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary)),
          Text(seance.cours.libelle(langue), style: theme.textTheme.titleSmall),
          Text(
            [
              if (seance.salle.isNotEmpty) seance.salle,
              if (seance.enseignant.isNotEmpty) seance.enseignant,
            ].join(' · '),
            style: secondaire,
          ),
          if (seance.troncCommun.isNotEmpty) ...[
            const SizedBox(height: 4),
            Pastille(seance.troncCommun, ton: TonPastille.info),
          ],
          if (appelAutorise)
            geste(
              libelle: t.appel,
              icone: Icons.fact_check_outlined,
              etat: seance.etatAppel,
              constat: seance.appel,
              ouvert: seance.appelOuvert,
              rouvert: seance.appelRouvert,
              surAction: surAppel,
              ouverture: seance.ouverture,
              fermeture: seance.fermeture,
            ),
          if (cahierAutorise && seance.etatCahier.isNotEmpty)
            geste(
              libelle: t.cahierDeTexte,
              icone: Icons.menu_book_outlined,
              etat: seance.etatCahier,
              constat: seance.cahier,
              ouvert: seance.cahierOuvert,
              rouvert: seance.cahierRouvert,
              surAction: surCahier,
              fermeture: seance.cahierFermeture,
            ),
        ],
      ),
    );
  }
}

class _CarteReouvertures extends StatelessWidget {
  const _CarteReouvertures({required this.reouvertures, required this.surJour});

  final List<ReouvertureSeance> reouvertures;
  final ValueChanged<DateTime?> surJour;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final langue = langueCourante(context);
    return CarteYsem(
      titre: t.seancesRouvertes,
      icone: Icons.lock_open_rounded,
      child: Column(
        children: [
          for (final r in reouvertures)
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => surJour(r.date),
              title: Text('${r.gesteLibelle} · ${r.cours.libelle(langue)}'),
              subtitle: Text([
                [Formats.jourCourt(r.date, langue), r.debut ?? '']
                    .where((s) => s.isNotEmpty)
                    .join(' '),
                if (r.jusquAu != null)
                  t.jusquAu(Formats.horodatage(r.jusquAu, langue)),
                if (r.motif.isNotEmpty) r.motif,
              ].join('\n')),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
        ],
      ),
    );
  }
}

/// Le seul droit que le délégué principal tient de sa charge : ouvrir ou
/// refermer l'appel à ses assistants.
class _CarteAssistants extends ConsumerStatefulWidget {
  const _CarteAssistants({required this.assistants});

  final List<MembreDelegation> assistants;

  @override
  ConsumerState<_CarteAssistants> createState() => _CarteAssistantsState();
}

class _CarteAssistantsState extends ConsumerState<_CarteAssistants> {
  final Map<int, bool> _valeurs = {};
  final Set<int> _envoi = {};

  Future<void> _basculer(MembreDelegation assistant, bool valeur) async {
    final messager = ScaffoldMessenger.of(context);
    setState(() {
      _valeurs[assistant.id] = valeur;
      _envoi.add(assistant.id);
    });
    try {
      final message = await ref
          .read(etudiantRepositoryProvider)
          .autoriserAssistant(assistant.id, peutFaireAppel: valeur);
      messager.showSnackBar(SnackBar(content: Text(message)));
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
      if (mounted) setState(() => _valeurs[assistant.id] = !valeur);
    } finally {
      if (mounted) setState(() => _envoi.remove(assistant.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return CarteYsem(
      titre: t.mesAssistants,
      icone: Icons.group_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.assistantsAide,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          for (final a in widget.assistants)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(a.nom),
              subtitle: Text(a.matricule),
              value: _valeurs[a.id] ?? a.peutFaireAppel,
              onChanged:
                  _envoi.contains(a.id) ? null : (v) => _basculer(a, v),
            ),
        ],
      ),
    );
  }
}
