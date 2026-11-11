import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../app/router.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/models/etudiant.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/auth/espace.dart';
import '../../../commun/avatar_etudiant.dart';
import '../../../commun/compte/cartes_compte.dart';
import '../../../commun/formulaire.dart';
import '../../../commun/piece_jointe.dart';
import '../../../commun/langue.dart';
import '../../application/lectures.dart';
import '../../domain/modeles.dart';
import 'edition_profil_page.dart';

/// Profil de l'étudiant : identité connue de la scolarité, sécurité du
/// compte, langue et déconnexion.
///
/// Deux portes s'y ouvrent quand la scolarité le décide
/// (`student_portal.profil`) : les informations de base, étudiant par
/// étudiant, et la photo, pour tous à la fois.
class ProfilPage extends ConsumerWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: VueAsynchrone<Profil>(
        valeur: ref.watch(profilProvider),
        surRafraichir: () => ref.refresh(profilProvider.future),
        constructeur: (profil) => ListView(
          padding: EdgeInsets.zero,
          children: [
            _Bandeau(profil: profil),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CarteInformations(profil: profil),
                  const SizedBox(height: 16),
                  if (profil.modification.profilAutorise ||
                      !profil.pere.estVide ||
                      !profil.mere.estVide) ...[
                    _CarteParents(profil: profil),
                    const SizedBox(height: 16),
                  ],
                  CarteSecurite(
                    espace: Espace.etudiant,
                    active: profil.etudiant.doubleAuthentification,
                    routeMotDePasse: Routes.motDePasseEtudiant,
                    apresChangement: () => ref.invalidate(profilProvider),
                  ),
                  const SizedBox(height: 16),
                  CarteLangue(
                    espace: Espace.etudiant,
                    apresChangement: () {
                      ref.invalidate(profilProvider);
                      ref.invalidate(tableauDeBordProvider);
                      ref.invalidate(navigationProvider);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (profil.connexionsRecentes.isNotEmpty) ...[
                    _CarteConnexions(connexions: profil.connexionsRecentes),
                    const SizedBox(height: 24),
                  ],
                  const BoutonDeconnexion(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bandeau extends StatelessWidget {
  const _Bandeau({required this.profil});

  final Profil profil;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langue = langueCourante(context);
    final etudiant = profil.etudiant;
    final cohorte = profil.inscriptionCourante?.resume(langue) ?? '';
    return BandeauMarque(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 24,
        20,
        28,
      ),
      // Pleine largeur : le bandeau pose son contenu dans un `Stack`, qui
      // le laisserait se rétrécir contre le bord gauche.
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            if (profil.modification.photoAutorisee)
              _PhotoModifiable(etudiant: etudiant)
            else
              AvatarEtudiant(etudiant: etudiant, rayon: 44),
            const SizedBox(height: 14),
            Text(
              etudiant.nomComplet,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              etudiant.matricule,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
                letterSpacing: 0.4,
              ),
            ),
            if (cohorte.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                cohorte,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CarteInformations extends StatelessWidget {
  const _CarteInformations({required this.profil});

  final Profil profil;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final langue = langueCourante(context);
    final e = profil.etudiant;
    final residence = [
      profil.quartierResidence,
      profil.villeResidence,
    ].where((s) => s.isNotEmpty).join(', ');
    final lignes = <Widget>[
      if (e.email.isNotEmpty)
        LigneInformation(
          icone: Icons.mail_outline_rounded,
          libelle: t.email,
          valeur: e.email,
        ),
      if (e.telephone.isNotEmpty)
        LigneInformation(
          icone: Icons.phone_outlined,
          libelle: t.telephone,
          valeur: e.telephone,
        ),
      if (e.dateNaissance != null)
        LigneInformation(
          icone: Icons.cake_outlined,
          libelle: t.dateNaissance,
          valeur: Formats.dateLongue(e.dateNaissance, langue),
        ),
      if (e.genreLibelle.isNotEmpty)
        LigneInformation(
          icone: Icons.person_outline_rounded,
          libelle: t.genre,
          valeur: e.genreLibelle,
        ),
      if (residence.isNotEmpty)
        LigneInformation(
          icone: Icons.home_outlined,
          libelle: t.residence,
          valeur: residence,
        ),
      if (e.statutLibelle.isNotEmpty)
        LigneInformation(
          icone: Icons.verified_outlined,
          libelle: t.statut,
          valeur: e.statutLibelle,
        ),
    ];
    final modifiable = profil.modification.profilAutorise;
    return CarteYsem(
      titre: t.informations,
      icone: Icons.badge_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (lignes.isEmpty)
            EtatVide(message: t.aucuneInformation)
          else
            ...lignes,
          if (modifiable) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => ouvrirEditionProfil(context, profil),
              icon: const Icon(Icons.edit_outlined),
              label: Text(t.modifierMonProfil),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ouvre la mise à jour du profil, puis relit ce qui en dépend.
Future<void> ouvrirEditionProfil(BuildContext context, Profil profil) async {
  final conteneur = ProviderScope.containerOf(context, listen: false);
  final modifie = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => EditionProfilPage(profil: profil)),
  );
  if (modifie == true) {
    conteneur.invalidate(profilProvider);
    conteneur.invalidate(tableauDeBordProvider);
  }
}

/// Le père et la mère tels que le dossier les connaît.
class _CarteParents extends StatelessWidget {
  const _CarteParents({required this.profil});

  final Profil profil;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    Widget parent(String titre, IconData icone, ParentDossier p) {
      final lignes = <Widget>[
        if (p.nom.isNotEmpty)
          LigneInformation(
            icone: Icons.person_outline_rounded,
            libelle: t.nomComplet,
            valeur: p.nom,
          ),
        if (p.telephone.isNotEmpty)
          LigneInformation(
            icone: Icons.phone_outlined,
            libelle: t.telephone,
            valeur: p.telephone,
          ),
        if (p.email.isNotEmpty)
          LigneInformation(
            icone: Icons.mail_outline_rounded,
            libelle: t.email,
            valeur: p.email,
          ),
        if (p.profession.isNotEmpty)
          LigneInformation(
            icone: Icons.work_outline_rounded,
            libelle: t.profession,
            valeur: p.profession,
          ),
        if (p.villeResidence.isNotEmpty)
          LigneInformation(
            icone: Icons.location_city_outlined,
            libelle: t.villeResidence,
            valeur: p.villeResidence,
          ),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Row(
              children: [
                Icon(icone, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(titre, style: theme.textTheme.titleSmall),
              ],
            ),
          ),
          if (lignes.isEmpty)
            Text('—', style: theme.textTheme.bodySmall)
          else
            ...lignes,
        ],
      );
    }

    return CarteYsem(
      titre: t.parentsEtTuteurs,
      icone: Icons.family_restroom_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          parent(t.pereOuTuteur, Icons.man_outlined, profil.pere),
          const SizedBox(height: 12),
          parent(t.mereOuTutrice, Icons.woman_outlined, profil.mere),
        ],
      ),
    );
  }
}

/// La photo du bandeau, quand la scolarité permet de la changer : un appui
/// propose de la remplacer ou de la retirer.
class _PhotoModifiable extends ConsumerStatefulWidget {
  const _PhotoModifiable({required this.etudiant});

  final Etudiant etudiant;

  @override
  ConsumerState<_PhotoModifiable> createState() => _PhotoModifiableState();
}

enum _GestePhoto { changer, retirer }

class _PhotoModifiableState extends ConsumerState<_PhotoModifiable> {
  bool _enCours = false;

  Future<void> _ouvrir() async {
    final t = AppLocalizations.of(context);
    final aUnePhoto = (widget.etudiant.photo ?? '').isNotEmpty;
    final geste = await showModalBottomSheet<_GestePhoto>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                t.photoProfilAide,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(aUnePhoto ? t.changerLaPhoto : t.ajouterUnePhoto),
              onTap: () => Navigator.of(context).pop(_GestePhoto.changer),
            ),
            if (aUnePhoto)
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(t.retirerLaPhoto),
                onTap: () => Navigator.of(context).pop(_GestePhoto.retirer),
              ),
          ],
        ),
      ),
    );
    if (!mounted || geste == null) return;
    switch (geste) {
      case _GestePhoto.changer:
        await _changer();
      case _GestePhoto.retirer:
        await _retirer();
    }
  }

  Future<void> _changer() async {
    final t = AppLocalizations.of(context);
    final pieces = await choisirPieces(
      context,
      extensions: const ['jpg', 'jpeg', 'png'],
    );
    if (pieces.isEmpty || !mounted) return;
    await _executer(
      () => ref.read(etudiantRepositoryProvider).changerPhoto(pieces.first),
      t.photoMiseAJour,
    );
  }

  Future<void> _retirer() async {
    final t = AppLocalizations.of(context);
    final ok = await confirmer(
      context,
      titre: t.retirerLaPhoto,
      texte: t.retirerLaPhotoTexte,
      action: t.retirer,
    );
    if (!ok || !mounted) return;
    await _executer(
      () => ref.read(etudiantRepositoryProvider).retirerPhoto(),
      t.photoRetiree,
    );
  }

  Future<void> _executer(Future<void> Function() geste, String succes) async {
    final messager = ScaffoldMessenger.of(context);
    setState(() => _enCours = true);
    try {
      await geste();
      // L'ancienne image ne doit pas survivre dans le cache des images.
      final ancienne = AvatarEtudiant.adressePhoto(widget.etudiant.photo);
      if (ancienne != null) {
        await NetworkImage(ancienne).evict();
      }
      ref.invalidate(profilProvider);
      ref.invalidate(tableauDeBordProvider);
      messager.showSnackBar(SnackBar(content: Text(succes)));
    } on ApiException catch (e) {
      final message = e.erreurDuChamp('photo') ?? e.message;
      messager.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: t.changerLaPhoto,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _enCours ? null : _ouvrir,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AvatarEtudiant(etudiant: widget.etudiant, rayon: 44),
            if (_enCours)
              const SizedBox.square(
                dimension: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarteConnexions extends StatelessWidget {
  const _CarteConnexions({required this.connexions});

  final List<ConnexionRecente> connexions;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final langue = langueCourante(context);
    final jetons = YsemTokens.of(context);
    return CarteYsem(
      titre: t.connexionsRecentes,
      icone: Icons.history_rounded,
      child: Column(
        children: [
          for (final c in connexions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(
                c.appareilConnu
                    ? Icons.devices_rounded
                    : Icons.warning_amber_rounded,
                color: c.appareilConnu ? null : jetons.alerte,
              ),
              title: Text(c.appareil.isEmpty ? c.canalLibelle : c.appareil),
              subtitle: Text(
                [
                  Formats.horodatage(c.date, langue),
                  if (c.appareil.isNotEmpty && c.canalLibelle.isNotEmpty)
                    c.canalLibelle,
                ].join(' · '),
              ),
            ),
        ],
      ),
    );
  }
}
