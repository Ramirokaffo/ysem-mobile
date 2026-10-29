import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../app/router.dart';
import '../../../../core/format/formats.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/auth/espace.dart';
import '../../../commun/avatar_etudiant.dart';
import '../../../commun/compte/cartes_compte.dart';
import '../../../commun/langue.dart';
import '../../application/lectures.dart';
import '../../domain/modeles.dart';

/// Profil de l'étudiant : identité connue de la scolarité, sécurité du
/// compte, langue et déconnexion.
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
          20, MediaQuery.paddingOf(context).top + 24, 20, 28),
      child: Column(
        children: [
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
  const _CarteInformations({required this.profil});

  final Profil profil;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final langue = langueCourante(context);
    final e = profil.etudiant;
    final residence = [profil.quartierResidence, profil.villeResidence]
        .where((s) => s.isNotEmpty)
        .join(', ');
    final lignes = <Widget>[
      if (e.email.isNotEmpty)
        LigneInformation(icone: Icons.mail_outline_rounded, libelle: t.email, valeur: e.email),
      if (e.telephone.isNotEmpty)
        LigneInformation(icone: Icons.phone_outlined, libelle: t.telephone, valeur: e.telephone),
      if (e.dateNaissance != null)
        LigneInformation(
          icone: Icons.cake_outlined,
          libelle: t.dateNaissance,
          valeur: Formats.dateLongue(e.dateNaissance, langue),
        ),
      if (e.genreLibelle.isNotEmpty)
        LigneInformation(icone: Icons.person_outline_rounded, libelle: t.genre, valeur: e.genreLibelle),
      if (residence.isNotEmpty)
        LigneInformation(icone: Icons.home_outlined, libelle: t.residence, valeur: residence),
      if (e.statutLibelle.isNotEmpty)
        LigneInformation(icone: Icons.verified_outlined, libelle: t.statut, valeur: e.statutLibelle),
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
              subtitle: Text([
                Formats.horodatage(c.date, langue),
                if (c.appareil.isNotEmpty && c.canalLibelle.isNotEmpty)
                  c.canalLibelle,
              ].join(' · ')),
            ),
        ],
      ),
    );
  }
}

