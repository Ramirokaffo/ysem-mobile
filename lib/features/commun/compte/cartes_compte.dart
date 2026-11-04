import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/charte/charte.dart';
import '../../../core/auth/espace.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../etudiant/hors_ligne/providers.dart';
import '../langue.dart';

// Cartes du profil communes aux deux espaces : sécurité du compte, langue,
// déconnexion.

/// Une ligne « libellé / valeur » d'une carte d'informations.
class LigneInformation extends StatelessWidget {
  const LigneInformation({super.key, required this.icone, required this.libelle, required this.valeur});

  final IconData icone;
  final String libelle;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icone, size: 20, color: theme.colorScheme.secondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(libelle,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                Text(valeur,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sécurité du compte : double authentification (mot de passe redemandé,
/// comme sur le portail web) et changement du mot de passe.
class CarteSecurite extends ConsumerStatefulWidget {
  const CarteSecurite({
    super.key,
    required this.espace,
    required this.active,
    required this.routeMotDePasse,
    this.apresChangement,
  });

  final Espace espace;

  /// État lu dans le profil, tel que le serveur le tient.
  final bool active;
  final String routeMotDePasse;

  /// Ce qu'il faut relire une fois l'acteur changé côté serveur.
  final VoidCallback? apresChangement;

  @override
  ConsumerState<CarteSecurite> createState() => _CarteSecuriteState();
}

class _CarteSecuriteState extends ConsumerState<CarteSecurite> {
  bool _enCours = false;

  Future<void> _basculer(bool activer) async {
    final motDePasse = await showDialog<String>(
      context: context,
      builder: (_) => _DemandeMotDePasse(activer: activer),
    );
    if (motDePasse == null || !mounted) return;
    setState(() => _enCours = true);
    final messager = ScaffoldMessenger.of(context);
    try {
      final resultat = await ref
          .read(authRepositoryProvider(widget.espace))
          .basculerDoubleAuth(motDePasse: motDePasse, activer: activer);
      ref.read(sessionProvider.notifier).mettreAJourActeur(resultat.acteur);
      widget.apresChangement?.call();
      messager.showSnackBar(SnackBar(content: Text(resultat.message)));
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return CarteYsem(
      titre: t.securite,
      icone: Icons.shield_outlined,
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.doubleAuthentification),
            subtitle: Text(t.doubleAuthentificationAide),
            value: widget.active,
            onChanged: _enCours ? null : _basculer,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.password_rounded),
            title: Text(t.changerMotDePasse),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(widget.routeMotDePasse),
          ),
        ],
      ),
    );
  }
}

class _DemandeMotDePasse extends StatefulWidget {
  const _DemandeMotDePasse({required this.activer});

  final bool activer;

  @override
  State<_DemandeMotDePasse> createState() => _DemandeMotDePasseState();
}

class _DemandeMotDePasseState extends State<_DemandeMotDePasse> {
  final _champ = TextEditingController();

  @override
  void dispose() {
    _champ.dispose();
    super.dispose();
  }

  void _valider() {
    if (_champ.text.isNotEmpty) Navigator.of(context).pop(_champ.text);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.activer
          ? t.activerDoubleAuthentification
          : t.desactiverDoubleAuthentification),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.confirmerParMotDePasse),
          const SizedBox(height: 16),
          TextField(
            controller: _champ,
            autofocus: true,
            obscureText: true,
            onSubmitted: (_) => _valider(),
            decoration: InputDecoration(labelText: t.motDePasse),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.annuler),
        ),
        FilledButton(onPressed: _valider, child: Text(t.confirmer)),
      ],
    );
  }
}

/// Langue d'affichage, enregistrée au dossier : le portail web et
/// l'application lisent ensuite la même préférence.
class CarteLangue extends ConsumerStatefulWidget {
  const CarteLangue({super.key, required this.espace, this.apresChangement});

  final Espace espace;

  /// Les libellés rendus par le serveur suivent la langue : ce qu'il faut
  /// relire.
  final VoidCallback? apresChangement;

  @override
  ConsumerState<CarteLangue> createState() => _CarteLangueState();
}

class _CarteLangueState extends ConsumerState<CarteLangue> {
  bool _enCours = false;

  Future<void> _changer(String langue) async {
    setState(() => _enCours = true);
    final messager = ScaffoldMessenger.of(context);
    try {
      final acteur = await ref
          .read(authRepositoryProvider(widget.espace))
          .changerLangue(langue);
      ref.read(sessionProvider.notifier).mettreAJourActeur(acteur);
      await ref.read(langueForceeProvider.notifier).definir(langue);
      widget.apresChangement?.call();
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final actuelle = langueCourante(context);
    return CarteYsem(
      titre: t.langue,
      icone: Icons.translate_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'fr', label: Text('Français')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {actuelle},
            showSelectedIcon: false,
            onSelectionChanged: _enCours
                ? null
                : (choix) {
                    if (choix.first != actuelle) _changer(choix.first);
                  },
          ),
          const SizedBox(height: 8),
          Text(
            t.langueAide,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Déconnexion, après confirmation.
class BoutonDeconnexion extends ConsumerWidget {
  const BoutonDeconnexion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final danger = Theme.of(context).colorScheme.error;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: danger,
        side: BorderSide(color: danger, width: 1.4),
      ),
      icon: const Icon(Icons.logout_rounded),
      label: Text(t.deconnexion),
      onPressed: () async {
        final nonEnvoyees = await nombreSaisiesNonEnvoyees(ref);
        if (!context.mounted) return;
        final confirme = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(t.deconnexion),
            content: Text(nonEnvoyees > 0
                ? t.deconnexionAvecSaisies(nonEnvoyees)
                : t.deconnexionConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(t.annuler),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(t.deconnexion),
              ),
            ],
          ),
        );
        if (confirme == true) {
          await ref.read(sessionProvider.notifier).deconnexion();
        }
      },
    );
  }
}
