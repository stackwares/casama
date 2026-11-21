package ai.casama.app

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Base64
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.webkit.JsPromptResult
import android.webkit.JsResult
import android.webkit.RenderProcessGoneDetail
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import androidx.webkit.JavaScriptReplyProxy
import androidx.webkit.ProfileStore
import androidx.webkit.WebMessageCompat
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import org.json.JSONObject
import java.io.ByteArrayOutputStream

/**
 * The browser inside the phone app (docs/PHONE-BROWSER-PLAN.md): one WebView a bot can drive while
 * the person watches. The contract with Dart is client/lib/features/app_browser/PROTOCOL.md §3.
 *
 * - Its own profile ("casama-bots"), so its cookies and storage are apart from everything else.
 * - The page script (assets/app_browser/page_agent.js) runs in an isolated script world, in every
 *   frame, from document start. Commands and answers travel as messages on the world's
 *   `casamaNative` object, never as evaluated strings.
 * - Dart decides every main-frame navigation before it loads, and again where it lands.
 * - A phone whose WebView lacks profiles or isolated worlds reports "not supported"; there is no
 *   fallback into the page's own world.
 */
object AppBrowserBridge {
    private const val CHANNEL = "casama/app_browser"
    private const val VIEW_TYPE = "casama/app_browser_view"
    private const val PROFILE = "casama-bots"
    private const val WORLD = "casama"
    private const val JS_OBJECT = "casamaNative"
    private val ALL = setOf("*")

    private val main = Handler(Looper.getMainLooper())
    private var channel: MethodChannel? = null
    private var activity: Activity? = null
    private var web: BotWebView? = null
    private var holder: FrameLayout? = null

    /** The top frame's side of the page script, once it has said hello on this page. */
    private var top: JavaScriptReplyProxy? = null
    private val pending = HashMap<String, MethodChannel.Result>()
    private var seq = 0

    /** Addresses Dart already allowed, each good for one load. */
    private val approved = HashSet<String>()
    private var dialog: JsResult? = null
    private var scale = 1f

    fun attach(engine: FlutterEngine, activity: Activity) {
        this.activity = activity
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler { call, result -> handle(call, result) }
        }
        engine.platformViewsController.registry.registerViewFactory(VIEW_TYPE, Factory)
    }

    private fun unsupported(): String? = when {
        !WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE) -> "no_profiles"
        !WebViewFeature.isFeatureSupported(WebViewFeature.WEB_MESSAGE_LISTENER) -> "no_messages"
        !WebViewFeature.isFeatureSupported(WebViewFeature.JS_INJECTION_IN_FRAME_AND_WORLD) -> "no_isolated_world"
        else -> null
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "supported" -> {
                    val why = unsupported()
                    result.success(mapOf("supported" to (why == null), "reason" to why, "realTaps" to true))
                }
                "load" -> {
                    val url = call.argument<String>("url") ?: return result.error("bad_args", "url", null)
                    val w = view() ?: return result.error("unsupported", unsupported(), null)
                    approved.add(url)
                    w.loadUrl(url)
                    result.success(null)
                }
                "command" -> command(call.argument<String>("json") ?: "{}", call.argument<Int>("timeout_ms") ?: 30_000, result)
                "tap" -> {
                    val w = web ?: return result.error("no_page", "No page is open", null)
                    val x = (call.argument<Number>("x") ?: 0).toFloat() * scale
                    val y = (call.argument<Number>("y") ?: 0).toFloat() * scale
                    w.tap(x, y) { result.success(null) }
                }
                "screenshot" -> {
                    val w = web ?: return result.error("no_page", "No page is open", null)
                    result.success(mapOf("data" to w.picture(call.argument<Int>("quality") ?: 70)))
                }
                "url" -> {
                    val w = web
                    result.success(
                        mapOf(
                            "url" to (w?.url ?: "about:blank"),
                            "title" to (w?.title ?: ""),
                            "loading" to ((w?.progress ?: 100) < 100),
                            "canGoBack" to (w?.canGoBack() ?: false),
                            "canGoForward" to (w?.canGoForward() ?: false),
                        ),
                    )
                }
                "back" -> { web?.goBack(); result.success(null) }
                "forward" -> { web?.goForward(); result.success(null) }
                "reload" -> { web?.reload(); result.success(null) }
                "stop" -> { web?.stopLoading(); result.success(null) }
                "answerDialog" -> {
                    val accept = call.argument<Boolean>("accept") ?: false
                    val d = dialog
                    dialog = null
                    if (d is JsPromptResult && accept) d.confirm(call.argument<String>("text") ?: "")
                    else if (accept) d?.confirm() else d?.cancel()
                    result.success(null)
                }
                "clearData" -> { clearData(call.argument<String>("host")); result.success(null) }
                "dispose" -> { dispose(); result.success(null) }
                else -> result.notImplemented()
            }
        } catch (e: Throwable) {
            result.error("failed", e.message, null)
        }
    }

    /** The one web view, made on first use. Null when this phone's WebView can't do it safely. */
    @SuppressLint("SetJavaScriptEnabled")
    private fun view(): BotWebView? {
        web?.let { return it }
        if (unsupported() != null) return null
        val ctx = activity ?: return null
        val w = BotWebView(ctx)
        // The profile first: it must be set before anything else is done with the view.
        WebViewCompat.setProfile(w, PROFILE)
        w.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            allowFileAccess = false
            allowContentAccess = false
            mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
            setSupportMultipleWindows(false)
            javaScriptCanOpenWindowsAutomatically = false
            mediaPlaybackRequiresUserGesture = true
        }
        scale = ctx.resources.displayMetrics.density
        val world = WebViewCompat.getExecutionWorld(w, WORLD)
        WebViewCompat.addWebMessageListener(w, JS_OBJECT, ALL, world, Listener)
        WebViewCompat.addJavaScriptOnEvent(w, pageScript(ctx), WebViewCompat.INJECTION_EVENT_DOCUMENT_START, ALL, world)
        w.webViewClient = Client
        w.webChromeClient = Chrome
        holder?.let { put(w, it) }
        web = w
        return w
    }

    private fun pageScript(ctx: Context): String {
        val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset("assets/app_browser/page_agent.js")
        val source = ctx.assets.open(key).bufferedReader().use { it.readText() }
        // A secret the frames of one page share, so only our script (never the page's) can connect
        // a frame's part of the script to the top one. New for every web view.
        val secret = java.util.UUID.randomUUID().toString()
        return "globalThis.__casamaPageAgentConfig={secret:\"$secret\"};\n$source"
    }

    private fun put(w: View, into: FrameLayout) {
        (w.parent as? ViewGroup)?.removeView(w)
        into.addView(w, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT))
    }

    // --- Page script -------------------------------------------------------------------------

    private fun command(json: String, timeoutMs: Int, result: MethodChannel.Result) {
        val proxy = top ?: return result.success("""{"ok":false,"code":"error","message":"The page isn't ready yet"}""")
        val id = "n${++seq}"
        val cmd = try { JSONObject(json).put("id", id) } catch (e: Throwable) { return result.error("bad_args", "json", null) }
        pending[id] = result
        main.postDelayed({
            pending.remove(id)?.success("""{"ok":false,"code":"error","message":"The page didn't answer in time"}""")
        }, timeoutMs.toLong())
        proxy.postMessage(cmd.toString())
    }

    private object Listener : WebViewCompat.WebMessageListener {
        override fun onPostMessage(view: WebView, message: WebMessageCompat, sourceOrigin: Uri, isMainFrame: Boolean, replyProxy: JavaScriptReplyProxy) {
            val data = message.data ?: return
            val m = try { JSONObject(data) } catch (e: Throwable) { return }
            if (m.optBoolean("hello")) {
                // Only the top frame takes commands; child frames talk to it inside the page.
                if (isMainFrame) top = replyProxy
                return
            }
            if (!isMainFrame) return
            val id = m.optString("id")
            pending.remove(id)?.success(m.toString())
        }
    }

    // --- Navigation --------------------------------------------------------------------------

    private fun ask(method: String, args: Map<String, Any?>, done: (Boolean) -> Unit) {
        val ch = channel ?: return done(false)
        ch.invokeMethod(method, args, object : MethodChannel.Result {
            override fun success(result: Any?) = done(result == true)
            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) = done(false)
            override fun notImplemented() = done(false)
        })
    }

    private object Client : WebViewClient() {
        override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
            if (!request.isForMainFrame) return false
            val url = request.url.toString()
            if (url == "about:blank" || approved.remove(url)) return false
            // Held until Dart says yes; then it loads once as an approved address.
            ask("navigate", mapOf("url" to url, "redirect" to request.isRedirect, "user" to request.hasGesture())) { ok ->
                if (ok) {
                    approved.add(url)
                    view.loadUrl(url)
                }
            }
            return true
        }

        override fun onPageStarted(view: WebView, url: String, favicon: Bitmap?) {
            top = null
            dialog = null
            channel?.invokeMethod("pageStarted", mapOf("url" to url))
            if (url == "about:blank") return
            // Where the page really landed (a form post or a redirect never asked first).
            ask("landed", mapOf("url" to url)) { ok ->
                if (!ok) {
                    view.stopLoading()
                    view.loadUrl("about:blank")
                }
            }
        }

        override fun onPageFinished(view: WebView, url: String) {
            channel?.invokeMethod("pageFinished", mapOf("url" to url, "title" to (view.title ?: "")))
        }

        override fun onScaleChanged(view: WebView, oldScale: Float, newScale: Float) {
            scale = newScale
        }

        override fun onRenderProcessGone(view: WebView, detail: RenderProcessGoneDetail): Boolean {
            dispose()
            channel?.invokeMethod("gone", mapOf("reason" to if (detail.didCrash()) "crashed" else "killed"))
            return true
        }
    }

    private object Chrome : WebChromeClient() {
        private fun hold(kind: String, message: String?, result: JsResult): Boolean {
            dialog?.cancel()
            dialog = result
            channel?.invokeMethod("dialog", mapOf("kind" to kind, "message" to (message ?: "")))
            // Dart answers, or dismisses it after 30 seconds; this is the backstop.
            main.postDelayed({ if (dialog === result) { dialog = null; result.cancel() } }, 60_000)
            return true
        }

        override fun onJsAlert(view: WebView, url: String?, message: String?, result: JsResult) = hold("alert", message, result)
        override fun onJsConfirm(view: WebView, url: String?, message: String?, result: JsResult) = hold("confirm", message, result)
        override fun onJsPrompt(view: WebView, url: String?, message: String?, defaultValue: String?, result: JsPromptResult) =
            hold("prompt", message, result)

        // A bot sets files through the page script; the system picker isn't offered.
        override fun onShowFileChooser(webView: WebView, filePathCallback: ValueCallback<Array<Uri>>, fileChooserParams: FileChooserParams): Boolean {
            filePathCallback.onReceiveValue(null)
            return true
        }
    }

    // --- Data --------------------------------------------------------------------------------

    private fun clearData(host: String?) {
        val profile = ProfileStore.getInstance().getOrCreateProfile(PROFILE)
        val cookies = profile.cookieManager
        if (host == null) {
            cookies.removeAllCookies(null)
            profile.webStorage.deleteAllData()
            web?.clearCache(true)
            web?.clearHistory()
        } else {
            for (origin in listOf("https://$host", "https://www.$host", "http://$host")) {
                cookies.getCookie(origin)?.split(";")?.forEach { pair ->
                    val name = pair.substringBefore("=").trim()
                    if (name.isNotEmpty()) {
                        cookies.setCookie(origin, "$name=; Max-Age=0; Path=/")
                        cookies.setCookie(origin, "$name=; Max-Age=0; Path=/; Domain=.$host")
                    }
                }
                profile.webStorage.deleteOrigin(origin)
            }
        }
        cookies.flush()
    }

    private fun dispose() {
        for (r in pending.values) r.success("""{"ok":false,"code":"error","message":"The page was closed"}""")
        pending.clear()
        top = null
        dialog?.cancel()
        dialog = null
        approved.clear()
        web?.let {
            (it.parent as? ViewGroup)?.removeView(it)
            it.stopLoading()
            it.destroy()
        }
        web = null
    }

    // --- The view ----------------------------------------------------------------------------

    private object Factory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
        override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
            val frame = FrameLayout(context)
            holder = frame
            view()?.let { put(it, frame) }
            return object : PlatformView {
                override fun getView(): View = frame
                override fun dispose() {
                    // The page outlives the screen that showed it: keep the web view, drop the frame.
                    if (holder === frame) holder = null
                    web?.let { if (it.parent === frame) frame.removeView(it) }
                }
            }
        }
    }

    /** A WebView that says when a real finger touches it, and can tap for a bot. */
    private class BotWebView(context: Context) : WebView(context) {
        private var injecting = false

        override fun dispatchTouchEvent(ev: MotionEvent): Boolean {
            if (!injecting && ev.actionMasked == MotionEvent.ACTION_DOWN) channel?.invokeMethod("userTouched", null)
            return super.dispatchTouchEvent(ev)
        }

        private fun touch(action: Int, down: Long, at: Long, x: Float, y: Float) {
            val e = MotionEvent.obtain(down, at, action, x, y, 0)
            e.source = android.view.InputDevice.SOURCE_TOUCHSCREEN
            injecting = true
            try { super.dispatchTouchEvent(e) } finally { injecting = false }
            e.recycle()
        }

        /** A tap through the view's own input path, so the page sees it as a real one. */
        fun tap(x: Float, y: Float, done: () -> Unit) {
            val down = SystemClock.uptimeMillis()
            touch(MotionEvent.ACTION_DOWN, down, down, x, y)
            main.postDelayed({
                touch(MotionEvent.ACTION_UP, down, SystemClock.uptimeMillis(), x, y)
                main.postDelayed(done, 60)
            }, 60)
        }

        fun picture(quality: Int): String {
            val w = width.coerceAtLeast(1)
            val h = height.coerceAtLeast(1)
            // Half size is plenty for a model and for the small card.
            val bmp = Bitmap.createBitmap(w / 2 + 1, h / 2 + 1, Bitmap.Config.RGB_565)
            val canvas = Canvas(bmp)
            canvas.scale(0.5f, 0.5f)
            draw(canvas)
            val out = ByteArrayOutputStream()
            bmp.compress(Bitmap.CompressFormat.JPEG, quality.coerceIn(30, 95), out)
            bmp.recycle()
            return Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
        }
    }
}
