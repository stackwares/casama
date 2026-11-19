package ai.casama.wear.notify

import ai.casama.wear.R
import ai.casama.wear.art.BotArt
import ai.casama.wear.core.AllowLevel
import ai.casama.wear.core.Logic
import ai.casama.wear.core.Risk
import ai.casama.wear.core.WatchPush
import ai.casama.wear.ui.Routes
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.RemoteInput

/**
 * The watch's own notifications (docs/WATCH-PLAN.md §6.2, WATCH-PROTOCOL §4), drawn from data-only
 * pushes so their buttons run on the watch, with the phone locked in a pocket. Allow is the first
 * button, so a pinch (where the watch supports gestures) answers a low-risk request.
 */
object Notifier {
    const val CH_NEEDS = "needs_you"
    const val CH_REPLIES = "replies"
    const val CH_ROUTINES = "routines"
    const val CH_WORKING = "working"
    const val CH_OTHER = "other"

    const val GROUP = "casama"
    const val REPLY_KEY = "casama_reply"

    fun ensureChannels(context: Context) {
        val m = context.getSystemService(NotificationManager::class.java) ?: return
        fun ch(id: String, name: Int, importance: Int) {
            if (m.getNotificationChannel(id) == null) m.createNotificationChannel(NotificationChannel(id, context.getString(name), importance))
        }
        ch(CH_NEEDS, R.string.watch_channel_requests, NotificationManager.IMPORTANCE_HIGH)
        ch(CH_REPLIES, R.string.watch_channel_replies, NotificationManager.IMPORTANCE_HIGH)
        ch(CH_ROUTINES, R.string.watch_brief, NotificationManager.IMPORTANCE_DEFAULT)
        ch(CH_WORKING, R.string.watch_channel_runs, NotificationManager.IMPORTANCE_LOW)
        ch(CH_OTHER, R.string.watch_channel_other, NotificationManager.IMPORTANCE_DEFAULT)
    }

    fun id(push: WatchPush): Int = push.key.hashCode()

    /**
     * Draws [push]. [title] and [body] are the words to show (the push's own, or what the watch
     * loaded itself when the push carried none); [quickReplies] are the person's (§6.2).
     */
    fun draw(
        context: Context,
        push: WatchPush,
        title: String,
        body: String,
        allow: AllowLevel?,
        quickReplies: List<String>,
        note: String? = null,
    ) {
        if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) return
        val nid = id(push)
        val channel = when (push.kind) {
            WatchPush.Kind.APPROVAL, WatchPush.Kind.SUGGESTION, WatchPush.Kind.TAKEOVER -> CH_NEEDS
            WatchPush.Kind.REPLY, WatchPush.Kind.FAILED -> CH_REPLIES
            WatchPush.Kind.BRIEF, WatchPush.Kind.ROUTINE -> CH_ROUTINES
            else -> CH_OTHER
        }
        val text = listOfNotNull(body.takeIf { it.isNotBlank() }, note).joinToString("\n")
        val b = NotificationCompat.Builder(context, channel)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
            .setAutoCancel(true)
            .setGroup(GROUP)
            .setOnlyAlertOnce(note != null)
            .setCategory(
                when (push.kind) {
                    WatchPush.Kind.REPLY -> NotificationCompat.CATEGORY_MESSAGE
                    WatchPush.Kind.APPROVAL, WatchPush.Kind.SUGGESTION -> NotificationCompat.CATEGORY_REMINDER
                    else -> NotificationCompat.CATEGORY_STATUS
                },
            )
        push.botName?.let { b.setLargeIcon(BotArt.bitmap(context, it, push.botAvatar, 96)) }
        b.setContentIntent(Routes.pending(context, contentRoute(push)))

        when (push.kind) {
            WatchPush.Kind.APPROVAL -> {
                val id = push.approvalId!!
                when {
                    Logic.pushAllows(push, allow) ->
                        b.addAction(R.drawable.ic_check, context.getString(R.string.watch_allow), action(context, ActionReceiver.ALLOW, push, nid))
                    // Medium risk opens the request, where Allow is a hold (§6.2).
                    push.risk == Risk.MEDIUM && allow == AllowLevel.MEDIUM ->
                        b.addAction(R.drawable.ic_check, context.getString(R.string.watch_allow), Routes.pending(context, Routes.request(id)))
                    else ->
                        b.addAction(R.drawable.ic_phone, context.getString(R.string.watch_review), Routes.pending(context, Routes.request(id)))
                }
                b.addAction(R.drawable.ic_close, context.getString(R.string.watch_deny), action(context, ActionReceiver.DENY, push, nid))
            }
            WatchPush.Kind.SUGGESTION -> {
                b.addAction(R.drawable.ic_check, context.getString(R.string.watch_do_it), action(context, ActionReceiver.DO_IT, push, nid))
                b.addAction(R.drawable.ic_close, context.getString(R.string.watch_not_now), action(context, ActionReceiver.NOT_NOW, push, nid))
            }
            WatchPush.Kind.REPLY -> {
                if (push.botId != null && push.conversationId != null) {
                    val input = RemoteInput.Builder(REPLY_KEY)
                        .setLabel(context.getString(R.string.watch_reply))
                        .setChoices(quickReplies.toTypedArray())
                        .setAllowFreeFormInput(true)
                        .build()
                    val reply = NotificationCompat.Action.Builder(
                        R.drawable.ic_mic,
                        context.getString(R.string.watch_reply),
                        action(context, ActionReceiver.REPLY, push, nid, mutable = true),
                    ).addRemoteInput(input).setAllowGeneratedReplies(false).build()
                    b.addAction(reply)
                }
                b.addAction(R.drawable.ic_phone, context.getString(R.string.watch_open_on_phone), action(context, ActionReceiver.OPEN_ON_PHONE, push, nid))
            }
            WatchPush.Kind.BRIEF, WatchPush.Kind.ROUTINE -> {
                b.addAction(R.drawable.ic_speaker, context.getString(R.string.watch_read_aloud), Routes.pending(context, contentRoute(push), readAloud = true))
            }
            WatchPush.Kind.FAILED -> Unit
            else -> {
                b.addAction(R.drawable.ic_phone, context.getString(R.string.watch_open_on_phone), action(context, ActionReceiver.OPEN_ON_PHONE, push, nid))
            }
        }
        notify(context, nid, b)
    }

    /** After a button worked: the words of what happened, then the notification goes by itself. */
    fun done(context: Context, nid: Int, title: String, text: String) {
        val b = NotificationCompat.Builder(context, CH_OTHER)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(text)
            .setSilent(true)
            .setGroup(GROUP)
            .setTimeoutAfter(2_500)
        notify(context, nid, b)
    }

    fun cancel(context: Context, nid: Int) = NotificationManagerCompat.from(context).cancel(nid)

    fun cancelAll(context: Context) = NotificationManagerCompat.from(context).cancelAll()

    private fun notify(context: Context, nid: Int, b: NotificationCompat.Builder) {
        try {
            NotificationManagerCompat.from(context).notify(nid, b.build())
        } catch (_: SecurityException) {
            // Notifications are off for the app: the app's Now screen still has it.
        }
    }

    private fun contentRoute(p: WatchPush): String = when (p.kind) {
        WatchPush.Kind.APPROVAL -> Routes.request(p.approvalId!!)
        WatchPush.Kind.SUGGESTION -> Routes.suggestion(p.suggestionId!!)
        WatchPush.Kind.REPLY, WatchPush.Kind.FAILED, WatchPush.Kind.ROUTINE ->
            p.botId?.let { Routes.chat(it, p.conversationId) } ?: Routes.NOW
        WatchPush.Kind.BRIEF -> Routes.BRIEF
        else -> Routes.NOW
    }

    private fun action(context: Context, what: String, p: WatchPush, nid: Int, mutable: Boolean = false): PendingIntent {
        val intent = Intent(context, ActionReceiver::class.java)
            .setAction("ai.casama.wear.$what")
            .putExtra(ActionReceiver.EXTRA_NOTIFICATION, nid)
            .putExtra(ActionReceiver.EXTRA_PUSH, toBundle(p))
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or (if (mutable) PendingIntent.FLAG_MUTABLE else PendingIntent.FLAG_IMMUTABLE)
        return PendingIntent.getBroadcast(context, (nid.toString() + what).hashCode(), intent, flags)
    }

    fun toBundle(p: WatchPush): Bundle = Bundle().apply {
        putString("kind", p.kind.name.lowercase())
        putString("link", p.link)
        putString("bot_id", p.botId)
        putString("bot_name", p.botName)
        putString("bot_avatar", p.botAvatar)
        putString("approval_id", p.approvalId)
        putString("risk", p.risk?.name?.lowercase())
        putString("suggestion_id", p.suggestionId)
        putString("conversation_id", p.conversationId)
        putString("message_id", p.messageId)
        putString("run_id", p.runId)
        putString("title", p.title)
        putString("body", p.body)
    }

    fun fromBundle(b: Bundle?): WatchPush? {
        b ?: return null
        val map = b.keySet().mapNotNull { k -> b.getString(k)?.let { k to it } }.toMap()
        return WatchPush.parse(map)
    }
}
