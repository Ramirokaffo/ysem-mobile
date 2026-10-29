import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/app/router.dart';
import 'package:ysem/core/auth/espace.dart';
import 'package:ysem/features/auth/application/session_controller.dart';

void main() {
  const etudiant = Session(espace: Espace.etudiant, acteur: {'matricule': 'X'});
  const aChanger = Session(
    espace: Espace.etudiant,
    acteur: {'matricule': 'X'},
    doitChangerMotDePasse: true,
  );

  test('restauration en cours : écran de démarrage', () {
    expect(redirection(const AsyncLoading(), Routes.accueilEtudiant),
        Routes.demarrage);
  });

  test('personne de connecté : seules les pages publiques', () {
    const personne = AsyncData<Session?>(null);
    expect(redirection(personne, Routes.connexionEtudiant), isNull);
    expect(redirection(personne, Routes.choixEspace), isNull);
    expect(redirection(personne, Routes.profilEtudiant), Routes.choixEspace);
    expect(redirection(personne, Routes.demarrage), Routes.choixEspace);
  });

  test("connecté : les pages publiques mènent à l'accueil", () {
    expect(redirection(const AsyncData(etudiant), Routes.connexionEtudiant),
        Routes.accueilEtudiant);
    expect(redirection(const AsyncData(etudiant), Routes.profilEtudiant), isNull);
  });

  test('mot de passe à changer : tout ramène au changement', () {
    expect(redirection(const AsyncData(aChanger), Routes.accueilEtudiant),
        Routes.motDePasseEtudiant);
    expect(redirection(const AsyncData(aChanger), Routes.sectionEtudiant('notes')),
        Routes.motDePasseEtudiant);
    expect(redirection(const AsyncData(aChanger), Routes.motDePasseEtudiant),
        isNull);
  });
}
