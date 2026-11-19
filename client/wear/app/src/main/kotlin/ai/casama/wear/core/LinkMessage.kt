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

    /** Open on phone. [title] is what the phone's notification says when its app isn't in front. */
    data class Open(val link: String, val title: String? = null) : LinkMessage()

    // phone -> watch
    data class SignedIn(
        val requestId: String,
        val server: String,
        val orgId: String,
        val orgName: String,
        val personName: String,
    ) : LinkMessage()

    data class SignInFailed(val requestId: String, val reason: String) : LinkMessage()

    /** The phone signed the watch in to a server address this watch won't call (see [isServerUrl]). */
    data class SignedInBadServer(val requestId: String) : LinkMessage()

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
            title?.takeIf { it.isNotBlank() }?.let { put("title", it.take(100)) }
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
        // Never sent: the watch's own note that an answer named a server it can't use.
        is SignedInBadServer -> buildJsonObject {
            put("type", "sign_in_failed")
            put("request_id", requestId)
            put("reason", "error")
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
                "open" -> o.strOrNull("link")?.let { Open(it, o.strOrNull("title")) }
                "signed_in" -> {
                    val server = o.str("server")
                    if (!isServerUrl(server)) SignedInBadServer(o.str("request_id"))
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
            val host = s.removePrefix("http://").substringBefore('/').substringBefore('?').substringBefore(':').lowercase()
            if (host == "localhost" || (host.endsWith(".local") && host.length > 6)) return true
            // A private address written as numbers: "10.evil.example" is a name, not an address.
            if (host.any { !it.isDigit() && it != '.' }) return false
            val parts = host.split('.').map { it.toIntOrNull() ?: -1 }
            if (parts.size != 4 || parts.any { it !in 0..255 }) return false
            val a = parts[0]
            val b = parts[1]
            return a == 10 || a == 127 || (a == 192 && b == 168) || (a == 172 && b in 16..31)
        }
    }
}

/**
 * The sign-in requests this watch has out with the phone (WATCH-PROTOCOL §2), each with the
 * fingerprint of the key it was made for. An answer is taken only for one of these and only while
 * the watch still has that key, so an answer to a request made before a sign-out, for a key that
 * is gone, or by another watch, can't sign this one in. Kept as "id fingerprint" lines.
 */
object SignInRequests {
    const val MAX = 8

    data class Issued(val id: String, val fingerprint: String)

    fun decode(text: String?): List<Issued> = text.orEmpty().lines().mapNotNull { line ->
        val parts = line.trim().split(' ')
        if (parts.size == 2 && parts[0].isNotEmpty() && parts[1].isNotEmpty()) Issued(parts[0], parts[1]) else null
    }

    fun encode(list: List<Issued>): String = list.joinToString("\n") { "${it.id} ${it.fingerprint}" }

    /** [list] with this request added, keeping the newest [MAX] and only this key's. */
    fun add(list: List<Issued>, id: String, fingerprint: String): List<Issued> =
        (list.filter { it.id != id && it.fingerprint == fingerprint } + Issued(id, fingerprint)).takeLast(MAX)

    /** Whether [id] is a request this watch made for the key whose fingerprint is [fingerprint]. */
    fun issued(list: List<Issued>, id: String, fingerprint: String?): Boolean =
        id.isNotBlank() && fingerprint != null && list.any { it.id == id && it.fingerprint == fingerprint }
}
