import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/format/formats.dart';
import '../../../core/network/api_exception.dart';
import '../../commun/position.dart';
import '../data/etudiant_repository.dart';
import '../domain/delegation.dart';
import 'base_hors_ligne.dart';
import 'paquet.dart';
import 'saisie_locale.dart';
import 'synchroniseur.dart';

/// Ce que le délégué voit d'une journée : la délégation et, séance par séance,
/// ce qui n'a pas encore trouvé sa place sur le serveur.
class VueDelegation {
  const VueDelegation({
    required this.etat,
    this.saisies = const [],
    this.luLe,
    this.valableJusquAu,
  });

  final Delegation etat;
  final List<SaisieLocale> saisies;

  /// Quand le paquet a été lu ; `null` pour une lecture directe du serveur.
  final DateTime? luLe;
  final DateTime? valableJusquAu;

  bool get depuisLePaquet => luLe != null;

  int get aEnvoyer =>
      saisies.where((s) => s.etat == EtatSaisie.enAttente).length;

  /// La saisie du téléphone à montrer pour une séance : la plus récente.
  SaisieLocale? saisieDe(String cle, String geste) {
    SaisieLocale? retenue;
    for (final s in saisies) {
      if (s.cle == cle && s.geste == geste) retenue = s;
    }
    return retenue;
  }

  /// Ce que le serveur n'a pas accepté d'office, toutes journées confondues.
  List<SaisieLocale> get aSuivre => [
        for (final s in saisies)
          if (s.etat == EtatSaisie.aArbitrer ||
              s.etat == EtatSaisie.ecartee ||
              s.etat == EtatSaisie.refusee)
            s,
      ];
}

/// Ce que l'écran affiche une fois la saisie enregistrée.
class IssueEnregistrement {
  const IssueEnregistrement.serveur(String this.message)
      : genre = GenreIssue.transmise;
  const IssueEnregistrement.saisie(this.genre, {this.message});

  final GenreIssue genre;

  /// Le message du serveur, quand il en a rendu un.
  final String? message;
}

/// La délégation vue par les écrans : le paquet quand il couvre la séance, le
/// serveur sinon.
///
/// Toute saisie sur une séance du paquet passe par le téléphone, réseau ou
/// non : un seul chemin d'écriture, et rien à perdre si le réseau tombe au
/// moment d'envoyer. Sans paquet — hors ligne désactivé par l'établissement,
/// journée lointaine, base indisponible —, les écrans parlent au serveur comme
/// ils l'ont toujours fait.
class DepotDelegation {
  DepotDelegation({
    required this.depot,
    required this.base,
    required this.synchroniseur,
    required this.matriculeSession,
    this.apresSaisie,
    DateTime Function()? horloge,
  }) : _horloge = horloge ?? DateTime.now;

  final EtudiantRepository depot;
  final BaseHorsLigne? base;
  final Synchroniseur? synchroniseur;
  final String? Function() matriculeSession;

  /// Appelée quand une saisie reste à envoyer : la tâche de fond s'en chargera
  /// au retour du réseau, même l'application fermée.
  final Future<void> Function()? apresSaisie;
  final DateTime Function() _horloge;

  Future<String?> _matricule() async {
    final base = this.base;
    if (base == null) return null;
    final session = matriculeSession();
    if (session != null && session.isNotEmpty) {
      if (await base.matriculeActif() != session) {
        await base.definirMatricule(session);
      }
      return session;
    }
    return base.matriculeActif();
  }

  Future<Paquet?> _paquet(String matricule) async {
    final garde = await base!.lirePaquet(matricule);
    return garde == null ? null : Paquet(garde);
  }

  Future<DateTime> _maintenant(Paquet paquet) async =>
      paquet.maintenant(_horloge(), await synchroniseur!.compteur());

  /// Une journée (`null` : aujourd'hui).
  Future<VueDelegation> delegation({String? jour}) async {
    final matricule = await _matricule();
    if (matricule != null) {
      var paquet = await _paquet(matricule);
      if (paquet == null) {
        await _premierPaquet();
        paquet = await _paquet(matricule);
      }
      if (paquet != null) {
        final vue = await _vueDuPaquet(paquet, matricule, jour);
        if (vue != null) return vue;
      }
    } else if (base != null) {
      await _premierPaquet();
      final trouve = await _matricule();
      if (trouve != null) {
        final paquet = await _paquet(trouve);
        if (paquet != null) {
          final vue = await _vueDuPaquet(paquet, trouve, jour);
          if (vue != null) return vue;
        }
      }
    }
    return VueDelegation(etat: await depot.delegation(jour: jour));
  }

  Future<VueDelegation?> _vueDuPaquet(
      Paquet paquet, String matricule, String? jour) async {
    final maintenant = await _maintenant(paquet);
    final date = jour == null
        ? DateTime.parse(Formats.iso(maintenant.toLocal()))
        : DateTime.parse(jour);
    if (!paquet.couvre(date)) return null;
    return VueDelegation(
      etat: paquet.delegationDuJour(date, maintenant),
      saisies: await base!.saisiesDe(matricule),
      luLe: paquet.luLe,
      valableJusquAu: paquet.au,
    );
  }

  Future<void> _premierPaquet() async {
    try {
      await synchroniseur?.rafraichirPaquet();
    } on ApiException catch (e) {
      debugPrint('Paquet hors ligne indisponible : $e');
    }
  }

  /// Le paquet et la séance, quand la séance y figure.
  Future<(String, Paquet)?> _portee(SeanceDelegue seance) async {
    if (seance.cle.isEmpty) return null;
    final matricule = await _matricule();
    if (matricule == null) return null;
    final paquet = await _paquet(matricule);
    if (paquet == null || !paquet.contient(seance.cle)) return null;
    return (matricule, paquet);
  }

  Future<SaisieLocale?> _saisieEnCours(
      String matricule, String cle, String geste) async {
    SaisieLocale? retenue;
    for (final s in await base!.saisiesDe(matricule)) {
      if (s.cle == cle &&
          s.geste == geste &&
          (s.etat == EtatSaisie.enAttente ||
              s.etat == EtatSaisie.transmise ||
              s.etat == EtatSaisie.aArbitrer)) {
        retenue = s;
      }
    }
    return retenue;
  }

  Future<int?> precisionMax(SeanceDelegue seance) async {
    final portee = await _portee(seance);
    return portee?.$2.precisionMax;
  }

  Future<FeuilleAppel> feuilleAppel(SeanceDelegue seance) async {
    final portee = await _portee(seance);
    if (portee != null) {
      final (matricule, paquet) = portee;
      final feuille = paquet.feuilleAppel(
        seance.cle,
        await _maintenant(paquet),
        await _saisieEnCours(matricule, seance.cle, SaisieLocale.gesteAppel),
      );
      if (feuille != null) return feuille;
    }
    return depot.feuilleAppel(seance);
  }

  Future<FeuilleCahier> feuilleCahier(SeanceDelegue seance) async {
    final portee = await _portee(seance);
    if (portee != null) {
      final (matricule, paquet) = portee;
      final feuille = paquet.feuilleCahier(
        seance.cle,
        await _maintenant(paquet),
        await _saisieEnCours(matricule, seance.cle, SaisieLocale.gesteCahier),
        await base!.saisiesDe(matricule),
      );
      if (feuille != null) return feuille;
    }
    return depot.feuilleCahier(seance);
  }

  Future<IssueEnregistrement> enregistrerAppel(
    SeanceDelegue seance, {
    required List<int> absents,
    PositionRelevee? position,
  }) async {
    final portee = await _portee(seance);
    if (portee == null) {
      return IssueEnregistrement.serveur(await depot.enregistrerAppel(
        seance,
        absents: absents,
        position: position,
      ));
    }
    return _enregistrer(
      portee.$1,
      seance,
      SaisieLocale.gesteAppel,
      {'absents': absents, ...?position?.champs},
    );
  }

  Future<IssueEnregistrement> enregistrerCahier(
    SeanceDelegue seance, {
    required Map<String, String> activites,
    required List<int> seancesFaites,
    PositionRelevee? position,
  }) async {
    final portee = await _portee(seance);
    if (portee == null) {
      return IssueEnregistrement.serveur(await depot.enregistrerCahier(
        seance,
        activites: activites,
        seancesFaites: seancesFaites,
        position: position,
      ));
    }
    return _enregistrer(
      portee.$1,
      seance,
      SaisieLocale.gesteCahier,
      {'activites': activites, 'blocs': seancesFaites, ...?position?.champs},
    );
  }

  Future<IssueEnregistrement> _enregistrer(String matricule,
      SeanceDelegue seance, String geste, Map<String, dynamic> contenu) async {
    final sync = synchroniseur!;
    final saisie = SaisieLocale(
      reference: nouvelleReference(),
      matricule: matricule,
      geste: geste,
      cle: seance.cle,
      jour: Formats.iso(seance.date!),
      charge: {...EtudiantRepository.designationDe(seance), ...contenu},
      saisiLe: _horloge(),
      compteur: await sync.compteur(),
    );
    final issue = await sync.enregistrer(saisie);
    if (issue.genre == GenreIssue.surLeTelephone) await apresSaisie?.call();
    return IssueEnregistrement.saisie(issue.genre, message: issue.detail);
  }

  /// Retire une saisie que le serveur n'a pas pu lire : le délégué en a pris
  /// connaissance.
  Future<void> oublierSaisie(SaisieLocale saisie) async =>
      base?.supprimerSaisie(saisie.reference);

  /// Envoie ce qui attend, puis relit le paquet.
  Future<void> synchroniser() async {
    final matricule = await _matricule();
    final sync = synchroniseur;
    if (matricule == null || sync == null) return;
    await sync.envoyerEnAttente(matricule);
    try {
      await sync.rafraichirPaquet();
    } on ApiException catch (e) {
      debugPrint('Paquet hors ligne non relu : $e');
    }
  }
}

final _aleatoire = Random.secure();

/// Un UUID v4 : c'est lui qui rend l'envoi rejouable.
String nouvelleReference() {
  final octets = List<int>.generate(16, (_) => _aleatoire.nextInt(256));
  octets[6] = (octets[6] & 0x0f) | 0x40;
  octets[8] = (octets[8] & 0x3f) | 0x80;
  final hex = octets.map((o) => o.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
