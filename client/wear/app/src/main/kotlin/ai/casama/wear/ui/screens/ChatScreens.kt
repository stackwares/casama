package ai.casama.wear.ui.screens

import ai.casama.wear.R
import ai.casama.wear.core.AttachmentKind
import ai.casama.wear.core.BotStatus
import ai.casama.wear.core.WatchChat
import ai.casama.wear.core.WatchMessage
import ai.casama.wear.data.ApiError
import ai.casama.wear.graph
import ai.casama.wear.live.OngoingRun
import ai.casama.wear.ui.Routes
import ai.casama.wear.ui.components.AsOf
import ai.casama.wear.ui.components.BotFace
import ai.casama.wear.ui.components.Message
import ai.casama.wear.ui.components.Words
import ai.casama.wear.ui.components.clockTime
import ai.casama.wear.ui.go
import ai.casama.wear.ui.theme.CasamaColors
import ai.casama.wear.voice.Speaker
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavHostController
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.Card
import androidx.wear.compose.material3.EdgeButton
import androidx.wear.compose.material3.FilledTonalButton
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.SurfaceTransformation
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.lazy.transformedHeight
import kotlinx.coroutines.launch

/**
 * A reply, and the chat it belongs to (§6.1 E): the last few messages, Read aloud, Reply by voice,
 * Open on phone. Long replies are cut by the server ("Continues on phone"); attachments are one
 * line each. The last chat is kept so it opens instantly and offline.
 */
@Composable
fun ChatScreen(nav: NavHostController, botId: String, conversationId: String?, readAloud: Boolean) {
    val context = LocalContext.current
    val graph = context.graph
    val session = graph.session
    val scope = rememberCoroutineScope()
    val speaker = remember { Speaker(context) }
    val speaking by speaker.speaking.collectAsState()
    val switches by graph.settings.switches.collectAsState()
    val self by session.self.collectAsState()
    val hideText = self?.hideReplyText == true || session.glance.collectAsState().value.glance?.hideReplyText == true
    var chat by remember(botId, conversationId) { mutableStateOf<WatchChat?>(session.cache.chat(botId)?.takeIf { conversationId == null || it.conversationId == conversationId }) }
    var offline by remember(botId, conversationId) { mutableStateOf(false) }
    var savedAt by remember(botId, conversationId) { mutableStateOf<Long?>(null) }

    DisposableEffect(Unit) { onDispose { speaker.shutdown() } }

    fun speak(m: WatchMessage) {
        scope.launch { speaker.speak(session, m.id, m.text, serverVoice = m.canSpeak && self?.features?.speech != false) }
    }

    LaunchedEffect(botId, conversationId) {
        try {
            val (c, raw) = session.call { chat(botId, conversationId) }
            chat = c
            offline = false
            session.cache.saveChat(botId, raw)
            savedAt = System.currentTimeMillis()
            // A run is still going in this chat: follow it.
            c.runId?.let { id -> if (OngoingRun.follows(context, id)) nav.go(Routes.working(id)) }
            val last = c.messages.lastOrNull { !it.fromUser }
            if (last != null && (readAloud || switches.readRepliesAloud) && !hideText) speak(last)
        } catch (_: ApiError) {
            offline = true
        }
    }

    val c = chat
    if (c == null) {
        Message(if (offline) stringResource(R.string.watch_couldnt_reach) else stringResource(R.string.watch_chat), null, modifier = Modifier.fillMaxSize())
        return
    }
    val lastReply = c.messages.lastOrNull { !it.fromUser }

    ListScreen(edgeButton = {
        EdgeButton(
            onClick = { nav.go(Routes.ask(c.bot.id, listen = true, conversationId = c.conversationId)) },
            colors = ButtonDefaults.buttonColors(containerColor = CasamaColors.Orchid, contentColor = CasamaColors.OnOrchid),
        ) {
            Icon(painterResource(R.drawable.ic_mic), contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(6.dp))
            Text(stringResource(R.string.watch_reply))
        }
    }) { spec ->
        item {
            Row(verticalAlignment = Alignment.CenterVertically) {
                BotFace(c.bot.name, c.bot.avatar, 24.dp)
                Spacer(Modifier.width(6.dp))
                Text(c.bot.name, style = MaterialTheme.typography.titleSmall, maxLines = 1)
            }
        }
        if (offline) item { AsOf(savedAt, offline = true) }
        if (c.bot.status == BotStatus.WORKING) {
            item { Text(stringResource(R.string.watch_is_working, c.bot.name), color = CasamaColors.Working, style = MaterialTheme.typography.bodySmall) }
        }
        c.messages.takeLast(6).forEach { m ->
            item {
                Card(
                    onClick = { if (!m.fromUser && !hideText) speak(m) },
                    enabled = !m.fromUser,
                    modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                    transformation = SurfaceTransformation(spec),
                ) {
                    Column {
                        Text(
                            if (m.fromUser) stringResource(R.string.watch_you) else c.bot.name,
                            style = MaterialTheme.typography.labelSmall,
                            color = if (m.fromUser) CasamaColors.Orchid else CasamaColors.Secondary,
                        )
                        if (hideText && !m.fromUser) {
                            Text(stringResource(R.string.watch_reply_ready), style = MaterialTheme.typography.bodyMedium)
                        } else {
                            Words(m.text, maxLines = 12, style = MaterialTheme.typography.bodyMedium)
                        }
                        m.attachments.forEach { a ->
                            Text("${attachmentMark(a.kind)} ${a.title}", style = MaterialTheme.typography.bodySmall, color = CasamaColors.Secondary, maxLines = 1)
                        }
                        if (m.cut) {
                            Text(stringResource(R.string.watch_continues_on_phone), style = MaterialTheme.typography.bodySmall, color = CasamaColors.Secondary)
                        }
                        m.at?.let { Text(clockTime(it), style = MaterialTheme.typography.labelSmall, color = CasamaColors.Dim) }
                    }
                }
            }
        }
        if (lastReply != null && !hideText) {
            item {
                FilledTonalButton(
                    onClick = { if (speaking) speaker.stop() else speak(lastReply) },
                    modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                    transformation = SurfaceTransformation(spec),
                    icon = { Icon(painterResource(if (speaking) R.drawable.ic_stop else R.drawable.ic_speaker), contentDescription = null, modifier = Modifier.size(18.dp)) },
                    label = { Text(stringResource(if (speaking) R.string.watch_stop_reading else R.string.watch_read_aloud), maxLines = 1) },
                )
            }
        }
        item {
            FilledTonalButton(
                onClick = { scope.launch { openOnPhone(context, c.link, c.bot.name) } },
                modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                transformation = SurfaceTransformation(spec),
                icon = { Icon(painterResource(R.drawable.ic_phone), contentDescription = null, modifier = Modifier.size(18.dp)) },
                label = { Text(stringResource(R.string.watch_open_on_phone), maxLines = 1) },
            )
        }
    }
}

/** A plain mark for an attachment's kind; the title says what it is. */
private fun attachmentMark(kind: AttachmentKind): String = when (kind) {
    AttachmentKind.IMAGE -> "▣"
    AttachmentKind.VIDEO -> "▶"
    AttachmentKind.AUDIO -> "♪"
    AttachmentKind.LINK -> "↗"
    else -> "▤"
}

/** Bots (§6.1 F): each bot, what it's doing, tap to chat, the mic to ask it. */
@Composable
fun BotsScreen(nav: NavHostController) {
    val graph = LocalContext.current.graph
    val state by graph.session.glance.collectAsState()
    val bots = state.glance?.bots.orEmpty()
    ListScreen { spec ->
        item { Text(stringResource(R.string.watch_bots), style = MaterialTheme.typography.titleSmall) }
        if (bots.isEmpty()) item { Message(stringResource(R.string.watch_no_bots), null) }
        bots.forEach { b ->
            item {
                Card(
                    onClick = { nav.go(Routes.chat(b.id, null)) },
                    modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                    transformation = SurfaceTransformation(spec),
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        BotFace(b.name, b.avatar, 28.dp)
                        Column(Modifier.weight(1f)) {
                            Text(b.name, style = MaterialTheme.typography.titleSmall, maxLines = 1)
                            val line = when (b.status) {
                                BotStatus.WORKING -> b.step ?: stringResource(R.string.watch_working)
                                BotStatus.WAITING -> stringResource(R.string.watch_waiting_for_you)
                                BotStatus.DISABLED -> stringResource(R.string.watch_off)
                                BotStatus.IDLE -> b.lastAt?.let { stringResource(R.string.watch_replied_at, clockTime(it).replace(' ', '\u00A0')) } ?: stringResource(R.string.watch_idle)
                            }
                            Words(
                                line,
                                maxLines = 2,
                                style = MaterialTheme.typography.bodySmall,
                                color = when (b.status) {
                                    BotStatus.WORKING -> CasamaColors.Working
                                    BotStatus.WAITING -> CasamaColors.Needs
                                    else -> CasamaColors.Secondary
                                },
                            )
                        }
                        if (b.status != BotStatus.DISABLED) {
                            FilledTonalButton(
                                onClick = {
                                    graph.settings.lastAskBotId = b.id
                                    nav.go(Routes.ask(b.id, listen = true))
                                },
                                modifier = Modifier.size(40.dp),
                                label = { Icon(painterResource(R.drawable.ic_mic), contentDescription = stringResource(R.string.watch_ask_bot, b.name), modifier = Modifier.size(18.dp)) },
                            )
                        }
                    }
                }
            }
        }
    }
}

/** Up next (§6.1 G): the routines coming up, each with Run Now. */
@Composable
fun UpNextScreen(nav: NavHostController) {
    val context = LocalContext.current
    val graph = context.graph
    val session = graph.session
    val scope = rememberCoroutineScope()
    val state by session.glance.collectAsState()
    val routines = state.glance?.next.orEmpty()
    var started by remember { mutableStateOf(setOf<String>()) }
    var failed by remember { mutableStateOf<String?>(null) }
    ListScreen { spec ->
        item { Text(stringResource(R.string.watch_up_next), style = MaterialTheme.typography.titleSmall) }
        if (routines.isEmpty()) item { Message(stringResource(R.string.watch_no_routines), null) }
        routines.forEach { r ->
            item {
                Card(
                    onClick = { nav.go(Routes.chat(r.botId, null)) },
                    modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                    transformation = SurfaceTransformation(spec),
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        BotFace(r.bot, r.botAvatar, 22.dp)
                        Spacer(Modifier.width(6.dp))
                        Text(r.nextAt?.let { untilText(it) } ?: r.every, style = MaterialTheme.typography.labelSmall, color = CasamaColors.Secondary, maxLines = 1)
                    }
                    Words(r.name, maxLines = 2, style = MaterialTheme.typography.titleSmall)
                    if (failed == r.id) Text(stringResource(R.string.watch_couldnt_reach), color = CasamaColors.Stop, style = MaterialTheme.typography.bodySmall)
                    Spacer(Modifier.height(4.dp))
                    FilledTonalButton(
                        onClick = {
                            if (r.id in started) return@FilledTonalButton
                            scope.launch {
                                try {
                                    val runId = session.call { runRoutine(r.id) }
                                    started = started + r.id
                                    failed = null
                                    graph.haptics.done()
                                    runId?.let {
                                        OngoingRun.startedOnWatch(it)
                                        nav.go(Routes.working(it))
                                    }
                                } catch (_: ApiError) {
                                    failed = r.id
                                }
                            }
                        },
                        enabled = r.enabled,
                        colors = ButtonDefaults.filledTonalButtonColors(
                            containerColor = CasamaColors.Tone,
                            contentColor = CasamaColors.OnTone,
                        ),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
                        modifier = Modifier.fillMaxWidth().height(36.dp),
                        icon = { Icon(painterResource(R.drawable.ic_play), contentDescription = null, modifier = Modifier.size(15.dp)) },
                        label = { Text(stringResource(if (r.id in started) R.string.watch_started else R.string.watch_run_now), maxLines = 1) },
                    )
                }
            }
        }
    }
}

/** The brief (§6.1 H): today's text from the brief bot, Read aloud, and when the next one comes. */
@Composable
fun BriefScreen(readAloud: Boolean) {
    val context = LocalContext.current
    val graph = context.graph
    val session = graph.session
    val scope = rememberCoroutineScope()
    val speaker = remember { Speaker(context) }
    val speaking by speaker.speaking.collectAsState()
    val state by session.glance.collectAsState()
    val brief = state.glance?.brief
    DisposableEffect(Unit) { onDispose { speaker.shutdown() } }
    val text = brief?.text
    LaunchedEffect(text) {
        if (readAloud && !text.isNullOrBlank()) speaker.speak(session, null, text, serverVoice = false)
    }
    fun toggleSpeak() {
        if (text.isNullOrBlank()) return
        if (speaking) speaker.stop() else scope.launch { speaker.speak(session, null, text, serverVoice = false) }
    }
    ListScreen { spec ->
        item { Text(stringResource(R.string.watch_brief), style = MaterialTheme.typography.titleSmall) }
        if (brief == null || text.isNullOrBlank()) {
            item {
                Message(
                    stringResource(R.string.watch_no_brief),
                    brief?.nextAt?.let { stringResource(R.string.watch_brief_at, clockTime(it)) },
                )
            }
            return@ListScreen
        }
        item {
            FilledTonalButton(
                onClick = { toggleSpeak() },
                modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                transformation = SurfaceTransformation(spec),
                icon = { Icon(painterResource(if (speaking) R.drawable.ic_stop else R.drawable.ic_speaker), contentDescription = null, modifier = Modifier.size(18.dp)) },
                label = { Text(stringResource(if (speaking) R.string.watch_stop_reading else R.string.watch_read_aloud), maxLines = 1) },
            )
        }
        item {
            Card(
                onClick = { toggleSpeak() },
                modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                transformation = SurfaceTransformation(spec),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    BotFace(brief.bot, brief.botAvatar, 22.dp)
                    Spacer(Modifier.width(6.dp))
                    Text(brief.at?.let { clockTime(it) } ?: brief.bot, style = MaterialTheme.typography.labelSmall, color = CasamaColors.Secondary)
                }
                Spacer(Modifier.height(4.dp))
                Words(text, maxLines = 20, style = MaterialTheme.typography.bodyMedium)
            }
        }
        brief.nextAt?.let { next ->
            item { Text(stringResource(R.string.watch_brief_at, clockTime(next)), style = MaterialTheme.typography.bodySmall, color = CasamaColors.Secondary, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth()) }
        }
    }
}

/**
 * Talk (§6.1 I): live voice calls run on the phone, where the audio and the call screen are; the
 * watch hands the call off and says so.
 */
@Composable
fun TalkScreen(nav: NavHostController, botId: String?) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val glance by context.graph.session.glance.collectAsState()
    val bot = glance.glance?.bot(botId)
    var sent by remember { mutableStateOf<Boolean?>(null) }
    ListScreen(edgeButton = {
        EdgeButton(onClick = {
            scope.launch {
                val link = if (bot != null) "/bots/${bot.id}/call" else "/"
                sent = openOnPhone(context, link, bot?.name.orEmpty())
            }
        }) {
            Icon(painterResource(R.drawable.ic_phone), contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(6.dp))
            Text(stringResource(R.string.watch_open_on_phone), maxLines = 1)
        }
    }) { _ ->
        bot?.let { b -> item { BotFace(b.name, b.avatar, 36.dp) } }
        item { Text(stringResource(R.string.watch_talk), style = MaterialTheme.typography.titleMedium, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth()) }
        item {
            Text(
                stringResource(
                    when (sent) {
                        true -> R.string.watch_sent_to_phone
                        false -> R.string.watch_couldnt_reach
                        null -> R.string.watch_talk_on_phone
                    },
                ),
                style = MaterialTheme.typography.bodySmall,
                color = CasamaColors.Secondary,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}
