import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // google-services.json talab qiladi — Firebase konsolida "uz.fargonam.mobile_seller"
    // ro'yxatdan o'tkazilgach shu fayl android/app/ ostiga qo'yiladi (hozircha yo'q).
    id("com.google.gms.google-services")
}

android {
    namespace = "uz.fargonam.mobile_seller"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    // Release imzolash — keystores/ papkasidan, parollar key.properties'dan
    // o'qiladi (key.properties git'ga tushmaydi, .gitignore'da)
    val keystoreFile = rootProject.file("../../keystores/fargonam-seller-release.jks")
    val keyProps = Properties()
    val keyPropsFile = rootProject.file("key.properties")
    if (keyPropsFile.exists()) {
        keyPropsFile.inputStream().use { keyProps.load(it) }
    }
    signingConfigs {
        if (keystoreFile.exists() && keyProps.containsKey("storePassword")) {
            create("release") {
                storeFile = keystoreFile
                storePassword = keyProps.getProperty("storePassword")
                keyAlias = keyProps.getProperty("keyAlias", "fargonam-seller")
                keyPassword = keyProps.getProperty("keyPassword")
            }
        }
    }

    defaultConfig {
        applicationId = "uz.fargonam.mobile_seller"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Keystore mavjud bo'lsa — release imzo, aks holda debug
            val relCfg = signingConfigs.findByName("release")
            signingConfig = relCfg ?: signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
