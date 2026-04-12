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
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // Release imzolash — keystores/ papkasidan o'qiladi
    val keystoreFile = rootProject.file("../../keystores/fargonam-user-release.jks")
    signingConfigs {
        if (keystoreFile.exists()) {
            create("release") {
                storeFile = keystoreFile
                storePassword = "fargonam@user2024"
                keyAlias = "fargonam-user"
                keyPassword = "fargonam@user2024"
            }
        }
    }

    defaultConfig {
        applicationId = "uz.fargonam.app"
        // Yandex MapKit Android 8.0+ talab qiladi
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Yandex MapKit API kalit — local.properties dan o'qiladi
        val localProps = java.util.Properties()
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
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Yandex MapKit native SDK (lite variant — kichikroq, POI'lar yo'q)
    implementation("com.yandex.android:maps.mobile:4.22.0-lite")
}
