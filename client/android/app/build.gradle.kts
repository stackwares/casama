import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Official release builds sign with Casama's upload key: android/key.properties (never committed;
// a copy of ~/.config/casama/android-key.properties, keystore and passwords in Vaultwarden).
// Without it (self-hosters, CI) release builds sign with the debug key so they still run.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "ai.casama.app"
    // Some plugins (receive_sharing_intent, permission_handler) need API 37 to compile against.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ai.casama.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keyProperties.isNotEmpty()) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
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

// Release and profile builds leave out dev_dependencies plugins (integration_test), but any other
// Flutter command in client/ (`flutter test`, `flutter pub get`, a web build) rewrites
// GeneratedPluginRegistrant.java with them included. If that happens while this build runs, javac
// fails with "package dev.flutter.plugins.integration_test does not exist". Strip dev-only plugin
// registrations right before compiling a release or profile build so the race can't break it.
val pluginRegistrant = file("src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")
val pluginDependencies = rootProject.file("../.flutter-plugins-dependencies")
tasks.matching { it.name == "compileReleaseJavaWithJavac" || it.name == "compileProfileJavaWithJavac" }
    .configureEach {
        doFirst {
            if (!pluginRegistrant.exists() || !pluginDependencies.exists()) return@doFirst
            val devPlugins = Regex("\"name\":\"([^\"]+)\"[^{}]*?\"dev_dependency\":true")
                .findAll(pluginDependencies.readText())
                .map { it.groupValues[1] }
                .toSet()
            val source = pluginRegistrant.readText()
            var cleaned = source
            for (name in devPlugins) {
                cleaned = cleaned.replace(
                    Regex(
                        "\\s*try \\{\\s*flutterEngine\\.getPlugins\\(\\)\\.add\\(new [\\w.]+\\(\\)\\);\\s*" +
                            "\\} catch \\(Exception e\\) \\{\\s*Log\\.e\\(TAG, \"Error registering plugin " +
                            Regex.escape(name) + ",[^\"]*\", e\\);\\s*\\}",
                    ),
                    "",
                )
            }
            if (cleaned != source) {
                pluginRegistrant.writeText(cleaned)
                logger.lifecycle("Removed dev-only plugins from GeneratedPluginRegistrant: ${devPlugins.joinToString()}")
            }
        }
    }
