package ai.casama.wear.surfaces

import ai.casama.wear.complications.AskComplication
import ai.casama.wear.complications.CreditsComplication
import ai.casama.wear.complications.NeedsYouComplication
import ai.casama.wear.tiles.AskTileService
import ai.casama.wear.tiles.BotTileService
import ai.casama.wear.tiles.NeedsYouTileService
import ai.casama.wear.tiles.UpNextTileService
import android.content.ComponentName
import android.content.Context
import androidx.wear.tiles.TileService
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceUpdateRequester

/** Tells every tile and complication to redraw from the saved glance (it changed, or sign-in did). */
object Surfaces {
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
