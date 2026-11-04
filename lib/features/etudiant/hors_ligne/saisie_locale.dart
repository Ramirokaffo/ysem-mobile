import 'dart:convert';

import 'package:horloge_monotone/horloge_monotone.dart';

/// Où en est une saisie gardée sur le téléphone.
enum EtatSaisie {
  /// Pas encore transmise : elle part dès que le réseau le permet.
  enAttente('en_attente'),

  /// Transmise et enregistrée ; la ligne tombe à la prochaine lecture du
  /// paquet, qui porte alors le constat.
  transmise('transmise'),

  /// Transmise, mais le service doit trancher.
  aArbitrer('a_arbitrer'),
  retenue('retenue'),
  ecartee('ecartee'),

  /// Le serveur n'a rien pu en faire : à refaire.
  refusee('refusee');

  const EtatSaisie(this.code);

  final String code;

  static EtatSaisie depuisCode(String code) => values.firstWhere(
        (e) => e.code == code,
        orElse: () => enAttente,
      );

  /// Traduit le statut rendu par le serveur.
  static EtatSaisie depuisServeur(String statut) => switch (statut) {
        'a_arbitrer' => aArbitrer,
        'retenue' => retenue,
        'ecartee' => ecartee,
        'refusee' => refusee,
        _ => transmise,
      };
}

/// Une saisie du délégué : ce qu'il a fait, tel qu'il partira au serveur.
class SaisieLocale {
  const SaisieLocale({
    required this.reference,
    required this.matricule,
    required this.geste,
    required this.cle,
    required this.jour,
    required this.charge,
    required this.saisiLe,
    this.compteur,
    this.etat = EtatSaisie.enAttente,
    this.motif = '',
    this.detail = '',
  });

  static const gesteAppel = 'appel';
  static const gesteCahier = 'cahier';

  /// Tirée ici et jamais changée : c'est elle qui rend l'envoi rejouable.
  final String reference;
  final String matricule;
  final String geste;

  /// Clé de la séance, celle du paquet.
  final String cle;
  final String jour;

  /// Le corps de l'envoi, sans ce qui se calcule au moment de partir.
  final Map<String, dynamic> charge;

  /// Heure affichée par le téléphone à la saisie.
  final DateTime saisiLe;

  /// Compteur interne à la saisie : le serveur en déduit le temps écoulé.
  final LectureCompteur? compteur;
  final EtatSaisie etat;
  final String motif;
  final String detail;

  List<int> get absents => [
        for (final v in (charge['absents'] as List? ?? const []))
          if (v is int) v,
      ];

  List<int> get blocs => [
        for (final v in (charge['blocs'] as List? ?? const []))
          if (v is int) v,
      ];

  Map<String, String> get activites => {
        for (final MapEntry(:key, :value)
            in (charge['activites'] as Map? ?? const {}).entries)
          '$key': '$value',
      };

  /// L'envoi tel qu'il part : `maintenant` est le compteur à l'instant de
  /// l'envoi. Un redémarrage entre-temps laisse `ecoule_ms` absent, et le
  /// serveur retient alors l'heure déclarée, marquée comme non vérifiée.
  Map<String, dynamic> envoi(LectureCompteur? maintenant) {
    final avant = compteur;
    final ecoule =
        avant == null || maintenant == null ? null : maintenant.ecouleDepuis(avant);
    return {
      ...charge,
      'reference': reference,
      'geste': geste,
      'saisi_le': saisiLe.toUtc().toIso8601String(),
      'ecoule_ms': ?ecoule,
    };
  }

  Map<String, Object?> versLigne() => {
        'reference': reference,
        'matricule': matricule,
        'geste': geste,
        'cle': cle,
        'jour': jour,
        'charge': jsonEncode(charge),
        'saisi_le': saisiLe.toUtc().toIso8601String(),
        'compteur_ms': compteur?.ms,
        'compteur_demarrage': compteur?.demarrage,
        'etat': etat.code,
        'motif': motif,
        'detail': detail,
      };

  factory SaisieLocale.depuisLigne(Map<String, Object?> ligne) {
    final ms = ligne['compteur_ms'] as int?;
    return SaisieLocale(
      reference: ligne['reference'] as String,
      matricule: ligne['matricule'] as String,
      geste: ligne['geste'] as String,
      cle: ligne['cle'] as String,
      jour: ligne['jour'] as String,
      charge: Map<String, dynamic>.from(
          jsonDecode(ligne['charge'] as String) as Map),
      saisiLe: DateTime.parse(ligne['saisi_le'] as String),
      compteur: ms == null
          ? null
          : LectureCompteur(
              ms: ms, demarrage: ligne['compteur_demarrage'] as int?),
      etat: EtatSaisie.depuisCode(ligne['etat'] as String),
      motif: ligne['motif'] as String? ?? '',
      detail: ligne['detail'] as String? ?? '',
    );
  }
}
