package ai.casama.app

import ai.casama.app.WidgetKit.asOf
import ai.casama.app.WidgetKit.show
import ai.casama.app.WidgetKit.text
import android.appwidget.AppWidgetManager
import android.content.Context
import android.text.format.DateUtils
import android.widget.RemoteViews

/**
 * Brief (D-405 §6.1 F): the latest morning brief (D-312) as plain text, with its bot and time, at
 * 4×2 and 4×3. Before today's arrives: "Brief at 7:00". A tap opens the chat at the brief.
 */
class BriefWidget : CasamaWidget() {
  override fun build(context: Context, manager: AppWidgetManager, host: WidgetHost): RemoteViews =
    WidgetKit.sized(
      context, manager, host.id,
      Cells.wide to { draw(context, host, lines = 4) },
      Cells.tall to { draw(context, host, lines = 9) },
    )

  private fun draw(context: Context, host: WidgetHost, lines: Int) = RemoteViews(context.packageName, R.layout.widget_list).apply {
    val w = host.words
    val b = host.glance.brief
    val bot = b?.let { it.bot to it.botAvatar } ?: host.glance.bots.first().let { it.name to it.avatar }
    setImageViewBitmap(R.id.w_mark, WidgetKit.mark(context, bot.first, bot.second, 24))
    show(R.id.w_mark, true)
    setTextViewText(R.id.w_title, w["brief"])
    setTextViewText(R.id.w_eyebrow, listOfNotNull(bot.first, b?.atMs?.let { GlanceStore.shortWhen(context, it) }).joinToString(" · "))
    show(R.id.w_rows, false)
    // The brief is the person's own news: behind the app lock it stays in the app.
    val body = if (host.quiet) null else b?.text
    if (body != null) {
      text(R.id.w_body, body)
      setInt(R.id.w_body, "setMaxLines", lines)
    } else {
      text(
        R.id.w_empty,
        when {
          b?.nextAtMs != null -> w.fill("brief_at", "time" to GlanceStore.time(context, b.nextAtMs))
          b?.text != null -> w["brief"]
          else -> w["no_brief"]
        },
      )
    }
    setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, b?.link ?: "/"))
    setContentDescription(android.R.id.background, listOfNotNull(w["brief"], bot.first, body).joinToString(". "))
    asOf(host)
  }
}

/**
 * Library (§6.1 G): the latest creations by their covers, one at 2×2 and three at 4×2. Covers are
 * fetched with the widget key by [GlanceRefresh] and cached by id and version; without one, a tile
 * in the creation's kind colour.
 */
class LibraryWidget : CasamaWidget() {
  override fun build(context: Context, manager: AppWidgetManager, host: WidgetHost): RemoteViews {
    val recent = host.glance.recent
    if (recent.isEmpty()) return WidgetKit.message(context, host.words["no_creations"], "/library")
    return WidgetKit.sized(
      context, manager, host.id,
      Cells.small to { small(context, host, recent.first()) },
      Cells.wide to { wide(context, host, recent.take(3)) },
    )
  }

  private fun title(host: WidgetHost, c: GlanceStore.Creation) = if (host.quiet) host.words["library"] else c.title

  private fun small(context: Context, host: WidgetHost, c: GlanceStore.Creation) = RemoteViews(context.packageName, R.layout.widget_cover).apply {
    setImageViewBitmap(R.id.w_cover, WidgetKit.cover(context, c, WidgetKit.px(context, 150), WidgetKit.px(context, 90)))
    setTextViewText(R.id.w_title, title(host, c))
    text(R.id.w_line, listOfNotNull(c.bot, GlanceStore.relative(c.atMs)).joinToString(" · "))
    setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, c.link))
    setContentDescription(android.R.id.background, "${host.words["library"]}. ${title(host, c)}")
  }

  private fun wide(context: Context, host: WidgetHost, list: List<GlanceStore.Creation>) = RemoteViews(context.packageName, R.layout.widget_list).apply {
    setTextViewText(R.id.w_title, host.words["library"])
    setTextViewText(R.id.w_eyebrow, "")
    removeAllViews(R.id.w_rows)
    val strip = RemoteViews(context.packageName, R.layout.widget_strip)
    for (c in list) {
      strip.addView(
        R.id.w_strip,
        RemoteViews(context.packageName, R.layout.widget_cover_cell).apply {
          setImageViewBitmap(R.id.w_cover, WidgetKit.cover(context, c, WidgetKit.px(context, 96), WidgetKit.px(context, 64)))
          setTextViewText(R.id.w_t1, title(host, c))
          setOnClickPendingIntent(R.id.w_cell, WidgetKit.open(context, c.link))
          setContentDescription(R.id.w_cell, title(host, c))
        },
      )
    }
    addView(R.id.w_rows, strip)
    setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, "/library"))
    asOf(host)
  }
}

/**
 * Tasks (§6.1 H), 4×2: the board's counts and its top rows, In review first because those wait on
 * a person. A tap opens /tasks.
 */
class TasksWidget : CasamaWidget() {
  override fun build(context: Context, manager: AppWidgetManager, host: WidgetHost): RemoteViews =
    RemoteViews(context.packageName, R.layout.widget_list).apply {
      val w = host.words
      val g = host.glance
      val c = g.taskCounts
      setTextViewText(R.id.w_title, w["tasks"])
      setTextViewText(R.id.w_eyebrow, "")
      removeAllViews(R.id.w_rows)
      addView(
        R.id.w_rows,
        RemoteViews(context.packageName, R.layout.widget_counts).apply {
          listOf(
            Triple(R.id.w_c1, R.id.w_l1, c.todo to w["todo"]),
            Triple(R.id.w_c2, R.id.w_l2, c.inProgress to w["in_progress"]),
            Triple(R.id.w_c3, R.id.w_l3, c.inReview to w["in_review"]),
            Triple(R.id.w_c4, R.id.w_l4, c.blocked to w["blocked"]),
          ).forEach { (n, l, v) ->
            setTextViewText(n, v.first.toString())
            setTextViewText(l, v.second)
          }
        },
      )
      val order = listOf("in_review", "blocked", "in_progress", "todo", "done")
      val taps = WidgetKit.direct(context, host)
      for (t in g.tasks.sortedBy { order.indexOf(it.status) }.take(2)) {
        addView(
          R.id.w_rows,
          WidgetKit.row(
            context, taps, host,
            t1 = if (host.quiet) w[t.status] else t.title,
            t2 = listOfNotNull(w[t.status].takeIf { !host.quiet }, t.bot).joinToString(" · "),
            link = t.link,
          ),
        )
      }
      setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, "/tasks"))
      setContentDescription(
        android.R.id.background,
        "${w["tasks"]}. ${w["todo"]} ${c.todo}, ${w["in_progress"]} ${c.inProgress}, ${w["in_review"]} ${c.inReview}, ${w["blocked"]} ${c.blocked}",
      )
      asOf(host)
    }
}

/**
 * Credits (§6.1 I), 2×2: a ring for the share of this period used, what's left and today's spend;
 * on the Free plan, when the daily cap resets; with billing off, today's and this month's spend.
 * Numbers only, so it may sit on the lock screen as it is.
 */
class CreditsWidget : CasamaWidget() {
  override fun build(context: Context, manager: AppWidgetManager, host: WidgetHost): RemoteViews =
    RemoteViews(context.packageName, R.layout.widget_credits).apply {
      val w = host.words
      val c = host.glance.credits
      val d = context.resources.displayMetrics.density
      val px = WidgetKit.px(context, 64)
      // The share used: the daily cap's on the Free plan, else the period's.
      val share = when {
        c == null || !c.billing || c.unlimited -> null
        c.dailyCapUsd != null && c.dailyCapUsd > 0 && c.dailyUsedUsd != null -> c.dailyUsedUsd / c.dailyCapUsd
        else -> c.usedShare
      }
      setImageViewBitmap(R.id.w_ring_track, WidgetKit.ringTrack(px, 6f, d))
      setImageViewBitmap(R.id.w_ring, WidgetKit.ringArc(px, 6f, d, share ?: 0.0))
      setTextViewText(R.id.w_count, share?.let { "${(it * 100).toInt()}%" } ?: "")
      val title: String
      val line: String
      when {
        c == null -> {
          title = w["credits"]
          line = ""
        }
        !c.billing -> {
          title = w.fill("spent_today", "amount" to GlanceStore.usd(c.todayUsd))
          line = GlanceStore.usd(c.monthUsd) + " · " +
            DateUtils.formatDateTime(context, System.currentTimeMillis(), DateUtils.FORMAT_SHOW_DATE or DateUtils.FORMAT_NO_MONTH_DAY or DateUtils.FORMAT_NO_YEAR)
        }
        c.dailyCapUsd != null && c.dailyUsedUsd != null -> {
          title = w.fill("credits_left", "amount" to GlanceStore.usd(maxOf(0.0, c.dailyCapUsd - c.dailyUsedUsd)))
          line = c.resetsAtMs?.let { w.fill("resets_at", "time" to GlanceStore.time(context, it)) } ?: ""
        }
        c.unlimited -> {
          title = c.plan ?: w["credits"]
          line = w.fill("spent_today", "amount" to GlanceStore.usd(c.todayUsd))
        }
        else -> {
          title = c.leftUsd?.let { w.fill("credits_left", "amount" to GlanceStore.usd(it)) } ?: w["credits"]
          line = w.fill("spent_today", "amount" to GlanceStore.usd(c.todayUsd))
        }
      }
      setTextViewText(R.id.w_title, title)
      text(R.id.w_line, line)
      setOnClickPendingIntent(android.R.id.background, WidgetKit.open(context, "/settings/billing"))
      setContentDescription(
        android.R.id.background,
        listOfNotNull(w["credits"], share?.let { w.fill("used_pct", "n" to (it * 100).toInt().toString()) }, title, line).joinToString(". "),
      )
      asOf(host)
    }
}
