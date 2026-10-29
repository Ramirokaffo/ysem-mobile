import 'json.dart';

/// Pagination rendue par l'API (`student_portal/api/base.py::paginer`) :
/// portée par la réponse plutôt que par des liens.
class Pagination {
  const Pagination({
    this.page = 1,
    this.pages = 1,
    this.total = 0,
    this.pageSuivante,
  });

  final int page;
  final int pages;
  final int total;
  final int? pageSuivante;

  bool get aUneSuite => pageSuivante != null;

  factory Pagination.depuisJson(Json? json) => json == null
      ? const Pagination()
      : Pagination(
          page: json.entier('page') ?? 1,
          pages: json.entier('pages') ?? 1,
          total: json.entier('total') ?? 0,
          pageSuivante: json.entier('page_suivante'),
        );
}
