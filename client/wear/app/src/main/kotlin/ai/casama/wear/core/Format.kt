package ai.casama.wear.core

import java.time.Instant
import java.time.ZoneId
import java.time.temporal.ChronoUnit
import java.util.Locale

/**
 * Numbers and times the screens show. Words come from resources (R.string.watch_*), so these
 * return numbers and choices, never English.
 */
object Format {
    /** "KQ7M2XAB" as "KQ7M 2XAB": two groups are easier to read off a wrist and type. */
    fun code(code: String): String {
        val c = code.uppercase().filter { it.isLetterOrDigit() }
        if (c.length < 6) return c
        val half = (c.length + 1) / 2
        return c.substring(0, half) + " " + c.substring(half)
    }

    /** A running clock: "0:42", "2:14", "1:02:03". Negative (clock skew) reads as 0:00. */
    fun elapsed(ms: Long): String {
        val total = (ms.coerceAtLeast(0) / 1000)
        val h = total / 3600
        val m = (total % 3600) / 60
        val s = total % 60
        return if (h > 0) String.format(Locale.ROOT, "%d:%02d:%02d", h, m, s)
        else String.format(Locale.ROOT, "%d:%02d", m, s)
    }

    /** How far off a time is, for "in 12 min" versus a clock time. */
    sealed class Until {
        /** Due, or overdue: say nothing about minutes. */
        data object Now : Until()
        data class Minutes(val minutes: Int) : Until()
        /** An hour or more away: show the clock time; [days] 0 is today, 1 tomorrow. */
        data class At(val days: Int) : Until()
    }

    fun until(now: Long, at: Long, zone: ZoneId): Until {
        val diff = at - now
        if (diff <= 30_000) return Until.Now
        // Rounded up: a routine 30 seconds away is "in 1 min", never "in 0 min".
        val minutes = ((diff + 59_999) / 60_000).toInt()
        if (minutes < 60) return Until.Minutes(minutes)
        return Until.At(dayOffset(now, at, zone))
    }

    /** Calendar days from [now] to [at] in [zone]: 0 today, 1 tomorrow, -1 yesterday. */
    fun dayOffset(now: Long, at: Long, zone: ZoneId): Int {
        val a = Instant.ofEpochMilli(now).atZone(zone).toLocalDate()
        val b = Instant.ofEpochMilli(at).atZone(zone).toLocalDate()
        return ChronoUnit.DAYS.between(a, b).toInt()
    }

    /** Credits used as a whole percent for the ring complication, 0 to 100. */
    fun percent(share: Double?): Int? = share?.let { (it.coerceIn(0.0, 1.0) * 100).toInt() }

    /** Saved data older than this is "as of" data: no claim about now (§6.3, §6.8). */
    const val STALE_AFTER_MS = 15 * 60 * 1000L

    fun isStale(savedAt: Long?, now: Long): Boolean = savedAt == null || now - savedAt > STALE_AFTER_MS || now < savedAt - 60_000
}
