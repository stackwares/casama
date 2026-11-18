package ai.casama.wear.complications

import ai.casama.wear.R
import ai.casama.wear.core.Format
import ai.casama.wear.core.Glance
import ai.casama.wear.core.Logic
import ai.casama.wear.graph
import ai.casama.wear.ui.Routes
import android.app.PendingIntent
import android.graphics.drawable.Icon
import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.LongTextComplicationData
import androidx.wear.watchface.complications.data.MonochromaticImage
import androidx.wear.watchface.complications.data.NoDataComplicationData
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.RangedValueComplicationData
import androidx.wear.watchface.complications.data.ShortTextComplicationData
import androidx.wear.watchface.complications.data.SmallImage
import androidx.wear.watchface.complications.data.SmallImageComplicationData
import androidx.wear.watchface.complications.data.SmallImageType
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingComplicationDataSourceService

private fun plain(text: String) = PlainComplicationText.Builder(text).build()

/** Shared by the three: read the saved glance, never wait on the network (§6.3). */
abstract class CasamaComplication : SuspendingComplicationDataSourceService() {
    protected fun glance(): Pair<Glance?, Boolean> {
        val graph = applicationContext.graph
        if (!graph.session.isSignedIn) return null to false
        val saved = graph.cache.glance()
        return saved?.glance to Format.isStale(saved?.savedAt, System.currentTimeMillis())
    }

    protected fun tap(route: String): PendingIntent = Routes.pending(applicationContext, route)

    protected fun mono(res: Int) = MonochromaticImage.Builder(Icon.createWithResource(applicationContext, res)).build()
}

/**
 * Needs you: SHORT_TEXT is the count (a tick at zero), LONG_TEXT the first request. An old glance
 * never claims "now": the count shows without the tick, and the long text says Casama.
 */
class NeedsYouComplication : CasamaComplication() {
    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationData? {
        val (g, stale) = glance()
        if (g == null) return signedOut(request.complicationType)
        val count = g.needsCount
        val first = Logic.firstNeed(g)
        val desc = if (count == 0) getString(R.string.watch_all_clear) else if (count == 1) getString(R.string.watch_needs_you_one) else getString(R.string.watch_needs_you_many, count.toString())
        val route = if (count == 0) Routes.NOW else Routes.NEEDS
        return when (request.complicationType) {
            ComplicationType.SHORT_TEXT -> ShortTextComplicationData.Builder(
                plain(if (count == 0) (if (stale) "–" else "✓") else count.toString()),
                plain(desc),
            )
                .setTitle(plain(getString(R.string.watch_need_you_short)))
                .setMonochromaticImage(mono(R.drawable.ic_notification))
                .setTapAction(tap(route))
                .build()
            ComplicationType.LONG_TEXT -> {
                val words = when {
                    first == null -> getString(R.string.watch_all_clear)
                    g.private || applicationContext.graph.session.self.value?.prefs?.showDetails == false -> "${first.bot}: ${getString(R.string.watch_needs_ok)}"
                    else -> "${first.bot}: ${first.text}"
                }
                LongTextComplicationData.Builder(plain(if (stale && first == null) getString(R.string.watch_comp_casama) else words), plain(desc))
                    .setTitle(plain(desc))
                    .setMonochromaticImage(mono(R.drawable.ic_notification))
                    .setTapAction(tap(route))
                    .build()
            }
            else -> NoDataComplicationData()
        }
    }

    private fun signedOut(type: ComplicationType): ComplicationData = when (type) {
        ComplicationType.SHORT_TEXT -> ShortTextComplicationData.Builder(plain("–"), plain(getString(R.string.watch_open_to_sign_in)))
            .setMonochromaticImage(mono(R.drawable.ic_notification))
            .setTapAction(tap(Routes.NOW))
            .build()
        ComplicationType.LONG_TEXT -> LongTextComplicationData.Builder(plain(getString(R.string.watch_open_to_sign_in)), plain(getString(R.string.watch_open_to_sign_in)))
            .setTapAction(tap(Routes.NOW))
            .build()
        else -> NoDataComplicationData()
    }

    override fun getPreviewData(type: ComplicationType): ComplicationData? = when (type) {
        ComplicationType.SHORT_TEXT -> ShortTextComplicationData.Builder(plain("2"), plain(getString(R.string.watch_needs_you_many, "2")))
            .setTitle(plain(getString(R.string.watch_need_you_short)))
            .setMonochromaticImage(mono(R.drawable.ic_notification))
            .build()
        ComplicationType.LONG_TEXT -> LongTextComplicationData.Builder(plain(getString(R.string.watch_needs_ok)), plain(getString(R.string.watch_comp_desc_needs_you)))
            .setTitle(plain(getString(R.string.watch_needs_you)))
            .build()
        else -> null
    }
}

/** Credits: how much of this period is used, as a ring. Unlimited or no billing: no data. */
class CreditsComplication : CasamaComplication() {
    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationData? {
        val (g, _) = glance()
        val credits = g?.credits ?: return NoDataComplicationData()
        val used = credits.usedShare
        if (!credits.billing || credits.unlimited || used == null || request.complicationType != ComplicationType.RANGED_VALUE) return NoDataComplicationData()
        val pct = Format.percent(used) ?: 0
        return RangedValueComplicationData.Builder(pct.toFloat(), 0f, 100f, plain("${getString(R.string.watch_credits)} $pct%"))
            .setText(plain("$pct%"))
            .setTitle(plain(getString(R.string.watch_credits)))
            .setTapAction(tap(Routes.SETTINGS))
            .build()
    }

    override fun getPreviewData(type: ComplicationType): ComplicationData? =
        if (type == ComplicationType.RANGED_VALUE) {
            RangedValueComplicationData.Builder(40f, 0f, 100f, plain(getString(R.string.watch_comp_desc_credits)))
                .setText(plain("40%"))
                .setTitle(plain(getString(R.string.watch_credits)))
                .build()
        } else {
            null
        }
}

/** Ask: the mic, one tap opens the app already listening. */
class AskComplication : CasamaComplication() {
    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationData? {
        if (request.complicationType != ComplicationType.SMALL_IMAGE) return NoDataComplicationData()
        val signedIn = applicationContext.graph.session.isSignedIn
        return image(if (signedIn) tap(Routes.ask(null, listen = true)) else tap(Routes.NOW))
    }

    private fun image(tap: PendingIntent?): ComplicationData {
        val icon = Icon.createWithResource(applicationContext, R.drawable.ic_mic)
        return SmallImageComplicationData.Builder(SmallImage.Builder(icon, SmallImageType.ICON).build(), plain(getString(R.string.watch_comp_desc_ask)))
            .apply { if (tap != null) setTapAction(tap) }
            .build()
    }

    override fun getPreviewData(type: ComplicationType): ComplicationData? =
        if (type == ComplicationType.SMALL_IMAGE) image(null) else null
}
