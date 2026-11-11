import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/charte/charte.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../commun/formulaire.dart';
import '../../../../core/providers.dart';
import '../../domain/modeles.dart';

/// Mise à jour du profil par l'étudiant, quand la scolarité l'a ouverte
/// (`Student.profil_modifiable_portail`). Mêmes champs que le portail web
/// (`student_portal.profil`) — jamais l'adresse e-mail, qui reçoit les codes
/// de connexion.
///
/// Seuls les champs changés partent : le serveur complète l'envoi des
/// valeurs du dossier, et rien n'est notifié quand rien n'a changé. Rend
/// `true` à l'écran appelant quand le profil a été modifié.
class EditionProfilPage extends ConsumerStatefulWidget {
  const EditionProfilPage({super.key, required this.profil});

  final Profil profil;

  @override
  ConsumerState<EditionProfilPage> createState() => _EditionProfilPageState();
}

class _EditionProfilPageState extends ConsumerState<EditionProfilPage> {
  final _cle = GlobalKey<FormState>();
  late final Map<String, String> _depart = widget.profil.valeursFormulaire;
  late final Map<String, TextEditingController> _controleurs = {
    for (final MapEntry(:key, :value) in _depart.entries)
      key: TextEditingController(text: value),
  };
  bool _envoi = false;
  ApiException? _erreur;

  /// Les champs que le serveur accepte : ceux qu'il annonce, à défaut tous
  /// ceux de l'écran (un serveur antérieur n'annonçait pas sa liste).
  Set<String> get _acceptes {
    final annonces = widget.profil.modification.champs;
    return annonces.isEmpty ? _depart.keys.toSet() : annonces;
  }

  @override
  void dispose() {
    for (final c in _controleurs.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _changes => {
    for (final nom in _acceptes)
      if (_controleurs[nom] != null &&
          _controleurs[nom]!.text.trim() != (_depart[nom] ?? '').trim())
        nom: _controleurs[nom]!.text.trim(),
  };

  Future<void> _enregistrer() async {
    final t = AppLocalizations.of(context);
    final messager = ScaffoldMessenger.of(context);
    setState(() => _erreur = null);
    if (!_cle.currentState!.validate()) return;
    final changes = _changes;
    if (changes.isEmpty) {
      messager.showSnackBar(SnackBar(content: Text(t.aucuneModification)));
      return;
    }
    setState(() => _envoi = true);
    try {
      final modifie = await ref
          .read(etudiantRepositoryProvider)
          .modifierProfil(changes);
      if (!mounted) return;
      messager.showSnackBar(
        SnackBar(
          content: Text(modifie ? t.profilMisAJour : t.aucuneModification),
        ),
      );
      Navigator.of(context).pop(modifie);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e;
        _envoi = false;
      });
      // Les validateurs lisent `_erreur` : `validate()` part avant la
      // reconstruction.
      _cle.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final erreur = _erreur;
    final email = widget.profil.etudiant.email;

    Widget champ(
      String nom,
      String libelle, {
      IconData? icone,
      bool obligatoire = false,
      TextInputType clavier = TextInputType.text,
      TextCapitalization majuscules = TextCapitalization.words,
      String? indice,
      Iterable<String> autofill = const [],
    }) {
      if (!_acceptes.contains(nom)) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: TextFormField(
          controller: _controleurs[nom],
          enabled: !_envoi,
          keyboardType: clavier,
          textCapitalization: majuscules,
          autofillHints: autofill,
          decoration: InputDecoration(
            labelText: obligatoire ? '$libelle *' : libelle,
            hintText: indice,
            prefixIcon: icone == null ? null : Icon(icone),
            errorMaxLines: 3,
          ),
          validator: (v) =>
              _erreur?.erreurDuChamp(nom) ??
              (obligatoire && (v ?? '').trim().isEmpty
                  ? t.champObligatoire
                  : null),
        ),
      );
    }

    List<Widget> parent(String prefixe) => [
      champ(
        '${prefixe}_full_name',
        t.nomComplet,
        icone: Icons.person_outline_rounded,
      ),
      champ(
        '${prefixe}_phone_number',
        t.telephone,
        icone: Icons.phone_outlined,
        clavier: TextInputType.phone,
        majuscules: TextCapitalization.none,
        indice: '+237 6XX XXX XXX',
      ),
      champ(
        '${prefixe}_email',
        t.email,
        icone: Icons.mail_outline_rounded,
        clavier: TextInputType.emailAddress,
        majuscules: TextCapitalization.none,
      ),
      champ(
        '${prefixe}_occupation',
        t.profession,
        icone: Icons.work_outline_rounded,
        majuscules: TextCapitalization.sentences,
      ),
      champ(
        '${prefixe}_live_city',
        t.villeResidence,
        icone: Icons.location_city_outlined,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(t.modifierMonProfil)),
      body: Form(
        key: _cle,
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Encadre(texte: t.profilModifiableExplication),
              EmplacementErreurs(
                messages: erreur == null
                    ? null
                    : erreursGlobales(erreur, _acceptes),
              ),
              const SizedBox(height: 20),
              CarteYsem(
                titre: t.identite,
                icone: Icons.badge_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    champ(
                      'firstname',
                      t.prenom,
                      obligatoire: true,
                      autofill: const [AutofillHints.givenName],
                    ),
                    champ(
                      'lastname',
                      t.nomDeFamille,
                      obligatoire: true,
                      autofill: const [AutofillHints.familyName],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CarteYsem(
                titre: t.contactEtResidence,
                icone: Icons.home_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // L'adresse e-mail est montrée, jamais modifiable.
                    if (email.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: TextFormField(
                          initialValue: email,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: t.email,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            helperText: t.emailNonModifiable,
                            helperMaxLines: 4,
                          ),
                        ),
                      ),
                    champ(
                      'phone_number',
                      t.telephone,
                      icone: Icons.phone_outlined,
                      clavier: TextInputType.phone,
                      majuscules: TextCapitalization.none,
                      indice: '+237 6XX XXX XXX',
                      autofill: const [AutofillHints.telephoneNumber],
                    ),
                    champ(
                      'residence_city',
                      t.villeResidence,
                      icone: Icons.location_city_outlined,
                    ),
                    champ(
                      'residence_quarter',
                      t.quartierResidence,
                      icone: Icons.place_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CarteYsem(
                titre: t.pereOuTuteur,
                icone: Icons.man_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: parent('father'),
                ),
              ),
              const SizedBox(height: 16),
              CarteYsem(
                titre: t.mereOuTutrice,
                icone: Icons.woman_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: parent('mother'),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _envoi ? null : _enregistrer,
                icon: _envoi
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(t.enregistrer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
