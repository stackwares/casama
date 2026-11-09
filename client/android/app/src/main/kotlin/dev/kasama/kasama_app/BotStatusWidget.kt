package dev.kasama.kasama_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** Home-screen widget: a bot's status and today's cost, with a quick-ask button. */
class BotStatusWidget : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    for (id in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.bot_status_widget).apply {
        setTextViewText(R.id.widget_bot, widgetData.getString("bot_name", "Kasama"))
        setTextViewText(R.id.widget_status, widgetData.getString("bot_status", "Open the app to sign in"))
        setTextViewText(R.id.widget_cost, widgetData.getString("bot_cost", ""))
        setOnClickPendingIntent(
            R.id.widget_ask,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("kasama://app/quick-ask")),
        )
        setOnClickPendingIntent(
            R.id.widget_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("kasama://app/bots")),
        )
      }
      appWidgetManager.updateAppWidget(id, views)
    }
  }
}
