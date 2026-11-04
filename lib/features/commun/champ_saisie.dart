import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/charte/charte.dart';
import '../../core/format/formats.dart';
import '../../core/models/champs.dart';
import '../../l10n/app_localizations.dart';
import 'formulaire.dart';

/// Un champ décrit par le serveur, sous le contrôle qui lui convient. Les
/// fichiers se composent à part : ils ne sont pas du texte.
class ChampDeSaisie extends StatelessWidget {
  const ChampDeSaisie({
    super.key,
    required this.champ,
    required this.valeur,
    required this.surChangement,
    this.erreur,
  });

  final ChampFormulaire champ;

  /// La valeur sous la forme où elle se poste (`AAAA-MM-JJ`, `true`…).
  final String valeur;
  final ValueChanged<String> surChangement;
  final String? erreur;

  String get _libelle =>
      champ.obligatoire ? '${champ.libelle} *' : champ.libelle;

  String? get _aide => champ.aide.isEmpty ? null : champ.aide;

  @override
  Widget build(BuildContext context) {
    if (champ.estBooleen) return _caseACocher(context);
    if (champ.estDate) return _date();
    if (champ.estListe) {
      return ChampListe(
        libelle: _libelle,
        choix: champ.choix,
        valeur: valeur,
        obligatoire: champ.obligatoire,
        aide: _aide,
        erreur: erreur,
        surChoix: surChangement,
      );
    }
    return TextFormField(
      initialValue: valeur,
      onChanged: surChangement,
      minLines: champ.multiligne ? 2 : 1,
      maxLines: champ.multiligne ? 5 : 1,
      keyboardType: champ.multiligne
          ? TextInputType.multiline
          : champ.estEntier
              ? TextInputType.number
              : champ.estEmail
                  ? TextInputType.emailAddress
                  : champ.nom.contains('phone')
                      ? TextInputType.phone
                      : TextInputType.text,
      inputFormatters:
          champ.estEntier ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(
        labelText: _libelle,
        helperText: _aide,
        helperMaxLines: 3,
        errorText: erreur,
        errorMaxLines: 3,
      ),
    );
  }

  Widget _caseACocher(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(champ.libelle),
          value: valeur == 'true',
          onChanged: (coche) => surChangement(coche ? 'true' : 'false'),
        ),
        if (erreur != null)
          Text(erreur!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error)),
      ],
    );
  }

  Widget _date() {
    final annee = DateTime.now().year;
    return ChampDate(
      libelle: _libelle,
      valeur: DateTime.tryParse(valeur),
      surChoix: (date) =>
          surChangement(date == null ? '' : Formats.iso(date)),
      premiere: DateTime(1930),
      derniere: DateTime(annee + 10, 12, 31),
      erreur: erreur,
      aide: _aide,
      effacable: !champ.obligatoire,
      modeInitial: champ.nom == 'date_naiss'
          ? DatePickerMode.year
          : DatePickerMode.day,
    );
  }
}

/// Une liste fermée : ouvre une feuille où chercher. Les pays et les organismes
/// se comptent par centaines, ce qu'un menu déroulant ne sait pas présenter.
class ChampListe extends StatelessWidget {
  const ChampListe({
    super.key,
    required this.libelle,
    required this.choix,
    required this.valeur,
    required this.surChoix,
    this.obligatoire = false,
    this.aide,
    this.erreur,
  });

  final String libelle;
  final List<OptionChamp> choix;
  final String valeur;
  final ValueChanged<String> surChoix;
  final bool obligatoire;
  final String? aide;
  final String? erreur;

  Future<void> _ouvrir(BuildContext context) async {
    final choisi = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FeuilleDeChoix(
        titre: libelle,
        choix: choix,
        valeur: valeur,
        effacable: !obligatoire && valeur.isNotEmpty,
      ),
    );
    if (choisi != null) surChoix(choisi);
  }

  @override
  Widget build(BuildContext context) {
    // Une valeur enregistrée avant la fermeture de la liste reste lisible : le
    // serveur dira si elle convient encore.
    final affiche =
        choix.where((c) => c.valeur == valeur).firstOrNull?.libelle ?? valeur;
    return InkWell(
      onTap: () => _ouvrir(context),
      borderRadius: BorderRadius.circular(YsemTokens.rayon),
      child: InputDecorator(
        isEmpty: valeur.isEmpty,
        decoration: InputDecoration(
          labelText: libelle,
          helperText: aide,
          helperMaxLines: 3,
          errorText: erreur,
          errorMaxLines: 3,
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
        ),
        child: Text(affiche),
      ),
    );
  }
}

class _FeuilleDeChoix extends StatefulWidget {
  const _FeuilleDeChoix({
    required this.titre,
    required this.choix,
    required this.valeur,
    required this.effacable,
  });

  final String titre;
  final List<OptionChamp> choix;
  final String valeur;
  final bool effacable;

  @override
  State<_FeuilleDeChoix> createState() => _FeuilleDeChoixState();
}

class _FeuilleDeChoixState extends State<_FeuilleDeChoix> {
  /// Au-delà, on cherche plus vite qu'on ne fait défiler.
  static const _seuilRecherche = 8;

  String _recherche = '';

  /// « yaounde » trouve « Yaoundé ».
  static String _normaliser(String texte) {
    const accents = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'ç': 'c', 'é': 'e', 'è': 'e', 'ê': 'e', //
      'ë': 'e', 'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o', 'ù': 'u', 'û': 'u',
      'ü': 'u', 'ÿ': 'y',
    };
    return texte
        .toLowerCase()
        .split('')
        .map((lettre) => accents[lettre] ?? lettre)
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final recherche = _normaliser(_recherche.trim());
    final options = recherche.isEmpty
        ? widget.choix
        : widget.choix
            .where((c) => _normaliser(c.libelle).contains(recherche))
            .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(widget.titre, style: theme.textTheme.titleMedium),
            ),
            if (widget.choix.length > _seuilRecherche)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _recherche = v),
                  decoration: InputDecoration(
                    hintText: t.rechercherDansLaListe,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                children: [
                  if (widget.effacable)
                    ListTile(
                      leading: const Icon(Icons.clear_rounded),
                      title: Text(t.effacerLaSelection),
                      onTap: () => Navigator.of(context).pop(''),
                    ),
                  for (final option in options)
                    ListTile(
                      title: Text(option.libelle),
                      selected: option.valeur == widget.valeur,
                      trailing: option.valeur == widget.valeur
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () => Navigator.of(context).pop(option.valeur),
                    ),
                  if (options.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(t.aucunChoixTrouve,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
