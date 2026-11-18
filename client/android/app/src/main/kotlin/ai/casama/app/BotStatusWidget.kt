package ai.casama.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget: a bot's status and today's cost, with a quick-ask button. While a bot works
 * on something you started (D-324, Phase 5), it shows that bot, its step and Stop instead; the
 * live state comes from [LiveRun.refreshWidget].
 */
class BotStatusWidget : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    for (id in appWidgetIds) {
      val liveRun = widgetData.getString("live_run_id", null)
      val views = RemoteViews(context.packageName, R.layout.bot_status_widget).apply {
        setOnClickPendingIntent(
            R.id.widget_ask,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("casama://app/quick-ask")),
        )
        if (liveRun != null) {
          val bot = widgetData.getString("live_bot", null)?.ifEmpty { null } ?: "Casama"
          setTextViewText(R.id.widget_bot, bot)
          setImageViewBitmap(R.id.widget_mark, BotArt.bitmap(context, bot, widgetData.getString("live_avatar", null), markPx(context)))
          setTextViewText(R.id.widget_status, widgetData.getString("live_step", ""))
          setViewVisibility(R.id.widget_cost, View.GONE)
          setViewVisibility(R.id.widget_stop, View.VISIBLE)
          setTextViewText(R.id.widget_stop, widgetData.getString("live_stop", "Stop"))
          setOnClickPendingIntent(
              R.id.widget_stop,
              HomeWidgetLaunchIntent.getActivity(
                  context, MainActivity::class.java, Uri.parse("casama://app/runs/${Uri.encode(liveRun)}/stop")),
          )
          setOnClickPendingIntent(
              R.id.widget_root,
              HomeWidgetLaunchIntent.getActivity(
                  context, MainActivity::class.java, Uri.parse("casama://app" + widgetData.getString("live_link", "/"))),
          )
        } else {
          val bot = widgetData.getString("bot_name", null)?.ifEmpty { null } ?: "Casama"
          setTextViewText(R.id.widget_bot, bot)
          setImageViewBitmap(R.id.widget_mark, BotArt.bitmap(context, bot, widgetData.getString("bot_avatar", null), markPx(context)))
          setTextViewText(R.id.widget_status, widgetData.getString("bot_status", "Open the app to sign in"))
          setTextViewText(R.id.widget_cost, widgetData.getString("bot_cost", ""))
          setViewVisibility(R.id.widget_cost, View.VISIBLE)
          setViewVisibility(R.id.widget_stop, View.GONE)
          setOnClickPendingIntent(
              R.id.widget_root,
              HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("casama://app/bots")),
          )
        }
      }
      appWidgetManager.updateAppWidget(id, views)
    }
  }

  private fun markPx(context: Context) = (32 * context.resources.displayMetrics.density).toInt()
}
