plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

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

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
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