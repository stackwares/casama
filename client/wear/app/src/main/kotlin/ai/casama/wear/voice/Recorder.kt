package ai.casama.wear.voice

import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import java.io.File
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.withContext

/**
 * Speaking a request (§6.1 C, §8.8): AAC in an MP4 container with MediaRecorder; the server
 * transcribes it. It stops by itself after about a second and a half of quiet once the person
 * has spoken, or after [MAX_MS], or when [stop] is called (a tap).
 */
class Recorder(private val context: Context) {
    sealed class Result {
        data class Audio(val file: File, val mime: String) : Result()
        /** Nothing loud enough was heard. */
        data object Silent : Result()
        data class Failed(val error: Throwable) : Result()
    }

    private var recorder: MediaRecorder? = null
    private val _level = MutableStateFlow(0f)
    /** 0 to 1, for the listening ring. */
    val level: StateFlow<Float> = _level.asStateFlow()
    @Volatile private var stopAsked = false

    fun stop() {
        stopAsked = true
    }

    /** Records until quiet, a tap or the limit. Call from a coroutine; cancelling it discards. */
    suspend fun record(): Result {
        stopAsked = false
        val file = File(context.cacheDir, "ask-${System.currentTimeMillis()}.m4a")
        val r = try {
            withContext(Dispatchers.IO) { start(file) }
        } catch (e: Exception) {
            release()
            file.delete()
            return Result.Failed(e)
        }
        recorder = r
        var heard = false
        var quietSince = 0L
        val started = System.currentTimeMillis()
        try {
            while (currentCoroutineContext().isActive && !stopAsked) {
                delay(TICK_MS)
                val amp = runCatching { r.maxAmplitude }.getOrDefault(0)
                _level.value = (amp / 12_000f).coerceIn(0f, 1f)
                val now = System.currentTimeMillis()
                if (amp > SPEECH) {
                    heard = true
                    quietSince = 0L
                } else if (heard) {
                    if (quietSince == 0L) quietSince = now
                    if (now - quietSince >= QUIET_MS) break
                }
                if (!heard && now - started > NO_SPEECH_MS) break
                if (now - started > MAX_MS) break
            }
        } finally {
            val ok = runCatching { r.stop() }.isSuccess
            release()
            _level.value = 0f
            if (!ok || !currentCoroutineContext().isActive) {
                file.delete()
            }
        }
        if (!file.exists() || file.length() < 512) {
            file.delete()
            return Result.Silent
        }
        // Nothing loud enough was heard, even when the person tapped to stop: don't send silence.
        if (!heard) {
            file.delete()
            return Result.Silent
        }
        return Result.Audio(file, "audio/mp4")
    }

    private fun start(file: File): MediaRecorder {
        val r = if (Build.VERSION.SDK_INT >= 31) MediaRecorder(context) else @Suppress("DEPRECATION") MediaRecorder()
        r.setAudioSource(MediaRecorder.AudioSource.VOICE_RECOGNITION)
        r.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        r.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        r.setAudioChannels(1)
        r.setAudioSamplingRate(16_000)
        r.setAudioEncodingBitRate(32_000)
        r.setOutputFile(file.absolutePath)
        r.prepare()
        r.start()
        return r
    }

    private fun release() {
        runCatching { recorder?.release() }
        recorder = null
    }

    private companion object {
        const val TICK_MS = 100L
        const val SPEECH = 1_800
        const val QUIET_MS = 1_500L
        const val NO_SPEECH_MS = 6_000L
        // About a minute of AAC at 32 kbps stays under the contract's 1 MB.
        const val MAX_MS = 55_000L
    }
}
