package ai.casama.wear.notify

import ai.casama.wear.BuildConfig
import ai.casama.wear.R
import ai.casama.wear.core.WatchPush
import ai.casama.wear.data.ApiError
import ai.casama.wear.graph
import ai.casama.wear.live.OngoingRun
import android.content.Context
import android.os.Build
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
        // Tiles and complications follow every push; a "glance" push is only that.
        session.refresh()
        if (push.kind == WatchPush.Kind.GLANCE) return

        val self = session.self.value
        var title = push.title
        var body = push.body
        when (push.kind) {
            WatchPush.Kind.APPROVAL -> {
                if (title == null) {
                    // Private notifications: load the request's words with the watch's own key.
                    runCatching { session.call { approval(push.approvalId!!) } }.getOrNull()?.let { a ->
                        title = context.getString(R.string.watch_needs_ok_from, a.bot)
                        body = a.title
                    }
                }
                graph.haptics.needsYou()
            }
            WatchPush.Kind.REPLY, WatchPush.Kind.FAILED -> {
                push.runId?.let { OngoingRun.end(context, it) }
                val hide = self?.hideReplyText == true
                if (body == null && !hide && push.botId != null) {
                    runCatching { session.call { chat(push.botId, push.conversationId) } }.getOrNull()?.let { (chat, raw) ->
                        session.cache.saveChat(push.botId, raw)
                        body = chat.messages.lastOrNull { !it.fromUser }?.text
                    }
                }
                if (hide) body = null
                if (push.kind == WatchPush.Kind.FAILED) {
                    title = title ?: context.getString(R.string.watch_couldnt_finish)
                    graph.haptics.problem()
                } else {
                    graph.haptics.done()
                }
            }
            else -> Unit
        }
        val fallbackTitle = when (push.kind) {
            WatchPush.Kind.APPROVAL -> context.getString(R.string.watch_needs_ok_from, push.botName.orEmpty())
            WatchPush.Kind.SUGGESTION -> context.getString(R.string.watch_suggests, push.botName.orEmpty())
            WatchPush.Kind.REPLY -> push.botName ?: context.getString(R.string.watch_reply_ready)
            WatchPush.Kind.BRIEF -> context.getString(R.string.watch_brief)
            WatchPush.Kind.TAKEOVER -> context.getString(R.string.watch_take_over)
            else -> context.getString(R.string.watch_comp_casama)
        }
        Notifier.draw(
            context,
            push,
            title = title ?: fallbackTitle,
            body = body.orEmpty(),
            allow = self?.prefs?.allow,
            quickReplies = PushSetup.quickReplies(context),
        )
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
            setBridging(context, on = false)
        } catch (_: ApiError) {
            // Offline: the next sign-in or app start tries again; bridging stays on meanwhile.
        }
    }

    /** Signed out: forget the token here (the server's went with the key) and bridge again. */
    @Suppress("DEPRECATION")
    suspend fun unregister(context: Context) {
        context.graph.settings.registeredPushToken = null
        setBridging(context, on = true)
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
