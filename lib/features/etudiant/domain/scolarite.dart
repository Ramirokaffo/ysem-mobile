import '../../../core/models/json.dart';
import 'modeles.dart';

/// Réponse de `scolarite/?semaine=` : emploi du temps, calendrier, parcours.
class Scolarite {
  const Scolarite({
    this.annee,
    this.inscription,
    this.semaine = const SemaineScolarite(),
    this.nombreDeSeances = 0,
    this.journees = const [],
    this.calendrier = const [],
    this.calendrierPasse = const [],
    this.parcours = const [],
  });

  final AnneeAcademique? annee;
  final Inscription? inscription;
  final SemaineScolarite semaine;

  /// Séances tenues de la semaine (ni annulées, ni chômées) — le compte du
  /// serveur, pas un second décompte.
  final int nombreDeSeances;
  final List<Journee> journees;
  final List<EvenementCalendrier> calendrier;
  final List<EvenementCalendrier> calendrierPasse;
  final List<Inscription> parcours;

  factory Scolarite.depuisJson(Json json) => Scolarite(
        annee: AnneeAcademique.depuisJson(json.objet('annee')),
        inscription: Inscription.depuisJson(json.objet('inscription')),
        semaine: SemaineScolarite.depuisJson(json.objet('semaine')),
        nombreDeSeances: json.entier('nombre_de_seances') ?? 0,
        journees: json.liste('journees', Journee.depuisJson),
        calendrier: json.liste('calendrier', EvenementCalendrier.depuisJson),
        calendrierPasse:
            json.liste('calendrier_passe', EvenementCalendrier.depuisJson),
        parcours: json.liste('parcours', (j) => Inscription.depuisJson(j)!),
      );
}
