import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/auth/espace.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../application/session_controller.dart';
import 'entete_connexion.dart';

/// Changement du mot de passe du portail, imposé (premier accès, mot de
/// passe remis par la scolarité) ou volontaire (depuis le profil).
class ChangementMotDePassePage extends ConsumerStatefulWidget {
  const ChangementMotDePassePage({super.key});

  @override
  ConsumerState<ChangementMotDePassePage> createState() =>
      _ChangementMotDePassePageState();
}

class _ChangementMotDePassePageState
    extends ConsumerState<ChangementMotDePassePage> {
  final _formulaire = GlobalKey<FormState>();
  final _actuel = TextEditingController();
  final _nouveau = TextEditingController();
  final _confirmation = TextEditingController();
  bool _masque = true;
  bool _enCours = false;
  ApiException? _erreur;

  @override
  void dispose() {
    _actuel.dispose();
    _nouveau.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (!_formulaire.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final espace = ref.read(sessionProvider).valueOrNull?.espace ??
          Espace.etudiant;
      final resultat =
          await ref.read(authRepositoryProvider(espace)).changerMotDePasse(
                actuel: _actuel.text,
                nouveau: _nouveau.text,
                confirmation: _confirmation.text,
              );
      if (!mounted) return;
      final messager = ScaffoldMessenger.of(context);
      final routeur = GoRouter.of(context);
      // Changement volontaire : l'écran a été empilé depuis le profil, on y
      // revient. Changement imposé : on y a été *redirigé* (rien à dépiler),
      // et la page reste une adresse valide de l'espace — la redirection ne
      // l'en fera pas sortir : c'est à elle de mener à l'accueil.
      //
      // L'ordre compte : lever l'obligation rafraîchit le routeur, qui relit
      // l'adresse courante. Dépilé avant, l'écran ne revient pas ; dans le
      // cas imposé, l'accueil n'est atteignable qu'une fois l'obligation levée.
      final session = ref.read(sessionProvider.notifier);
      if (routeur.canPop()) {
        routeur.pop();
        session.marquerMotDePasseChange(resultat.acteur);
      } else {
        session.marquerMotDePasseChange(resultat.acteur);
        routeur.go(Routes.accueil(espace));
      }
      messager.showSnackBar(SnackBar(content: Text(resultat.message)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = e);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final impose = ref.watch(
      sessionProvider.select((s) => s.valueOrNull?.doitChangerMotDePasse ?? false),
    );
    // Le formulaire du portail enseignant nomme ses champs à l'anglaise
    // (`password`, `password_confirm`) ; celui de l'étudiant à la française.
    final erreursChamp = _erreur?.erreurs['nouveau_mot_de_passe'] ??
        _erreur?.erreurs['password'] ??
        const [];
    final erreursActuel = _erreur?.erreurs['current_password'] ?? const [];
    final erreursConfirmation =
        _erreur?.erreurs['password_confirm'] ?? const [];

    InputDecoration decoration(String libelle, {String? erreur}) =>
        InputDecoration(
          labelText: libelle,
          errorText: erreur,
          errorMaxLines: 4,
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            tooltip: _masque ? t.afficher : t.masquer,
            icon: Icon(_masque
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _masque = !_masque),
          ),
        );
    String? obligatoire(String? v) =>
        (v == null || v.isEmpty) ? t.champObligatoire : null;

    return PopScope(
      canPop: !impose,
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            EnteteConnexion(
              titre: t.changerMotDePasse,
              sousTitre: impose
                  ? t.motDePasseImposeConsigne
                  : t.motDePasseVolontaireConsigne,
              retour: !impose,
              actions: [
                if (impose)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () =>
                        ref.read(sessionProvider.notifier).deconnexion(),
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(t.deconnexion),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Form(
                key: _formulaire,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _actuel,
                        obscureText: _masque,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.next,
                        decoration: decoration(
                          t.motDePasseActuel,
                          erreur: erreursActuel.isEmpty
                              ? null
                              : erreursActuel.join('\n'),
                        ),
                        validator: obligatoire,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nouveau,
                        obscureText: _masque,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.next,
                        decoration: decoration(
                          t.nouveauMotDePasse,
                          erreur: erreursChamp.isEmpty
                              ? null
                              : erreursChamp.join('\n'),
                        ),
                        validator: obligatoire,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmation,
                        obscureText: _masque,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _envoyer(),
                        decoration: decoration(
                          t.confirmationMotDePasse,
                          erreur: erreursConfirmation.isEmpty
                              ? null
                              : erreursConfirmation.join('\n'),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return t.champObligatoire;
                          if (v != _nouveau.text) return t.confirmationDifferente;
                          return null;
                        },
                      ),
                      if (_erreur != null &&
                          erreursChamp.isEmpty &&
                          erreursActuel.isEmpty &&
                          erreursConfirmation.isEmpty) ...[
                        const SizedBox(height: 16),
                        MessageErreur(_erreur!.message),
                      ],
                      const SizedBox(height: 24),
                      BoutonEnvoi(
                        libelle: t.enregistrer,
                        enCours: _enCours,
                        onPressed: _envoyer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
