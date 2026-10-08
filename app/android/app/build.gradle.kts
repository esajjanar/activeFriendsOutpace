import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(keyPropertiesFile.inputStream())
}

android {
    namespace = "app.activefriends.app"
    // Health Connect on Android 14+ (Pixel 9, Sep 2026 system update) requires
    // compileSdk ≥ 36. Use maxOf so Flutter upgrades are picked up automatically.
    compileSdk = maxOf(flutter.compileSdkVersion, 36)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "app.activefriends.app"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String?
            keyPassword = keyProperties["keyPassword"] as String?
            storeFile = keyProperties["storeFile"]?.let { rootProject.file(it) }
            storePassword = keyProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = if (keyPropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Do NOT pin androidx.health.connect:connect-client here. The `health`
    // Flutter package (13.3.2) is compiled against 1.2.0-alpha02 and pulls it in
    // transitively. A previous hard override to the OLDER 1.1.0-rc03 forced the
    // plugin's native code to run against APIs it wasn't built for, which can
    // break the Health Connect client at runtime. If a newer client is ever
    // needed, it must MATCH OR EXCEED the version the plugin ships with
    // (latest as of Sep 2026: 1.2.0-alpha06).
}
