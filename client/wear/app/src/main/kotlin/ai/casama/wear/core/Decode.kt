package ai.casama.wear.core

import java.time.OffsetDateTime
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.longOrNull

/**
 * Tolerant decoding of the server's answers. A watch must never crash on bad or newer server data:
 * unknown keys are ignored, missing ones get a safe default, a broken list item is dropped, and an
 * unknown enum value maps to the nearest safe one. A value without the one field it can't do
 * without (an id) is [DecodeException].
 */
object Decode {
    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

    fun parse(text: String): JsonObject =
        try {
            json.parseToJsonElement(text) as? JsonObject ?: throw DecodeException("not an object")
        } catch (e: DecodeException) {
            throw e
        } catch (e: Exception) {
            throw DecodeException(e.message ?: "bad json")
        }

    fun glance(text: String): Glance = glance(parse(text))
    fun self(text: String): WatchSelf = self(parse(text))
    fun code(text: String): WatchCode = code(parse(text))
    fun chat(text: String): WatchChat = chat(parse(text))
    fun asked(text: String): WatchAsked = asked(parse(text))
    fun approval(text: String): WatchApproval = approval(parse(text))
    fun run(text: String): WatchRun = run(parse(text))

    fun glance(o: JsonObject): Glance {
        val needs = o.obj("needs")
        val items = needs?.list("items") { need(it) } ?: emptyList()
        val flags = o.obj("flags")
        return Glance(
            version = o.str("version"),
            madeAt = o.time("made_at"),
            orgId = o.str("org_id"),
            needsCount = (needs?.int("count") ?: items.size).coerceAtLeast(0),
            needs = items,
            bots = o.list("bots") { bot(it) },
            runs = o.list("runs") { glanceRun(it) },
            next = o.list("next") { routine(it) },
            brief = o.obj("brief")?.let { runCatching { brief(it) }.getOrNull() },
            credits = o.obj("credits")?.let { credits(it) },
            starters = o.list("starters") { s ->
                GlanceStarter(s.str("emoji"), s.str("text")).takeIf { it.text.isNotBlank() }
            },
            private = flags?.bool("private") ?: false,
            hideReplyText = flags?.bool("hide_reply_text") ?: false,
        )
    }

    private fun need(o: JsonObject) = GlanceNeed(
        kind = when (o.str("kind")) {
            "approval" -> NeedKind.APPROVAL
            "takeover" -> NeedKind.TAKEOVER
            "suggestion" -> NeedKind.SUGGESTION
            else -> NeedKind.OTHER
        },
        id = o.id(),
        botId = o.str("bot_id"),
        bot = o.str("bot"),
        botAvatar = o.str("bot_avatar"),
        text = o.str("text"),
        risk = risk(o.strOrNull("risk")),
        urgent = o.bool("urgent"),
        createdAt = o.time("created_at"),
        link = o.str("link"),
    )

    private fun bot(o: JsonObject) = GlanceBot(
        id = o.id(),
        name = o.str("name"),
        avatar = o.str("avatar"),
        status = botStatus(o.str("status")),
        step = o.strOrNull("step"),
        lastText = o.strOrNull("last_text"),
        lastAt = o.time("last_at"),
        busyAt = o.time("busy_at"),
        link = o.str("link"),
    )

    private fun glanceRun(o: JsonObject) = GlanceRun(
        id = o.id(),
        botId = o.str("bot_id"),
        bot = o.str("bot"),
        botAvatar = o.str("bot_avatar"),
        phase = phase(o.str("phase")),
        step = o.str("step"),
        steps = o.int("steps"),
        startedAt = o.time("started_at"),
        approvalId = o.strOrNull("approval_id"),
        risk = risk(o.strOrNull("risk")),
        link = o.str("link"),
    )

    private fun routine(o: JsonObject) = GlanceRoutine(
        id = o.id(),
        botId = o.str("bot_id"),
        name = o.str("name"),
        bot = o.str("bot"),
        botAvatar = o.str("bot_avatar"),
        nextAt = o.time("next_at"),
        every = o.str("every"),
        enabled = o.bool("enabled", true),
        link = o.str("link"),
    )

    private fun brief(o: JsonObject) = GlanceBrief(
        botId = o.str("bot_id"),
        bot = o.str("bot"),
        botAvatar = o.str("bot_avatar"),
        text = o.strOrNull("text")?.takeIf { it.isNotBlank() },
        at = o.time("at"),
        nextAt = o.time("next_at"),
        link = o.str("link"),
    )

    private fun credits(o: JsonObject) = GlanceCredits(
        billing = o.bool("billing"),
        unlimited = o.bool("unlimited"),
        plan = o.strOrNull("plan"),
        usedShare = o.double("used_share")?.coerceIn(0.0, 1.0),
        leftUsd = o.double("left_usd"),
    )

    fun self(o: JsonObject): WatchSelf {
        val prefs = o.obj("prefs")
        val features = o.obj("features")
        return WatchSelf(
            keyId = o.str("key_id"),
            orgId = o.str("org_id"),
            orgName = o.str("org_name"),
            personName = o.obj("person")?.str("name") ?: "",
            prefs = WatchPrefs(
                allow = when (prefs?.str("allow")) {
                    "low" -> AllowLevel.LOW
                    "none" -> AllowLevel.NONE
                    else -> AllowLevel.MEDIUM
                },
                showDetails = prefs?.bool("show_details", true) ?: true,
                quickReplies = prefs?.strings("quick_replies")?.filter { it.isNotBlank() }?.take(6) ?: emptyList(),
            ),
            hideReplyText = o.bool("hide_reply_text"),
            askBotId = o.strOrNull("ask_bot_id"),
            features = WatchFeatures(
                dictation = features?.bool("dictation") ?: false,
                speech = features?.bool("speech") ?: false,
                outOfCredits = features?.bool("out_of_credits") ?: false,
            ),
        )
    }

    fun code(o: JsonObject): WatchCode {
        val code = o.str("code").uppercase().filter { it.isLetterOrDigit() }
        if (code.length < 4) throw DecodeException("no code")
        return WatchCode(code, o.time("expires_at"), o.int("poll_every_s", 3).coerceIn(1, 60))
    }

    private fun attachment(o: JsonObject) = WatchAttachment(
        kind = when (o.str("kind")) {
            "page" -> AttachmentKind.PAGE
            "image" -> AttachmentKind.IMAGE
            "video" -> AttachmentKind.VIDEO
            "audio" -> AttachmentKind.AUDIO
            "document" -> AttachmentKind.DOCUMENT
            "card" -> AttachmentKind.CARD
            "link" -> AttachmentKind.LINK
            else -> AttachmentKind.FILE
        },
        title = o.str("title"),
    )

    fun message(o: JsonObject) = WatchMessage(
        id = o.id(),
        fromUser = o.str("role") == "user",
        text = o.str("text"),
        cut = o.bool("cut"),
        attachments = o.list("attachments") { attachment(it) },
        at = o.time("at"),
        canSpeak = o.bool("can_speak"),
    )

    fun chat(o: JsonObject): WatchChat {
        val b = o.obj("bot") ?: throw DecodeException("no bot")
        return WatchChat(
            bot = WatchBotHeader(b.id(), b.str("name"), b.str("avatar"), botStatus(b.str("status"))),
            conversationId = o.strOrNull("conversation_id"),
            messages = o.list("messages") { message(it) },
            runId = o.strOrNull("run_id"),
            link = o.str("link"),
        )
    }

    fun asked(o: JsonObject) = WatchAsked(
        conversationId = o.str("conversation_id").ifEmpty { throw DecodeException("no conversation") },
        messageId = o.str("message_id"),
        runId = o.strOrNull("run_id"),
        heard = o.str("heard"),
    )

    fun approval(o: JsonObject) = WatchApproval(
        id = o.id(),
        runId = o.str("run_id"),
        botId = o.str("bot_id"),
        bot = o.str("bot"),
        botAvatar = o.str("bot_avatar"),
        status = when (o.str("status")) {
            "approved" -> ApprovalStatus.APPROVED
            "denied" -> ApprovalStatus.DENIED
            "expired" -> ApprovalStatus.EXPIRED
            else -> ApprovalStatus.PENDING
        },
        title = o.str("title"),
        details = o.strings("details").take(3),
        // Unknown risk reads as high: the safe side.
        risk = risk(o.strOrNull("risk")) ?: Risk.HIGH,
        payment = o.bool("payment"),
        // Unknown permission reads as "phone": never allow more than the server said.
        canAllow = when (o.str("can_allow")) {
            "tap" -> CanAllow.TAP
            "hold" -> CanAllow.HOLD
            else -> CanAllow.PHONE
        },
        whyPhone = when (o.strOrNull("why_phone")) {
            "high_risk" -> WhyPhone.HIGH_RISK
            "payment" -> WhyPhone.PAYMENT
            "setting" -> WhyPhone.SETTING
            "workspace" -> WhyPhone.WORKSPACE
            "not_yours" -> WhyPhone.NOT_YOURS
            else -> null
        },
        createdAt = o.time("created_at"),
        expiresAt = o.time("expires_at"),
        link = o.str("link"),
    )

    fun run(o: JsonObject) = WatchRun(
        id = o.id(),
        botId = o.str("bot_id"),
        bot = o.str("bot"),
        botAvatar = o.str("bot_avatar"),
        conversationId = o.strOrNull("conversation_id"),
        phase = phase(o.str("phase")),
        step = o.str("step"),
        steps = o.int("steps"),
        startedAt = o.time("started_at"),
        endedAt = o.time("ended_at"),
        approval = o.obj("approval")?.let { runCatching { approval(it) }.getOrNull() },
        reply = o.obj("reply")?.let { runCatching { message(it) }.getOrNull() },
        link = o.str("link"),
    )

    private fun risk(s: String?): Risk? = when (s) {
        "low" -> Risk.LOW
        "medium" -> Risk.MEDIUM
        "high" -> Risk.HIGH
        else -> null
    }

    private fun botStatus(s: String) = when (s) {
        "working" -> BotStatus.WORKING
        "waiting" -> BotStatus.WAITING
        "disabled" -> BotStatus.DISABLED
        else -> BotStatus.IDLE
    }

    // An unknown phase from a newer server reads as working: the screen keeps following the run
    // and the next snapshot (or its end) settles it.
    private fun phase(s: String) = when (s) {
        "needs_ok" -> RunPhase.NEEDS_OK
        "take_over" -> RunPhase.TAKE_OVER
        "finished" -> RunPhase.FINISHED
        "problem" -> RunPhase.PROBLEM
        "stopped" -> RunPhase.STOPPED
        else -> RunPhase.WORKING
    }

    /** ISO 8601 with an offset ("2026-11-19T09:13:40.000Z") to epoch ms, or null. */
    fun parseTime(s: String?): Long? {
        if (s.isNullOrBlank()) return null
        return try {
            OffsetDateTime.parse(s).toInstant().toEpochMilli()
        } catch (_: Exception) {
            null
        }
    }
}

class DecodeException(message: String) : Exception(message)

// --- small readers -----------------------------------------------------------------------------

internal fun JsonObject.prim(key: String): JsonPrimitive? = this[key] as? JsonPrimitive

internal fun JsonObject.strOrNull(key: String): String? =
    prim(key)?.takeIf { it.isString }?.content

internal fun JsonObject.str(key: String, default: String = ""): String = strOrNull(key) ?: default

internal fun JsonObject.id(): String = strOrNull("id")?.takeIf { it.isNotBlank() } ?: throw DecodeException("no id")

internal fun JsonObject.bool(key: String, default: Boolean = false): Boolean = prim(key)?.booleanOrNull ?: default

internal fun JsonObject.int(key: String, default: Int = 0): Int {
    val p = prim(key) ?: return default
    return p.longOrNull?.toInt() ?: p.doubleOrNull?.toInt() ?: default
}

internal fun JsonObject.double(key: String): Double? = prim(key)?.doubleOrNull

internal fun JsonObject.time(key: String): Long? = Decode.parseTime(strOrNull(key))

internal fun JsonObject.obj(key: String): JsonObject? = this[key] as? JsonObject

internal fun JsonObject.strings(key: String): List<String> =
    (this[key] as? JsonArray)?.mapNotNull { (it as? JsonPrimitive)?.takeIf { p -> p.isString }?.content } ?: emptyList()

/** Each object item decoded on its own; one bad item is dropped, not the whole answer. */
internal fun <T> JsonObject.list(key: String, item: (JsonObject) -> T?): List<T> =
    (this[key] as? JsonArray)?.mapNotNull { el: JsonElement ->
        (el as? JsonObject)?.let { runCatching { item(it) }.getOrNull() }
    } ?: emptyList()
