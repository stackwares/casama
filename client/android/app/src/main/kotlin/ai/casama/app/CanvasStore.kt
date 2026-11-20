package ai.casama.app

import ai.casama.app.canvas.Canvas
import ai.casama.app.canvas.CanvasDecode
import ai.casama.app.canvas.CanvasList
import ai.casama.app.canvas.CanvasLogic
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.util.Log
import java.io.File

/**
 * What the Canvas widget reads (docs/BOT-WIDGET-PLAN.md §10.2): the `CanvasList` from
 * `GET /v1/canvases`, kept as JSON under [KEY] in home_widget's `HomeWidgetPreferences` beside the
 * glance. The app writes it when it fetches (`canvas_sync.dart`, then `casama/widgets` → `reload`),
 * and [CanvasRefresh] writes it while the app is closed. Decoded by the pure model in `canvas/`.
 *
 * Pictures (backgrounds, paintings, a `picture` entry's own) are cached by hash in the app's files,
 * already shrunk to the largest placed Canvas widget, by [CanvasRefresh].
 */
object CanvasStore {
  const val KEY = "canvases"
  /** Written when the server has no /v1/canvases (404): the widget asks to update the server. */
  const val KEY_UNSUPPORTED = "canvases_unsupported"
  const val PICTURES_DIR = "widget_canvas_pictures"

  private var cachedRaw: String? = null
  private var cached: CanvasList? = null

  /** The list as last written, or null when there is none (or it isn't one). */
  fun load(context: Context): CanvasList? = parseCached(GlanceStore.prefs(context).all[KEY] as? String)

  fun unsupported(context: Context) = GlanceStore.flag(GlanceStore.prefs(context).all[KEY_UNSUPPORTED])

  @Synchronized
  private fun parseCached(raw: String?): CanvasList? {
    if (raw == null) return null
    if (raw == cachedRaw) return cached
    cached = parse(raw)
    cachedRaw = raw
    return cached
  }

  fun parse(raw: String): CanvasList? = runCatching { CanvasDecode.list(raw) }
    .onFailure { Log.w(CasamaWidget.TAG, "canvases unreadable: ${it.message}") }
    .getOrNull()

  /** Where a picture is cached: by its hash, which names one picture for good. */
  fun pictureFile(context: Context, hash: String): File? =
    if (CanvasLogic.safeHash(hash)) File(File(context.filesDir, PICTURES_DIR), "$hash.jpg") else null

  /** Every placed Canvas widget's id. */
  fun placedIds(context: Context): IntArray =
    AppWidgetManager.getInstance(context).getAppWidgetIds(ComponentName(context, CanvasWidget::class.java))

  /** The canvases the placed Canvas widgets show now: what pictures and redraw times are kept for. */
  fun shown(context: Context, list: CanvasList? = load(context), nowMs: Long = System.currentTimeMillis()): List<Canvas> =
    placedIds(context).toList().mapNotNull { CanvasLogic.choose(list, WidgetConfig.canvas(context, it), nowMs) }.distinctBy { it.id }

  /**
   * The `sizes` the server is told (§9.2): for each placed Canvas widget, `keyguard` on the lock
   * screen page, else home_small, home_medium or home_large from its size.
   */
  fun sizes(context: Context): List<String> {
    val manager = AppWidgetManager.getInstance(context)
    return placedIds(context).map { id ->
      val o = manager.getAppWidgetOptions(id)
      CanvasLogic.sizeName(
        o.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0),
        o.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0),
        WidgetKit.onKeyguard(manager, id),
      )
    }.distinct().sorted()
  }

  /** The largest placed Canvas widget in px (width, height), capped: what pictures are shrunk to. */
  fun largestPx(context: Context): Pair<Int, Int> {
    val manager = AppWidgetManager.getInstance(context)
    var w = 0
    var h = 0
    for (id in placedIds(context)) {
      val o = manager.getAppWidgetOptions(id)
      w = maxOf(w, o.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 0))
      h = maxOf(h, o.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0))
    }
    if (w <= 0 || h <= 0) { w = 250; h = 180 }
    return capPx(context, w, h)
  }

  /** [wDp]×[hDp] in px, scaled down so the longer side is at most [MAX_SIDE_PX]. */
  fun capPx(context: Context, wDp: Int, hDp: Int): Pair<Int, Int> {
    val d = context.resources.displayMetrics.density
    var w = (wDp * d).toInt().coerceAtLeast(1)
    var h = (hDp * d).toInt().coerceAtLeast(1)
    val longest = maxOf(w, h)
    if (longest > MAX_SIDE_PX) {
      w = w * MAX_SIDE_PX / longest
      h = h * MAX_SIDE_PX / longest
    }
    return w.coerceAtLeast(1) to h.coerceAtLeast(1)
  }

  /** A widget's pictures cross to the launcher as bitmaps: kept well under its limit. */
  const val MAX_SIDE_PX = 900
}
