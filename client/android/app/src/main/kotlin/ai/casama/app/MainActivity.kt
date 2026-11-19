package ai.casama.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.browser.customtabs.CustomTabsIntent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity: Health Connect's permission screen needs a FragmentActivity (D-150).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Channels, clearing a chat's replies, approval buttons (D-325).
        PushNotifications.ensureChannels(this)
        PushNotifications.attach(MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "casama/notifications"), this)
        PushNotifications.deliver(intent)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "casama/sign_in_sheet")
            .setMethodCallHandler { call, result ->
                val url = call.argument<String>("url")
                if (call.method != "open" || url == null) result.notImplemented()
                else SignInSheet.open(this, url, result)
            }
        // Live calls in the background (D-327 §7): the call notification's service.
        CallBridge.channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "casama/call_service").also {
            it.setMethodCallHandler { call, result -> CallBridge.handle(applicationContext, call, result) }
        }
        // Live calls (D-327): the screen stays on while the call screen is in front.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "casama/screen_awake")
            .setMethodCallHandler { call, result ->
                val on = call.argument<Boolean>("on")
                if (call.method != "set" || on == null) {
                    result.notImplemented()
                } else {
                    if (on) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    result.success(null)
                }
            }
        // The app lock (D-375): a blank picture in Recents while it's on (Android 13+), and no
        // screenshots or recordings when the person asks for that.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "casama/app_lock")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                    "set" -> {
                        val hide = call.argument<Boolean>("hideInRecents") ?: false
                        val secure = call.argument<Boolean>("secure") ?: false
                        if (Build.VERSION.SDK_INT >= 33) setRecentsScreenshotEnabled(!hide)
                        if (secure) window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        else window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        // Widgets (D-405): the widget key, redraws, what's placed, and adding widgets or a bot's
        // icon to the home screen. The glance itself goes through home_widget.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "casama/widgets")
            .setMethodCallHandler { call, result -> WidgetChannel.handle(applicationContext, call, result) }
        // Wear OS (D-410): signing a watch in, workspace switches and sign-out (WATCH-PROTOCOL §3).
        WearBridge.attach(MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "casama/watch"), this)
        // The island on Android (D-324, Phase 5): the app's feed drawn as live notifications.
        val island = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "casama/island")
        LiveRun.channel = island
        island
            .setMethodCallHandler { call, result ->
                val debug = LiveRun.debuggable(this)
                when (call.method) {
                    "state" -> result.success(LiveRun.apply(applicationContext, call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()))
                    // Debug builds only: the on-device check (integration_test/island_android_test.dart).
                    "debug" -> if (debug) result.success(LiveRun.debugState(applicationContext)) else result.notImplemented()
                    "debugWidget" -> if (debug) result.success(LiveRun.debugWidget(applicationContext)) else result.notImplemented()
                    "debugPush" -> if (debug) {
                        // A server push as LiveRunReceiver hands it over, without Firebase.
                        val data = (call.arguments as? Map<*, *>).orEmpty()
                            .mapNotNull { (k, v) -> if (k is String && v is String) k to v else null }.toMap()
                        val wasInFront = LiveRun.appInFront
                        LiveRun.appInFront = false
                        LiveRun.fromPush(applicationContext, data)
                        LiveRun.appInFront = wasInFront
                        result.success(true)
                    } else result.notImplemented()
                    "debugAction" -> if (debug) {
                        val args = (call.arguments as? Map<*, *>).orEmpty()
                        result.success(LiveRun.debugAction(this, args["run_id"] as? String, args["title"] as? String))
                    } else result.notImplemented()
                    "debugForceCustom" -> if (debug) {
                        LiveRun.forceCustom = call.arguments == true
                        result.success(true)
                    } else result.notImplemented()
                    else -> result.notImplemented()
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // The call lives in Flutter: without the engine there's no call, so no notification either.
        CallBridge.channel = null
        CallService.stop(applicationContext)
        PushNotifications.detach()
        LiveRun.channel = null
        WearBridge.detach()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // The call notification, tapped: the call screen.
        if (intent.action == CallService.ACTION_OPEN) CallBridge.send("open")
        PushNotifications.deliver(intent)
    }

    override fun onPause() {
        super.onPause()
        LiveRun.appInFront = false
        PushNotifications.foreground = false
        SignInSheet.left()
    }

    override fun onResume() {
        super.onResume()
        LiveRun.appInFront = true
        PushNotifications.foreground = true
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
