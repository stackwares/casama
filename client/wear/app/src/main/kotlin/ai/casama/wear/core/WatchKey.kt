package ai.casama.wear.core

import java.security.MessageDigest
import java.util.Base64

/**
 * The watch's key (docs/WATCH-PROTOCOL.md §1): `cwt_` + base64url(32 random bytes, no padding),
 * 47 characters. Only its fingerprint, lowercase hex of sha256("casama-watch-key:" + key), ever
 * leaves the watch other than in the `Authorization: Watch <key>` header.
 */
object WatchKey {
    const val PREFIX = "cwt_"
    const val BYTES = 32

    fun fromBytes(bytes: ByteArray): String {
        require(bytes.size == BYTES) { "a watch key is $BYTES bytes" }
        return PREFIX + Base64.getUrlEncoder().withoutPadding().encodeToString(bytes)
    }

    fun fingerprint(key: String): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(("casama-watch-key:$key").toByteArray(Charsets.UTF_8))
        val out = StringBuilder(digest.size * 2)
        for (b in digest) {
            val v = b.toInt() and 0xff
            out.append(HEX[v ushr 4]).append(HEX[v and 0x0f])
        }
        return out.toString()
    }

    /** Shape check before a stored key is used (a corrupt store reads as signed out). */
    fun looksValid(key: String?): Boolean =
        key != null && key.length == 47 && key.startsWith(PREFIX) &&
            key.substring(4).all { it.isLetterOrDigit() || it == '-' || it == '_' }

    private const val HEX = "0123456789abcdef"
}
