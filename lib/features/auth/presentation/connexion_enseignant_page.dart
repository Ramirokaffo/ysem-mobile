import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../commun/langue.dart';
import '../application/connexion.dart';
import 'entete_connexion.dart';

/// Connexion à l'espace enseignant : adresse e-mail et mot de passe du
/// portail enseignant (les mêmes que sur le web).
class ConnexionEnseignantPage extends ConsumerStatefulWidget {
  const ConnexionEnseignantPage({super.key});

  @override
  ConsumerState<ConnexionEnseignantPage> createState() =>
      _ConnexionEnseignantPageState();
}

class _ConnexionEnseignantPageState
    extends ConsumerState<ConnexionEnseignantPage> {
  final _formulaire = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _motDePasse = TextEditingController();
  bool _masque = true;
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _email.dispose();
    _motDePasse.dispose();
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
      final resultat =
          await ref.read(authEnseignantRepositoryProvider).connexion(
                email: _email.text,
                motDePasse: _motDePasse.text,
              );
      if (!mounted) return;
      TextInput.finishAutofillContext();
      poursuivreConnexion(context, ref, resultat);
    } on ApiException catch (e) {
      // `compte_non_active`, `dossier_archive` : le message du serveur dit
      // déjà quoi faire.
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _motDePasseOublie() async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MotDePasseOublie(email: _email.text),
    );
    if (message != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          EnteteConnexion(
            titre: t.espaceEnseignant,
            sousTitre: t.connexionEnseignantConsigne,
            actions: const [SelecteurLangue()],
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
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [
                        AutofillHints.email,
                        AutofillHints.username,
                      ],
                      decoration: InputDecoration(
                        labelText: t.email,
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (v) => validerEmail(v, t),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _motDePasse,
                      obscureText: _masque,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _envoyer(),
                      decoration: InputDecoration(
                        labelText: t.motDePasse,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _masque ? t.afficher : t.masquer,
                          icon: Icon(_masque
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _masque = !_masque),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? t.champObligatoire : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _motDePasseOublie,
                        child: Text(t.motDePasseOublie),
                      ),
                    ),
                    if (_erreur != null) ...[
                      const SizedBox(height: 8),
                      MessageErreur(_erreur!),
                    ],
                    const SizedBox(height: 16),
                    BoutonEnvoi(
                      libelle: t.seConnecter,
                      enCours: _enCours,
                      onPressed: _envoyer,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 18, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.connexionEnseignantAide,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
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
}

/// Contrôle de forme d'une adresse ; le serveur reste juge du reste.
String? validerEmail(String? valeur, AppLocalizations t) {
  final v = valeur?.trim() ?? '';
  if (v.isEmpty) return t.champObligatoire;
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) return t.emailInvalide;
  return null;
}

/// « Mot de passe oublié » : le lien de réinitialisation du portail web est
/// envoyé à l'adresse ; c'est dans le navigateur que le mot de passe se pose.
class _MotDePasseOublie extends ConsumerStatefulWidget {
  const _MotDePasseOublie({required this.email});

  final String email;

  @override
  ConsumerState<_MotDePasseOublie> createState() => _MotDePasseOublieState();
}

class _MotDePasseOublieState extends ConsumerState<_MotDePasseOublie> {
  final _formulaire = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email.trim());
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (!_formulaire.currentState!.validate()) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final message = await ref
          .read(authEnseignantRepositoryProvider)
          .motDePasseOublie(_email.text);
      if (mounted) Navigator.pop(context, message);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formulaire,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.motDePasseOublie, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              t.motDePasseOublieConsigne,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _email,
              autofocus: widget.email.trim().isEmpty,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: t.email,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
              ),
              validator: (v) => validerEmail(v, t),
              onFieldSubmitted: (_) => _envoyer(),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 16),
              MessageErreur(_erreur!),
            ],
            const SizedBox(height: 20),
            BoutonEnvoi(
              libelle: t.envoyerLeLien,
              enCours: _enCours,
              onPressed: _envoyer,
            ),
          ],
        ),
      ),
    );
  }
}
