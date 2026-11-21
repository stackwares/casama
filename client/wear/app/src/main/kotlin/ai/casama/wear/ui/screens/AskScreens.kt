package ai.casama.wear.ui.screens

import ai.casama.wear.R
import ai.casama.wear.core.Encode
import ai.casama.wear.core.GlanceBot
import ai.casama.wear.core.Logic
import ai.casama.wear.core.QueuedAsk
import ai.casama.wear.core.RunPhase
import ai.casama.wear.core.WatchAsked
import ai.casama.wear.core.WatchRun
import ai.casama.wear.data.ApiError
import ai.casama.wear.graph
import ai.casama.wear.live.OngoingRun
import ai.casama.wear.ui.Routes
import ai.casama.wear.ui.components.BotFace
import ai.casama.wear.ui.components.DoneScreen
import ai.casama.wear.ui.components.Eyebrow
import ai.casama.wear.ui.components.Message
import ai.casama.wear.ui.components.Words
import ai.casama.wear.ui.components.reduceMotion
import ai.casama.wear.ui.components.runningClock
import ai.casama.wear.ui.replace
import ai.casama.wear.ui.theme.CasamaColors
import ai.casama.wear.ui.theme.LocalAmbient
import ai.casama.wear.voice.Recorder
import android.Manifest
import android.app.Activity
import android.app.RemoteInput
import android.content.pm.PackageManager
import android.util.Base64
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
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
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.navigation.NavHostController
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.EdgeButton
import androidx.wear.compose.material3.FilledTonalButton
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.SurfaceTransformation
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.lazy.transformedHeight
import androidx.wear.input.RemoteInputIntentHelper
import java.io.File
import java.time.Instant
import java.util.Locale
import java.util.UUID
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private const val TYPED = "casama_typed"

/** Where asking stands (§6.1 C). */
private sealed interface Stage {
    /** Starters, the mic and Type instead. */
    data object Choose : Stage
    data object Listening : Stage
    data object Sending : Stage
    /** What the server heard (or got typed), with a moment to Undo before it moves on. */
    data class Heard(val asked: WatchAsked, val typed: Boolean = false) : Stage
    /** Offline: saved, it sends when the watch is back online. */
    data object Kept : Stage
    data object Silent : Stage
    /** The server has no voice service for this ask: Type instead. */
    data object NoVoice : Stage
    data object MicDenied : Stage
    data object Failed : Stage
    data object OutOfCredits : Stage
}

/**
 * Ask (§6.1 C): the watch listens at once when opened from a tile, complication or the Ask button;
 * it stops after a moment's quiet or a tap. The server hears it; the watch shows what it heard,
 * with Undo, then follows the run. Offline it keeps the ask and sends it later; an ask kept for
 * more than ten minutes asks first (Now shows it).
 */
@Composable
fun AskScreen(nav: NavHostController, botId: String?, listen: Boolean, conversationId: String? = null) {
    val context = LocalContext.current
    val graph = context.graph
    val session = graph.session
    val scope = rememberCoroutineScope()
    val glance by session.glance.collectAsState()
    val self by session.self.collectAsState()
    val bot: GlanceBot? = glance.glance?.bot(botId) ?: Logic.askBot(glance.glance, graph.settings.lastAskBotId, self?.askBotId)
    val dictation = self?.features?.dictation ?: true
    val outOfCredits = self?.features?.outOfCredits == true
    val recorder = remember { Recorder(context) }
    var stage by remember { mutableStateOf<Stage>(if (outOfCredits) Stage.OutOfCredits else Stage.Choose) }
    var job by remember { mutableStateOf<Job?>(null) }

    DisposableEffect(Unit) { onDispose { recorder.stop(); job?.cancel() } }

    fun send(text: String?, audio: Recorder.Result.Audio?) {
        val target = bot ?: return
        graph.settings.lastAskBotId = target.id
        stage = Stage.Sending
        job = scope.launch {
            // A recording kept for later must outlive the cache: it moves into the app's files.
            val audioFile = audio?.file?.let { f ->
                val dir = File(context.filesDir, "outbox").apply { mkdirs() }
                val kept = File(dir, f.name)
                if (f.renameTo(kept)) kept else f
            }
            val item = QueuedAsk(
                id = UUID.randomUUID().toString(),
                botId = target.id,
                conversationId = conversationId,
                text = text,
                audioPath = audioFile?.absolutePath,
                audioMime = audio?.mime,
                askedAt = System.currentTimeMillis(),
                surface = "app",
            )
            val body = Encode.ask(
                botId = item.botId,
                conversationId = item.conversationId,
                text = item.text,
                audioBase64 = audioFile?.readBytes()?.let { Base64.encodeToString(it, Base64.NO_WRAP) },
                audioMime = item.audioMime,
                language = Locale.getDefault().toLanguageTag(),
                askedAtIso = Instant.ofEpochMilli(item.askedAt).toString(),
                surface = item.surface,
            )
            stage = try {
                val asked = session.call { ask(body, item.id) }
                audioFile?.delete()
                asked.runId?.let { OngoingRun.startedOnWatch(it) }
                Stage.Heard(asked, typed = audio == null)
            } catch (_: ApiError.Offline) {
                graph.outbox.keep(item)
                Stage.Kept
            } catch (_: ApiError.Server) {
                // 5xx only: the server had a problem, so it is worth sending again later.
                graph.outbox.keep(item)
                Stage.Kept
            } catch (_: ApiError.RateLimited) {
                graph.outbox.keep(item)
                Stage.Kept
            } catch (e: ApiError.Refused) {
                // The server won't take it, and would answer the same to every retry: never kept.
                audioFile?.delete()
                when {
                    e.code == "nothing_heard" -> Stage.Silent
                    e.status == 402 -> Stage.OutOfCredits
                    else -> {
                        graph.haptics.problem()
                        Stage.Failed
                    }
                }
            } catch (e: ApiError.Conflict) {
                audioFile?.delete()
                if (e.code == "voice_unavailable") Stage.NoVoice else Stage.Failed
            } catch (_: ApiError.Forbidden) {
                audioFile?.delete()
                // Out of credits, or the bot is no longer this person's to ask.
                if (session.self.value?.features?.outOfCredits == true) Stage.OutOfCredits else Stage.Failed
            } catch (_: ApiError) {
                audioFile?.delete()
                graph.haptics.problem()
                Stage.Failed
            }
        }
    }

    fun startListening() {
        if (bot == null || !dictation) return
        stage = Stage.Listening
        job = scope.launch {
            when (val r = recorder.record()) {
                is Recorder.Result.Audio -> send(null, r)
                Recorder.Result.Silent -> stage = Stage.Silent
                is Recorder.Result.Failed -> stage = Stage.Failed
            }
        }
    }

    val micPermission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) startListening() else stage = Stage.MicDenied
    }
    fun listenNow() {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
            startListening()
        } else {
            micPermission.launch(Manifest.permission.RECORD_AUDIO)
        }
    }

    // Type instead: the system's keyboard, handwriting or voice input (§6.1 C).
    val typeLauncher = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        if (result.resultCode != Activity.RESULT_OK) return@rememberLauncherForActivityResult
        val typed = result.data?.let { RemoteInput.getResultsFromIntent(it) }?.getCharSequence(TYPED)?.toString()
        if (!typed.isNullOrBlank()) send(typed, null)
    }
    val typeLabel = stringResource(R.string.watch_type_instead)
    val askLabel = bot?.let { stringResource(R.string.watch_ask_bot, it.name) } ?: stringResource(R.string.watch_ask)
    fun typeInstead() {
        val intent = RemoteInputIntentHelper.createActionRemoteInputIntent()
        RemoteInputIntentHelper.putRemoteInputsExtra(intent, listOf(RemoteInput.Builder(TYPED).setLabel(typeLabel).build()))
        RemoteInputIntentHelper.putTitleExtra(intent, askLabel)
        typeLauncher.launch(intent)
    }

    // "Open listening" is used once. Saved with the screen, so an activity the system re-creates
    // doesn't open the microphone again by itself.
    var listenUsed by rememberSaveable { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        if (listen && !listenUsed && stage == Stage.Choose && dictation && bot != null) {
            listenUsed = true
            listenNow()
        }
    }

    when (val s = stage) {
        Stage.Listening -> Listening(bot, recorder) { recorder.stop() }
        Stage.Sending -> Message(stringResource(R.string.watch_sending), null, modifier = Modifier.fillMaxSize())
        is Stage.Heard -> Heard(
            asked = s.asked,
            typed = s.typed,
            onUndo = {
                scope.launch {
                    s.asked.runId?.let { id -> runCatching { session.call { cancelRun(id, "w-undo-$id") } } }
                    nav.popBackStack()
                }
            },
            onNext = {
                val run = s.asked.runId
                if (run != null) nav.replace(Routes.working(run)) else nav.replace(Routes.chat(bot?.id.orEmpty(), s.asked.conversationId))
            },
        )
        Stage.Kept -> DoneScreen(stringResource(R.string.watch_kept_offline), null) { nav.popBackStack() }
        Stage.OutOfCredits -> Message(stringResource(R.string.watch_out_of_credits), null, modifier = Modifier.fillMaxSize())
        else -> ListScreen(
            edgeButton = if (dictation && bot != null) {
                {
                    EdgeButton(
                        onClick = { listenNow() },
                        colors = ButtonDefaults.buttonColors(containerColor = CasamaColors.Orchid, contentColor = CasamaColors.OnOrchid),
                    ) {
                        Icon(painterResource(R.drawable.ic_mic), contentDescription = askLabel, modifier = Modifier.size(22.dp))
                    }
                }
            } else {
                null
            },
        ) { spec ->
            if (bot == null) {
                item { Message(stringResource(R.string.watch_no_bots), null) }
                return@ListScreen
            }
            item { BotFace(bot.name, bot.avatar, 30.dp) }
            item { Text(askLabel, style = MaterialTheme.typography.titleSmall, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth()) }
            val note = when (s) {
                Stage.Silent -> R.string.watch_didnt_catch
                Stage.NoVoice -> R.string.watch_no_dictation
                Stage.MicDenied -> R.string.watch_mic_denied
                Stage.Failed -> R.string.watch_couldnt_reach
                else -> if (!dictation) R.string.watch_no_dictation else null
            }
            note?.let { n ->
                item { Text(stringResource(n), color = CasamaColors.Secondary, style = MaterialTheme.typography.bodySmall, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth()) }
            }
            // Starters: the bot's own short asks, one tap to send (§6.1 C).
            glance.glance?.starters.orEmpty().take(4).forEach { st ->
                item {
                    FilledTonalButton(
                        onClick = { send(st.text, null) },
                        modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                        transformation = SurfaceTransformation(spec),
                    ) { Text(st.label, maxLines = 2) }
                }
            }
            item {
                FilledTonalButton(
                    onClick = { typeInstead() },
                    modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                    transformation = SurfaceTransformation(spec),
                    icon = { Icon(painterResource(R.drawable.ic_keyboard), contentDescription = null, modifier = Modifier.size(18.dp)) },
                    label = { Text(typeLabel, maxLines = 1) },
                )
            }
            if (glance.glance?.bots.orEmpty().size > 1) {
                item {
                    FilledTonalButton(
                        onClick = { nav.navigate(ai.casama.wear.ui.Routes.BOTS) { launchSingleTop = true } },
                        modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                        transformation = SurfaceTransformation(spec),
                        icon = { Icon(painterResource(R.drawable.ic_bots), contentDescription = null, modifier = Modifier.size(18.dp)) },
                        label = { Text(stringResource(R.string.watch_choose_bot), maxLines = 1) },
                    )
                }
            }
        }
    }
}

/** Listening: the bot's face inside a ring that follows the voice; a tap stops. */
@Composable
private fun Listening(bot: GlanceBot?, recorder: Recorder, onStop: () -> Unit) {
    val level by recorder.level.collectAsState()
    val label = stringResource(R.string.watch_listening)
    Box(
        Modifier
            .fillMaxSize()
            .padding(top = 22.dp, bottom = 8.dp)
            .semantics { contentDescription = label },
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(contentAlignment = Alignment.Center) {
                Ring(color = CasamaColors.Orchid, size = 76.dp, sweep = 0.25f + 0.75f * level, spinning = false)
                BotFace(bot?.name.orEmpty(), bot?.avatar, 44.dp)
            }
            Spacer(Modifier.height(6.dp))
            Text(label, style = MaterialTheme.typography.titleSmall, color = CasamaColors.Orchid)
            Spacer(Modifier.height(4.dp))
            FilledTonalButton(onClick = onStop, label = { Text(stringResource(R.string.watch_tap_to_stop), maxLines = 1) })
        }
    }
}

/**
 * Heard: the words the server got, Undo for four seconds, then on to the run. A typed ask says
 * "Sent", since nothing was heard.
 */
@Composable
private fun Heard(asked: WatchAsked, typed: Boolean, onUndo: () -> Unit, onNext: () -> Unit) {
    var undone by remember { mutableStateOf(false) }
    LaunchedEffect(asked) {
        delay(4_000)
        if (!undone) onNext()
    }
    ListScreen(edgeButton = {
        EdgeButton(onClick = { undone = true; onUndo() }) { Text(stringResource(R.string.watch_undo)) }
    }) { _ ->
        item { Eyebrow(stringResource(if (typed) R.string.watch_reply_sent else R.string.watch_heard), CasamaColors.Orchid) }
        item {
            Words("“${asked.heard}”", maxLines = 4, style = MaterialTheme.typography.titleMedium, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
        }
    }
}

/**
 * A ring: a turning arc while a bot works, or a level meter while listening. With reduce motion
 * on, or wrist down, it stands still (§6.7).
 */
@Composable
fun Ring(color: Color, size: Dp, sweep: Float = 0.3f, spinning: Boolean = true) {
    val still = reduceMotion() || LocalAmbient.current || !spinning
    val angle = if (still) {
        -90f
    } else {
        val t = rememberInfiniteTransition(label = "ring")
        val a by t.animateFloat(
            initialValue = 0f,
            targetValue = 360f,
            animationSpec = infiniteRepeatable(tween(1400, easing = LinearEasing), RepeatMode.Restart),
            label = "angle",
        )
        a
    }
    val track = CasamaColors.Card
    Canvas(Modifier.size(size)) {
        val stroke = Stroke(width = 5.dp.toPx(), cap = StrokeCap.Round)
        drawArc(track, 0f, 360f, useCenter = false, style = stroke)
        drawArc(color, angle, 360f * sweep.coerceIn(0.02f, 1f), useCenter = false, style = stroke)
    }
}

/**
 * Working (§6.1 D): the run live over the server's event stream, step by step, with Stop. It turns
 * into the request when the bot needs an OK, and into the reply when it's done, with a tap on the
 * wrist. Runs started here also show as an Ongoing Activity on the watch face.
 */
@Composable
fun WorkingScreen(nav: NavHostController, runId: String) {
    val context = LocalContext.current
    val graph = context.graph
    val session = graph.session
    val scope = rememberCoroutineScope()
    val fromGlance = session.glance.collectAsState().value.glance?.runs?.firstOrNull { it.id == runId }
    // The run's own state: another run opened over this one starts clean (see RequestScreen).
    var run by remember(runId) { mutableStateOf<WatchRun?>(null) }
    var stopped by remember(runId) { mutableStateOf(false) }
    var stopping by remember(runId) { mutableStateOf(false) }

    LaunchedEffect(runId) {
        runCatching { run = session.call { run(runId) } }
        try {
            session.api.runStream(runId).collect { r ->
                run = r
                if (OngoingRun.follows(context, runId)) OngoingRun.show(context, r)
                when (r.phase) {
                    RunPhase.NEEDS_OK -> r.approval?.let { a ->
                        graph.haptics.needsYou()
                        nav.replace(Routes.request(a.id))
                    }
                    RunPhase.FINISHED -> {
                        graph.haptics.done()
                        OngoingRun.end(context, runId)
                        session.refresh()
                        nav.replace(Routes.chat(r.botId, r.conversationId))
                    }
                    RunPhase.PROBLEM -> {
                        graph.haptics.problem()
                        OngoingRun.end(context, runId)
                    }
                    RunPhase.STOPPED -> OngoingRun.end(context, runId)
                    else -> Unit
                }
            }
        } catch (e: ApiError.SignedOut) {
            // Session.call already signed the watch out.
        } catch (_: ApiError) {
            // The stream gave up: what's on screen stays, the glance carries on.
        }
    }

    if (stopped) {
        DoneScreen(stringResource(R.string.watch_stopped), null) { nav.popBackStack() }
        return
    }

    val r = run
    val phase = r?.phase ?: fromGlance?.phase ?: RunPhase.WORKING
    val bot = r?.bot ?: fromGlance?.bot.orEmpty()
    val avatar = r?.botAvatar ?: fromGlance?.botAvatar.orEmpty()
    val step = r?.step ?: fromGlance?.step.orEmpty()
    val steps = r?.steps ?: fromGlance?.steps ?: 0
    val started = r?.startedAt ?: fromGlance?.startedAt

    ListScreen(
        edgeButton = if (phase.live) {
            {
                EdgeButton(
                    onClick = {
                        if (stopping) return@EdgeButton
                        stopping = true
                        scope.launch {
                            try {
                                session.call { cancelRun(runId, "w-stop-$runId") }
                                OngoingRun.end(context, runId)
                                stopped = true
                            } catch (e: ApiError.Conflict) {
                                if (Logic.conflict(e.code) == Logic.ConflictKind.OVER) {
                                    // It ended by itself a moment before the tap (409 run_finished):
                                    // nothing to stop and nothing wrong. Show how it ended.
                                    OngoingRun.end(context, runId)
                                    runCatching { session.call { run(runId) } }.getOrNull()?.let { run = it }
                                    session.refresh()
                                } else {
                                    graph.haptics.problem()
                                }
                            } catch (_: ApiError) {
                                graph.haptics.problem()
                            } finally {
                                stopping = false
                            }
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = CasamaColors.StopContainer, contentColor = CasamaColors.OnStopContainer),
                ) {
                    Icon(painterResource(R.drawable.ic_stop), contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(6.dp))
                    Text(stringResource(R.string.watch_stop))
                }
            }
        } else {
            null
        },
    ) { _ ->
        item {
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Ring(
                        color = when (phase) {
                            RunPhase.PROBLEM -> CasamaColors.Stop
                            RunPhase.NEEDS_OK, RunPhase.TAKE_OVER -> CasamaColors.Needs
                            else -> CasamaColors.Working
                        },
                        size = 48.dp,
                        sweep = if (phase.live) 0.3f else 1f,
                        spinning = phase == RunPhase.WORKING,
                    )
                    BotFace(bot, avatar, 32.dp)
                }
                Spacer(Modifier.height(4.dp))
                val title = when (phase) {
                    RunPhase.FINISHED -> stringResource(R.string.watch_finished)
                    RunPhase.PROBLEM -> stringResource(R.string.watch_couldnt_finish)
                    RunPhase.STOPPED -> stringResource(R.string.watch_stopped)
                    RunPhase.NEEDS_OK -> stringResource(R.string.watch_needs_ok)
                    RunPhase.TAKE_OVER -> stringResource(R.string.watch_take_over)
                    RunPhase.WORKING -> stringResource(R.string.watch_is_working, bot)
                }
                Text(title, style = MaterialTheme.typography.titleSmall, textAlign = TextAlign.Center, maxLines = 1, modifier = Modifier.fillMaxWidth())
                if (step.isNotBlank() && phase.live) {
                    Words(step, maxLines = 2, style = MaterialTheme.typography.bodySmall, color = CasamaColors.Secondary, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
                }
                val parts = listOfNotNull(
                    steps.takeIf { it > 0 }?.let { stringResource(R.string.watch_step_count, it.toString()) },
                    started?.let { runningClock(it, r?.endedAt, running = phase.live) },
                )
                if (parts.isNotEmpty()) {
                    Text(parts.joinToString(" · "), style = MaterialTheme.typography.labelSmall, color = CasamaColors.Secondary, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
                }
            }
        }
        if (phase == RunPhase.TAKE_OVER || phase == RunPhase.PROBLEM) {
            item {
                FilledTonalButton(
                    onClick = { scope.launch { openOnPhone(context, r?.link ?: fromGlance?.link ?: "/", bot) } },
                    modifier = Modifier.fillMaxWidth(),
                    icon = { Icon(painterResource(R.drawable.ic_phone), contentDescription = null, modifier = Modifier.size(18.dp)) },
                    label = { Text(stringResource(R.string.watch_open_on_phone), maxLines = 1) },
                )
            }
        }
    }
}

