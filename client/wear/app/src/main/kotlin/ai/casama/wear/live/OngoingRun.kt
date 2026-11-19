package ai.casama.wear.live

import ai.casama.wear.R
import ai.casama.wear.art.BotArt
import ai.casama.wear.core.Glance
import ai.casama.wear.core.RunPhase
import ai.casama.wear.core.WatchRun
import ai.casama.wear.notify.Notifier
import ai.casama.wear.ui.Routes
import android.content.Context
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.edit
import androidx.wear.ongoing.OngoingActivity
import androidx.wear.ongoing.Status

/**
 * A run started from the watch, on the watch face (§6.5): an Ongoing Activity on Wear OS 3 to 6
 * (an icon on the face and a line in the app list), and a Live Update on Wear OS 7 where the
 * system promotes it. The bot's face, its step and a running clock; cleared when the run ends, at
 * once when the person stopped it. The clock is the system's chronometer, so it keeps time with
 * the app closed and nothing polls.
 */
object OngoingRun {
    private const val PREFS = "casama_ongoing"
    /** Ten minutes without news and it goes by itself: a run that long ends with a push anyway. */
    private const val TIMEOUT_MS = 10 * 60 * 1000L

    private fun nid(runId: String) = ("run:$runId").hashCode()

    /** Runs the person started on this watch (Ask, Run Now, Do It): only these get a live surface. */
    private val startedHere = java.util.Collections.synchronizedSet(mutableSetOf<String>())

    fun startedOnWatch(runId: String) {
        startedHere += runId
    }

    /** True for a run started here, or one already showing (after the app restarted). */
    fun follows(context: Context, runId: String): Boolean =
        runId in startedHere ||
            runId in context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getStringSet("runs", emptySet()).orEmpty()

    /** Starts or updates the live surface for [run]. Ended runs clear it. */
    fun show(context: Context, run: WatchRun) {
        if (!run.phase.live) {
            end(context, run.id)
            return
        }
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs.edit { putStringSet("runs", (prefs.getStringSet("runs", emptySet()).orEmpty() + run.id)) }
        val title = context.getString(R.string.watch_is_working, run.bot)
        val step = when (run.phase) {
            RunPhase.NEEDS_OK -> context.getString(R.string.watch_needs_ok)
            RunPhase.TAKE_OVER -> context.getString(R.string.watch_take_over)
            else -> run.step
        }
        val touch = Routes.pending(context, Routes.working(run.id))
        val builder = NotificationCompat.Builder(context, Notifier.CH_WORKING)
            .setSmallIcon(R.drawable.ic_notification)
            .setLargeIcon(BotArt.bitmap(context, run.bot, run.botAvatar, 96))
            .setContentTitle(title)
            .setContentText(step)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setContentIntent(touch)
            .setTimeoutAfter(TIMEOUT_MS)
            // Wear OS 7 Live Updates: ongoing, started by the person, time-sensitive (§2.2).
            .setRequestPromotedOngoing(true)
            .setShortCriticalText(run.bot)
        run.startedAt?.let { builder.setWhen(it).setUsesChronometer(true).setShowWhen(true) }
        val status = Status.Builder()
            .addTemplate("#bot# · #clock#")
            .addTemplate("#bot# · #step#")
            .addPart("bot", Status.TextPart(run.bot))
            .addPart("step", Status.TextPart(step))
            .apply {
                // Stopwatch parts count from a time on the elapsed-since-boot clock.
                run.startedAt?.let { addPart("clock", Status.StopwatchPart(SystemClock.elapsedRealtime() - (System.currentTimeMillis() - it))) }
            }
            .build()
        OngoingActivity.Builder(context, nid(run.id), builder)
            .setStaticIcon(R.drawable.ic_notification)
            .setTouchIntent(touch)
            .setStatus(status)
            .setTitle(title)
            .setContentDescription("$title. $step")
            .build()
            .apply(context)
        try {
            NotificationManagerCompat.from(context).notify(nid(run.id), builder.build())
        } catch (_: SecurityException) {
            // Notifications are off: the app's Working screen still shows it.
        }
    }

    fun end(context: Context, runId: String) {
        NotificationManagerCompat.from(context).cancel(nid(runId))
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs.edit { putStringSet("runs", prefs.getStringSet("runs", emptySet()).orEmpty() - runId) }
    }

    /** A glance that no longer lists a run means it ended: clear its surface. */
    fun reconcile(context: Context, glance: Glance) {
        val live = glance.runs.map { it.id }.toSet()
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs.getStringSet("runs", emptySet()).orEmpty().filter { it !in live }.forEach { end(context, it) }
    }

    fun clearAll(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs.getStringSet("runs", emptySet()).orEmpty().forEach { NotificationManagerCompat.from(context).cancel(nid(it)) }
        prefs.edit { clear() }
    }
}
