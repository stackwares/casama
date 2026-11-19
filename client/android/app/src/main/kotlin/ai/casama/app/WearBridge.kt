package ai.casama.app

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Node
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

/**
 * The phone side of the Wear OS link (D-410, docs/WATCH-PROTOCOL.md §2 and §3).
 *
 * A watch asks to be signed in with a `sign_in` message on `/casama/watch`. The request is held in
 * SharedPreferences (Flutter may not be running) and passed to Dart live on the `casama/watch`
 * channel when it is. Dart signs the watch in with the server (registering its fingerprint, never
 * seeing its key) and answers; the answer goes back to the watch that asked. Dart also tells
 * watches about a workspace switch (`context`) and sign-out (`sign_out`).
 *
 * At most one request is held per watch key (a watch that asks again replaces its earlier
 * request), each for fifteen minutes. Dart reads them without taking them; a request leaves when
 * it is answered, so one the app was killed before answering is still there next time.
 *
 * "Open on phone" from the watch opens the link when the app is on screen; otherwise it leaves a
 * notification that does (Android doesn't let a background service start an activity).
 */
object WearBridge {
    const val PATH = "/casama/watch"
    private const val WATCH_CAPABILITY = "casama_watch"
    private const val PREFS = "casama_wear_bridge"
    private const val K_REQUESTS = "requests"
    private const val K_NODES = "nodes"
    /** The watch node a request came from, kept beside it so the answer goes back there. */
    private const val NODE = "_node"
    private const val MAX_HELD = 10
    /** When a held request arrived (epoch milliseconds). */
    private const val AT = "at"
    private const val HELD_FOR_MS = 15 * 60 * 1000L
    /** The tag of "from your watch" notifications; the id is the link's hash. */
    private const val OPEN_TAG = "watch-open"
    private const val TAG = "WearBridge"

    private val main = Handler(Looper.getMainLooper())

    @Volatile
    var channel: MethodChannel? = null

    fun attach(channel: MethodChannel, context: Context) {
        this.channel = channel
        val app = context.applicationContext
        channel.setMethodCallHandler { call, result -> handle(app, call, result) }
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    // --- from the watch ------------------------------------------------------------------------

    fun onMessage(context: Context, sourceNode: String, data: ByteArray) {
        val msg = try {
            JSONObject(String(data, Charsets.UTF_8))
        } catch (_: Exception) {
            return
        }
        when (msg.optString("type")) {
            "sign_in" -> {
                val requestId = msg.optString("request_id")
                val fingerprint = msg.optString("fingerprint")
                if (requestId.isBlank() || fingerprint.isBlank()) return
                val request = JSONObject()
                    .put("request_id", requestId)
                    .put("platform", msg.optString("platform").ifBlank { "wearos" })
                    .put("fingerprint", fingerprint)
                    .put("name", msg.optString("name").ifBlank { "Wear OS" })
                    .put(AT, System.currentTimeMillis())
                for (k in listOf("model", "app_version", "os_version")) {
                    msg.optString(k).takeIf { it.isNotBlank() }?.let { request.put(k, it) }
                }
                hold(context, JSONObject(request.toString()).put(NODE, sourceNode))
                // Live too, when Flutter is up; Dart drops a request it already has.
                main.post { channel?.invokeMethod("request", toMap(request)) }
            }
            "open" -> {
                // App routes only ("/approvals/…"), never "//host".
                val asked = msg.optString("link").takeIf { it.startsWith("/") && !it.startsWith("//") } ?: return
                // A bare "/" (an older watch app, for a push that had no link) isn't a screen in
                // the app: its first screen instead.
                val link = if (asked == "/") "/bots" else asked
                val title = msg.optString("title").trim().take(100)
                main.post {
                    val ch = channel
                    if (ch != null && PushNotifications.foreground) {
                        // On screen: go there now.
                        ch.invokeMethod("open", mapOf("link" to link))
                    } else {
                        // In the background or not running. A service may not start an activity
                        // from there (Android 10+), so the link waits in a notification.
                        notifyOpen(context, link, title)
                    }
                }
            }
        }
    }

    /** "From your watch": a notification that opens [link] in the app when tapped. */
    private fun notifyOpen(context: Context, link: String, title: String) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        PushNotifications.ensureChannels(context)
        // The app's router reads casama://app/<route>, as for any link into the app.
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("casama://app$link"))
            .setClass(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val id = link.hashCode()
        val open = PendingIntent.getActivity(context, id, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = Notification.Builder(context, PushNotifications.NEEDS_YOU)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title.ifBlank { context.applicationInfo.loadLabel(context.packageManager).toString() })
            .setContentText("From your watch")
            .setCategory(Notification.CATEGORY_REMINDER)
            .setAutoCancel(true)
            // Only for this phone: the watch that asked doesn't need it bridged back.
            .setLocalOnly(true)
            .setContentIntent(open)
            .build()
        try {
            manager.notify(OPEN_TAG, id, notification)
        } catch (e: SecurityException) {
            // Notifications are off for the app: nothing to show; the watch said "Sent to phone".
            Log.w(TAG, "couldn't post the link from the watch: ${e.message}")
        }
    }

    // --- held requests -------------------------------------------------------------------------

    private fun held(context: Context): JSONArray = try {
        JSONArray(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(K_REQUESTS, "[]"))
    } catch (_: Exception) {
        JSONArray()
    }

    private fun save(context: Context, list: List<JSONObject>) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(K_REQUESTS, JSONArray(list.takeLast(MAX_HELD)).toString())
            .apply()
    }

    /**
     * The held requests that are still fresh. One older than fifteen minutes is dropped (the
     * watch asks again when it is opened); one from an older app, with no time, is given now.
     * Saved back when that changed anything.
     */
    @Synchronized
    private fun fresh(context: Context): List<JSONObject> {
        val now = System.currentTimeMillis()
        val all = items(held(context))
        var changed = false
        val kept = all.filter { r ->
            if (!r.has(AT)) {
                r.put(AT, now)
                changed = true
            }
            val at = r.optLong(AT, now)
            // A clock set back makes a request look like it is from the future: drop those too.
            at in (now - HELD_FOR_MS)..(now + 60_000)
        }
        if (changed || kept.size != all.size) save(context, kept)
        return kept
    }

    @Synchronized
    private fun hold(context: Context, request: JSONObject) {
        val id = request.optString("request_id")
        val fingerprint = request.optString("fingerprint")
        // One request per watch key: a watch that asks again replaces its earlier request.
        save(context, fresh(context).filter { it.optString("request_id") != id && it.optString("fingerprint") != fingerprint } + request)
        val nodes = nodes(context)
        nodes.put(id, request.optString(NODE))
        // Keep the last few only.
        while (nodes.length() > MAX_HELD) nodes.remove(nodes.keys().next())
        saveNodes(context, nodes)
    }

    /**
     * The node a request came from, and forgets it. The request leaves the held list, and so
     * does any other request from the same watch key (it has its answer now): [answeredFor] is
     * the fingerprint Dart answered for, else the held request's own.
     */
    @Synchronized
    private fun takeNode(context: Context, requestId: String, answeredFor: String?): String? {
        val all = fresh(context)
        val fingerprint = answeredFor?.takeIf { it.isNotBlank() }
            ?: all.firstOrNull { it.optString("request_id") == requestId }?.optString("fingerprint").orEmpty()
        save(context, all.filter { it.optString("request_id") != requestId && (fingerprint.isEmpty() || it.optString("fingerprint") != fingerprint) })
        val nodes = nodes(context)
        val node = nodes.optString(requestId).takeIf { it.isNotBlank() }
        nodes.remove(requestId)
        saveNodes(context, nodes)
        return node
    }

    private fun nodes(context: Context): JSONObject = try {
        JSONObject(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(K_NODES, "{}") ?: "{}")
    } catch (_: Exception) {
        JSONObject()
    }

    private fun saveNodes(context: Context, nodes: JSONObject) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(K_NODES, nodes.toString()).apply()
    }

    private fun items(a: JSONArray): List<JSONObject> = (0 until a.length()).mapNotNull { a.optJSONObject(it) }

    // --- from Dart -----------------------------------------------------------------------------

    private fun handle(context: Context, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "takeRequests" -> {
                // Read, not taken (§3): a request leaves when it is answered, so one the app was
                // closed before answering is handed over again. Dart skips ids it has seen.
                result.success(fresh(context).map { r -> toMap(JSONObject(r.toString()).apply { remove(NODE) }) })
            }
            "answer" -> {
                val requestId = call.argument<String>("request_id")
                if (requestId.isNullOrBlank()) {
                    result.error("bad_args", "request_id is required", null)
                    return
                }
                val ok = call.argument<Boolean>("ok") == true
                val msg = JSONObject().put("request_id", requestId)
                if (ok) {
                    msg.put("type", "signed_in")
                    for (k in listOf("server", "org_id", "org_name", "person_name")) msg.put(k, call.argument<String>(k).orEmpty())
                } else {
                    msg.put("type", "sign_in_failed")
                    val reason = call.argument<String>("reason")
                    msg.put("reason", if (reason in setOf("signed_out", "declined", "error")) reason else "error")
                }
                val node = takeNode(context, requestId, call.argument<String>("fingerprint"))
                send(context, msg, node)
                result.success(null)
            }
            "setContext" -> {
                val msg = JSONObject().put("type", "context")
                for (k in listOf("server", "org_id", "org_name", "person_name")) msg.put(k, call.argument<String>(k).orEmpty())
                send(context, msg, null)
                result.success(null)
            }
            "signOut" -> {
                save(context, emptyList())
                saveNodes(context, JSONObject())
                send(context, JSONObject().put("type", "sign_out"), null)
                result.success(null)
            }
            "status" -> status(context, result)
            else -> result.notImplemented()
        }
    }

    /** `{supported, paired, installed}`: Play services' Wearable API, a watch, our app on it. */
    private fun status(context: Context, result: MethodChannel.Result) {
        val supported = GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context) == ConnectionResult.SUCCESS
        if (!supported) {
            result.success(mapOf("supported" to false, "paired" to false, "installed" to false))
            return
        }
        val nodes = Wearable.getNodeClient(context).connectedNodes
        nodes.addOnCompleteListener { t ->
            val paired = t.isSuccessful && t.result.orEmpty().isNotEmpty()
            Wearable.getCapabilityClient(context)
                .getCapability(WATCH_CAPABILITY, CapabilityClient.FILTER_ALL)
                .addOnCompleteListener { c ->
                    val installed = c.isSuccessful && c.result?.nodes.orEmpty().isNotEmpty()
                    main.post { result.success(mapOf("supported" to true, "paired" to (paired || installed), "installed" to installed)) }
                }
        }
    }

    /** To [node] when known (the watch that asked), else to every reachable watch with our app. */
    private fun send(context: Context, msg: JSONObject, node: String?) {
        val bytes = msg.toString().toByteArray(Charsets.UTF_8)
        val messages = Wearable.getMessageClient(context)
        if (node != null) {
            messages.sendMessage(node, PATH, bytes).addOnFailureListener { e ->
                Log.w(TAG, "send to the asking watch failed (${e.message}); trying every watch")
                sendAll(context, bytes)
            }
        } else {
            sendAll(context, bytes)
        }
    }

    private fun sendAll(context: Context, bytes: ByteArray) {
        Wearable.getCapabilityClient(context)
            .getCapability(WATCH_CAPABILITY, CapabilityClient.FILTER_REACHABLE)
            .addOnSuccessListener { info ->
                info.nodes.forEach { n: Node -> Wearable.getMessageClient(context).sendMessage(n.id, PATH, bytes) }
            }
            .addOnFailureListener { e -> Log.w(TAG, "no watch to send to: ${e.message}") }
    }

    private fun toMap(o: JSONObject): Map<String, Any?> =
        o.keys().asSequence().associateWith { k -> o.opt(k).takeUnless { it == JSONObject.NULL } }
}

/** Receives the watch's messages on `/casama/watch`, even with the app closed. */
class WearBridgeService : WearableListenerService() {
    override fun onMessageReceived(event: MessageEvent) {
        if (event.path != WearBridge.PATH) return
        WearBridge.onMessage(applicationContext, event.sourceNodeId, event.data)
    }
}
