import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/discipline.dart';
import '../domain/documents.dart';
import '../domain/examens.dart';
import '../domain/finances.dart';
import '../domain/mobile_money.dart';
import '../domain/moratoires.dart';
import '../domain/notes.dart';
import '../domain/permissions.dart';
import '../domain/reinscription.dart';
import '../domain/scolarite.dart';
import '../domain/suggestions.dart';
import '../domain/supports.dart';

/// Ma scolarité, semaine par semaine (`null` : semaine courante).
final scolariteProvider =
    FutureProvider.autoDispose.family<Scolarite, String?>(
  (ref, semaine) =>
      ref.watch(etudiantRepositoryProvider).scolarite(semaine: semaine),
);

final notesProvider = FutureProvider.autoDispose<Notes>(
  (ref) => ref.watch(etudiantRepositoryProvider).notes(),
);

/// Ma situation financière, année par année (`null` : année active).
final financesProvider = FutureProvider.autoDispose.family<Finances, int?>(
  (ref, annee) => ref.watch(etudiantRepositoryProvider).finances(annee: annee),
);

final examensProvider = FutureProvider.autoDispose<Examens>(
  (ref) => ref.watch(etudiantRepositoryProvider).examens(),
);

final supportsProvider = FutureProvider.autoDispose<Supports>(
  (ref) => ref.watch(etudiantRepositoryProvider).supports(),
);

final documentsProvider = FutureProvider.autoDispose<Documents>(
  (ref) => ref.watch(etudiantRepositoryProvider).documents(),
);

final disciplineProvider = FutureProvider.autoDispose<DossierDiscipline>(
  (ref) => ref.watch(etudiantRepositoryProvider).discipline(),
);

final moratoiresProvider = FutureProvider.autoDispose<Moratoires>(
  (ref) => ref.watch(etudiantRepositoryProvider).moratoires(),
);

/// Mes permissions, semaine par semaine (`null` : semaine courante).
final permissionsProvider =
    FutureProvider.autoDispose.family<Permissions, String?>(
  (ref, semaine) =>
      ref.watch(etudiantRepositoryProvider).permissions(semaine: semaine),
);

final suggestionsProvider = FutureProvider.autoDispose<Suggestions>(
  (ref) => ref.watch(etudiantRepositoryProvider).suggestions(),
);

final reinscriptionProvider = FutureProvider.autoDispose<Reinscription>(
  (ref) => ref.watch(etudiantRepositoryProvider).reinscription(),
);

final versementsProvider = FutureProvider.autoDispose<Versements>(
  (ref) => ref.watch(etudiantRepositoryProvider).versements(),
);

/// Paiement Mobile Money : ouverture, plafond et transactions de l'année.
final mobileMoneyProvider = FutureProvider.autoDispose<MobileMoney>(
  (ref) => ref.watch(etudiantRepositoryProvider).mobileMoney(),
);
