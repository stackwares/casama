package ai.casama.wear.data

import ai.casama.wear.core.AskQueue
import ai.casama.wear.core.Encode
import ai.casama.wear.core.QueuedAsk
import ai.casama.wear.graph
import ai.casama.wear.notify.Notifier
import android.content.Context
import android.util.Base64
import androidx.core.content.edit
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import java.io.File
import java.time.Instant
import java.util.Locale

/**
 * Asks kept while the watch was offline (§6.1 C), sent by [OutboxWorker] once a network is back.
 * Ones kept longer than ten minutes wait for the person to say Send (Now and Ask show them).
 */
class AskOutbox(private val context: Context) {
    private val prefs = context.getSharedPreferences("casama_outbox", Context.MODE_PRIVATE)

    @Synchronized
    fun items(): List<QueuedAsk> = AskQueue.decode(prefs.getString(K_ITEMS, null))

    @Synchronized
    fun keep(item: QueuedAsk) {
        save(AskQueue.add(items(), item))
        schedule(context)
    }

    @Synchronized
    fun remove(id: String) {
        items().firstOrNull { it.id == id }?.audioPath?.let { File(it).delete() }
        save(AskQueue.remove(items(), id))
    }

    /** Ones waiting for the person to say Send or Discard. */
    fun awaitingConfirm(now: Long = System.currentTimeMillis()): List<QueuedAsk> = AskQueue.split(items(), now).askFirst

    fun clear() {
        items().forEach { it.audioPath?.let { p -> File(p).delete() } }
        prefs.edit { remove(K_ITEMS) }
    }

    private fun save(list: List<QueuedAsk>) = prefs.edit { putString(K_ITEMS, AskQueue.encode(list)) }

    /** How sending a kept ask went. */
    enum class Sent {
        /** It went, or the server already had it. */
        YES,
        /** No connection, a busy server or a rate limit: it stays and is tried again. */
        LATER,
        /** The server won't take it (and answers the same to every retry): removed. */
        DROPPED,
    }

    /**
     * Sends [item] with its own idempotency key. The server stores its answer to a key, so a
     * refusal (nothing heard, a bad recording, a bot that's gone) would be replayed on every
     * retry: those are dropped, never kept to fail forever.
     */
    suspend fun send(item: QueuedAsk): Sent {
        val session = context.graph.session
        val body = Encode.ask(
            botId = item.botId,
            conversationId = item.conversationId,
            text = item.text,
            audioBase64 = item.audioPath?.let { p -> File(p).takeIf { it.exists() }?.readBytes()?.let { Base64.encodeToString(it, Base64.NO_WRAP) } },
            audioMime = item.audioMime,
            language = Locale.getDefault().toLanguageTag(),
            askedAtIso = Instant.ofEpochMilli(item.askedAt).toString(),
            surface = item.surface,
        )
        return try {
            session.call { ask(body, item.id) }
            remove(item.id)
            Sent.YES
        } catch (e: ApiError.Offline) {
            Sent.LATER
        } catch (e: ApiError.RateLimited) {
            Sent.LATER
        } catch (e: ApiError.Server) {
            Sent.LATER
        } catch (e: ApiError.SignedOut) {
            // The session wiped everything, this ask with it.
            Sent.LATER
        } catch (e: ApiError.Bad) {
            // The server took it; only its answer couldn't be read.
            remove(item.id)
            Sent.YES
        } catch (e: ApiError) {
            remove(item.id)
            Sent.DROPPED
        }
    }

    companion object {
        private const val K_ITEMS = "items"
        private const val WORK = "casama_outbox"

        fun schedule(context: Context) {
            val request = OneTimeWorkRequestBuilder<OutboxWorker>()
                .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                .build()
            WorkManager.getInstance(context).enqueueUniqueWork(WORK, ExistingWorkPolicy.REPLACE, request)
        }
    }
}

/** Sends the fresh kept asks when a network is back; old ones wait for the person. */
class OutboxWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val outbox = AskOutbox(applicationContext)
        if (!applicationContext.graph.session.isSignedIn) return Result.success()
        val split = AskQueue.split(outbox.items(), System.currentTimeMillis())
        split.dropped.forEach { outbox.remove(it.id) }
        for (item in split.sendNow) {
            when (outbox.send(item)) {
                AskOutbox.Sent.YES -> Unit
                AskOutbox.Sent.LATER -> return Result.retry()
                // Nobody is looking at a screen: say it where it will be seen.
                AskOutbox.Sent.DROPPED -> Notifier.askDropped(applicationContext, item.askedAt)
            }
        }
        return Result.success()
    }
}
