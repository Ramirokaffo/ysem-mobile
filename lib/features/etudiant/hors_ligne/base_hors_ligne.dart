import 'dart:convert';

import 'package:horloge_monotone/horloge_monotone.dart';
import 'package:path/path.dart' as chemin;
import 'package:sqflite/sqflite.dart';

import 'saisie_locale.dart';

/// Ce que le téléphone garde pour le délégué : le paquet de la semaine et les
/// saisies qui n'ont pas encore trouvé leur place sur le serveur.
///
/// Une base SQLite plutôt qu'un fichier : une saisie doit survivre à une
/// batterie vide au milieu d'une écriture, et la tâche de fond écrit en même
/// temps que l'écran. Dossier privé de l'application, hors des sauvegardes.
class BaseHorsLigne {
  BaseHorsLigne(this._base);

  final Database _base;

  static const nomFichier = 'hors_ligne.db';
  static const _cleMatricule = 'matricule';

  static Future<void> creer(Database base, int _) async {
    await base.execute('''
      CREATE TABLE paquet (
        matricule TEXT PRIMARY KEY,
        contenu TEXT NOT NULL,
        lu_le TEXT NOT NULL,
        horloge_serveur TEXT NOT NULL,
        compteur_ms INTEGER,
        compteur_demarrage INTEGER
      )''');
    await base.execute('''
      CREATE TABLE saisie (
        reference TEXT PRIMARY KEY,
        matricule TEXT NOT NULL,
        geste TEXT NOT NULL,
        cle TEXT NOT NULL,
        jour TEXT NOT NULL,
        charge TEXT NOT NULL,
        saisi_le TEXT NOT NULL,
        compteur_ms INTEGER,
        compteur_demarrage INTEGER,
        etat TEXT NOT NULL,
        motif TEXT NOT NULL DEFAULT '',
        detail TEXT NOT NULL DEFAULT ''
      )''');
    await base.execute(
        'CREATE INDEX saisie_etat ON saisie (matricule, etat, jour)');
    await base.execute(
        'CREATE TABLE meta (cle TEXT PRIMARY KEY, valeur TEXT NOT NULL)');
  }

  static Future<BaseHorsLigne> ouvrir() async {
    final dossier = await getDatabasesPath();
    final base = await openDatabase(
      chemin.join(dossier, nomFichier),
      version: 1,
      onCreate: creer,
    );
    return BaseHorsLigne(base);
  }

  // --- À qui appartient ce qui est gardé -------------------------------

  Future<String?> matriculeActif() async {
    final lignes = await _base.query('meta',
        where: 'cle = ?', whereArgs: [_cleMatricule], limit: 1);
    return lignes.isEmpty ? null : lignes.first['valeur'] as String;
  }

  /// Un autre étudiant ouvre l'application : le paquet du précédent, qui
  /// nomme toute sa classe, n'a pas à rester. Ses saisies, elles, attendent
  /// son retour sans jamais s'afficher ni partir sous un autre compte.
  Future<void> definirMatricule(String matricule) async {
    await _base.transaction((tx) async {
      await tx.delete('paquet', where: 'matricule <> ?', whereArgs: [matricule]);
      await tx.insert('meta', {'cle': _cleMatricule, 'valeur': matricule},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  /// Déconnexion volontaire : plus rien de lisible, les saisies non envoyées
  /// restent pour la prochaine connexion du même compte.
  Future<void> oublierPaquet() async {
    await _base.transaction((tx) async {
      await tx.delete('paquet');
      await tx.delete('meta', where: 'cle = ?', whereArgs: [_cleMatricule]);
    });
  }

  // --- Le paquet -------------------------------------------------------

  Future<void> ecrirePaquet(
    String matricule,
    Map<String, dynamic> contenu, {
    required DateTime luLe,
    required DateTime horlogeServeur,
    LectureCompteur? compteur,
  }) =>
      _base.insert(
        'paquet',
        {
          'matricule': matricule,
          'contenu': jsonEncode(contenu),
          'lu_le': luLe.toUtc().toIso8601String(),
          'horloge_serveur': horlogeServeur.toUtc().toIso8601String(),
          'compteur_ms': compteur?.ms,
          'compteur_demarrage': compteur?.demarrage,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> supprimerPaquet(String matricule) =>
      _base.delete('paquet', where: 'matricule = ?', whereArgs: [matricule]);

  Future<PaquetGarde?> lirePaquet(String matricule) async {
    final lignes = await _base.query('paquet',
        where: 'matricule = ?', whereArgs: [matricule], limit: 1);
    if (lignes.isEmpty) return null;
    final ligne = lignes.first;
    final ms = ligne['compteur_ms'] as int?;
    return PaquetGarde(
      contenu: Map<String, dynamic>.from(
          jsonDecode(ligne['contenu'] as String) as Map),
      luLe: DateTime.parse(ligne['lu_le'] as String),
      horlogeServeur: DateTime.parse(ligne['horloge_serveur'] as String),
      compteur: ms == null
          ? null
          : LectureCompteur(
              ms: ms, demarrage: ligne['compteur_demarrage'] as int?),
    );
  }

  Future<bool> aUnPaquet() async {
    final matricule = await matriculeActif();
    if (matricule == null) return false;
    return (await _base.query('paquet',
            columns: ['matricule'],
            where: 'matricule = ?',
            whereArgs: [matricule],
            limit: 1))
        .isNotEmpty;
  }

  // --- Les saisies -----------------------------------------------------

  /// Enregistre une saisie, à la place de celle que le délégué corrige.
  ///
  /// Une séance n'a qu'une saisie à envoyer par geste : la correction prend
  /// la place de ce qui n'est pas parti. Ce qui attend l'arbitrage reste, le
  /// service doit en décider.
  Future<void> enregistrerSaisie(SaisieLocale saisie) =>
      _base.transaction((tx) async {
        await tx.delete(
          'saisie',
          where: 'matricule = ? AND geste = ? AND cle = ? AND etat IN (?, ?, ?)',
          whereArgs: [
            saisie.matricule,
            saisie.geste,
            saisie.cle,
            EtatSaisie.enAttente.code,
            EtatSaisie.transmise.code,
            EtatSaisie.refusee.code,
          ],
        );
        await tx.insert('saisie', saisie.versLigne());
      });

  /// Les saisies à envoyer, dans l'ordre où les séances ont eu lieu.
  Future<List<SaisieLocale>> saisiesAEnvoyer(String matricule, {int? limite}) =>
      _saisies(
        'matricule = ? AND etat = ?',
        [matricule, EtatSaisie.enAttente.code],
        limite: limite,
      );

  Future<List<SaisieLocale>> saisiesDe(String matricule) =>
      _saisies('matricule = ?', [matricule]);

  Future<int> nombreAEnvoyer(String matricule) async {
    final lignes = await _base.rawQuery(
      'SELECT COUNT(*) AS nombre FROM saisie WHERE matricule = ? AND etat = ?',
      [matricule, EtatSaisie.enAttente.code],
    );
    return Sqflite.firstIntValue(lignes) ?? 0;
  }

  Future<List<SaisieLocale>> _saisies(String filtre, List<Object?> valeurs,
      {int? limite}) async {
    final lignes = await _base.query('saisie',
        where: filtre,
        whereArgs: valeurs,
        orderBy: 'jour, saisi_le',
        limit: limite);
    return lignes.map(SaisieLocale.depuisLigne).toList();
  }

  /// Pose le sort d'une saisie. Sans effet sur une ligne remplacée entre-temps
  /// par une correction, qui partira à son tour.
  Future<void> poserEtat(String reference, EtatSaisie etat,
          {String motif = '', String detail = ''}) =>
      _base.update(
        'saisie',
        {'etat': etat.code, 'motif': motif, 'detail': detail},
        where: 'reference = ?',
        whereArgs: [reference],
      );

  Future<void> supprimerSaisie(String reference) =>
      _base.delete('saisie', where: 'reference = ?', whereArgs: [reference]);

  /// Le paquet relu porte le constat : la ligne transmise n'a plus d'objet.
  Future<void> purgerTransmises(String matricule) => _base.delete(
        'saisie',
        where: 'matricule = ? AND etat = ?',
        whereArgs: [matricule, EtatSaisie.transmise.code],
      );

  Future<void> fermer() => _base.close();
}

class PaquetGarde {
  const PaquetGarde({
    required this.contenu,
    required this.luLe,
    required this.horlogeServeur,
    this.compteur,
  });

  final Map<String, dynamic> contenu;
  final DateTime luLe;

  /// Heure du serveur à la lecture : le repère de l'heure fiable.
  final DateTime horlogeServeur;
  final LectureCompteur? compteur;
}
