package ai.casama.wear.core

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * Asks kept while offline (§6.1 C). Each keeps the idempotency key it will be sent with, so a
 * retry after a dropped connection can't ask twice. One kept for more than ten minutes asks the
 * person before it goes; one older than a day is dropped (nobody wants yesterday's question
 * answered by surprise, and the recording would be stale).
 */
data class QueuedAsk(
    /** Also the Idempotency-Key. */
    val id: String,
    val botId: String,
    val conversationId: String?,
    val text: String?,
    /** A recording in the app's own files, sent as base64 when the watch is back online. */
    val audioPath: String?,
    val audioMime: String?,
    val askedAt: Long,
    val surface: String,
)

object AskQueue {
    const val CONFIRM_AFTER_MS = 10 * 60 * 1000L
    const val DROP_AFTER_MS = 24 * 60 * 60 * 1000L
    const val MAX = 10

    data class Split(val sendNow: List<QueuedAsk>, val askFirst: List<QueuedAsk>, val dropped: List<QueuedAsk>)

    fun needsConfirm(item: QueuedAsk, now: Long): Boolean = now - item.askedAt > CONFIRM_AFTER_MS

    /** What to send without asking, what to ask about first, and what is too old to keep. */
    fun split(items: List<QueuedAsk>, now: Long): Split {
        val dropped = items.filter { now - it.askedAt > DROP_AFTER_MS }
        val kept = items - dropped.toSet()
        val (old, fresh) = kept.partition { needsConfirm(it, now) }
        return Split(fresh.sortedBy { it.askedAt }, old.sortedBy { it.askedAt }, dropped)
    }

    /** Adds [item] (replacing one with the same id), keeping the newest [MAX]. */
    fun add(items: List<QueuedAsk>, item: QueuedAsk): List<QueuedAsk> =
        (items.filter { it.id != item.id } + item).sortedBy { it.askedAt }.takeLast(MAX)

    fun remove(items: List<QueuedAsk>, id: String): List<QueuedAsk> = items.filter { it.id != id }

    fun encode(items: List<QueuedAsk>): String = buildJsonArray {
        for (i in items) add(buildJsonObject {
            put("id", i.id)
            put("bot_id", i.botId)
            put("conversation_id", i.conversationId)
            put("text", i.text)
            put("audio_path", i.audioPath)
            put("audio_mime", i.audioMime)
            put("asked_at", i.askedAt)
            put("surface", i.surface)
        })
    }.toString()

    fun decode(text: String?): List<QueuedAsk> {
        if (text.isNullOrBlank()) return emptyList()
        val arr = runCatching { kotlinx.serialization.json.Json.parseToJsonElement(text) as? JsonArray }.getOrNull()
            ?: return emptyList()
        return arr.mapNotNull { el ->
            val o = el as? JsonObject ?: return@mapNotNull null
            val id = o.strOrNull("id") ?: return@mapNotNull null
            val bot = o.strOrNull("bot_id") ?: return@mapNotNull null
            val text = o.strOrNull("text")
            val audio = o.strOrNull("audio_path")
            if (text.isNullOrBlank() && audio.isNullOrBlank()) return@mapNotNull null
            val at = o.prim("asked_at")?.content?.toLongOrNull() ?: return@mapNotNull null
            QueuedAsk(id, bot, o.strOrNull("conversation_id"), text, audio, o.strOrNull("audio_mime"), at, o.str("surface", "app"))
        }
    }
}
