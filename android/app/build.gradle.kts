import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKey = keystorePropertiesFile.exists()
if (hasReleaseKey) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "ro.acilfov.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Necesar pentru flutter_local_notifications (notificari programate).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ro.acilfov.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    // Un release semnat cu cheia de debug poate fi impersonat mai usor si nu
    // ar trebui distribuit. Verificarea e lazy (doar cand se asambleaza chiar
    // o varianta de release), ca sa nu stricam build-urile de debug pe masini
    // fara `key.properties`.
    tasks.matching { it.name.startsWith("assembleRelease") || it.name.startsWith("bundleRelease") }
        .configureEach {
            doFirst {
                if (!hasReleaseKey) {
                    throw GradleException(
                        "Lipseste android/key.properties: un build de release nu poate " +
                            "fi semnat cu cheia de debug. Adauga fisierul cu keystore-ul " +
                            "de productie inainte de a rula acest task."
                    )
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
    // Biblioteca de "desugaring" ceruta de flutter_local_notifications.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
