package ai.casama.wear.core

// The HTTP contract (packages/contracts/src/watch.ts, glance.ts) as the watch reads it. Plain JVM
// Kotlin with no Android imports, so scripts/test-wear-kotlin.sh compiles and tests it with kotlinc.
// Only the fields the watch shows are kept; times are epoch milliseconds (null when absent or bad).

enum class Risk { LOW, MEDIUM, HIGH }

enum class NeedKind { APPROVAL, TAKEOVER, SUGGESTION, OTHER }

enum class BotStatus { IDLE, WORKING, WAITING, DISABLED }

enum class RunPhase {
    WORKING, NEEDS_OK, TAKE_OVER, FINISHED, PROBLEM, STOPPED;

    /** Still going: a screen keeps following it. */
    val live: Boolean get() = this == WORKING || this == NEEDS_OK || this == TAKE_OVER
}

data class GlanceNeed(
    val kind: NeedKind,
    val id: String,
    val botId: String,
    val bot: String,
    val botAvatar: String,
    val text: String,
    val risk: Risk?,
    val urgent: Boolean,
    val createdAt: Long?,
    val link: String,
)

data class GlanceBot(
    val id: String,
    val name: String,
    val avatar: String,
    val status: BotStatus,
    val step: String?,
    val lastText: String?,
    val lastAt: Long?,
    val busyAt: Long?,
    val link: String,
)

data class GlanceRun(
    val id: String,
    val botId: String,
    val bot: String,
    val botAvatar: String,
    val phase: RunPhase,
    val step: String,
    val steps: Int,
    val startedAt: Long?,
    val approvalId: String?,
    val risk: Risk?,
    val link: String,
)

data class GlanceRoutine(
    val id: String,
    val botId: String,
    val name: String,
    val bot: String,
    val botAvatar: String,
    val nextAt: Long?,
    val every: String,
    val enabled: Boolean,
    val link: String,
)

data class GlanceBrief(
    val botId: String,
    val bot: String,
    val botAvatar: String,
    val text: String?,
    val at: Long?,
    val nextAt: Long?,
    val link: String,
)

data class GlanceCredits(
    val billing: Boolean,
    val unlimited: Boolean,
    val plan: String?,
    /** Share of this period's credits used, 0 to 1; null when unknown. */
    val usedShare: Double?,
    val leftUsd: Double?,
)

data class GlanceStarter(val emoji: String, val text: String) {
    val label: String get() = if (emoji.isBlank()) text else "$emoji $text"
}

data class Glance(
    val version: String,
    val madeAt: Long?,
    val orgId: String,
    val needsCount: Int,
    val needs: List<GlanceNeed>,
    val bots: List<GlanceBot>,
    /** Older servers send none (D-410 added it). */
    val runs: List<GlanceRun>,
    val next: List<GlanceRoutine>,
    val brief: GlanceBrief?,
    val credits: GlanceCredits?,
    val starters: List<GlanceStarter>,
    val private: Boolean,
    val hideReplyText: Boolean,
) {
    fun bot(id: String?): GlanceBot? = bots.firstOrNull { it.id == id }
}

enum class AllowLevel { MEDIUM, LOW, NONE }

data class WatchPrefs(
    val allow: AllowLevel,
    val showDetails: Boolean,
    val quickReplies: List<String>,
)

data class WatchFeatures(val dictation: Boolean, val speech: Boolean, val outOfCredits: Boolean)

data class WatchSelf(
    val keyId: String,
    val orgId: String,
    val orgName: String,
    val personName: String,
    val prefs: WatchPrefs,
    val hideReplyText: Boolean,
    val askBotId: String?,
    val features: WatchFeatures,
)

data class WatchCode(val code: String, val expiresAt: Long?, val pollEverySeconds: Int)

enum class AttachmentKind { PAGE, IMAGE, VIDEO, AUDIO, DOCUMENT, FILE, CARD, LINK }

data class WatchAttachment(val kind: AttachmentKind, val title: String)

data class WatchMessage(
    val id: String,
    val fromUser: Boolean,
    val text: String,
    /** The text was cut: "Continues on phone". */
    val cut: Boolean,
    val attachments: List<WatchAttachment>,
    val at: Long?,
    val canSpeak: Boolean,
)

data class WatchBotHeader(val id: String, val name: String, val avatar: String, val status: BotStatus)

data class WatchChat(
    val bot: WatchBotHeader,
    val conversationId: String?,
    val messages: List<WatchMessage>,
    val runId: String?,
    val link: String,
)

data class WatchAsked(val conversationId: String, val messageId: String, val runId: String?, val heard: String)

enum class ApprovalStatus { PENDING, APPROVED, DENIED, EXPIRED }

/** What this watch may do with a request; the server decides (§8.4), the watch obeys. */
enum class CanAllow { TAP, HOLD, PHONE }

enum class WhyPhone { HIGH_RISK, PAYMENT, SETTING, WORKSPACE, NOT_YOURS }

data class WatchApproval(
    val id: String,
    val runId: String,
    val botId: String,
    val bot: String,
    val botAvatar: String,
    val status: ApprovalStatus,
    val title: String,
    val details: List<String>,
    val risk: Risk,
    val payment: Boolean,
    val canAllow: CanAllow,
    val whyPhone: WhyPhone?,
    val createdAt: Long?,
    val expiresAt: Long?,
    val link: String,
)

data class WatchRun(
    val id: String,
    val botId: String,
    val bot: String,
    val botAvatar: String,
    val conversationId: String?,
    val phase: RunPhase,
    val step: String,
    val steps: Int,
    val startedAt: Long?,
    val endedAt: Long?,
    val approval: WatchApproval?,
    val reply: WatchMessage?,
    val link: String,
)
