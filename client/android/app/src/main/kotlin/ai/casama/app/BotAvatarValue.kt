package ai.casama.app

/**
 * What `bots.avatar_url` says about a bot's own picture (docs/BOT-PICTURES-PLAN.md §5.1):
 * `image:<uuid>:<rrggbb><rrggbb>`, the picture's id and the two colours the server took from it.
 * No Android in here, so scripts/test-bot-avatar-kotlin.sh can check it against the shared vectors
 * (packages/domain/test/fixtures/bot-avatar-vectors.json) the TypeScript, Dart and Swift parsers
 * read too.
 */
object BotAvatarValue {
  /** A bot's picture: its id and its two colours as ARGB ints (opaque). */
  data class Picture(val id: String, val top: Int, val bottom: Int)

  // Exactly this and nothing around it: lowercase only, and Kotlin's `matches` must cover all of it.
  private val IMAGE = Regex("^image:([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}):([0-9a-f]{6})([0-9a-f]{6})$")
  private val UUID = Regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")

  /** The picture [avatar] names, or null for initials, mascots, old web links and typos. */
  fun picture(avatar: String?): Picture? {
    val m = IMAGE.matchEntire(avatar ?: return null) ?: return null
    val (id, a, b) = m.destructured
    return Picture(id, opaque(a), opaque(b))
  }

  /** Whether [id] is a lowercase uuid. Checked before an id becomes a file name or a URL. */
  fun isValidId(id: String) = UUID.matches(id)

  /** The ids of every picture named by [avatars]. */
  fun ids(avatars: Iterable<String?>): Set<String> = avatars.mapNotNull { picture(it)?.id }.toSet()

  private fun opaque(hex: String) = (0xFF000000L or hex.toLong(16)).toInt()
}
