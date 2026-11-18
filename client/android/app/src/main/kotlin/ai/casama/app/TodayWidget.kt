package ai.casama.app

import ai.casama.app.WidgetKit.asOf
import ai.casama.app.WidgetKit.show
import ai.casama.app.WidgetKit.text
import ai.casama.app.WidgetKit.timer
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.text.format.DateUtils
import android.widget.RemoteViews
import android.widget.RemoteViewsService

/**
 * Today (D-405 §6.1 E, §6.4): everything on one 4×3 or taller widget. The date and a credits ring;
 * the running bot with its timer and Stop (live, from [LiveRun.refreshWidget]); a scrolling list of
 * Needs you (two rows with buttons), Up next (two rows with Run now) and what bots last finished;
 * and an ask field.
 *
 * The list is a RemoteViews collection: items handed over whole on Android 12 and later
 * (RemoteCollectionItems), and through [TodayWidgetService] below. Its taps are fill-ins of one
 * template that starts [LiveRunActionActivity], which opens a link or acts through the app.
 */
class TodayWidget : CasamaWidget() {
  override fun build(context: Context, manager: AppWidgetManager, host: WidgetHost): RemoteViews =
    RemoteViews(context.packageName, R.layout.widget_today).apply {
      val g = host.glance
      val w = host.words
      setTextViewText(R.id.w_eyebrow, w["today"])
      setTextViewText(
        R.id.w_title,
        DateUtils.formatDateTime(context, System.currentTimeMillis(), DateUtils.FORMAT_SHOW_WEEKDAY or DateUtils.FORMAT_SHOW_DATE or DateUtils.FORMAT_NO_YEAR),
      )
      asOf(host)
      ring(context, this, g.credits)
      setOnClickPendingIntent(R.id.w_ring_box, WidgetKit.open(context, "/settings/billing"))

      // The run the person started, live (only its bot's name on the lock screen, which Today
      // isn't on; the app lock keeps the step out).
      val live = WidgetKit.live(host.snap.prefs)
      show(R.id.w_live, live != null)
      if (live != null) {
        setImageViewBitmap(R.id.w_live_mark, WidgetKit.mark(context, live.bot, live.avatar, 28))
        setTextViewText(R.id.w_live_bot, live.bot.ifEmpty { "Casama" })
        text(R.id.w_live_step, if (host.quiet) w[if (live.needsYou) "waiting" else "working"] else live.step.ifEmpty { w["working"] })
        if (live.needsYou) show(R.id.w_chrono, false) else timer(R.id.w_chrono, live.startedAtMs)
        setTextViewText(R.id.w_live_stop, live.stopLabel)
        show(R.id.w_live_stop, !live.needsYou)
        setOnClickPendingIntent(R.id.w_live_stop, WidgetKit.act(context, host, live.stop))
        setOnClickPendingIntent(R.id.w_live, WidgetKit.open(context, live.link))
      }

      // The list, and one quiet line when there's nothing in it.
      setPendingIntentTemplate(R.id.w_list, template(context, host.id))
      setEmptyView(R.id.w_list, R.id.w_empty)
      setTextViewText(R.id.w_empty, listOf(w["all_clear"], NeedsYouWidget.nextDue(context, host)).joinToString(" · "))
      if (Build.VERSION.SDK_INT >= 31) {
        val items = items(context, host)
        val builder = RemoteViews.RemoteCollectionItems.Builder().setViewTypeCount(2).setHasStableIds(true)
        items.forEach { (id, views) -> builder.addItem(id, views) }
        setRemoteAdapter(R.id.w_list, builder.build())
      } else {
        @Suppress("DEPRECATION")
        setRemoteAdapter(
          R.id.w_list,
          Intent(context, TodayWidgetService::class.java)
            .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, host.id)
            .let { it.setData(Uri.parse(it.toUri(Intent.URI_INTENT_SCHEME))) },
        )
      }

      val bot = g.bots.first()
      setTextViewText(R.id.w_field, w.fill("ask_bot", "bot" to bot.name))
      setOnClickPendingIntent(R.id.w_field, WidgetKit.open(context, "/quick-ask?bot=${Uri.encode(bot.id)}"))
      setOnClickPendingIntent(R.id.w_mic, WidgetKit.open(context, "/bots/${Uri.encode(bot.id)}/call"))
      setContentDescription(R.id.w_mic, w["talk"])
      setContentDescription(
        android.R.id.background,
        listOfNotNull(w["today"], if (g.needsCount > 0) "${w["needs_you"]}, ${g.needsCount}" else w["all_clear"]).joinToString(". "),
      )
    }

  override fun afterDraw(context: Context, manager: AppWidgetManager, id: Int) {
    // Below Android 12 the list comes from TodayWidgetService, which reloads only when told to.
    @Suppress("DEPRECATION")
    if (Build.VERSION.SDK_INT < 31) manager.notifyAppWidgetViewDataChanged(id, R.id.w_list)
  }

  companion object {
    /** The ring in the corner: the share of this period's credits used; hidden when unknown. */
    fun ring(context: Context, views: RemoteViews, credits: GlanceStore.Credits?) {
      val share = credits?.usedShare?.takeIf { credits.billing && !credits.unlimited }
      views.setViewVisibility(R.id.w_ring_box, if (share != null) android.view.View.VISIBLE else android.view.View.GONE)
      if (share == null) return
      val d = context.resources.displayMetrics.density
      val px = WidgetKit.px(context, 40)
      views.setImageViewBitmap(R.id.w_ring_track, WidgetKit.ringTrack(px, 4f, d))
      views.setImageViewBitmap(R.id.w_ring, WidgetKit.ringArc(px, 4f, d, share))
      views.setContentDescription(R.id.w_ring_box, "${(share * 100).toInt()}%")
    }

    /**
     * One template for every row's taps (fill-ins carry the link or the action). Mutable, so they
     * can: Android 12 and later need that said; below, a PendingIntent is mutable unless told not.
     */
    private fun template(context: Context, id: Int): PendingIntent = PendingIntent.getActivity(
      context,
      id,
      Intent(context, LiveRunActionActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
      PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0),
    )

    /** Fill-in taps for the template above. With the app lock on, acting opens the app instead. */
    private fun fillIns(host: WidgetHost) = object : Taps {
      override fun open(views: RemoteViews, viewId: Int, link: String) = views.setOnClickFillInIntent(
        viewId,
        Intent()
          .setData(Uri.parse("casama-widget://open/" + Uri.encode(link)))
          .putExtra(LiveRun.EXTRA_LINK, "casama://app$link"),
      )

      override fun act(views: RemoteViews, viewId: Int, action: WidgetAction) {
        if (!host.inPlace) return open(views, viewId, action.fallback)
        views.setOnClickFillInIntent(
          viewId,
          Intent()
            .setData(Uri.parse("casama-widget://${action.kind}/${Uri.encode(action.target)}"))
            .putExtra(LiveRun.EXTRA_LINK, "casama://app${action.fallback}")
            .putExtra(LiveRun.EXTRA_ACTION, action.kind)
            .putExtra(LiveRun.EXTRA_TARGET, action.target)
            .putExtra(LiveRun.EXTRA_BOT, action.botId),
        )
      }
    }

    /** The list's items with stable ids: section headings and rows. */
    fun items(context: Context, host: WidgetHost): List<Pair<Long, RemoteViews>> {
      val g = host.glance
      val w = host.words
      val taps = fillIns(host)
      val out = mutableListOf<Pair<Long, RemoteViews>>()
      fun section(title: String) {
        out += (title.hashCode().toLong() shl 1) to RemoteViews(context.packageName, R.layout.widget_section).apply {
          setTextViewText(R.id.w_t1, title)
        }
      }
      fun add(key: String, views: RemoteViews) {
        out += ((key.hashCode().toLong() shl 1) or 1L) to views
      }

      if (g.needs.isNotEmpty()) {
        section(if (g.needsCount > 0) "${w["needs_you"]} · ${g.needsCount}" else w["needs_you"])
        for (n in g.needs.take(2)) {
          add(
            "need:${n.id}",
            WidgetKit.row(
              context, taps, host,
              t1 = if (host.quiet) WidgetKit.quietNeed(n, w) else n.text,
              t2 = if (host.quiet) null else if (n.kind == "suggestion") w.fill("suggests", "bot" to n.bot) else n.bot,
              link = n.link,
              mark = WidgetKit.mark(context, n.bot, n.botAvatar, 32),
              buttons = WidgetKit.needButtons(n, w),
            ),
          )
        }
      }
      val now = System.currentTimeMillis()
      val next = g.next.filter { it.enabled && (it.nextAtMs ?: 0L) > now }.sortedBy { it.nextAtMs }.take(2)
      if (next.isNotEmpty()) {
        section(w["up_next"])
        for (r in next) {
          val started = WidgetConfig.started(context, r.id)
          add(
            "next:${r.id}",
            WidgetKit.row(
              context, taps, host,
              t1 = if (host.quiet) r.bot else r.name,
              t2 = if (host.quiet) r.every else listOf(r.bot, r.every).filter { it.isNotEmpty() }.joinToString(" · "),
              link = r.link,
              time = GlanceStore.shortWhen(context, r.nextAtMs!!),
              buttons = listOf(if (started) w["started"] to null else w["run_now"] to WidgetKit.runNow(r)),
            ),
          )
        }
      }
      if (g.lately.isNotEmpty()) {
        section(w["finished"])
        for (d in g.lately.take(3)) {
          add(
            "done:${d.botId}:${d.atMs}",
            WidgetKit.row(
              context, taps, host,
              t1 = if (host.quiet) d.bot else d.title,
              t2 = listOfNotNull(if (host.quiet) null else d.bot, GlanceStore.relative(d.atMs)).joinToString(" · "),
              link = d.link,
              mark = WidgetKit.mark(context, d.bot, d.botAvatar, 32),
            ),
          )
        }
      }
      return out
    }
  }
}

/**
 * Today's list below Android 12, where a collection's items come from a service. It builds the
 * same items as [TodayWidget.items] from the store.
 */
class TodayWidgetService : RemoteViewsService() {
  override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
    Factory(applicationContext, intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID))

  private class Factory(private val context: Context, private val id: Int) : RemoteViewsFactory {
    private var items: List<Pair<Long, RemoteViews>> = emptyList()

    override fun onCreate() {}

    override fun onDataSetChanged() {
      val snap = GlanceStore.load(context)
      items = if (snap.state != GlanceStore.State.READY) emptyList()
      else TodayWidget.items(context, WidgetHost(id, WidgetKit.onKeyguard(AppWidgetManager.getInstance(context), id), snap))
    }

    override fun onDestroy() {
      items = emptyList()
    }

    override fun getCount() = items.size

    override fun getViewAt(position: Int): RemoteViews =
      items.getOrNull(position)?.second ?: RemoteViews(context.packageName, R.layout.widget_section)

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount() = 2

    override fun getItemId(position: Int) = items.getOrNull(position)?.first ?: position.toLong()

    override fun hasStableIds() = true
  }
}
