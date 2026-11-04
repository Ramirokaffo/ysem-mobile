import 'package:horloge_monotone/horloge_monotone.dart';

import '../../../core/format/formats.dart';
import '../../../core/models/json.dart';
import '../domain/delegation.dart';
import 'base_hors_ligne.dart';
import 'saisie_locale.dart';

/// Le paquet de la semaine, et les règles qui se rejouent sans serveur.
///
/// Il ne compose aucun modèle à part : il rend le JSON qu'auraient rendu
/// `delegation/`, `delegation/appel/` et `delegation/cahier/`, et ce sont les
/// mêmes lecteurs qui le lisent. Les écrans n'ont donc pas deux façons de
/// montrer une séance selon que le réseau est là ou non.
class Paquet {
  Paquet(this._garde)
      : _etudiants = {
          for (final e in _garde.contenu.liste('etudiants', (j) => j))
            e.entier('id') ?? 0: e,
        },
        _plans = {
          for (final p in _garde.contenu.liste('plans', (j) => j))
            p.entier('id') ?? 0: p.liste('seances', (j) => j),
        },
        _seances = _garde.contenu.liste('seances', (j) => j);

  final PaquetGarde _garde;
  final Map<int, Json> _etudiants;
  final Map<int, List<Json>> _plans;
  final List<Json> _seances;

  Json get _contenu => _garde.contenu;

  DateTime get luLe => _garde.luLe;
  DateTime? get du => _contenu.date('du');
  DateTime? get au => _contenu.date('au');

  /// L'imprécision maximale acceptée par le serveur, en mètres.
  int? get precisionMax => _contenu.objet('geolocalisation')?.entier('precision_max');

  /// L'heure à laquelle se comparent les fenêtres.
  ///
  /// L'heure du serveur à la lecture, plus le temps écoulé au compteur interne :
  /// changer l'heure du téléphone n'ouvre rien. Sans compteur comparable
  /// (redémarrage), l'horloge du téléphone, corrigée de l'écart constaté à la
  /// lecture.
  DateTime maintenant(DateTime horlogeAppareil, LectureCompteur? compteur) {
    final avant = _garde.compteur;
    final ecoule =
        avant == null || compteur == null ? null : compteur.ecouleDepuis(avant);
    if (ecoule != null) {
      return _garde.horlogeServeur.add(Duration(milliseconds: ecoule));
    }
    return horlogeAppareil.add(_garde.horlogeServeur.difference(_garde.luLe));
  }

  bool couvre(DateTime jour) {
    final iso = Formats.iso(jour);
    return _seances.any((s) => s.texte('date') == iso) ||
        (du != null &&
            au != null &&
            !jour.isBefore(du!) &&
            !jour.isAfter(au!));
  }

  Json? _seance(String cle) {
    for (final s in _seances) {
      if (s.texte('cle') == cle) return s;
    }
    return null;
  }

  bool contient(String cle) => _seance(cle) != null;

  /// Rejoue l'état d'une séance à l'heure dite.
  ///
  /// Le serveur a rendu cet état à la lecture du paquet. Ce qui ne dépend que
  /// du temps se recalcule ; le reste — annulée, signée, renvoyée — reste ce
  /// qu'il a dit.
  static Json reevaluer(Json seance, DateTime maintenant) {
    final appel = _etatFenetre(
      etat: seance.texte('etat'),
      ouverture: seance.date('ouverture'),
      fermeture: seance.date('fermeture'),
      maintenant: maintenant,
    );
    final resultat = Map<String, dynamic>.of(seance);
    if (appel != null) {
      resultat['etat'] = appel;
      resultat['ouverte'] = appel == 'ouverte';
    }
    final cahier = seance.objet('cahier_texte');
    if (cahier != null) {
      final etat = _etatFenetre(
        etat: cahier.texte('etat'),
        ouverture: cahier.date('ouverture'),
        fermeture: cahier.date('fermeture'),
        maintenant: maintenant,
      );
      if (etat != null) {
        resultat['cahier_texte'] = {
          ...cahier,
          'etat': etat,
          'ouvert': etat == 'ouverte',
        };
      }
    }
    return resultat;
  }

  static const _etatsDuTemps = {'ouverte', 'a_venir', 'close'};

  static String? _etatFenetre({
    required String etat,
    required DateTime? ouverture,
    required DateTime? fermeture,
    required DateTime maintenant,
  }) {
    if (!_etatsDuTemps.contains(etat) || ouverture == null || fermeture == null) {
      return null;
    }
    if (maintenant.isBefore(ouverture)) return 'a_venir';
    return maintenant.isAfter(fermeture) ? 'close' : 'ouverte';
  }

  /// Ce que rendrait `delegation/?jour=`.
  Delegation delegationDuJour(DateTime jour, DateTime maintenant) {
    final iso = Formats.iso(jour);
    final aujourdhui = maintenant.toLocal();
    return Delegation.depuisJson({
      ..._contenu,
      'jour': iso,
      'veille': Formats.iso(jour.subtract(const Duration(days: 1))),
      'lendemain': Formats.iso(jour.add(const Duration(days: 1))),
      'aujourd_hui': Formats.iso(aujourdhui),
      'seances': [
        for (final s in _seances)
          if (s.texte('date') == iso) reevaluer(s, maintenant),
      ],
    });
  }

  /// Ce que rendrait `delegation/appel/`, une saisie en cours primant sur ce
  /// que le serveur connaissait.
  FeuilleAppel? feuilleAppel(String cle, DateTime maintenant, SaisieLocale? saisie) {
    final seance = _seance(cle);
    if (seance == null) return null;
    final permissions = {
      for (final p in seance.liste('permissions', (j) => j))
        p.entier('etudiant') ?? 0: p,
    };
    final absents = saisie?.absents ?? _entiers(seance['absents']);
    return FeuilleAppel.depuisJson({
      'seance': reevaluer(seance, maintenant),
      'deja_relevee': seance.booleen('deja_relevee'),
      'appel': seance['appel'],
      'position_exigee': seance.booleen('position_appel'),
      'lignes': [
        for (final id in _entiers(seance['etudiants']))
          if (_etudiants[id] case final etudiant?)
            {
              'etudiant': etudiant,
              'absent': (permissions[id]?.booleen('verrouillee') ?? false) ||
                  absents.contains(id),
              'verrouillee': permissions[id]?.booleen('verrouillee') ?? false,
              'permission': permissions[id],
            },
      ],
    });
  }

  /// Le rang de la séance dans le programme, ce que le téléphone a recueilli
  /// compris. Même règle que `Teaching.cahier.rang_pedagogique` : un cahier
  /// d'une séance antérieure avance le rang, sans quoi deux séances tenues
  /// sans réseau proposeraient le même contenu. Le serveur le recalcule de
  /// toute façon : ce n'est ici que ce qu'on montre au délégué.
  int rangLocal(Json seance, Iterable<SaisieLocale> saisies) {
    final plan = _plans[seance.entier('plan')] ?? const <Json>[];
    final numeros = {
      for (final ligne in plan) ligne.entier('id') ?? 0: ligne.entier('numero') ?? 0,
    };
    var rang = seance.entier('rang') ?? 1;
    final date = seance.texte('date');
    final cle = seance.texte('cle');
    final anterieures = [
      for (final s in saisies)
        if (s.geste == SaisieLocale.gesteCahier &&
            s.cle != cle &&
            s.jour.compareTo(date) < 0 &&
            (s.etat == EtatSaisie.enAttente || s.etat == EtatSaisie.transmise) &&
            _seance(s.cle)?.entier('plan') == seance.entier('plan'))
          s,
    ];
    final atteints = [
      for (final s in anterieures)
        for (final id in s.blocs)
          if (numeros[id] != null) numeros[id]!,
    ];
    if (atteints.isNotEmpty) {
      final dernier = atteints.reduce((a, b) => a > b ? a : b);
      if (dernier + 1 > rang) rang = dernier + 1;
    }
    return rang + anterieures.where((s) => s.blocs.isEmpty).length;
  }

  /// Le contenu prévu des trois premiers blocs, au-delà du plan sa dernière
  /// séance : `Teaching.cahier.programmes_prevus`.
  List<Json> _contenusPrevus(List<Json> plan, int rang) {
    if (plan.isEmpty) return const [];
    final parNumero = {for (final l in plan) l.entier('numero') ?? 0: l};
    final dernier = parNumero[parNumero.keys.reduce((a, b) => a > b ? a : b)]!;
    return [for (var i = 0; i < 3; i++) parNumero[rang + i] ?? dernier];
  }

  /// Ce que rendrait `delegation/cahier/`.
  FeuilleCahier? feuilleCahier(
    String cle,
    DateTime maintenant,
    SaisieLocale? saisie,
    Iterable<SaisieLocale> saisies,
  ) {
    final seance = _seance(cle);
    if (seance == null) return null;
    final plan = _plans[seance.entier('plan')] ?? const <Json>[];
    final cahier = seance.objet('cahier_texte')?.objet('cahier');
    return FeuilleCahier.depuisJson({
      'seance': reevaluer(seance, maintenant),
      'circuit': _contenu['circuit_cahier'],
      'position_exigee': seance.booleen('position_cahier'),
      'cahier': saisie == null
          ? cahier
          : {
              ...?cahier,
              'activites': saisie.activites,
              'blocs': [
                for (final id in saisie.blocs)
                  {
                    'programme_fait': {'id': id},
                  },
              ],
            },
      'contenus_prevus': _contenusPrevus(plan, rangLocal(seance, saisies)),
      'seances_plan': plan,
      'groupes_activites': _contenu['groupes_activites'],
    });
  }

  static List<int> _entiers(Object? valeur) => [
        for (final v in (valeur as List? ?? const []))
          if (v is int) v,
      ];
}
