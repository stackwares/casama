package ai.casama.wear.notify

import ai.casama.wear.BuildConfig
import ai.casama.wear.R
import ai.casama.wear.core.Logic
import ai.casama.wear.core.WatchPush
import ai.casama.wear.data.ApiError
import ai.casama.wear.graph
import ai.casama.wear.live.OngoingRun
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationManagerCompat
import androidx.wear.phone.interactions.notifications.BridgingConfig
import androidx.wear.phone.interactions.notifications.BridgingManager
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withTimeoutOrNull

/**
 * Data-only pushes sent to this watch's own Firebase token (WATCH-PROTOCOL §4). Firebase runs
 * [onMessageReceived] on a background thread and keeps the process for it, so the short loads
 * below (the words a private push left out) block that thread, never the main one.
 */
class WearMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) {
        val graph = applicationContext.graph
        val session = graph.session
        if (!session.isSignedIn) return
        val push = WatchPush.parse(message.data) ?: return
        runBlocking {
            withTimeoutOrNull(8_000) { handle(applicationContext, push) }
        }
    }

    private suspend fun handle(context: Context, push: WatchPush) {
        val graph = context.graph
        val session = graph.session
        // Notifications may have been turned off (or on) since the app was last open.
        PushSetup.syncBridging(context)
        // A "glance" push is only a nudge for tiles and complications.
        if (push.kind == WatchPush.Kind.GLANCE) {
            session.refresh()
            return
        }

        val elsewhere = Logic.elsewhere(push.orgId, graph.settings.orgId)
        when (push.kind) {
            WatchPush.Kind.APPROVAL -> graph.haptics.needsYou()
            WatchPush.Kind.REPLY -> {
                push.runId?.let { OngoingRun.end(context, it) }
                graph.haptics.done()
            }
            WatchPush.Kind.FAILED -> {
                push.runId?.let { OngoingRun.end(context, it) }
                graph.haptics.problem()
            }
            else -> Unit
        }
        // What is on the wrist for this push now, so a later look only redraws when it would differ.
        var shown: Pair<String, String>? = null
        fun draw(title: String?, body: String?, quiet: Boolean) {
            val words = PushWords.of(context, push, title, body)
            if (quiet && words == shown) return
            shown = words
            // Quiet: only over the first drawing while it is still there (Notifier.draw), never
            // bringing back one the person already answered or swiped away.
            Notifier.draw(
                context,
                push,
                title = words.first,
                body = words.second,
                allow = session.self.value?.prefs?.allow,
                quickReplies = PushSetup.quickReplies(context),
                elsewhere = elsewhere,
                quiet = quiet,
            )
        }
        // Drawn first, from what the push itself says and the settings saved here: on a slow link
        // the calls below can take longer than this service is given, and nothing else would show
        // it (bridging is off).
        draw(push.title, push.body, quiet = false)

        // What this watch may show can have changed on the phone since its app was last open (Show
        // details, Hide reply text). Ask, and take back words that shouldn't be there any more.
        session.refreshSelf()
        if (!session.isSignedIn) return
        draw(push.title, push.body, quiet = true)

        // Tiles and complications follow every push; the glance also says when it is private.
        session.refresh()
        if (!session.isSignedIn) return
        draw(push.title, push.body, quiet = true)

        // Private notifications leave the words out: load them with the watch's own key, unless
        // details are off here or the push is about another workspace (the key can't read it).
        if (!PushWords.showDetails(context) || elsewhere) return
        when (push.kind) {
            WatchPush.Kind.APPROVAL -> if (push.title == null) {
                runCatching { session.call { approval(push.approvalId!!) } }.getOrNull()?.let { a ->
                    draw(context.getString(R.string.watch_needs_ok_from, a.bot), a.title, quiet = true)
                }
            }
            WatchPush.Kind.REPLY, WatchPush.Kind.FAILED -> if (push.body == null && session.self.value?.hideReplyText != true && push.botId != null) {
                runCatching { session.call { chat(push.botId, push.conversationId) } }.getOrNull()?.let { (chat, raw) ->
                    session.cache.saveChat(push.botId, raw)
                    chat.messages.lastOrNull { !it.fromUser }?.text?.takeIf { it.isNotBlank() }?.let { draw(push.title, it, quiet = true) }
                }
            }
            else -> Unit
        }
    }

    // FCM 26 deprecates the token calls for register()/onRegistered; both paths hand over the same
    // token, so the watch listens to both and keeps using getToken() until the old one goes.
    @Deprecated("FCM 26: onRegistered")
    override fun onNewToken(token: String) = tokenChanged(token)

    override fun onRegistered(token: String) = tokenChanged(token)

    private fun tokenChanged(token: String) {
        val graph = applicationContext.graph
        if (!graph.session.isSignedIn || graph.settings.registeredPushToken == token) return
        runBlocking { withTimeoutOrNull(8_000) { PushSetup.send(applicationContext, token) } }
    }
}

/**
 * The words a push is drawn with, without the network. With details off on this watch (Settings →
 * Watch on the phone) or a private glance (app lock), never the push's own words: the bot's name
 * and general words from the app's strings (WATCH-PLAN §10). "Hide reply text" hides a reply's.
 */
internal object PushWords {
    fun showDetails(context: Context): Boolean {
        val graph = context.graph
        return graph.session.self.value?.prefs?.showDetails != false && graph.cache.glance()?.glance?.private != true
    }

    /** (title, body) for [push]; [title] and [body] are the push's own or ones the watch loaded. */
    fun of(context: Context, push: WatchPush, title: String? = push.title, body: String? = push.body): Pair<String, String> {
        val show = showDetails(context)
        val reply = push.kind == WatchPush.Kind.REPLY || push.kind == WatchPush.Kind.FAILED
        val hideReply = reply && context.graph.session.self.value?.hideReplyText == true
        val t = title?.takeIf { show && it.isNotBlank() }
        val b = body?.takeIf { show && !hideReply && it.isNotBlank() }
        val bot = push.botName.orEmpty()
        return when (push.kind) {
            WatchPush.Kind.APPROVAL -> (t ?: context.getString(R.string.watch_needs_ok_from, bot)) to b.orEmpty()
            WatchPush.Kind.SUGGESTION -> (t ?: context.getString(R.string.watch_suggests, bot)) to b.orEmpty()
            WatchPush.Kind.REPLY ->
                if (t != null) t to b.orEmpty()
                else if (push.botName != null) push.botName to (b ?: context.getString(R.string.watch_reply_ready))
                else context.getString(R.string.watch_reply_ready) to b.orEmpty()
            WatchPush.Kind.FAILED -> (t ?: context.getString(R.string.watch_couldnt_finish)) to b.orEmpty()
            WatchPush.Kind.BRIEF -> (t ?: context.getString(R.string.watch_brief)) to b.orEmpty()
            WatchPush.Kind.TAKEOVER -> (t ?: context.getString(R.string.watch_take_over)) to b.orEmpty()
            else -> (t ?: context.getString(R.string.watch_comp_casama)) to b.orEmpty()
        }
    }
}

/**
 * Firebase on the watch: set up from the build's values (client/config/firebase.json), a token
 * only once signed in, registered with PUT /v1/watch-keys/current. Once the server has the
 * watch's own token, the phone's copies of Casama's notifications stop being bridged (WATCH-
 * PROTOCOL §4), so nothing shows twice; signing out turns bridging back on.
 */
object PushSetup {
    val configured: Boolean
        get() = BuildConfig.FIREBASE_PROJECT_ID.isNotBlank() && BuildConfig.FIREBASE_APP_ID.isNotBlank() &&
            BuildConfig.FIREBASE_API_KEY.isNotBlank() && BuildConfig.FIREBASE_SENDER_ID.isNotBlank()

    fun initFirebase(context: Context) {
        if (!configured || FirebaseApp.getApps(context).isNotEmpty()) return
        runCatching {
            FirebaseApp.initializeApp(
                context,
                FirebaseOptions.Builder()
                    .setProjectId(BuildConfig.FIREBASE_PROJECT_ID)
                    .setApplicationId(BuildConfig.FIREBASE_APP_ID)
                    .setApiKey(BuildConfig.FIREBASE_API_KEY)
                    .setGcmSenderId(BuildConfig.FIREBASE_SENDER_ID)
                    .build(),
            )
        }
    }

    /** Signed in: make a token and give it to the server. */
    @Suppress("DEPRECATION")
    suspend fun register(context: Context) {
        if (!configured) return
        val messaging = runCatching { FirebaseMessaging.getInstance() }.getOrNull() ?: return
        messaging.isAutoInitEnabled = true
        val token = runCatching { messaging.token.await() }.getOrNull() ?: return
        send(context, token)
    }

    suspend fun send(context: Context, token: String) {
        val graph = context.graph
        try {
            graph.session.call { updateSelf(token, BuildConfig.VERSION_NAME, Build.VERSION.RELEASE) }
            graph.settings.registeredPushToken = token
            syncBridging(context)
        } catch (_: ApiError) {
            // Offline: the next sign-in or app start tries again; bridging stays on meanwhile.
        }
    }

    /** Signed out: forget the token here (the server's went with the key) and bridge again. */
    @Suppress("DEPRECATION")
    suspend fun unregister(context: Context) {
        context.graph.settings.registeredPushToken = null
        bridgingOff = null
        syncBridging(context)
        if (!configured) return
        runCatching {
            val messaging = FirebaseMessaging.getInstance()
            messaging.isAutoInitEnabled = false
            messaging.deleteToken().await()
        }
    }

    /** Re-sends the token at app start when the server may not have it yet. */
    suspend fun ensureRegistered(context: Context) {
        if (context.graph.settings.registeredPushToken == null) register(context)
    }

    /** What was last asked of the system in this process; null until the first time. */
    @Volatile private var bridgingOff: Boolean? = null

    /**
     * The phone's copies of Casama's notifications stop being bridged only while this watch draws
     * its own: the server has its token AND notifications are allowed here. In every other case
     * they are bridged, so an alert still reaches the wrist. Checked whenever that can have
     * changed: a token registered, sign-out, the app coming forward, a push arriving.
     */
    fun syncBridging(context: Context) {
        val off = context.graph.settings.registeredPushToken != null &&
            NotificationManagerCompat.from(context).areNotificationsEnabled()
        if (bridgingOff == off) return
        bridgingOff = off
        setBridging(context, on = !off)
    }

    private fun setBridging(context: Context, on: Boolean) {
        runCatching { BridgingManager.fromContext(context).setConfig(BridgingConfig.Builder(context, on).build()) }
    }

    /** The person's quick replies (GET /v1/watch/me), else the built-in four (§6.2). */
    fun quickReplies(context: Context): List<String> =
        context.graph.session.self.value?.prefs?.quickReplies?.takeIf { it.isNotEmpty() }
            ?: listOf(
                context.getString(R.string.watch_quick_yes),
                context.getString(R.string.watch_quick_no),
                context.getString(R.string.watch_quick_tell_more),
                context.getString(R.string.watch_quick_not_now),
            )
}
