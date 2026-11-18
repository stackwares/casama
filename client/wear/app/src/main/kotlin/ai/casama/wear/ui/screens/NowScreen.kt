package ai.casama.wear.ui.screens

import ai.casama.wear.R
import ai.casama.wear.art.BotArt
import ai.casama.wear.core.Format
import ai.casama.wear.core.GlanceNeed
import ai.casama.wear.core.Logic
import ai.casama.wear.core.NeedKind
import ai.casama.wear.core.QueuedAsk
import ai.casama.wear.core.Risk
import ai.casama.wear.graph
import ai.casama.wear.ui.Routes
import ai.casama.wear.ui.components.AsOf
import ai.casama.wear.ui.components.BotFace
import ai.casama.wear.ui.components.Eyebrow
import ai.casama.wear.ui.components.Message
import ai.casama.wear.ui.components.Words
import ai.casama.wear.ui.components.clockTime
import ai.casama.wear.ui.components.largeText
import ai.casama.wear.ui.components.runningClock
import ai.casama.wear.ui.go
import ai.casama.wear.ui.theme.CasamaColors
import ai.casama.wear.ui.theme.LocalAmbient
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavHostController
import androidx.wear.compose.foundation.lazy.TransformingLazyColumnItemScope
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.Card
import androidx.wear.compose.material3.CardDefaults
import androidx.wear.compose.material3.EdgeButton
import androidx.wear.compose.material3.FilledTonalButton
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.SurfaceTransformation
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.lazy.TransformationSpec
import androidx.wear.compose.material3.lazy.transformedHeight
import java.time.ZoneId
import kotlinx.coroutines.launch

/**
 * Now (§6.1 A): one list, most urgent first: needs you, then each bot that is working with a
 * running clock, then what runs next. Ask is the edge button. Nothing waiting and nothing working:
 * All clear with the sleepy face and when the brief comes. Opens from the saved glance, never a
 * spinner; offline, the live colours go grey and it says how old it is.
 */
@Composable
fun NowScreen(nav: NavHostController) {
    val context = LocalContext.current
    val graph = context.graph
    val session = graph.session
    val state by session.glance.collectAsState()
    val self by session.self.collectAsState()
    val g = state.glance
    val offline = state.offline
    val ambient = LocalAmbient.current
    val large = largeText()
    val scope = rememberCoroutineScope()
    var kept by remember { mutableStateOf(graph.outbox.awaitingConfirm()) }
    val outOfCredits = self?.features?.outOfCredits == true

    ListScreen(
        edgeButton = {
            EdgeButton(
                onClick = { nav.go(Routes.ask(null, listen = true)) },
                enabled = !outOfCredits,
                colors = ButtonDefaults.buttonColors(containerColor = CasamaColors.Orchid, contentColor = CasamaColors.OnOrchid),
            ) {
                Icon(painterResource(R.drawable.ic_mic), contentDescription = null, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(6.dp))
                Text(stringResource(R.string.watch_ask))
            }
        },
    ) { spec ->
        if (offline) item { AsOf(state.savedAt, offline = true, modifier = Modifier.fillMaxWidth()) }
        if (state.serverTooOld) {
            item { Message(stringResource(R.string.watch_server_too_old), null, modifier = Modifier.transformedHeight(this, spec)) }
            return@ListScreen
        }
        if (g == null) {
            // First load: the layout in grey, never a spinner (§6.8).
            items(2) { Placeholder(spec) }
            return@ListScreen
        }
        if (outOfCredits) {
            item {
                Card(
                    onClick = { scope.launch { openOnPhone(context, "/settings/billing", context.getString(R.string.watch_out_of_credits)) } },
                    modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                    transformation = SurfaceTransformation(spec),
                ) {
                    Text(stringResource(R.string.watch_out_of_credits), style = MaterialTheme.typography.titleSmall)
                    Text(stringResource(R.string.watch_open_on_phone), style = MaterialTheme.typography.bodySmall, color = CasamaColors.Secondary)
                }
            }
        }
        kept.forEach { k -> item { KeptAsk(k, spec, onDone = { kept = graph.outbox.awaitingConfirm() }) } }

        if (Logic.allClear(g)) {
            item {
                val brief = g.brief?.nextAt
                val sub = brief?.let { at ->
                    val time = clockTime(at)
                    if (Format.dayOffset(System.currentTimeMillis(), at, ZoneId.systemDefault()) >= 1) stringResource(R.string.watch_brief_tomorrow, time)
                    else stringResource(R.string.watch_brief_at, time)
                } ?: stringResource(R.string.watch_nothing_waiting)
                Message(stringResource(R.string.watch_all_clear), sub, faceRes = BotArt.sleepy, modifier = Modifier.transformedHeight(this, spec).padding(vertical = 6.dp))
            }
        }
        val rows = Logic.nowRows(g).let { if (large) it.take(2) else it }
        for (row in rows) {
            when (row) {
                is Logic.NowRow.Needs -> item {
                    NeedsCard(row.count, row.first, offline, spec) {
                        val first = row.first
                        when {
                            row.count == 1 && first != null -> openNeed(nav, first)
                            else -> nav.go(Routes.NEEDS)
                        }
                    }
                }
                is Logic.NowRow.Working -> item {
                    WorkingCard(row.run.bot, row.run.botAvatar, row.run.step, row.run.startedAt, offline, spec) {
                        nav.go(Routes.working(row.run.id))
                    }
                }
                is Logic.NowRow.WorkingBot -> item {
                    WorkingCard(row.bot.name, row.bot.avatar, row.bot.step.orEmpty(), null, offline, spec) {
                        nav.go(Routes.chat(row.bot.id, null))
                    }
                }
                is Logic.NowRow.UpNext -> item {
                    val r = row.routine
                    Card(
                        onClick = { nav.go(Routes.UP_NEXT) },
                        modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                        transformation = SurfaceTransformation(spec),
                    ) {
                        Eyebrow(stringResource(R.string.watch_up_next), CasamaColors.Orchid)
                        Words(r.name, maxLines = 1, style = MaterialTheme.typography.titleSmall)
                        Text(
                            listOfNotNull(r.nextAt?.let { untilText(it) }, r.bot.takeIf { it.isNotBlank() }).joinToString(" · "),
                            style = MaterialTheme.typography.bodySmall,
                            color = CasamaColors.Secondary,
                            maxLines = 1,
                        )
                    }
                }
                is Logic.NowRow.Brief -> if (!large) item {
                    Card(
                        onClick = { nav.go(Routes.BRIEF) },
                        modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                        transformation = SurfaceTransformation(spec),
                    ) {
                        Eyebrow(stringResource(R.string.watch_brief), CasamaColors.Secondary)
                        Words(row.brief.text.orEmpty(), maxLines = 2, style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
        }
        if (!ambient) {
            item { NavRow(R.drawable.ic_bots, stringResource(R.string.watch_bots), spec) { nav.go(Routes.BOTS) } }
            item { NavRow(R.drawable.ic_clock, stringResource(R.string.watch_up_next), spec) { nav.go(Routes.UP_NEXT) } }
            if (g.brief != null && Logic.nowRows(g).none { it is Logic.NowRow.Brief }) {
                item { NavRow(R.drawable.ic_brief, stringResource(R.string.watch_brief), spec) { nav.go(Routes.BRIEF) } }
            }
            item { NavRow(R.drawable.ic_settings, stringResource(R.string.watch_settings), spec) { nav.go(Routes.SETTINGS) } }
        }
    }
}

fun openNeed(nav: NavHostController, need: GlanceNeed) {
    when (need.kind) {
        NeedKind.APPROVAL -> nav.go(Routes.request(need.id))
        NeedKind.SUGGESTION -> nav.go(Routes.suggestion(need.id))
        else -> nav.go(Routes.NEEDS)
    }
}

@Composable
fun riskLabel(risk: Risk?): String? = when (risk) {
    Risk.LOW -> stringResource(R.string.watch_low_risk)
    Risk.MEDIUM -> stringResource(R.string.watch_medium_risk)
    Risk.HIGH -> stringResource(R.string.watch_high_risk)
    null -> null
}

@Composable
fun TransformingLazyColumnItemScope.NeedsCard(count: Int, first: GlanceNeed?, offline: Boolean, spec: TransformationSpec, onClick: () -> Unit) {
    val ambient = LocalAmbient.current
    val live = !offline && !ambient
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
        transformation = SurfaceTransformation(spec),
        colors = if (live) CardDefaults.cardColors(containerColor = CasamaColors.NeedsContainer, contentColor = CasamaColors.OnNeedsContainer)
        else CardDefaults.cardColors(containerColor = if (ambient) Color.Black else CasamaColors.Card),
    ) {
        Eyebrow(stringResource(R.string.watch_needs_you) + " · " + count, if (live) CasamaColors.Needs else CasamaColors.Secondary)
        if (first != null) {
            Spacer(Modifier.height(2.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                BotFace(first.bot, first.botAvatar, 26.dp)
                Spacer(Modifier.width(8.dp))
                Column {
                    Words(first.text, maxLines = 1, style = MaterialTheme.typography.titleSmall)
                    Text(
                        listOfNotNull(first.bot, riskLabel(first.risk)).joinToString(" · "),
                        style = MaterialTheme.typography.bodySmall,
                        color = if (live) CasamaColors.OnNeedsContainer.copy(alpha = 0.8f) else CasamaColors.Secondary,
                        maxLines = 1,
                    )
                }
            }
        }
    }
}

@Composable
fun TransformingLazyColumnItemScope.WorkingCard(
    bot: String,
    avatar: String,
    step: String,
    startedAt: Long?,
    offline: Boolean,
    spec: TransformationSpec,
    onClick: () -> Unit,
) {
    val ambient = LocalAmbient.current
    val live = !offline && !ambient
    val clock = runningClock(startedAt, running = !ambient)
    val working = stringResource(R.string.watch_working)
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
        transformation = SurfaceTransformation(spec),
        colors = if (live) CardDefaults.cardColors(containerColor = CasamaColors.WorkingContainer, contentColor = Color.White)
        else CardDefaults.cardColors(containerColor = if (ambient) Color.Black else CasamaColors.Card),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            BotFace(bot, avatar, 22.dp)
            Spacer(Modifier.width(8.dp))
            Column(Modifier.weight(1f)) {
                Text("$bot · ${working.lowercase()}", style = MaterialTheme.typography.bodySmall, maxLines = 1)
                if (step.isNotBlank()) Words(step, maxLines = 1, style = MaterialTheme.typography.bodySmall, color = if (live) CasamaColors.OnWorkingContainer else CasamaColors.Secondary)
            }
            if (clock.isNotEmpty()) {
                Text(clock, color = if (live) CasamaColors.Working else CasamaColors.Secondary, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}

@Composable
fun TransformingLazyColumnItemScope.NavRow(icon: Int, label: String, spec: TransformationSpec, onClick: () -> Unit) {
    FilledTonalButton(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
        transformation = SurfaceTransformation(spec),
        icon = { Icon(painterResource(icon), contentDescription = null, modifier = Modifier.size(20.dp)) },
        label = { Text(label, maxLines = 1) },
    )
}

@Composable
private fun TransformingLazyColumnItemScope.Placeholder(spec: TransformationSpec) {
    Box(
        Modifier
            .fillMaxWidth()
            .transformedHeight(this, spec)
            .height(64.dp)
            .clip(RoundedCornerShape(22.dp))
            .background(CasamaColors.Card)
            .semantics { contentDescription = "" },
    )
}

@Composable
private fun TransformingLazyColumnItemScope.KeptAsk(k: QueuedAsk, spec: TransformationSpec, onDone: () -> Unit) {
    val context = LocalContext.current
    val graph = context.graph
    val scope = rememberCoroutineScope()
    Card(
        onClick = {},
        enabled = false,
        modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
        transformation = SurfaceTransformation(spec),
    ) {
        Text(stringResource(R.string.watch_kept_old, clockTime(k.askedAt)), style = MaterialTheme.typography.bodySmall, textAlign = TextAlign.Start)
        k.text?.let { Words("“$it”", maxLines = 2, style = MaterialTheme.typography.bodySmall, color = CasamaColors.Secondary) }
        Spacer(Modifier.height(4.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Button(onClick = {
                scope.launch {
                    graph.outbox.send(k)
                    onDone()
                }
            }, modifier = Modifier.weight(1f)) { Text(stringResource(R.string.watch_send), maxLines = 1) }
            FilledTonalButton(onClick = {
                graph.outbox.remove(k.id)
                onDone()
            }, modifier = Modifier.weight(1f)) { Text(stringResource(R.string.watch_discard), maxLines = 1) }
        }
    }
}

/** "in 12 min", or the clock time when it's an hour or more away. */
@Composable
fun untilText(at: Long): String = when (val u = Format.until(System.currentTimeMillis(), at, ZoneId.systemDefault())) {
    Format.Until.Now -> clockTime(at)
    is Format.Until.Minutes -> stringResource(R.string.watch_in_minutes, u.minutes)
    is Format.Until.At -> clockTime(at)
}

/** Open on phone (§6.1 E): the phone link first, else a notification on the phone via the server. */
suspend fun openOnPhone(context: android.content.Context, link: String, title: String): Boolean {
    if (ai.casama.wear.link.PhoneLink.openOnPhone(context, link)) return true
    return runCatching { context.graph.session.call { handoff(link, title) } }.isSuccess
}
