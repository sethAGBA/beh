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
