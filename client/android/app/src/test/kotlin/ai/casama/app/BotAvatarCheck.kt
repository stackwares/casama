package ai.casama.app

import ai.casama.app.canvas.MiniJson
import java.io.File

/**
 * Checks BotAvatarValue (the `image:<uuid>:<rrggbb><rrggbb>` parser) against the shared vectors in
 * packages/domain/test/fixtures/bot-avatar-vectors.json, the same file the TypeScript, Dart and
 * Swift parsers read. A plain `main` with no test library, like CanvasModelCheck: run it with
 * scripts/test-bot-avatar-kotlin.sh. BotArt itself needs Android's resources, so the mascot half
 * of the vectors is only checked to not be a picture.
 */
private var checks = 0

private fun expect(ok: Boolean, what: () -> String) {
  checks++
  if (!ok) throw AssertionError(what())
}

fun main() {
  val file = File(System.getProperty("vectors.file") ?: "../../../packages/domain/test/fixtures/bot-avatar-vectors.json")
  val root = MiniJson.parse(file.readText()) as Map<*, *>
  val vectors = root["vectors"] as List<*>
  expect(vectors.isNotEmpty()) { "no vectors in ${file.absolutePath}" }
  for (raw in vectors) {
    val v = raw as Map<*, *>
    val value = v["value"] as String?
    val picture = BotAvatarValue.picture(value)
    if (v["kind"] == "image") {
      val colors = (v["colors"] as List<*>).map { (it as String).removePrefix("#").toLong(16).let { c -> (0xFF000000L or c).toInt() } }
      expect(picture != null) { "$value should be a picture" }
      expect(picture!!.id == v["id"]) { "$value: id ${picture.id}, want ${v["id"]}" }
      expect(picture.top == colors[0] && picture.bottom == colors[1]) { "$value: colours" }
    } else {
      expect(picture == null) { "$value should not be a picture" }
    }
  }
  // `$` in a regex may stop before a trailing newline; a picture value has nothing after it.
  expect(BotAvatarValue.picture("image:6f1c2e9a-3b4d-4c5e-8f70-1a2b3c4d5e6f:7a90ff7de9f4\n") == null) { "trailing newline" }
  expect(!BotAvatarValue.isValidId("../etc/passwd") && BotAvatarValue.isValidId("6f1c2e9a-3b4d-4c5e-8f70-1a2b3c4d5e6f")) { "ids" }
  println("$checks checks, 0 failed")
}
