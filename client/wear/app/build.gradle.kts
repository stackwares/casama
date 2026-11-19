import groovy.json.JsonSlurper
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

// The phone app's version (client/pubspec.yaml, "version: 0.1.0+40"). The Wear bundle has its own
// track in Play Console but shares the package name, so its version code sits above the phone's
// range: 1,000,000,000 + the build number (docs/WATCH-PLAN.md §8.8). `-PbuildNumber=41` overrides.
val pubspecVersion: Pair<String, Int> = run {
    val line = rootProject.file("../pubspec.yaml").readLines().firstOrNull { it.startsWith("version:") }
        ?: error("version: missing from client/pubspec.yaml")
    val raw = line.removePrefix("version:").trim()
    val name = raw.substringBefore('+')
    val build = raw.substringAfter('+', "1").toIntOrNull() ?: 1
    name to build
}
val buildNumber: Int = (findProperty("buildNumber") as String?)?.toIntOrNull() ?: pubspecVersion.second

// Same upload key as the phone (a Wear bundle must share the phone's package and signing key):
// client/android/key.properties, never committed. Without it release builds use the debug key.
val keyProperties = Properties().apply {
    val file = rootProject.file("../android/key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

// Firebase's public client identifiers, the same file the phone's official builds read
// (client/config/firebase.json, --dart-define-from-file). Set up at run time (WearApp.kt), so a
// build without the file simply has no pushes; the app still works by polling the glance.
@Suppress("UNCHECKED_CAST")
val firebase: Map<String, String> = run {
    val file = rootProject.file("../config/firebase.json")
    if (!file.exists()) emptyMap() else (JsonSlurper().parse(file) as Map<String, Any?>)
        .mapValues { (_, v) -> v?.toString() ?: "" }
}
fun firebaseValue(key: String, fallback: String = ""): String =
    firebase[key]?.takeIf { it.isNotBlank() } ?: firebase[fallback] ?: ""
fun quoted(value: String) = "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\""

// Code sign-in's server is Casama Cloud. `-PdefaultServer=<url>` points a DEBUG build at a dev
// stack (store captures, local testing). It never reaches a release: a release build with it set
// (the flag, a gradle.properties line or ORG_GRADLE_PROJECT_defaultServer) fails instead of
// shipping a store bundle whose code sign-in goes somewhere else.
val defaultServerOverride: String? =
    (findProperty("defaultServer") as String?)?.trim()?.trimEnd('/')?.takeIf { it.isNotEmpty() }
if (defaultServerOverride != null) {
    // preReleaseBuild is the first task of every release build (bundleRelease, assembleRelease).
    tasks.configureEach {
        if (name == "preReleaseBuild") {
            doFirst {
                throw GradleException("defaultServer is for debug builds only. Build the release without -PdefaultServer (check gradle.properties and ORG_GRADLE_PROJECT_defaultServer too).")
            }
        }
    }
}

android {
    namespace = "ai.casama.wear"
    // AGP 9.1.1 compiles against API 37, as the phone does. Target stays 36 (§8.8): 36 gives the
    // dimmed always-on screen; 37 would ask for the local-network permission.
    compileSdk = 37

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "ai.casama.app"
        minSdk = 30
        targetSdk = 36
        versionCode = 1_000_000_000 + buildNumber
        versionName = pubspecVersion.first
        buildConfigField("String", "FIREBASE_PROJECT_ID", quoted(firebaseValue("FIREBASE_PROJECT_ID")))
        buildConfigField("String", "FIREBASE_SENDER_ID", quoted(firebaseValue("FIREBASE_MESSAGING_SENDER_ID")))
        buildConfigField("String", "FIREBASE_API_KEY", quoted(firebaseValue("FIREBASE_ANDROID_API_KEY", "FIREBASE_API_KEY")))
        buildConfigField("String", "FIREBASE_APP_ID", quoted(firebaseValue("FIREBASE_ANDROID_APP_ID", "FIREBASE_APP_ID")))
        // Code sign-in's server; a debug build may point elsewhere (defaultServerOverride above).
        buildConfigField("String", "DEFAULT_SERVER", quoted("https://api.casama.ai"))
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    signingConfigs {
        if (keyProperties.isNotEmpty()) {
            create("release") {
                val store = File(keyProperties.getProperty("storeFile"))
                // The phone resolves a relative storeFile from client/android/app.
                storeFile = if (store.isAbsolute) store else rootProject.file("../android/app/${store.path}")
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            // A build type's field replaces defaultConfig's of the same name.
            defaultServerOverride?.let { buildConfigField("String", "DEFAULT_SERVER", quoted(it)) }
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }

    packaging {
        resources.excludes += setOf("/META-INF/{AL2.0,LGPL2.1}", "/META-INF/versions/9/previous-compilation-data.bin")
    }

    testOptions {
        unitTests.all {
            // The shared sample answers every client decodes (packages/contracts/fixtures/watch).
            it.systemProperty("fixtures.dir", rootProject.file("../../packages/contracts/fixtures/watch").absolutePath)
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Compose for Wear OS, Material 3 Expressive (§2.2).
    implementation("androidx.wear.compose:compose-material3:1.7.1")
    implementation("androidx.wear.compose:compose-foundation:1.7.1")
    implementation("androidx.wear.compose:compose-navigation:1.7.1")
    implementation("androidx.activity:activity-compose:1.13.0")
    // A library pulls in an old Fragment; the ActivityResult permission request needs 1.3 or later.
    implementation("androidx.fragment:fragment-ktx:1.9.1")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.11.0")
    implementation("androidx.core:core-ktx:1.19.1")
    // Ambient mode (AmbientLifecycleObserver), RemoteInput helpers, bridging, Ongoing Activity.
    implementation("androidx.wear:wear:1.4.0")
    implementation("androidx.wear:wear-input:1.2.0")
    implementation("androidx.wear:wear-phone-interactions:1.1.1")
    implementation("androidx.wear:wear-ongoing:1.1.0")
    // Tiles and complications (§6.3).
    implementation("androidx.wear.tiles:tiles:1.6.2")
    implementation("androidx.wear.protolayout:protolayout:1.4.2")
    implementation("androidx.wear.protolayout:protolayout-expression:1.4.2")
    implementation("androidx.wear.protolayout:protolayout-material3:1.4.2")
    implementation("androidx.wear.watchface:watchface-complications-data-source-ktx:1.3.0")
    implementation("androidx.concurrent:concurrent-futures-ktx:1.3.0")
    // The phone link (sign-in and Open on phone) and pushes to the watch itself.
    implementation("com.google.android.gms:play-services-wearable:20.0.1")
    implementation("com.google.firebase:firebase-messaging:26.0.2")
    // Network, JSON, background work.
    implementation("com.squareup.okhttp3:okhttp:5.5.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.11.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-guava:1.11.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.13.0")
    implementation("androidx.work:work-runtime-ktx:2.12.0")
    // Ships the baseline profile (src/main/baseline-prof.txt) to devices that install from Play.
    implementation("androidx.profileinstaller:profileinstaller:1.4.1")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit:2.4.0")
}
