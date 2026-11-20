package ai.casama.app.canvas

import java.io.File
import java.time.ZoneId

/**
 * Checks the Canvas widget's pure model (CanvasModel.kt, MiniJson.kt) against every shared sample
 * in packages/contracts/fixtures/canvases, the same files the server's and the other widgets'
 * tests read. A plain `main` with no test library, since the phone app has none: run it with
 * scripts/test-canvas-kotlin.sh. Exits non-zero on the first failure.
 */
private var checks = 0

private fun expect(ok: Boolean, what: () -> String) {
  checks++
  if (!ok) throw AssertionError(what())
}

private fun <T> eq(want: T, got: T, what: String) = expect(want == got) { "$what: want $want, got $got" }

private fun ms(iso: String) = CanvasDecode.ms(iso)!!

fun main() {
  val dir = File(System.getProperty("fixtures.dir") ?: "../../../packages/contracts/fixtures/canvases")
  val files = dir.listFiles { f -> f.name.endsWith(".json") }?.sortedBy { it.name }
    ?: throw AssertionError("no fixtures at ${dir.absolutePath}")
  expect(files.size >= 2) { "expected canvases.json and private.json, found ${files.size}" }

  // Every sample decodes, and every entry has what its template needs to draw.
  for (f in files) {
    val list = CanvasDecode.list(f.readText())
    expect(list.version.isNotEmpty()) { "${f.name}: no version" }
    expect(list.madeAtMs > 0) { "${f.name}: no made_at" }
    expect(list.items.isNotEmpty()) { "${f.name}: no items" }
    for (c in list.items) {
      expect(c.link.startsWith("/")) { "${f.name} ${c.name}: link isn't an app route" }
      expect(c.name.isNotEmpty() && c.bot.isNotEmpty()) { "${f.name}: a canvas without a name or bot" }
      if (list.isPrivate) expect(c.entries.isEmpty()) { "${f.name} ${c.name}: a private list with entries" }
      else expect(c.entries.isNotEmpty() && c.entries[0].atMs == null) { "${f.name} ${c.name}: entries[0] isn't the one showing now" }
      expect(c.entries.size <= 14) { "${f.name} ${c.name}: more than 14 entries" }
      for (e in c.entries) {
        expect(e.short.length <= 80 && e.tiny.length <= 24) { "${f.name} ${c.name}: short or tiny too long" }
        when (e.template) {
          Template.COUNTDOWN -> expect(e.targetMs != null) { "${c.name}: countdown without a target" }
          Template.NUMBER -> expect(e.value != null) { "${c.name}: number without a value" }
          Template.LIST -> expect(e.items.size in 1..5) { "${c.name}: list with ${e.items.size} items" }
          Template.PICTURE -> expect(e.backgroundPicture != null) { "${c.name}: picture without a picture" }
          Template.TEXT -> expect(e.text != null || e.title != null) { "${c.name}: text with nothing to say" }
        }
        if (e.look.background.kind == BackgroundKind.COLOR) expect(e.look.background.color != null) { "${c.name}: colour without one" }
        if (e.look.background.kind == BackgroundKind.GRADIENT) expect(e.look.background.from != null && e.look.background.to != null) { "${c.name}: gradient without colours" }
        e.backgroundPicture?.let { expect(CanvasLogic.safeHash(it)) { "${c.name}: picture hash $it isn't the route's" } }
      }
    }
  }

  val all = CanvasDecode.list(File(dir, "canvases.json").readText())
  // All five templates are in the sample.
  eq(Template.values().toSet(), all.items.flatMap { c -> c.entries.map { it.template } }.toSet(), "templates")

  val verse = all.items[0]
  eq("Daily verse", verse.name, "first canvas")
  eq(14, verse.entries.size, "rotation window")
  val v0 = verse.entries[0]
  eq(BackgroundKind.PICTURE, v0.look.background.kind, "verse background")
  eq("painting-night_sky", v0.backgroundPicture, "verse painting")
  eq(Font.SERIF, v0.look.font, "verse font")
  eq(true, v0.look.center, "verse align")
  eq(Ink.LIGHT, v0.look.ink, "verse ink")
  eq("📖", CanvasLogic.iconText(v0.look.icon), "emoji icon")
  eq(setOf("painting-night_sky"), CanvasLogic.pictures(verse), "verse pictures")

  // The timeline: entries[0] until the next `at`, then that one; ticks at the next switch.
  val now = ms("2027-03-10T09:00:00.000Z")
  eq(v0, CanvasLogic.current(verse, now), "showing now")
  eq(ms("2027-03-10T22:00:00.000Z"), CanvasLogic.nextSwitchMs(verse, now), "next switch")
  eq(verse.entries[1], CanvasLogic.current(verse, ms("2027-03-10T22:00:00.000Z")), "switched at its time")
  eq(verse.entries[2], CanvasLogic.current(verse, ms("2027-03-12T08:00:00.000Z")), "two switches later")
  eq(verse.entries[13], CanvasLogic.current(verse, ms("2030-01-01T00:00:00.000Z")), "the last stays")
  eq(null, CanvasLogic.nextSwitchMs(verse, ms("2030-01-01T00:00:00.000Z")), "nothing after the last")

  // Which canvas: Automatic is items[0]; a named one; a gone one is nothing; `until` passed is gone.
  eq(verse, CanvasLogic.choose(all, null, now), "automatic")
  eq("Streak", CanvasLogic.choose(all, "aaaaaaaa-0000-4000-8000-000000000003", now)?.name, "named")
  eq(null, CanvasLogic.choose(all, "aaaaaaaa-0000-4000-8000-00000000dead", now), "named but gone")
  eq(null, CanvasLogic.choose(all, "aaaaaaaa-0000-4000-8000-000000000002", ms("2027-04-03T00:00:00.000Z")), "until passed")
  eq(null, CanvasLogic.choose(null, null, now), "no list")

  // Countdown: days as text, a timer under a day, done at the target; ticks at midnight and a day before.
  val trip = all.items[1]
  val t = trip.entries[0]
  eq(Template.COUNTDOWN, t.template, "trip template")
  eq(BackgroundKind.GRADIENT, t.look.background.kind, "trip background")
  eq(0xFF0B3A53.toInt(), t.look.background.from, "gradient from")
  eq(0xFF1F7A8C.toInt(), t.look.background.to, "gradient to")
  eq(null, CanvasLogic.iconText("checklist"), "an icon name is skipped")
  val utc = ZoneId.of("UTC")
  eq(Countdown.Days(22, true), CanvasLogic.countdown(t, now, utc), "22 days to Tokyo")
  eq(Countdown.Timer(t.targetMs!!, true), CanvasLogic.countdown(t, ms("2027-03-31T12:00:00.000Z"), utc), "timer under a day")
  eq(Countdown.Done, CanvasLogic.countdown(t, ms("2027-04-01T02:00:00.000Z"), utc), "done after")
  eq(ms("2027-03-11T00:00:00.000Z"), CanvasLogic.countdownChangeMs(t, now, utc), "redraw at midnight")
  eq(ms("2027-03-31T01:00:00.000Z"), CanvasLogic.countdownChangeMs(t, ms("2027-03-31T00:30:00.000Z"), utc), "redraw a day before")
  eq(t.targetMs, CanvasLogic.countdownChangeMs(t, ms("2027-03-31T12:00:00.000Z"), utc), "redraw at the target")
  val up = t.copy(countUp = true)
  eq(Countdown.Timer(t.targetMs, false), CanvasLogic.countdown(up, ms("2027-04-01T05:00:00.000Z"), utc), "counting up under a day")
  eq(Countdown.Days(2, false), CanvasLogic.countdown(up, ms("2027-04-03T05:00:00.000Z"), utc), "counting up in days")
  eq(Countdown.Days(22, true), CanvasLogic.countdown(up, now, utc), "count up before the target counts down")
  // Days follow the person's calendar, not 24-hour blocks.
  eq(Countdown.Days(21, true), CanvasLogic.countdown(t, now, ZoneId.of("America/Los_Angeles")), "days in Los Angeles time")

  // Number: value, goal, unit; the ring's share.
  val streak = all.items[2].entries[0]
  eq(12.0, streak.value, "value")
  eq(30.0, streak.of, "of")
  eq("days", streak.unit, "unit")
  eq("12", CanvasLogic.formatValue(streak.value!!), "value text")
  eq("12.5", CanvasLogic.formatValue(12.5), "half")
  eq(0.4, CanvasLogic.share(streak.value, streak.of), "share")
  eq(null, CanvasLogic.share(12.0, null), "no goal")
  eq(0xFFFFF59D.toInt(), streak.look.background.color, "colour")
  eq(0xFFE65100.toInt(), streak.look.accent, "accent")
  eq(Ink.DARK, streak.look.ink, "dark ink")
  eq(Font.ROUNDED, streak.look.font, "rounded")
  eq(true, all.items[2].hideWhenLocked, "hide when locked")

  // List: items and done; the next day's list at 16:00.
  val today = all.items[3]
  eq(listOf(false, true, false, false), today.entries[0].items.map { it.done }, "done flags")
  eq(Ink.AUTO, today.entries[0].look.ink, "auto ink")
  eq("Tomorrow", CanvasLogic.current(today, ms("2027-03-10T16:00:00.000Z"))?.title, "list switches")

  // Picture: its own picture fills the background.
  val card = all.items[4].entries[0]
  eq("0123456789abcdef0123456789abcdef", card.backgroundPicture, "own picture")
  eq(Font.MONO, card.look.font, "mono")

  // The next redraw across the shown canvases: the list's 16:00 comes first.
  eq(ms("2027-03-10T16:00:00.000Z"), CanvasLogic.nextTickMs(all.items, now, utc), "next tick")

  // Private: names and bots, no entries, nothing to draw or fetch.
  val priv = CanvasDecode.list(File(dir, "private.json").readText())
  eq(true, priv.isPrivate, "private")
  eq(null, CanvasLogic.current(priv.items[0], now), "no entry")
  eq(emptySet<String>(), CanvasLogic.pictures(priv.items[0]), "no pictures")
  eq(null, CanvasLogic.nextTickMs(priv.items.filter { it.untilMs == null }, now, utc), "no ticks")

  // Sizes the server is told.
  eq("home_small", CanvasLogic.sizeName(110, 40, false), "2x1")
  eq("home_small", CanvasLogic.sizeName(110, 110, false), "2x2")
  eq("home_medium", CanvasLogic.sizeName(250, 110, false), "4x2")
  eq("home_large", CanvasLogic.sizeName(250, 250, false), "4x4")
  eq("keyguard", CanvasLogic.sizeName(250, 250, true), "lock screen")

  // The reader: escapes, surrogate pairs, numbers, and junk refused.
  eq(mapOf("a" to listOf(1.0, -2.5, true, null), "b" to "x\"\n\u00e9😀"), MiniJson.parse("""{"a":[1,-2.5e0,true,null],"b":"x\"\n\u00e9\ud83d\ude00"}"""), "mini json")
  expect(runCatching { CanvasDecode.list("[1,") }.isFailure) { "junk decoded" }
  expect(runCatching { CanvasDecode.list("{} x") }.isFailure) { "trailing text decoded" }

  println("OK: ${files.size} fixtures, $checks checks")
}
