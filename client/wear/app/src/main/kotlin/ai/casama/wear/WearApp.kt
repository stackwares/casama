package ai.casama.wear

import ai.casama.wear.data.AskOutbox
import ai.casama.wear.data.Device
import ai.casama.wear.data.GlanceCache
import ai.casama.wear.data.KeyStore
import ai.casama.wear.data.Session
import ai.casama.wear.data.Settings
import ai.casama.wear.data.WatchApi
import ai.casama.wear.notify.Notifier
import ai.casama.wear.notify.PushSetup
import ai.casama.wear.ui.Haptics
import android.app.Application
import android.content.Context
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/** Casama on Wear OS (D-410). One [Graph] for the app, its services, tiles and complications. */
class WearApp : Application() {
    lateinit var graph: Graph
        private set

    override fun onCreate() {
        super.onCreate()
        graph = Graph(this)
        Notifier.ensureChannels(this)
        // Firebase from client/config/firebase.json values baked in at build time (the phone app
        // does the same from --dart-define). No file: no pushes, the app still works.
        PushSetup.initFirebase(this)
        if (graph.session.isSignedIn && graph.outbox.items().isNotEmpty()) AskOutbox.schedule(this)
        // Open the sealed key once off the main thread; later calls use the cached copy.
        graph.scope.launch(Dispatchers.IO) { graph.keys.get() }
    }
}

/** The app's long-lived pieces. Cheap to make; everything heavy is lazy. */
class Graph(app: Context) {
    /** Outlives screens: sign-in, refreshes, answering from tiles and notifications. */
    val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    val settings = Settings(app)
    val keys = KeyStore(app)
    val cache = GlanceCache(app)
    val api = WatchApi(settings, keys, Device.userAgent())
    val session = Session(app, scope, settings, keys, cache, api)
    val outbox = AskOutbox(app)
    val haptics = Haptics(app)
}

val Context.graph: Graph get() = (applicationContext as WearApp).graph
