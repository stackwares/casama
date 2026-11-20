package ai.casama.app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

/**
 * Bots' own pictures (docs/BOT-PICTURES-PLAN.md §5.4) for what Android draws outside the app:
 * widgets, the live-run and call notifications, the pinned bot icon. Each keeps a copy of the
 * 128 px PNG in `filesDir/bot-images/<id>.png` and [BotArt] reads that file; a missing file draws
 * the initials on the picture's own colours. Ids never change what a picture shows, so a file is
 * fetched once and only deleted when no bot uses it.
 *
 * `GET {glance_server}/v1/bot-images/{id}?size=128&format=png` needs no key. [ensure] blocks: call
 * it off the main thread (the widget worker does, [ensureThen] starts a thread for the rest).
 */
object BotPictures {
  private const val DIR = "bot-images"
  private const val TIMEOUT_MS = 8_000
  /** A 128 px PNG is a few KB; anything bigger isn't the picture we asked for. */
  private const val MAX_BYTES = 256 * 1024
  /**
   * A file younger than this survives [prune]: the app may be about to draw it for a notification
   * or a pinned icon from a list the widget worker never saw.
   */
  private const val PRUNE_GRACE_MS = 24 * 60 * 60 * 1000L
  private val PNG = byteArrayOf(0x89.toByte(), 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)
  private val background = Executors.newSingleThreadExecutor()

  /** Where [id]'s file is (it may not exist yet), or null when [id] isn't a uuid. */
  fun file(context: Context, id: String): File? =
    if (BotAvatarValue.isValidId(id)) File(File(context.filesDir, DIR), "$id.png") else null

  fun has(context: Context, id: String) = file(context, id)?.exists() == true

  /** The decoded picture, or null when there's no usable file (a broken one is deleted to be fetched again). */
  fun bitmap(context: Context, id: String): Bitmap? {
    val f = file(context, id)?.takeIf { it.exists() } ?: return null
    return BitmapFactory.decodeFile(f.path) ?: run {
      f.delete()
      null
    }
  }

  /** The server's API base as the app wrote it for the widgets (`glance_server`), without a trailing slash. */
  fun server(context: Context): String? =
    (GlanceStore.prefs(context).all[GlanceStore.KEY_SERVER] as? String)?.trimEnd('/')?.ifEmpty { null }

  /**
   * Downloads the pictures in [ids] that aren't on disk yet. Blocking; never throws. Anything that
   * can't be fetched stays missing and the mark shows initials. Returns how many arrived.
   */
  fun ensure(context: Context, ids: Collection<String>, server: String): Int {
    var fetched = 0
    val dir = File(context.filesDir, DIR)
    for (id in ids.toSet()) {
      val file = file(context, id) ?: continue
      if (file.exists()) continue
      dir.mkdirs()
      val conn = try {
        (URL("$server/v1/bot-images/$id?size=128&format=png").openConnection() as HttpURLConnection).apply {
          connectTimeout = TIMEOUT_MS
          readTimeout = TIMEOUT_MS
          setRequestProperty("Accept", "image/png")
        }
      } catch (e: Exception) {
        continue
      }
      try {
        if (conn.responseCode != 200) continue
        val bytes = conn.inputStream.use { readUpTo(it, MAX_BYTES) } ?: continue
        if (bytes.size < PNG.size || !bytes.copyOf(PNG.size).contentEquals(PNG)) continue
        val tmp = File(dir, file.name + ".part")
        tmp.writeBytes(bytes)
        if (tmp.renameTo(file)) fetched++
      } catch (e: Exception) {
        Log.w(CasamaWidget.TAG, "bot picture fetch failed: ${e.message}")
      } finally {
        conn.disconnect()
      }
    }
    return fetched
  }

  /** All of [input], or null when it is longer than [max] bytes. */
  private fun readUpTo(input: InputStream, max: Int): ByteArray? {
    val out = ByteArrayOutputStream()
    val buffer = ByteArray(8 * 1024)
    while (true) {
      val n = input.read(buffer)
      if (n < 0) break
      if (out.size() + n > max) return null
      out.write(buffer, 0, n)
    }
    return out.toByteArray()
  }

  /**
   * [ensure] on a background thread for code that runs on the main thread (a notification, the
   * pinned icon); [then] runs on that background thread with the number that arrived, only when it is more than none.
   */
  fun ensureThen(context: Context, ids: Collection<String>, then: (Int) -> Unit) {
    val app = context.applicationContext
    val server = server(app) ?: return
    if (ids.none { BotAvatarValue.isValidId(it) && !has(app, it) }) return
    background.execute {
      val n = runCatching { ensure(app, ids, server) }.getOrDefault(0)
      if (n > 0) then(n)
    }
  }

  /** Deletes the files of pictures not in [keep] (the full set the widgets know of, never a part). */
  fun prune(context: Context, keep: Set<String>, graceMs: Long = PRUNE_GRACE_MS) {
    val now = System.currentTimeMillis()
    File(context.filesDir, DIR).listFiles()?.forEach { f ->
      val id = f.name.removeSuffix(".png")
      if (f.name.endsWith(".png") && id in keep) return@forEach
      // Half-downloaded files and unknown names go too; a recent picture waits out the grace period.
      if (f.name.endsWith(".png") && now - f.lastModified() < graceMs) return@forEach
      f.delete()
    }
  }

  /** Every bot avatar the widgets draw: the glance's, the canvases' and the old single bot's. */
  private fun widgetAvatars(context: Context): List<String?> {
    val g = (GlanceStore.prefs(context).all[GlanceStore.KEY_GLANCE] as? String)?.let { GlanceStore.parse(it) }
    val fromGlance = g?.let {
      it.needs.map { n -> n.botAvatar } + it.bots.map { b -> b.avatar } + it.next.map { r -> r.botAvatar } +
        it.lately.map { d -> d.botAvatar } + listOfNotNull(it.brief?.botAvatar)
    } ?: emptyList()
    val fromCanvases = CanvasStore.load(context)?.items?.map { it.botAvatar } ?: emptyList()
    return fromGlance + fromCanvases + GlanceStore.prefs(context).getString("bot_avatar", null)
  }

  /** Whether a picture the widgets draw isn't on disk yet (the app just wrote new data: fetch). */
  fun missing(context: Context): Boolean = BotAvatarValue.ids(widgetAvatars(context)).any { !has(context, it) }

  /**
   * The widget worker's step: saves the pictures the widgets draw and doesn't have, deletes the
   * ones no bot uses, and redraws the widgets when any arrived. Blocking (off the main thread).
   */
  fun refresh(context: Context) {
    val ids = BotAvatarValue.ids(widgetAvatars(context))
    val server = server(context)
    val fetched = if (server != null) ensure(context, ids, server) else 0
    prune(context, ids)
    if (fetched > 0) WidgetKit.redrawAll(context)
  }

  /** Everything saved goes (signed out, or the key was dropped). */
  fun clear(context: Context) {
    File(context.filesDir, DIR).deleteRecursively()
  }
}
