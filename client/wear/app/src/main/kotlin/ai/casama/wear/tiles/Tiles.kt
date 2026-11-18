package ai.casama.wear.tiles

import ai.casama.wear.R
import ai.casama.wear.art.BotArt
import ai.casama.wear.core.Format
import ai.casama.wear.core.Glance
import ai.casama.wear.core.GlanceBot
import ai.casama.wear.core.Logic
import ai.casama.wear.core.NeedKind
import ai.casama.wear.data.ApiError
import ai.casama.wear.graph
import ai.casama.wear.live.OngoingRun
import ai.casama.wear.ui.MainActivity
import ai.casama.wear.ui.Routes
import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.DimensionBuilders.dp
import androidx.wear.protolayout.LayoutElementBuilders.LayoutElement
import androidx.wear.protolayout.ModifiersBuilders.Clickable
import androidx.wear.protolayout.layout.androidImageResource
import androidx.wear.protolayout.layout.imageResource
import androidx.wear.protolayout.layout.inlineImageResource
import androidx.wear.protolayout.material3.ColorScheme
import androidx.wear.protolayout.material3.MaterialScope
import androidx.wear.protolayout.material3.Typography
import androidx.wear.protolayout.material3.avatarImage
import androidx.wear.protolayout.material3.icon
import androidx.wear.protolayout.material3.iconEdgeButton
import androidx.wear.protolayout.material3.primaryLayout
import androidx.wear.protolayout.material3.text
import androidx.wear.protolayout.material3.textEdgeButton
import androidx.wear.protolayout.modifiers.clickable
import androidx.wear.protolayout.modifiers.loadAction
import androidx.wear.protolayout.types.LayoutColor
import androidx.wear.protolayout.types.LayoutString
import androidx.wear.tiles.Material3TileService
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.tile
import androidx.wear.tiles.timeline
import androidx.wear.tiles.timelineEntry
import kotlin.time.Duration.Companion.minutes
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull

/** The app's colours on tiles: orchid for Ask, amber for Needs you, green for working (§2.2). */
internal object TileColors {
    private fun c(argb: Long) = LayoutColor(argb.toInt())
    val scheme = ColorScheme(
        primary = c(0xFFF2B0EC),
        onPrimary = c(0xFF3B0A3D),
        primaryContainer = c(0xFF5A2A5C),
        onPrimaryContainer = c(0xFFFFD7F9),
        secondary = c(0xFF5FD49A),
        onSecondary = c(0xFF00391F),
        tertiary = c(0xFFF0A84A),
        onTertiary = c(0xFF3D2300),
        error = c(0xFFFF6B6B),
        onError = c(0xFF3D0000),
    )
    val needs = c(0xFFF0A84A)
    val working = c(0xFF5FD49A)
    val secondaryText = c(0xFF9A9AA0)
}

/**
 * Every Casama tile: drawn from the saved glance (a tile must answer at once), refreshed in the
 * background when that's old; signed out it says "Open Casama to sign in". Buttons that act
 * (Allow, Run Now) are load actions: the tile asks again with the button's id and the action runs
 * here, through the server, before the new layout comes back.
 */
abstract class CasamaTile : Material3TileService(false, TileColors.scheme) {

    protected abstract fun MaterialScope.signedIn(g: Glance?, note: String?): LayoutElement

    /** Runs a tapped action; returns a line to show (Done, Already answered, Couldn't reach). */
    protected open suspend fun act(clickId: String): String? = null

    override suspend fun MaterialScope.tileResponse(requestParams: RequestBuilders.TileRequest): TileBuilders.Tile {
        val graph = applicationContext.graph
        val session = graph.session
        val layout = if (!session.isSignedIn) {
            primaryLayout(
                titleSlot = { text(LayoutString(getString(R.string.watch_comp_casama))) },
                mainSlot = { text(LayoutString(getString(R.string.watch_open_to_sign_in)), typography = Typography.BODY_LARGE, maxLines = 3) },
                onClick = open(Routes.NOW, "open"),
            )
        } else {
            val clicked = requestParams.currentState.lastClickableId
            val note = if (clicked.contains(':')) withTimeoutOrNull(8_000) { act(clicked) } ?: getString(R.string.watch_couldnt_reach) else null
            val saved = graph.cache.glance()
            if (Format.isStale(saved?.savedAt, System.currentTimeMillis())) graph.scope.launch { session.refresh() }
            signedIn(saved?.glance, note)
        }
        return tile(timeline(timelineEntry(layout)), 15.minutes)
    }

    /** Opens a screen of the app. */
    protected fun open(route: String, id: String): Clickable {
        val activity = ActionBuilders.AndroidActivity.Builder()
            .setPackageName(packageName)
            .setClassName(MainActivity::class.java.name)
            .addKeyToExtraMapping(Routes.EXTRA_ROUTE, ActionBuilders.AndroidStringExtra.Builder().setValue(route).build())
            .build()
        return clickable(ActionBuilders.LaunchAction.Builder().setAndroidActivity(activity).build(), id)
    }

    /** A button that runs [act] with [id] (which holds a ':'). */
    protected fun action(id: String): Clickable = clickable(loadAction(), id)

    protected fun MaterialScope.face(name: String, avatar: String?, id: String): LayoutElement {
        val res = BotArt.mascotRes(avatar)
        val image = if (res != null) {
            imageResource(androidImageResource(res))
        } else {
            imageResource(null, inlineImageResource(BotArt.png(applicationContext, name, avatar, 96), 96, 96))
        }
        return avatarImage(image, "face_${name.filter { it.isLetterOrDigit() }}_$id", dp(44f), dp(44f))
    }

    protected fun MaterialScope.micButton(route: String): LayoutElement =
        iconEdgeButton(open(route, "ask")) { icon(imageResource(androidImageResource(R.drawable.ic_mic)), "ic_mic") }

    protected fun MaterialScope.line(value: String, typography: Int = Typography.BODY_MEDIUM, color: LayoutColor? = null, lines: Int = 2): LayoutElement =
        if (color != null) text(LayoutString(value), typography = typography, color = color, maxLines = lines)
        else text(LayoutString(value), typography = typography, maxLines = lines)

    /** The person's words stay off the face when the workspace is private or details are hidden. */
    protected fun showWords(g: Glance?): Boolean =
        g?.private != true && applicationContext.graph.session.self.value?.prefs?.showDetails != false
}

/** Needs you: how many, the first, and Allow for a low-risk request when this watch may. */
class NeedsYouTileService : CasamaTile() {
    override fun MaterialScope.signedIn(g: Glance?, note: String?): LayoutElement {
        val first = g?.let { Logic.firstNeed(it) }
        val count = g?.needsCount ?: 0
        if (first == null) {
            return primaryLayout(
                titleSlot = { line(getString(R.string.watch_needs_you), Typography.TITLE_SMALL) },
                mainSlot = { line(note ?: getString(R.string.watch_all_clear), Typography.TITLE_MEDIUM) },
                bottomSlot = { micButton(Routes.ask(null, listen = true)) },
                onClick = open(Routes.NOW, "now"),
            )
        }
        val allow = applicationContext.graph.session.self.value?.prefs?.allow
        val ui = Logic.needUi(first, allow)
        val words = if (showWords(g)) first.text else getString(R.string.watch_needs_ok)
        val route = Routes.fromLink(first.link) ?: if (first.kind == NeedKind.SUGGESTION) Routes.suggestion(first.id) else Routes.request(first.id)
        return primaryLayout(
            titleSlot = {
                line(if (count == 1) getString(R.string.watch_needs_you_one) else getString(R.string.watch_needs_you_many, count.toString()), Typography.TITLE_SMALL, TileColors.needs, 1)
            },
            mainSlot = { line(note ?: "${first.bot}: $words", Typography.BODY_LARGE, lines = 3) },
            bottomSlot = {
                when (ui) {
                    Logic.NeedUi.ALLOW -> textEdgeButton(action("allow:${first.id}")) { text(LayoutString(getString(R.string.watch_allow))) }
                    Logic.NeedUi.SUGGESTION -> textEdgeButton(open(route, "open_need")) { text(LayoutString(getString(R.string.watch_do_it))) }
                    else -> textEdgeButton(open(route, "open_need")) { text(LayoutString(getString(R.string.watch_review))) }
                }
            },
            onClick = open(Routes.NEEDS, "needs"),
        )
    }

    override suspend fun act(clickId: String): String? {
        val (kind, id) = clickId.split(':', limit = 2)
        if (kind != "allow") return null
        val session = applicationContext.graph.session
        // Only a request the server still lets this watch allow with a tap.
        return try {
            val a = session.call { approval(id) }
            if (Logic.requestUi(a, System.currentTimeMillis()) != Logic.RequestUi.ALLOW_TAP) return getString(R.string.watch_review_on_phone)
            session.call { decide(id, true, "w-allow-$id") }
            applicationContext.graph.haptics.done()
            session.refresh()
            getString(R.string.watch_allowed)
        } catch (_: ApiError.Conflict) {
            getString(R.string.watch_already_answered)
        } catch (_: ApiError.NotFound) {
            getString(R.string.watch_already_answered)
        } catch (_: ApiError) {
            getString(R.string.watch_couldnt_reach)
        }
    }
}

/** Ask: the Ask bot's face and one big button that opens the app listening. */
class AskTileService : CasamaTile() {
    override fun MaterialScope.signedIn(g: Glance?, note: String?): LayoutElement {
        val graph = applicationContext.graph
        val bot = Logic.askBot(g, graph.settings.lastAskBotId, graph.session.self.value?.askBotId)
        val route = Routes.ask(bot?.id, listen = true)
        return primaryLayout(
            titleSlot = { line(bot?.let { getString(R.string.watch_ask_bot, it.name) } ?: getString(R.string.watch_ask), Typography.TITLE_SMALL, lines = 1) },
            mainSlot = { if (bot != null) face(bot.name, bot.avatar, "ask") else line(getString(R.string.watch_no_bots)) },
            bottomSlot = { micButton(route) },
            onClick = open(route, "ask_main"),
        )
    }
}

/** Up next: the next routine, when, and Run Now. */
class UpNextTileService : CasamaTile() {
    override fun MaterialScope.signedIn(g: Glance?, note: String?): LayoutElement {
        val (next, _) = g?.let { Logic.upNext(it) } ?: (null to null)
        if (next == null) {
            return primaryLayout(
                titleSlot = { line(getString(R.string.watch_up_next), Typography.TITLE_SMALL) },
                mainSlot = { line(getString(R.string.watch_no_routines)) },
                onClick = open(Routes.UP_NEXT, "upnext"),
            )
        }
        val whenText = next.nextAt?.let { at ->
            when (val u = Format.until(System.currentTimeMillis(), at, java.time.ZoneId.systemDefault())) {
                is Format.Until.Minutes -> getString(R.string.watch_in_minutes, u.minutes.toString())
                else -> android.text.format.DateFormat.getTimeFormat(applicationContext).format(java.util.Date(at))
            }
        } ?: next.every
        return primaryLayout(
            titleSlot = { line(whenText, Typography.TITLE_SMALL, TileColors.working, 1) },
            mainSlot = { line(note ?: next.name, Typography.BODY_LARGE, lines = 3) },
            bottomSlot = { textEdgeButton(action("run:${next.id}")) { text(LayoutString(getString(R.string.watch_run_now))) } },
            onClick = open(Routes.UP_NEXT, "upnext"),
        )
    }

    override suspend fun act(clickId: String): String? {
        val (kind, id) = clickId.split(':', limit = 2)
        if (kind != "run") return null
        val graph = applicationContext.graph
        return try {
            graph.session.call { runRoutine(id, "w-run-$id-${System.currentTimeMillis() / 60_000}") }?.let { OngoingRun.startedOnWatch(it) }
            graph.haptics.done()
            getString(R.string.watch_started)
        } catch (_: ApiError) {
            getString(R.string.watch_couldnt_reach)
        }
    }
}

/** One bot: its face, what it's doing, tap to open the chat, the mic to ask it. */
class BotTileService : CasamaTile() {
    override fun MaterialScope.signedIn(g: Glance?, note: String?): LayoutElement {
        val graph = applicationContext.graph
        val bot: GlanceBot? = g?.bot(graph.settings.tileBotId)
            ?: Logic.askBot(g, graph.settings.lastAskBotId, graph.session.self.value?.askBotId)
        if (bot == null) {
            return primaryLayout(mainSlot = { line(getString(R.string.watch_no_bots)) }, onClick = open(Routes.NOW, "now"))
        }
        val status = when (bot.status) {
            ai.casama.wear.core.BotStatus.WORKING -> getString(R.string.watch_working)
            ai.casama.wear.core.BotStatus.WAITING -> getString(R.string.watch_waiting_for_you)
            ai.casama.wear.core.BotStatus.DISABLED -> getString(R.string.watch_off)
            ai.casama.wear.core.BotStatus.IDLE -> getString(R.string.watch_idle)
        }
        return primaryLayout(
            titleSlot = { line(bot.name, Typography.TITLE_SMALL, lines = 1) },
            mainSlot = { face(bot.name, bot.avatar, "bot") },
            labelForBottomSlot = { line(status, Typography.LABEL_SMALL, if (bot.status == ai.casama.wear.core.BotStatus.WORKING) TileColors.working else TileColors.secondaryText, 1) },
            bottomSlot = { micButton(Routes.ask(bot.id, listen = true)) },
            onClick = open(Routes.chat(bot.id, null), "chat"),
        )
    }
}
