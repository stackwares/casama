package ai.casama.wear.notify

import ai.casama.wear.R
import ai.casama.wear.core.CanAllow
import ai.casama.wear.core.Encode
import ai.casama.wear.core.Logic
import ai.casama.wear.core.QueuedAsk
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
import kotlinx.coroutines.withTimeoutOrNull

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
            // Tiles and complications catch up after the answer, outside the button's own time:
            // a slow refresh must never turn "Allowed" into "Couldn't reach Casama".
            runCatching { graph.session.refresh() }
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
                    // The same notification and words give the same key, so a retry after a
                    // timeout that did arrive can't send the reply twice.
                    val key = (push.notificationId ?: push.messageId)?.let { Logic.replyKey(it, text) } ?: WatchApi.newKey()
                    // Cut off before the receiver's own limit, so a link that hangs still ends
                    // in "kept", not in a lost reply.
                    val went = try {
                        withTimeoutOrNull(7_000) { session.call { ask(body, key) } } != null
                    } catch (e: ApiError) {
                        if (e !is ApiError.Offline && e !is ApiError.Server && e !is ApiError.RateLimited) throw e
                        false
                    }
                    if (!went) {
                        // No connection: kept like any other ask (with the same key), and sent
                        // when the watch is back.
                        graph.outbox.keep(QueuedAsk(key, push.botId, push.conversationId, text, null, null, System.currentTimeMillis(), "notification"))
                        Notifier.done(context, nid, context.getString(R.string.watch_kept_offline), text)
                        return
                    }
                    graph.haptics.done()
                    Notifier.done(context, nid, context.getString(R.string.watch_reply_sent), text)
                }
                OPEN_ON_PHONE -> {
                    val title = PushWords.of(context, push).first
                    val opened = PhoneLink.openOnPhone(context, push.link, title) ||
                        runCatching { session.call { handoff(push.link, title) } }.isSuccess
                    Notifier.done(
                        context,
                        nid,
                        context.getString(if (opened) R.string.watch_sent_to_phone else R.string.watch_couldnt_reach),
                        bot,
                    )
                }
            }
        } catch (e: ApiError.Conflict) {
            if (Logic.conflict(e.code) == Logic.ConflictKind.OVER) {
                Notifier.done(context, nid, context.getString(R.string.watch_already_answered), bot)
            } else {
                // Do It on a run the server couldn't start (the bot has no model, say): the
                // suggestion is kept, so never "Already answered". The phone says why.
                graph.haptics.problem()
                redraw(context, push, context.getString(R.string.watch_not_on_watch), elsewhere = true)
            }
        } catch (e: ApiError.Refused) {
            // 402: a limit was reached and nothing started. Anything else is a plain failure.
            if (e.status != 402) throw e
            graph.haptics.problem()
            redraw(context, push, context.getString(R.string.watch_out_of_credits), elsewhere = true)
        } catch (e: ApiError.NotFound) {
            if (e.elsewhere) {
                // Not in this watch's workspace: only the phone can answer it.
                redraw(context, push, context.getString(R.string.watch_not_on_watch), elsewhere = true)
            } else {
                Notifier.done(context, nid, context.getString(R.string.watch_already_answered), bot)
            }
        } catch (e: ApiError.Forbidden) {
            // The server's limits said no (a setting changed since the push): the phone decides.
            graph.haptics.problem()
            redraw(context, push.copy(risk = null, canAllow = CanAllow.PHONE), context.getString(R.string.watch_review_on_phone))
        } catch (e: ApiError.SignedOut) {
            Notifier.cancel(context, nid)
        }
    }

    private fun redraw(context: Context, push: WatchPush, note: String, elsewhere: Boolean = false) {
        val graph = context.graph
        val words = PushWords.of(context, push)
        val otherWorkspace = Logic.elsewhere(push.orgId, graph.settings.orgId)
        Notifier.draw(
            context,
            push,
            title = words.first,
            body = words.second,
            allow = graph.session.self.value?.prefs?.allow,
            quickReplies = PushSetup.quickReplies(context),
            note = note,
            elsewhere = elsewhere || otherWorkspace,
            otherWorkspace = otherWorkspace,
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
