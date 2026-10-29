import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../app/router.dart';
import '../../../../core/auth/espace.dart';
import '../../../../core/format/formats.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../../../commun/compte/cartes_compte.dart';
import '../../../commun/langue.dart';
import '../../application/lectures.dart';
import '../../domain/modeles.dart';
import '../avatar_enseignant.dart';
import '../sections.dart';

/// Profil de l'enseignant : ce que le service sait de lui, sécurité du
/// compte, langue et déconnexion.
///
/// L'identité vient de `auth/moi/` (ouvert aux candidats comme aux recrutés),
/// relue au rafraîchissement ; le dossier complet a sa page, réservée aux
/// recrutés.
class ProfilEnseignantPage extends ConsumerWidget {
  const ProfilEnseignantPage({super.key});

  Future<void> _relire(WidgetRef ref) async {
    final depot = ref.read(authEnseignantRepositoryProvider);
    final acteur = depot.acteurDe(await depot.moi());
    ref.read(sessionProvider.notifier).mettreAJourActeur(acteur);
    ref.invalidate(photoEnseignantProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final enseignant = ref.watch(
      sessionProvider.select((s) => s.valueOrNull?.enseignant),
    );
    if (enseignant == null) return const SizedBox.shrink();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _relire(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _Bandeau(enseignant: enseignant),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CarteInformations(enseignant: enseignant),
                  if (enseignant.recrute) ...[
                    const SizedBox(height: 16),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: Text(t.monDossier),
                        subtitle: Text(t.monDossierAide),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => ouvrirSectionEnseignant(context, 'dossier'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  CarteSecurite(
                    espace: Espace.enseignant,
                    active: enseignant.doubleAuthentification,
                    routeMotDePasse: Routes.motDePasseEnseignant,
                  ),
                  const SizedBox(height: 16),
                  CarteLangue(
                    espace: Espace.enseignant,
                    apresChangement: () {
                      ref.invalidate(tableauDeBordEnseignantProvider);
                      ref.invalidate(menuEnseignantProvider);
                      ref.invalidate(dossierEnseignantProvider);
                    },
                  ),
                  const SizedBox(height: 24),
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
  const _Bandeau({required this.enseignant});

  final Enseignant enseignant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rattachement = [enseignant.gradeLibelle, enseignant.departement]
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return BandeauMarque(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.paddingOf(context).top + 24, 20, 28),
      child: Column(
        children: [
          AvatarEnseignant(enseignant: enseignant, rayon: 44),
          const SizedBox(height: 14),
          Text(
            enseignant.nomComplet,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            enseignant.matricule,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              letterSpacing: 0.4,
            ),
          ),
          if (rattachement.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              rattachement,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.88)),
            ),
          ],
        ],
      ),
    );
  }
}

class _CarteInformations extends StatelessWidget {
  const _CarteInformations({required this.enseignant});

  final Enseignant enseignant;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final langue = langueCourante(context);
    final e = enseignant;
    final lignes = <Widget>[
      if (e.email.isNotEmpty)
        LigneInformation(
            icone: Icons.mail_outline_rounded, libelle: t.email, valeur: e.email),
      if (e.telephone.isNotEmpty)
        LigneInformation(
            icone: Icons.phone_outlined,
            libelle: t.telephone,
            valeur: e.telephone),
      if (e.genreLibelle.isNotEmpty)
        LigneInformation(
            icone: Icons.person_outline_rounded,
            libelle: t.genre,
            valeur: e.genreLibelle),
      if (e.profilLibelle.isNotEmpty)
        LigneInformation(
            icone: Icons.work_outline_rounded,
            libelle: t.profilProfessionnel,
            valeur: e.profilLibelle),
      if (e.dernierDiplomeLibelle.isNotEmpty)
        LigneInformation(
            icone: Icons.school_outlined,
            libelle: t.dernierDiplome,
            valeur: e.dernierDiplomeLibelle),
      if (e.dateRecrutement != null)
        LigneInformation(
          icone: Icons.event_available_outlined,
          libelle: t.dateRecrutement,
          valeur: Formats.dateLongue(e.dateRecrutement, langue),
        ),
      if (e.statutLibelle.isNotEmpty)
        LigneInformation(
          icone: Icons.verified_outlined,
          libelle: t.statut,
          valeur: e.recrute
              ? '${e.statutLibelle} · ${e.permanent ? t.permanent : t.vacataire}'
              : e.statutLibelle,
        ),
    ];
    return CarteYsem(
      titre: t.informations,
      icone: Icons.badge_outlined,
      child: lignes.isEmpty
          ? EtatVide(message: t.aucuneInformation)
          : Column(children: lignes),
    );
  }
}
