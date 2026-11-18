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

    /** A push's buttons (§6.2): Allow only for a low-risk request. */
    fun pushAllows(p: WatchPush, allow: AllowLevel?): Boolean =
        p.kind == WatchPush.Kind.APPROVAL && p.risk == Risk.LOW && allow != AllowLevel.NONE

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
