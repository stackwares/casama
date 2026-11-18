package ai.casama.app

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
                for (k in listOf("model", "app_version", "os_version")) {
                    msg.optString(k).takeIf { it.isNotBlank() }?.let { request.put(k, it) }
                }
                hold(context, JSONObject(request.toString()).put(NODE, sourceNode))
                // Live too, when Flutter is up; Dart drops a request it already has.
                main.post { channel?.invokeMethod("request", toMap(request)) }
            }
            "open" -> {
                val link = msg.optString("link").takeIf { it.startsWith("/") } ?: return
                main.post {
                    val ch = channel
                    if (ch != null) {
                        bringToFront(context, null)
                        ch.invokeMethod("open", mapOf("link" to link))
                    } else {
                        // The app isn't running: open it at the link (its router reads casama://app/...).
                        bringToFront(context, Uri.parse("casama://app$link"))
                    }
                }
            }
        }
    }

    private fun bringToFront(context: Context, data: Uri?) {
        val intent = (if (data != null) Intent(Intent.ACTION_VIEW, data) else Intent(Intent.ACTION_MAIN))
            .setClass(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
        try {
            context.startActivity(intent)
        } catch (e: Exception) {
            // Android 10+ may refuse a background start; the watch already showed "Sent to phone".
            Log.w(TAG, "couldn't open the app: ${e.message}")
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

    @Synchronized
    private fun hold(context: Context, request: JSONObject) {
        val id = request.optString("request_id")
        save(context, items(held(context)).filter { it.optString("request_id") != id } + request)
        val nodes = nodes(context)
        nodes.put(id, request.optString(NODE))
        // Keep the last few only.
        while (nodes.length() > MAX_HELD) nodes.remove(nodes.keys().next())
        saveNodes(context, nodes)
    }

    /** The node a request came from, and forgets it (also dropping the request if still held). */
    @Synchronized
    private fun takeNode(context: Context, requestId: String): String? {
        save(context, items(held(context)).filter { it.optString("request_id") != requestId })
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
                // Handed over and cleared (§3); the node each came from stays until it's answered.
                val list = synchronized(this) { items(held(context)).also { save(context, emptyList()) } }
                result.success(list.map { r -> toMap(JSONObject(r.toString()).apply { remove(NODE) }) })
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
                val node = takeNode(context, requestId)
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
