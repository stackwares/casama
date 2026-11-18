package ai.casama.wear.core

import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/** Request bodies for the watch routes (packages/contracts/src/watch.ts). */
object Encode {
    /** What a watch says about itself (WatchDevice), shared by the code request and the phone link. */
    data class Device(
        val name: String,
        val model: String?,
        val appVersion: String?,
        val osVersion: String?,
    )

    /** POST /v1/watch/codes (WatchCodeRequest). */
    fun codeRequest(fingerprint: String, device: Device): String = buildJsonObject {
        put("fingerprint", fingerprint)
        put("platform", "wearos")
        put("name", device.name.take(80).ifBlank { "Wear OS" })
        device.model?.takeIf { it.isNotBlank() }?.let { put("model", it.take(80)) }
        device.appVersion?.let { put("app_version", it.take(40)) }
        device.osVersion?.let { put("os_version", it.take(40)) }
    }.toString()

    /** PUT /v1/watch-keys/current (WatchSelfUpdate). A null token clears it. */
    fun selfUpdate(pushToken: String?, appVersion: String?, osVersion: String?): String = buildJsonObject {
        put("push_token", pushToken)
        if (pushToken != null) put("push_kind", "fcm")
        appVersion?.let { put("app_version", it.take(40)) }
        osVersion?.let { put("os_version", it.take(40)) }
    }.toString()

    /** POST /v1/watch/ask (WatchAsk): text, or a recording as base64. */
    fun ask(
        botId: String,
        conversationId: String?,
        text: String?,
        audioBase64: String?,
        audioMime: String?,
        language: String?,
        askedAtIso: String?,
        surface: String,
    ): String = buildJsonObject {
        put("bot_id", botId)
        conversationId?.let { put("conversation_id", it) }
        text?.takeIf { it.isNotBlank() }?.let { put("text", it.take(4000)) }
        if (audioBase64 != null && audioMime != null) {
            put("audio", buildJsonObject {
                put("data", audioBase64)
                put("mime", audioMime)
            })
        }
        language?.takeIf { it.isNotBlank() }?.let { put("language", it.take(20)) }
        askedAtIso?.let { put("asked_at", it) }
        put("surface", surface)
    }.toString()

    /** POST /v1/approvals/{id}/decision. Never `always_allow`: a phone decision (§6.1 B). */
    fun decision(allow: Boolean): String = buildJsonObject {
        put("decision", if (allow) "approved" else "denied")
    }.toString()

    /** POST /v1/suggestions/{id}/dismiss. */
    fun dismiss(): String = buildJsonObject { put("dont_suggest_again", false) }.toString()

    /** POST /v1/watch/handoff. Links must be app routes ("/…"). */
    fun handoff(link: String, title: String): String = buildJsonObject {
        put("link", if (link.startsWith("/")) link.take(300) else "/")
        put("title", title.take(100).ifBlank { "Casama" })
    }.toString()

    /** An empty JSON body for POSTs that take none. */
    const val EMPTY = "{}"
}
