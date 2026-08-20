import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "uz.fargonam.app"
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
    val keystoreFile = rootProject.file("../../keystores/fargonam-user-release.jks")
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
                keyAlias = keyProps.getProperty("keyAlias", "fargonam-user")
                keyPassword = keyProps.getProperty("keyPassword")
            }
        }
    }

    defaultConfig {
        applicationId = "uz.fargonam.app"
        // minSdk 26 — Yandex MapKit talabi edi (hozir o'chirilgan, pastga
        // qarang), o'zgartirilmadi (boshqa bog'liqlik bo'lishi mumkin).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Yandex MapKit API kalit — local.properties dan o'qiladi
        val localProps = Properties()
        val localPropsFile = rootProject.file("local.properties")
        if (localPropsFile.exists()) {
            localPropsFile.inputStream().use { localProps.load(it) }
        }
        buildConfigField(
            "String",
            "YANDEX_MAPKIT_KEY",
            "\"${localProps.getProperty("yandex.mapkit.key", "")}\""
        )
    }

    buildFeatures {
        buildConfig = true
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

dependencies {
    // 2026-08-20: vaqtincha o'chirilgan (APK ~71MB kamaytirish uchun, taksi
    // hali 2-bosqich funksiyasi). Qaytarish: PROGRESS.md "Taksi qaytarish".
    // implementation("com.yandex.android:maps.mobile:4.22.0-lite")
}
