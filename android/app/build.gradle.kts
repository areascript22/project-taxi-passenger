import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// dev firma con keystore.properties; prod con keystore-prod.properties (otro
// .jks, guardado fuera del repo). Son llaves de subida distintas a propósito.
val keystorePropertiesFile = rootProject.file("keystore.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val keystoreProdPropertiesFile = rootProject.file("keystore-prod.properties")
val keystoreProdProperties = Properties()
if (keystoreProdPropertiesFile.exists()) {
    keystoreProdProperties.load(FileInputStream(keystoreProdPropertiesFile))
}

fun loadEnvProperties(fileName: String): Properties {
    val props = Properties()
    val file = rootProject.file("../assets/env/$fileName")
    if (file.exists()) {
        FileInputStream(file).use { props.load(it) }
    }
    return props
}

val devEnvProperties = loadEnvProperties(".env_dev")
val prodEnvProperties = loadEnvProperties(".env_prod")

android {
    namespace = "com.areascript.passenger_app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Requerido por flutter_local_notifications en minSdk < 26 (usa
        // APIs de java.time internamente).
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html). [cite: 3]
        applicationId = "com.areascript.passenger_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config. [cite: 4]
        minSdk = 24
        // Fijo en vez de flutter.targetSdkVersion: el Flutter SDK instalado
        // (3.29.2) todavía resuelve ese valor a 35, pero Google Play ya
        // exige apuntar como mínimo a 36 para subidas nuevas. compileSdk ya
        // estaba en 36, así que las herramientas de build ya lo soportan.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Flavor configuration
    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationId = "com.areascript.passenger_app.dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "TaxiGo Dev")
            manifestPlaceholders["mapsApiKey"] = devEnvProperties.getProperty("MAPS_API_KEY", "")
        }
        create("prod") {
            dimension = "environment"
            applicationId = "com.areascript.passenger_app"
            versionNameSuffix = ""
            resValue("string", "app_name", "TaxiGo")
            manifestPlaceholders["mapsApiKey"] = prodEnvProperties.getProperty("MAPS_API_KEY", "")
        }
    }

    signingConfigs {
        create("devRelease") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                // rootProject.file resuelve relativo a "android/"
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
        create("prodRelease") {
            if (keystoreProdPropertiesFile.exists()) {
                keyAlias = keystoreProdProperties.getProperty("keyAlias")
                keyPassword = keystoreProdProperties.getProperty("keyPassword")
                // Ruta absoluta: el .jks de prod vive fuera del repo.
                storeFile = rootProject.file(keystoreProdProperties.getProperty("storeFile"))
                storePassword = keystoreProdProperties.getProperty("storePassword")
            }
        }
    }

    // La firma va por flavor: el buildType "release" no define signingConfig
    // (si lo hiciera, ganaría sobre el del flavor). Los builds debug siguen
    // usando la llave debug de Android.
    productFlavors.getByName("dev").signingConfig = if (keystorePropertiesFile.exists()) {
        signingConfigs.getByName("devRelease")
    } else {
        signingConfigs.getByName("debug")
    }
    productFlavors.getByName("prod").signingConfig = signingConfigs.getByName("prodRelease")
}

// Un release de prod NUNCA debe salir firmado con la llave debug ni con un
// keystore a medio configurar: falla el build en vez de generar un APK que
// Play Console rechazaría (o peor, que aceptaría con la llave equivocada).
gradle.taskGraph.whenReady {
    val buildsProdRelease = allTasks.any {
        it.name.contains("ProdRelease") &&
            (it.name.startsWith("assemble") || it.name.startsWith("bundle") || it.name.startsWith("package"))
    }
    if (buildsProdRelease) {
        if (!keystoreProdPropertiesFile.exists()) {
            throw GradleException("Falta android/keystore-prod.properties: no se puede firmar el release de prod.")
        }
        if (keystoreProdProperties.getProperty("storePassword") == "CHANGE_ME" ||
            keystoreProdProperties.getProperty("keyPassword") == "CHANGE_ME") {
            throw GradleException("android/keystore-prod.properties todavía tiene CHANGE_ME: pon las contraseñas reales.")
        }
        val prodStore = rootProject.file(keystoreProdProperties.getProperty("storeFile") ?: "")
        if (!prodStore.isFile) {
            throw GradleException("No existe el keystore de prod: $prodStore")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}