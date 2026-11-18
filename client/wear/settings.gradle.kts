// Casama for Wear OS (D-410, docs/WATCH-PLAN.md §8.8). Its own Gradle project on purpose
// (decision 14): the Flutter tool runs bare task names (`bundleRelease`) in every module of
// client/android, so a Wear module there would be built, and could fail, with every phone build.
// Keep the Android Gradle plugin and Kotlin versions in step with client/android/settings.gradle.kts.
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("com.android.application") version "9.1.1" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.4.0" apply false
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "casama-wear"
include(":app")
