package ai.casama.wear.core

/**
 * A data-only push sent to the watch's own Firebase token (docs/WATCH-PROTOCOL.md §4). All values
 * are strings. With private notifications on, `title` and `body` are absent and the watch loads
 * what happened itself with its key.
 */
data class WatchPush(
    val kind: Kind,
    val link: String,
    val botId: String?,
    val botName: String?,
    val botAvatar: String?,
    val approvalId: String?,
    val risk: Risk?,
    val suggestionId: String?,
    val conversationId: String?,
    val messageId: String?,
    val runId: String?,
    val title: String?,
    val body: String?,
) {
    enum class Kind { APPROVAL, SUGGESTION, REPLY, FAILED, BRIEF, ROUTINE, TAKEOVER, OTHER, GLANCE }

    /** One notification per thing: an approval, a suggestion, a chat, or the link. */
    val key: String
        get() = when (kind) {
            Kind.APPROVAL -> "approval:${approvalId ?: link}"
            Kind.SUGGESTION -> "suggestion:${suggestionId ?: link}"
            Kind.REPLY, Kind.FAILED -> "chat:${conversationId ?: runId ?: link}"
            else -> "${kind.name.lowercase()}:${messageId ?: runId ?: link}"
        }

    companion object {
        fun parse(data: Map<String, String>): WatchPush? {
            // `watch_kind` holds the watch's kinds (WATCH-PROTOCOL §4); `kind` keeps the phone's
            // own values and is read only when it is absent (a glance nudge, an older server).
            val kind = when (data["watch_kind"] ?: data["kind"]) {
                "approval", "approval_request" -> Kind.APPROVAL
                "routine_result" -> Kind.ROUTINE
                "suggestion" -> Kind.SUGGESTION
                "reply" -> Kind.REPLY
                "failed" -> Kind.FAILED
                "brief" -> Kind.BRIEF
                "routine" -> Kind.ROUTINE
                "takeover" -> Kind.TAKEOVER
                // A refresh nudge for tiles and complications, with no content (D-405 pushes).
                "glance" -> Kind.GLANCE
                null, "" -> return null
                else -> Kind.OTHER
            }
            fun s(k: String) = data[k]?.takeIf { it.isNotBlank() }
            val p = WatchPush(
                kind = kind,
                link = s("link")?.takeIf { it.startsWith("/") } ?: "/",
                botId = s("bot_id"),
                botName = s("bot_name"),
                botAvatar = s("bot_avatar"),
                approvalId = s("approval_id"),
                risk = when (s("risk")) {
                    "low" -> Risk.LOW
                    "medium" -> Risk.MEDIUM
                    "high" -> Risk.HIGH
                    else -> null
                },
                suggestionId = s("suggestion_id"),
                conversationId = s("conversation_id"),
                messageId = s("message_id"),
                runId = s("run_id"),
                title = s("title"),
                body = s("body"),
            )
            // Without its id an approval or suggestion can't be answered: show it as "open on phone".
            return when {
                kind == Kind.APPROVAL && p.approvalId == null -> p.copy(kind = Kind.OTHER)
                kind == Kind.SUGGESTION && p.suggestionId == null -> p.copy(kind = Kind.OTHER)
                else -> p
            }
        }
    }
}
