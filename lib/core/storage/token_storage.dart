import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/espace.dart';

/// Couple de jetons JWT d'un espace.
class Jetons {
  const Jetons({
    required this.acces,
    required this.rafraichissement,
    this.accesExpireLe,
    this.rafraichissementExpireLe,
  });

  final String acces;
  final String rafraichissement;

  /// Horodatages Unix (secondes) rendus par le serveur.
  final int? accesExpireLe;
  final int? rafraichissementExpireLe;

  bool get rafraichissementExpire {
    final fin = rafraichissementExpireLe;
    if (fin == null) return false;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= fin;
  }

  /// Lit le bloc `jetons` d'une réponse de connexion ou de rafraîchissement.
  /// Le rafraîchissement ne rend qu'un accès neuf : on garde alors l'ancien
  /// jeton de rafraîchissement (`precedent`).
  factory Jetons.depuisJson(Map<String, dynamic> json, {Jetons? precedent}) {
    return Jetons(
      acces: json['acces'] as String,
      rafraichissement:
          (json['rafraichissement'] as String?) ?? precedent!.rafraichissement,
      accesExpireLe: _entier(json['acces_expire_le']),
      rafraichissementExpireLe: _entier(json['rafraichissement_expire_le']) ??
          precedent?.rafraichissementExpireLe,
    );
  }

  static int? _entier(Object? v) => v is int ? v : int.tryParse('${v ?? ''}');
}

/// Rangement chiffré des jetons (Keystore Android, Keychain iOS).
class TokenStorage {
  TokenStorage([FlutterSecureStorage? stockage])
      : _stockage = stockage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _stockage;

  static const _cleEspaceActif = 'ysem.espace_actif';

  String _cle(Espace espace, String nom) => 'ysem.${espace.name}.$nom';

  Future<Jetons?> lire(Espace espace) async {
    final acces = await _stockage.read(key: _cle(espace, 'acces'));
    final rafraichissement =
        await _stockage.read(key: _cle(espace, 'rafraichissement'));
    if (acces == null || rafraichissement == null) return null;
    return Jetons(
      acces: acces,
      rafraichissement: rafraichissement,
      accesExpireLe:
          int.tryParse(await _stockage.read(key: _cle(espace, 'acces_exp')) ?? ''),
      rafraichissementExpireLe: int.tryParse(
          await _stockage.read(key: _cle(espace, 'rafraichissement_exp')) ?? ''),
    );
  }

  Future<void> ecrire(Espace espace, Jetons jetons) async {
    await _stockage.write(key: _cle(espace, 'acces'), value: jetons.acces);
    await _stockage.write(
        key: _cle(espace, 'rafraichissement'), value: jetons.rafraichissement);
    await _stockage.write(
        key: _cle(espace, 'acces_exp'), value: jetons.accesExpireLe?.toString());
    await _stockage.write(
        key: _cle(espace, 'rafraichissement_exp'),
        value: jetons.rafraichissementExpireLe?.toString());
  }

  Future<void> effacer(Espace espace) async {
    for (final nom in const [
      'acces',
      'rafraichissement',
      'acces_exp',
      'rafraichissement_exp',
    ]) {
      await _stockage.delete(key: _cle(espace, nom));
    }
  }

  /// Dernier espace ouvert, pour rouvrir l'application au bon endroit.
  Future<Espace?> espaceActif() async {
    final nom = await _stockage.read(key: _cleEspaceActif);
    return Espace.values.where((e) => e.name == nom).firstOrNull;
  }

  Future<void> definirEspaceActif(Espace? espace) => espace == null
      ? _stockage.delete(key: _cleEspaceActif)
      : _stockage.write(key: _cleEspaceActif, value: espace.name);
}
