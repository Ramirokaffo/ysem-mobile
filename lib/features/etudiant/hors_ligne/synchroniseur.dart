import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:horloge_monotone/horloge_monotone.dart';

import '../../../core/models/json.dart';
import '../../../core/network/api_exception.dart';
import 'base_hors_ligne.dart';
import 'saisie_locale.dart';

/// Les deux routes du serveur dont la synchronisation a besoin.
abstract class ServeurHorsLigne {
  Future<Json> lirePaquet();

  Future<Json> envoyer(List<Json> saisies, {required bool immediate});
}

/// Ce qu'il est advenu d'une saisie que le délégué vient d'enregistrer.
enum GenreIssue {
  /// Le serveur l'a enregistrée.
  transmise,

  /// Pas de réseau : elle partira toute seule.
  surLeTelephone,

  /// Reçue, mais le service doit trancher.
  aArbitrer,
}

class IssueSaisie {
  const IssueSaisie(this.genre, {this.detail = ''});

  final GenreIssue genre;
  final String detail;
}

/// Va et vient entre le téléphone et le serveur.
///
/// Rien n'est perdu quand la réponse manque : une ligne ne quitte
/// `en_attente` que sur le résultat du serveur, et renvoyer une saisie déjà
/// reçue rend le même résultat (`discipline.hors_ligne`).
class Synchroniseur {
  Synchroniseur({
    required this.base,
    required this.serveur,
    HorlogeMonotone horloge = const HorlogeMonotone(),
    DateTime Function()? maintenant,
  })  : _horloge = horloge,
        _maintenant = maintenant ?? DateTime.now;

  final BaseHorsLigne base;
  final ServeurHorsLigne serveur;
  final HorlogeMonotone _horloge;
  final DateTime Function() _maintenant;

  static const tailleLot = 50;

  /// Devant son écran, le délégué n'attend pas un réseau à une barre. Si la
  /// réponse arrive trop tard, l'envoi repartira : le rejeu est sans effet.
  static const attenteMaximale = Duration(seconds: 12);

  Future<void>? _enCours;

  Future<LectureCompteur?> compteur() => _horloge.lire();

  /// Enregistre sur le téléphone, puis tente l'envoi.
  ///
  /// Le délégué est devant son écran : ce qu'il peut encore corriger (position,
  /// fenêtre) lui est refusé sur-le-champ par une [ApiException], et la saisie
  /// qu'il corrigeait lui est rendue. Sans réseau, tout reste ici.
  Future<IssueSaisie> enregistrer(SaisieLocale saisie) async {
    final remplacees = (await base.saisiesDe(saisie.matricule))
        .where((s) =>
            s.geste == saisie.geste &&
            s.cle == saisie.cle &&
            s.etat == EtatSaisie.enAttente)
        .toList();
    await base.enregistrerSaisie(saisie);

    final Json reponse;
    try {
      reponse = await serveur.envoyer(
        [saisie.envoi(await _horloge.lire())],
        immediate: true,
      ).timeout(attenteMaximale);
    } on ApiException {
      // Réseau, session expirée, serveur en panne : aucune réponse ne dit
      // que la saisie est perdue, elle reste à envoyer.
      return const IssueSaisie(GenreIssue.surLeTelephone);
    } on TimeoutException {
      return const IssueSaisie(GenreIssue.surLeTelephone);
    }

    final resultats = reponse.liste('resultats', (j) => j);
    if (resultats.isEmpty) return const IssueSaisie(GenreIssue.surLeTelephone);
    final resultat = resultats.first;
    final statut = resultat.texte('statut');
    final detail = _detail(resultat);

    if (statut == 'reessayer') {
      return const IssueSaisie(GenreIssue.surLeTelephone);
    }
    if (statut == 'refusee') {
      await base.supprimerSaisie(saisie.reference);
      for (final ancienne in remplacees) {
        await base.enregistrerSaisie(ancienne);
      }
      throw ApiException(
        code: resultat.texte('motif'),
        message: detail,
        statut: 403,
      );
    }
    await _poser(saisie.reference, resultat);
    return statut == 'a_arbitrer'
        ? IssueSaisie(GenreIssue.aArbitrer, detail: detail)
        : const IssueSaisie(GenreIssue.transmise);
  }

  /// Envoie tout ce qui attend. Rend `true` quand plus rien n'attend.
  ///
  /// Une seule à la fois dans ce processus ; la tâche de fond peut croiser
  /// l'écran, et c'est alors la référence qui protège.
  Future<bool> envoyerEnAttente(String matricule) async {
    final enCours = _enCours;
    if (enCours != null) await enCours;
    final termine = _envoyer(matricule);
    _enCours = termine.then((_) {}, onError: (_) {});
    try {
      return await termine;
    } finally {
      _enCours = null;
    }
  }

  Future<bool> _envoyer(String matricule) async {
    while (true) {
      final lot = await base.saisiesAEnvoyer(matricule, limite: tailleLot);
      if (lot.isEmpty) return true;
      final Json reponse;
      try {
        final compteur = await _horloge.lire();
        reponse = await serveur.envoyer(
          [for (final s in lot) s.envoi(compteur)],
          immediate: false,
        );
      } on ApiException catch (e) {
        debugPrint('Synchronisation interrompue : $e');
        return false;
      }
      var avancees = 0;
      for (final resultat in reponse.liste('resultats', (j) => j)) {
        if (resultat.texte('statut') == 'reessayer') continue;
        final reference = resultat.texte('reference');
        if (reference.isEmpty) continue;
        await _poser(reference, resultat);
        avancees++;
      }
      // Ce qui n'a pas avancé repartira au prochain passage : rejouer tout de
      // suite ne ferait que marteler le serveur.
      if (avancees == 0) return false;
    }
  }

  Future<void> _poser(String reference, Json resultat) => base.poserEtat(
        reference,
        EtatSaisie.depuisServeur(resultat.texte('statut')),
        motif: resultat.texte('motif'),
        detail: _detail(resultat),
      );

  static String _detail(Json resultat) {
    final detail = resultat.texte('detail');
    return detail.isNotEmpty ? detail : resultat.texte('motif_libelle');
  }

  /// Relit le paquet et le sort de ce qui a été transmis.
  ///
  /// Rend `true` quand un paquet est gardé à l'issue. Une erreur réseau laisse
  /// l'ancien paquet en place : il sert justement à ça.
  Future<bool> rafraichirPaquet() async {
    final Json contenu;
    final debut = _maintenant();
    final compteur = await _horloge.lire();
    final actif = await base.matriculeActif();
    try {
      contenu = await serveur.lirePaquet();
    } on ApiException catch (e) {
      if (e.code == 'non_delegue' && actif != null) {
        await base.supprimerPaquet(actif);
        return false;
      }
      rethrow;
    }

    final matricule =
        contenu.objet('membre')?.objet('etudiant')?.texte('matricule') ?? actif;
    if (matricule == null || matricule.isEmpty) return false;

    await _relireLeSort(matricule, contenu);
    if (!contenu.booleen('actif')) {
      await base.supprimerPaquet(matricule);
      return false;
    }
    await base.definirMatricule(matricule);
    await base.ecrirePaquet(
      matricule,
      contenu,
      luLe: debut,
      horlogeServeur: contenu.date('horloge_serveur') ?? debut,
      compteur: compteur,
    );
    await base.purgerTransmises(matricule);
    return true;
  }

  /// Le service a tranché : la ligne le dit, ou tombe si le paquet porte le
  /// constat. Une ligne dont le serveur ne parle plus a fait son temps.
  Future<void> _relireLeSort(String matricule, Json contenu) async {
    final connues = {
      for (final s in contenu.liste('saisies', (j) => j)) s.texte('reference'): s,
    };
    for (final saisie in await base.saisiesDe(matricule)) {
      final suivie = saisie.etat == EtatSaisie.aArbitrer ||
          saisie.etat == EtatSaisie.ecartee ||
          saisie.etat == EtatSaisie.retenue;
      if (!suivie) continue;
      final sort = connues[saisie.reference];
      if (sort == null || sort.texte('statut') == 'retenue') {
        await base.supprimerSaisie(saisie.reference);
      } else {
        await _poser(saisie.reference, sort);
      }
    }
  }
}
