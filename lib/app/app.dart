import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../features/auth/application/session_controller.dart';
import '../features/commun/push/push.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class YsemApp extends ConsumerWidget {
  const YsemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Le contrôleur vit avec l'application : il suit la session et reçoit les
    // push, quelle que soit la page ouverte.
    ref.watch(pushProvider);
    // Choix fait sur l'appareil, sinon langue du dossier une fois connecté,
    // sinon celle du téléphone.
    final forcee = ref.watch(langueForceeProvider);
    final session = ref.watch(sessionProvider).valueOrNull;
    final duDossier = session?.langueDuDossier;
    final langue = forcee ?? duDossier;
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.clair,
      darkTheme: AppTheme.sombre,
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
      locale: langue == null ? null : Locale(langue),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
