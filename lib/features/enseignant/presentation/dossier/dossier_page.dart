import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/format/formats.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../commun/compte/cartes_compte.dart';
import '../../../commun/langue.dart';
import '../../../commun/piece_jointe.dart';
import '../../application/lectures.dart';
import '../../domain/dossier.dart';
import '../../domain/modeles.dart';
import '../avatar_enseignant.dart';
import 'edition_dossier_page.dart';

/// Ouvre l'écran de saisie d'un bloc ou d'une ligne.
void _editer(
  BuildContext context,
  FormulairesDossier formulaires,
  CibleEdition cible,
  String titre, {
  String? aide,
  Set<String> piecesDeposees = const {},
}) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => EditionDossierPage(
        titre: titre,
        formulaires: formulaires,
        cible: cible,
        aide: aide,
        piecesDeposees: piecesDeposees,
      ),
    ));

/// Le crayon d'une carte, offert quand le serveur rend de quoi saisir.
Widget? _crayon(BuildContext context, VoidCallback? surAppui) {
  if (surAppui == null) return null;
  return IconButton(
    tooltip: AppLocalizations.of(context).modifier,
    visualDensity: VisualDensity.compact,
    icon: const Icon(Icons.edit_outlined, size: 20),
    onPressed: surAppui,
  );
}

/// « Mon dossier » : la lecture de l'état civil, des coordonnées, du cursus,
/// des certifications et des expériences, chaque bloc s'ouvrant à la saisie
/// avec les champs du web — et ce que le service a validé.
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
            _Photo(dossier: dossier),
            const SizedBox(height: 16),
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
            _Certifications(dossier: dossier),
            const SizedBox(height: 16),
            _Professionnel(dossier: dossier),
            const SizedBox(height: 16),
            _Experiences(
              titre: t.experiencesEnseignement,
              icone: Icons.co_present_outlined,
              lignes: dossier.experiencesEnseignement,
              tableau: TableauDossier.experiencesEnseignement,
              formulaires: dossier.formulaires,
            ),
            const SizedBox(height: 16),
            _Experiences(
              titre: t.experiencesEntreprise,
              icone: Icons.business_center_outlined,
              lignes: dossier.experiencesEntreprise,
              tableau: TableauDossier.experiencesEntreprise,
              formulaires: dossier.formulaires,
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
              dossier.formulaires == null
                  ? t.dossierModifierSurLeWeb
                  : t.dossierTenuParLeService,
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

/// La photo du dossier : elle se remplace, elle ne se retire pas, comme sur
/// le web.
class _Photo extends ConsumerStatefulWidget {
  const _Photo({required this.dossier});

  final DossierEnseignant dossier;

  @override
  ConsumerState<_Photo> createState() => _PhotoState();
}

class _PhotoState extends ConsumerState<_Photo> {
  bool _enCours = false;

  Future<void> _changer() async {
    final messager = ScaffoldMessenger.of(context);
    final pieces = await choisirPieces(
      context,
      extensions: const ['jpg', 'jpeg', 'png'],
    );
    if (pieces.isEmpty || !mounted) return;
    setState(() => _enCours = true);
    try {
      final resultat = await ref
          .read(enseignantRepositoryProvider)
          .modifierDossier(const {}, fichiers: {'photo': pieces.first});
      await relireDossier(ref);
      annoncerResultat(messager, resultat);
    } on ApiException catch (e) {
      final message = e.erreurs['photo']?.join(' ') ?? e.message;
      messager.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final e = widget.dossier.enseignant;
    return Row(
      children: [
        AvatarEnseignant(enseignant: e, rayon: 34),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.nomComplet, style: theme.textTheme.titleMedium),
              Text(e.matricule, style: theme.textTheme.bodySmall),
              if (widget.dossier.formulaires != null)
                _enCours
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : TextButton.icon(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: _changer,
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        label: Text(
                            e.aUnePhoto ? t.changerLaPhoto : t.ajouterUnePhoto),
                      ),
            ],
          ),
        ),
      ],
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
    ];
    final f = d.formulaires;
    return CarteYsem(
      titre: t.etatCivil,
      icone: Icons.badge_outlined,
      action: _crayon(
        context,
        f == null
            ? null
            : () => _editer(context, f, const CibleBloc(BlocDossier.identite),
                t.informationsPersonnelles),
      ),
      child: lignes.isEmpty
          ? EtatVide(message: t.aucuneInformation)
          : Column(children: lignes),
    );
  }
}

/// Ce que l'intéressé tient de son activité. Le grade n'y est pas : il résout
/// le taux de vacation, et se lit sur le profil.
class _Professionnel extends StatelessWidget {
  const _Professionnel({required this.dossier});

  final DossierEnseignant dossier;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final d = dossier;
    final f = d.formulaires;
    return CarteYsem(
      titre: t.informationsProfessionnelles,
      icone: Icons.work_outline_rounded,
      action: _crayon(
        context,
        f == null
            ? null
            : () => _editer(
                  context,
                  f,
                  const CibleBloc(BlocDossier.professionnel),
                  t.informationsProfessionnelles,
                  aide: t.dossierAideProfessionnel,
                  piecesDeposees: {if (d.cvDepose) 'cv'},
                ),
      ),
      child: Column(
        children: [
          if (d.enseignant.profilLibelle.isNotEmpty)
            LigneInformation(
                icone: Icons.work_outline_rounded,
                libelle: t.profilProfessionnel,
                valeur: d.enseignant.profilLibelle),
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
        ],
      ),
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
    final f = d.formulaires;
    final secondTelephone = f?.valeurs['identite']?['phone_number_2'] ?? '';
    final lignes = <Widget>[
      if (e.email.isNotEmpty)
        LigneInformation(
            icone: Icons.mail_outline_rounded, libelle: t.email, valeur: e.email),
      if (e.telephone.isNotEmpty)
        LigneInformation(
            icone: Icons.phone_outlined, libelle: t.telephone, valeur: e.telephone),
      if (secondTelephone.isNotEmpty)
        LigneInformation(
            icone: Icons.phone_outlined,
            libelle: t.telephoneSecondaire,
            valeur: secondTelephone),
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
      action: _crayon(
        context,
        f == null
            ? null
            : () => _editer(context, f, const CibleBloc(BlocDossier.coordonnees),
                t.coordonneesEtUrgence),
      ),
      child: lignes.isEmpty
          ? EtatVide(message: t.aucuneInformation)
          : Column(children: lignes),
    );
  }
}

/// Une ligne d'un tableau : l'appui l'ouvre à la saisie quand le serveur le
/// permet, et une ligne qu'il ne connaît pas reste lue.
class _LigneTableau extends StatelessWidget {
  const _LigneTableau({
    required this.titre,
    required this.sousTitre,
    this.icone,
    this.justificatif = false,
    this.surAppui,
  });

  final String titre;
  final String sousTitre;
  final IconData? icone;
  final bool justificatif;
  final VoidCallback? surAppui;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      onTap: surAppui,
      leading:
          icone == null ? null : Icon(icone, color: theme.colorScheme.secondary),
      title: Text(titre,
          style:
              theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
      subtitle: sousTitre.isEmpty ? null : Text(sousTitre),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (justificatif)
            Tooltip(
              message: t.justificatifDepose,
              child: Icon(Icons.attach_file_rounded,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
            ),
          if (surAppui != null)
            Icon(Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Le bouton d'ajout d'un tableau, absent quand le dossier est en lecture.
class _BoutonAjout extends StatelessWidget {
  const _BoutonAjout({required this.libelle, required this.surAppui});

  final String libelle;
  final VoidCallback surAppui;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          onPressed: surAppui,
          icon: const Icon(Icons.add_rounded),
          label: Text(libelle),
        ),
      );
}

/// Ouvre une ligne d'un tableau, si le formulaire la connaît.
VoidCallback? _ouvrirLigne(
  BuildContext context,
  FormulairesDossier? formulaires,
  TableauDossier tableau,
  int id,
  String titre,
) {
  final ligne = formulaires?.ligne(tableau, id);
  if (formulaires == null || ligne == null) return null;
  return () => _editer(context, formulaires, CibleLigne(tableau, ligne), titre);
}

class _Cursus extends StatelessWidget {
  const _Cursus({required this.dossier});

  final DossierEnseignant dossier;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final f = dossier.formulaires;
    return CarteYsem(
      titre: t.cursusAcademique,
      icone: Icons.school_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (dossier.cursus.isEmpty)
            EtatVide(message: t.aucunDiplome, icone: Icons.school_outlined),
          for (final l in dossier.cursus)
            _LigneTableau(
              icone: Icons.workspace_premium_outlined,
              titre: [l.diplome, l.specialisation]
                  .where((s) => s.isNotEmpty)
                  .join(' — '),
              sousTitre: [
                l.etablissement,
                if (l.annee != null) '${l.annee}',
                l.pays,
              ].where((s) => s.isNotEmpty).join(' · '),
              justificatif: l.justificatif,
              surAppui: _ouvrirLigne(context, f, TableauDossier.cursus, l.id,
                  t.modifierLeDiplome),
            ),
          if (f != null)
            _BoutonAjout(
              libelle: t.ajouterUnDiplome,
              surAppui: () => _editer(context, f,
                  const CibleLigne(TableauDossier.cursus), t.ajouterUnDiplome),
            ),
        ],
      ),
    );
  }
}

class _Certifications extends StatelessWidget {
  const _Certifications({required this.dossier});

  final DossierEnseignant dossier;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final f = dossier.formulaires;
    return CarteYsem(
      titre: t.certifications,
      icone: Icons.verified_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (dossier.certifications.isEmpty)
            EtatVide(message: t.aucunElement, icone: Icons.verified_outlined),
          for (final c in dossier.certifications)
            _LigneTableau(
              icone: Icons.verified_outlined,
              titre: c.intitule,
              sousTitre: [
                c.organisme,
                if (c.annee != null) '${c.annee}',
                c.domaine,
              ].where((s) => s.isNotEmpty).join(' · '),
              surAppui: _ouvrirLigne(context, f, TableauDossier.certifications,
                  c.id, t.modifierLaCertification),
            ),
          if (f != null)
            _BoutonAjout(
              libelle: t.ajouterUneCertification,
              surAppui: () => _editer(
                  context,
                  f,
                  const CibleLigne(TableauDossier.certifications),
                  t.ajouterUneCertification),
            ),
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
    required this.tableau,
    required this.formulaires,
  });

  final String titre;
  final IconData icone;
  final List<LigneExperience> lignes;
  final TableauDossier tableau;
  final FormulairesDossier? formulaires;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final f = formulaires;
    String duree(LigneExperience l) => [
          if (l.annees > 0) t.nombreAnnees(l.annees),
          if (l.mois > 0) t.nombreMois(l.mois),
        ].join(' ');
    return CarteYsem(
      titre: titre,
      icone: icone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (lignes.isEmpty)
            EtatVide(message: t.aucuneExperience, icone: icone),
          for (final l in lignes)
            _LigneTableau(
              titre:
                  [l.organisme, l.poste].where((s) => s.isNotEmpty).join(' — '),
              sousTitre: [
                duree(l),
                [l.ville, l.pays].where((s) => s.isNotEmpty).join(', '),
              ].where((s) => s.isNotEmpty).join(' · '),
              surAppui:
                  _ouvrirLigne(context, f, tableau, l.id, t.modifierLExperience),
            ),
          if (f != null)
            _BoutonAjout(
              libelle: t.ajouterUneExperience,
              surAppui: () => _editer(context, f, CibleLigne(tableau),
                  t.ajouterUneExperience),
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
