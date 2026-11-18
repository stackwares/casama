package ai.casama.wear.notify

import ai.casama.wear.R
import ai.casama.wear.core.Encode
import ai.casama.wear.core.WatchPush
import ai.casama.wear.data.ApiError
import ai.casama.wear.data.WatchApi
import ai.casama.wear.graph
import ai.casama.wear.link.PhoneLink
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.RemoteInput
import java.util.Locale
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout

/**
 * A notification's buttons, answered on the watch (§6.2): Allow, Deny, Do It, Not now, a spoken or
 * quick Reply, Open on phone. The call runs in the app's scope under goAsync, so it can finish
 * after the receiver returns; it is cut off well before the system's ten seconds.
 */
class ActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val what = intent.action?.substringAfterLast('.') ?: return
        val push = Notifier.fromBundle(intent.getBundleExtra(EXTRA_PUSH)) ?: return
        val nid = intent.getIntExtra(EXTRA_NOTIFICATION, 0)
        val reply = RemoteInput.getResultsFromIntent(intent)?.getCharSequence(Notifier.REPLY_KEY)?.toString()
        val pending = goAsync()
        val graph = context.applicationContext.graph
        graph.scope.launch {
            try {
                withTimeout(9_000) { handle(context.applicationContext, what, push, nid, reply) }
            } catch (_: Exception) {
                graph.haptics.problem()
                redraw(context.applicationContext, push, context.getString(R.string.watch_couldnt_reach))
            } finally {
                pending.finish()
            }
        }
    }

    private suspend fun handle(context: Context, what: String, push: WatchPush, nid: Int, reply: String?) {
        val graph = context.graph
        val session = graph.session
        val bot = push.botName.orEmpty()
        try {
            when (what) {
                ALLOW -> {
                    session.call { decide(push.approvalId!!, allow = true, idempotencyKey = "n-allow-${push.approvalId}") }
                    graph.haptics.done()
                    Notifier.done(context, nid, context.getString(R.string.watch_allowed), bot)
                }
                DENY -> {
                    session.call { decide(push.approvalId!!, allow = false, idempotencyKey = "n-deny-${push.approvalId}") }
                    graph.haptics.done()
                    Notifier.done(context, nid, context.getString(R.string.watch_denied), bot)
                }
                DO_IT -> {
                    session.call { acceptSuggestion(push.suggestionId!!, "n-do-${push.suggestionId}") }
                    graph.haptics.done()
                    Notifier.done(context, nid, context.getString(R.string.watch_started), bot)
                }
                NOT_NOW -> {
                    session.call { dismissSuggestion(push.suggestionId!!, "n-later-${push.suggestionId}") }
                    Notifier.cancel(context, nid)
                }
                REPLY -> {
                    val text = reply?.trim().orEmpty()
                    if (text.isEmpty()) return
                    val body = Encode.ask(
                        botId = push.botId!!,
                        conversationId = push.conversationId,
                        text = text,
                        audioBase64 = null,
                        audioMime = null,
                        language = Locale.getDefault().toLanguageTag(),
                        askedAtIso = null,
                        surface = "notification",
                    )
                    session.call { ask(body, WatchApi.newKey()) }
                    graph.haptics.done()
                    Notifier.done(context, nid, context.getString(R.string.watch_sending), text)
                }
                OPEN_ON_PHONE -> {
                    val opened = PhoneLink.openOnPhone(context, push.link) ||
                        runCatching { session.call { handoff(push.link, push.title ?: bot) } }.isSuccess
                    Notifier.done(
                        context,
                        nid,
                        context.getString(if (opened) R.string.watch_sent_to_phone else R.string.watch_couldnt_reach),
                        bot,
                    )
                }
            }
            session.refresh()
        } catch (e: ApiError.Conflict) {
            Notifier.done(context, nid, context.getString(R.string.watch_already_answered), bot)
        } catch (e: ApiError.NotFound) {
            Notifier.done(context, nid, context.getString(R.string.watch_already_answered), bot)
        } catch (e: ApiError.Forbidden) {
            // The server's limits said no (a setting changed since the push): the phone decides.
            graph.haptics.problem()
            redraw(context, push.copy(risk = null), context.getString(R.string.watch_review_on_phone))
        } catch (e: ApiError.SignedOut) {
            Notifier.cancel(context, nid)
        }
    }

    private fun redraw(context: Context, push: WatchPush, note: String) {
        val self = context.graph.session.self.value
        Notifier.draw(
            context,
            push,
            title = push.title ?: push.botName.orEmpty(),
            body = push.body.orEmpty(),
            allow = self?.prefs?.allow,
            quickReplies = PushSetup.quickReplies(context),
            note = note,
        )
    }

    companion object {
        const val ALLOW = "ALLOW"
        const val DENY = "DENY"
        const val DO_IT = "DO_IT"
        const val NOT_NOW = "NOT_NOW"
        const val REPLY = "REPLY"
        const val OPEN_ON_PHONE = "OPEN_ON_PHONE"
        const val EXTRA_NOTIFICATION = "casama_notification"
        const val EXTRA_PUSH = "casama_push"
    }
}
