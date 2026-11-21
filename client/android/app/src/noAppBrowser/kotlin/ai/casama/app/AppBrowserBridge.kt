package ai.casama.app

import android.app.Activity
import io.flutter.embedding.engine.FlutterEngine

/**
 * The browser inside the phone app (docs/PHONE-BROWSER-PLAN.md) is not in this build: the real
 * bridge lives in src/appBrowser and is compiled only with the build switch (app/build.gradle.kts).
 */
object AppBrowserBridge {
    fun attach(engine: FlutterEngine, activity: Activity) {}
}
