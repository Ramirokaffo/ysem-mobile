import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/espace.dart';
import '../../../core/providers.dart';
import '../../commun/espace/menu.dart';
import '../domain/cours.dart';
import '../domain/modeles.dart';
import '../domain/planning.dart';

final tableauDeBordEnseignantProvider =
    FutureProvider.autoDispose<TableauDeBordEnseignant>(
  (ref) => ref.watch(enseignantRepositoryProvider).tableauDeBord(),
);

/// Le dossier (« Mon dossier »), réservé aux recrutés.
final dossierEnseignantProvider = FutureProvider.autoDispose<DossierEnseignant>(
  (ref) => ref.watch(enseignantRepositoryProvider).dossier(),
);

/// Photo du dossier, chargée avec le jeton ; gardée tant que l'espace vit.
final photoEnseignantProvider = FutureProvider<Uint8List?>(
  (ref) => ref.watch(enseignantRepositoryProvider).photo(),
);

/// Le menu de l'enseignant, venu du registre `lecturers.navigation`.
final menuEnseignantProvider = menuProvider(Espace.enseignant);

/// Mon emploi du temps, semaine par semaine (`null` : semaine courante).
final emploiDuTempsProvider =
    FutureProvider.autoDispose.family<EmploiDuTemps, String?>(
  (ref, semaine) =>
      ref.watch(enseignantRepositoryProvider).emploiDuTemps(semaine: semaine),
);

final rattrapagesProvider = FutureProvider.autoDispose<Rattrapages>(
  (ref) => ref.watch(enseignantRepositoryProvider).rattrapages(),
);

final classesProvider = FutureProvider.autoDispose<MesClasses>(
  (ref) => ref.watch(enseignantRepositoryProvider).classes(),
);

/// La liste d'une classe, par sa clé.
final detailClasseProvider =
    FutureProvider.autoDispose.family<DetailClasse, String>(
  (ref, cle) => ref.watch(enseignantRepositoryProvider).classe(cle),
);

final fichesASignerProvider = FutureProvider.autoDispose<FichesASigner>(
  (ref) => ref.watch(enseignantRepositoryProvider).fichesASigner(),
);
