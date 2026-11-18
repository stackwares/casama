package ai.casama.app

import ai.casama.app.WidgetKit.asOf
import ai.casama.app.WidgetKit.show
import ai.casama.app.WidgetKit.text
import ai.casama.app.WidgetKit.textColor
import android.appwidget.AppWidgetManager
import android.content.Context
import android.net.Uri
import android.util.SizeF
import android.widget.RemoteViews

/** The sizes the widgets lay out for (dp): Android's 2×1, 2×2, 4×2 and 4×3 cells, roughly. */
internal object Cells {
  val bar = SizeF(110f, 40f)
  val small = SizeF(110f, 110f)
  val wide = SizeF(250f, 110f)
  val tall = SizeF(250f, 180f)
}

/**
 * Ask (D-405 §6.1 C, §6.4): a 4×1 bar (resizable from 2×1 to 5×1) and a 2×2 with two things to try.
 * A tap opens quick ask with the keyboard up; the microphone starts a voice call; a starter opens
 * quick ask with it typed in, not sent. A bot can be picked (WidgetConfigActivity), else the first.
 */
class AskWidget : CasamaWidget() {
  override fun build(context: Context, manager: AppWidgetManager, host: WidgetHost): RemoteViews {
    val bot = WidgetConfig.botFor(context, host.id, host.glance)!!
    return WidgetKit.sized(
      context, manager, host.id,
      Cells.bar to { bar(context, host, bot) },
      Cells.small to { square(context, host, bot) },
    )
  }

  private fun ask(bot: GlanceStore.Bot) = "/quick-ask?bot=${Uri.encode(bot.id)}"

  private fun talk(bot: GlanceStore.Bot) = "/bots/${Uri.encode(bot.id)}/call"

  private fun bar(context: Context, host: WidgetHost, bot: GlanceStore.Bot) =
    RemoteViews(context.packageName, R.layout.widget_ask_bar).apply {
      val title = host.words.fill("ask_bot", "bot" to bot.name)
      setImageViewBitmap(R.id.w_mark, WidgetKit.mark(context, bot.name, bot.avatar, 32))
      setTextViewText(R.id.w_title, title)
      setContentDescription(android.R.id.background, title)
      setContentDescription(R.id.w_mic, host.words["talk"])
      setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, ask(bot)))
      setOnClickPendingIntent(R.id.w_mic, WidgetKit.open(context, talk(bot)))
    }

  private fun square(context: Context, host: WidgetHost, bot: GlanceStore.Bot) =
    RemoteViews(context.packageName, R.layout.widget_ask).apply {
      val title = host.words.fill("ask_bot", "bot" to bot.name)
      setImageViewBitmap(R.id.w_mark, WidgetKit.mark(context, bot.name, bot.avatar, 36))
      setTextViewText(R.id.w_title, title)
      setContentDescription(android.R.id.background, title)
      setContentDescription(R.id.w_mic, host.words["talk"])
      setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, ask(bot)))
      setOnClickPendingIntent(R.id.w_mic, WidgetKit.open(context, talk(bot)))
      // The person's own starters (D-338) are what keep this from being a launcher. They are the
      // person's words, so the app lock leaves them out (the writer already did).
      val starters = if (host.quiet) emptyList() else host.glance.starters
      listOf(R.id.w_chip1, R.id.w_chip2).forEachIndexed { i, viewId ->
        val s = starters.getOrNull(i)
        show(viewId, s != null)
        if (s != null) {
          setTextViewText(viewId, listOf(s.emoji, s.text).filter { it.isNotEmpty() }.joinToString(" "))
          setOnClickPendingIntent(viewId, WidgetKit.open(context, ask(bot) + "&text=" + Uri.encode(s.text)))
        }
      }
    }
}

/**
 * Needs you (§6.1 A): the count the Chats tab's Needs you row shows, approvals and takeovers first.
 * 2×2: the number, the first item's bot and one line. 4×2: two rows with their buttons. Nothing
 * waiting: All clear and the next thing due. On the lock screen, counts and general words only.
 */
class NeedsYouWidget : CasamaWidget() {
  override fun build(context: Context, manager: AppWidgetManager, host: WidgetHost): RemoteViews =
    WidgetKit.sized(
      context, manager, host.id,
      Cells.small to { small(context, host) },
      Cells.wide to { wide(context, host) },
    )

  private fun line(n: GlanceStore.Need, host: WidgetHost) =
    if (host.quiet) WidgetKit.quietNeed(n, host.words) else n.text.ifEmpty { WidgetKit.quietNeed(n, host.words) }

  private fun small(context: Context, host: WidgetHost) = RemoteViews(context.packageName, R.layout.widget_tile).apply {
    val g = host.glance
    val w = host.words
    val first = g.needs.firstOrNull()
    if (g.needsCount > 0) {
      text(R.id.w_count, g.needsCount.toString())
      if (first != null) setImageViewBitmap(R.id.w_mark, WidgetKit.mark(context, first.bot, first.botAvatar, 36))
      show(R.id.w_mark, first != null)
      setTextViewText(R.id.w_title, w["needs_you"])
      val line = first?.let { line(it, host) }
      text(R.id.w_line, line)
      // One item opens it; several open the list.
      val link = if (g.needsCount == 1 && first != null) first.link else "/inbox"
      setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, link))
      setContentDescription(android.R.id.background, listOfNotNull("${w["needs_you"]}, ${g.needsCount}", line).joinToString(". "))
    } else {
      val bot = g.bots.first()
      setImageViewBitmap(R.id.w_mark, WidgetKit.mark(context, bot.name, bot.avatar, 36))
      show(R.id.w_mark, true)
      setTextViewText(R.id.w_title, w["all_clear"])
      textColor(context, R.id.w_title, R.color.widget_fg)
      val due = nextDue(context, host)
      text(R.id.w_line, due)
      setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, "/inbox"))
      setContentDescription(android.R.id.background, listOf(w["all_clear"], due).joinToString(". "))
    }
    asOf(host)
  }

  private fun wide(context: Context, host: WidgetHost) = RemoteViews(context.packageName, R.layout.widget_list).apply {
    val g = host.glance
    val w = host.words
    setTextViewText(R.id.w_title, w["needs_you"])
    text(R.id.w_badge, if (g.needsCount > 0) g.needsCount.toString() else null)
    setTextViewText(R.id.w_eyebrow, "")
    removeAllViews(R.id.w_rows)
    val taps = WidgetKit.direct(context, host)
    val items = g.needs.take(2)
    for (n in items) {
      val t2 = when {
        host.quiet -> null
        n.kind == "approval" -> n.bot
        n.kind == "takeover" -> WidgetKit.quietNeed(n, w)
        else -> w.fill("suggests", "bot" to n.bot)
      }
      addView(
        R.id.w_rows,
        WidgetKit.row(
          context, taps, host,
          t1 = line(n, host),
          t2 = t2,
          link = n.link,
          mark = WidgetKit.mark(context, n.bot, n.botAvatar, 32),
          buttons = WidgetKit.needButtons(n, w),
        ),
      )
    }
    if (items.isEmpty()) {
      text(R.id.w_empty, listOfNotNull(w["all_clear"], nextDue(context, host)).joinToString(" · "))
    }
    show(R.id.w_rows, items.isNotEmpty())
    setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, "/inbox"))
    setContentDescription(
      android.R.id.background,
      if (g.needsCount > 0) "${w["needs_you"]}, ${g.needsCount}. ${items.joinToString(". ") { line(it, host) }}" else w["all_clear"],
    )
    asOf(host)
  }

  companion object {
    /** The next thing due, for All clear (§6.1 A): the brief's hour or the next routine. */
    fun nextDue(context: Context, host: WidgetHost): String {
      val g = host.glance
      val now = System.currentTimeMillis()
      val brief = g.brief?.nextAtMs?.takeIf { it > now }
      val routine = g.next.filter { it.enabled && (it.nextAtMs ?: 0L) > now }.minByOrNull { it.nextAtMs!! }
      return when {
        brief != null && (routine == null || brief <= routine.nextAtMs!!) ->
          host.words.fill("brief_at", "time" to GlanceStore.time(context, brief))
        routine != null -> {
          val name = if (host.quiet) routine.bot else routine.name
          "$name · ${GlanceStore.shortWhen(context, routine.nextAtMs!!)}"
        }
        else -> host.words["nothing_next"]
      }
    }
  }
}

/**
 * Routines (§6.1 D): automatic (the next runs, across bots) or up to four chosen ones. 2×2: the
 * next one with Run now. 4×2: three rows, Run now on each. Run now goes through the app and shows
 * "Started" for a moment; the run then appears as a live notification.
 */
class RoutinesWidget : CasamaWidget() {
  override fun build(context: Context, manager: AppWidgetManager, host: WidgetHost): RemoteViews {
    val list = routines(context, host)
    if (list.isEmpty()) {
      val bot = host.glance.bots.first()
      return WidgetKit.message(context, host.words["no_routines"], "/bots/${Uri.encode(bot.id)}/routines")
    }
    return WidgetKit.sized(
      context, manager, host.id,
      Cells.small to { small(context, host, list.first()) },
      Cells.wide to { wide(context, host, list.take(3)) },
    )
  }

  /** The chosen routines in the order picked, else the enabled ones by their next run. */
  private fun routines(context: Context, host: WidgetHost): List<GlanceStore.Routine> {
    val chosen = WidgetConfig.routines(context, host.id)
    val next = host.glance.next
    if (chosen.isNotEmpty()) {
      val picked = chosen.mapNotNull { id -> next.firstOrNull { it.id == id } }
      if (picked.isNotEmpty()) return picked
    }
    return next.filter { it.enabled }.sortedBy { it.nextAtMs ?: Long.MAX_VALUE }
  }

  private fun button(context: Context, host: WidgetHost, r: GlanceStore.Routine): Pair<String, WidgetAction?> =
    if (WidgetConfig.started(context, r.id)) host.words["started"] to null
    else host.words["run_now"] to WidgetKit.runNow(r)

  private fun small(context: Context, host: WidgetHost, r: GlanceStore.Routine) =
    RemoteViews(context.packageName, R.layout.widget_tile).apply {
      val w = host.words
      val at = r.nextAtMs
      text(R.id.w_eyebrow, listOfNotNull(w["up_next"], at?.let { GlanceStore.shortWhen(context, it) }).joinToString(" · "))
      show(R.id.w_spacer, false)
      // A routine's name is the person's words: the lock screen shows the bot instead.
      setTextViewText(R.id.w_title, if (host.quiet) r.bot else r.name)
      val line = listOfNotNull(if (host.quiet) null else r.bot, at?.let { GlanceStore.relative(it) }).joinToString(" · ")
      text(R.id.w_line, line)
      setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, r.link))
      setContentDescription(android.R.id.background, "${w["up_next"]}. ${if (host.quiet) r.bot else r.name}. $line")
      if (host.buttons) {
        show(R.id.w_buttons, true)
        show(R.id.w_btn2, false)
        val (label, action) = button(context, host, r)
        setTextViewText(R.id.w_btn1, label)
        setOnClickPendingIntent(
          R.id.w_btn1,
          if (action != null) WidgetKit.act(context, host, action) else WidgetKit.open(context, r.link),
        )
      }
      asOf(host)
    }

  private fun wide(context: Context, host: WidgetHost, list: List<GlanceStore.Routine>) =
    RemoteViews(context.packageName, R.layout.widget_list).apply {
      val w = host.words
      setTextViewText(R.id.w_title, w["up_next"])
      setTextViewText(R.id.w_eyebrow, "")
      removeAllViews(R.id.w_rows)
      val taps = WidgetKit.direct(context, host)
      for (r in list) {
        addView(
          R.id.w_rows,
          WidgetKit.row(
            context, taps, host,
            t1 = if (host.quiet) r.bot else r.name,
            t2 = if (host.quiet) r.every else listOf(r.bot, r.every).filter { it.isNotEmpty() }.joinToString(" · "),
            link = r.link,
            time = r.nextAtMs?.let { GlanceStore.shortWhen(context, it) } ?: "–",
            buttons = listOf(button(context, host, r)),
          ),
        )
      }
      val first = list.first()
      setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, "/bots/${Uri.encode(first.botId)}/routines"))
      setContentDescription(android.R.id.background, "${w["up_next"]}. ${list.joinToString(". ") { if (host.quiet) it.bot else it.name }}")
      asOf(host)
    }
}
