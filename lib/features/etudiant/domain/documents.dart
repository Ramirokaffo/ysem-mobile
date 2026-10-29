import '../../../core/models/json.dart';
import 'modeles.dart';
import 'pagination.dart';

/// Réponse de `documents/` : les documents officiels du dossier.
class Documents {
  const Documents({this.documents = const [], this.pagination = const Pagination()});

  final List<DocumentOfficiel> documents;
  final Pagination pagination;

  /// Les documents regroupés par année académique, dans l'ordre de la
  /// réponse (année la plus récente d'abord).
  List<(String, List<DocumentOfficiel>)> get parAnnee {
    final resultat = <(String, List<DocumentOfficiel>)>[];
    for (final document in documents) {
      if (resultat.isEmpty || resultat.last.$1 != document.annee) {
        resultat.add((document.annee, [document]));
      } else {
        resultat.last.$2.add(document);
      }
    }
    return resultat;
  }

  factory Documents.depuisJson(Json json) => Documents(
        documents: json.liste('documents', DocumentOfficiel.depuisJson),
        pagination: Pagination.depuisJson(json.objet('pagination')),
      );
}
