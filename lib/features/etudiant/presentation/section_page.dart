import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/espace.dart';
import '../../../core/navigation/icones_sections.dart';
import '../../commun/fil/discussions_page.dart';
import '../../shell/presentation/a_implementer_page.dart';
import '../application/lectures.dart';
import 'archives/archives_page.dart';
import 'association/association_historique_page.dart';
import 'association/association_page.dart';
import 'bibliotheque/bibliotheque_page.dart';
import 'delegation/delegation_page.dart';
import 'discipline/discipline_page.dart';
import 'documents/documents_page.dart';
import 'examens/examens_page.dart';
import 'finances/finances_page.dart';
import 'messagerie/messagerie_page.dart';
import 'moratoires/moratoires_page.dart';
import 'notes/notes_page.dart';
import 'permissions/permissions_page.dart';
import 'promotion/promotion_page.dart';
import 'reinscription/reinscription_page.dart';
import 'scolarite/scolarite_page.dart';
import 'suggestions/suggestions_page.dart';
import 'supports/supports_page.dart';

/// Une section du menu, ouverte par son code de registre. Celles qui ne sont
/// pas encore livrées dans l'application affichent un écran d'attente, avec
/// le libellé et l'icône du registre du portail.
class SectionPage extends ConsumerWidget {
  const SectionPage({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(navigationProvider).valueOrNull?.section(code);
    final titre = section?.libelle;
    return switch (code) {
      'academics' => ScolaritePage(titre: titre),
      'notes' => NotesPage(titre: titre),
      'finances' => FinancesPage(titre: titre),
      'examens' => ExamensPage(titre: titre),
      'supports' => SupportsPage(titre: titre),
      'documents' => DocumentsPage(titre: titre),
      'discipline' => DisciplinePage(titre: titre),
      'moratoriums' => MoratoiresPage(titre: titre),
      'permissions' => PermissionsPage(titre: titre),
      'messages' => MessageriePage(titre: titre),
      'suggestions' => SuggestionsPage(titre: titre),
      'inscription' => ReinscriptionPage(titre: titre),
      'discussions' => DiscussionsPage(espace: Espace.etudiant, titre: titre),
      'bibliotheque' => BibliothequePage(titre: titre),
      'archives' => ArchivesPage(titre: titre),
      'promotion' => PromotionPage(titre: titre),
      'association' => AssociationPage(titre: titre),
      'delegation' => DelegationPage(titre: titre),
      'association_historique' => AssociationHistoriquePage(titre: titre),
      _ => AImplementerPage(
          titre: titre ?? code,
          icone: section == null ? null : iconeDeSection(section.icone),
        ),
    };
  }
}
