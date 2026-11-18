package ai.casama.wear.data

import ai.casama.wear.core.Decode
import ai.casama.wear.core.Glance
import ai.casama.wear.core.WatchChat
import android.content.Context
import androidx.core.content.edit
import java.io.File

/**
 * The last glance and the last chats the watch showed (§10: "what the watch keeps"), so every
 * screen, tile and complication opens from what was saved, never a spinner. Wiped at sign-out.
 * Files are written whole to a temp file and renamed, so a crash never leaves half a file.
 */
class GlanceCache(context: Context) {
    private val dir = File(context.filesDir, "cache").apply { mkdirs() }
    private val prefs = context.getSharedPreferences("casama_cache", Context.MODE_PRIVATE)

    data class Saved(val glance: Glance, val savedAt: Long, val etag: String?)

    @Volatile private var memo: Saved? = null

    fun glance(): Saved? {
        memo?.let { return it }
        val file = File(dir, GLANCE)
        if (!file.exists()) return null
        return runCatching { Saved(Decode.glance(file.readText()), prefs.getLong(K_SAVED, 0L), prefs.getString(K_ETAG, null)) }
            .getOrNull()
            ?.also { memo = it }
    }

    fun saveGlance(raw: String, glance: Glance, etag: String?, now: Long) {
        write(GLANCE, raw)
        prefs.edit {
            putLong(K_SAVED, now)
            putString(K_ETAG, etag)
        }
        memo = Saved(glance, now, etag)
    }

    /** A 304: the saved glance is still true as of [now]. */
    fun touch(now: Long) {
        prefs.edit { putLong(K_SAVED, now) }
        memo = memo?.copy(savedAt = now)
    }

    fun chat(botId: String): WatchChat? =
        runCatching { File(dir, chatFile(botId)).takeIf { it.exists() }?.readText()?.let { Decode.chat(it) } }.getOrNull()

    fun saveChat(botId: String, raw: String) = write(chatFile(botId), raw)

    fun wipe() {
        memo = null
        dir.listFiles()?.forEach { it.delete() }
        prefs.edit { clear() }
    }

    private fun chatFile(botId: String) = "chat_" + botId.filter { it.isLetterOrDigit() || it == '-' } + ".json"

    private fun write(name: String, text: String) {
        val tmp = File(dir, "$name.tmp")
        tmp.writeText(text)
        if (!tmp.renameTo(File(dir, name))) {
            File(dir, name).writeText(text)
            tmp.delete()
        }
    }

    private companion object {
        const val GLANCE = "glance.json"
        const val K_SAVED = "glance_saved_at"
        const val K_ETAG = "glance_etag"
    }
}
