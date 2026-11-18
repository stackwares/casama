package ai.casama.app

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

/**
 * A bot's mark outside the app (live run notifications, the call notification, the home-screen
 * widget), drawn as the app draws it (client/lib/ui/bot_avatar.dart): the bot's mascot when it
 * picked one (res/drawable-nodpi/mascot_<name>.png, from assets/mascots), otherwise its initials
 * on a rounded square in its gradient, picked from its name as botPalette does. Keep both lists in
 * step with bot_avatar.dart and mascot.dart.
 */
object BotArt {
  /** The mascots (mascot.dart, `Mascot`) and their own two colours. */
  private val mascots = mapOf(
    "winky" to (0xFF7A90FF.toInt() to 0xFF7DE9F4.toInt()),
    "sleepy" to (0xFF7C83F2.toInt() to 0xFFA59CF6.toInt()),
    "starry" to (0xFFFF9F43.toInt() to 0xFFFFC94D.toInt()),
    "lovey" to (0xFFFF6FAE.toInt() to 0xFFFF9CC9.toInt()),
    "cool" to (0xFF14B8A6.toInt() to 0xFF4FD1C5.toInt()),
    "thinker" to (0xFFF59E0B.toInt() to 0xFFFBBF24.toInt()),
    "giggly" to (0xFF22C55E.toInt() to 0xFF4ADE80.toInt()),
    "shy" to (0xFFFB7185.toInt() to 0xFFFDA4AF.toInt()),
    "focused" to (0xFF3B82F6.toInt() to 0xFF60A5FA.toInt()),
    "wow" to (0xFF8B5CF6.toInt() to 0xFFA78BFA.toInt()),
  )

  /** The initials gradients (bot_avatar.dart, `_palettes`). */
  private val palettes = listOf(
    0xFF14B8A6.toInt() to 0xFF0F766E.toInt(),
    0xFF6366F1.toInt() to 0xFF4338CA.toInt(),
    0xFFF59E0B.toInt() to 0xFFD97706.toInt(),
    0xFFEC4899.toInt() to 0xFFBE185D.toInt(),
    0xFF3B82F6.toInt() to 0xFF1D4ED8.toInt(),
    0xFF8B5CF6.toInt() to 0xFF6D28D9.toInt(),
    0xFF10B981.toInt() to 0xFF047857.toInt(),
    0xFFF97316.toInt() to 0xFFC2410C.toInt(),
  )

  /** Named here, not looked up by name, so resource shrinking keeps them. */
  private val drawables = mapOf(
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

  private val cache = LruCache<String, Bitmap>(16)

  /** The mascot's key (`winky`) for an `avatar_url` of `mascot:winky`, when we ship that mascot. */
  fun mascot(avatar: String?): String? =
    avatar?.takeIf { it.startsWith("mascot:") }?.removePrefix("mascot:")?.takeIf { it in mascots }

  /** The bot's two colours: its mascot's, or its initials gradient. */
  fun colors(name: String, avatar: String?): Pair<Int, Int> {
    mascot(avatar)?.let { return mascots.getValue(it) }
    // botPalette: (h * 31 + code unit) & 0x7fffffff over the lower-cased name's UTF-16.
    var h = 0L
    for (c in name.lowercase()) h = (h * 31 + c.code) and 0x7fffffff
    return palettes[(h % palettes.size).toInt()]
  }

  /** The colour things in the bot's colour use. */
  fun accent(name: String, avatar: String?): Int = colors(name, avatar).first

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

  /** The mark at [px] square, transparent around a mascot. */
  fun bitmap(context: Context, name: String, avatar: String?, px: Int): Bitmap {
    val key = "${mascot(avatar) ?: "i:$name"}@$px"
    cache.get(key)?.let { return it }
    val out = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(out)
    val mascot = mascot(avatar)
    val art = mascot?.let { drawables[it] }?.let { BitmapFactory.decodeResource(context.resources, it) }
    if (art != null) {
      // The art keeps a margin for the cloud's hops (mascot.dart, _zoom): draw it a little larger.
      val grow = (px * 0.07f).toInt()
      canvas.drawBitmap(
        art,
        null,
        Rect(-grow, -grow, px + grow, px + grow),
        Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG),
      )
    } else {
      val (top, bottom) = colors(name, null)
      val size = px.toFloat()
      val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        shader = LinearGradient(0f, 0f, size, size, top, bottom, Shader.TileMode.CLAMP)
      }
      canvas.drawRoundRect(RectF(0f, 0f, size, size), size * 0.32f, size * 0.32f, fill)
      val letters = initials(name)
      val text = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = 0xFFFFFFFF.toInt()
        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        textAlign = Paint.Align.CENTER
        textSize = size * (if (name.trim().contains(' ')) 0.36f else 0.44f)
      }
      val y = size / 2 - (text.descent() + text.ascent()) / 2
      canvas.drawText(letters, size / 2, y, text)
    }
    cache.put(key, out)
    return out
  }
}
