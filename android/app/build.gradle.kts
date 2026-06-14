import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("keystore.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    println("⚠️ WARNING: keystore.properties not found")
}

android {
    namespace = "com.areascript.passenger_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Configuración de firmas para RELEASE
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    // Flavor configuration
    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationId = "com.areascript.passenger_app.dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "ViaGo Dev")
            // 🔥 IMPORTANTE: Asignar la firma de release
            signingConfig = signingConfigs.getByName("release")
        }
        create("prod") {
            dimension = "environment"
            applicationId = "com.areascript.passenger_app"
            versionNameSuffix = ""
            resValue("string", "app_name", "Taxi")
            signingConfig = signingConfigs.getByName("release")
        }
    }

    buildTypes {
        release {
            // 🔥 Ya no es necesario asignar aquí porque cada flavor ya tiene su signingConfig
            signingConfig = null  // Dejar que cada flavor maneje su firma
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            // Opcional: También firmar debug con release para pruebas
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}