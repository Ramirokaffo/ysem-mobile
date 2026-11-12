import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/espace.dart';
import '../../../core/models/devoirs.dart';
import '../../../core/models/examens.dart';
import '../../../core/providers.dart';
import '../../commun/espace/menu.dart';
import '../domain/cours.dart';
import '../domain/documents.dart';
import '../domain/epreuves.dart';
import '../domain/feuilles.dart';
import '../domain/modeles.dart';
import '../domain/planning.dart';
import '../domain/situation.dart';

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

final devoirsEnseignantProvider = FutureProvider.autoDispose<DevoirsEnseignant>(
  (ref) => ref.watch(enseignantRepositoryProvider).devoirs(),
);

/// Les devoirs d'une seule classe (`?classe=`), pour sa fiche.
final devoirsDeClasseProvider =
    FutureProvider.autoDispose.family<DevoirsEnseignant, String>(
  (ref, cle) => ref.watch(enseignantRepositoryProvider).devoirs(classe: cle),
);

final devoirEnseignantProvider = FutureProvider.autoDispose.family<DevoirComplet, int>(
  (ref, id) => ref.watch(enseignantRepositoryProvider).devoir(id),
);

final groupementsProvider = FutureProvider.autoDispose.family<List<Groupement>, String>(
  (ref, cle) => ref.watch(enseignantRepositoryProvider).groupements(cle),
);

final groupementProvider = FutureProvider.autoDispose.family<Groupement, int>(
  (ref, id) => ref.watch(enseignantRepositoryProvider).groupement(id),
);

/// La liste d'une classe, par sa clé.
final detailClasseProvider =
    FutureProvider.autoDispose.family<DetailClasse, String>(
  (ref, cle) => ref.watch(enseignantRepositoryProvider).classe(cle),
);

final fichesASignerProvider = FutureProvider.autoDispose<FichesASigner>(
  (ref) => ref.watch(enseignantRepositoryProvider).fichesASigner(),
);

final disponibilitesProvider = FutureProvider.autoDispose<Disponibilites>(
  (ref) => ref.watch(enseignantRepositoryProvider).disponibilites(),
);

final examensEnseignantProvider = FutureProvider.autoDispose<Examens>(
  (ref) => ref.watch(enseignantRepositoryProvider).examens(),
);

final ponctualiteProvider = FutureProvider.autoDispose<Ponctualite>(
  (ref) => ref.watch(enseignantRepositoryProvider).ponctualite(),
);

final vacationsProvider = FutureProvider.autoDispose<Vacations>(
  (ref) => ref.watch(enseignantRepositoryProvider).vacations(),
);

final enseignementsProvider = FutureProvider.autoDispose<Enseignements>(
  (ref) => ref.watch(enseignantRepositoryProvider).enseignements(),
);

final feuillesDeNotesProvider = FutureProvider.autoDispose<FeuillesDeNotes>(
  (ref) => ref.watch(enseignantRepositoryProvider).feuillesDeNotes(),
);

/// Une feuille, avec son contrôle continu et ses grilles par code.
final detailFeuilleProvider =
    FutureProvider.autoDispose.family<DetailFeuille, int>(
  (ref, id) => ref.watch(enseignantRepositoryProvider).feuille(id),
);

/// Un contrôle continu et ses notes, par `(feuille, contrôle)`.
final detailControleProvider =
    FutureProvider.autoDispose.family<DetailControle, (int, int)>(
  (ref, cle) =>
      ref.watch(enseignantRepositoryProvider).controle(cle.$1, cle.$2),
);

final documentsCoursProvider = FutureProvider.autoDispose<DocumentsDeCours>(
  (ref) => ref.watch(enseignantRepositoryProvider).documentsDeCours(),
);

/// Un plan de cours, tel qu'il se lit ou se saisit en ligne.
final planCoursProvider = FutureProvider.autoDispose.family<PlanEnLigne, int>(
  (ref, id) => ref.watch(enseignantRepositoryProvider).planDeCours(id),
);

final mesEpreuvesProvider = FutureProvider.autoDispose<MesEpreuves>(
  (ref) => ref.watch(enseignantRepositoryProvider).mesEpreuves(),
);
