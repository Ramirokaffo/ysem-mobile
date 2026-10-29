/// Lecture tolérante du JSON de l'API : un champ absent ou d'un autre type
/// rend la valeur par défaut au lieu de faire tomber l'écran.
typedef Json = Map<String, dynamic>;

extension LectureJson on Json {
  String texte(String cle) => this[cle]?.toString() ?? '';

  String? texteOuNul(String cle) {
    final v = this[cle];
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  bool booleen(String cle) => this[cle] == true;

  int? entier(String cle) {
    final v = this[cle];
    return v is int ? v : int.tryParse('${v ?? ''}');
  }

  double? nombre(String cle) {
    final v = this[cle];
    return v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
  }

  /// Date (`2026-10-29`) ou horodatage ISO.
  DateTime? date(String cle) => DateTime.tryParse('${this[cle] ?? ''}');

  Json? objet(String cle) {
    final v = this[cle];
    return v is Map ? Map<String, dynamic>.from(v) : null;
  }

  List<T> liste<T>(String cle, T Function(Json) lire) {
    final v = this[cle];
    if (v is! List) return const [];
    return [
      for (final e in v)
        if (e is Map) lire(Map<String, dynamic>.from(e)),
    ];
  }
}
