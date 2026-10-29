import 'package:intl/intl.dart';

/// Mises en forme partagées, dans la langue de l'interface.
class Formats {
  const Formats._();

  /// `125 000 FCFA` (espace insécable en français, virgule en anglais).
  static String montant(double? valeur, String langue) {
    if (valeur == null) return '—';
    final f = NumberFormat.decimalPattern(langue == 'en' ? 'en' : 'fr');
    return '${f.format(valeur.round())} FCFA';
  }

  /// Note sur 20 : `14,50` / `14.50` ; `—` quand il n'y en a pas.
  static String note(double? valeur, String langue) {
    if (valeur == null) return '—';
    return NumberFormat('0.00', langue == 'en' ? 'en' : 'fr').format(valeur);
  }

  /// Pondération d'un contrôle : `2`, `1,5` / `1.5` (sans zéros inutiles).
  static String coefficient(double valeur, String langue) =>
      NumberFormat('0.##', langue == 'en' ? 'en' : 'fr').format(valeur);

  /// `2026-11-04`, la date que l'API attend en paramètre.
  static String iso(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// `4 nov.` / `Nov 4`.
  static String jourMois(DateTime? date, String langue) {
    if (date == null) return '';
    return DateFormat.MMMd(langue).format(date);
  }

  /// `mar. 4 nov.` / `Tue, Nov 4`.
  static String jourCourt(DateTime? date, String langue) {
    if (date == null) return '';
    return DateFormat.MMMEd(langue).format(date);
  }

  /// `mercredi 4 novembre` / `Wednesday, November 4`.
  static String jourLong(DateTime? date, String langue) {
    if (date == null) return '';
    final texte = DateFormat.MMMMEEEEd(langue).format(date);
    return texte.isEmpty ? texte : texte[0].toUpperCase() + texte.substring(1);
  }

  /// `4 novembre 2026` / `November 4, 2026`.
  static String dateLongue(DateTime? date, String langue) {
    if (date == null) return '';
    return DateFormat.yMMMMd(langue).format(date.toLocal());
  }

  /// `4 nov. 2026 à 14:05` / `Nov 4, 2026 at 2:05 PM`.
  static String horodatage(DateTime? date, String langue) {
    if (date == null) return '';
    final local = date.toLocal();
    final jour = DateFormat.yMMMd(langue).format(local);
    final heure = DateFormat.Hm(langue).format(local);
    return langue == 'en' ? '$jour, $heure' : '$jour à $heure';
  }

  /// Rang ordinal : `1er`, `2e` / `1st`, `2nd`, `3rd`, `11th`.
  static String ordinal(int n, String langue) {
    if (langue != 'en') return n == 1 ? '1er' : '${n}e';
    final dizaine = n % 100;
    if (dizaine >= 11 && dizaine <= 13) return '${n}th';
    return switch (n % 10) {
      1 => '${n}st',
      2 => '${n}nd',
      3 => '${n}rd',
      _ => '${n}th',
    };
  }

  /// `08:00 – 10:00`, à partir des `HH:MM` du créneau.
  static String plage(String? debut, String? fin) {
    if (debut == null && fin == null) return '';
    if (fin == null) return debut!;
    if (debut == null) return fin;
    return '$debut – $fin';
  }
}
