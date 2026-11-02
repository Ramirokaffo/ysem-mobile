# Publication Google Play — YSEM

Fichiers de ce dossier :
- `icone_512.png` — icône de l'application (512 × 512)
- `banniere_1024x500.png` — image de présentation (feature graphic)
- Le paquet à envoyer : `build/app/outputs/bundle/release/app-release.aab`

Identifiant de l'application : **com.ysem.education** (définitif).

---

## 1. Fiche du Play Store (Croissance › Présence sur le Store › Fiche principale)

**Nom de l'application** (30 car. max)
> YSEM

**Description courte** (80 car. max)
> Notes, emploi du temps, paiements et messages de YSEM, sur votre téléphone.

**Description complète** (4 000 car. max)
> L'application officielle de YSEM – School of Economics and Management.
>
> Étudiants et enseignants retrouvent leur espace YSEM directement sur leur téléphone, avec les mêmes informations que sur le portail web.
>
> ESPACE ÉTUDIANT
> • Emploi du temps de la semaine et calendrier académique
> • Notes et résultats publiés par le jury
> • Situation financière, échéancier, reçus et relevés de compte
> • Réinscription et déclaration de versements bancaires
> • Documents officiels, planning des examens, supports de cours
> • Assiduité, permissions d'absence, moratoires
> • Messagerie avec la scolarité et discussions de classe
> • Bibliothèque universitaire, boîte à suggestions, élection de l'association
> • Espace délégué : appel et cahier de texte
>
> ESPACE ENSEIGNANT
> • Emploi du temps, classes et listes d'étudiants
> • Fiches à signer, rattrapages
> • Notifications du service
>
> Connexion sécurisée par matricule (ou e-mail pour les enseignants), mot de passe et code de vérification.
>
> L'accès est réservé aux étudiants et enseignants de YSEM : les identifiants sont fournis par l'établissement.

**Catégorie** : Enseignement
**Coordonnées** : e-mail de contact obligatoire (ex. scolarite@ysem.education), site web https://www.ysem.education

**Captures d'écran téléphone** : 2 minimum (8 max), format 9:16, entre 320 et 3 840 px.
→ À faire depuis un téléphone une fois l'app installée via le test interne (étape 4 du guide).

---

## 2. Contenu de l'application (Règles › Contenu de l'application)

### Accès à l'application
« Tout ou partie de l'application est soumise à des restrictions » → fournir **un compte de test** aux examinateurs Google :
- Matricule + mot de passe d'un étudiant de test **sans adresse e-mail au dossier**
  (sans e-mail, la double authentification ne s'applique pas — sinon l'examinateur
  reste bloqué au code et l'app est refusée), ou un compte dont la 2FA est désactivée.
- Instructions : « Choisir Espace étudiant, saisir le matricule et le mot de passe. »

### Annonces
Non, l'application ne contient pas d'annonces.

### Classification du contenu
Questionnaire IARC, catégorie « Référence, actualités ou éducation ». Répondre Non à
tout (violence, sexualité, langage, drogues, jeux d'argent). Oui à « les utilisateurs
peuvent interagir / échanger des messages » (messagerie et discussions de classe).

### Public cible
**18 ans et plus** (étudiants du supérieur). Évite les règles « Familles ».

### Application d'actualités : Non. Application gouvernementale : Non.
### Applications financières : Non (la déclaration de versement n'est pas un service financier).
### Santé : Non.

### Sécurité des données
- Collecte ou partage de données : **Oui, collecte**. Aucun partage avec des tiers.
- Chiffrement en transit : **Oui** (HTTPS).
- Les utilisateurs peuvent-ils demander la suppression ? **Oui**, auprès de la scolarité.
- Les comptes sont-ils créés dans l'app ? **Non** (fournis par l'établissement) →
  pas d'URL de suppression de compte exigée.

| Type de données | Collectée | Obligatoire | Finalité |
|---|---|---|---|
| Nom | Oui | Oui | Fonctionnalités de l'app, gestion du compte |
| Adresse e-mail | Oui | Non | Gestion du compte (code de vérification) |
| Numéro de téléphone | Oui | Non | Fonctionnalités de l'app |
| Identifiants utilisateur (matricule) | Oui | Oui | Gestion du compte |
| Position précise | Oui | Non (délégués seulement) | Fonctionnalités de l'app (vérifier la présence en salle à l'appel) |
| Autres infos financières (versements, échéances) | Oui | Non | Fonctionnalités de l'app |
| Photos | Oui | Non | Fonctionnalités de l'app (pièces jointes, photo de profil) |
| Fichiers et documents | Oui | Non | Fonctionnalités de l'app (justificatifs) |
| Messages dans l'application | Oui | Non | Fonctionnalités de l'app |

Aucune donnée n'est traitée de façon « éphémère » ; aucune n'est utilisée pour la
publicité ou l'analyse.

### Politique de confidentialité
**https://si.ysem.education/confidentialite/** — page publique du système (fr/en),
coordonnées lues dans les réglages de l'établissement. Gabarit :
`ysem-system/main/templates/main/confidentialite.html` (date de mise à jour :
`ConfidentialiteView.MISE_A_JOUR`, à avancer à chaque modification du texte).
En ligne après le prochain déploiement.
