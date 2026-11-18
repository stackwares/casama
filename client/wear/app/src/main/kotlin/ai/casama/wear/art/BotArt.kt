package ai.casama.wear.art

import ai.casama.wear.R
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.util.LruCache
import java.io.ByteArrayOutputStream

/**
 * A bot's face on the watch, drawn as the app draws it (client/lib/ui/bot_avatar.dart, and the
 * phone's BotArt.kt): its mascot when it picked one (res/drawable-nodpi/mascot_<name>.png, from
 * client/assets/mascots at watch size), otherwise its initials on a rounded square in its gradient,
 * picked from its name as botPalette does. Keep the lists in step with bot_avatar.dart.
 */
object BotArt {
    private val mascots = mapOf(
        "winky" to R.drawable.mascot_winky,
        "sleepy" to R.drawable.mascot_sleepy,
        "starry" to R.drawable.mascot_starry,
        "lovey" to R.drawable.mascot_lovey,
        "cool" to R.drawable.mascot_cool,
        "thinker" to R.drawable.mascot_thinker,
        "giggly" to R.drawable.mascot_giggly,
        "shy" to R.drawable.mascot_shy,
        "focused" to R.drawable.mascot_focused,
        "wow" to R.drawable.mascot_wow,
    )

    /** The initials gradients (bot_avatar.dart, `_palettes`). */
    val palettes: List<Pair<Int, Int>> = listOf(
        0xFF14B8A6.toInt() to 0xFF0F766E.toInt(),
        0xFF6366F1.toInt() to 0xFF4338CA.toInt(),
        0xFFF59E0B.toInt() to 0xFFD97706.toInt(),
        0xFFEC4899.toInt() to 0xFFBE185D.toInt(),
        0xFF3B82F6.toInt() to 0xFF1D4ED8.toInt(),
        0xFF8B5CF6.toInt() to 0xFF6D28D9.toInt(),
        0xFF10B981.toInt() to 0xFF047857.toInt(),
        0xFFF97316.toInt() to 0xFFC2410C.toInt(),
    )

    private val cache = LruCache<String, Bitmap>(24)

    /** The drawable for `mascot:<name>`, when we ship that mascot. */
    fun mascotRes(avatar: String?): Int? =
        avatar?.takeIf { it.startsWith("mascot:") }?.removePrefix("mascot:")?.let { mascots[it] }

    /** The sleepy face for All clear (§6.1 A). */
    val sleepy: Int get() = R.drawable.mascot_sleepy

    /** The initials gradient for [name]: botPalette, (h * 31 + code unit) & 0x7fffffff, lower-cased. */
    fun palette(name: String): Pair<Int, Int> {
        var h = 0L
        for (c in name.lowercase()) h = (h * 31 + c.code) and 0x7fffffff
        return palettes[(h % palettes.size).toInt()]
    }

    /** One or two letters, as `botInitials` makes them. */
    fun initials(name: String): String {
        val parts = name.trim().split(Regex("\\s+")).filter { it.isNotEmpty() }
        fun first(s: String) = String(Character.toChars(s.codePointAt(0)))
        return when {
            parts.isEmpty() -> "?"
            parts.size == 1 -> first(parts[0]).uppercase()
            else -> (first(parts[0]) + first(parts[1])).uppercase()
        }
    }

    /** The face at [px] square, transparent around a mascot (notifications, tiles, complications). */
    fun bitmap(context: Context, name: String, avatar: String?, px: Int): Bitmap {
        val res = mascotRes(avatar)
        val key = "${res ?: "i:$name"}@$px"
        cache.get(key)?.let { return it }
        val out = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(out)
        val art = res?.let { BitmapFactory.decodeResource(context.resources, it) }
        if (art != null) {
            // The art keeps a margin for the cloud's hops (mascot.dart, _zoom): draw it a little larger.
            val grow = (px * 0.07f).toInt()
            canvas.drawBitmap(art, null, Rect(-grow, -grow, px + grow, px + grow), Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG))
        } else {
            val (top, bottom) = palette(name)
            val size = px.toFloat()
            val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = LinearGradient(0f, 0f, size, size, top, bottom, Shader.TileMode.CLAMP)
            }
            canvas.drawRoundRect(RectF(0f, 0f, size, size), size * 0.32f, size * 0.32f, fill)
            val text = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = 0xFFFFFFFF.toInt()
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                textAlign = Paint.Align.CENTER
                textSize = size * (if (name.trim().contains(' ')) 0.36f else 0.44f)
            }
            val y = size / 2 - (text.descent() + text.ascent()) / 2
            canvas.drawText(initials(name), size / 2, y, text)
        }
        cache.put(key, out)
        return out
    }

    /** PNG bytes for a tile's inline image. */
    fun png(context: Context, name: String, avatar: String?, px: Int): ByteArray =
        ByteArrayOutputStream().also { bitmap(context, name, avatar, px).compress(Bitmap.CompressFormat.PNG, 100, it) }.toByteArray()
}
