package ai.casama.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Rect
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * `casama/widgets` (D-405): what the app asks of the Android widgets. The glance itself goes through
 * home_widget (`HomeWidget.saveWidgetData` + `updateWidget`); this channel covers the rest.
 *
 * - `setKey` {key: String?}: the widget key for fetching while closed (null deletes it, at sign-out),
 *   and re-plans the periodic refresh.
 * - `reload`: redraws every widget from the store (and fetches covers the Library and pictures the
 *   Canvas lack). The app writes `canvases` (the `GET /v1/canvases` body) beside `glance` first.
 * - `installed`: [{provider: simple class name, id: Int}] for every placed widget.
 * - `pin` {provider, canvas_id?}: asks the launcher to add that widget (Settings → Widgets, "Add to
 *   Home screen"); `CanvasWidget` with a `canvas_id` is placed showing that canvas.
 * - `pinBot` {bot_id, name, avatar}: asks the launcher to add the bot as its own icon, opening its chat.
 */
object WidgetChannel {
  fun handle(context: Context, call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "setKey" -> {
        GlanceRefresh.setKey(context, call.argument<String>("key"))
        result.success(true)
      }
      "reload" -> {
        WidgetKit.redrawAll(context)
        GlanceRefresh.schedule(context)
        CanvasRefresh.scheduleTick(context)
        if (GlanceRefresh.coversMissing(context) || CanvasRefresh.picturesMissing(context)) GlanceRefresh.now(context)
        previews(context)
        result.success(true)
      }
      "installed" -> result.success(
        WidgetKit.installed(context).map { (cls, id) -> mapOf("provider" to cls.simpleName, "id" to id) },
      )
      "pin" -> {
        val cls = WidgetKit.provider(call.argument<String>("provider"))
        val manager = AppWidgetManager.getInstance(context)
        // Canvas may come with its canvas chosen: the launcher calls back with the new widget's id.
        val canvasId = call.argument<String>("canvas_id")?.takeIf { cls == CanvasWidget::class.java }
        val callback = canvasId?.let {
          PendingIntent.getBroadcast(
            context,
            it.hashCode(),
            Intent(context, CanvasWidget::class.java).setAction(CanvasWidget.ACTION_PINNED).putExtra(CanvasWidget.EXTRA_CANVAS, it),
            // Mutable so the launcher can add the widget's id; explicit, so only ours receives it.
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0),
          )
        }
        result.success(cls != null && manager.isRequestPinAppWidgetSupported && manager.requestPinAppWidget(ComponentName(context, cls), null, callback))
      }
      "pinBot" -> {
        val id = call.argument<String>("bot_id")
        val name = call.argument<String>("name") ?: ""
        result.success(id != null && pinBot(context, id, name, call.argument<String>("avatar")))
      }
      else -> result.notImplemented()
    }
  }

  /** A bot on the home screen as its own icon (§6.4): its face on white, opening its chat. */
  private fun pinBot(context: Context, botId: String, name: String, avatar: String?): Boolean {
    val shortcuts = context.getSystemService(ShortcutManager::class.java) ?: return false
    if (!shortcuts.isRequestPinShortcutSupported) return false
    val label = name.ifEmpty { "Casama" }
    val info = ShortcutInfo.Builder(context, "bot_$botId")
      .setShortLabel(label)
      .setLongLabel(label)
      .setIcon(Icon.createWithAdaptiveBitmap(adaptiveMark(context, label, avatar)))
      .setIntent(
        Intent(Intent.ACTION_VIEW, Uri.parse("casama://app/bots/${Uri.encode(botId)}/chat"), context, MainActivity::class.java)
          .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
      )
      .build()
    return runCatching { shortcuts.requestPinShortcut(info, null) }.getOrDefault(false)
  }

  /** An adaptive icon (108 dp, the mark inside the 66 dp safe zone) on white. */
  private fun adaptiveMark(context: Context, name: String, avatar: String?): Bitmap {
    val size = WidgetKit.px(context, 108)
    val markPx = WidgetKit.px(context, 60)
    val out = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(out)
    canvas.drawColor(0xFFFFFFFF.toInt())
    val mark = BotArt.bitmap(context, name, avatar?.ifEmpty { null }, markPx)
    val at = (size - markPx) / 2
    canvas.drawBitmap(mark, null, Rect(at, at, at + markPx, at + markPx), null)
    return out
  }

  private const val PREVIEW_EVERY_MS = 12 * 60 * 60 * 1000L

  /**
   * Android 15 and later: the widget picker previews the person's own bot (§6.4). The system limits
   * how often a preview may change, so at most twice a day, and only with real data in hand.
   */
  private fun previews(context: Context) {
    if (Build.VERSION.SDK_INT < 35) return
    val snap = GlanceStore.load(context)
    if (snap.state != GlanceStore.State.READY || snap.isPrivate) return
    val prefs = context.getSharedPreferences("casama_widgets", Context.MODE_PRIVATE)
    if (System.currentTimeMillis() - prefs.getLong("previews_at", 0L) < PREVIEW_EVERY_MS) return
    prefs.edit().putLong("previews_at", System.currentTimeMillis()).apply()
    val manager = AppWidgetManager.getInstance(context)
    val host = WidgetHost(AppWidgetManager.INVALID_APPWIDGET_ID, false, snap)
    for (cls in listOf(AskWidget::class.java, BotStatusWidget::class.java, NeedsYouWidget::class.java, RoutinesWidget::class.java)) {
      runCatching {
        val views = cls.getDeclaredConstructor().newInstance().build(context, manager, host)
        manager.setWidgetPreview(ComponentName(context, cls), AppWidgetProviderInfo.WIDGET_CATEGORY_HOME_SCREEN, views)
      }.onFailure { Log.w(CasamaWidget.TAG, "preview for ${cls.simpleName} failed", it) }
    }
  }
}
