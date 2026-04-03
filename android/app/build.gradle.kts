plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

android {
    namespace = "com.reelboost.reelboost_ai"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.reelboost.reelboost_ai"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val localProps = Properties()
    val localPropsFile = rootProject.file("local.properties")
    if (localPropsFile.exists()) {
        localPropsFile.inputStream().use { localProps.load(it) }
    }
    // Empty AdMob app id crashes the native SDK at startup — always use a valid placeholder.
    val admobAppIdResolved =
        (localProps.getProperty("ADMOB_APP_ID") ?: "").trim().takeIf { it.isNotEmpty() }
            ?: "ca-app-pub-3940256099942544~3347511713"

    val keystoreProps = Properties()
    val keystorePropsFile = rootProject.file("key.properties")
    if (keystorePropsFile.exists()) {
        keystorePropsFile.inputStream().use { keystoreProps.load(it) }
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProps.getProperty("storeFile") ?: ""
            if (storeFilePath.isNotBlank()) {
                storeFile = file(storeFilePath)
            }
            storePassword = keystoreProps.getProperty("storePassword") ?: ""
            keyAlias = keystoreProps.getProperty("keyAlias") ?: ""
            keyPassword = keystoreProps.getProperty("keyPassword") ?: ""
        }
    }

    buildTypes {
        debug {
            manifestPlaceholders["usesCleartextTraffic"] = "true"
            manifestPlaceholders["admobAppId"] = admobAppIdResolved
        }
        release {
            // Play Store: add android/key.properties with storeFile, passwords, keyAlias.
            // Without it, release APK is signed with the debug key (local testing only).
            val storePath = (keystoreProps.getProperty("storeFile") ?: "").trim()
            signingConfig = if (storePath.isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Production API is HTTPS-only (Railway).
            manifestPlaceholders["usesCleartextTraffic"] = "false"
            // Real ID via local.properties ADMOB_APP_ID; otherwise Google test app id (never empty).
            manifestPlaceholders["admobAppId"] = admobAppIdResolved

            // Avoid R8 minify on some Windows setups where classes.dex stays locked (AV/IDE).
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
