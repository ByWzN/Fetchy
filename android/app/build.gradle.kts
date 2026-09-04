import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing credentials, kept out of version control (android/.gitignore
// excludes both key.properties and *.jks). Android permanently ties an app's
// identity to its signing key: an update signed with a different key is
// refused outright, so this keystore and its password must be backed up and
// never regenerated once a release has been published.
//
// Absent on a machine that has not been set up for release signing — the
// release build type then falls back to debug signing so ordinary local
// builds still work.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}
val hasReleaseSigning = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.example.fetchy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.fetchy"

        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters += listOf(
                "arm64-v8a",
                "armeabi-v7a",
                "x86_64"
            )
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true

            // youtubedl-android's ffmpeg/python artifacts ship their
            // bundled binaries as libffmpeg.zip.so / libpython.zip.so — a
            // zip archive under a .so name, not real native code — so AGP's
            // release-build debug-symbol stripping (llvm-strip) can fail
            // against them with "not recognized as a valid object file".
            // This tells AGP to package these two files exactly as they
            // are rather than attempting to strip them; every other
            // library is unaffected and still gets stripped normally.
            keepDebugSymbols += setOf(
                "**/libffmpeg.zip.so",
                "**/libpython.zip.so"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Falls back to debug signing only when no keystore is configured
            // on this machine. A published build must always use the release
            // key — see the note above.
            signingConfig = if (hasReleaseSigning) {
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

dependencies {
    implementation("io.github.junkfood02.youtubedl-android:library:0.18.1")

    // LGPL-3.0, arm64-v8a only. Merge is unavailable on other ABIs;
    // direct and audio-only downloads remain supported there.
     implementation("io.github.junkfood02.youtubedl-android:ffmpeg:0.18.1")

    // Connected Accounts/Sessions: Keystore-backed encryption at rest for
    // locally-imported cookie sessions. Deliberately the smallest official
    // library that provides this — no bespoke crypto, no large dependency.
    implementation("androidx.security:security-crypto:1.1.0")

    // Easy Connect: launches third-party login in a real browser (Custom
    // Tabs) instead of an embedded WebView, per Android's own guidance for
    // third-party authentication. See SessionsChannelHandler.
    implementation("androidx.browser:browser:1.10.0")

    // Download Location (custom folder): reads/writes into a
    // user-granted Storage Access Framework tree via DocumentFile,
    // without constructing raw filesystem paths. See
    // com.example.fetchy.storage.
    implementation("androidx.documentfile:documentfile:1.0.1")
}

flutter {
    source = "../.."
}