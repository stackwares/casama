package ai.casama.wear.ui.screens

import ai.casama.wear.R
import ai.casama.wear.core.ApprovalStatus
import ai.casama.wear.core.GlanceNeed
import ai.casama.wear.core.Logic
import ai.casama.wear.core.NeedKind
import ai.casama.wear.core.WatchApproval
import ai.casama.wear.core.WhyPhone
import ai.casama.wear.data.ApiError
import ai.casama.wear.graph
import ai.casama.wear.ui.components.BotFace
import ai.casama.wear.ui.components.DoneScreen
import ai.casama.wear.ui.components.HoldToAllowButton
import ai.casama.wear.ui.components.Message
import ai.casama.wear.ui.components.Words
import ai.casama.wear.ui.theme.CasamaColors
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
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

/** Needs you (§6.1 B), the list: every request and suggestion, most urgent first. */
@Composable
fun NeedsScreen(nav: NavHostController) {
    val context = LocalContext.current
    val session = context.graph.session
    val scope = rememberCoroutineScope()
    val state by session.glance.collectAsState()
    val needs = state.glance?.needs.orEmpty()
    // The count also has things the watch gets no item for (a skill idea): they are on the phone.
    val more = (state.glance?.needsCount ?: 0) - needs.size
    // A need sent to the phone: its id, and whether that worked.
    var sent by remember { mutableStateOf<Pair<String, Boolean>?>(null) }
    ListScreen { spec ->
        item {
            Text(stringResource(R.string.watch_needs_you), color = CasamaColors.Needs, style = MaterialTheme.typography.titleSmall, modifier = Modifier.padding(bottom = 4.dp))
        }
        if (needs.isEmpty() && more <= 0) {
            item { Message(stringResource(R.string.watch_all_clear), stringResource(R.string.watch_nothing_waiting)) }
        }
        needs.forEach { n ->
            item {
                val answerable = n.kind == NeedKind.APPROVAL || n.kind == NeedKind.SUGGESTION
                val title = needText(n)
                Card(
                    onClick = {
                        if (answerable) {
                            openNeed(nav, n)
                        } else {
                            // A takeover, a password, a question: the phone's to answer.
                            scope.launch { sent = n.id to openOnPhone(context, n.link, title.ifBlank { n.bot }) }
                        }
                    },
                    modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                    transformation = SurfaceTransformation(spec),
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        BotFace(n.bot, n.botAvatar, 24.dp)
                        Spacer(Modifier.width(8.dp))
                        Column {
                            Words(title, maxLines = 2, style = MaterialTheme.typography.titleSmall)
                            Text(listOfNotNull(n.bot, riskLabel(n.risk)).joinToString(" · "), style = MaterialTheme.typography.bodySmall, color = CasamaColors.Secondary, maxLines = 1)
                            if (!answerable) {
                                val line = when (sent?.takeIf { it.first == n.id }?.second) {
                                    true -> R.string.watch_sent_to_phone
                                    false -> R.string.watch_couldnt_reach
                                    null -> R.string.watch_open_on_phone
                                }
                                Text(stringResource(line), style = MaterialTheme.typography.bodySmall, color = CasamaColors.Orchid, maxLines = 1)
                            }
                        }
                    }
                }
            }
        }
        if (more > 0) {
            item {
                Text(
                    stringResource(R.string.watch_more_on_phone, more.toString()),
                    style = MaterialTheme.typography.bodySmall,
                    color = CasamaColors.Secondary,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }
    }
}

/**
 * Something this watch can't answer: it is in another workspace than the watch is signed in to
 * ([otherWorkspace], a push that said so), or the server says it isn't this watch's (a 404
 * `not_found`). Never "Already answered": it may still be waiting. The phone can answer it.
 */
@Composable
fun ElsewhereScreen(nav: NavHostController, link: String, title: String, otherWorkspace: Boolean) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var done by remember(link) { mutableStateOf<Boolean?>(null) }
    done?.let { ok ->
        DoneScreen(stringResource(if (ok) R.string.watch_sent_to_phone else R.string.watch_couldnt_reach), null, good = ok) { nav.popBackStack() }
        return
    }
    ListScreen(edgeButton = {
        EdgeButton(onClick = { scope.launch { done = openOnPhone(context, link, title) } }) {
            Icon(painterResource(R.drawable.ic_phone), contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(6.dp))
            Text(stringResource(R.string.watch_open_on_phone), maxLines = 1)
        }
    }) { _ ->
        if (title.isNotBlank()) {
            item { Words(title, maxLines = 3, style = MaterialTheme.typography.titleMedium, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth()) }
        }
        item {
            Text(
                stringResource(if (otherWorkspace) R.string.watch_other_workspace else R.string.watch_not_on_watch),
                style = MaterialTheme.typography.bodySmall,
                color = CasamaColors.Secondary,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}

@Composable
private fun needText(n: GlanceNeed): String = when (n.kind) {
    NeedKind.TAKEOVER -> n.text.ifBlank { stringResource(R.string.watch_take_over) }
    else -> n.text
}

/**
 * A request (§6.1 B), as the server says this watch may answer it: low risk Allow in one tap,
 * medium Hold to allow, high risk or a payment Review on phone. Deny always works and is never the
 * first button. Never Always Allow. After answering: a tick, a tap on the wrist, and it closes.
 */
@Composable
fun RequestScreen(nav: NavHostController, approvalId: String) {
    val context = LocalContext.current
    val graph = context.graph
    val session = graph.session
    val scope = rememberCoroutineScope()
    // Every piece of state is the request's it was loaded for. Opening another request over this
    // one (a notification tapped while a request is on screen) reuses this screen with a new id:
    // without the key the old request's words and buttons would stay over the new id.
    var approval by remember(approvalId) { mutableStateOf<WatchApproval?>(null) }
    var failed by remember(approvalId) { mutableStateOf(false) }
    var done by remember(approvalId) { mutableStateOf<Pair<String, String?>?>(null) }
    var confirming by remember(approvalId) { mutableStateOf(false) }
    var busy by remember(approvalId) { mutableStateOf(false) }
    var elsewhere by remember(approvalId) { mutableStateOf(false) }
    // Before the details load, show what the glance knows (never a spinner).
    val fromGlance = session.glance.collectAsState().value.glance?.needs?.firstOrNull { it.id == approvalId }

    LaunchedEffect(approvalId) {
        try {
            approval = session.call { approval(approvalId) }
        } catch (e: ApiError.NotFound) {
            if (e.elsewhere) elsewhere = true else done = context.getString(R.string.watch_already_answered) to null
        } catch (_: ApiError) {
            failed = true
        }
    }

    done?.let { (title, sub) ->
        DoneScreen(title, sub) { nav.popBackStack() }
        return
    }
    if (elsewhere) {
        ElsewhereScreen(nav, approval?.link ?: fromGlance?.link ?: "/approvals/$approvalId", approval?.title ?: fromGlance?.text.orEmpty(), otherWorkspace = false)
        return
    }

    fun answer(allow: Boolean) {
        // Only the request that is on screen, loaded: never a tap meant for another one.
        if (busy || approval?.id?.equals(approvalId, ignoreCase = true) != true) return
        busy = true
        scope.launch {
            try {
                session.call { decide(approvalId, allow, idempotencyKey = "w-${if (allow) "allow" else "deny"}-$approvalId") }
                graph.haptics.done()
                val bot = approval?.bot ?: fromGlance?.bot.orEmpty()
                done = context.getString(if (allow) R.string.watch_allowed else R.string.watch_denied) to
                    (if (allow) context.getString(R.string.watch_is_working, bot) else null)
                session.refresh()
            } catch (e: ApiError.Conflict) {
                done = context.getString(R.string.watch_already_answered) to null
            } catch (e: ApiError.NotFound) {
                // `not_found`: not in this watch's workspace. Anything else: it is gone.
                if (e.elsewhere) elsewhere = true else done = context.getString(R.string.watch_already_answered) to null
            } catch (e: ApiError.Forbidden) {
                graph.haptics.problem()
                // The server's limits said no: only the phone can answer it now, for its reason.
                approval = approval?.let { it.copy(canAllow = ai.casama.wear.core.CanAllow.PHONE, whyPhone = Logic.whyPhone(e.detail) ?: it.whyPhone ?: WhyPhone.SETTING) }
            } catch (_: ApiError) {
                graph.haptics.problem()
                failed = true
            } finally {
                busy = false
            }
        }
    }

    val a = approval
    val ui = a?.let { Logic.requestUi(it, System.currentTimeMillis()) }
    if (ui == Logic.RequestUi.ALREADY_ANSWERED) {
        LaunchedEffect(Unit) { done = context.getString(R.string.watch_already_answered) to null }
        return
    }
    if (confirming && a != null) {
        // TalkBack: the hold became a tap; this asks before allowing (§6.7).
        ListScreen(edgeButton = {
            EdgeButton(onClick = { confirming = false; answer(true) }, colors = ButtonDefaults.buttonColors(containerColor = CasamaColors.Needs, contentColor = CasamaColors.OnNeeds)) {
                Text(stringResource(R.string.watch_allow))
            }
        }) { spec ->
            item { Text(stringResource(R.string.watch_hold_hint), textAlign = TextAlign.Center, style = MaterialTheme.typography.titleMedium, modifier = Modifier.fillMaxWidth()) }
            item {
                FilledTonalButton(onClick = { confirming = false }, modifier = Modifier.fillMaxWidth().transformedHeight(this, spec), transformation = SurfaceTransformation(spec)) {
                    Text(stringResource(R.string.watch_not_now))
                }
            }
        }
        return
    }

    val bot = a?.bot ?: fromGlance?.bot.orEmpty()
    val avatar = a?.botAvatar ?: fromGlance?.botAvatar.orEmpty()
    val title = a?.title ?: fromGlance?.text.orEmpty()
    ListScreen(
        edgeButton = when (ui) {
            Logic.RequestUi.ALLOW_TAP -> {
                {
                    EdgeButton(
                        onClick = { answer(true) },
                        enabled = !busy,
                        colors = ButtonDefaults.buttonColors(containerColor = CasamaColors.Needs, contentColor = CasamaColors.OnNeeds),
                    ) {
                        Icon(painterResource(R.drawable.ic_check), contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(6.dp))
                        Text(stringResource(R.string.watch_allow))
                    }
                }
            }
            Logic.RequestUi.PHONE_ONLY -> {
                {
                    EdgeButton(onClick = {
                        scope.launch {
                            val ok = openOnPhone(context, a.link, title.ifBlank { bot })
                            done = context.getString(if (ok) R.string.watch_sent_to_phone else R.string.watch_couldnt_reach) to null
                        }
                    }) {
                        Icon(painterResource(R.drawable.ic_phone), contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(6.dp))
                        Text(stringResource(R.string.watch_review_on_phone), maxLines = 1)
                    }
                }
            }
            else -> null
        },
    ) { spec ->
        item { BotFace(bot, avatar, 30.dp) }
        item {
            Text(
                stringResource(R.string.watch_needs_ok_from, bot),
                style = MaterialTheme.typography.bodySmall,
                color = CasamaColors.Secondary,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )
        }
        item { Words(title, maxLines = 3, style = MaterialTheme.typography.titleMedium, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth()) }
        a?.details?.forEach { d ->
            item { Words(d, maxLines = 2, style = MaterialTheme.typography.bodySmall, color = CasamaColors.Secondary, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth()) }
        }
        if (ui == Logic.RequestUi.PHONE_ONLY) {
            item {
                Text(
                    whyText(a.whyPhone),
                    color = if (a.whyPhone == WhyPhone.HIGH_RISK || a.whyPhone == WhyPhone.PAYMENT) CasamaColors.Stop else CasamaColors.Secondary,
                    style = MaterialTheme.typography.bodySmall,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }
        if (failed) {
            item { Text(stringResource(R.string.watch_couldnt_reach), color = CasamaColors.Stop, style = MaterialTheme.typography.bodySmall, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth()) }
        }
        if (ui == Logic.RequestUi.ALLOW_HOLD) {
            item {
                HoldToAllowButton(
                    onAllow = { answer(true) },
                    onConfirmTap = { confirming = true },
                    onFilled = { graph.haptics.click() },
                    modifier = Modifier.transformedHeight(this, spec),
                )
            }
        }
        if (a != null && a.status == ApprovalStatus.PENDING) {
            item {
                FilledTonalButton(
                    onClick = { answer(false) },
                    enabled = !busy,
                    modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                    transformation = SurfaceTransformation(spec),
                    icon = { Icon(painterResource(R.drawable.ic_close), contentDescription = null, modifier = Modifier.size(18.dp)) },
                    label = { Text(stringResource(R.string.watch_deny)) },
                )
            }
        }
        item { Spacer(Modifier.height(4.dp)) }
    }
}

@Composable
private fun whyText(why: WhyPhone?): String = when (why) {
    WhyPhone.HIGH_RISK, null -> stringResource(R.string.watch_why_high_risk)
    WhyPhone.PAYMENT -> stringResource(R.string.watch_why_payment)
    WhyPhone.SETTING -> stringResource(R.string.watch_why_setting)
    WhyPhone.WORKSPACE -> stringResource(R.string.watch_why_workspace)
    WhyPhone.NOT_YOURS -> stringResource(R.string.watch_why_not_yours)
}

/** A suggestion (§6.1 B): the bot, its idea, Do It or Not now. */
@Composable
fun SuggestionScreen(nav: NavHostController, suggestionId: String) {
    val context = LocalContext.current
    val graph = context.graph
    val session = graph.session
    val scope = rememberCoroutineScope()
    val need = session.glance.collectAsState().value.glance?.needs?.firstOrNull { it.id == suggestionId }
    var done by remember(suggestionId) { mutableStateOf<String?>(null) }
    var failed by remember(suggestionId) { mutableStateOf(false) }
    // A limit was reached (402): nothing started, and the suggestion is still there.
    var outOfCredits by remember(suggestionId) { mutableStateOf(false) }
    var busy by remember(suggestionId) { mutableStateOf(false) }
    var elsewhere by remember(suggestionId) { mutableStateOf(false) }

    done?.let {
        DoneScreen(it, null) { nav.popBackStack() }
        return
    }
    if (elsewhere) {
        // The glance's own link for it, else where suggestions wait on the phone.
        ElsewhereScreen(nav, need?.link ?: Logic.PHONE_NEEDS, need?.text.orEmpty(), otherWorkspace = false)
        return
    }

    fun act(accept: Boolean) {
        if (busy) return
        busy = true
        scope.launch {
            try {
                session.call {
                    if (accept) acceptSuggestion(suggestionId, "w-do-$suggestionId") else dismissSuggestion(suggestionId, "w-later-$suggestionId")
                }
                if (accept) graph.haptics.done()
                done = context.getString(if (accept) R.string.watch_started else R.string.watch_done)
                session.refresh()
            } catch (e: ApiError.Conflict) {
                if (Logic.conflict(e.code) == Logic.ConflictKind.OVER) {
                    done = context.getString(R.string.watch_already_answered)
                } else {
                    // The server couldn't start it (the bot has no model, say) and kept the
                    // suggestion: not "Already answered". The phone shows why.
                    graph.haptics.problem()
                    elsewhere = true
                }
            } catch (e: ApiError.NotFound) {
                if (e.elsewhere) elsewhere = true else done = context.getString(R.string.watch_already_answered)
            } catch (e: ApiError.Refused) {
                graph.haptics.problem()
                outOfCredits = e.status == 402
                failed = !outOfCredits
            } catch (_: ApiError) {
                graph.haptics.problem()
                outOfCredits = false
                failed = true
            } finally {
                busy = false
            }
        }
    }

    ListScreen(edgeButton = {
        EdgeButton(onClick = { act(true) }, enabled = !busy, colors = ButtonDefaults.buttonColors(containerColor = CasamaColors.Orchid, contentColor = CasamaColors.OnOrchid)) {
            Text(stringResource(R.string.watch_do_it))
        }
    }) { spec ->
        if (need != null) {
            item { BotFace(need.bot, need.botAvatar, 30.dp) }
            item { Text(stringResource(R.string.watch_suggests, need.bot), style = MaterialTheme.typography.bodySmall, color = CasamaColors.Secondary, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth()) }
            item { Words(need.text, maxLines = 3, style = MaterialTheme.typography.titleMedium, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth()) }
        }
        if (failed || outOfCredits) {
            item { Text(stringResource(if (outOfCredits) R.string.watch_out_of_credits else R.string.watch_couldnt_reach), color = CasamaColors.Stop, style = MaterialTheme.typography.bodySmall, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth()) }
        }
        item {
            FilledTonalButton(
                onClick = { act(false) },
                enabled = !busy,
                modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                transformation = SurfaceTransformation(spec),
            ) { Text(stringResource(R.string.watch_not_now)) }
        }
    }
}
