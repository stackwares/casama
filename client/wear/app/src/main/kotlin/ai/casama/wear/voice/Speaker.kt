package ai.casama.wear.voice

import ai.casama.wear.data.Session
import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.io.File
import java.util.Locale
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Read aloud (§6.6): the bot's own voice from GET /v1/messages/{id}/speech, the watch's
 * text-to-speech when the server has no voice or can't be reached. Plays on the speaker or
 * headphones as speech, not media.
 */
class Speaker(private val context: Context) {
    private var player: MediaPlayer? = null
    private var tts: TextToSpeech? = null
    private val _speaking = MutableStateFlow(false)
    val speaking: StateFlow<Boolean> = _speaking.asStateFlow()

    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ASSISTANT)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
        .build()

    /** Reads [text] aloud, in the bot's voice when [messageId] can be spoken by the server. */
    suspend fun speak(session: Session, messageId: String?, text: String, serverVoice: Boolean) {
        stop()
        _speaking.value = true
        if (messageId != null && serverVoice) {
            val file = File(context.cacheDir, "speech-${messageId.filter { it.isLetterOrDigit() }}.mp3")
            val ok = file.exists() || runCatching { session.call { speech(messageId, file) } }.isSuccess
            if (ok && play(file)) return
        }
        speakLocally(text)
    }

    private fun play(file: File): Boolean = try {
        val p = MediaPlayer()
        p.setAudioAttributes(attributes)
        p.setDataSource(file.absolutePath)
        p.setOnCompletionListener { stop() }
        p.setOnErrorListener { _, _, _ -> stop(); true }
        p.prepare()
        p.start()
        player = p
        true
    } catch (_: Exception) {
        runCatching { player?.release() }
        player = null
        false
    }

    private fun speakLocally(text: String) {
        val existing = tts
        if (existing != null) {
            say(existing, text)
            return
        }
        var engine: TextToSpeech? = null
        engine = TextToSpeech(context) { status ->
            val e = engine ?: return@TextToSpeech
            if (status == TextToSpeech.SUCCESS) {
                e.setAudioAttributes(attributes)
                runCatching { e.language = Locale.getDefault() }
                e.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) = Unit
                    override fun onDone(utteranceId: String?) {
                        _speaking.value = false
                    }
                    @Deprecated("Deprecated in Java")
                    override fun onError(utteranceId: String?) {
                        _speaking.value = false
                    }
                })
                say(e, text)
            } else {
                _speaking.value = false
            }
        }
        tts = engine
    }

    private fun say(e: TextToSpeech, text: String) {
        if (e.speak(text, TextToSpeech.QUEUE_FLUSH, null, "casama") != TextToSpeech.SUCCESS) _speaking.value = false
    }

    fun stop() {
        runCatching { player?.stop() }
        runCatching { player?.release() }
        player = null
        runCatching { tts?.stop() }
        _speaking.value = false
    }

    fun shutdown() {
        stop()
        runCatching { tts?.shutdown() }
        tts = null
    }
}
