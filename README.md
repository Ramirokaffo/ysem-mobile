# YSEM — application mobile

Portails étudiant et enseignant de YSEM (School of Economics and Management),
adossés à l'API REST du système (`/api/v1/portail-etudiant/`).

## Lancer

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   # runserver local vu de l'émulateur
flutter run --dart-define=API_BASE_URL=https://… --dart-define=API_LOGS=true
```

Le trafic HTTP en clair n'est autorisé qu'en debug
(`android/app/src/debug/AndroidManifest.xml`).

## Notifications push

`android/app/google-services.json` vient du projet Firebase (application
`com.ysem.education`). Sans lui l'application se construit et tourne, sans push :
le compteur reste relu toutes les 90 s. La clé d'envoi est côté serveur
(`FCM_SERVICE_ACCOUNT_B64`).

## Charte

Dérivée du logo (`main/static/main/images/ysemlogo.png` du backend) :

| Jeton | Valeur | Usage |
|---|---|---|
| bleu du logo | `#16A1D8` | bandeaux, icônes, primaire en mode sombre |
| bleu profond | `#0A6890` | couleur d'action en mode clair (contraste AA sur blanc) |
| encre | `#05374D` | fin du dégradé, titres |

Police : Nunito (comme le web), embarquée dans `assets/fonts/` (OFL).
Tout est dans `lib/app/charte/` (couleurs, composants) et `lib/app/theme.dart`.

## Régénérer

```bash
flutter gen-l10n                          # après toute retouche de lib/l10n/*.arb (fr = source)
dart run flutter_launcher_icons           # icône (assets/icone/)
dart run flutter_native_splash:create     # écran natif de démarrage
flutter analyze && flutter test
```

Le logo source ne fait que 703 px : un logo vectoriel ou HD est à fournir
avant la publication sur les stores.
