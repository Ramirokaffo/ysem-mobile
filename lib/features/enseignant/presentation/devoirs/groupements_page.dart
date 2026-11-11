import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/models/devoirs.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/lectures.dart';

/// Les groupements de travail d'une classe — « Groupes d'exposé », « Groupes
/// de TP » —, réutilisables d'un devoir à l'autre.
class GroupementsPage extends ConsumerWidget {
  const GroupementsPage({super.key, required this.classe});

  final ClasseDevoir classe;

  Future<void> _creer(BuildContext context, WidgetRef ref) async {
    final groupement = await showModalBottomSheet<Groupement>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NouveauGroupement(classe: classe),
    );
    ref.invalidate(groupementsProvider(classe.cle));
    if (groupement != null && context.mounted) {
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => GroupementPage(id: groupement.id, titre: groupement.nom),
      ));
      ref.invalidate(groupementsProvider(classe.cle));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.devoirsGroupesDeTravail)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _creer(context, ref),
        icon: const Icon(Icons.group_add_outlined),
        label: Text(t.groupementNouveau),
      ),
      body: VueAsynchrone<List<Groupement>>(
        valeur: ref.watch(groupementsProvider(classe.cle)),
        surRafraichir: () => ref.refresh(groupementsProvider(classe.cle).future),
        constructeur: (groupements) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Text(classe.libelle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            if (groupements.isEmpty)
              EtatVide(message: t.groupementAucun, icone: Icons.groups_outlined),
            for (final groupement in groupements) ...[
              CarteYsem(
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => GroupementPage(id: groupement.id, titre: groupement.nom),
                  ));
                  ref.invalidate(groupementsProvider(classe.cle));
                },
                child: Row(children: [
                  Expanded(
                      child: Text(groupement.nom, style: Theme.of(context).textTheme.titleSmall)),
                  Pastille(t.groupementNbGroupes('${groupement.groupes.length}'),
                      icone: Icons.groups_outlined),
                ]),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _NouveauGroupement extends ConsumerStatefulWidget {
  const _NouveauGroupement({required this.classe});

  final ClasseDevoir classe;

  @override
  ConsumerState<_NouveauGroupement> createState() => _NouveauGroupementState();
}

class _NouveauGroupementState extends ConsumerState<_NouveauGroupement> {
  final _nom = TextEditingController();
  final _valeur = TextEditingController(text: '4');
  String _tirage = '';
  bool _envoi = false;

  @override
  void dispose() {
    _nom.dispose();
    _valeur.dispose();
    super.dispose();
  }

  Future<void> _creer() async {
    setState(() => _envoi = true);
    try {
      final groupement = await ref.read(enseignantRepositoryProvider).creerGroupement(
            classe: widget.classe.cle,
            nom: _nom.text.trim(),
            tirage: _tirage,
            valeur: int.tryParse(_valeur.text.trim()),
          );
      if (mounted) Navigator.of(context).pop(groupement);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _envoi = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(t.groupementNouveau, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _nom,
              enabled: !_envoi,
              decoration: InputDecoration(labelText: t.groupementNom),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _tirage,
              decoration: InputDecoration(labelText: t.groupementComposition),
              items: [
                DropdownMenuItem(value: '', child: Text(t.groupementTirageAucun)),
                DropdownMenuItem(value: 'nombre', child: Text(t.groupementTirageNombre)),
                DropdownMenuItem(value: 'taille', child: Text(t.groupementTirageTaille)),
              ],
              onChanged: _envoi ? null : (v) => setState(() => _tirage = v ?? ''),
            ),
            if (_tirage.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _valeur,
                enabled: !_envoi,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: t.groupementNombre),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _envoi ? null : _creer,
              icon: const Icon(Icons.check_rounded),
              label: Text(t.groupementCreer),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un groupement : ses groupes et la composition — le groupe de chaque
/// inscrit, ou un tirage au sort.
class GroupementPage extends ConsumerStatefulWidget {
  const GroupementPage({super.key, required this.id, this.titre});

  final int id;
  final String? titre;

  @override
  ConsumerState<GroupementPage> createState() => _GroupementPageState();
}

class _GroupementPageState extends ConsumerState<GroupementPage> {
  /// Composition en cours d'édition (étudiant → groupe), vide tant que rien
  /// n'a été touché.
  final Map<int, int?> _modifs = {};
  bool _envoi = false;

  Future<void> _geste(Map<String, dynamic> donnees) async {
    setState(() => _envoi = true);
    try {
      await ref.read(enseignantRepositoryProvider).gesteGroupement(widget.id, donnees);
      _modifs.clear();
      ref.invalidate(groupementProvider(widget.id));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
    if (mounted) setState(() => _envoi = false);
  }

  Future<String?> _demanderNom(String titre, {String initial = ''}) {
    final controleur = TextEditingController(text: initial);
    final t = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      builder: (contexte) => AlertDialog(
        title: Text(titre),
        content: TextField(controller: controleur, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(contexte).pop(), child: Text(t.annuler)),
          FilledButton(
              onPressed: () => Navigator.of(contexte).pop(controleur.text.trim()),
              child: Text(t.enregistrer)),
        ],
      ),
    );
  }

  Future<void> _tirer() async {
    final t = AppLocalizations.of(context);
    var tirage = 'nombre';
    final valeur = TextEditingController(text: '4');
    final ok = await showDialog<bool>(
      context: context,
      builder: (contexte) => StatefulBuilder(
        builder: (contexte, majour) => AlertDialog(
          title: Text(t.groupementTirer),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(t.groupementTirerAide, style: Theme.of(contexte).textTheme.bodySmall),
            DropdownButton<String>(
              value: tirage,
              isExpanded: true,
              items: [
                DropdownMenuItem(value: 'nombre', child: Text(t.groupementTirageNombre)),
                DropdownMenuItem(value: 'taille', child: Text(t.groupementTirageTaille)),
              ],
              onChanged: (v) => majour(() => tirage = v ?? tirage),
            ),
            TextField(
              controller: valeur,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t.groupementNombre),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.of(contexte).pop(false), child: Text(t.annuler)),
            FilledButton(onPressed: () => Navigator.of(contexte).pop(true), child: Text(t.groupementTirer)),
          ],
        ),
      ),
    );
    if (ok == true) {
      await _geste({'action': 'tirer', 'tirage': tirage, 'valeur': int.tryParse(valeur.text.trim())});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final valeur = ref.watch(groupementProvider(widget.id));
    final groupement = valeur.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(groupement?.nom ?? widget.titre ?? t.devoirsGroupesDeTravail),
        actions: [
          if (groupement != null && !groupement.compositionFigee)
            IconButton(
              tooltip: t.groupementTirer,
              icon: const Icon(Icons.shuffle_rounded),
              onPressed: _envoi ? null : _tirer,
            ),
          if (groupement != null)
            PopupMenuButton<String>(
              onSelected: (choix) async {
                if (choix == 'renommer') {
                  final nom = await _demanderNom(t.groupementRenommer, initial: groupement.nom);
                  if (nom != null && nom.isNotEmpty) await _geste({'action': 'renommer', 'nom': nom});
                } else if (choix == 'supprimer') {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (contexte) => AlertDialog(
                      content: Text(t.groupementSupprimerConfirmer),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(contexte).pop(false), child: Text(t.annuler)),
                        FilledButton(onPressed: () => Navigator.of(contexte).pop(true), child: Text(t.supprimer)),
                      ],
                    ),
                  );
                  if (ok != true || !context.mounted) return;
                  try {
                    await ref.read(enseignantRepositoryProvider).supprimerGroupement(widget.id);
                    if (context.mounted) Navigator.of(context).pop();
                  } on ApiException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'renommer', child: Text(t.groupementRenommer)),
                if (groupement.nbDevoirs == 0)
                  PopupMenuItem(value: 'supprimer', child: Text(t.supprimer)),
              ],
            ),
        ],
      ),
      floatingActionButton: _modifs.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _envoi
                  ? null
                  : () => _geste({
                        'action': 'composer',
                        'affectations': {
                          for (final MapEntry(key: etudiant, value: groupe) in _modifs.entries)
                            '$etudiant': groupe,
                        },
                      }),
              icon: const Icon(Icons.save_rounded),
              label: Text(t.groupementEnregistrerComposition),
            ),
      body: VueAsynchrone<Groupement>(
        valeur: valeur,
        surRafraichir: () => ref.refresh(groupementProvider(widget.id).future),
        constructeur: (groupement) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Text('${groupement.coursIntitule} · ${groupement.cohorte}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            for (final groupe in groupement.groupes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.groups_outlined),
                title: Text(groupe.nom),
                subtitle: Text(groupe.membres.isEmpty
                    ? t.groupeAucunMembre
                    : groupe.membres.map((m) => m.nomComplet).join(', ')),
                trailing: PopupMenuButton<String>(
                  onSelected: (choix) async {
                    if (choix == 'renommer') {
                      final nom = await _demanderNom(t.groupeNom, initial: groupe.nom);
                      if (nom != null && nom.isNotEmpty) {
                        await _geste({'action': 'renommer_groupe', 'groupe': groupe.id, 'nom': nom});
                      }
                    } else {
                      await _geste({'action': 'supprimer_groupe', 'groupe': groupe.id});
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'renommer', child: Text(t.groupementRenommer)),
                    PopupMenuItem(value: 'supprimer', child: Text(t.supprimer)),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: _envoi
                  ? null
                  : () async {
                      final nom = await _demanderNom(t.groupementAjouterGroupe);
                      if (nom != null) await _geste({'action': 'ajouter_groupe', 'nom': nom});
                    },
              icon: const Icon(Icons.add_rounded),
              label: Text(t.groupementAjouterGroupe),
            ),
            const Divider(height: 32),
            Text(t.groupementComposition, style: Theme.of(context).textTheme.titleMedium),
            if (groupement.compositionFigee)
              Text(t.groupementCompositionFigee, style: Theme.of(context).textTheme.bodySmall),
            if (!groupement.compositionFigee && groupement.groupes.isNotEmpty)
              for (final (etudiant, groupeId) in groupement.etudiants)
                Row(children: [
                  Expanded(child: Text(etudiant.nomComplet)),
                  DropdownButton<int?>(
                    value: _modifs.containsKey(etudiant.id) ? _modifs[etudiant.id] : groupeId,
                    items: [
                      DropdownMenuItem<int?>(value: null, child: Text(t.groupementAucunGroupe)),
                      for (final groupe in groupement.groupes)
                        DropdownMenuItem<int?>(value: groupe.id, child: Text(groupe.nom)),
                    ],
                    onChanged: _envoi ? null : (v) => setState(() => _modifs[etudiant.id] = v),
                  ),
                ]),
          ],
        ),
      ),
    );
  }
}
