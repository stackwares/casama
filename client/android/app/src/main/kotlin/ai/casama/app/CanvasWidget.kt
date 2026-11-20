package ai.casama.app

import ai.casama.app.WidgetKit.show
import ai.casama.app.WidgetKit.text
import ai.casama.app.WidgetKit.textColor
import ai.casama.app.canvas.BackgroundKind
import ai.casama.app.canvas.Canvas
import ai.casama.app.canvas.CanvasEntry
import ai.casama.app.canvas.CanvasLogic
import ai.casama.app.canvas.Countdown
import ai.casama.app.canvas.Font
import ai.casama.app.canvas.Ink
import ai.casama.app.canvas.Look
import ai.casama.app.canvas.Template
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.LinearGradient
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.text.SpannableString
import android.text.Spanned
import android.text.format.DateUtils
import android.text.style.StrikethroughSpan
import android.text.style.StyleSpan
import android.text.style.TypefaceSpan
import android.util.SizeF
import android.view.Gravity
import android.widget.RemoteViews
import java.time.ZoneId

/**
 * Canvas (docs/BOT-WIDGET-PLAN.md §6, §10.2): what a bot puts on the person's widget, from
 * `GET /v1/canvases` ([CanvasStore]). The server has cut every text and chosen the text colour; this
 * only draws. Five templates (text, countdown, number, list, picture) at four sizes: 2×1 (compact),
 * 2×2, 4×2 and 4×3 and up, a size map on Android 12 and later.
 *
 * - The entry showing is the last whose time has come; [CanvasRefresh.scheduleTick] redraws at the
 *   next one, and at midnight or a day before a countdown's target.
 * - The background: the plain widget surface (`auto`), a colour as a tint on the rounded frame, or a
 *   gradient or picture drawn once into one bitmap that every size shares. A picture that isn't
 *   cached or wouldn't fit draws a colour instead.
 * - Locked: on the lock screen page a canvas with **Hide on a locked phone** shows its name only. A
 *   private key (app lock) shows the name and bot only.
 * - The person's choice ([WidgetConfig.canvas]): Automatic (the canvas set most recently) or one by
 *   name. A tap opens the canvas's link.
 */
class CanvasWidget : CasamaWidget() {
  private enum class Size { COMPACT, SMALL, MEDIUM, LARGE }

  override fun build(context: Context, manager: AppWidgetManager, host: WidgetHost): RemoteViews {
    val list = CanvasStore.load(context)
    if (list == null && CanvasStore.unsupported(context)) return WidgetKit.message(context, host.words["update_server"], "/")
    val now = System.currentTimeMillis()
    val canvas = CanvasLogic.choose(list, WidgetConfig.canvas(context, host.id), now) ?: return empty(context, manager, host)
    val entry = CanvasLogic.current(canvas, now)
    // The app's own fetch (with the session) may hold entries while the app lock is on: the glance
    // says so, and the widget then draws as a private key would.
    val private = list?.isPrivate == true || host.snap.isPrivate
    val locked = host.keyguard && canvas.hideWhenLocked
    if (entry == null || private || locked) return nameOnly(context, manager, host, canvas, withBot = !locked)

    // Made once and shared by every size: the launcher keeps one copy of each bitmap.
    val art = art(context, manager, host.id, entry)
    val mark = WidgetKit.mark(context, canvas.bot, canvas.botAvatar, 18)
    return WidgetKit.sized(
      context, manager, host.id,
      Cells.bar to { draw(context, host, canvas, entry, art, mark, Size.COMPACT, now) },
      Cells.small to { draw(context, host, canvas, entry, art, mark, Size.SMALL, now) },
      Cells.wide to { draw(context, host, canvas, entry, art, mark, Size.MEDIUM, now) },
      Cells.tall to { draw(context, host, canvas, entry, art, mark, Size.LARGE, now) },
    )
  }

  /** Signed out and the rest as every widget; no bots yet is "no canvas yet" here. */
  override fun stateViews(context: Context, manager: AppWidgetManager, host: WidgetHost): RemoteViews =
    if (host.snap.state == GlanceStore.State.NO_BOTS) empty(context, manager, host) else super.stateViews(context, manager, host)

  override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: android.content.SharedPreferences) {
    super.onUpdate(context, appWidgetManager, appWidgetIds, widgetData)
    CanvasRefresh.scheduleTick(context)
  }

  override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle) {
    super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    // Placed, resized or moved to the lock screen: tell the server where the canvas now shows
    // (`sizes`) and fetch pictures at the new size. Only when the set of sizes changed.
    val sizes = CanvasStore.sizes(context).joinToString(",")
    val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    if (prefs.getString(KEY_SIZES, null) != sizes) {
      prefs.edit().putString(KEY_SIZES, sizes).apply()
      GlanceRefresh.now(context)
    }
  }

  override fun onDeleted(context: Context, appWidgetIds: IntArray) {
    super.onDeleted(context, appWidgetIds)
    CanvasRefresh.scheduleTick(context)
  }

  /** The app pinned a Canvas widget with a canvas already chosen (`casama/widgets` → `pin`). */
  override fun onReceive(context: Context, intent: Intent) {
    if (intent.action != ACTION_PINNED) return super.onReceive(context, intent)
    val id = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
    val manager = AppWidgetManager.getInstance(context)
    // Only a widget of ours: the broadcast is explicit, but the id comes from outside.
    if (manager.getAppWidgetInfo(id)?.provider != ComponentName(context, CanvasWidget::class.java)) return
    WidgetConfig.setCanvas(context, id, intent.getStringExtra(EXTRA_CANVAS))
    draw(context, manager, id, GlanceStore.load(context))
    CanvasRefresh.scheduleTick(context)
    GlanceRefresh.now(context)
  }

  // MARK: States

  /** "Ask a bot to put something here" with one example (§6.5); 2×1 has room for the first only. */
  private fun empty(context: Context, manager: AppWidgetManager, host: WidgetHost): RemoteViews {
    val w = host.words
    fun make(compact: Boolean) = RemoteViews(context.packageName, R.layout.widget_canvas_empty).apply {
      show(R.id.w_mascot, !compact)
      setTextViewText(R.id.w_title, w["canvas_empty"])
      text(R.id.w_line, if (compact) null else w["canvas_try"])
      setContentDescription(android.R.id.background, listOfNotNull(w["canvas_empty"], w["canvas_try"].takeIf { !compact }).joinToString(". "))
      setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, "/settings/widgets"))
    }
    return WidgetKit.sized(context, manager, host.id, Cells.bar to { make(true) }, Cells.small to { make(false) })
  }

  /** A canvas by name only: private (with its bot), or hidden on a locked phone (the name alone). */
  private fun nameOnly(context: Context, manager: AppWidgetManager, host: WidgetHost, canvas: Canvas, withBot: Boolean): RemoteViews {
    val mark = if (withBot) WidgetKit.mark(context, canvas.bot, canvas.botAvatar, 18) else null
    fun make(compact: Boolean): RemoteViews =
      if (compact) {
        RemoteViews(context.packageName, R.layout.widget_canvas_compact).apply {
          setTextViewText(R.id.w_text, canvas.name)
          frame(context, canvas, listOf(canvas.name, canvas.bot.takeIf { withBot }))
        }
      } else {
        RemoteViews(context.packageName, R.layout.widget_canvas_text).apply {
          setTextViewText(R.id.w_title, "")
          setTextViewText(R.id.w_text, canvas.name)
          setInt(R.id.w_text, "setMaxLines", 2)
          text(R.id.w_footer, canvas.bot.takeIf { withBot })
          if (mark != null) {
            setImageViewBitmap(R.id.w_mark, mark)
            show(R.id.w_mark, true)
          }
          frame(context, canvas, listOf(canvas.name, canvas.bot.takeIf { withBot }))
        }
      }
    return WidgetKit.sized(context, manager, host.id, Cells.bar to { make(true) }, Cells.small to { make(false) })
  }

  /** What every canvas view shares: the tap and what a screen reader says. */
  private fun RemoteViews.frame(context: Context, canvas: Canvas, said: List<String?>) {
    setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, canvas.link))
    setContentDescription(android.R.id.background, said.filterNot { it.isNullOrEmpty() }.joinToString(". "))
  }

  // MARK: Drawing an entry

  private fun draw(
    context: Context,
    host: WidgetHost,
    canvas: Canvas,
    e: CanvasEntry,
    art: Bitmap?,
    mark: Bitmap,
    size: Size,
    now: Long,
  ): RemoteViews {
    val layout = if (size == Size.COMPACT) R.layout.widget_canvas_compact else when (e.template) {
      Template.TEXT -> R.layout.widget_canvas_text
      Template.COUNTDOWN -> R.layout.widget_canvas_countdown
      Template.NUMBER -> R.layout.widget_canvas_number
      Template.LIST -> R.layout.widget_canvas_list
      Template.PICTURE -> R.layout.widget_canvas_picture
    }
    val look = e.look
    return RemoteViews(context.packageName, layout).apply {
      background(e, art)
      val icon = CanvasLogic.iconText(look.icon)
      text(R.id.w_icon, icon)
      if (size == Size.COMPACT) {
        compact(context, host, e, now)
      } else {
        setImageViewBitmap(R.id.w_mark, mark)
        show(R.id.w_mark, true)
        title(context, R.id.w_title, e.title, look)
        // Kept (empty) without a title, so the bot's mark stays in the corner.
        show(R.id.w_title, true)
        when (e.template) {
          Template.TEXT -> textBody(context, e, size)
          Template.COUNTDOWN -> countdown(context, host, e, size, now)
          Template.NUMBER -> number(context, e, size)
          Template.LIST -> list(context, e, size)
          Template.PICTURE -> body(context, R.id.w_text, e.text, look)
        }
        // The footer everywhere but a small countdown, number or list (§6.3).
        val footer = e.footer.takeIf {
          size != Size.SMALL || e.template == Template.TEXT || e.template == Template.PICTURE
        }
        second(context, R.id.w_footer, footer, look)
      }
      frame(context, canvas, listOf(canvas.name, e.short.ifEmpty { e.text ?: e.title }, canvas.bot))
    }
  }

  private fun RemoteViews.compact(context: Context, host: WidgetHost, e: CanvasEntry, now: Long) {
    val look = e.look
    if (e.template == Template.COUNTDOWN) {
      body(context, R.id.w_text, e.title ?: e.tiny, look)
      timeLeft(context, host, e, now, R.id.w_days, R.id.w_chrono)
    } else {
      body(context, R.id.w_text, e.short.ifEmpty { e.text ?: e.title }, look)
    }
  }

  private fun RemoteViews.textBody(context: Context, e: CanvasEntry, size: Size) {
    // Up to 6 lines, 12 on the large size; the text shrinks to fit (autosize in the layout).
    setInt(R.id.w_text, "setMaxLines", if (size == Size.LARGE) 12 else 6)
    body(context, R.id.w_text, e.text, e.look)
  }

  private fun RemoteViews.countdown(context: Context, host: WidgetHost, e: CanvasEntry, size: Size, now: Long) {
    val look = e.look
    timeLeft(context, host, e, now, R.id.w_days, R.id.w_chrono)
    val target = e.targetMs
    second(
      context, R.id.w_date,
      if (size != Size.SMALL && target != null) DateUtils.formatDateTime(
        context, target,
        DateUtils.FORMAT_SHOW_WEEKDAY or DateUtils.FORMAT_ABBREV_WEEKDAY or DateUtils.FORMAT_SHOW_DATE or
          DateUtils.FORMAT_ABBREV_MONTH or DateUtils.FORMAT_SHOW_TIME,
      ) else null,
      look,
    )
    body(context, R.id.w_text, e.text.takeIf { size == Size.LARGE }, look)
  }

  /** Days as text, or the system's own timer under a day (it ticks by itself), or "Now". */
  private fun RemoteViews.timeLeft(context: Context, host: WidgetHost, e: CanvasEntry, now: Long, daysId: Int, chronoId: Int) {
    val w = host.words
    when (val c = CanvasLogic.countdown(e, now, ZoneId.systemDefault())) {
      is Countdown.Timer -> {
        // A Chronometer counts from an elapsedRealtime base: the target, in that clock.
        setChronometer(chronoId, SystemClock.elapsedRealtime() + (c.targetMs - now), null, true)
        setChronometerCountDown(chronoId, c.down)
        ink(context, chronoId, e.look, secondary = false)
        show(chronoId, true)
        show(daysId, false)
      }
      is Countdown.Days -> {
        title(context, daysId, "${c.days} " + (if (c.days == 1L) w["canvas_day"] else w["canvas_days"]), e.look, big = true)
        show(chronoId, false)
      }
      Countdown.Done -> {
        title(context, daysId, w["canvas_now"], e.look, big = true)
        show(chronoId, false)
      }
      null -> {
        show(daysId, false)
        show(chronoId, false)
      }
    }
  }

  private fun RemoteViews.number(context: Context, e: CanvasEntry, size: Size) {
    val look = e.look
    val value = e.value?.let { CanvasLogic.formatValue(it) } ?: ""
    val share = CanvasLogic.share(e.value, e.of)
    if (share != null) {
      val d = context.resources.displayMetrics.density
      val px = WidgetKit.px(context, 56)
      val accent = look.accent ?: context.getColor(R.color.widget_primary)
      setImageViewBitmap(R.id.w_ring_track, WidgetKit.ringTrack(px, 6f, d))
      setInt(R.id.w_ring_track, "setColorFilter", accent)
      setInt(R.id.w_ring_track, "setImageAlpha", 64)
      setImageViewBitmap(R.id.w_ring, WidgetKit.ringArc(px, 6f, d, share))
      setInt(R.id.w_ring, "setColorFilter", accent)
      title(context, R.id.w_value_in, value, look)
      show(R.id.w_ring_box, true)
      show(R.id.w_value, false)
      // "/ 30 days" beside the ring, from the medium size.
      val of = e.of?.let { CanvasLogic.formatValue(it) }
      second(context, R.id.w_unit, if (size == Size.SMALL) null else listOfNotNull("/ $of", e.unit).joinToString(" "), look)
    } else {
      title(context, R.id.w_value, value, look, big = true)
      second(context, R.id.w_unit, e.unit, look)
    }
    body(context, R.id.w_text, e.text.takeIf { size == Size.LARGE }, look)
  }

  private fun RemoteViews.list(context: Context, e: CanvasEntry, size: Size) {
    val rows = when (size) {
      Size.LARGE -> 5
      Size.MEDIUM -> 4
      else -> 3
    }
    listOf(R.id.w_i1, R.id.w_i2, R.id.w_i3, R.id.w_i4, R.id.w_i5).forEachIndexed { i, viewId ->
      val item = e.items.getOrNull(i)?.takeIf { i < rows }
      if (item == null) {
        show(viewId, false)
        return@forEachIndexed
      }
      text(viewId, styled((if (item.done) "✓  " else "○  ") + item.text, e.look.font, strike = item.done))
      ink(context, viewId, e.look, secondary = item.done)
      align(viewId, e.look)
    }
  }

  // MARK: Text

  /** `serif` and `mono` as spans (they cross to the launcher); `plain` and `rounded` are the default. */
  private fun styled(value: CharSequence, font: Font, bold: Boolean = false, strike: Boolean = false): CharSequence {
    val family = when (font) {
      Font.SERIF -> "serif"
      Font.MONO -> "monospace"
      Font.PLAIN, Font.ROUNDED -> null
    }
    if (family == null && !strike) return value
    return SpannableString(value).apply {
      if (family != null) {
        setSpan(TypefaceSpan(family), 0, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        // The span replaces the layout's medium weight: bold keeps a title a title.
        if (bold) setSpan(StyleSpan(Typeface.BOLD), 0, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      }
      if (strike) setSpan(StrikethroughSpan(), 0, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    }
  }

  private fun RemoteViews.title(context: Context, viewId: Int, value: String?, look: Look, big: Boolean = false) {
    text(viewId, value?.let { styled(it, look.font, bold = !big) })
    ink(context, viewId, look, secondary = false)
    align(viewId, look)
  }

  private fun RemoteViews.body(context: Context, viewId: Int, value: String?, look: Look) {
    text(viewId, value?.let { styled(it, look.font) })
    ink(context, viewId, look, secondary = false)
    align(viewId, look)
  }

  private fun RemoteViews.second(context: Context, viewId: Int, value: String?, look: Look) {
    text(viewId, value?.let { styled(it, look.font) })
    ink(context, viewId, look, secondary = true)
    align(viewId, look)
  }

  /** The text colour the server chose: white, near-black, or the widget's own (light and dark). */
  private fun RemoteViews.ink(context: Context, viewId: Int, look: Look, secondary: Boolean) {
    when (look.ink) {
      Ink.LIGHT -> setTextColor(viewId, if (secondary) 0xD9FFFFFF.toInt() else 0xFFFFFFFF.toInt())
      Ink.DARK -> setTextColor(viewId, if (secondary) 0xB31C1B1F.toInt() else 0xFF1C1B1F.toInt())
      Ink.AUTO -> textColor(context, viewId, if (secondary) R.color.widget_fg2 else R.color.widget_fg)
    }
  }

  private fun RemoteViews.align(viewId: Int, look: Look) {
    if (look.center) setInt(viewId, "setGravity", Gravity.CENTER)
  }

  // MARK: Background

  /** The picture or gradient as the bitmap ([art]); else a colour tinting the rounded frame; else the widget's own. */
  private fun RemoteViews.background(e: CanvasEntry, art: Bitmap?) {
    if (art != null) {
      setImageViewBitmap(R.id.w_art, art)
      show(R.id.w_art, true)
      return
    }
    val bg = e.look.background
    val fill = when (bg.kind) {
      // A picture entry over the widget's own surface whose picture isn't here: a colour its text reads on.
      BackgroundKind.AUTO -> if (e.template == Template.PICTURE) fallback(e.look.ink) else null
      BackgroundKind.COLOR -> bg.color
      // A gradient that couldn't be drawn: its first colour.
      BackgroundKind.GRADIENT -> bg.from ?: bg.color
      // A picture that isn't here or won't fit: its colour, else one the text reads on.
      BackgroundKind.PICTURE -> bg.color ?: fallback(e.look.ink)
    }
    if (fill != null) {
      setInt(R.id.w_fill, "setColorFilter", fill)
      show(R.id.w_fill, true)
    }
  }

  /** A colour light text reads on, or dark text; null keeps the widget's own surface. */
  private fun fallback(ink: Ink): Int? = when (ink) {
    Ink.LIGHT -> 0xFF2C2C2E.toInt()
    Ink.DARK -> 0xFFECE6F0.toInt()
    Ink.AUTO -> null
  }

  /**
   * The entry's picture (with a soft shade under light text) or gradient, drawn once at the widget's
   * largest size. On Android 12 and later the launcher rounds it (the frame clips to its outline);
   * below, it is drawn at the widget's size with the widget's corners. Null when there is nothing to
   * draw, the picture isn't cached yet, or it wouldn't fit the launcher's limit: a colour is drawn.
   */
  private fun art(context: Context, manager: AppWidgetManager, id: Int, e: CanvasEntry): Bitmap? = runCatching {
    val bg = e.look.background
    val hash = e.backgroundPicture
    val picture = hash?.let { CanvasStore.pictureFile(context, it) }?.takeIf { it.exists() }?.let { BitmapFactory.decodeFile(it.path) }
    val gradient = bg.kind == BackgroundKind.GRADIENT && bg.from != null && bg.to != null
    if (picture == null && !gradient) return null
    val o = manager.getAppWidgetOptions(id)
    val modern = Build.VERSION.SDK_INT >= 31
    // Android 12+: the largest box any size can take; below: the portrait size drawn now.
    var wDp = o.getInt(if (modern) AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH else AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
    var hDp = o.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
    if (wDp <= 0 || hDp <= 0) { wDp = 250; hDp = 180 }
    val (w, h) = CanvasStore.capPx(context, wDp, hDp)
    if (w.toLong() * h * 4 > budget(context)) return null
    val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
    val c = android.graphics.Canvas(out)
    val box = RectF(0f, 0f, w.toFloat(), h.toFloat())
    val radius = if (modern) 0f else context.resources.getDimension(R.dimen.widget_radius)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
    if (picture != null) {
      // Fill, centre-cropped.
      val scale = maxOf(w.toFloat() / picture.width, h.toFloat() / picture.height)
      val m = Matrix().apply {
        setScale(scale, scale)
        postTranslate((w - picture.width * scale) / 2, (h - picture.height * scale) / 2)
      }
      paint.shader = BitmapShader(picture, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP).apply { setLocalMatrix(m) }
      c.drawRoundRect(box, radius, radius, paint)
      picture.recycle()
      if (e.look.ink == Ink.LIGHT) {
        // A soft shade so light text reads on any picture: a little all over, more at the foot.
        c.drawRoundRect(box, radius, radius, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0x2E000000 })
        c.drawRoundRect(
          box, radius, radius,
          Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(0f, h * 0.4f, 0f, h.toFloat(), 0x00000000, 0x73000000, Shader.TileMode.CLAMP)
          },
        )
      }
    } else {
      // From top-leading to bottom-trailing (mirrored in a right-to-left language).
      val rtl = context.resources.configuration.layoutDirection == android.view.View.LAYOUT_DIRECTION_RTL
      paint.shader = LinearGradient(
        if (rtl) w.toFloat() else 0f, 0f, if (rtl) 0f else w.toFloat(), h.toFloat(),
        bg.from!!, bg.to!!, Shader.TileMode.CLAMP,
      )
      c.drawRoundRect(box, radius, radius, paint)
    }
    out
  }.getOrNull()

  /**
   * The bytes a background may take: the launcher refuses a widget whose bitmaps pass 1.5 screens of
   * ARGB, and the mark and ring need room too, so a third of that.
   */
  private fun budget(context: Context): Long {
    val m = context.resources.displayMetrics
    return m.widthPixels.toLong() * m.heightPixels * 4 * 3 / 2 / 3
  }

  companion object {
    /** The app pinned a Canvas widget with a canvas chosen ([WidgetChannel] `pin`). */
    const val ACTION_PINNED = "ai.casama.app.CANVAS_PINNED"
    const val EXTRA_CANVAS = "canvas_id"
    private const val PREFS = "casama_widgets"
    private const val KEY_SIZES = "canvas_sizes_sent"
  }
}
