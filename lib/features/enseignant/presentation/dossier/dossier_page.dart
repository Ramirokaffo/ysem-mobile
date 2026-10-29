import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/compte/cartes_compte.dart';
import '../../../commun/langue.dart';
import '../../application/lectures.dart';
import '../../domain/modeles.dart';

/// « Mon dossier » en lecture : état civil, coordonnées, cursus,
/// certifications, expériences, et ce que le service a validé.
///
/// Les pièces manquantes sont **signalées**, jamais opposées, comme sur le
/// web. Le grade, les domaines et les cours ne se déclarent pas soi-même :
/// ils sont lus, avec la décision du service.
class DossierPage extends ConsumerWidget {
  const DossierPage({super.key, this.titre});

  final String? titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre ?? t.monDossier)),
      body: VueAsynchrone<DossierEnseignant>(
        valeur: ref.watch(dossierEnseignantProvider),
        surRafraichir: () => ref.refresh(dossierEnseignantProvider.future),
        constructeur: (dossier) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (dossier.piecesACompleter.isNotEmpty) ...[
              Encadre(
                titre: t.dossierIncomplet,
                texte: dossier.piecesACompleter.map((p) => '• $p').join('\n'),
                icone: Icons.assignment_late_outlined,
              ),
              const SizedBox(height: 16),
            ],
            _EtatCivil(dossier: dossier),
            const SizedBox(height: 16),
            _Coordonnees(dossier: dossier),
            const SizedBox(height: 16),
            _Cursus(dossier: dossier),
            const SizedBox(height: 16),
            _Experiences(
              titre: t.experiencesEnseignement,
              icone: Icons.co_present_outlined,
              lignes: dossier.experiencesEnseignement,
            ),
            const SizedBox(height: 16),
            _Experiences(
              titre: t.experiencesEntreprise,
              icone: Icons.business_center_outlined,
              lignes: dossier.experiencesEntreprise,
            ),
            const SizedBox(height: 16),
            _Validations(
              titre: t.domainesEnseignement,
              icone: Icons.category_outlined,
              lignes: dossier.domaines,
            ),
            const SizedBox(height: 16),
            _Validations(
              titre: t.coursProposes,
              icone: Icons.menu_book_outlined,
              lignes: dossier.coursProposes,
            ),
            const SizedBox(height: 20),
            Text(
              t.dossierModifierSurLeWeb,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _EtatCivil extends StatelessWidget {
  const _EtatCivil({required this.dossier});

  final DossierEnseignant dossier;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final langue = langueCourante(context);
    final d = dossier;
    final naissance = [
      if (d.dateNaissance != null) Formats.dateLongue(d.dateNaissance, langue),
      d.lieuNaissance,
    ].where((s) => s.isNotEmpty).join(' · ');
    final lignes = <Widget>[
      if (naissance.isNotEmpty)
        LigneInformation(
            icone: Icons.cake_outlined, libelle: t.dateNaissance, valeur: naissance),
      if (d.nationalite.isNotEmpty)
        LigneInformation(
            icone: Icons.flag_outlined,
            libelle: t.nationalite,
            valeur: d.nationalite),
      if (d.regionOrigine.isNotEmpty)
        LigneInformation(
            icone: Icons.place_outlined,
            libelle: t.regionOrigine,
            valeur: d.regionOrigine),
      if (d.situationMatrimoniale.isNotEmpty)
        LigneInformation(
          icone: Icons.family_restroom_outlined,
          libelle: t.situationMatrimoniale,
          valeur: d.enfantsACharge == null || d.enfantsACharge == 0
              ? d.situationMatrimoniale
              : '${d.situationMatrimoniale} · ${t.enfantsACharge(d.enfantsACharge!)}',
        ),
      if (d.cni.isNotEmpty)
        LigneInformation(icone: Icons.credit_card_outlined, libelle: t.cni, valeur: d.cni),
      if (d.niu.isNotEmpty)
        LigneInformation(icone: Icons.numbers_rounded, libelle: t.niu, valeur: d.niu),
      if (d.universiteRattachement.isNotEmpty)
        LigneInformation(
            icone: Icons.account_balance_outlined,
            libelle: t.universiteRattachement,
            valeur: d.universiteRattachement),
      LigneInformation(
        icone: Icons.description_outlined,
        libelle: t.cv,
        valeur: d.cvDepose ? t.depose : t.nonDepose,
      ),
    ];
    return CarteYsem(
      titre: t.etatCivil,
      icone: Icons.badge_outlined,
      child: Column(children: lignes),
    );
  }
}

class _Coordonnees extends StatelessWidget {
  const _Coordonnees({required this.dossier});

  final DossierEnseignant dossier;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final d = dossier;
    final e = d.enseignant;
    final urgence = [
      d.contactUrgenceNom,
      if (d.contactUrgenceRelation.isNotEmpty) '(${d.contactUrgenceRelation})',
      d.contactUrgenceTelephone,
    ].where((s) => s.isNotEmpty).join(' ');
    final lignes = <Widget>[
      if (e.email.isNotEmpty)
        LigneInformation(
            icone: Icons.mail_outline_rounded, libelle: t.email, valeur: e.email),
      if (e.telephone.isNotEmpty)
        LigneInformation(
            icone: Icons.phone_outlined, libelle: t.telephone, valeur: e.telephone),
      if (d.adresse.isNotEmpty)
        LigneInformation(icone: Icons.home_outlined, libelle: t.adresse, valeur: d.adresse),
      if (urgence.isNotEmpty)
        LigneInformation(
            icone: Icons.emergency_outlined,
            libelle: t.contactUrgence,
            valeur: urgence),
    ];
    return CarteYsem(
      titre: t.coordonnees,
      icone: Icons.contact_phone_outlined,
      child: lignes.isEmpty
          ? EtatVide(message: t.aucuneInformation)
          : Column(children: lignes),
    );
  }
}

class _Cursus extends StatelessWidget {
  const _Cursus({required this.dossier});

  final DossierEnseignant dossier;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vide = dossier.cursus.isEmpty && dossier.certifications.isEmpty;
    return CarteYsem(
      titre: t.cursusEtCertifications,
      icone: Icons.school_outlined,
      child: vide
          ? EtatVide(message: t.aucunDiplome, icone: Icons.school_outlined)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final l in dossier.cursus)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(Icons.workspace_premium_outlined,
                        color: theme.colorScheme.secondary),
                    title: Text(
                      [l.diplome, l.specialisation]
                          .where((s) => s.isNotEmpty)
                          .join(' — '),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text([
                      l.etablissement,
                      if (l.annee != null) '${l.annee}',
                      l.pays,
                    ].where((s) => s.isNotEmpty).join(' · ')),
                    trailing: l.justificatif
                        ? Tooltip(
                            message: t.justificatifDepose,
                            child: Icon(Icons.attach_file_rounded,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant),
                          )
                        : null,
                  ),
                if (dossier.certifications.isNotEmpty) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Text(t.certifications,
                        style: theme.textTheme.labelLarge),
                  ),
                  for (final c in dossier.certifications)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(Icons.verified_outlined,
                          color: theme.colorScheme.secondary),
                      title: Text(c.intitule,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      subtitle: Text([
                        c.organisme,
                        if (c.annee != null) '${c.annee}',
                        c.domaine,
                      ].where((s) => s.isNotEmpty).join(' · ')),
                    ),
                ],
              ],
            ),
    );
  }
}

class _Experiences extends StatelessWidget {
  const _Experiences({
    required this.titre,
    required this.icone,
    required this.lignes,
  });

  final String titre;
  final IconData icone;
  final List<LigneExperience> lignes;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String duree(LigneExperience l) => [
          if (l.annees > 0) t.nombreAnnees(l.annees),
          if (l.mois > 0) t.nombreMois(l.mois),
        ].join(' ');
    return CarteYsem(
      titre: titre,
      icone: icone,
      child: lignes.isEmpty
          ? EtatVide(message: t.aucuneExperience, icone: icone)
          : Column(
              children: [
                for (final l in lignes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      [l.organisme, l.poste]
                          .where((s) => s.isNotEmpty)
                          .join(' — '),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text([
                      duree(l),
                      [l.ville, l.pays].where((s) => s.isNotEmpty).join(', '),
                    ].where((s) => s.isNotEmpty).join(' · ')),
                  ),
              ],
            ),
    );
  }
}

class _Validations extends StatelessWidget {
  const _Validations({
    required this.titre,
    required this.icone,
    required this.lignes,
  });

  final String titre;
  final IconData icone;
  final List<LigneValidee> lignes;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return CarteYsem(
      titre: titre,
      icone: icone,
      child: lignes.isEmpty
          ? EtatVide(message: t.aucunElement, icone: icone)
          : Column(
              children: [
                for (final l in lignes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(l.libelle,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: l.code.isEmpty ? null : Text(l.code),
                    trailing: l.statutLibelle.isEmpty
                        ? null
                        : Pastille(l.statutLibelle,
                            ton: Pastille.tonDuStatut(l.statut)),
                  ),
              ],
            ),
    );
  }
}
