package ai.casama.wear.ui

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri

/**
 * The app's screens as routes, shared by navigation, notifications, tiles and complications.
 * An empty id is written as "_" so every route has the same shape.
 */
object Routes {
    const val NOW = "now"
    const val NEEDS = "needs"
    const val BOTS = "bots"
    const val UP_NEXT = "upnext"
    const val BRIEF = "brief"
    const val SETTINGS = "settings"
    const val SIGN_IN = "signin"

    const val REQUEST = "request/{id}"
    const val SUGGESTION = "suggestion/{id}"
    const val ASK = "ask/{bot}/{listen}/{conv}"
    const val WORKING = "working/{run}"
    const val CHAT = "chat/{bot}/{conv}"
    const val TALK = "talk/{bot}"
    /**
     * Something this watch can't answer: its link and title, as hex, and "1" when it is known to
     * be in another workspace ("0": the server only said it isn't this watch's).
     */
    const val ELSEWHERE = "elsewhere/{link}/{title}/{other}"

    fun request(id: String) = "request/${enc(id)}"
    fun suggestion(id: String) = "suggestion/${enc(id)}"
    fun ask(botId: String?, listen: Boolean, conversationId: String? = null) = "ask/${enc(botId)}/${if (listen) 1 else 0}/${enc(conversationId)}"
    fun working(runId: String) = "working/${enc(runId)}"
    fun chat(botId: String, conversationId: String?) = "chat/${enc(botId)}/${enc(conversationId)}"
    fun talk(botId: String?) = "talk/${enc(botId)}"
    fun elsewhere(link: String, title: String?, otherWorkspace: Boolean) =
        "elsewhere/${hex(link.take(300))}/${hex(title.orEmpty().take(120))}/${if (otherWorkspace) 1 else 0}"

    /** Free text (a link, a title) as a route argument: hex of its UTF-8, "_" when empty. */
    private fun hex(text: String): String =
        text.toByteArray(Charsets.UTF_8).joinToString("") { "%02x".format(it.toInt() and 0xff) }.ifEmpty { "_" }

    /** The text of a [hex] argument; null when empty or not hex. */
    fun text(value: String?): String? {
        val h = arg(value) ?: return null
        if (h.length % 2 != 0) return null
        return runCatching { String(ByteArray(h.length / 2) { h.substring(it * 2, it * 2 + 2).toInt(16).toByte() }, Charsets.UTF_8) }.getOrNull()
    }

    fun arg(value: String?): String? = value?.takeIf { it.isNotEmpty() && it != "_" }

    private fun enc(id: String?): String = id?.filter { it.isLetterOrDigit() || it == '-' }?.ifEmpty { null } ?: "_"

    const val EXTRA_ROUTE = "casama_route"
    const val EXTRA_READ_ALOUD = "casama_read_aloud"

    fun intent(context: Context, route: String, readAloud: Boolean = false): Intent =
        Intent(context, MainActivity::class.java)
            .setAction(Intent.ACTION_VIEW)
            // A distinct data URI keeps PendingIntents for different routes apart.
            .setData(Uri.parse("casama-wear://open/$route"))
            .putExtra(EXTRA_ROUTE, route)
            .putExtra(EXTRA_READ_ALOUD, readAloud)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)

    fun pending(context: Context, route: String, readAloud: Boolean = false): PendingIntent =
        PendingIntent.getActivity(
            context,
            (route + readAloud).hashCode(),
            intent(context, route, readAloud),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    /** An app route the phone understands ("/approvals/<id>") from a push or a glance item. */
    fun fromLink(link: String): String? {
        val path = link.substringBefore('?')
        val parts = path.trim('/').split('/')
        return when {
            parts.size >= 2 && parts[0] == "approvals" -> request(parts[1])
            parts.size >= 3 && parts[0] == "bots" && parts[2] == "chat" ->
                chat(parts[1], Uri.parse("x://y$link").getQueryParameter("c"))
            else -> null
        }
    }
}
