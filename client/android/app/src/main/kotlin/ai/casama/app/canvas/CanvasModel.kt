package ai.casama.app.canvas

import java.time.Instant
import java.time.LocalDate
import java.time.OffsetDateTime
import java.time.ZoneId
import java.time.temporal.ChronoUnit

/**
 * The Canvas widget's data (docs/BOT-WIDGET-PLAN.md §6, §10.2): `GET /v1/canvases`
 * (packages/contracts/src/canvas.ts, `CanvasList`), decoded, and the decisions the widget makes from
 * it: which canvas a widget shows, which entry shows now, when it next changes, and how a countdown
 * reads. No Android here, so it is tested with kotlinc (scripts/test-canvas-kotlin.sh) against
 * packages/contracts/fixtures/canvases.
 *
 * The server has already cut every text and chosen the text colour; this only reads.
 */
data class CanvasList(
  val version: String,
  val madeAtMs: Long,
  /** A private widget key (app lock on): names and bots only, no entries. */
  val isPrivate: Boolean,
  val items: List<Canvas>,
)

data class Canvas(
  val id: String,
  val orgId: String,
  val name: String,
  val botId: String,
  val bot: String,
  val botAvatar: String,
  val status: String,
  val hideWhenLocked: Boolean,
  val version: Int,
  val setAtMs: Long,
  val untilMs: Long?,
  /** The app route a tap opens. */
  val link: String,
  val entries: List<CanvasEntry>,
)

enum class Template { TEXT, COUNTDOWN, NUMBER, LIST, PICTURE }

data class ListItem(val text: String, val done: Boolean)

data class CanvasEntry(
  /** When it shows from; null for the one showing now. */
  val atMs: Long?,
  val template: Template,
  val title: String?,
  val text: String?,
  val footer: String?,
  val targetMs: Long?,
  /** countdown: counting up since the target rather than down to it. */
  val countUp: Boolean,
  val value: Double?,
  val of: Double?,
  val unit: String?,
  val items: List<ListItem>,
  val picture: String?,
  val short: String,
  val tiny: String,
  val look: Look,
) {
  /** The picture this entry draws behind it, if any: its own (template `picture`), else its look's. */
  val backgroundPicture: String?
    get() {
      val own = if (template == Template.PICTURE) picture else null
      return own ?: look.background.picture?.takeIf { look.background.kind == BackgroundKind.PICTURE }
    }
}

enum class BackgroundKind { AUTO, COLOR, GRADIENT, PICTURE }

/** Colours are ARGB ints (opaque), or null when absent or not `#rrggbb`. */
data class Background(val kind: BackgroundKind, val color: Int?, val from: Int?, val to: Int?, val picture: String?)

enum class Font { PLAIN, SERIF, ROUNDED, MONO }

enum class Ink { LIGHT, DARK, AUTO }

data class Look(
  val background: Background,
  val font: Font,
  val center: Boolean,
  /** One emoji or an icon name. */
  val icon: String?,
  val accent: Int?,
  val ink: Ink,
)

/** How a countdown reads at a moment. */
sealed class Countdown {
  /** Under a day: a timer ticking by itself toward (or up from) [targetMs]. */
  data class Timer(val targetMs: Long, val down: Boolean) : Countdown()

  /** A day or more: whole calendar days, redrawn at midnight. */
  data class Days(val days: Long, val down: Boolean) : Countdown()

  /** Counting down and the time has come. */
  object Done : Countdown()
}

object CanvasDecode {
  /** The list from its JSON; throws when it isn't one. */
  fun list(raw: String): CanvasList {
    val o = MiniJson.parse(raw) as? Map<*, *> ?: throw IllegalArgumentException("not a canvas list")
    return CanvasList(
      version = o.s("version") ?: "",
      madeAtMs = ms(o.s("made_at")) ?: 0L,
      isPrivate = o["private"] == true,
      items = o.objects("items").mapNotNull { canvas(it) },
    )
  }

  /** Null when it can't be a canvas (no id); a widget then skips it. */
  fun canvas(o: Map<*, *>): Canvas? {
    val id = o.s("id") ?: return null
    return Canvas(
      id = id,
      orgId = o.s("org_id") ?: "",
      name = o.s("name") ?: "",
      botId = o.s("bot_id") ?: "",
      bot = o.s("bot") ?: "",
      botAvatar = o.s("bot_avatar") ?: "",
      status = o.s("status") ?: "shown",
      hideWhenLocked = o["hide_when_locked"] == true,
      version = (o["version"] as? Number)?.toInt() ?: 0,
      setAtMs = ms(o.s("set_at")) ?: 0L,
      untilMs = ms(o.s("until")),
      link = o.s("link")?.takeIf { it.startsWith("/") } ?: "/canvases/$id",
      entries = o.objects("entries").map { entry(it) },
    )
  }

  fun entry(o: Map<*, *>): CanvasEntry {
    val template = when (o.s("template")) {
      "countdown" -> Template.COUNTDOWN
      "number" -> Template.NUMBER
      "list" -> Template.LIST
      "picture" -> Template.PICTURE
      else -> Template.TEXT
    }
    val short = o.s("short") ?: ""
    return CanvasEntry(
      atMs = ms(o.s("at")),
      template = template,
      title = o.s("title"),
      // A template this version doesn't know draws as text, with its short form.
      text = o.s("text") ?: short.takeIf { o.s("template") !in KNOWN },
      footer = o.s("footer"),
      targetMs = ms(o.s("target")),
      countUp = o.s("count") == "up",
      value = (o["value"] as? Number)?.toDouble(),
      of = (o["of"] as? Number)?.toDouble(),
      unit = o.s("unit"),
      items = o.objects("items").map { ListItem(it.s("text") ?: "", it["done"] == true) },
      picture = o.s("picture"),
      short = short,
      tiny = o.s("tiny") ?: "",
      look = look(o["look"] as? Map<*, *>),
    )
  }

  private val KNOWN = setOf("text", "countdown", "number", "list", "picture")

  fun look(o: Map<*, *>?): Look {
    val b = o?.get("background") as? Map<*, *>
    return Look(
      background = Background(
        kind = when (b?.s("kind")) {
          "color" -> BackgroundKind.COLOR
          "gradient" -> BackgroundKind.GRADIENT
          "picture" -> BackgroundKind.PICTURE
          else -> BackgroundKind.AUTO
        },
        color = color(b?.s("color")),
        from = color(b?.s("from")),
        to = color(b?.s("to")),
        picture = b?.s("picture"),
      ),
      font = when (o?.s("font")) {
        "serif" -> Font.SERIF
        "rounded" -> Font.ROUNDED
        "mono" -> Font.MONO
        else -> Font.PLAIN
      },
      center = o?.s("align") == "center",
      icon = o?.s("icon"),
      accent = color(o?.s("accent")),
      ink = when (o?.s("ink")) {
        "light" -> Ink.LIGHT
        "dark" -> Ink.DARK
        else -> Ink.AUTO
      },
    )
  }

  /** `#rrggbb` as an opaque ARGB int. */
  fun color(hex: String?): Int? {
    if (hex == null || hex.length != 7 || hex[0] != '#') return null
    val rgb = hex.substring(1).toIntOrNull(16) ?: return null
    return (0xFF000000.toInt()) or rgb
  }

  fun ms(iso: String?): Long? =
    iso?.let { runCatching { OffsetDateTime.parse(it).toInstant().toEpochMilli() }.getOrNull() }

  private fun Map<*, *>.s(key: String): String? = (this[key] as? String)?.takeIf { it.isNotEmpty() }

  private fun Map<*, *>.objects(key: String): List<Map<*, *>> =
    (this[key] as? List<*>)?.mapNotNull { it as? Map<*, *> } ?: emptyList()
}

object CanvasLogic {
  const val DAY_MS = 24 * 60 * 60 * 1000L

  /** The calendar day [ms] falls on in [zone]. */
  private fun day(ms: Long, zone: ZoneId): LocalDate = Instant.ofEpochMilli(ms).atZone(zone).toLocalDate()

  /** Still to be shown at [nowMs]: its `until` hasn't passed. */
  fun live(c: Canvas, nowMs: Long) = c.untilMs == null || c.untilMs > nowMs

  /**
   * The canvas a widget shows: the named one ([chosenId]) while it is there, else nothing (the
   * widget says "no canvas yet", §6.5); Automatic (null) is the one set most recently, `items[0]`.
   */
  fun choose(list: CanvasList?, chosenId: String?, nowMs: Long): Canvas? {
    val items = list?.items?.filter { live(it, nowMs) } ?: return null
    return if (chosenId == null) items.firstOrNull() else items.firstOrNull { it.id == chosenId }
  }

  /** The entry showing at [nowMs]: the last whose time has come (`entries[0]` has none). */
  fun current(c: Canvas, nowMs: Long): CanvasEntry? =
    c.entries.lastOrNull { it.atMs == null || it.atMs <= nowMs } ?: c.entries.firstOrNull()

  /** When the next planned entry takes over, if one is planned. */
  fun nextSwitchMs(c: Canvas, nowMs: Long): Long? =
    c.entries.mapNotNull { it.atMs }.filter { it > nowMs }.minOrNull()

  /** How a countdown entry reads at [nowMs] in [zone]. */
  fun countdown(e: CanvasEntry, nowMs: Long, zone: ZoneId): Countdown? {
    val target = e.targetMs ?: return null
    val up = e.countUp && nowMs >= target
    if (!up && nowMs >= target) return Countdown.Done
    val gap = if (up) nowMs - target else target - nowMs
    if (gap < DAY_MS) return Countdown.Timer(target, down = !up)
    val today = day(nowMs, zone)
    val then = day(target, zone)
    val days = if (up) ChronoUnit.DAYS.between(then, today) else ChronoUnit.DAYS.between(today, then)
    return Countdown.Days(maxOf(1L, days), down = !up)
  }

  /** When a countdown's reading next changes by itself: midnight, a day before the target, the target. */
  fun countdownChangeMs(e: CanvasEntry, nowMs: Long, zone: ZoneId): Long? {
    val target = e.targetMs ?: return null
    val midnight = day(nowMs, zone).plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli()
    return when (val c = countdown(e, nowMs, zone)) {
      null, Countdown.Done -> null
      // A ticking timer changes by itself; down, it ends at the target; up, it turns to days a day on.
      is Countdown.Timer -> if (c.down) target else target + DAY_MS
      is Countdown.Days -> if (c.down) minOf(midnight, target - DAY_MS) else midnight
    }
  }

  /** The next moment any of [shown] must be redrawn without new data: an entry, a countdown, an `until`. */
  fun nextTickMs(shown: List<Canvas>, nowMs: Long, zone: ZoneId): Long? =
    shown.flatMap { c ->
      listOfNotNull(
        nextSwitchMs(c, nowMs),
        c.untilMs?.takeIf { it > nowMs },
        current(c, nowMs)?.takeIf { it.template == Template.COUNTDOWN }?.let { countdownChangeMs(it, nowMs, zone) },
      )
    }.filter { it > nowMs }.minOrNull()

  /** The pictures [c] draws: what a widget keeps cached for it. */
  fun pictures(c: Canvas): Set<String> = c.entries.mapNotNull { it.backgroundPicture }.toSet()

  /** A picture hash is safe as a file name and a path part (the server's own pattern). */
  fun safeHash(h: String) = Regex("^(painting-[a-z_]{2,20}|[0-9a-f]{16,64})$").matches(h)

  /**
   * The size a placed widget reports to the server (`sizes`), from its size in dp: Android's lock
   * screen page counts as `keyguard`.
   */
  fun sizeName(widthDp: Int, heightDp: Int, keyguard: Boolean): String = when {
    keyguard -> "keyguard"
    widthDp < 250 || heightDp < 110 -> "home_small"
    heightDp < 180 -> "home_medium"
    else -> "home_large"
  }

  /** `12`, `12.5`, `-3`: no trailing zeros. */
  fun formatValue(v: Double): String =
    if (v == Math.floor(v) && !v.isInfinite() && Math.abs(v) < 1e15) v.toLong().toString()
    else String.format(java.util.Locale.US, "%.2f", v).trimEnd('0').trimEnd('.')

  /** The share of a goal for a ring, 0 to 1; null without a goal. */
  fun share(value: Double?, of: Double?): Double? =
    if (value == null || of == null || of <= 0) null else (value / of).coerceIn(0.0, 1.0)

  /** The icon as text: an emoji is drawn as it is; an icon name (letters, digits, `_`, `-`) is skipped. */
  fun iconText(icon: String?): String? =
    icon?.trim()?.takeIf { it.isNotEmpty() && !Regex("^[A-Za-z0-9_.-]+$").matches(it) }
}
