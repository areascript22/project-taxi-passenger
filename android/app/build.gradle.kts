import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("keystore.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.areascript.passenger_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.areascript.passenger_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
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
            resValue("string", "app_name", "Taxi Dev")
        }
        create("prod") {
            dimension = "environment"
            applicationId = "com.areascript.passenger_app"
            versionNameSuffix = ""
            resValue("string", "app_name", "Taxi")
        }
    }

    signingConfigs {
        create("prod") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Use prod signing config for release builds
            signingConfig = if (getCurrentFlavor() == "prod" && keystorePropertiesFile.exists()) {
                signingConfigs.getByName("prod")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

fun getCurrentFlavor(): String {
    return gradle.startParameter.taskNames
        .firstOrNull { it.contains("prod") || it.contains("dev") }
        ?.let { if (it.contains("prod")) "prod" else "dev" }
        ?: "dev"
}
flutter {
    source = "../.."
}