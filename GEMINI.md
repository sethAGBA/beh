# Gemini Configuration

This file is used to configure Gemini's behavior for this project.

## About the Project

*   **Project Name:** application_beh
*   **Description:** Une application de réservation de mariage.
*   **Framework:** Flutter
*   **Language:** Dart

## Instructions for Gemini

*   When adding new features, please follow the existing coding style.
*   Ensure that all new code is well-documented.
*   When adding new dependencies, please update the `pubspec.yaml` file.
*   Please run `flutter analyze` to check for any analysis issues after making changes.
*   Please run `flutter test` to run the tests after making changes.


  1. Architecture et Structure du Code
  Actuellement, tous les fichiers sont dans le répertoire lib. Pour une meilleure organisation et maintenance, nous pouvons structurer votre projet par
  fonctionnalités.


   * Organisation par fonctionnalités : Créer des dossiers pour chaque fonctionnalité principale (par exemple, authentication, home, profile, event_management).
   * Séparation de la logique : Séparer l'interface utilisateur (les widgets) de la logique métier (par exemple, la communication avec une base de données).


  2. Gestion de l'État (State Management)
  Pour le moment, la gestion de l'état est minimale. Pour une application comme la vôtre, où les données de l'utilisateur et les informations sur les événements
  doivent être accessibles à plusieurs endroits, une solution de gestion de l'état est essentielle.


   * Recommandation : Je vous suggère d'intégrer le package provider. C'est une solution simple et puissante, parfaite pour commencer. Elle nous permettra de
     gérer l'état de l'utilisateur (connecté ou non), les informations de son profil, et les détails des événements de mariage.


  3. Backend et Authentification
  Vos écrans de connexion et d'inscription sont actuellement des maquettes. Pour les rendre fonctionnels, nous devons les connecter à un service de backend.


   * Recommandation : Firebase est un excellent choix pour votre application. Il offre :
       * Firebase Authentication : Pour une gestion sécurisée des utilisateurs (connexion par e-mail/mot de passe, réseaux sociaux, etc.).
       * Cloud Firestore : Une base de données NoSQL pour stocker les informations des utilisateurs, les détails des mariages, les listes d'invités, les
         prestataires, etc.
       * Firebase Storage : Pour stocker des fichiers, comme les photos de profil ou les images des lieux de réception.


  4. Interface Utilisateur et Expérience Utilisateur (UI/UX)
  Nous pouvons améliorer l'expérience globale de l'utilisateur.


   * Thème de l'application : Définir un thème cohérent (couleurs, polices) pour donner à votre application une identité visuelle unique.
   * Validation des formulaires : Ajouter une validation en temps réel sur les champs de vos formulaires de connexion et d'inscription pour guider l'utilisateur.
   * Retours visuels : Informer l'utilisateur de ce qui se passe, par exemple en affichant un indicateur de chargement lors de la connexion ou de l'inscription.

  Par où commencer ?

  Je vous propose de commencer par mettre en place l'authentification avec Firebase et d'intégrer le gestionnaire d'état provider. C'est la base la plus
  importante pour la suite du développement de votre application.


  Qu'en pensez-vous ? Souhaitez-vous que nous commencions par l'intégration de Firebase ?



   1. Vérifier la présence de `google-services.json` :
       * Naviguez vers le répertoire android/app/ de votre projet.
       * Confirmez si un fichier nommé google-services.json y existe.


   2. Vérifier le nom du package Android :
       * Ouvrez android/app/src/main/AndroidManifest.xml et trouvez l'attribut package dans la balise <manifest>.
       * Ouvrez android/app/build.gradle.kts et trouvez l'applicationId dans le bloc defaultConfig.
       * Allez sur votre console Firebase, sélectionnez votre projet, puis allez dans "Paramètres du projet" (l'icône en forme d'engrenage). Sous "Vos
         applications", sélectionnez votre application Android. Vérifiez le "Nom du package" qui y est listé.
       * Confirmez si les trois noms de package (de `AndroidManifest.xml`, `build.gradle.kts` et de la console Firebase) sont identiques.


   3. Vérifier l'empreinte SHA-1 :
       * Dans votre console Firebase, sous "Paramètres du projet" -> "Vos applications" -> votre application Android, vérifiez s'il y a des empreintes de
         certificat SHA listées.
       * Si ce n'est pas le cas, vous devrez générer l'empreinte SHA-1 de votre application et l'ajouter à Firebase. Vous pouvez généralement la générer en
         exécutant keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android dans votre terminal (pour les
         versions de débogage).


  Veuillez me fournir les résultats de ces vérifications.




 # config

Ajouter Firebase à votre application Android
Completed
Enregistrer l'application
Nom du package Android : com.example.beh, pseudo de l'application : BEH
Editable
Télécharger, puis ajouter un fichier de configuration
3
Ajouter le SDK Firebase
Instructions pour Gradle
|
UnityC++
tip:
Vous utilisez toujours la syntaxe buildscript pour gérer les plug-ins ? Découvrez comment ajouter des plug-ins Firebase à l'aide de cette syntaxe.
Pour rendre les valeurs de configuration google-services.json accessibles aux SDK Firebase, vous devez disposer du plug-in Gradle des services Google.



# Groovy (build.gradle)
Ajoutez le plug-in en tant que dépendance du fichier build.gradle au niveau du projet :

Fichier Gradle au niveau racine (au niveau du projet) (<project>/build.gradle) :
plugins {
  // ...

  // Add the dependency for the Google services Gradle plugin
  id 'com.google.gms.google-services' version '4.4.3' apply false
}
Ensuite, dans le fichier build.gradle de votre module (au niveau de l'application), ajoutez le plug-in google-services et tous les SDK Firebase que vous souhaitez utiliser dans votre application :

Fichier Gradle du module (au niveau de l'application) (<project>/<app-module>/build.gradle) :
plugins {
  id 'com.android.application'
  // Add the Google services Gradle plugin
  id 'com.google.gms.google-services'
  ...
}

dependencies {
  // Import the Firebase BoM
  implementation platform('com.google.firebase:firebase-bom:34.1.0')

  // TODO: Add the dependencies for Firebase products you want to use
  // When using the BoM, don't specify versions in Firebase dependencies
  implementation 'com.google.firebase:firebase-analytics'

  // Add the dependencies for any other desired Firebase products
  // https://firebase.google.com/docs/android/setup#available-libraries
}
Si vous suivez la nomenclature BoM Android Firebase, votre application utilisera toujours des versions compatibles de la bibliothèque Firebase. En savoir plus
Après avoir ajouté le plug-in et les SDK souhaités, synchronisez votre projet Android avec les fichiers Gradle.




# config 2


Ajouter Firebase à votre application Android
Completed
Enregistrer l'application
Nom du package Android : com.example.beh, pseudo de l'application : BEH
Editable
Télécharger, puis ajouter un fichier de configuration
3
Ajouter le SDK Firebase
Instructions pour Gradle
|
UnityC++
tip:
Vous utilisez toujours la syntaxe buildscript pour gérer les plug-ins ? Découvrez comment ajouter des plug-ins Firebase à l'aide de cette syntaxe.
Pour rendre les valeurs de configuration google-services.json accessibles aux SDK Firebase, vous devez disposer du plug-in Gradle des services Google.


# DSL Kotlin (build.gradle.kts)

Groovy (build.gradle)
Ajoutez le plug-in en tant que dépendance du fichier build.gradle.kts au niveau du projet :

Fichier Gradle au niveau racine (au niveau du projet) (<project>/build.gradle.kts) :
plugins {
  // ...

  // Add the dependency for the Google services Gradle plugin
  id("com.google.gms.google-services") version "4.4.3" apply false
}
Ensuite, dans le fichier build.gradle.kts de votre module (au niveau de l'application), ajoutez le plug-in google-services et tous les SDK Firebase que vous souhaitez utiliser dans votre application :

Fichier Gradle du module (au niveau de l'application) (<project>/<app-module>/build.gradle.kts) :
plugins {
  id("com.android.application")
  // Add the Google services Gradle plugin
  id("com.google.gms.google-services")
  ...
}

dependencies {
  // Import the Firebase BoM
  implementation(platform("com.google.firebase:firebase-bom:34.1.0"))

  // TODO: Add the dependencies for Firebase products you want to use
  // When using the BoM, don't specify versions in Firebase dependencies
  implementation("com.google.firebase:firebase-analytics")

  // Add the dependencies for any other desired Firebase products
  // https://firebase.google.com/docs/android/setup#available-libraries
}
Si vous suivez la nomenclature BoM Android Firebase, votre application utilisera toujours des versions compatibles de la bibliothèque Firebase. En savoir plus
Après avoir ajouté le plug-in et les SDK souhaités, synchronisez votre projet Android avec les fichiers Gradle.




Application de Gestion d'Événements
Flutter Mobile + Base de données online 

🏗️ Architecture Technique
Base de données firebase
-- Tables principales

- Utilisateurs (gestion authentification et profils)
- Types d’évènements (mariage, anniversaire, conférence, funérailles)
- Réservation
- Prestations décoration (simple, moderne, luxueuse)
- Prestations nourriture (africaine, européenne)
- commandes
- paiements
- Paramètres utilisateur

Structure de navigation

	Bottom Navigation Bar : Navigation principale entre modules
	AppBar : Barre d'outils contextuelle avec titre et actions 
	Body : Zone de contenu principal avec scrolling 
	FAB : Boutons d'actions rapides contextuels

📱 Modules & Écrans Détaillés
🔐 1. AUTHENTIFICATION
Écran Inscription
	Formulaire : Nom, Prénom, Email, Téléphone, Mot de passe, Confirmation 
	 Validation : Contrôle format email, force mot de passe, unicité 
	Actions : Bouton "S'inscrire", Lien vers connexion 
	Design : Logo application, champs Material Design
Écran Connexion
	Formulaire : Email/Téléphone, Mot de passe 
	Options : "Se souvenir de moi", "Mot de passe oublié" 
	Actions : Bouton "Se connecter", Lien vers inscription 
	 Sécurité : Chiffrement local des données

🏠 2. ÉCRAN D'ACCUEIL
Écran Bienvenue
Widgets d’accueil :
├── 👋 Message personnalisé "Bonjour [Nom utilisateur]"
├── 🎉 Bannière avec image d'événements
├── 📊 Statistiques rapides (réservations en cours)
├── 🔗 Raccourcis vers services populaires
└── 📢 Notifications et alertes importantes

Navigation rapide : 
o	Bouton "Nouvelle réservation" 
o	Historique des événements 
o	Accès paramètres profil

🛎️ 3. ÉCRAN SERVICES
Catalogue des services
  Cards visuelles : Image, titre, description courte, tarif de base 
  Services disponibles :
•	💒 Organisation de mariages
•	🎂 Fêtes d'anniversaire
•	📋 Conférences professionnelles
•	⚱️ Cérémonies funéraires 
  Actions : "Réserver maintenant", "En savoir plus" 
   Filtres : Par budget, type, popularité

📝 4. GESTION DES RÉSERVATIONS
Écran Réservation - Sélection Type
	Grid d'événements : Cards avec icônes et descriptions 
	Types disponibles :
o	Mariage, Anniversaire, Conférence, Funérailles 
	Navigation : Tap pour accéder au formulaire spécifique
Formulaire Réservation Mariage
Champs obligatoires 
├── 👰 Nom de la mariée
├── 🤵 Nom du marié  
├── 👥 Nombre de personnes invitées
├── 📅 Date de l'événement
├── ⏰ Heure de début
├── 💰 Budget prévu
├── 📝 Notes spéciales (optionnel)
└── 📍 Lieu souhaité (optionnel)
Validation temps réel : • Vérification disponibilité date • Calcul automatique coût base • Suggestions selon budget
Actions : "Enregistrer réservation", "Annuler"

📊 5. ÉCRAN PLANIFICATION
Tableau de bord événement
Widgets planification 
├── ⏳ Compte à rebours (jours restants)
├── 📈 Progression préparatifs (pourcentage)
├── ✅ Checklist tâches importantes  
├── 💰 Budget utilisé vs restant
└── 📞 Contacts prestataires
Boutons d'actions 
	Modifier prestations
	Voir récapitulatif
	Contacter organisateur

🎨 6. ÉCRAN PRESTATIONS
Section Décoration
Types disponibles :
Décoration options 
├── 🌸 Simple (économique)
│   ├── Description, prix, images
│   └── Compteur +/- pour quantité
├── 🎭 Moderne (intermédiaire)  
│   ├── Description, prix, images
│   └── Compteur +/- pour quantité
└── 💎 Luxueuse (premium)
    ├── Description, prix, images
    └── Compteur +/- pour quantité
Interface :
o	Cards avec photos haute qualité 
o	Prix affichés clairement
o	 Boutons +/- pour ajuster quantités • Calcul total temps réel
Section Nourriture
Cuisine Africaine 
Menu africain 
├── 🥗 Entrées
│   ├── Salade d'avocat, Beignets, etc.
│   └── Sélection multiple possible
├── 🍛 Plats de résistance
│   ├── Riz au gras, Attiéké poisson, etc.
│   └── Compteur portions
└── 🍰 Desserts
    ├── Fruits locaux, Gâteaux, etc.
    └── Options végétariennes
Cuisine Européenne :
Menu européen 
├── 🥙 Entrées
│   ├── Soupe, Salade César, etc.
│   └── Allergènes indiqués
├── 🥩 Plats principaux
│   ├── Steaks, Pâtes, Poisson, etc.
│   └── Cuisson personnalisable
└── 🧁 Desserts
    ├── Tiramisu, Tarte, etc.
    └── Options sans sucre
Fonctionnalités : 
	Photos appétissantes des plats 
	Informations nutritionnelles 
	Gestion allergies/régimes spéciaux 
	Estimation nombre de portions
Action : Bouton "Continuer" pour récapitulatif

📋 7. ÉCRAN COMMANDE
Récapitulatif complet
Section récapitulative 
├── 📝 Détails événement
│   ├── Type, date, lieu, invités
│   └── Informations client
├── 🎨 Prestations décoration
│   ├── Type choisi, quantité, prix unitaire
│   └── Sous-total décoration
├── 🍽️ Prestations restauration
│   ├── Plats sélectionnés par catégorie
│   ├── Nombre de portions
│   └── Sous-total restauration
├── 💰 Calculs financiers
│   ├── Sous-total prestations
│   ├── Taxes applicables
│   ├── Remises éventuelles
│   └── TOTAL GÉNÉRAL
└── 📊 Récapitulatif visuel (graphique)
Actions disponibles 
  Bouton Payer maintenant (vert, mis en valeur) 
  Bouton "Annuler commande" (rouge, discret) 
   "Modifier prestations" (retour en arrière) 
   "Sauvegarder pour plus tard"

💳 8. PROCESSUS DE PAIEMENT
Écran Méthodes de paiement
Options disponibles 
Méthodes paiement 
 📱 T-Money
│   ├── Logo, description
│   └── Frais de transaction
└── 💰 Flooz  
    ├── Logo, description
    └── Frais de transaction
Interface 
Cards sélectionnables avec radio buttons • Informations sécurité affichées • Montant total rappelé
Écran Confirmation paiement
• Récapitulatif : Méthode choisie, montant, numéro transaction • Action : "Confirmer le paiement" • Sécurité : Double confirmation utilisateur
Écran Vérification
État de traitement :
├── 🔄 Animation loading
├── ⏳ Message "Traitement en cours..."
├── 📊 Barre de progression
└── ℹ️ "Vérification des fonds..."
Gestion asynchrone : Timeout, retry automatique
Écran Succès
Confirmation succès :
├── ✅ Icône de validation
├── 🎉 Message de félicitations
├── 📄 Numéro de confirmation
├── 📧 "Reçu envoyé par email"
├── 📅 Rappel date événement
└── 🏠 Bouton "Retour accueil"
Écran Échec
Notification échec:
├── ❌ Icône d'erreur
├── 😔 Message d'excuse
├── 🔍 Raison de l'échec
├── 💡 Suggestions solutions
├── 🔄 Bouton "Réessayer"
└── 📞 Contact support
 
⚙️ 9. ÉCRAN PARAMÈTRES
Menu des paramètres
Options disponibles:
├── 👤 Éditer le profil
│   ├── Photo, nom, contact
│   └── Préférences événements
├── 🔒 Changer mot de passe
│   ├── Ancien/nouveau mot de passe
│   └── Confirmation sécurisée
├── 🔔 Notifications
│   ├── Push notifications
│   ├── Email rappels
│   └── SMS confirmations
├── 🌍 Langue et région
├── 🎨 Thème application
├── 💾 Sauvegarde données
├── ❓ Aide et support
├── 📜 Conditions d'utilisation
└── 🚪 Déconnexion
 
👨‍💼 10. ÉCRAN ADMINISTRATEUR
Tableau de bord admin
Modules administrateur :
├── 📊 Analytics
│   ├── Nombre réservations
│   ├── CA par type événement
│   └── Clients actifs
├── 👥 Gestion utilisateurs
│   ├── Liste clients
│   ├── Blocage/déblocage comptes
│   └── Historique activités
├── 🛎️ Gestion services
│   ├── Modifier tarifs
│   ├── Ajouter prestations
│   └── Gérer disponibilités  
├── 💰 Suivi financier
│   ├── Transactions réussies/échouées
│   ├── Commissions prestataires
│   └── Rapports comptables
├── ⚙️ Configuration app
│   ├── Paramètres globaux
│   ├── Messages système
│   └── Maintenance
└── 📞 Support client
    ├── Tickets ouverts
    ├── Messages clients
    └── FAQ management
Sécurité admin : • Authentification renforcée • Logs de toutes les actions • Permissions granulaires
 
🎨 Interface Utilisateur
Design System
• Material Design 3 avec thème personnalisé événementiel • Palette couleurs : Doré/champagne pour élégance • Mode sombre/clair selon préférences • Responsive pour tablettes et téléphones • Animations fluides entre écrans
Composants réutilisables
• Event Cards : Cards événements avec images • Counter Widgets : Boutons +/- pour quantités • Price Displays : Affichage prix formaté • Progress Indicators : Barres progression commande • Custom Buttons : Boutons actions principales • Image Galleries : Carousels photos prestations
 
⚡ Fonctionnalités Avancées
Performance
• Pagination des listes événements • Cache images prestations • Compression photos utilisateur • Mode offline consultation historique
Automatisations
• Rappels automatiques avant événements • Calculs prix temps réel • Suggestions personnalisées selon historique • Notifications push étapes importantes
Intégrations
• Calendrier système synchronisation dates • Contacts importation liste invités • Maps localisation lieux événements • Partage social événements organisés
 
🔄 Workflows Principaux
Réservation complète
Connexion → Services → Type événement → Formulaire → Prestations → Commande → Paiement → Confirmation
Gestion événement
Planification → Modification prestations → Suivi progression → Rappels automatiques → Évaluation post-événement
Process paiement
Récapitulatif → Méthode paiement → Confirmation → Vérification → Succès/Échec → Notification
 
📱 Maquette Wireframe Application
🏠 Écran d'Accueil
┌─────────────────────────────────────────┐
│ ☰ Événements Pro            👤 Profil │
├─────────────────────────────────────────┤
│        👋 Bonjour Marie !               │
│                                         │
│  🎉 [Image bannière événements]        │
│                                         │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐    │
│ │📊 Stats │ │🛎️Service│ │⚙️ Config│    │
│ │3 Événts │ │Réserver │ │Paramètre│    │
│ └─────────┘ └─────────┘ └─────────┘    │
│                                         │
│ 📢 Prochains événements:               │
│ • Mariage Sarah - Dans 15 jours        │
│ • Anniversaire - Dans 30 jours         │
└─────────────────────────────────────────┘
│🏠 Accueil │🛎️Services │📋Mes Événements│
└─────────────────────────────────────────┘
🛎️ Écran Services
│ ← Services Disponibles          🔍     
├┤
│ │
│ │ 💒 MARIAGES                      
│ │ Organisation complète            │ │
│ │ À partir de 500,000 FCFA        │ │
│ │            [Réserver]           │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 🎂 ANNIVERSAIRES                 │ │
│ │ Fêtes personnalisées             │ │
│ │ À partir de 150,000 FCFA        │ │
│ │            [Réserver]           │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 📋 CONFÉRENCES                   │ │
│ │ Événements professionnels        │ │
│ │            [Réserver]           │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
📝 Formulaire Réservation Mariage
┌─────────────────────────────────────────┐
│ ← Réservation Mariage           💾      │
├─────────────────────────────────────────┤
│                                         │
│ 👰 Nom de la mariée                    │
│ ┌─────────────────────────────────────┐ │
│ │ [Sarah Kouadio____________]         │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 🤵 Nom du marié                        │
│ ┌─────────────────────────────────────┐ │
│ │ [Jean Baptiste____________]         │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 👥 Nombre d'invités: [150]    📅📅      │
│                                         │
│ 📅 Date: [25/12/2024]  ⏰ Heure: [14h]  │
│                                         │
│ 💰 Budget prévu                        │
│ ┌─────────────────────────────────────┐ │
│ │ [2,000,000 FCFA_______]            │ │
│ └─────────────────────────────────────┘ │
│                                         │
│        [Annuler]  [Enregistrer]         │
└─────────────────────────────────────────┘
📊 Écran Planification
┌─────────────────────────────────────────┐
│ ← Mariage Sarah & Jean          ⚙️      │
├─────────────────────────────────────────┤
│                                         │
│        ⏳ 🎯 DANS 15 JOURS              │
│                                         │
│ 📈 Progression: ▓▓▓▓▓▓▓░░░ 70%         │
│                                         │
│ ✅ Checklist:                          │
│ ☑️ Lieu réservé                        │
│ ☑️ Traiteur contacté                   │
│ ⬜ Décoration choisie                   │
│ ⬜ Musique réservée                     │
│                                         │
│ 💰 Budget: 1,400,000 / 2,000,000      │
│ ▓▓▓▓▓▓▓░░░ 70% utilisé                 │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │          [🎨 Prestations]          │ │
│ │          [📋 Récapitulatif]        │ │
│ │          [📞 Contacts]             │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
🎨 Écran Prestations - Décoration
┌─────────────────────────────────────────┐
│ ← Prestations                   ✓ Suivant│
├─────────────────────────────────────────┤
│                                         │
│ 🎨 DÉCORATION                          │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 🌸 SIMPLE - 80,000 FCFA            │ │
│ │ [Image déco simple]                 │ │
│ │ Ballons, nappes basiques   [-][0][+]│ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 🎭 MODERNE - 150,000 FCFA          │ │
│ │ [Image déco moderne]                │ │
│ │ Design contemporain        [-][1][+]│ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 💎 LUXUEUSE - 300,000 FCFA         │ │
│ │ [Image déco luxe]                   │ │
│ │ Matériaux premium      [-][0][+]    │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 💰 Sous-total: 150,000 FCFA            │
└─────────────────────────────────────────┘
🍽️ Écran Prestations - Nourriture
┌─────────────────────────────────────────┐
│ ← Nourriture Africaine          ✓ Suivant│
├─────────────────────────────────────────┤
│                                         │
│ 🥗 ENTRÉES                             │
│ ☑️ Salade d'avocat (50 pers) - 25k     │
│ ☑️ Beignets haricot (100p) - 15k       │
│                                         │
│ 🍛 PLATS PRINCIPAUX                     │
│ ☑️ Riz au gras (150 pers) - 120k       │
│ ☑️ Attiéké poisson (150p) - 180k       │
│ ⬜ Foutou sauce claire - 90k            │
│                                         │
│ 🍰 DESSERTS                            │
│ ☑️ Salade de fruits (100p) - 30k       │
│ ⬜ Gâteau traditionnel - 45k            │
│                                         │
│ ───────────────────────────────────────  │
│ 💰 Sous-total Africain: 370,000 FCFA   │
│                                         │
│     [🌍 Européenne] [➡️ Continuer]      │
└─────────────────────────────────────────┘
📋 Écran Commande - Récapitulatif
┌─────────────────────────────────────────┐
│ ← Récapitulatif Commande        💾      │
├─────────────────────────────────────────┤
│                                         │
│ 💒 MARIAGE Sarah & Jean                │
│ 📅 25/12/2024 à 14h00                 │
│ 👥 150 personnes                       │
│                                         │
│ ──────────────────────────────────────── │
│ 🎨 DÉCORATION                          │
│ • Moderne (x1) ............. 150,000₣  │
│                                         │
│ 🍽️ RESTAURATION                       │
│ • Menu Africain ............ 370,000₣  │
│ • Menu Européen ............ 280,000₣  │
│                                         │
│ ──────────────────────────────────────── │
│ Sous-total .................. 800,000₣  │
│ TVA (18%) ................... 144,000₣  │
│ ──────────────────────────────────────── │
│ 💰 TOTAL GÉNÉRAL ............ 944,000₣  │
│                                         │
│      [❌ Annuler]    [💳 Payer]        │
└─────────────────────────────────────────┘
💳 Écran Méthodes Paiement
┌─────────────────────────────────────────┐
│ ← Méthode de Paiement           🔒      │
├─────────────────────────────────────────┤
│                                         │
│ 💰 Montant à payer: 944,000 FCFA       │
│                                         │
│ Choisissez votre méthode:               │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ ⚫ 📱 T-Money                      │ │
│ │    Paiement sécurisé mobile        │ │
│ │    Frais: 2,500 FCFA               │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ ⚪ 💰 Flooz                        │ │
│ │    Portefeuille électronique        │ │
│ │    Frais: 3,000 FCFA               │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 🔒 Paiement 100% sécurisé              │
│                                         │
│           [Confirmer Paiement]          │
└─────────────────────────────────────────┘
⏳ Écran Vérification
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│                                         │
│            🔄 [Animation]               │
│                                         │
│        Traitement en cours...           │
│                                         │
│    Vérification de vos fonds...         │
│                                         │
│        ████████████ 85%                │
│                                         │
│    Veuillez patienter quelques          │
│           instants                      │
│                                         │
│                                         │
│                                         │
└─────────────────────────────────────────┘
✅ Écran Succès
┌─────────────────────────────────────────┐
│                                         │
│              ✅                         │
│                                         │
│         🎉 FÉLICITATIONS ! 🎉           │
│                                         │
│    Votre réservation a été             │
│       confirmée avec succès            │
│                                         │
│ 📄 Confirmation N°: #MRG2024001        │
│                                         │
│ 📧 Reçu envoyé à votre email           │
│                                         │
│ 📅 Rappel programmé pour le             │
│    20 Décembre 2024                    │
│                                         │
│           [🏠 Retour Accueil]           │
│           [📄 Voir Détails]             │
│                                         │
└─────────────────────────────────────────┘
❌ Écran Échec
┌─────────────────────────────────────────┐
│                                         │
│              ❌                         │
│                                         │
│         😔 Paiement échoué              │
│                                         │
│    Nous sommes désolés, votre          │
│    paiement n'a pas pu être traité     │
│                                         │
│ 🔍 Raison: Fonds insuffisants          │
│                                         │
│ 💡 Suggestions:                        │
│ • Vérifiez votre solde                 │
│ • Réessayez dans quelques minutes      │
│ • Contactez votre opérateur            │
│                                         │
│      [🔄 Réessayer] [📞 Support]       │
│           [🏠 Retour]                   │
└─────────────────────────────────────────┘
 

