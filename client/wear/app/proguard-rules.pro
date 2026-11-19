# R8 rules for the Wear OS app. Libraries ship their own consumer rules (Compose, Wear, Tiles,
# OkHttp, coroutines, Firebase, Play services); these cover what reflection or the manifest reaches.

# Manifest entry points are kept by AAPT's generated rules; WorkManager builds workers by name.
-keep class ai.casama.wear.data.OutboxWorker { <init>(...); }

# kotlinx.serialization: the app decodes through JsonElement only (no @Serializable classes),
# so the library's own rules are enough. Keep line numbers for readable crash reports.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# OkHttp 5 optional platform integrations that are absent on Android.
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**

# Google Tink / error-prone annotations pulled in transitively by Play services.
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
