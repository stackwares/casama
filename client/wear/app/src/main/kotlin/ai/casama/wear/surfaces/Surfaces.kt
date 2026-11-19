package ai.casama.wear.surfaces

import ai.casama.wear.complications.AskComplication
import ai.casama.wear.complications.CreditsComplication
import ai.casama.wear.complications.NeedsYouComplication
import ai.casama.wear.core.Format
import ai.casama.wear.graph
import ai.casama.wear.tiles.AskTileService
import ai.casama.wear.tiles.BotTileService
import ai.casama.wear.tiles.NeedsYouTileService
import ai.casama.wear.tiles.UpNextTileService
import android.content.ComponentName
import android.content.Context
import androidx.wear.tiles.TileService
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceUpdateRequester
import kotlinx.coroutines.launch

/** Tells every tile and complication to redraw from the saved glance (it changed, or sign-in did). */
object Surfaces {
    @Volatile private var lastStaleRefresh = 0L

    /**
     * A face asked for data and the saved glance is old: fetch it in the background (at most once
     * a minute) and redraw when that made it fresh, so a count answered on the phone doesn't stay.
     */
    fun refreshIfStale(context: Context) {
        val graph = context.graph
        val now = System.currentTimeMillis()
        if (!graph.session.isSignedIn || now - lastStaleRefresh < 60_000) return
        lastStaleRefresh = now
        graph.scope.launch {
            graph.session.refresh()
            if (!Format.isStale(graph.cache.glance()?.savedAt, System.currentTimeMillis())) update(context)
        }
    }

    fun update(context: Context) {
        val app = context.applicationContext
        runCatching {
            val updater = TileService.getUpdater(app)
            listOf(NeedsYouTileService::class.java, AskTileService::class.java, UpNextTileService::class.java, BotTileService::class.java)
                .forEach { updater.requestUpdate(it) }
        }
        listOf(NeedsYouComplication::class.java, CreditsComplication::class.java, AskComplication::class.java).forEach {
            runCatching { ComplicationDataSourceUpdateRequester.create(app, ComponentName(app, it)).requestUpdateAll() }
        }
    }
}
