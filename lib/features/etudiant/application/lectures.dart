import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/espace.dart';
import '../../../core/providers.dart';
import '../../commun/espace/menu.dart';
import '../domain/modeles.dart';

final tableauDeBordProvider = FutureProvider.autoDispose<TableauDeBord>(
  (ref) => ref.watch(etudiantRepositoryProvider).tableauDeBord(),
);

final profilProvider = FutureProvider.autoDispose<Profil>(
  (ref) => ref.watch(etudiantRepositoryProvider).profil(),
);

/// Le menu de l'étudiant, venu du registre du portail (contrôleur commun aux
/// deux espaces).
final navigationProvider = menuProvider(Espace.etudiant);
