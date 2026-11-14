import java.util.Properties
import java.io.FileInputStream
import java.net.URI
import java.util.Base64

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Le plugin fait échouer le build sans ce fichier, propre au projet Firebase.
// Sans lui l'application se construit et tourne, sans notifications push.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// Clé d'envoi Google Play, hors dépôt (android/key.properties).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Hôte des liens d'application (App Links) : celui du serveur que vise la
// compilation — --dart-define=API_BASE_URL (Flutter le transmet encodé en
// base64 dans la propriété « dart-defines »), à défaut la valeur par défaut de
// lib/core/config/env.dart, relue ici pour n'avoir qu'une source. Une
// application compilée pour la pile de test n'intercepte donc pas les liens de
// la production, ni l'inverse.
val hoteLiens: String = run {
    val defines = (project.findProperty("dart-defines") as String?)
        ?.split(",")
        ?.mapNotNull { runCatching { String(Base64.getDecoder().decode(it)) }.getOrNull() }
        .orEmpty()
    val adresseCompilee = defines.firstOrNull { it.startsWith("API_BASE_URL=") }?.substringAfter("=")
    val adresseParDefaut = rootProject.file("../lib/core/config/env.dart")
        .takeIf { it.exists() }
        ?.readLines()
        ?.map { it.trim() }
        ?.dropWhile { !it.contains("'API_BASE_URL'") }
        ?.filterNot { it.startsWith("//") }
        ?.firstNotNullOfOrNull { Regex("defaultValue:\\s*'([^']+)'").find(it)?.groupValues?.get(1) }
    val adresse = adresseCompilee ?: adresseParDefaut ?: "https://si.ysem.education"
    runCatching { URI(adresse).host }.getOrNull() ?: "si.ysem.education"
}

android {
    namespace = "com.ysem.ysem"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Identifiant Google Play : définitif une fois publié.
        applicationId = "com.ysem.education"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["hoteLiens"] = hoteLiens
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // Sans key.properties (autre poste), repli sur la clé de debug.
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
