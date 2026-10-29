import 'package:flutter/material.dart';

import 'charte/couleurs.dart';

/// Jetons de la charte que Material ne porte pas : tons d'état, dégradé de
/// marque, rayons. Lus par `YsemTokens.of(context)`.
@immutable
class YsemTokens extends ThemeExtension<YsemTokens> {
  const YsemTokens({
    required this.succes,
    required this.alerte,
    required this.danger,
    required this.info,
    required this.neutre,
    required this.degrade,
  });

  final Color succes;
  final Color alerte;
  final Color danger;
  final Color info;
  final Color neutre;
  final Gradient degrade;

  static const rayon = 16.0;
  static const rayonPetit = 10.0;

  static YsemTokens of(BuildContext context) =>
      Theme.of(context).extension<YsemTokens>()!;

  @override
  YsemTokens copyWith({
    Color? succes,
    Color? alerte,
    Color? danger,
    Color? info,
    Color? neutre,
    Gradient? degrade,
  }) =>
      YsemTokens(
        succes: succes ?? this.succes,
        alerte: alerte ?? this.alerte,
        danger: danger ?? this.danger,
        info: info ?? this.info,
        neutre: neutre ?? this.neutre,
        degrade: degrade ?? this.degrade,
      );

  @override
  YsemTokens lerp(ThemeExtension<YsemTokens>? other, double t) {
    if (other is! YsemTokens) return this;
    return YsemTokens(
      succes: Color.lerp(succes, other.succes, t)!,
      alerte: Color.lerp(alerte, other.alerte, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      neutre: Color.lerp(neutre, other.neutre, t)!,
      degrade: t < 0.5 ? degrade : other.degrade,
    );
  }
}

/// Thème de l'application, aux couleurs du logo YSEM.
///
/// En clair, l'action est en bleu profond (le bleu du logo manque de
/// contraste pour du texte sur blanc) ; en sombre, c'est le bleu du logo
/// lui-même.
class AppTheme {
  const AppTheme._();

  static const police = 'Nunito';

  static final ThemeData clair = _construire(
    const ColorScheme(
      brightness: Brightness.light,
      primary: YsemCouleurs.bleuProfond,
      onPrimary: YsemCouleurs.blanc,
      primaryContainer: Color(0xFFD5EEF9),
      onPrimaryContainer: YsemCouleurs.encre,
      secondary: YsemCouleurs.bleu,
      onSecondary: YsemCouleurs.blanc,
      secondaryContainer: Color(0xFFE3F4FB),
      onSecondaryContainer: YsemCouleurs.encre,
      tertiary: YsemCouleurs.encre,
      onTertiary: YsemCouleurs.blanc,
      error: YsemCouleurs.danger,
      onError: YsemCouleurs.blanc,
      errorContainer: Color(0xFFFDE4E4),
      onErrorContainer: Color(0xFF7F1D1D),
      surface: YsemCouleurs.blanc,
      onSurface: YsemCouleurs.texte,
      onSurfaceVariant: YsemCouleurs.texteDiscret,
      surfaceContainerLowest: YsemCouleurs.blanc,
      surfaceContainerLow: Color(0xFFF7F9FB),
      surfaceContainer: YsemCouleurs.fondClair,
      surfaceContainerHigh: Color(0xFFEAEFF4),
      surfaceContainerHighest: Color(0xFFE2E8EE),
      outline: Color(0xFFB4C0CC),
      outlineVariant: YsemCouleurs.ligne,
      inverseSurface: YsemCouleurs.encre,
      onInverseSurface: YsemCouleurs.blanc,
      inversePrimary: YsemCouleurs.bleu,
      shadow: Color(0x1A05374D),
    ),
    fond: YsemCouleurs.fondClair,
  );

  static final ThemeData sombre = _construire(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: YsemCouleurs.bleu,
      onPrimary: YsemCouleurs.encre,
      primaryContainer: YsemCouleurs.bleuProfond,
      onPrimaryContainer: YsemCouleurs.blanc,
      secondary: Color(0xFF7FCBEA),
      onSecondary: YsemCouleurs.encre,
      secondaryContainer: Color(0xFF0E3A4F),
      onSecondaryContainer: Color(0xFFD5EEF9),
      tertiary: Color(0xFF9FD8F0),
      onTertiary: YsemCouleurs.encre,
      error: Color(0xFFF87171),
      onError: Color(0xFF450A0A),
      errorContainer: Color(0xFF5B1515),
      onErrorContainer: Color(0xFFFDE4E4),
      surface: YsemCouleurs.surfaceSombre,
      onSurface: Color(0xFFE6EDF2),
      onSurfaceVariant: Color(0xFFA3B3C1),
      surfaceContainerLowest: YsemCouleurs.fondSombre,
      surfaceContainerLow: Color(0xFF0E1F28),
      surfaceContainer: YsemCouleurs.surfaceSombreHaute,
      surfaceContainerHigh: Color(0xFF1A2F3B),
      surfaceContainerHighest: Color(0xFF223845),
      outline: Color(0xFF4B6170),
      outlineVariant: Color(0xFF243844),
      inverseSurface: Color(0xFFE6EDF2),
      onInverseSurface: YsemCouleurs.encre,
      inversePrimary: YsemCouleurs.bleuProfond,
      shadow: Color(0xFF000000),
    ),
    fond: YsemCouleurs.fondSombre,
  );

  static ThemeData _construire(ColorScheme schema, {required Color fond}) {
    final sombre = schema.brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: schema,
      fontFamily: police,
      scaffoldBackgroundColor: fond,
    );
    final texte = base.textTheme.apply(
      fontFamily: police,
      bodyColor: schema.onSurface,
      displayColor: sombre ? schema.onSurface : YsemCouleurs.encre,
    );
    final rond = BorderRadius.circular(YsemTokens.rayonPetit);
    const boutonForme = StadiumBorder();
    const boutonTaille = Size(64, 52);
    final boutonTexte = texte.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 15,
    );

    return base.copyWith(
      textTheme: texte.copyWith(
        headlineSmall: texte.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        titleLarge: texte.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: texte.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: texte.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: texte.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      extensions: [
        YsemTokens(
          succes: sombre ? const Color(0xFF4ADE80) : YsemCouleurs.succes,
          alerte: sombre ? const Color(0xFFFBBF24) : YsemCouleurs.alerte,
          danger: schema.error,
          info: sombre ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
          neutre: schema.onSurfaceVariant,
          degrade: YsemCouleurs.degradeMarque,
        ),
      ],
      appBarTheme: AppBarThemeData(
        backgroundColor: fond,
        foregroundColor: sombre ? schema.onSurface : YsemCouleurs.encre,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: texte.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: sombre ? schema.onSurface : YsemCouleurs.encre,
        ),
      ),
      cardTheme: CardThemeData(
        color: schema.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(YsemTokens.rayon),
          side: BorderSide(color: schema.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: boutonTaille,
          shape: boutonForme,
          textStyle: boutonTexte,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: boutonTaille,
          shape: boutonForme,
          textStyle: boutonTexte,
          side: BorderSide(color: schema.primary, width: 1.4),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: boutonTexte),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: sombre ? schema.surfaceContainer : YsemCouleurs.blanc,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: rond,
          borderSide: BorderSide(color: schema.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: rond,
          borderSide: BorderSide(color: schema.outlineVariant, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: rond,
          borderSide: BorderSide(color: schema.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: rond,
          borderSide: BorderSide(color: schema.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: rond,
          borderSide: BorderSide(color: schema.error, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: schema.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: schema.primaryContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (etats) => texte.labelMedium?.copyWith(
            fontWeight: etats.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (etats) => IconThemeData(
            color: etats.contains(WidgetState.selected)
                ? (sombre ? schema.onPrimaryContainer : YsemCouleurs.encre)
                : schema.onSurfaceVariant,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: schema.primary,
        shape: RoundedRectangleBorder(borderRadius: rond),
      ),
      dividerTheme: DividerThemeData(color: schema.outlineVariant, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: rond),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: schema.primary,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: BorderSide(color: schema.outlineVariant),
      ),
    );
  }
}
