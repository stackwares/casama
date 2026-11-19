package ai.casama.wear.core

/**
 * Decisions the screens, tiles and notifications share, kept here so they are tested once. None of
 * them works out a risk or a step: the server sends those (§4 principle 4). These only pick which
 * of the server's answers to show and which buttons it allows.
 */
object Logic {
    /** A row on Now, most urgent first (§6.1 A). */
    sealed class NowRow {
        data class Needs(val count: Int, val first: GlanceNeed?) : NowRow()
        data class Working(val run: GlanceRun) : NowRow()
        /** A bot the glance says is working, on a server too old to send `runs`. */
        data class WorkingBot(val bot: GlanceBot) : NowRow()
        data class UpNext(val routine: GlanceRoutine) : NowRow()
        data class Brief(val brief: GlanceBrief) : NowRow()
    }

    fun nowRows(g: Glance): List<NowRow> {
        val rows = mutableListOf<NowRow>()
        if (g.needsCount > 0) rows += NowRow.Needs(g.needsCount, firstNeed(g))
        if (g.runs.isNotEmpty()) {
            g.runs.take(3).forEach { rows += NowRow.Working(it) }
        } else {
            g.bots.filter { it.status == BotStatus.WORKING }.take(3).forEach { rows += NowRow.WorkingBot(it) }
        }
        g.next.firstOrNull { it.enabled && it.nextAt != null }?.let { rows += NowRow.UpNext(it) }
        g.brief?.let { if (it.text != null) rows += NowRow.Brief(it) }
        return rows
    }

    /** Nothing waiting and nothing working: the sleepy face and what comes next. */
    fun allClear(g: Glance): Boolean =
        g.needsCount == 0 && g.runs.isEmpty() && g.bots.none { it.status == BotStatus.WORKING }

    /** Approvals first, then urgent suggestions, then the rest, as the server already orders them. */
    fun firstNeed(g: Glance): GlanceNeed? = g.needs.firstOrNull()

    /** What a request screen offers (§6.1 B). */
    enum class RequestUi { ALLOW_TAP, ALLOW_HOLD, PHONE_ONLY, ALREADY_ANSWERED }

    fun requestUi(a: WatchApproval, now: Long): RequestUi = when {
        a.status != ApprovalStatus.PENDING -> RequestUi.ALREADY_ANSWERED
        a.expiresAt != null && a.expiresAt < now -> RequestUi.ALREADY_ANSWERED
        // Never more than the server allows; a payment or high risk never even if it said so.
        a.payment || a.risk == Risk.HIGH -> RequestUi.PHONE_ONLY
        a.canAllow == CanAllow.TAP -> RequestUi.ALLOW_TAP
        a.canAllow == CanAllow.HOLD -> RequestUi.ALLOW_HOLD
        else -> RequestUi.PHONE_ONLY
    }

    /** `detail` of a `403 watch_allow_refused` (WATCH-PROTOCOL §1) as the reason the screen says. */
    fun whyPhone(detail: String?): WhyPhone? = when (detail) {
        "high_risk" -> WhyPhone.HIGH_RISK
        "payment" -> WhyPhone.PAYMENT
        "setting" -> WhyPhone.SETTING
        "workspace" -> WhyPhone.WORKSPACE
        "not_yours" -> WhyPhone.NOT_YOURS
        else -> null
    }

    /** What a `409` on one of the watch's own actions means (WATCH-PROTOCOL §1). */
    enum class ConflictKind {
        /** Someone answered it, or it ended, before the tap. Nothing is wrong. */
        OVER,
        /** The server couldn't start the run (the bot has no model, say). It is still waiting; the phone says why. */
        CANT_START,
    }

    /**
     * By the problem's code: `approval_already_decided`, `suggestion_closed` and `run_finished`
     * (Allow, Deny, Do It, Not now, Stop on something already answered or ended) are over. Any
     * other code is a run Do It couldn't start (`no_model_configured`…): the suggestion is kept, so
     * it must never read "Already answered". A 409 with no code (an older server) counts as over.
     */
    fun conflict(code: String?): ConflictKind = when {
        code.isNullOrBlank() -> ConflictKind.OVER
        code.endsWith("_decided") || code.endsWith("_closed") || code.endsWith("_finished") -> ConflictKind.OVER
        else -> ConflictKind.CANT_START
    }

    /** The phone app's first screen: where Open on phone goes when there is nothing more exact. */
    const val PHONE_HOME = "/bots"

    /** Where suggestions and other things that need the person wait on the phone. */
    const val PHONE_NEEDS = "/inbox?tab=0"

    /**
     * A link fit to send to the phone: one of its own routes ("/approvals/…"), never "//host". A
     * bare "/" (what a push with no link carries) isn't a screen there, so it and anything else
     * become the first screen.
     */
    fun phoneRoute(link: String?): String {
        val l = link?.trim().orEmpty()
        return if (l.length > 1 && l.startsWith("/") && !l.startsWith("//")) l else PHONE_HOME
    }

    /** What a need from the glance offers before its details load (tiles, Now's first row). */
    enum class NeedUi { ALLOW, REVIEW, SUGGESTION, OPEN_ON_PHONE }

    /**
     * One-tap Allow from a tile or a notification is for low risk only, and only when the person's
     * setting lets a watch allow (§6.2). Medium opens the request with Hold to allow.
     */
    fun needUi(n: GlanceNeed, allow: AllowLevel?): NeedUi = when (n.kind) {
        NeedKind.APPROVAL -> when {
            n.risk == Risk.LOW && allow != AllowLevel.NONE -> NeedUi.ALLOW
            else -> NeedUi.REVIEW
        }
        NeedKind.SUGGESTION -> NeedUi.SUGGESTION
        else -> NeedUi.OPEN_ON_PHONE
    }

    /**
     * A push's buttons (§6.2): Allow in one tap only when the server says this watch may ("tap").
     * A server that doesn't say (no `can_allow`): only for a low-risk request.
     */
    fun pushAllows(p: WatchPush, allow: AllowLevel?): Boolean {
        if (p.kind != WatchPush.Kind.APPROVAL || allow == AllowLevel.NONE) return false
        return when (p.canAllow) {
            CanAllow.TAP -> true
            CanAllow.HOLD, CanAllow.PHONE -> false
            null -> p.risk == Risk.LOW
        }
    }

    /** Allow that opens the request, where it is a hold: "hold" from the server, else medium risk. */
    fun pushHolds(p: WatchPush, allow: AllowLevel?): Boolean {
        if (p.kind != WatchPush.Kind.APPROVAL) return false
        return when (p.canAllow) {
            CanAllow.HOLD -> allow != AllowLevel.NONE
            CanAllow.TAP, CanAllow.PHONE -> false
            null -> p.risk == Risk.MEDIUM && allow == AllowLevel.MEDIUM
        }
    }

    /**
     * A push about another workspace than the one this watch is signed in to: it can be read, not
     * answered from here. When either side doesn't say, it is treated as this workspace's.
     */
    fun elsewhere(pushOrgId: String?, watchOrgId: String?): Boolean =
        !pushOrgId.isNullOrBlank() && !watchOrgId.isNullOrBlank() && pushOrgId != watchOrgId

    /**
     * The Idempotency-Key for a reply sent from a notification: the same notification and words
     * give the same key, so a retry after a timeout that did arrive can't send it twice.
     */
    fun replyKey(notificationId: String, text: String): String {
        val digest = java.security.MessageDigest.getInstance("SHA-256")
            .digest("watch-reply:$notificationId:$text".toByteArray(Charsets.UTF_8))
        return "n-reply-" + digest.take(16).joinToString("") { "%02x".format(it.toInt() and 0xff) }
    }

    /**
     * Whether the person's own words may show: not while the glance is private (app lock), not
     * when they turned details off on the phone, and not wrist down when they asked for that.
     */
    fun showWords(private: Boolean, showDetails: Boolean, ambient: Boolean, hideWhenWristDown: Boolean): Boolean =
        !private && showDetails && !(ambient && hideWhenWristDown)

    /** The bot Ask goes to: the one last asked if it still exists, else the server's pick, else the first. */
    fun askBot(g: Glance?, lastAsked: String?, serverPick: String?): GlanceBot? {
        val bots = g?.bots?.filter { it.status != BotStatus.DISABLED } ?: return null
        return bots.firstOrNull { it.id == lastAsked } ?: bots.firstOrNull { it.id == serverPick } ?: bots.firstOrNull()
    }

    /** The routine after the next one, for the Up next tile's "then 9:00 Inbox sweep". */
    fun upNext(g: Glance): Pair<GlanceRoutine?, GlanceRoutine?> {
        val list = g.next.filter { it.enabled && it.nextAt != null }.sortedBy { it.nextAt }
        return list.getOrNull(0) to list.getOrNull(1)
    }
}
