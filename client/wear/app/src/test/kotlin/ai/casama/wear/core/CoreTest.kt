package ai.casama.wear.core

import java.io.File
import java.time.ZoneId
import java.time.ZonedDateTime
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.test.fail
import org.junit.Test

/**
 * The watch's pure Kotlin: decoding every shared sample answer (packages/contracts/fixtures/watch,
 * the same files the server's and the Apple Watch's tests read), the key and its fingerprint,
 * formatting, the offline queue and the screen decisions. Runs under Gradle (testDebugUnitTest)
 * and without it (scripts/test-wear-kotlin.sh).
 */
class CoreTest {
    private val fixtures: File = File(
        System.getProperty("fixtures.dir") ?: "../../../packages/contracts/fixtures/watch",
    )

    private fun read(name: String) = File(fixtures, name).readText()

    @Test
    fun decodesEveryFixture() {
        val files = fixtures.listFiles { f -> f.name.endsWith(".json") }?.sortedBy { it.name }
            ?: fail("no fixtures at ${fixtures.absolutePath}")
        assertTrue(files.size >= 10, "expected the 10 shared fixtures, found ${files.size}")
        for (f in files) {
            val text = f.readText()
            when {
                f.name == "glance.json" -> Decode.glance(text)
                f.name == "me.json" -> Decode.self(text)
                f.name == "code.json" -> Decode.code(text)
                f.name == "asked.json" -> Decode.asked(text)
                f.name == "chat.json" -> Decode.chat(text)
                f.name.startsWith("approval_") -> Decode.approval(text)
                f.name.startsWith("run_") -> Decode.run(text)
                else -> fail("no decoder for fixture ${f.name}: add one to the watch app")
            }
        }
    }

    @Test
    fun glanceFields() {
        val g = Decode.glance(read("glance.json"))
        assertEquals(2, g.needsCount)
        assertEquals(NeedKind.APPROVAL, g.needs[0].kind)
        assertEquals(Risk.MEDIUM, g.needs[0].risk)
        assertEquals(NeedKind.SUGGESTION, g.needs[1].kind)
        assertTrue(g.needs[1].urgent)
        assertEquals("mascot:focused", g.bots[0].avatar)
        assertEquals(BotStatus.WORKING, g.bots[0].status)
        assertNull(g.bots[1].step)
        assertEquals(1, g.runs.size)
        assertEquals(RunPhase.WORKING, g.runs[0].phase)
        assertEquals(Decode.parseTime("2026-11-19T09:13:02.000Z"), g.runs[0].startedAt)
        assertEquals("Inbox sweep", g.next[0].name)
        assertEquals(0.42, g.credits?.usedShare)
        assertEquals("☀️ What's on today?", g.starters[0].label)
        assertEquals("Three meetings today. Rain after 4.", g.brief?.text)
        assertFalse(g.private)
    }

    @Test
    fun glanceToleratesMissingRunsUnknownKeysAndBadItems() {
        val text = """
            {"version":"v1","org_id":"o","made_at":"nope","extra":{"x":1},
             "needs":{"count":1,"items":[{"kind":"approval","bot":"Milo"},
                                         {"kind":"newkind","id":"n2","risk":"weird","urgent":"yes"}]},
             "bots":[{"id":"b","name":"Ada","status":"sleeping","future":true}, 7, null],
             "next":"oops", "brief":null, "credits":{"used_share":4.2},
             "flags":{"private":true}}
        """.trimIndent()
        val g = Decode.glance(text)
        assertTrue(g.runs.isEmpty())
        assertNull(g.madeAt)
        assertEquals(1, g.needs.size, "the item with no id is dropped")
        assertEquals(NeedKind.OTHER, g.needs[0].kind)
        assertNull(g.needs[0].risk)
        assertFalse(g.needs[0].urgent)
        assertEquals(BotStatus.IDLE, g.bots.single().status)
        assertTrue(g.next.isEmpty())
        assertEquals(1.0, g.credits?.usedShare)
        assertTrue(g.private)
        assertFailsWith<DecodeException> { Decode.glance("[1,2]") }
        assertFailsWith<DecodeException> { Decode.glance("not json") }
    }

    @Test
    fun selfCodeAskedChat() {
        val me = Decode.self(read("me.json"))
        assertEquals("Oliver", me.personName)
        assertEquals("Home", me.orgName)
        assertEquals(AllowLevel.MEDIUM, me.prefs.allow)
        assertEquals(listOf("Yes", "No", "Tell me more", "Not now"), me.prefs.quickReplies)
        assertTrue(me.features.dictation)
        assertEquals("22222222-2222-4222-8222-222222222222", me.askBotId)

        val code = Decode.code(read("code.json"))
        assertEquals("KQ7M2XAB", code.code)
        assertEquals(3, code.pollEverySeconds)

        val asked = Decode.asked(read("asked.json"))
        assertEquals("Book Thursday with Dana", asked.heard)
        assertEquals("44444444-4444-4444-8444-444444444444", asked.runId)

        val chat = Decode.chat(read("chat.json"))
        assertEquals(3, chat.messages.size)
        assertTrue(chat.messages[1].fromUser)
        assertEquals(AttachmentKind.PAGE, chat.messages[2].attachments.single().kind)
        assertNull(chat.runId)
    }

    @Test
    fun approvalsAndRuns() {
        val medium = Decode.approval(read("approval_medium.json"))
        assertEquals(CanAllow.HOLD, medium.canAllow)
        assertEquals(3, medium.details.size)
        val high = Decode.approval(read("approval_high.json"))
        assertEquals(CanAllow.PHONE, high.canAllow)
        assertEquals(WhyPhone.PAYMENT, high.whyPhone)
        assertTrue(high.payment)

        val now = Decode.parseTime("2026-11-19T09:15:00Z")!!
        assertEquals(Logic.RequestUi.ALLOW_HOLD, Logic.requestUi(medium, now))
        assertEquals(Logic.RequestUi.PHONE_ONLY, Logic.requestUi(high, now))
        assertEquals(Logic.RequestUi.ALREADY_ANSWERED, Logic.requestUi(medium.copy(status = ApprovalStatus.APPROVED), now))
        assertEquals(Logic.RequestUi.ALREADY_ANSWERED, Logic.requestUi(medium, Decode.parseTime("2026-11-21T00:00:00Z")!!))
        // A server mistake never lets a payment or high risk through.
        assertEquals(Logic.RequestUi.PHONE_ONLY, Logic.requestUi(high.copy(canAllow = CanAllow.TAP), now))
        assertEquals(Logic.RequestUi.ALLOW_TAP, Logic.requestUi(medium.copy(canAllow = CanAllow.TAP, risk = Risk.LOW), now))
        // Unknown values read as the safe side.
        val odd = Decode.approval("""{"id":"a","risk":"extreme","can_allow":"swipe"}""")
        assertEquals(Risk.HIGH, odd.risk)
        assertEquals(CanAllow.PHONE, odd.canAllow)

        val working = Decode.run(read("run_working.json"))
        assertEquals(RunPhase.WORKING, working.phase)
        assertTrue(working.phase.live)
        val needsOk = Decode.run(read("run_needs_ok.json"))
        assertEquals(RunPhase.NEEDS_OK, needsOk.phase)
        assertEquals("55555555-5555-4555-8555-555555555555", needsOk.approval?.id)
        val finished = Decode.run(read("run_finished.json"))
        assertFalse(finished.phase.live)
        assertNotNull(finished.reply)
        assertTrue(finished.reply.canSpeak)
        assertEquals(88_000L, finished.endedAt!! - finished.startedAt!!)
    }

    @Test
    fun keyAndFingerprint() {
        val key = WatchKey.fromBytes(ByteArray(32))
        assertEquals("cwt_" + "A".repeat(43), key)
        assertEquals(47, key.length)
        assertTrue(WatchKey.looksValid(key))
        // Known vector: printf '%s' "casama-watch-key:cwt_AAA…A" | shasum -a 256
        assertEquals("ac37bdc0613002302fb038066df0bce2d9912dce2e82f625e1f7eacd95677778", WatchKey.fingerprint(key))
        val bytes = ByteArray(32) { (it * 7 + 250).toByte() }
        val k2 = WatchKey.fromBytes(bytes)
        assertTrue(WatchKey.looksValid(k2))
        assertTrue(Regex("^[0-9a-f]{64}$").matches(WatchKey.fingerprint(k2)))
        assertFalse(WatchKey.looksValid("cwt_short"))
        assertFalse(WatchKey.looksValid(null))
        assertFailsWith<IllegalArgumentException> { WatchKey.fromBytes(ByteArray(16)) }
    }

    @Test
    fun formatting() {
        assertEquals("KQ7M 2XAB", Format.code("KQ7M2XAB"))
        assertEquals("KQ7M 2XAB", Format.code("kq7m-2xab"))
        assertEquals("0:00", Format.elapsed(-5000))
        assertEquals("0:42", Format.elapsed(42_000))
        assertEquals("2:14", Format.elapsed(134_000))
        assertEquals("1:02:03", Format.elapsed(3_723_000))
        assertEquals(42, Format.percent(0.42))
        assertEquals(100, Format.percent(3.0))
        assertNull(Format.percent(null))
    }

    @Test
    fun relativeTimes() {
        val zone = ZoneId.of("Asia/Manila")
        val now = ZonedDateTime.of(2026, 11, 19, 21, 0, 0, 0, zone).toInstant().toEpochMilli()
        assertEquals(Format.Until.Now, Format.until(now, now - 60_000, zone))
        assertEquals(Format.Until.Now, Format.until(now, now + 20_000, zone))
        assertEquals(Format.Until.Minutes(1), Format.until(now, now + 31_000, zone))
        assertEquals(Format.Until.Minutes(12), Format.until(now, now + 11 * 60_000 + 1, zone))
        assertEquals(Format.Until.Minutes(59), Format.until(now, now + 59 * 60_000, zone))
        assertEquals(Format.Until.At(0), Format.until(now, now + 2 * 3_600_000, zone))
        assertEquals(Format.Until.At(1), Format.until(now, now + 10 * 3_600_000, zone))
        assertEquals(1, Format.dayOffset(now, now + 3 * 3_600_000 + 1, zone))
        assertFalse(Format.isStale(now - 60_000, now))
        assertTrue(Format.isStale(now - 16 * 60_000, now))
        assertTrue(Format.isStale(null, now))
        assertTrue(Format.isStale(now + 10 * 60_000, now), "a save from the future is a clock problem")
    }

    @Test
    fun queueAging() {
        val now = 1_800_000_000_000L
        fun ask(id: String, ageMin: Long) = QueuedAsk(id, "b", null, "hi $id", null, null, now - ageMin * 60_000, "app")
        var q = emptyList<QueuedAsk>()
        q = AskQueue.add(q, ask("a", 2))
        q = AskQueue.add(q, ask("b", 11))
        q = AskQueue.add(q, ask("c", 60 * 25))
        q = AskQueue.add(q, ask("a", 1)) // same id replaces
        assertEquals(3, q.size)
        val split = AskQueue.split(q, now)
        assertEquals(listOf("a"), split.sendNow.map { it.id })
        assertEquals(listOf("b"), split.askFirst.map { it.id })
        assertEquals(listOf("c"), split.dropped.map { it.id })
        assertFalse(AskQueue.needsConfirm(ask("x", 10), now))
        assertTrue(AskQueue.needsConfirm(ask("x", 10).copy(askedAt = now - 10 * 60_000 - 1), now))
        // Round trip, and a bad store reads as empty.
        val back = AskQueue.decode(AskQueue.encode(q))
        assertEquals(q, back)
        assertTrue(AskQueue.decode("garbage").isEmpty())
        assertTrue(AskQueue.decode("""[{"id":"x","bot_id":"b","asked_at":1}]""").isEmpty(), "no text, no audio")
        // At most MAX, newest kept.
        var many = emptyList<QueuedAsk>()
        for (i in 0 until 15) many = AskQueue.add(many, ask("m$i", 15L - i))
        assertEquals(AskQueue.MAX, many.size)
        assertEquals("m14", many.last().id)
        assertEquals(listOf("a", "c"), AskQueue.remove(q, "b").map { it.id }.sorted())
    }

    @Test
    fun nowScreen() {
        val g = Decode.glance(read("glance.json"))
        val rows = Logic.nowRows(g)
        assertTrue(rows[0] is Logic.NowRow.Needs)
        assertTrue(rows[1] is Logic.NowRow.Working)
        assertTrue(rows.any { it is Logic.NowRow.UpNext })
        assertFalse(Logic.allClear(g))
        val quiet = g.copy(needsCount = 0, needs = emptyList(), runs = emptyList(), bots = g.bots.map { it.copy(status = BotStatus.IDLE) })
        assertTrue(Logic.allClear(quiet))
        // An older server without runs: working bots show instead.
        val old = g.copy(runs = emptyList())
        assertTrue(Logic.nowRows(old).any { it is Logic.NowRow.WorkingBot })

        val approval = g.needs[0]
        assertEquals(Logic.NeedUi.REVIEW, Logic.needUi(approval, AllowLevel.MEDIUM))
        assertEquals(Logic.NeedUi.ALLOW, Logic.needUi(approval.copy(risk = Risk.LOW), AllowLevel.MEDIUM))
        assertEquals(Logic.NeedUi.REVIEW, Logic.needUi(approval.copy(risk = Risk.LOW), AllowLevel.NONE))
        assertEquals(Logic.NeedUi.SUGGESTION, Logic.needUi(g.needs[1], AllowLevel.MEDIUM))
        assertEquals(Logic.NeedUi.OPEN_ON_PHONE, Logic.needUi(approval.copy(kind = NeedKind.TAKEOVER), AllowLevel.MEDIUM))

        assertEquals("33333333-3333-4333-8333-333333333333", Logic.askBot(g, "33333333-3333-4333-8333-333333333333", null)?.id)
        assertEquals("22222222-2222-4222-8222-222222222222", Logic.askBot(g, "gone", "22222222-2222-4222-8222-222222222222")?.id)
        assertEquals("Inbox sweep", Logic.upNext(g).first?.name)
        assertNull(Logic.upNext(g).second)

        assertTrue(Logic.showWords(private = false, showDetails = true, ambient = false, hideWhenWristDown = true))
        assertFalse(Logic.showWords(private = false, showDetails = true, ambient = true, hideWhenWristDown = true))
        assertTrue(Logic.showWords(private = false, showDetails = true, ambient = true, hideWhenWristDown = false))
        assertFalse(Logic.showWords(private = true, showDetails = true, ambient = false, hideWhenWristDown = false))
    }

    @Test
    fun pushesAndPhoneLink() {
        val p = WatchPush.parse(mapOf("kind" to "approval", "approval_id" to "a1", "risk" to "low", "link" to "/approvals/a1", "title" to "Milo"))!!
        assertEquals(WatchPush.Kind.APPROVAL, p.kind)
        assertTrue(Logic.pushAllows(p, AllowLevel.MEDIUM))
        assertFalse(Logic.pushAllows(p.copy(risk = Risk.MEDIUM), AllowLevel.MEDIUM))
        assertFalse(Logic.pushAllows(p, AllowLevel.NONE))
        assertEquals("approval:a1", p.key)
        assertEquals(WatchPush.Kind.OTHER, WatchPush.parse(mapOf("kind" to "approval"))!!.kind, "no id: open on phone")
        assertEquals("/", WatchPush.parse(mapOf("kind" to "reply", "link" to "https://evil"))!!.link)
        assertNull(WatchPush.parse(mapOf("title" to "x")))
        assertEquals(WatchPush.Kind.OTHER, WatchPush.parse(mapOf("kind" to "brand_new"))!!.kind)

        val signIn = LinkMessage.SignIn("r1", "f".repeat(64), Encode.Device("Pixel Watch", "Pixel Watch 3", "0.1.0", "15"))
        assertEquals(signIn, LinkMessage.decode(signIn.encode().toByteArray()))
        val ok = LinkMessage.decode("""{"type":"signed_in","request_id":"r1","server":"https://api.casama.ai/","org_id":"o","org_name":"Home","person_name":"Oliver"}""")
        assertEquals(LinkMessage.SignedIn("r1", "https://api.casama.ai", "o", "Home", "Oliver"), ok)
        assertNull(LinkMessage.decode("""{"type":"signed_in","server":"http://evil.example.com"}"""), "no plain http over the internet")
        assertNotNull(LinkMessage.decode("""{"type":"context","server":"http://192.168.1.5:8080","org_id":"o"}"""))
        assertEquals(LinkMessage.SignOut, LinkMessage.decode("""{"type":"sign_out"}"""))
        assertNull(LinkMessage.decode("""{"type":"later_thing"}"""))
        assertNull(LinkMessage.decode("{{"))
    }

    @Test
    fun sseAndEncoding() {
        val sse = SseParser()
        val lines = listOf(": keep-alive", "event: run", "data: {\"id\":\"r\",", "data: \"phase\":\"working\"}", "", "", "data: x", "")
        val events = lines.mapNotNull { sse.feed(it) }
        assertEquals(2, events.size)
        assertEquals("run", events[0].name)
        assertEquals("{\"id\":\"r\",\n\"phase\":\"working\"}", events[0].data)
        assertEquals("message", events[1].name)

        val body = Decode.parse(Encode.ask("b", null, "hi", null, null, "en", null, "app"))
        assertEquals("hi", body.str("text"))
        assertNull(body.strOrNull("conversation_id"))
        assertNull(body["audio"])
        val audio = Decode.parse(Encode.ask("b", "c", null, "AAAA", "audio/mp4", null, "2026-11-19T09:00:00Z", "notification"))
        assertEquals("audio/mp4", audio.obj("audio")?.str("mime"))
        assertEquals("c", audio.str("conversation_id"))
        assertEquals("approved", Decode.parse(Encode.decision(true)).str("decision"))
        assertNull(Decode.parse(Encode.decision(true))["always_allow"], "never Always Allow from a watch")
        assertEquals("/", Decode.parse(Encode.handoff("https://x", "t")).str("link"))
        val code = Decode.parse(Encode.codeRequest("f", Encode.Device("", null, "0.1.0", null)))
        assertEquals("wearos", code.str("platform"))
        assertEquals("Wear OS", code.str("name"))
        val clear = Decode.parse(Encode.selfUpdate(null, "0.1.0", null))
        assertTrue(clear.containsKey("push_token"))
        assertNull(clear.strOrNull("push_kind"))
    }
}
