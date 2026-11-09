import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/providers.dart';
import 'features/commun/push/canal_push.dart';
import 'features/commun/push/push.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  await initializeDateFormatting();
  final canalPush = await ouvrirCanalPush();
  runApp(ProviderScope(
    overrides: [
      preferencesProvider.overrideWithValue(preferences),
      canalPushProvider.overrideWithValue(canalPush),
    ],
    child: const YsemApp(),
  ));
}
