package ai.casama.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.browser.customtabs.CustomTabsIntent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity: Health Connect's permission screen needs a FragmentActivity (D-150).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "casama/sign_in_sheet")
            .setMethodCallHandler { call, result ->
                val url = call.argument<String>("url")
                if (call.method != "open" || url == null) result.notImplemented()
                else SignInSheet.open(this, url, result)
            }
    }

    override fun onPause() {
        super.onPause()
        SignInSheet.left()
    }

    override fun onResume() {
        super.onResume()
        SignInSheet.resumed()
    }
}

/**
 * The sign-in sheet (D-243): a Custom Tab that shares the browser's sign-ins. The server ends a
 * sign-in on casama-auth://done, which [SignInCallbackActivity] catches; the tab has no history, so
 * it closes once that activity shows. Back in the app without that address: the person closed it.
 */
object SignInSheet {
    private var pending: MethodChannel.Result? = null
    private var away = false

    fun open(activity: Activity, url: String, result: MethodChannel.Result) {
        pending?.success(null)
        pending = result
        away = false
        try {
            val tab = CustomTabsIntent.Builder().setShowTitle(true).build()
            tab.intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY or Intent.FLAG_ACTIVITY_NEW_TASK)
            tab.launchUrl(activity, Uri.parse(url))
        } catch (e: Exception) {
            pending = null
            result.error("failed", e.message, null)
        }
    }

    fun finished(uri: Uri?) {
        pending?.success(uri?.toString())
        pending = null
    }

    fun left() {
        if (pending != null) away = true
    }

    fun resumed() {
        if (!away) return
        away = false
        // Returned before casama-auth://done arrived: closed. (The callback runs before this.)
        pending?.success(null)
        pending = null
    }
}

/** Catches casama-auth://done, hands it to [SignInSheet] and gets out of the way. */
class SignInCallbackActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        SignInSheet.finished(intent?.data)
        // Bring the app's existing task forward, as a launcher tap would (no second copy).
        packageManager.getLaunchIntentForPackage(packageName)?.let {
            it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(it)
        }
        finish()
    }
}
