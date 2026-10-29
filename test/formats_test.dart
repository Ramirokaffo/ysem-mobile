import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ysem/app/charte/widgets/pastille.dart';
import 'package:ysem/core/format/formats.dart';
import 'package:ysem/core/navigation/icones_sections.dart';

void main() {
  setUpAll(initializeDateFormatting);

  test('montant en FCFA, arrondi, selon la langue', () {
    expect(Formats.montant(125000.4, 'en'), '125,000 FCFA');
    expect(Formats.montant(125000, 'fr').replaceAll(RegExp(r'\s'), ' '),
        '125 000 FCFA');
    expect(Formats.montant(null, 'fr'), '—');
  });

  test("plage horaire d'un créneau", () {
    expect(Formats.plage('08:00', '10:00'), '08:00 – 10:00');
    expect(Formats.plage('08:00', null), '08:00');
    expect(Formats.plage(null, null), '');
  });

  test('une icône inconnue du registre a un repli', () {
    expect(iconeDeSection('fa-bell'), Icons.notifications_rounded);
    expect(iconeDeSection('fa-nouvelle-section'), Icons.apps_rounded);
  });

  test('ton des statuts financiers du service', () {
    expect(Pastille.tonDuStatut('up_to_date'), TonPastille.succes);
    expect(Pastille.tonDuStatut('overdue'), TonPastille.danger);
    expect(Pastille.tonDuStatut('moratorium'), TonPastille.info);
  });
}
