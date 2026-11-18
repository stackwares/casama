package ai.casama.wear.data

import ai.casama.wear.core.WatchKey
import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.core.content.edit
import java.security.KeyStore as JavaKeyStore
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * The watch key (WATCH-PROTOCOL §1): made here from 32 random bytes and kept encrypted under an
 * AES-GCM key that lives in the Android Keystore and never leaves it. Only the fingerprint is
 * handed to anyone else. A new key is made after every sign-out, so a removed watch can't come
 * back with its old one.
 */
class KeyStore(context: Context) {
    private val prefs = context.getSharedPreferences("casama_key", Context.MODE_PRIVATE)
    @Volatile private var cached: String? = null

    /** The key, made on first use. */
    @Synchronized
    fun getOrCreate(): String {
        get()?.let { return it }
        val bytes = ByteArray(WatchKey.BYTES).also { SecureRandom().nextBytes(it) }
        val key = WatchKey.fromBytes(bytes)
        bytes.fill(0)
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, wrappingKey())
        val sealed = cipher.doFinal(key.toByteArray(Charsets.UTF_8))
        prefs.edit {
            putString(K_DATA, Base64.encodeToString(sealed, Base64.NO_WRAP))
            putString(K_IV, Base64.encodeToString(cipher.iv, Base64.NO_WRAP))
        }
        cached = key
        return key
    }

    /** The key if one was made and can still be read; a broken store reads as none. */
    @Synchronized
    fun get(): String? {
        cached?.let { return it }
        val data = prefs.getString(K_DATA, null) ?: return null
        val iv = prefs.getString(K_IV, null) ?: return null
        return try {
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.DECRYPT_MODE, wrappingKey(), GCMParameterSpec(128, Base64.decode(iv, Base64.NO_WRAP)))
            val key = String(cipher.doFinal(Base64.decode(data, Base64.NO_WRAP)), Charsets.UTF_8)
            if (WatchKey.looksValid(key)) key.also { cached = it } else null
        } catch (_: Exception) {
            // The Keystore key is gone (a restore to another watch, a factory reset of the store):
            // the sealed key can't be opened, so the watch signs in again with a new one.
            null
        }
    }

    fun fingerprint(): String = WatchKey.fingerprint(getOrCreate())

    /** Whether a sealed key is stored, without opening it (cheap enough for app start). */
    fun exists(): Boolean = prefs.contains(K_DATA)

    /** Forgets the key (sign-out). The next sign-in makes a new one. */
    @Synchronized
    fun wipe() {
        cached = null
        prefs.edit { clear() }
        runCatching {
            JavaKeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }.deleteEntry(ALIAS)
        }
    }

    private fun wrappingKey(): SecretKey {
        val store = JavaKeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        (store.getEntry(ALIAS, null) as? JavaKeyStore.SecretKeyEntry)?.let { return it.secretKey }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
        generator.init(
            KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    private companion object {
        const val ANDROID_KEYSTORE = "AndroidKeyStore"
        const val ALIAS = "casama_watch_key_wrap"
        const val TRANSFORMATION = "AES/GCM/NoPadding"
        const val K_DATA = "sealed"
        const val K_IV = "iv"
    }
}
