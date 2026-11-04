import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../../../commun/champ_saisie.dart';
import '../../../commun/formulaire.dart';
import '../../../commun/piece_jointe.dart';
import '../../application/lectures.dart';
import '../../domain/dossier.dart';

/// Relit ce que le dossier nourrit : la page, la photo, et l'identité que
/// montrent l'accueil et le profil.
Future<void> relireDossier(WidgetRef ref) async {
  ref.invalidate(dossierEnseignantProvider);
  ref.invalidate(photoEnseignantProvider);
  // Lus avant l'attente : la page peut se refermer pendant la relecture.
  final depot = ref.read(authEnseignantRepositoryProvider);
  final session = ref.read(sessionProvider.notifier);
  try {
    session.mettreAJourActeur(depot.acteurDe(await depot.moi()));
  } on ApiException {
    // Le dossier est enregistré : l'identité se relira à la prochaine visite.
  }
}

/// Le message d'un enregistrement, et ce que le cursus en a déduit.
void annoncerResultat(ScaffoldMessengerState messager, ResultatDossier r) {
  final avertissement = r.avertissement;
  messager.showSnackBar(SnackBar(
    content: Text(
        avertissement == null ? r.detail : '${r.detail}\n$avertissement'),
    duration: Duration(seconds: avertissement == null ? 4 : 10),
  ));
}

/// Les titres des tableaux, pour nommer une erreur qui vise un autre écran.
Map<TableauDossier, String> titresTableaux(AppLocalizations t) => {
      TableauDossier.cursus: t.cursusAcademique,
      TableauDossier.certifications: t.certifications,
      TableauDossier.experiencesEnseignement: t.experiencesEnseignement,
      TableauDossier.experiencesEntreprise: t.experiencesEntreprise,
    };

/// Un écran de saisie du dossier : un bloc, une ligne d'un tableau, ou une
/// ligne neuve. Ce sont les champs du web, tels que le serveur les décrit.
class EditionDossierPage extends ConsumerStatefulWidget {
  const EditionDossierPage({
    super.key,
    required this.titre,
    required this.formulaires,
    required this.cible,
    this.aide,
    this.piecesDeposees = const {},
  });

  final String titre;
  final FormulairesDossier formulaires;
  final CibleEdition cible;
  final String? aide;

  /// Pièces d'un bloc : celles d'une ligne viennent de la ligne.
  final Set<String> piecesDeposees;

  @override
  ConsumerState<EditionDossierPage> createState() => _EditionDossierPageState();
}

class _EditionDossierPageState extends ConsumerState<EditionDossierPage> {
  late final _saisie = SaisieDossier(
    widget.formulaires,
    widget.cible,
    piecesDeposees: widget.piecesDeposees,
  );
  bool _enCours = false;
  List<String> _bandeau = const [];

  Future<void> _envoyer(Future<ResultatDossier> Function() envoi) async {
    final t = AppLocalizations.of(context);
    final messager = ScaffoldMessenger.of(context);
    final navigateur = Navigator.of(context);
    setState(() {
      _enCours = true;
      _bandeau = const [];
      _saisie.erreurs = const {};
    });
    try {
      final resultat = await envoi();
      await relireDossier(ref);
      annoncerResultat(messager, resultat);
      navigateur.pop();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _bandeau = _saisie.poserErreurs(e, titresTableaux(t)));
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  void _enregistrer() {
    final depot = ref.read(enseignantRepositoryProvider);
    _envoyer(() =>
        depot.modifierDossier(_saisie.corps, fichiers: _saisie.fichiers));
  }

  Future<void> _supprimer(CibleLigne cible) async {
    final t = AppLocalizations.of(context);
    final depot = ref.read(enseignantRepositoryProvider);
    final oui = await confirmer(
      context,
      titre: t.supprimerCetteLigne,
      texte: t.supprimerCetteLigneTexte,
      action: t.supprimer,
    );
    if (!oui) return;
    _envoyer(() => depot.modifierDossier({
          cible.tableau.cle: [
            {'id': cible.ligne!.id, 'supprimer': true},
          ],
        }));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cible = widget.cible;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titre),
        actions: [
          if (cible is CibleLigne && cible.ligne != null)
            IconButton(
              tooltip: t.supprimer,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _enCours ? null : () => _supprimer(cible),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (_bandeau.isNotEmpty) ...[
            BandeauErreurs(messages: _bandeau),
            const SizedBox(height: 16),
          ],
          if (widget.aide != null) ...[
            Encadre(texte: widget.aide!),
            const SizedBox(height: 16),
          ],
          for (final champ in _saisie.champsVisibles) ...[
            if (champ.estFichier)
              _ChampPiece(
                saisie: _saisie,
                nom: champ.nom,
                libelle: champ.libelle,
                aide: champ.aide,
                retirable: champ.retirable,
                actif: !_enCours,
                surChangement: () => setState(() {}),
              )
            else
              ChampDeSaisie(
                key: ValueKey(champ.nom),
                champ: champ,
                valeur: _saisie.valeur(champ.nom),
                erreur: _saisie.erreurs[champ.nom]?.join(' '),
                surChangement: (v) =>
                    setState(() => _saisie.valeurs[champ.nom] = v),
              ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _enCours ? null : _enregistrer,
            icon: _enCours
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(t.enregistrer),
          ),
        ],
      ),
    );
  }
}

/// Une pièce du dossier : celle qu'on choisit, ou celle déjà déposée, qu'on
/// remplace ou qu'on retire quand le web le permet.
class _ChampPiece extends StatelessWidget {
  const _ChampPiece({
    required this.saisie,
    required this.nom,
    required this.libelle,
    required this.aide,
    required this.retirable,
    required this.actif,
    required this.surChangement,
  });

  final SaisieDossier saisie;
  final String nom;
  final String libelle;
  final String aide;
  final bool retirable;
  final bool actif;
  final VoidCallback surChangement;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final piece = saisie.pieces[nom];
    final deposee = saisie.deposees.contains(nom);
    final retiree = saisie.retraits.contains(nom);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChampPieceJointe(
          libelle: libelle,
          piece: piece,
          actif: actif,
          extensions:
              nom == 'cv' ? const ['pdf', 'doc', 'docx'] : extensionsPieces,
          erreur: saisie.erreurs[nom]?.join(' '),
          aide: deposee && !retiree
              ? t.pieceDejaDeposee
              : aide.isEmpty
                  ? null
                  : aide,
          surChoix: (choisie) {
            if (choisie == null) {
              saisie.pieces.remove(nom);
            } else {
              saisie.pieces[nom] = choisie;
              saisie.retraits.remove(nom);
            }
            surChangement();
          },
        ),
        if (deposee && retirable && piece == null) ...[
          if (retiree)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(t.fichierRetireALEnregistrement,
                        style: theme.textTheme.bodySmall),
                  ),
                  TextButton(
                    onPressed: actif
                        ? () {
                            saisie.retraits.remove(nom);
                            surChangement();
                          }
                        : null,
                    child: Text(t.conserverLeFichier),
                  ),
                ],
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: actif
                    ? () {
                        saisie.retraits.add(nom);
                        surChangement();
                      }
                    : null,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: Text(t.retirerLeFichierActuel),
              ),
            ),
        ],
      ],
    );
  }
}
