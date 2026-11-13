package ai.casama.app

import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.app.Notification

/**
 * Suggestion pushes with buttons (D-247). The server sends suggestions to Android apps that say
 * they can draw them (devices.data_pushes) as data-only FCM messages; this receiver draws them with
 * "Do it" and "Not now". It listens to the same broadcast as Firebase's own receivers (the
 * firebase_messaging plugin does too), so the Dart handlers still see every message.
 */
class SuggestionPushReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val extras = intent.extras ?: return
        // Only our data-only suggestion messages: notification messages are drawn by Firebase.
        if (extras.getString("kind") != "suggestion" || extras.getString("category") != "SUGGESTION") return
        if (extras.containsKey("gcm.notification.title") || extras.containsKey("gcm.n.title")) return
        val suggestionId = extras.getString("suggestion_id") ?: return
        val title = extras.getString("title") ?: return
        val body = extras.getString("body") ?: ""
        val botId = extras.getString("bot_id") ?: ""
        val id = suggestionId.hashCode()

        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL) == null) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL, "Suggestions", NotificationManager.IMPORTANCE_HIGH).apply {
                    description = "Things your bots offer to do for you"
                },
            )
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        fun open(link: String, request: Int) = PendingIntent.getActivity(
            context,
            request,
            Intent(context, SuggestionActionActivity::class.java)
                .putExtra(EXTRA_LINK, link)
                .putExtra(EXTRA_NOTIFICATION, id)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            flags,
        )
        val accept = "casama://app/suggestions/${Uri.encode(suggestionId)}/accept" +
            if (botId.isNotEmpty()) "?bot=${Uri.encode(botId)}" else ""
        val later = PendingIntent.getBroadcast(
            context,
            id + 2,
            Intent(context, SuggestionDismissReceiver::class.java).putExtra(EXTRA_NOTIFICATION, id),
            flags,
        )
        val action = { label: String, intent: PendingIntent ->
            Notification.Action.Builder(null, label, intent).build()
        }
        val notification = Notification.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setContentIntent(open("casama://app/inbox", id))
            .addAction(action("Do it", open(accept, id + 1)))
            .addAction(action("Not now", later))
            .build()
        try {
            manager.notify(id, notification)
        } catch (_: SecurityException) {
            // Notifications are off for the app; the inbox still has it.
        }
    }

    companion object {
        const val CHANNEL = "suggestions"
        const val EXTRA_LINK = "casama_link"
        const val EXTRA_NOTIFICATION = "casama_notification_id"
    }
}

/** "Not now": clears the notification; the suggestion stays in For you. */
class SuggestionDismissReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(SuggestionPushReceiver.EXTRA_NOTIFICATION, 0)
        if (id != 0) context.getSystemService(NotificationManager::class.java)?.cancel(id)
    }
}

/**
 * Clears the notification, then opens the app at the button's link. An activity, not a receiver,
 * because Android 12 and later don't let notification receivers start activities.
 */
class SuggestionActionActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val id = intent.getIntExtra(SuggestionPushReceiver.EXTRA_NOTIFICATION, 0)
        if (id != 0) getSystemService(NotificationManager::class.java)?.cancel(id)
        intent.getStringExtra(SuggestionPushReceiver.EXTRA_LINK)?.let { link ->
            startActivity(
                Intent(Intent.ACTION_VIEW, Uri.parse(link), this, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            )
        }
        finish()
    }
}
