import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../commun/langue.dart';
import '../application/connexion.dart';
import 'entete_connexion.dart';

/// Connexion à l'espace étudiant : matricule et mot de passe du portail
/// (le même que sur le web).
class ConnexionEtudiantPage extends ConsumerStatefulWidget {
  const ConnexionEtudiantPage({super.key});

  @override
  ConsumerState<ConnexionEtudiantPage> createState() =>
      _ConnexionEtudiantPageState();
}

class _ConnexionEtudiantPageState extends ConsumerState<ConnexionEtudiantPage> {
  final _formulaire = GlobalKey<FormState>();
  final _matricule = TextEditingController();
  final _motDePasse = TextEditingController();
  bool _masque = true;
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _matricule.dispose();
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
      final resultat = await ref.read(authEtudiantRepositoryProvider).connexion(
            matricule: _matricule.text,
            motDePasse: _motDePasse.text,
          );
      if (!mounted) return;
      TextInput.finishAutofillContext();
      poursuivreConnexion(context, ref, resultat);
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
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          EnteteConnexion(
            titre: t.espaceEtudiant,
            sousTitre: t.connexionEtudiantConsigne,
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
                      controller: _matricule,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.username],
                      decoration: InputDecoration(
                        labelText: t.matricule,
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? t.champObligatoire
                          : null,
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
                    if (_erreur != null) ...[
                      const SizedBox(height: 16),
                      MessageErreur(_erreur!),
                    ],
                    const SizedBox(height: 24),
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
                            t.connexionAide,
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
