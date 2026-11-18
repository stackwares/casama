package ai.casama.app

import android.content.Context
import android.content.SharedPreferences
import android.text.format.DateFormat
import android.text.format.DateUtils
import java.time.OffsetDateTime
import java.util.Calendar
import org.json.JSONArray
import org.json.JSONObject

/**
 * What the widgets read (D-405, docs/WIDGETS-PLAN.md §8.1 and §17): the glance the app (or
 * [GlanceRefresh]) wrote into home_widget's `HomeWidgetPreferences`, the widgets' words beside it,
 * and whether the person is signed in. Parsed with org.json into small classes, once per change.
 *
 * Native code holds no copy of the app's text except the English fallbacks in [Words], used when
 * the app hasn't written `glance_words` yet.
 */
object GlanceStore {
  const val PREFS = "HomeWidgetPreferences"
  const val KEY_GLANCE = "glance"
  const val KEY_WORDS = "glance_words"
  const val KEY_SERVER = "glance_server"
  const val KEY_SIGNED_IN = "glance_signed_in"
  /** Written by the app when the server has no /v1/glance (§6.6, "server too old"): `"1"`. */
  const val KEY_UNSUPPORTED = "glance_unsupported"
  /** When [GlanceRefresh] last heard "not changed" from the server (ms): the data is that fresh. */
  const val KEY_CHECKED_AT = "glance_checked_at"

  /** Older than this, a widget claims nothing about now and says "as of" (§4, principle 5). */
  const val STALE_MS = 10 * 60 * 1000L

  data class Need(
    val kind: String,
    val id: String,
    val botId: String,
    val bot: String,
    val botAvatar: String,
    val text: String,
    val risk: String?,
    val urgent: Boolean,
    val createdAtMs: Long,
    val link: String,
  ) {
    /** Allow and Deny in place: a low-risk approval only (decision 5). Dart checks again. */
    val answersInPlace get() = kind == "approval" && risk == "low"
  }

  data class Bot(
    val id: String,
    val name: String,
    val avatar: String,
    val status: String,
    val step: String?,
    val lastText: String?,
    val lastAtMs: Long?,
    val busyAtMs: Long?,
    val link: String,
  )

  data class Routine(
    val id: String,
    val botId: String,
    val name: String,
    val bot: String,
    val botAvatar: String,
    val nextAtMs: Long?,
    val every: String,
    val enabled: Boolean,
    val link: String,
  )

  data class Brief(
    val botId: String,
    val bot: String,
    val botAvatar: String,
    val text: String?,
    val atMs: Long?,
    val nextAtMs: Long?,
    val link: String,
  )

  data class Done(val botId: String, val bot: String, val botAvatar: String, val title: String, val atMs: Long, val link: String)

  data class Creation(
    val id: String,
    val kind: String,
    val title: String,
    val bot: String?,
    val hasCover: Boolean,
    val version: Int,
    val atMs: Long,
    val link: String,
  )

  data class Task(val id: String, val title: String, val status: String, val bot: String?, val link: String)

  data class TaskCounts(val todo: Int, val inProgress: Int, val inReview: Int, val blocked: Int)

  data class Credits(
    val billing: Boolean,
    val unlimited: Boolean,
    val plan: String?,
    val usedShare: Double?,
    val leftUsd: Double?,
    val todayUsd: Double,
    val monthUsd: Double,
    val dailyCapUsd: Double?,
    val dailyUsedUsd: Double?,
    val resetsAtMs: Long?,
  )

  data class Starter(val emoji: String, val text: String)

  data class Glance(
    val version: String,
    val madeAtMs: Long,
    val orgId: String,
    val needsCount: Int,
    val needs: List<Need>,
    val bots: List<Bot>,
    val next: List<Routine>,
    val brief: Brief?,
    val lately: List<Done>,
    val recent: List<Creation>,
    val taskCounts: TaskCounts,
    val tasks: List<Task>,
    val credits: Credits?,
    val starters: List<Starter>,
    val isPrivate: Boolean,
    val hideReplyText: Boolean,
  )

  /** Which of the §6.6 states the widgets are in. */
  enum class State { SIGNED_OUT, FIRST_LOAD, UPDATE_SERVER, NO_BOTS, READY }

  /**
   * One read of the store, as every widget draws it. [stale]: the data is over ten minutes old, so
   * nothing claims "working" and [asOf] says when it was true.
   */
  class Snapshot(
    val state: State,
    val glance: Glance?,
    val words: Words,
    val stale: Boolean,
    val asOf: String?,
    /** The store itself: the live run (LiveRun.refreshWidget) and the strings an older app wrote. */
    val prefs: SharedPreferences,
  ) {
    val isPrivate get() = glance?.isPrivate == true
  }

  private var cachedRaw: String? = null
  private var cached: Glance? = null

  fun prefs(context: Context): SharedPreferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

  fun load(context: Context): Snapshot {
    val p = prefs(context)
    // Read loosely: home_widget stores whatever type Dart passed, and a wrong type mustn't crash.
    val all = p.all
    val words = Words.from(all[KEY_WORDS] as? String)
    val glance = parseCached(all[KEY_GLANCE] as? String)
    val state = when {
      !flag(all[KEY_SIGNED_IN]) -> State.SIGNED_OUT
      glance == null && flag(all[KEY_UNSUPPORTED]) -> State.UPDATE_SERVER
      glance == null -> State.FIRST_LOAD
      glance.bots.isEmpty() -> State.NO_BOTS
      else -> State.READY
    }
    val freshAt = maxOf(glance?.madeAtMs ?: 0L, (all[KEY_CHECKED_AT] as? Number)?.toLong() ?: 0L)
    val stale = glance != null && System.currentTimeMillis() - freshAt > STALE_MS
    val asOf = if (stale) words.fill("as_of", "time" to time(context, freshAt)) else null
    return Snapshot(state, glance, words, stale, asOf, p)
  }

  /** `"1"` as §17 says, or a true written by mistake. */
  fun flag(v: Any?) = v == "1" || v == true || v == "true"

  /** Whether the person is signed in, as the app last said. */
  fun signedIn(context: Context) = flag(prefs(context).all[KEY_SIGNED_IN])

  @Synchronized
  private fun parseCached(raw: String?): Glance? {
    if (raw == null) return null
    if (raw == cachedRaw) return cached
    cached = parse(raw)
    cachedRaw = raw
    return cached
  }

  /** The glance from its JSON (packages/contracts/src/glance.ts), or null when it isn't one. */
  fun parse(raw: String): Glance? = runCatching {
    val o = JSONObject(raw)
    val needs = o.optJSONObject("needs")
    val tasks = o.optJSONObject("tasks")
    val counts = tasks?.optJSONObject("counts")
    val flags = o.optJSONObject("flags")
    Glance(
      version = o.optString("version"),
      madeAtMs = ms(o.str("made_at")) ?: 0L,
      orgId = o.optString("org_id"),
      needsCount = needs?.optInt("count") ?: 0,
      needs = needs?.optJSONArray("items").objects().map {
        Need(
          kind = it.optString("kind"),
          id = it.optString("id"),
          botId = it.optString("bot_id"),
          bot = it.optString("bot"),
          botAvatar = it.optString("bot_avatar"),
          text = it.optString("text"),
          risk = it.str("risk"),
          urgent = it.optBoolean("urgent"),
          createdAtMs = ms(it.str("created_at")) ?: 0L,
          link = it.link(),
        )
      },
      bots = o.optJSONArray("bots").objects().map {
        Bot(
          id = it.optString("id"),
          name = it.optString("name"),
          avatar = it.optString("avatar"),
          status = it.optString("status", "idle"),
          step = it.str("step"),
          lastText = it.str("last_text"),
          lastAtMs = ms(it.str("last_at")),
          busyAtMs = ms(it.str("busy_at")),
          link = it.link(),
        )
      },
      next = o.optJSONArray("next").objects().map {
        Routine(
          id = it.optString("id"),
          botId = it.optString("bot_id"),
          name = it.optString("name"),
          bot = it.optString("bot"),
          botAvatar = it.optString("bot_avatar"),
          nextAtMs = ms(it.str("next_at")),
          every = it.optString("every"),
          enabled = it.optBoolean("enabled", true),
          link = it.link(),
        )
      },
      brief = o.optJSONObject("brief")?.let {
        Brief(
          botId = it.optString("bot_id"),
          bot = it.optString("bot"),
          botAvatar = it.optString("bot_avatar"),
          text = it.str("text"),
          atMs = ms(it.str("at")),
          nextAtMs = ms(it.str("next_at")),
          link = it.link(),
        )
      },
      lately = o.optJSONArray("lately").objects().map {
        Done(it.optString("bot_id"), it.optString("bot"), it.optString("bot_avatar"), it.optString("title"), ms(it.str("at")) ?: 0L, it.link())
      },
      recent = o.optJSONArray("recent").objects().map {
        Creation(
          id = it.optString("id"),
          kind = it.optString("kind", "file"),
          title = it.optString("title"),
          bot = it.str("bot"),
          hasCover = it.optBoolean("has_cover"),
          version = it.optInt("version"),
          atMs = ms(it.str("at")) ?: 0L,
          link = it.link(),
        )
      },
      taskCounts = TaskCounts(
        counts?.optInt("todo") ?: 0,
        counts?.optInt("in_progress") ?: 0,
        counts?.optInt("in_review") ?: 0,
        counts?.optInt("blocked") ?: 0,
      ),
      tasks = tasks?.optJSONArray("items").objects().map {
        Task(it.optString("id"), it.optString("title"), it.optString("status"), it.str("bot"), it.link())
      },
      credits = o.optJSONObject("credits")?.let {
        Credits(
          billing = it.optBoolean("billing"),
          unlimited = it.optBoolean("unlimited"),
          plan = it.str("plan"),
          usedShare = it.num("used_share"),
          leftUsd = it.num("left_usd"),
          todayUsd = it.num("today_usd") ?: 0.0,
          monthUsd = it.num("month_usd") ?: 0.0,
          dailyCapUsd = it.num("daily_cap_usd"),
          dailyUsedUsd = it.num("daily_used_usd"),
          resetsAtMs = ms(it.str("resets_at")),
        )
      },
      starters = o.optJSONArray("starters").objects().map { Starter(it.optString("emoji"), it.optString("text")) },
      isPrivate = flags?.optBoolean("private") ?: false,
      hideReplyText = flags?.optBoolean("hide_reply_text") ?: false,
    )
  }.getOrNull()

  private fun JSONArray?.objects(): List<JSONObject> =
    if (this == null) emptyList() else (0 until length()).mapNotNull { optJSONObject(it) }

  /** A string value, or null for JSON null, a missing key or an empty string. */
  private fun JSONObject.str(key: String): String? =
    if (isNull(key)) null else optString(key).takeIf { it.isNotEmpty() }

  private fun JSONObject.num(key: String): Double? =
    if (isNull(key) || !has(key)) null else optDouble(key).takeIf { !it.isNaN() }

  /** An app route; anything that isn't one opens the app's start. */
  private fun JSONObject.link(): String = optString("link").takeIf { it.startsWith("/") } ?: "/"

  private fun ms(iso: String?): Long? =
    iso?.let { runCatching { OffsetDateTime.parse(it).toInstant().toEpochMilli() }.getOrNull() }

  // MARK: Formatting shared by the widgets

  /** "9:41" in the phone's own 12 or 24 hour style. */
  fun time(context: Context, ms: Long): String = DateFormat.getTimeFormat(context).format(ms)

  /** "9:00" today, else "Fri", else "18 Nov": the short form a routine's time takes in a row. */
  fun shortWhen(context: Context, ms: Long): String {
    val now = Calendar.getInstance()
    val then = Calendar.getInstance().apply { timeInMillis = ms }
    val sameDay = now.get(Calendar.YEAR) == then.get(Calendar.YEAR) && now.get(Calendar.DAY_OF_YEAR) == then.get(Calendar.DAY_OF_YEAR)
    return when {
      sameDay -> time(context, ms)
      ms - System.currentTimeMillis() < 6 * DateUtils.DAY_IN_MILLIS ->
        DateUtils.formatDateTime(context, ms, DateUtils.FORMAT_SHOW_WEEKDAY or DateUtils.FORMAT_ABBREV_WEEKDAY)
      else -> DateUtils.formatDateTime(context, ms, DateUtils.FORMAT_SHOW_DATE or DateUtils.FORMAT_ABBREV_MONTH or DateUtils.FORMAT_NO_YEAR)
    }
  }

  /** "in 18 min", "2 hours ago": the phone's own relative words. */
  fun relative(ms: Long): String =
    DateUtils.getRelativeTimeSpanString(ms, System.currentTimeMillis(), DateUtils.MINUTE_IN_MILLIS, DateUtils.FORMAT_ABBREV_RELATIVE).toString()

  /** "$4.20". */
  fun usd(v: Double): String = if (v >= 100) "$" + Math.round(v) else "$" + String.format(java.util.Locale.US, "%.2f", v)
}

/**
 * The widgets' words (§17): the app's own from `app_en.arb`, written as `glance_words`, with an
 * English copy here for when they're missing. Placeholders: `{bot}`, `{time}`, `{n}`, `{amount}`,
 * `{title}`.
 */
class Words(private val saved: JSONObject?) {
  operator fun get(key: String): String =
    saved?.optString(key)?.takeIf { it.isNotEmpty() } ?: defaults[key] ?: key

  fun fill(key: String, vararg values: Pair<String, String>): String =
    values.fold(get(key)) { s, (k, v) -> s.replace("{$k}", v) }

  companion object {
    fun from(raw: String?) = Words(raw?.let { runCatching { JSONObject(it) }.getOrNull() })

    val defaults = mapOf(
      "needs_you" to "Needs you",
      "all_clear" to "All clear",
      "allow" to "Allow",
      "deny" to "Deny",
      "review" to "Review",
      "open" to "Open",
      "do_it" to "Do it",
      "run_now" to "Run now",
      "started" to "Started",
      "stop" to "Stop",
      "ask" to "Ask",
      "ask_bot" to "Ask {bot}",
      "talk" to "Talk",
      "try" to "Try",
      "up_next" to "Up next",
      "no_routines" to "No routines yet",
      "working" to "Working",
      "waiting" to "Waiting for you",
      "idle" to "Idle",
      "off" to "Turned off",
      "replied_at" to "Replied {time}",
      "brief" to "Brief",
      "brief_at" to "Brief at {time}",
      "no_brief" to "No brief yet",
      "today" to "Today",
      "credits" to "Credits",
      "credits_left" to "{amount} left",
      "spent_today" to "{amount} today",
      "used_pct" to "{n}% used",
      "resets_at" to "Resets {time}",
      "finished" to "Finished",
      "library" to "Library",
      "no_creations" to "Nothing made yet",
      "tasks" to "Tasks",
      "todo" to "To do",
      "in_progress" to "In progress",
      "in_review" to "In review",
      "blocked" to "Blocked",
      "sign_in" to "Open Casama to sign in",
      "no_bots" to "Meet your first bot",
      "as_of" to "As of {time}",
      "update_server" to "Update your Casama server to use this widget",
      "needs_ok_from" to "{bot} needs your OK",
      "suggests" to "{bot} suggests",
      "take_over" to "{bot} wants you to take over",
      "next_brief" to "Next brief {time}",
      "nothing_next" to "Nothing coming up",
    )
  }
}
