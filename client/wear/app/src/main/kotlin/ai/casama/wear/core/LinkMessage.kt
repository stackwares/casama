package ai.casama.wear.core

import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * Messages on the phone link (docs/WATCH-PROTOCOL.md §2): Data Layer path `/casama/watch`, body
 * UTF-8 JSON with a `type`. The phone side (client/android WearBridge.kt) speaks the same.
 */
sealed class LinkMessage {
    // watch -> phone
    data class SignIn(
        val requestId: String,
        val fingerprint: String,
        val device: Encode.Device,
    ) : LinkMessage()

    data class Open(val link: String) : LinkMessage()

    // phone -> watch
    data class SignedIn(
        val requestId: String,
        val server: String,
        val orgId: String,
        val orgName: String,
        val personName: String,
    ) : LinkMessage()

    data class SignInFailed(val requestId: String, val reason: String) : LinkMessage()

    data class Context(val server: String, val orgId: String, val orgName: String, val personName: String) : LinkMessage()

    data object SignOut : LinkMessage()

    fun encode(): String = when (this) {
        is SignIn -> buildJsonObject {
            put("type", "sign_in")
            put("request_id", requestId)
            put("fingerprint", fingerprint)
            put("platform", "wearos")
            put("name", device.name)
            device.model?.let { put("model", it) }
            device.appVersion?.let { put("app_version", it) }
            device.osVersion?.let { put("os_version", it) }
        }
        is Open -> buildJsonObject {
            put("type", "open")
            put("link", link)
        }
        is SignedIn -> buildJsonObject {
            put("type", "signed_in")
            put("request_id", requestId)
            put("server", server)
            put("org_id", orgId)
            put("org_name", orgName)
            put("person_name", personName)
        }
        is SignInFailed -> buildJsonObject {
            put("type", "sign_in_failed")
            put("request_id", requestId)
            put("reason", reason)
        }
        is Context -> buildJsonObject {
            put("type", "context")
            put("server", server)
            put("org_id", orgId)
            put("org_name", orgName)
            put("person_name", personName)
        }
        SignOut -> buildJsonObject { put("type", "sign_out") }
    }.toString()

    companion object {
        const val PATH = "/casama/watch"
        const val PHONE_CAPABILITY = "casama_phone"
        const val WATCH_CAPABILITY = "casama_watch"

        /** Null for anything unreadable or of an unknown type (a newer phone may send more). */
        fun decode(bytes: ByteArray): LinkMessage? = decode(bytes.toString(Charsets.UTF_8))

        fun decode(text: String): LinkMessage? {
            val o: JsonObject = runCatching { Decode.parse(text) }.getOrNull() ?: return null
            return when (o.str("type")) {
                "sign_in" -> SignIn(
                    o.str("request_id"),
                    o.str("fingerprint"),
                    Encode.Device(o.str("name"), o.strOrNull("model"), o.strOrNull("app_version"), o.strOrNull("os_version")),
                )
                "open" -> o.strOrNull("link")?.let { Open(it) }
                "signed_in" -> {
                    val server = o.str("server")
                    if (!isServerUrl(server)) null
                    else SignedIn(o.str("request_id"), server.trimEnd('/'), o.str("org_id"), o.str("org_name"), o.str("person_name"))
                }
                "sign_in_failed" -> SignInFailed(o.str("request_id"), o.str("reason", "error"))
                "context" -> {
                    val server = o.str("server")
                    if (!isServerUrl(server)) null
                    else Context(server.trimEnd('/'), o.str("org_id"), o.str("org_name"), o.str("person_name"))
                }
                "sign_out" -> SignOut
                else -> null
            }
        }

        /**
         * The phone tells the watch which server to call. Only https, except plain http to a
         * private-network host for a self-hosted server at home (the key would otherwise travel
         * in the clear over the internet).
         */
        fun isServerUrl(s: String): Boolean {
            if (s.startsWith("https://") && s.length > 8) return true
            if (!s.startsWith("http://")) return false
            val host = s.removePrefix("http://").substringBefore('/').substringBefore(':').lowercase()
            return host == "localhost" || host.endsWith(".local") || host.startsWith("10.") ||
                host.startsWith("192.168.") || Regex("^172\\.(1[6-9]|2\\d|3[01])\\.").containsMatchIn(host) ||
                host.startsWith("127.")
        }
    }
}
