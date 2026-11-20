package ai.casama.app

import ai.casama.app.canvas.CanvasList
import ai.casama.app.canvas.CanvasLogic
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequest
import androidx.work.PeriodicWorkRequest
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.time.ZoneId
import java.util.concurrent.TimeUnit

/**
 * Widgets fresh while Casama is closed (D-405 Phase 3, §8.3 and §8.7). The app hands over a widget
 * key (`casama/widgets` → `setKey`), kept in the app-private file `casama_widget_key`; it reads the
 * glance and creation covers and nothing else. With a key and at least one widget placed:
 *
 * - a 30-minute periodic job fetches `GET {glance_server}/v1/glance?org_id=` (Android's floor for
 *   periodic work, and a server that can't push still gets there);
 * - a `glance` data message ([GlancePushReceiver]) queues one fetch at once.
 *
 * A fetch that finds nothing new costs one cheap request (`If-None-Match`, 304). Both stop when the
 * last widget is removed or the key is dropped (sign-out). With a Canvas widget placed, both also
 * fetch the canvases ([CanvasRefresh], docs/BOT-WIDGET-PLAN.md §10.2).
 */
object GlanceRefresh {
  private const val KEY_PREFS = "casama_widget_key"
  private const val PERIODIC = "casama_glance_periodic"
  private const val NOW = "casama_glance_now"
  /** Tags the periodic job, so a failed periodic fetch waits for its next turn instead of retrying. */
  const val TAG_PERIODIC = "casama_glance_periodic_tag"
  private const val COVERS_DIR = "widget_covers"
  private const val TIMEOUT_MS = 10_000

  private fun keyPrefs(context: Context) = context.getSharedPreferences(KEY_PREFS, Context.MODE_PRIVATE)

  fun key(context: Context): String? = keyPrefs(context).getString("key", null)

  /** Stores the widget key (null deletes it, with the cached covers) and re-plans the refreshes. */
  fun setKey(context: Context, key: String?) {
    keyPrefs(context).edit().apply {
      if (key.isNullOrEmpty()) clear() else putString("key", key).remove("etag")
    }.apply()
    if (key.isNullOrEmpty()) {
      File(context.filesDir, COVERS_DIR).deleteRecursively()
      File(context.filesDir, CanvasStore.PICTURES_DIR).deleteRecursively()
      BotPictures.clear(context)
    }
    schedule(context)
  }

  /** Periodic refreshes while a key is set and any widget of ours is placed; none otherwise. */
  fun schedule(context: Context) {
    val work = runCatching { WorkManager.getInstance(context.applicationContext) }.getOrNull() ?: return
    if (key(context) == null || WidgetKit.installed(context).isEmpty()) {
      work.cancelUniqueWork(PERIODIC)
      return
    }
    work.enqueueUniquePeriodicWork(
      PERIODIC,
      ExistingPeriodicWorkPolicy.KEEP,
      PeriodicWorkRequest.Builder(GlanceWorker::class.java, 30, TimeUnit.MINUTES)
        .setConstraints(online())
        .addTag(TAG_PERIODIC)
        .build(),
    )
  }

  /** One fetch as soon as the phone is online (a refresh push, or covers the app just listed). */
  fun now(context: Context) {
    if (key(context) == null || WidgetKit.installed(context).isEmpty()) return
    runCatching {
      WorkManager.getInstance(context.applicationContext).enqueueUniqueWork(
        NOW,
        ExistingWorkPolicy.REPLACE,
        OneTimeWorkRequest.Builder(GlanceWorker::class.java).setConstraints(online()).build(),
      )
    }
  }

  private fun online() = Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()

  /** What a fetch came to. */
  enum class Outcome { CHANGED, SAME, GONE, FAILED, SKIPPED }

  /**
   * Fetches the glance (off the main thread; the worker calls it). On a new one it is saved where
   * the widgets read and every widget redrawn. A key the server no longer knows is dropped.
   */
  fun fetch(context: Context): Outcome {
    val key = key(context) ?: return Outcome.SKIPPED
    val store = GlanceStore.prefs(context)
    val server = (store.all[GlanceStore.KEY_SERVER] as? String)?.trimEnd('/')?.ifEmpty { null } ?: return Outcome.SKIPPED
    if (!GlanceStore.signedIn(context)) return Outcome.SKIPPED
    val current = (store.all[GlanceStore.KEY_GLANCE] as? String)?.let { GlanceStore.parse(it) }
    // The workspace comes from the glance the app last wrote; with none yet there's nothing to ask.
    val org = current?.orgId?.ifEmpty { null } ?: return Outcome.SKIPPED
    val url = URL("$server/v1/glance?org_id=" + URLEncoder.encode(org, "UTF-8"))
    val conn = (url.openConnection() as HttpURLConnection).apply {
      connectTimeout = TIMEOUT_MS
      readTimeout = TIMEOUT_MS
      setRequestProperty("Authorization", "Widget $key")
      setRequestProperty("Accept", "application/json")
      // The server's own ETag for the glance we hold, else its version quoted as one. The app may
      // have written a newer glance since the last fetch, so a tag for another version isn't used.
      val k = keyPrefs(context)
      val tag = k.getString("etag", null)?.takeIf { k.getString("etag_version", null) == current.version }
        ?: current.version.ifEmpty { null }?.let { "\"$it\"" }
      if (tag != null) setRequestProperty("If-None-Match", tag)
    }
    return try {
      when (val code = conn.responseCode) {
        200 -> {
          val body = conn.inputStream.bufferedReader().use { it.readText() }
          val glance = GlanceStore.parse(body) ?: return Outcome.FAILED
          // The person switched workspaces or signed out meanwhile: the app's write wins.
          if (!GlanceStore.signedIn(context)) return Outcome.SKIPPED
          store.edit()
            .putString(GlanceStore.KEY_GLANCE, body)
            .putLong(GlanceStore.KEY_CHECKED_AT, System.currentTimeMillis())
            .commit()
          conn.getHeaderField("ETag")?.let {
            keyPrefs(context).edit().putString("etag", it).putString("etag_version", glance.version).apply()
          }
          fetchCovers(context, server, key, glance)
          WidgetKit.redrawAll(context)
          Outcome.CHANGED
        }
        304 -> {
          // Unchanged, and so true as of now: the widgets drop any "as of".
          store.edit().putLong(GlanceStore.KEY_CHECKED_AT, System.currentTimeMillis()).commit()
          fetchCovers(context, server, key, current)
          WidgetKit.redrawAll(context)
          Outcome.SAME
        }
        401, 403 -> {
          Log.i(CasamaWidget.TAG, "widget key refused ($code); dropping it")
          setKey(context, null)
          Outcome.GONE
        }
        else -> {
          Log.w(CasamaWidget.TAG, "glance fetch: HTTP $code")
          Outcome.FAILED
        }
      }
    } catch (e: Exception) {
      Log.w(CasamaWidget.TAG, "glance fetch failed: ${e.message}")
      Outcome.FAILED
    } finally {
      conn.disconnect()
    }
  }

  // MARK: Covers (Library)

  /** Where a creation's cover is cached: by id and version, so a new cover is fetched again. */
  fun coverFile(context: Context, id: String, version: Int): File =
    File(File(context.filesDir, COVERS_DIR), "${id.filter { it.isLetterOrDigit() || it == '-' }}_$version")

  /**
   * Fetches the covers the Library widget would show and doesn't have yet, and forgets the rest.
   * Only while a Library widget is placed.
   */
  private fun fetchCovers(context: Context, server: String, key: String, glance: GlanceStore.Glance) {
    val dir = File(context.filesDir, COVERS_DIR)
    val placed = WidgetKit.installed(context).any { it.first == LibraryWidget::class.java }
    val wanted = if (placed) glance.recent.filter { it.hasCover }.take(6) else emptyList()
    val keep = wanted.map { coverFile(context, it.id, it.version).name }.toSet()
    dir.listFiles()?.filter { it.name !in keep }?.forEach { it.delete() }
    for (c in wanted) {
      val file = coverFile(context, c.id, c.version)
      if (file.exists()) continue
      dir.mkdirs()
      val conn = (URL("$server/v1/creations/${URLEncoder.encode(c.id, "UTF-8")}/cover").openConnection() as HttpURLConnection).apply {
        connectTimeout = TIMEOUT_MS
        readTimeout = TIMEOUT_MS
        setRequestProperty("Authorization", "Widget $key")
      }
      try {
        if (conn.responseCode != 200) continue
        // At most 2 MB: a cover is a small picture, and anything bigger isn't one.
        val bytes = conn.inputStream.use { it.readBytes() }.takeIf { it.size <= 2 * 1024 * 1024 } ?: continue
        val tmp = File(dir, file.name + ".part")
        tmp.writeBytes(bytes)
        tmp.renameTo(file)
      } catch (e: Exception) {
        Log.w(CasamaWidget.TAG, "cover fetch failed: ${e.message}")
      } finally {
        conn.disconnect()
      }
    }
  }

  /** Covers for a glance the app just wrote (`reload`): fetched in the background when missing. */
  fun coversMissing(context: Context): Boolean {
    if (key(context) == null) return false
    if (WidgetKit.installed(context).none { it.first == LibraryWidget::class.java }) return false
    val g = (GlanceStore.prefs(context).all[GlanceStore.KEY_GLANCE] as? String)?.let { GlanceStore.parse(it) } ?: return false
    return g.recent.filter { it.hasCover }.take(6).any { !coverFile(context, it.id, it.version).exists() }
  }
}

/** The background fetch, for both the periodic job and a push's one-off. */
class GlanceWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
  override fun doWork(): Result {
    val glance = GlanceRefresh.fetch(applicationContext)
    // The canvases after the glance: a key the glance found refused is gone by now, so this skips.
    val canvases = CanvasRefresh.fetch(applicationContext)
    // The bots' own pictures last: they come from the data both fetches just stored, and need no key.
    if (glance != GlanceRefresh.Outcome.SKIPPED || canvases != GlanceRefresh.Outcome.SKIPPED) BotPictures.refresh(applicationContext)
    val failed = glance == GlanceRefresh.Outcome.FAILED || canvases == GlanceRefresh.Outcome.FAILED
    // A one-off from a push retries a couple of times; the periodic job just waits for its next turn.
    return if (failed && runAttemptCount < 2 && GlanceRefresh.TAG_PERIODIC !in tags) Result.retry() else Result.success()
  }
}

/**
 * The Canvas widget's data while the app is closed (docs/BOT-WIDGET-PLAN.md §10.2): with a Canvas
 * widget placed, the 30-minute job and every refresh push also fetch
 * `GET {glance_server}/v1/canvases?sizes=…` with the widget key (`If-None-Match`, 304 when nothing
 * changed), then the pictures the placed widgets draw, shrunk to the largest of them and cached by
 * hash. Planned entries switch by themselves: a one-off job at the next entry's time
 * ([scheduleTick]), which Android may run a few minutes late.
 */
object CanvasRefresh {
  private const val TICK = "casama_canvas_tick"
  private const val TIMEOUT_MS = 10_000
  /** A picture is a JPEG the server already shrank (under 400 KB); anything far bigger isn't one. */
  private const val MAX_PICTURE_BYTES = 2 * 1024 * 1024
  /** Pictures kept at most: a rotation usually shares one painting. */
  private const val MAX_PICTURES = 8

  private fun placed(context: Context) = CanvasStore.placedIds(context).isNotEmpty()

  /** Fetches the canvases (off the main thread; [GlanceWorker] calls it). */
  fun fetch(context: Context): GlanceRefresh.Outcome {
    if (!placed(context)) return GlanceRefresh.Outcome.SKIPPED
    val key = GlanceRefresh.key(context) ?: return GlanceRefresh.Outcome.SKIPPED
    val store = GlanceStore.prefs(context)
    val server = (store.all[GlanceStore.KEY_SERVER] as? String)?.trimEnd('/')?.ifEmpty { null } ?: return GlanceRefresh.Outcome.SKIPPED
    if (!GlanceStore.signedIn(context)) return GlanceRefresh.Outcome.SKIPPED
    // The workspace comes from the glance, as GlanceRefresh's own fetch does.
    val org = (store.all[GlanceStore.KEY_GLANCE] as? String)?.let { GlanceStore.parse(it) }?.orgId?.ifEmpty { null }
      ?: return GlanceRefresh.Outcome.SKIPPED
    val current = CanvasStore.load(context)
    val sizes = CanvasStore.sizes(context).joinToString(",")
    val url = URL(
      "$server/v1/canvases?org_id=" + URLEncoder.encode(org, "UTF-8") + "&sizes=" + URLEncoder.encode(sizes, "UTF-8"),
    )
    val conn = (url.openConnection() as HttpURLConnection).apply {
      connectTimeout = TIMEOUT_MS
      readTimeout = TIMEOUT_MS
      setRequestProperty("Authorization", "Widget $key")
      setRequestProperty("Accept", "application/json")
      // The server's ETag is the list's version, quoted; whoever wrote the list last (the app or
      // this), its version is the one to ask about.
      current?.version?.ifEmpty { null }?.let { setRequestProperty("If-None-Match", "\"$it\"") }
    }
    return try {
      when (val code = conn.responseCode) {
        200 -> {
          val body = conn.inputStream.bufferedReader().use { it.readText() }
          val list = CanvasStore.parse(body) ?: return GlanceRefresh.Outcome.FAILED
          if (!GlanceStore.signedIn(context)) return GlanceRefresh.Outcome.SKIPPED
          store.edit().putString(CanvasStore.KEY, body).remove(CanvasStore.KEY_UNSUPPORTED).commit()
          fetchPictures(context, server, key, list)
          redraw(context)
          GlanceRefresh.Outcome.CHANGED
        }
        304 -> {
          fetchPictures(context, server, key, current)
          redraw(context)
          GlanceRefresh.Outcome.SAME
        }
        401, 403 -> {
          Log.i(CasamaWidget.TAG, "widget key refused for canvases ($code); dropping it")
          GlanceRefresh.setKey(context, null)
          GlanceRefresh.Outcome.GONE
        }
        404 -> {
          // A server from before bot widgets.
          store.edit().putString(CanvasStore.KEY_UNSUPPORTED, "1").commit()
          redraw(context)
          GlanceRefresh.Outcome.SAME
        }
        else -> {
          Log.w(CasamaWidget.TAG, "canvas fetch: HTTP $code")
          GlanceRefresh.Outcome.FAILED
        }
      }
    } catch (e: Exception) {
      Log.w(CasamaWidget.TAG, "canvas fetch failed: ${e.message}")
      GlanceRefresh.Outcome.FAILED
    } finally {
      conn.disconnect()
    }
  }

  /** Redraws the Canvas widgets and plans their next switch. */
  fun redraw(context: Context) {
    WidgetKit.redraw(context, CanvasWidget::class.java)
    scheduleTick(context)
  }

  /** The pictures the placed widgets draw now and later: (canvas id, hash). */
  private fun wanted(context: Context, list: CanvasList?): List<Pair<String, String>> =
    CanvasStore.shown(context, list)
      .flatMap { c -> CanvasLogic.pictures(c).map { c.id to it } }
      .distinctBy { it.second }
      .take(MAX_PICTURES)

  /** Whether a picture the widgets would draw isn't cached yet (`reload` then queues a fetch). */
  fun picturesMissing(context: Context): Boolean {
    if (GlanceRefresh.key(context) == null || !placed(context)) return false
    return wanted(context, CanvasStore.load(context)).any { (_, h) -> CanvasStore.pictureFile(context, h)?.exists() == false }
  }

  /**
   * Fetches the pictures the placed widgets draw and doesn't have yet, shrinks each to the largest
   * placed widget, and forgets the rest. A picture that can't be fetched leaves its colour drawn.
   */
  private fun fetchPictures(context: Context, server: String, key: String, list: CanvasList?) {
    val dir = File(context.filesDir, CanvasStore.PICTURES_DIR)
    val wanted = wanted(context, list)
    val keep = wanted.mapNotNull { CanvasStore.pictureFile(context, it.second)?.name }.toSet()
    dir.listFiles()?.filter { it.name !in keep }?.forEach { it.delete() }
    if (wanted.isEmpty()) return
    val (maxW, maxH) = CanvasStore.largestPx(context)
    for ((canvasId, hash) in wanted) {
      val file = CanvasStore.pictureFile(context, hash) ?: continue
      if (file.exists()) continue
      dir.mkdirs()
      val path = "/v1/canvases/${URLEncoder.encode(canvasId, "UTF-8")}/pictures/${URLEncoder.encode(hash, "UTF-8")}"
      val conn = (URL(server + path).openConnection() as HttpURLConnection).apply {
        connectTimeout = TIMEOUT_MS
        readTimeout = TIMEOUT_MS
        setRequestProperty("Authorization", "Widget $key")
      }
      try {
        if (conn.responseCode != 200) continue
        val bytes = conn.inputStream.use { it.readBytes() }.takeIf { it.size <= MAX_PICTURE_BYTES } ?: continue
        val small = shrink(bytes, maxW, maxH) ?: continue
        val tmp = File(dir, file.name + ".part")
        tmp.outputStream().use { small.compress(Bitmap.CompressFormat.JPEG, 85, it) }
        small.recycle()
        tmp.renameTo(file)
      } catch (e: Exception) {
        Log.w(CasamaWidget.TAG, "canvas picture fetch failed: ${e.message}")
      } finally {
        conn.disconnect()
      }
    }
  }

  /** Decodes [bytes] no larger than needed to cover [w]×[h], then scales it to just cover it. */
  private fun shrink(bytes: ByteArray, w: Int, h: Int): Bitmap? = runCatching {
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
    if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
    var sample = 1
    while (bounds.outWidth / (sample * 2) >= w && bounds.outHeight / (sample * 2) >= h) sample *= 2
    val decoded = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, BitmapFactory.Options().apply { inSampleSize = sample })
      ?: return null
    val scale = maxOf(w.toFloat() / decoded.width, h.toFloat() / decoded.height)
    if (scale >= 1f) return decoded
    val out = Bitmap.createScaledBitmap(decoded, (decoded.width * scale).toInt().coerceAtLeast(1), (decoded.height * scale).toInt().coerceAtLeast(1), true)
    if (out !== decoded) decoded.recycle()
    out
  }.getOrNull()

  /**
   * A one-off job at the next moment a placed Canvas widget changes by itself: a planned entry, a
   * countdown turning from days to a timer or a new day, an `until`. Replaced on every redraw; none
   * when nothing is planned or no Canvas widget is placed.
   */
  fun scheduleTick(context: Context) {
    val work = runCatching { WorkManager.getInstance(context.applicationContext) }.getOrNull() ?: return
    val now = System.currentTimeMillis()
    val next = if (placed(context)) CanvasLogic.nextTickMs(CanvasStore.shown(context, nowMs = now), now, ZoneId.systemDefault()) else null
    if (next == null) {
      work.cancelUniqueWork(TICK)
      return
    }
    work.enqueueUniqueWork(
      TICK,
      ExistingWorkPolicy.REPLACE,
      OneTimeWorkRequest.Builder(CanvasTickWorker::class.java)
        // A moment after, so the entry's time has surely come when it draws.
        .setInitialDelay(next - now + 2_000, TimeUnit.MILLISECONDS)
        .build(),
    )
  }
}

/** The switch to a planned entry: redraws from what is stored, no network, and plans the next one. */
class CanvasTickWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
  override fun doWork(): Result {
    CanvasRefresh.redraw(applicationContext)
    return Result.success()
  }
}

/**
 * Refresh pushes (§8.3, step 4): data-only FCM messages of kind "glance", with no content in them.
 * It listens to the same broadcast as Firebase's own receivers, as [LiveRunReceiver] does, so the
 * Dart handlers still see every message.
 */
class GlancePushReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    val extras = intent.extras ?: return
    if (extras.getString("kind") != "glance") return
    if (extras.containsKey("gcm.notification.title") || extras.containsKey("gcm.n.title")) return
    GlanceRefresh.now(context)
  }
}
