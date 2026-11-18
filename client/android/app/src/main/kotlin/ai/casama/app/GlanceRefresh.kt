package ai.casama.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
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
 * last widget is removed or the key is dropped (sign-out).
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
    if (key.isNullOrEmpty()) File(context.filesDir, COVERS_DIR).deleteRecursively()
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
  override fun doWork(): Result = when (GlanceRefresh.fetch(applicationContext)) {
    // A one-off from a push retries a couple of times; the periodic job just waits for its next turn.
    GlanceRefresh.Outcome.FAILED -> if (runAttemptCount < 2 && GlanceRefresh.TAG_PERIODIC !in tags) Result.retry() else Result.success()
    else -> Result.success()
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
