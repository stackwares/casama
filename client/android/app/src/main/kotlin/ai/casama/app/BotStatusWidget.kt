package ai.casama.app

import ai.casama.app.WidgetKit.asOf
import ai.casama.app.WidgetKit.show
import ai.casama.app.WidgetKit.text
import ai.casama.app.WidgetKit.textColor
import ai.casama.app.WidgetKit.timer
import android.appwidget.AppWidgetManager
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews

/**
 * Bot (D-405 §6.1 B): one bot's face, name and where it stands, with a bot to pick (else the first).
 * 2×2: Working with its step, Waiting for you, Idle with when it last replied, or Turned off. 4×2:
 * adds its last message and Ask and Talk. While it runs something the person started (D-324), it
 * is live: the step, a running timer and Stop, from [LiveRun.refreshWidget], pushes included.
 *
 * Keeps the class name of the old Bot status widget, so widgets people already placed become this
 * one (decision 12). Today's cost moved to Credits.
 */
class BotStatusWidget : CasamaWidget() {
  override fun build(context: Context, manager: AppWidgetManager, host: WidgetHost): RemoteViews {
    val bot = WidgetConfig.botFor(context, host.id, host.glance)!!
    val live = WidgetKit.live(host.snap.prefs)?.takeIf { it.botId == bot.id || (it.botId.isEmpty() && it.bot == bot.name) }
    val state = State.of(context, host, bot, live)
    return WidgetKit.sized(
      context, manager, host.id,
      Cells.small to { small(context, host, bot, live, state) },
      Cells.wide to { wide(context, host, bot, live, state) },
    )
  }

  /** Where the bot stands, as drawn: the pill's word and colour, and the line under the name. */
  private class State(val pill: String?, val tone: Int, val line: String?) {
    companion object {
      fun of(context: Context, host: WidgetHost, bot: GlanceStore.Bot, live: WidgetKit.Live?): State {
        val w = host.words
        // The lock screen gets general words only: no step (it can name the person's things).
        fun step(s: String?) = if (host.quiet) null else s?.ifEmpty { null }
        if (live != null) {
          return if (live.needsYou) State(w["waiting"], ORANGE, step(live.step))
          else State(w["working"], GREEN, step(live.step) ?: w["working"])
        }
        val replied = (bot.busyAtMs ?: bot.lastAtMs)?.let { w.fill("replied_at", "time" to GlanceStore.shortWhen(context, it)) }
        return when {
          bot.status == "disabled" -> State(w["off"], PLAIN, null)
          // Old data claims nothing about now (§4, principle 5): when it was last busy instead.
          host.snap.stale && (bot.status == "working" || bot.status == "waiting") -> State(null, PLAIN, replied ?: host.snap.asOf)
          bot.status == "working" -> State(w["working"], GREEN, step(bot.step) ?: w["working"])
          bot.status == "waiting" -> State(w["waiting"], ORANGE, step(bot.step))
          else -> State(w["idle"], PLAIN, replied)
        }
      }
    }
  }

  private fun RemoteViews.pill(context: Context, state: State, live: WidgetKit.Live?) {
    show(R.id.w_pill, state.pill != null)
    setTextViewText(R.id.w_pill_text, state.pill ?: "")
    val (bg, fg) = when (state.tone) {
      GREEN -> R.drawable.widget_pill_green to R.color.widget_on_green
      ORANGE -> R.drawable.widget_pill_orange to R.color.widget_on_orange
      else -> R.drawable.widget_pill_plain to R.color.widget_fg2
    }
    setInt(R.id.w_pill, "setBackgroundResource", bg)
    textColor(context, R.id.w_pill_text, fg)
    textColor(context, R.id.w_chrono, fg)
    if (live != null && !live.needsYou) timer(R.id.w_chrono, live.startedAtMs) else show(R.id.w_chrono, false)
  }

  /** Stop and Open while live; Ask and Talk otherwise. None on the lock screen. */
  private fun buttons(host: WidgetHost, bot: GlanceStore.Bot, live: WidgetKit.Live?): List<Pair<String, WidgetAction?>> {
    if (!host.buttons) return emptyList()
    return if (live != null) listOf(live.stopLabel to live.stop, host.words["open"] to null)
    else listOf(host.words["ask"] to null, host.words["talk"] to null)
  }

  private fun RemoteViews.setButtons(context: Context, host: WidgetHost, bot: GlanceStore.Bot, live: WidgetKit.Live?, swapFill: Boolean) {
    val list = buttons(host, bot, live)
    val links = if (live != null) listOf(null, live.link)
    else listOf("/quick-ask?bot=${Uri.encode(bot.id)}", "/bots/${Uri.encode(bot.id)}/call")
    listOf(R.id.w_btn1, R.id.w_btn2).forEachIndexed { i, viewId ->
      val b = list.getOrNull(i)
      show(viewId, b != null)
      if (b == null) return@forEachIndexed
      setTextViewText(viewId, b.first)
      val action = b.second
      setOnClickPendingIntent(
        viewId,
        if (action != null) WidgetKit.act(context, host, action) else WidgetKit.open(context, links[i] ?: bot.link),
      )
    }
    // Stop isn't the main thing a person wants from a bot: both tonal while live.
    if (swapFill && live != null) {
      setInt(R.id.w_btn1, "setBackgroundResource", R.drawable.widget_btn_tone)
      textColor(context, R.id.w_btn1, R.color.widget_on_tone)
    }
  }

  private fun small(context: Context, host: WidgetHost, bot: GlanceStore.Bot, live: WidgetKit.Live?, state: State) =
    RemoteViews(context.packageName, R.layout.widget_tile).apply {
      setImageViewBitmap(R.id.w_lead_mark, WidgetKit.mark(context, bot.name, bot.avatar, 40))
      show(R.id.w_lead_mark, true)
      pill(context, state, live)
      setTextViewText(R.id.w_title, bot.name)
      text(R.id.w_line, state.line)
      setInt(R.id.w_line, "setMaxLines", 1)
      val buttons = buttons(host, bot, live)
      show(R.id.w_buttons, buttons.isNotEmpty())
      setButtons(context, host, bot, live, swapFill = true)
      setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, live?.link ?: bot.link))
      setContentDescription(android.R.id.background, listOfNotNull(bot.name, state.pill, state.line).joinToString(", "))
      if (live == null) asOf(host)
    }

  private fun wide(context: Context, host: WidgetHost, bot: GlanceStore.Bot, live: WidgetKit.Live?, state: State) =
    RemoteViews(context.packageName, R.layout.widget_bot_wide).apply {
      setImageViewBitmap(R.id.w_mark, WidgetKit.mark(context, bot.name, bot.avatar, 40))
      setTextViewText(R.id.w_title, bot.name)
      text(R.id.w_line, state.line)
      pill(context, state, live)
      // Its last message: the person's words, so not on the lock screen or behind the app lock, and
      // not when replies are hidden (D-325; the writer leaves it out too).
      val body = if (host.quiet || host.glance.hideReplyText) null else bot.lastText
      setTextViewText(R.id.w_body, body ?: "")
      setButtons(context, host, bot, live, swapFill = true)
      setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, live?.link ?: bot.link))
      setContentDescription(android.R.id.background, listOfNotNull(bot.name, state.pill, state.line, body).joinToString(", "))
      if (live == null) asOf(host)
    }

  /**
   * A server without the glance (§6.6): the Bot widget works as it did, from the strings the app
   * still writes (`bot_name`, `bot_avatar`, `bot_status`), live overlay included.
   */
  override fun stateViews(context: Context, manager: AppWidgetManager, host: WidgetHost): RemoteViews {
    val p = host.snap.prefs
    val name = p.getString("bot_name", null)?.ifEmpty { null }
    if (host.snap.state != GlanceStore.State.UPDATE_SERVER || name == null) return super.stateViews(context, manager, host)
    val live = WidgetKit.live(p)
    return RemoteViews(context.packageName, R.layout.widget_tile).apply {
      val shown = live?.bot?.ifEmpty { null } ?: name
      setImageViewBitmap(R.id.w_lead_mark, WidgetKit.mark(context, shown, live?.avatar ?: p.getString("bot_avatar", null), 40))
      show(R.id.w_lead_mark, true)
      setTextViewText(R.id.w_title, shown)
      text(R.id.w_line, if (live != null) live.step else p.getString("bot_status", null))
      if (live != null && host.buttons) {
        show(R.id.w_buttons, true)
        show(R.id.w_btn2, false)
        setTextViewText(R.id.w_btn1, live.stopLabel)
        setInt(R.id.w_btn1, "setBackgroundResource", R.drawable.widget_btn_tone)
        textColor(context, R.id.w_btn1, R.color.widget_on_tone)
        setOnClickPendingIntent(R.id.w_btn1, WidgetKit.act(context, host, live.stop))
      }
      setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, live?.link ?: "/quick-ask"))
    }
  }

  private companion object {
    const val PLAIN = 0
    const val GREEN = 1
    const val ORANGE = 2
  }
}
