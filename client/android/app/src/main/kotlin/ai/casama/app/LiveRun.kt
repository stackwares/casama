package ai.casama.app

import android.app.Activity
import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ApplicationInfo
import android.graphics.Color
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/**
 * The island on Android (D-324, docs/ISLAND-AND-MENU-BAR-PLAN.md §6 E and §8.6): one ongoing
 * notification per run the person started, on a silent "Bots at work" channel.
 *
 * - Android 16 and later, when the phone allows it: a Live Update (a promoted ongoing notification
 *   with a status bar chip and a card on the lock screen). The platform requires the standard
 *   look, so no custom views and no colorizing.
 * - Otherwise: the system's frame with our own RemoteViews inside (collapsed and expanded).
 *
 * States come from two places: the app's feed over the casama/island channel while the app runs
 * ([apply]), and data-only FCM messages of kind "live" from the server when it doesn't
 * ([LiveRunReceiver], [fromPush]). Whichever is newer wins, and a run once shown as ended is never
 * drawn as working again. The lock screen gets a public version that says only that a bot is at
 * work. The home-screen widget shows the run that matters most, with Stop.
 */
object LiveRun {
  const val CHANNEL = "live_runs"
  const val TAG = "casama_live"
  private const val PREFS = "casama_live"
  /** How long past its stale time a pushed state stays without further word. */
  private const val SERVER_GRACE_MS = 60 * 60 * 1000L
  /** Finished stays for 15 minutes, then clears itself (decision 9). */
  const val FINISHED_FOR_MS = 15 * 60 * 1000L
  /** What's kept about a run (to order states and end it) is forgotten after a day. */
  private const val KEEP_MS = 24 * 60 * 60 * 1000L

  /** Debug builds only: draw the RemoteViews form even where a Live Update is allowed. */
  var forceCustom = false

  /** Whether Casama's window is in front: its own feed is live then, so server states wait. */
  @Volatile var appInFront = false

  /**
   * The running app's island channel (MainActivity sets it while its engine lives), so Stop, Allow
   * and Deny act through the app without opening it (D-324, Phase 6). Null: the button opens the
   * app instead.
   */
  @Volatile var channel: MethodChannel? = null

  private val defaults = mapOf(
    "open" to "Open",
    "stop" to "Stop",
    "review" to "Review",
    "allow" to "Allow",
    "deny" to "Deny",
    "needs_ok" to "Needs your OK",
    "needs_you" to "Needs you",
    "working" to "Working",
    "take_over" to "Wants you to take over",
    "finished" to "Finished",
    "problem" to "Stopped with a problem",
    "bot_working" to "A bot is working",
    "bots_at_work" to "Bots at work",
    "steps_one" to "1 step",
    "steps_other" to "%d steps",
  )

  /** One run as drawn: the feed item's fields (island_feed.dart, IslandItem.toJson). */
  data class Run(
    val runId: String,
    val botId: String,
    val bot: String,
    val phase: String,
    val step: String,
    val detail: String?,
    val steps: Int,
    val approvalId: String?,
    val startedAtMs: Long,
    val endedAtMs: Long?,
    val link: String,
    /** A server state: when it goes stale (the app's own states have none). */
    val staleAtMs: Long? = null,
    /** The waiting request's risk ("low", "medium", "high"): high ones are only reviewed in the app. */
    val risk: String? = null,
    /** The bot's icon as it stores it (`mascot:<name>`); null draws its initials. */
    val botAvatar: String? = null,
  ) {
    val ended get() = endedAtMs != null || phase == "finished" || phase == "problem"
    val needsYou get() = phase == "needsOk" || phase == "takeOver"
  }

  private fun prefs(context: Context): SharedPreferences =
    context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

  private fun labels(context: Context): Map<String, String> {
    val saved = prefs(context).getString("labels", null)?.let { runCatching { JSONObject(it) }.getOrNull() }
    return defaults.mapValues { (k, v) -> saved?.optString(k)?.takeIf { it.isNotEmpty() } ?: v }
  }

  private fun manager(context: Context) = context.getSystemService(NotificationManager::class.java)

  private fun ensureChannel(context: Context, labels: Map<String, String>) {
    val manager = manager(context) ?: return
    val name = labels.getValue("bots_at_work")
    val existing = manager.getNotificationChannel(CHANNEL)
    if (existing != null && existing.name == name) return
    // Silent: the request's own notification buzzes once; this one never makes a sound. Default
    // importance, since a Live Update can't sit on a minimum-importance channel.
    manager.createNotificationChannel(
      NotificationChannel(CHANNEL, name, NotificationManager.IMPORTANCE_DEFAULT).apply {
        setSound(null, null)
        enableVibration(false)
        setShowBadge(false)
      },
    )
  }

  // MARK: The app's feed

  /**
   * The app's whole island state: draws each run in `items`, and ends one it no longer lists
   * (the person stopped it, so it leaves at once) once the app has caught up with the server
   * (`synced`). Returns whether notifications can show.
   */
  fun apply(context: Context, state: Map<*, *>): Boolean {
    (state["labels"] as? Map<*, *>)?.let { l ->
      prefs(context).edit().putString("labels", JSONObject(l.mapKeys { it.key.toString() }).toString()).apply()
    }
    val labels = labels(context)
    ensureChannel(context, labels)
    val synced = state["synced"] == true
    val now = System.currentTimeMillis()
    val wanted = mutableMapOf<String, Run>()
    for (raw in state["items"] as? List<*> ?: emptyList<Any>()) {
      val item = raw as? Map<*, *> ?: continue
      if (item["here"] == true) continue
      val run = runFromItem(item) ?: continue
      wanted[run.runId] = run
    }
    for (run in wanted.values) draw(context, run, labels, stampMs = now, fromServer = false)
    // A bot's own picture is saved first when it isn't here yet (off the main thread); the
    // notification is drawn again once it arrives, with the initials on its colours until then.
    BotPictures.ensureThen(context, BotAvatarValue.ids(wanted.values.map { it.botAvatar })) { redrawWithPictures(context, state) }
    // What's on screen, and what was just posted (notify is asynchronous, so the active list may
    // not have it yet).
    for (runId in shownRuns(context) + recordedRuns(context)) {
      if (runId in wanted || !synced) continue
      if (record(context, runId)?.optBoolean("ended") == true) continue
      end(context, runId)
    }
    refreshWidget(context)
    return manager(context)?.areNotificationsEnabled() ?: false
  }

  private fun runFromItem(item: Map<*, *>): Run? {
    val runId = item["run_id"] as? String ?: return null
    fun seconds(v: Any?): Long? = (v as? Number)?.let { (it.toDouble() * 1000).toLong() }
    return Run(
      runId = runId,
      botId = item["bot_id"] as? String ?: "",
      bot = item["bot"] as? String ?: "",
      phase = item["phase"] as? String ?: "working",
      step = item["step"] as? String ?: "",
      detail = (item["detail"] as? String)?.takeIf { it.isNotEmpty() },
      steps = (item["steps"] as? Number)?.toInt() ?: 0,
      approvalId = (item["approval_id"] as? String)?.takeIf { it.isNotEmpty() },
      startedAtMs = seconds(item["started_at"]) ?: System.currentTimeMillis(),
      endedAtMs = seconds(item["ended_at"]),
      link = item["link"] as? String ?: "/",
      risk = (item["risk"] as? String)?.takeIf { it.isNotEmpty() },
      botAvatar = (item["bot_avatar"] as? String)?.takeIf { it.isNotEmpty() },
    )
  }

  // MARK: Server pushes

  /**
   * A live update from the server (packages/agent liveData: every value a string). Drawn unless
   * the app is in front, or the app already drew something newer. A stopped run (its end leaves
   * at once) is removed.
   */
  fun fromPush(context: Context, data: Map<String, String>) {
    val runId = data["run_id"]?.takeIf { it.isNotEmpty() } ?: return
    val labels = labels(context)
    ensureChannel(context, labels)
    fun seconds(key: String) = data[key]?.toDoubleOrNull()?.let { (it * 1000).toLong() }
    val stamp = seconds("updated_at") ?: System.currentTimeMillis()
    val dismiss = seconds("dismiss_at")
    if (data["event"] == "end" && dismiss != null && dismiss <= stamp) {
      // Stopped: gone at once, as the app does. An end is final, so no stamp can make it "older".
      end(context, runId)
      refreshWidget(context)
      return
    }
    // A run nobody here follows (another phone's start) gets no notification out of nowhere.
    if (!shownRuns(context).contains(runId) && record(context, runId) == null && data["event"] == "end") return
    if (appInFront) return
    val run = Run(
      runId = runId,
      botId = data["bot_id"] ?: "",
      bot = data["bot_name"] ?: "",
      phase = data["phase"] ?: "working",
      step = data["step"] ?: "",
      detail = null,
      steps = data["steps"]?.toIntOrNull() ?: 0,
      approvalId = data["approval_id"]?.takeIf { it.isNotEmpty() },
      startedAtMs = seconds("started_at") ?: stamp,
      endedAtMs = seconds("ended_at") ?: if (data["event"] == "end") stamp else null,
      link = data["link"]?.takeIf { it.startsWith("/") } ?: "/",
      staleAtMs = seconds("stale_at"),
      risk = data["risk"]?.takeIf { it.isNotEmpty() },
      botAvatar = data["bot_avatar"]?.takeIf { it.isNotEmpty() },
    )
    Log.d("casama.live", "push for $runId: ${run.phase}")
    draw(context, run, labels, stampMs = stamp, fromServer = true)
    // Already on a background thread: fetch a picture we don't have and draw again with it.
    val picture = BotAvatarValue.picture(run.botAvatar)
    val server = BotPictures.server(context)
    if (picture != null && server != null && !BotPictures.has(context, picture.id) &&
      BotPictures.ensure(context, listOf(picture.id), server) > 0
    ) {
      forgetDrawn(context, run)
      draw(context, run, labels, stampMs = stamp, fromServer = true)
    }
    refreshWidget(context)
  }

  /** A picture arrived after the app drew its runs: forget what was drawn (when nothing newer was) and draw again. */
  private fun redrawWithPictures(context: Context, state: Map<*, *>) {
    for (raw in state["items"] as? List<*> ?: emptyList<Any>()) {
      val run = (raw as? Map<*, *>)?.takeIf { it["here"] != true }?.let { runFromItem(it) } ?: continue
      forgetDrawn(context, run)
    }
    apply(context, state)
  }

  /** Makes the next [draw] of [run] post again even though its state is the same as the last one's. */
  private fun forgetDrawn(context: Context, run: Run) {
    val last = record(context, run.runId) ?: return
    // A newer state drawn since (a push) already has the picture's file to read: leave it be.
    if (last.optString("key") != run.key()) return
    prefs(context).edit().putString("run_${run.runId}", last.put("key", "").put("app_key", "").toString()).apply()
  }

  // MARK: Drawing

  private fun record(context: Context, runId: String): JSONObject? =
    prefs(context).getString("run_$runId", null)?.let { runCatching { JSONObject(it) }.getOrNull() }

  private fun recordedRuns(context: Context): Set<String> =
    prefs(context).all.keys.filter { it.startsWith("run_") }.map { it.removePrefix("run_") }.toSet()

  private fun shownRuns(context: Context): Set<String> {
    val shown = manager(context)?.activeNotifications.orEmpty()
      .filter { it.tag == TAG }
      .mapNotNull { it.notification.extras.getString(EXTRA_RUN) }
    return shown.toSet()
  }

  private fun id(runId: String) = runId.hashCode()

  private fun draw(context: Context, run: Run, labels: Map<String, String>, stampMs: Long, fromServer: Boolean) {
    val manager = manager(context) ?: return
    val last = record(context, run.runId)
    if (last != null) {
      // Ended is final: a late "working" never brings a finished run back.
      if (last.optBoolean("ended") && !run.ended) return
      // Swiped away (Android 14 lets people clear ongoing notifications): it stays away.
      if (last.optBoolean("dismissed")) return
      // Firebase doesn't keep order: an older server state is dropped. Never an end, which is final
      // (and the stamps compare the server's clock with this phone's).
      if (fromServer && !run.ended && stampMs < last.optLong("stamp")) return
      // The app redraws only what changed in its own feed, so a newer server state it hasn't
      // caught up with yet (the app in the background) isn't drawn over.
      if (!fromServer && last.optString("app_key") == run.key()) return
      // The same thing again: leave the notification alone (no flicker, no reordering).
      if (last.optString("key") == run.key() && shownRuns(context).contains(run.runId)) return
      // Finished and already swiped away or timed out: don't bring it back.
      if (last.optBoolean("ended") && !shownRuns(context).contains(run.runId)) return
    }
    val promoted = !forceCustom && !run.ended && Build.VERSION.SDK_INT >= 36 && manager.canPostPromotedNotifications()
    val notification = build(context, run, labels, promoted)
    try {
      manager.notify(TAG, id(run.runId), notification)
    } catch (_: SecurityException) {
      // Notifications are off for the app; the app still shows every run.
      return
    }
    prefs(context).edit().putString(
      "run_${run.runId}",
      JSONObject()
        .put("stamp", maxOf(stampMs, last?.optLong("stamp") ?: 0L))
        .put("key", run.key())
        .put("app_key", if (fromServer) last?.optString("app_key") ?: "" else run.key())
        .put("ended", run.ended)
        .put("bot", run.bot)
        .put("bot_id", run.botId)
        .put("avatar", run.botAvatar ?: "")
        .put("step", stepText(run, labels))
        .put("phase", run.phase)
        .put("link", run.link)
        .put("started_at", run.startedAtMs)
        .put("kept", System.currentTimeMillis())
        .put("dismissed", false)
        .toString(),
    ).apply()
    sweep(context)
  }

  /** What the notification shows, so an unchanged state isn't drawn again. */
  private fun Run.key() = listOf(bot, botAvatar, phase, step, detail, steps, approvalId, endedAtMs != null).joinToString("\u0001")

  private fun stepText(run: Run, labels: Map<String, String>) = when {
    run.phase == "finished" -> labels.getValue("finished")
    run.phase == "problem" -> labels.getValue("problem")
    run.phase == "needsOk" && run.step.isEmpty() -> labels.getValue("needs_ok")
    run.phase == "takeOver" && run.step.isEmpty() -> labels.getValue("take_over")
    run.step.isEmpty() -> labels.getValue("working")
    else -> run.step
  }

  private fun stepsText(n: Int, labels: Map<String, String>) =
    if (n == 1) labels.getValue("steps_one") else labels.getValue("steps_other").replace("%d", n.toString())

  /** A casama:// link into the app, opened through [LiveRunActionActivity]. */
  private fun open(context: Context, path: String, request: Int): PendingIntent = PendingIntent.getActivity(
    context,
    request,
    Intent(context, LiveRunActionActivity::class.java)
      .putExtra(EXTRA_LINK, "casama://app$path")
      .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
  )

  /**
   * A button that acts in place (D-324, Phase 6): [LiveRunActionActivity] hands [kind] to the
   * running app and closes, so the app never shows; with no app running, or if it can't, it opens
   * [path] instead, as before. An activity, so Android asks to unlock first; Allow and Deny say so
   * explicitly too.
   */
  private fun act(context: Context, kind: String, target: String, path: String, request: Int): PendingIntent =
    PendingIntent.getActivity(
      context,
      request,
      Intent(context, LiveRunActionActivity::class.java)
        .putExtra(EXTRA_LINK, "casama://app$path")
        .putExtra(EXTRA_ACTION, kind)
        .putExtra(EXTRA_TARGET, target)
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

  /**
   * Whether a waiting request can be answered from the notification: only when its risk is known
   * and isn't high (a state without one, from an older server, shows Review alone).
   */
  fun answersInPlace(run: Run) =
    run.phase == "needsOk" && run.approvalId != null && run.risk != null && run.risk != "high"

  private const val ORANGE = 0xFFF28C28.toInt()
  private const val GREEN = 0xFF2FB463.toInt()
  private const val AMBER = 0xFFE0A100.toInt()

  fun build(context: Context, run: Run, labels: Map<String, String>, promoted: Boolean): Notification {
    val id = id(run.runId)
    val step = stepText(run, labels)
    // (label, intent, needs unlocking). Android shows three at most: a request answered here has
    // Allow, Deny and Review, and the notification itself opens the chat.
    val buttons = buildList {
      when {
        run.ended -> {}
        answersInPlace(run) -> {
          val a = run.approvalId!!
          val review = "/approvals/$a"
          add(Triple(labels.getValue("allow"), act(context, "allow", a, review, id + 5), true))
          add(Triple(labels.getValue("deny"), act(context, "deny", a, review, id + 6), true))
          add(Triple(labels.getValue("review"), open(context, review, id + 1), false))
        }
        run.phase == "needsOk" -> run.approvalId?.let {
          add(Triple(labels.getValue("review"), open(context, "/approvals/$it", id + 1), false))
        }
        run.phase == "takeOver" -> {}
        else -> add(
          Triple(labels.getValue("stop"), act(context, "stop", run.runId, "/runs/${run.runId}/stop", id + 2), false),
        )
      }
      if (!run.ended && size < 3) add(Triple(labels.getValue("open"), open(context, run.link, id + 3), false))
    }
    val public = Notification.Builder(context, CHANNEL)
      .setSmallIcon(R.drawable.ic_notification)
      .setContentTitle("Casama")
      .setContentText(
        when {
          run.phase == "problem" -> labels.getValue("problem")
          run.ended -> labels.getValue("finished")
          run.phase == "needsOk" -> labels.getValue("needs_ok")
          run.phase == "takeOver" -> labels.getValue("needs_you")
          else -> labels.getValue("bot_working")
        },
      )
      .build()
    val b = Notification.Builder(context, CHANNEL)
      .setSmallIcon(R.drawable.ic_notification)
      .setContentTitle(title(run, promoted))
      .setContentText(step)
      .setContentIntent(open(context, run.link, id))
      .setDeleteIntent(
        PendingIntent.getBroadcast(
          context,
          id + 4,
          Intent(context, LiveRunDismissReceiver::class.java).putExtra(EXTRA_RUN_ID, run.runId),
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        ),
      )
      .setOnlyAlertOnce(true)
      .setVisibility(Notification.VISIBILITY_PRIVATE)
      .setPublicVersion(public)
      .setCategory(if (run.needsYou) Notification.CATEGORY_STATUS else Notification.CATEGORY_PROGRESS)
      .addExtras(Bundle().apply {
        putString(EXTRA_RUN, run.runId)
        putString(EXTRA_PHASE, run.phase)
        putInt(EXTRA_STEPS, run.steps)
        putString(EXTRA_FORM, if (promoted) "live" else "custom")
      })
    // The bot's own colour while it works; orange once it needs the person.
    b.setColor(if (run.needsYou) ORANGE else BotArt.accent(run.bot, run.botAvatar))
    // The bot itself, as the app draws it (its mascot or initials), never the app's mark. The
    // custom views draw it themselves; a Live Update shows it as the large icon.
    if (promoted) b.setLargeIcon(Icon.createWithBitmap(mark(context, run)))
    if (run.ended) {
      b.setOngoing(false)
        .setAutoCancel(true)
        .setTimeoutAfter(FINISHED_FOR_MS)
        .setShowWhen(true)
        .setWhen(run.endedAtMs ?: System.currentTimeMillis())
    } else {
      b.setOngoing(true)
        .setUsesChronometer(true)
        .setShowWhen(true)
        .setWhen(run.startedAtMs)
      // Drawn from a push while the app sleeps: if no further word comes for an hour past its
      // stale time (a lost end), it clears itself instead of staying pinned. Each update re-posts
      // it and starts the clock again.
      run.staleAtMs?.let { b.setTimeoutAfter(maxOf(0L, it - System.currentTimeMillis()) + SERVER_GRACE_MS) }
    }
    for ((label, intent, unlock) in buttons) {
      val action = Notification.Action.Builder(null, label, intent)
      if (unlock && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) action.setAuthenticationRequired(true)
      b.addAction(action.build())
    }

    if (promoted) {
      // A Live Update: the standard look, ongoing, a title, and a request to be promoted
      // ("android.requestPromotedOngoing", what setRequestPromotedOngoing sets on 36.1).
      val text = listOfNotNull(step, run.detail).joinToString("\n")
      b.setStyle(Notification.BigTextStyle().bigText(text))
      b.addExtras(Bundle().apply { putBoolean(EXTRA_REQUEST_PROMOTED, true) })
      // The chip: a word while it needs you, else the running time (the chronometer).
      if (run.needsYou && Build.VERSION.SDK_INT >= 36) b.setShortCriticalText(labels.getValue("needs_you"))
    } else {
      b.setStyle(Notification.DecoratedCustomViewStyle())
      b.setCustomContentView(views(context, run, step, labels, expanded = false))
      b.setCustomBigContentView(views(context, run, step, labels, expanded = true))
    }
    return b.build()
  }

  /**
   * The notification's title. One UI lays a Live Update's running time straight after the title
   * with no gap ("Inbox Bot00:35"), so on Samsung the title carries two no-break spaces, which a
   * TextView doesn't trim the way it trims ordinary trailing spaces. Stock Android puts the time in
   * the header instead, so it gets the plain name.
   */
  private fun title(run: Run, promoted: Boolean): String {
    val name = run.bot.ifEmpty { "Casama" }
    val clockAfterTitle = promoted && !run.ended && Build.MANUFACTURER.equals("samsung", ignoreCase = true)
    return if (clockAfterTitle) "$name\u00A0\u00A0" else name
  }

  /** The bot's mark at the notification's large-icon size. */
  private fun mark(context: Context, run: Run) =
    BotArt.bitmap(context, run.bot.ifEmpty { "Casama" }, run.botAvatar, (48 * context.resources.displayMetrics.density).toInt())

  private fun views(context: Context, run: Run, step: String, labels: Map<String, String>, expanded: Boolean): RemoteViews {
    val v = RemoteViews(context.packageName, if (expanded) R.layout.live_run_expanded else R.layout.live_run_collapsed)
    v.setImageViewBitmap(R.id.live_mark, mark(context, run))
    v.setTextViewText(R.id.live_bot, run.bot.ifEmpty { "Casama" })
    v.setTextViewText(R.id.live_step, step)
    v.setTextColor(
      R.id.live_step,
      when {
        run.needsYou -> ORANGE
        run.phase == "finished" -> GREEN
        run.phase == "problem" -> AMBER
        else -> Color.GRAY
      },
    )
    // The phase badge on the mark, as the app's status dot.
    val badge = when (run.phase) {
      "needsOk", "takeOver" -> ORANGE
      "finished" -> GREEN
      "problem" -> AMBER
      else -> BotArt.accent(run.bot, run.botAvatar)
    }
    v.setInt(R.id.live_badge, "setColorFilter", badge)
    if (run.ended) {
      v.setViewVisibility(R.id.live_time, View.GONE)
    } else {
      // Chronometer counts from an elapsedRealtime base.
      val base = SystemClock.elapsedRealtime() - (System.currentTimeMillis() - run.startedAtMs)
      v.setChronometer(R.id.live_time, base, null, true)
      v.setViewVisibility(R.id.live_time, View.VISIBLE)
    }
    if (expanded) {
      v.setTextViewText(R.id.live_detail, run.detail ?: "")
      v.setViewVisibility(R.id.live_detail, if (run.detail.isNullOrEmpty()) View.GONE else View.VISIBLE)
      v.setTextViewText(R.id.live_steps, stepsText(run.steps, labels))
      v.setViewVisibility(R.id.live_steps, if (run.steps > 0) View.VISIBLE else View.GONE)
    }
    return v
  }

  /** The person cleared a run's notification: remember it so later states don't bring it back. */
  fun dismissed(context: Context, runId: String) {
    val last = record(context, runId) ?: return
    prefs(context).edit().putString("run_$runId", last.put("dismissed", true).toString()).apply()
    refreshWidget(context)
  }

  /**
   * Removes a run's notification at once (the person stopped it, or it ended unseen). What's kept
   * about it stays as a marker, ended and cleared, so a late push or a feed that hasn't caught up
   * can't bring it back; the daily sweep forgets it.
   */
  fun end(context: Context, runId: String) {
    manager(context)?.cancel(TAG, id(runId))
    val marker = (record(context, runId) ?: JSONObject())
      .put("ended", true)
      .put("dismissed", true)
      .put("kept", System.currentTimeMillis())
    prefs(context).edit().putString("run_$runId", marker.toString()).apply()
  }

  /** Forgets runs drawn more than a day ago. */
  private fun sweep(context: Context) {
    val p = prefs(context)
    val old = System.currentTimeMillis() - KEEP_MS
    val stale = p.all.keys.filter { k ->
      k.startsWith("run_") && (record(context, k.removePrefix("run_"))?.optLong("kept") ?: 0L) < old
    }
    if (stale.isNotEmpty()) p.edit().apply { stale.forEach { remove(it) } }.apply()
  }

  // MARK: The home-screen widgets

  /**
   * Puts the run that matters most (needs you first, then the newest) into the widgets' data, or
   * clears it when nothing runs, and redraws the widgets that show it live (Bot and Today, D-405).
   */
  fun refreshWidget(context: Context) {
    // From the records, not the active list: notify is asynchronous.
    val live = recordedRuns(context).mapNotNull { r -> record(context, r)?.let { r to it } }
      .filter { !it.second.optBoolean("ended") && !it.second.optBoolean("dismissed") }
      .sortedWith(
        compareByDescending<Pair<String, JSONObject>> { it.second.optString("phase") in setOf("needsOk", "takeOver") }
          .thenByDescending { it.second.optLong("started_at") },
      )
      .firstOrNull()
    val data = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
    val before = data.getString("live_run_id", null)
    data.edit().apply {
      if (live == null) {
        remove("live_run_id"); remove("live_bot"); remove("live_bot_id"); remove("live_avatar"); remove("live_step")
        remove("live_link"); remove("live_phase"); remove("live_started_at")
      } else {
        putString("live_run_id", live.first)
        putString("live_bot", live.second.optString("bot"))
        putString("live_bot_id", live.second.optString("bot_id"))
        putString("live_phase", live.second.optString("phase", "working"))
        putLong("live_started_at", live.second.optLong("started_at", System.currentTimeMillis()))
        putString("live_avatar", live.second.optString("avatar"))
        putString("live_step", live.second.optString("step"))
        putString("live_link", live.second.optString("link", "/"))
        putString("live_stop", labels(context).getValue("stop"))
      }
    }.apply()
    if (before == null && live == null) return
    WidgetKit.redraw(context, BotStatusWidget::class.java)
    WidgetKit.redraw(context, TodayWidget::class.java)
  }

  // MARK: Debug (the on-device check reads what is drawn)

  fun debuggable(context: Context) = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

  /** Debug builds: presses a run's notification button by its label, as a person's tap does. */
  fun debugAction(context: Context, runId: String?, title: String?): Boolean {
    val manager = manager(context) ?: return false
    val n = manager.activeNotifications.firstOrNull { it.tag == TAG && it.notification.extras.getString(EXTRA_RUN) == runId }
      ?.notification ?: return false
    val action = n.actions?.firstOrNull { it.title.toString() == title } ?: return false
    val options = if (Build.VERSION.SDK_INT >= 34) {
      android.app.ActivityOptions.makeBasic()
        .setPendingIntentBackgroundActivityStartMode(android.app.ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED)
        .toBundle()
    } else {
      null
    }
    action.actionIntent.send(context, 0, null, null, null, null, options)
    return true
  }

  /** Debug builds: whether a button asks to unlock first (Allow and Deny). */
  private fun unlocks(a: Notification.Action) = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && a.isAuthenticationRequired

  fun debugState(context: Context): List<Map<String, Any?>> {
    val manager = manager(context) ?: return emptyList()
    return manager.activeNotifications.filter { it.tag == TAG }.map { sbn ->
      val n = sbn.notification
      val e = n.extras
      mapOf(
        "run_id" to e.getString(EXTRA_RUN),
        "bot" to e.getCharSequence(Notification.EXTRA_TITLE)?.toString(),
        "step" to e.getCharSequence(Notification.EXTRA_TEXT)?.toString(),
        "phase" to e.getString(EXTRA_PHASE),
        "steps" to e.getInt(EXTRA_STEPS),
        "form" to e.getString(EXTRA_FORM),
        "ongoing" to ((n.flags and Notification.FLAG_ONGOING_EVENT) != 0),
        "promoted" to ((n.flags and Notification.FLAG_PROMOTED_ONGOING) != 0),
        "promotable" to (Build.VERSION.SDK_INT >= 36 && n.hasPromotableCharacteristics()),
        "chip" to e.getString("android.shortCriticalText"),
        "public" to n.publicVersion?.extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString(),
        "actions" to (n.actions?.map { it.title.toString() } ?: emptyList<String>()),
        "unlock" to (n.actions?.filter { unlocks(it) }?.map { it.title.toString() } ?: emptyList<String>()),
        "timeout_ms" to n.timeoutAfter,
        "channel" to n.channelId,
        "sdk" to Build.VERSION.SDK_INT,
        "enabled" to manager.areNotificationsEnabled(),
        "can_promote" to (Build.VERSION.SDK_INT >= 36 && manager.canPostPromotedNotifications()),
      )
    }
  }

  fun debugWidget(context: Context): Map<String, Any?> {
    val data = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
    return mapOf(
      "run_id" to data.getString("live_run_id", null),
      "bot" to data.getString("live_bot", null),
      "step" to data.getString("live_step", null),
      "enabled" to (manager(context)?.areNotificationsEnabled() ?: false),
    )
  }

  const val EXTRA_LINK = "casama_live_link"
  const val EXTRA_RUN_ID = "casama_live_run"
  const val EXTRA_ACTION = "casama_live_action"
  const val EXTRA_TARGET = "casama_live_target"
  /** The bot a widget's Run now or Do it is for (D-405 §17). */
  const val EXTRA_BOT = "casama_live_bot"
  private const val EXTRA_RUN = "casama.run_id"
  private const val EXTRA_PHASE = "casama.phase"
  private const val EXTRA_STEPS = "casama.steps"
  private const val EXTRA_FORM = "casama.form"
  private const val EXTRA_REQUEST_PROMOTED = "android.requestPromotedOngoing"
}

/**
 * Live updates from the server (D-324, Phase 5): data-only FCM messages of kind "live", drawn
 * here even when the app isn't running. It listens to the same broadcast as Firebase's own
 * receivers, as [SuggestionPushReceiver] does, so the Dart handlers still see every message.
 */
class LiveRunReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    val extras = intent.extras ?: return
    if (extras.getString("kind") != "live") return
    if (extras.containsKey("gcm.notification.title") || extras.containsKey("gcm.n.title")) return
    val data = extras.keySet()
      .filter { !it.startsWith("google.") && !it.startsWith("gcm.") }
      .mapNotNull { k -> extras.getString(k)?.let { k to it } }
      .toMap()
    LiveRun.fromPush(context, data)
  }
}

/** A live notification the person swiped away. */
class LiveRunDismissReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    intent.getStringExtra(LiveRun.EXTRA_RUN_ID)?.let { LiveRun.dismissed(context, it) }
  }
}

/**
 * Opens the app at a live notification's or a widget's link (Stop, Review, Open, a row), or acts
 * through the running app without showing it. An activity, not a receiver, because Android 12 and
 * later don't let notification receivers start activities, and so Android asks to unlock first.
 * The notification stays: the app's feed updates or ends it.
 *
 * Kinds handed to Dart over `casama/island` → `action` (D-324 Phase 6, D-405 §17): `stop`
 * (run_id), `allow` and `deny` (approval_id), `run_routine` (routine_id, bot_id) and `accept`
 * (suggestion_id, bot_id). Silent while the app is alive; otherwise, or if Dart says no, the link.
 */
class LiveRunActionActivity : Activity() {
  private var done = false
  private val handler = Handler(Looper.getMainLooper())

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    val link = intent.getStringExtra(LiveRun.EXTRA_LINK)
    val kind = intent.getStringExtra(LiveRun.EXTRA_ACTION)
    val target = intent.getStringExtra(LiveRun.EXTRA_TARGET)
    if (kind == null || target == null || LiveRun.channel == null) return open(link)
    // A notification's Allow and Deny already asked to unlock (setAuthenticationRequired); a
    // widget's button can't, so anything that answers or starts something asks here first.
    val keyguard = getSystemService(KeyguardManager::class.java)
    if (kind != "stop" && keyguard != null && keyguard.isKeyguardLocked) {
      if (Build.VERSION.SDK_INT >= 27) setShowWhenLocked(true)
      keyguard.requestDismissKeyguard(
        this,
        object : KeyguardManager.KeyguardDismissCallback() {
          override fun onDismissSucceeded() = act(kind, target, link)

          override fun onDismissCancelled() = close()

          override fun onDismissError() = close()
        },
      )
      return
    }
    act(kind, target, link)
  }

  /** Hands the action to the running app; the link if it can't (no answer in 8 s is a no). */
  private fun act(kind: String, target: String, link: String?) {
    val channel = LiveRun.channel ?: return open(link)
    val bot = intent.getStringExtra(LiveRun.EXTRA_BOT) ?: ""
    val args = when (kind) {
      "stop" -> mapOf("run_id" to target)
      "run_routine" -> mapOf("routine_id" to target, "bot_id" to bot)
      "accept" -> mapOf("suggestion_id" to target, "bot_id" to bot)
      else -> mapOf("approval_id" to target)
    }
    // Widget taps carry a casama-widget:// address (WidgetKit.actionIntent, Today's fill-ins); a
    // notification's don't. Dart lets a widget answer low-risk requests only (D-405 §10).
    val from = if (intent.data?.scheme == "casama-widget") mapOf("from" to "widget") else emptyMap()
    val timeout = Runnable { open(link) }
    handler.postDelayed(timeout, 8_000)
    channel.invokeMethod(
      "action",
      mapOf<String, Any>("kind" to kind, "unlocked" to true) + args + from,
      object : MethodChannel.Result {
        override fun success(result: Any?) {
          handler.removeCallbacks(timeout)
          if (result == true) {
            // Run now says "Started" on the widgets for a moment (D-405 §6.1 D).
            if (kind == "run_routine") {
              WidgetConfig.markStarted(applicationContext, target)
              WidgetKit.redraw(applicationContext, RoutinesWidget::class.java)
              WidgetKit.redraw(applicationContext, TodayWidget::class.java)
            }
            close()
          } else {
            open(link)
          }
        }

        override fun error(code: String, message: String?, details: Any?) {
          handler.removeCallbacks(timeout)
          open(link)
        }

        override fun notImplemented() {
          handler.removeCallbacks(timeout)
          open(link)
        }
      },
    )
  }

  /** The app couldn't do it here: open it where the person can (the button's old behaviour). */
  private fun open(link: String?) {
    if (done) return
    done = true
    link?.let {
      startActivity(
        Intent(Intent.ACTION_VIEW, Uri.parse(it), this, MainActivity::class.java)
          .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
      )
    }
    finish()
  }

  private fun close() {
    if (done) return
    done = true
    finish()
  }
}
