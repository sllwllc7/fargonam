plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
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
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // Release imzolash — keystores/ papkasidan o'qiladi
    val keystoreFile = rootProject.file("../../keystores/fargonam-seller-release.jks")
    signingConfigs {
        if (keystoreFile.exists()) {
            create("release") {
                storeFile = keystoreFile
                storePassword = "fargonam@seller2024"
                keyAlias = "fargonam-seller"
                keyPassword = "fargonam@seller2024"
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
        }
    }
}

flutter {
    source = "../.."
}
