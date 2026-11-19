package ai.casama.wear.data

import ai.casama.wear.core.AskQueue
import ai.casama.wear.core.Encode
import ai.casama.wear.core.QueuedAsk
import ai.casama.wear.graph
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

    /**
     * Sends [item] with its own idempotency key. True when it went (or the server already had
     * it); false when still offline. Other refusals drop it: retrying won't change the answer.
     */
    suspend fun send(item: QueuedAsk): Boolean {
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
            true
        } catch (e: ApiError.Offline) {
            false
        } catch (e: ApiError.RateLimited) {
            false
        } catch (e: ApiError.Server) {
            false
        } catch (e: ApiError) {
            remove(item.id)
            true
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
            if (!outbox.send(item)) return Result.retry()
        }
        return Result.success()
    }
}
