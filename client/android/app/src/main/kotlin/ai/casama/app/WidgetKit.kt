package ai.casama.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

/**
 * What every Casama widget shares (D-405, docs/WIDGETS-PLAN.md §6 and §8.4): the §6.6 states, the
 * lock screen and app lock rules (§10), sizes per layout, and the two kinds of tap — one that opens
 * the app at a link, and one that acts through [LiveRunActionActivity] (silent while the app is
 * alive, else it opens the same link).
 *
 * All RemoteViews (decision 10): responsive layouts by size on Android 12 and later, the closest
 * single layout below.
 */
abstract class CasamaWidget : HomeWidgetProvider() {
  override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
    val snap = GlanceStore.load(context)
    for (id in appWidgetIds) draw(context, appWidgetManager, id, snap)
  }

  /** Redraws one placed widget from [snap]. A widget never stays blank: a failure draws a state. */
  fun draw(context: Context, manager: AppWidgetManager, id: Int, snap: GlanceStore.Snapshot) {
    val host = WidgetHost(id, WidgetKit.onKeyguard(manager, id), snap)
    val views = try {
      when (snap.state) {
        GlanceStore.State.READY -> build(context, manager, host)
        else -> stateViews(context, manager, host)
      }
    } catch (e: Exception) {
      // Never blank, never a wrong claim: the placeholder frame, opening the app.
      Log.w(TAG, "drawing ${javaClass.simpleName} failed", e)
      RemoteViews(context.packageName, R.layout.widget_loading).apply {
        setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, "/"))
      }
    }
    manager.updateAppWidget(id, views)
    afterDraw(context, manager, id)
  }

  /** Redraws every placed copy of this widget. */
  fun drawAll(context: Context) {
    val manager = AppWidgetManager.getInstance(context)
    val ids = manager.getAppWidgetIds(ComponentName(context, javaClass))
    if (ids.isEmpty()) return
    val snap = GlanceStore.load(context)
    for (id in ids) draw(context, manager, id, snap)
  }

  /** The widget with the glance in hand (state READY). */
  abstract fun build(context: Context, manager: AppWidgetManager, host: WidgetHost): RemoteViews

  /** Signed out, first load, a server too old, no bots yet (§6.6). */
  open fun stateViews(context: Context, manager: AppWidgetManager, host: WidgetHost): RemoteViews {
    val w = host.snap.words
    return when (host.snap.state) {
      GlanceStore.State.SIGNED_OUT -> WidgetKit.message(context, w["sign_in"], "/")
      GlanceStore.State.UPDATE_SERVER -> WidgetKit.message(context, w["update_server"], "/")
      GlanceStore.State.NO_BOTS -> WidgetKit.message(context, w["no_bots"], "/bots")
      else -> RemoteViews(context.packageName, R.layout.widget_loading).apply {
        setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, "/"))
      }
    }
  }

  /** Hook for collections that need telling their data changed (Today below Android 12). */
  open fun afterDraw(context: Context, manager: AppWidgetManager, id: Int) {}

  override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle) {
    super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    // Resized, or moved between the home screen and the lock screen: below Android 12 the layout is
    // picked here; on any version the lock screen hides words and buttons.
    draw(context, appWidgetManager, appWidgetId, GlanceStore.load(context))
  }

  override fun onEnabled(context: Context) {
    super.onEnabled(context)
    GlanceRefresh.schedule(context)
  }

  override fun onDeleted(context: Context, appWidgetIds: IntArray) {
    super.onDeleted(context, appWidgetIds)
    WidgetConfig.forget(context, appWidgetIds)
  }

  override fun onDisabled(context: Context) {
    super.onDisabled(context)
    // The last copy of this widget is gone: stop refreshing if it was the last of any of ours.
    GlanceRefresh.schedule(context)
  }

  companion object {
    const val TAG = "casama.widgets"
  }
}

/**
 * One placed widget as it is drawn. On the lock screen ([keyguard]) the person's words are left
 * out and there are no buttons (§10). With the app lock on ([GlanceStore.Snapshot.isPrivate]) the
 * writer already left the words out, and acting buttons open the app instead.
 */
class WidgetHost(val id: Int, val keyguard: Boolean, val snap: GlanceStore.Snapshot) {
  val glance: GlanceStore.Glance get() = snap.glance!!
  val words: Words get() = snap.words
  /** Leave out anything written by or about the person: requests, routine names, briefs, replies. */
  val quiet get() = keyguard || snap.isPrivate
  /** Draw buttons at all. */
  val buttons get() = !keyguard
  /** Buttons act in place; otherwise they open the app at the thing (the app lock asks first). */
  val inPlace get() = !snap.isPrivate
}

/** How a row's taps are set: directly, or as fill-ins of a collection's template (Today). */
interface Taps {
  fun open(views: RemoteViews, viewId: Int, link: String)
  fun act(views: RemoteViews, viewId: Int, action: WidgetAction)
}

/**
 * Something a button does through the app (§8.4): Allow, Deny, Run now, Do it, Stop. [fallback] is
 * the app route opened when the app isn't alive or can't do it here.
 */
data class WidgetAction(val kind: String, val target: String, val botId: String, val fallback: String)

object WidgetKit {
  /** Every provider, in the order Settings → Widgets lists them. Simple names are the channel's. */
  val providers: List<Class<out CasamaWidget>> = listOf(
    NeedsYouWidget::class.java,
    BotStatusWidget::class.java,
    AskWidget::class.java,
    RoutinesWidget::class.java,
    TodayWidget::class.java,
    BriefWidget::class.java,
    LibraryWidget::class.java,
    TasksWidget::class.java,
    CreditsWidget::class.java,
  )

  fun provider(simpleName: String?): Class<out CasamaWidget>? = providers.firstOrNull { it.simpleName == simpleName }

  /** Every placed widget of ours: (provider, id). */
  fun installed(context: Context): List<Pair<Class<out CasamaWidget>, Int>> {
    val manager = AppWidgetManager.getInstance(context)
    return providers.flatMap { cls -> manager.getAppWidgetIds(ComponentName(context, cls)).map { cls to it } }
  }

  /** Redraws every placed widget from the store (after the app or [GlanceRefresh] wrote it). */
  fun redrawAll(context: Context) {
    for (cls in providers) redraw(context, cls)
  }

  fun redraw(context: Context, cls: Class<out CasamaWidget>) {
    runCatching { cls.getDeclaredConstructor().newInstance().drawAll(context) }
      .onFailure { Log.w(CasamaWidget.TAG, "redraw ${cls.simpleName} failed", it) }
  }

  fun onKeyguard(manager: AppWidgetManager, id: Int): Boolean =
    manager.getAppWidgetOptions(id).getInt(AppWidgetManager.OPTION_APPWIDGET_HOST_CATEGORY, -1) ==
      AppWidgetProviderInfo.WIDGET_CATEGORY_KEYGUARD

  // MARK: Taps

  /** Opens the app at [link] (an app route), as every widget tap that only opens does (§17). */
  fun open(context: Context, link: String): PendingIntent =
    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("casama://app$link"))

  /**
   * Acts through the app ([LiveRunActionActivity]). With the app lock on it opens the fallback
   * instead, so the lock screen asks first (§8.4).
   */
  fun act(context: Context, host: WidgetHost, action: WidgetAction): PendingIntent =
    if (!host.inPlace) open(context, action.fallback)
    else PendingIntent.getActivity(
      context,
      0,
      actionIntent(context, action),
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

  /** The action's intent; its data makes each one distinct to the PendingIntent cache. */
  fun actionIntent(context: Context, action: WidgetAction): Intent =
    Intent(context, LiveRunActionActivity::class.java)
      .setData(Uri.parse("casama-widget://${action.kind}/${Uri.encode(action.target)}"))
      .putExtra(LiveRun.EXTRA_LINK, "casama://app${action.fallback}")
      .putExtra(LiveRun.EXTRA_ACTION, action.kind)
      .putExtra(LiveRun.EXTRA_TARGET, action.target)
      .putExtra(LiveRun.EXTRA_BOT, action.botId)
      .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

  /** Taps set straight on a widget's views. */
  fun direct(context: Context, host: WidgetHost) = object : Taps {
    override fun open(views: RemoteViews, viewId: Int, link: String) =
      views.setOnClickPendingIntent(viewId, open(context, link))

    override fun act(views: RemoteViews, viewId: Int, action: WidgetAction) =
      views.setOnClickPendingIntent(viewId, act(context, host, action))
  }

  // MARK: Layouts

  /**
   * A layout per size: on Android 12 and later the launcher picks the largest that fits as the
   * person resizes; below, the largest that fits the widget's current size is drawn.
   */
  fun sized(context: Context, manager: AppWidgetManager, id: Int, vararg layouts: Pair<SizeF, () -> RemoteViews>): RemoteViews {
    if (Build.VERSION.SDK_INT >= 31) return RemoteViews(layouts.associate { (size, make) -> size to make() })
    val o = manager.getAppWidgetOptions(id)
    // Portrait: the narrowest width and the tallest height the launcher reports.
    val w = o.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
    val h = o.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
    val fits = layouts.filter { (s, _) -> w >= s.width && h >= s.height }
    val pick = fits.maxByOrNull { (s, _) -> s.width * s.height } ?: layouts.minBy { (s, _) -> s.width * s.height }
    return pick.second()
  }

  /** The state layout (§6.6): the mascot and one line, opening the app at [link]. */
  fun message(context: Context, text: String, link: String): RemoteViews =
    RemoteViews(context.packageName, R.layout.widget_message).apply {
      setTextViewText(R.id.w_title, text)
      setContentDescription(android.R.id.background, text)
      setOnClickPendingIntent(android.R.id.background, open(context, link))
    }

  fun px(context: Context, dp: Int) = (dp * context.resources.displayMetrics.density).toInt()

  fun mark(context: Context, name: String, avatar: String?, dp: Int): Bitmap =
    BotArt.bitmap(context, name.ifEmpty { "Casama" }, avatar?.ifEmpty { null }, px(context, dp))

  fun RemoteViews.show(viewId: Int, on: Boolean) = setViewVisibility(viewId, if (on) View.VISIBLE else View.GONE)

  fun RemoteViews.text(viewId: Int, value: CharSequence?) {
    setTextViewText(viewId, value ?: "")
    setViewVisibility(viewId, if (value.isNullOrEmpty()) View.GONE else View.VISIBLE)
  }

  /** "As of 9:41" when the data is old (§6.6). */
  fun RemoteViews.asOf(host: WidgetHost) = text(R.id.w_asof, host.snap.asOf)

  /**
   * A text colour from a resource. On Android 12 and later the launcher resolves it when it draws,
   * so it follows light, dark and the phone's colours; below, it is resolved now.
   */
  fun RemoteViews.textColor(context: Context, viewId: Int, colorRes: Int) {
    if (Build.VERSION.SDK_INT >= 31) setColorStateList(viewId, "setTextColor", colorRes)
    else setTextColor(viewId, context.getColor(colorRes))
  }

  /** The run a person started that matters most, as [LiveRun.refreshWidget] keeps it. */
  data class Live(
    val runId: String,
    val botId: String,
    val bot: String,
    val avatar: String?,
    val step: String,
    val phase: String,
    val link: String,
    val startedAtMs: Long,
    val stopLabel: String,
  ) {
    val needsYou get() = phase == "needsOk" || phase == "takeOver"

    /** Stop, through the app (silent while it's alive), else the stop link. */
    val stop get() = WidgetAction("stop", runId, botId, "/runs/${Uri.encode(runId)}/stop")
  }

  fun live(p: SharedPreferences): Live? {
    val runId = p.getString("live_run_id", null) ?: return null
    return Live(
      runId = runId,
      botId = p.getString("live_bot_id", null) ?: "",
      bot = p.getString("live_bot", null) ?: "",
      avatar = p.getString("live_avatar", null),
      step = p.getString("live_step", null) ?: "",
      phase = p.getString("live_phase", null) ?: "working",
      link = p.getString("live_link", null)?.takeIf { it.startsWith("/") } ?: "/",
      startedAtMs = p.getLong("live_started_at", System.currentTimeMillis()),
      stopLabel = p.getString("live_stop", null) ?: "Stop",
    )
  }

  /** A Chronometer counting up from [startedAtMs] (it counts from an elapsedRealtime base). */
  fun RemoteViews.timer(viewId: Int, startedAtMs: Long) {
    val base = android.os.SystemClock.elapsedRealtime() - (System.currentTimeMillis() - startedAtMs)
    setChronometer(viewId, base, null, true)
    setViewVisibility(viewId, View.VISIBLE)
  }

  /** The one-line description of a need for the lock screen or the app lock: no request text. */
  fun quietNeed(n: GlanceStore.Need, w: Words): String = when (n.kind) {
    "approval" -> w.fill("needs_ok_from", "bot" to n.bot)
    "takeover" -> w.fill("take_over", "bot" to n.bot)
    else -> w.fill("suggests", "bot" to n.bot)
  }

  /** A need's button (§6.1 A): Allow/Deny on a low-risk approval, Review, Open, Do it. */
  fun needButtons(n: GlanceStore.Need, w: Words): List<Pair<String, WidgetAction?>> = when {
    n.kind == "approval" && n.answersInPlace -> listOf(
      w["allow"] to WidgetAction("allow", n.id, n.botId, "/approvals/${n.id}"),
      w["deny"] to WidgetAction("deny", n.id, n.botId, "/approvals/${n.id}"),
    )
    n.kind == "approval" -> listOf(w["review"] to null)
    n.kind == "takeover" -> listOf(w["open"] to null)
    else -> listOf(
      w["do_it"] to WidgetAction("accept", n.id, n.botId, "/suggestions/${Uri.encode(n.id)}/accept?bot=${Uri.encode(n.botId)}"),
    )
  }

  /** Run now on a routine (§6.1 D). */
  fun runNow(r: GlanceStore.Routine) =
    WidgetAction("run_routine", r.id, r.botId, "/run-routine/${Uri.encode(r.id)}:${Uri.encode(r.botId)}")

  /**
   * One row (widget_row.xml): a need, a routine, a task, something done. Buttons are left out on the
   * lock screen; the row itself always opens its link.
   */
  fun row(
    context: Context,
    taps: Taps,
    host: WidgetHost,
    t1: String,
    t2: String?,
    link: String,
    mark: Bitmap? = null,
    time: String? = null,
    buttons: List<Pair<String, WidgetAction?>> = emptyList(),
  ): RemoteViews = RemoteViews(context.packageName, R.layout.widget_row).apply {
    setTextViewText(R.id.w_t1, t1)
    text(R.id.w_t2, t2)
    if (mark != null) {
      setImageViewBitmap(R.id.w_mark, mark)
      show(R.id.w_mark, true)
    }
    text(R.id.w_time, time)
    taps.open(this, R.id.w_row, link)
    setContentDescription(R.id.w_row, listOfNotNull(time, t1, t2).joinToString(", "))
    val shown = if (host.buttons) buttons.take(2) else emptyList()
    listOf(R.id.w_btn1, R.id.w_btn2).forEachIndexed { i, viewId ->
      val b = shown.getOrNull(i)
      show(viewId, b != null)
      if (b != null) {
        setTextViewText(viewId, b.first)
        val action = b.second
        if (action != null) taps.act(this, viewId, action) else taps.open(this, viewId, link)
      }
    }
  }

  // MARK: Pictures

  /** A ring's track (a whole circle), white, tinted by the layout so it follows light and dark. */
  fun ringTrack(px: Int, strokeDp: Float, density: Float): Bitmap = ring(px, strokeDp * density, 1f)

  /** The used share of a ring, from twelve o'clock clockwise, white (tinted by the layout). */
  fun ringArc(px: Int, strokeDp: Float, density: Float, share: Double): Bitmap =
    ring(px, strokeDp * density, share.coerceIn(0.0, 1.0).toFloat())

  private fun ring(px: Int, stroke: Float, share: Float): Bitmap {
    val out = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
    if (share <= 0f) return out
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
      style = Paint.Style.STROKE
      strokeWidth = stroke
      strokeCap = Paint.Cap.ROUND
      color = 0xFFFFFFFF.toInt()
    }
    val inset = stroke / 2
    val box = RectF(inset, inset, px - inset, px - inset)
    if (share >= 1f) Canvas(out).drawOval(box, paint) else Canvas(out).drawArc(box, -90f, 360f * share, false, paint)
    return out
  }

  /** A creation's colour by kind, for a tile without a cover. */
  private fun kindColor(kind: String) = when (kind) {
    "page" -> 0xFF7A3FA8.toInt()
    "image" -> 0xFF14B8A6.toInt()
    "video" -> 0xFFEC4899.toInt()
    "audio" -> 0xFFF97316.toInt()
    "document" -> 0xFF3B82F6.toInt()
    else -> 0xFF64748B.toInt()
  }

  /**
   * A creation's picture at [w]×[h] px, rounded: its cached cover (fetched by [GlanceRefresh] with
   * the widget key), else a tile in its kind's colour with its first letter.
   */
  fun cover(context: Context, c: GlanceStore.Creation, w: Int, h: Int): Bitmap {
    val radius = 10 * context.resources.displayMetrics.density
    val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(out)
    val box = RectF(0f, 0f, w.toFloat(), h.toFloat())
    val file = if (c.hasCover) GlanceRefresh.coverFile(context, c.id, c.version) else null
    val art = file?.takeIf { it.exists() }?.let { decodeSampled(it, w, h) }
    if (art != null) {
      // Centre-crop the cover into the rounded box.
      val scale = maxOf(w.toFloat() / art.width, h.toFloat() / art.height)
      val m = android.graphics.Matrix().apply {
        setScale(scale, scale)
        postTranslate((w - art.width * scale) / 2, (h - art.height * scale) / 2)
      }
      val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG).apply {
        shader = BitmapShader(art, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP).apply { setLocalMatrix(m) }
      }
      canvas.drawRoundRect(box, radius, radius, paint)
    } else {
      canvas.drawRoundRect(box, radius, radius, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = kindColor(c.kind) })
      val letter = c.title.trim().take(1).uppercase().ifEmpty { "•" }
      val text = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = 0xFFFFFFFF.toInt()
        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        textAlign = Paint.Align.CENTER
        textSize = minOf(w, h) * 0.42f
      }
      canvas.drawText(letter, w / 2f, h / 2f - (text.descent() + text.ascent()) / 2, text)
    }
    return out
  }

  /** Decodes a cover no larger than needed, so a widget's pictures stay well under its limit. */
  private fun decodeSampled(file: File, w: Int, h: Int): Bitmap? = runCatching {
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeFile(file.path, bounds)
    var sample = 1
    while (bounds.outWidth / (sample * 2) >= w && bounds.outHeight / (sample * 2) >= h) sample *= 2
    BitmapFactory.decodeFile(file.path, BitmapFactory.Options().apply { inSampleSize = sample })
  }.getOrNull()
}

/**
 * What a person chose for each placed widget (WidgetConfigActivity): a bot for Ask and Bot, and
 * up to four routines for Routines (none: automatic). App-private, keyed by widget id.
 */
object WidgetConfig {
  private const val PREFS = "casama_widgets"
  /** How long Run now shows "Started" (§6.1 D) before the row returns to normal. */
  private const val STARTED_FOR_MS = 90_000L

  private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

  fun bot(context: Context, id: Int): String? = prefs(context).getString("bot_$id", null)

  fun setBot(context: Context, id: Int, botId: String) = prefs(context).edit().putString("bot_$id", botId).apply()

  /** The chosen routines, in the order picked; empty means automatic. */
  fun routines(context: Context, id: Int): List<String> =
    prefs(context).getString("routines_$id", null)?.split(',')?.filter { it.isNotEmpty() } ?: emptyList()

  fun setRoutines(context: Context, id: Int, ids: List<String>) =
    prefs(context).edit().putString("routines_$id", ids.take(4).joinToString(",")).apply()

  fun forget(context: Context, ids: IntArray) {
    prefs(context).edit().apply { ids.forEach { remove("bot_$it"); remove("routines_$it") } }.apply()
  }

  /** Run now was pressed and the app took it: the row says "Started" for a while. */
  fun markStarted(context: Context, routineId: String) =
    prefs(context).edit().putLong("started_$routineId", System.currentTimeMillis()).apply()

  fun started(context: Context, routineId: String): Boolean =
    System.currentTimeMillis() - prefs(context).getLong("started_$routineId", 0L) < STARTED_FOR_MS

  /** The bot a widget shows: the chosen one while it exists, else the first (the default bot). */
  fun botFor(context: Context, id: Int, glance: GlanceStore.Glance): GlanceStore.Bot? {
    val chosen = bot(context, id)
    return glance.bots.firstOrNull { it.id == chosen } ?: glance.bots.firstOrNull()
  }
}
