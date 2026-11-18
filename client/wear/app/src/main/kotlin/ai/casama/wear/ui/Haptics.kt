package ai.casama.wear.ui

import android.content.Context
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.os.Build

/**
 * A tap on the wrist means something (§4 principle 8, §6.7): one pattern for "needs you", one for
 * "done", one for a problem, and a click when a hold completes.
 */
class Haptics(context: Context) {
    private val vibrator: Vibrator? =
        if (Build.VERSION.SDK_INT >= 31) context.getSystemService(VibratorManager::class.java)?.defaultVibrator
        else @Suppress("DEPRECATION") context.getSystemService(Vibrator::class.java)

    /** Two even taps: someone is waiting. */
    fun needsYou() = wave(longArrayOf(0, 70, 90, 70), intArrayOf(0, 200, 0, 200))

    /** A short rising pair: it worked. */
    fun done() = wave(longArrayOf(0, 35, 60, 80), intArrayOf(0, 140, 0, 255))

    /** One long, low buzz: it didn't. */
    fun problem() = wave(longArrayOf(0, 260), intArrayOf(0, 160))

    /** A crisp click: the hold filled. */
    fun click() {
        val v = vibrator ?: return
        runCatching { v.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK)) }
    }

    private fun wave(timings: LongArray, amplitudes: IntArray) {
        val v = vibrator ?: return
        if (!v.hasVibrator()) return
        runCatching {
            val effect = if (v.hasAmplitudeControl()) VibrationEffect.createWaveform(timings, amplitudes, -1)
            else VibrationEffect.createWaveform(timings, -1)
            v.vibrate(effect)
        }
    }
}
