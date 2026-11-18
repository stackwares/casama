package ai.casama.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.Person
import androidx.core.graphics.drawable.IconCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Live calls in the background (D-327 §7): a microphone foreground service holding an ongoing
 * call notification (CallStyle: the bot, the timer, Mute and End Call), so the call keeps the mic
 * with the screen off or another app in front. Flutter starts it when a call starts, while the app
 * is in front (Android lets a service start using the mic only then), over `casama/call_service`.
 * Buttons come back to Flutter as `action` calls; the call itself stays in Flutter.
 */
object CallBridge {
    var channel: MethodChannel? = null
    private val main = Handler(Looper.getMainLooper())

    fun send(action: String) {
        main.post { channel?.invokeMethod("action", mapOf("action" to action)) }
    }

    fun handle(context: Context, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                CallService.state = CallService.State(
                    bot = call.argument<String>("bot") ?: "Casama",
                    avatar = call.argument<String>("avatar"),
                    labels = CallService.Labels(
                        live = call.argument<String>("live") ?: "On a call",
                        muted = call.argument<String>("muted") ?: "Muted",
                        reconnecting = call.argument<String>("reconnecting") ?: "Reconnecting",
                        mute = call.argument<String>("mute") ?: "Mute",
                        unmute = call.argument<String>("unmute") ?: "Unmute",
                        end = call.argument<String>("end") ?: "End Call",
                        channel = call.argument<String>("channel") ?: "Calls",
                    ),
                )
                try {
                    ContextCompat.startForegroundService(
                        context,
                        Intent(context, CallService::class.java).setAction(CallService.ACTION_SHOW),
                    )
                    result.success(null)
                } catch (e: Exception) {
                    // Started from the background, or the microphone permission is missing.
                    CallService.state = null
                    result.error("failed", e.message, null)
                }
            }
            "connected" -> {
                CallService.state?.since = call.argument<Number>("since")?.toLong() ?: System.currentTimeMillis()
                CallService.refresh(context)
                result.success(null)
            }
            "update" -> {
                CallService.state?.let {
                    it.muted = call.argument<Boolean>("muted") ?: it.muted
                    it.reconnecting = call.argument<Boolean>("reconnecting") ?: it.reconnecting
                }
                CallService.refresh(context)
                result.success(null)
            }
            "stop" -> {
                CallService.stop(context)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}

class CallService : Service() {
    class Labels(
        val live: String,
        val muted: String,
        val reconnecting: String,
        val mute: String,
        val unmute: String,
        val end: String,
        val channel: String,
    )

    class State(
        val bot: String,
        /** The bot's icon as it stores it (`mascot:<name>`); null draws its initials. */
        val avatar: String? = null,
        val labels: Labels,
        var since: Long = 0,
        var muted: Boolean = false,
        var reconnecting: Boolean = false,
    )

    companion object {
        const val CHANNEL_ID = "casama_calls"
        const val NOTIFICATION_ID = 3270
        const val ACTION_SHOW = "ai.casama.app.call.SHOW"
        const val ACTION_MUTE = "ai.casama.app.call.MUTE"
        const val ACTION_UNMUTE = "ai.casama.app.call.UNMUTE"
        const val ACTION_END = "ai.casama.app.call.END"
        const val ACTION_OPEN = "ai.casama.app.call.OPEN"

        @Volatile
        var state: State? = null

        /** Redraws the notification (mute, reconnecting, the timer's start). */
        fun refresh(context: Context) {
            val s = state ?: return
            val nm = context.getSystemService(NotificationManager::class.java) ?: return
            nm.notify(NOTIFICATION_ID, build(context, s))
        }

        fun stop(context: Context) {
            state = null
            context.stopService(Intent(context, CallService::class.java))
        }

        private fun ensureChannel(context: Context, name: String) {
            val nm = context.getSystemService(NotificationManager::class.java) ?: return
            if (nm.getNotificationChannel(CHANNEL_ID) != null) return
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, name, NotificationManager.IMPORTANCE_DEFAULT).apply {
                    setSound(null, null)
                    enableVibration(false)
                },
            )
        }

        private fun serviceIntent(context: Context, action: String, code: Int) = PendingIntent.getService(
            context,
            code,
            Intent(context, CallService::class.java).setAction(action),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        fun build(context: Context, s: State): Notification {
            ensureChannel(context, s.labels.channel)
            val open = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java)
                    .setAction(ACTION_OPEN)
                    .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            // The bot as the app draws it (its mascot or initials), on the call card and the chip.
            val mark = BotArt.bitmap(context, s.bot, s.avatar, (48 * context.resources.displayMetrics.density).toInt())
            val bot = Person.Builder().setName(s.bot).setIcon(IconCompat.createWithBitmap(mark)).setImportant(true).build()
            val text = when {
                s.reconnecting -> s.labels.reconnecting
                s.muted -> s.labels.muted
                else -> s.labels.live
            }
            val b = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle(s.bot)
                .setContentText(text)
                .setLargeIcon(mark)
                .setContentIntent(open)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setSilent(true)
                .setCategory(NotificationCompat.CATEGORY_CALL)
                .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
                .setStyle(
                    NotificationCompat.CallStyle.forOngoingCall(bot, serviceIntent(context, ACTION_END, 1)),
                )
                .addAction(
                    NotificationCompat.Action.Builder(
                        R.drawable.ic_notification,
                        if (s.muted) s.labels.unmute else s.labels.mute,
                        serviceIntent(context, if (s.muted) ACTION_UNMUTE else ACTION_MUTE, 2),
                    ).build(),
                )
            if (s.since > 0) b.setWhen(s.since).setShowWhen(true).setUsesChronometer(true)
            return b.build()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_MUTE -> CallBridge.send("mute")
            ACTION_UNMUTE -> CallBridge.send("unmute")
            ACTION_END -> CallBridge.send("end")
        }
        val s = state
        if (s == null) {
            stopSelf()
            return START_NOT_STICKY
        }
        val n = build(this, s)
        if (Build.VERSION.SDK_INT >= 30) {
            startForeground(NOTIFICATION_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
        } else {
            startForeground(NOTIFICATION_ID, n)
        }
        return START_NOT_STICKY
    }

    // Swiped away from recents: the call ends with the app (its turns are saved; the server bills it).
    override fun onTaskRemoved(rootIntent: Intent?) {
        state = null
        stopSelf()
    }

    override fun onDestroy() {
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }
}
