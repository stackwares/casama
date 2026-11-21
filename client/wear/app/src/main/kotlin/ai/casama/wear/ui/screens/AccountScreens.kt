package ai.casama.wear.ui.screens

import ai.casama.wear.R
import ai.casama.wear.art.BotArt
import ai.casama.wear.core.Format
import ai.casama.wear.data.Session
import ai.casama.wear.graph
import ai.casama.wear.ui.components.DoneScreen
import ai.casama.wear.ui.components.Message
import ai.casama.wear.ui.theme.CasamaColors
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavHostController
import androidx.wear.compose.material3.Card
import androidx.wear.compose.material3.EdgeButton
import androidx.wear.compose.material3.FilledTonalButton
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.SurfaceTransformation
import androidx.wear.compose.material3.SwitchButton
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.lazy.transformedHeight
import kotlinx.coroutines.launch

/**
 * Settings (§6.1 J): who and where, which bot Ask uses, the two watch switches, Sign out. All other
 * settings live on the phone.
 */
@Composable
fun SettingsScreen(nav: NavHostController) {
    val context = LocalContext.current
    val graph = context.graph
    val session = graph.session
    val scope = rememberCoroutineScope()
    val self by session.self.collectAsState()
    val auth by session.auth.collectAsState()
    val switches by graph.settings.switches.collectAsState()
    val glance by session.glance.collectAsState()
    val signedIn = auth as? Session.Auth.SignedIn
    val askBot = ai.casama.wear.core.Logic.askBot(glance.glance, graph.settings.lastAskBotId, self?.askBotId)
    var signingOut by remember { mutableStateOf(false) }

    ListScreen { spec ->
        item { Text(stringResource(R.string.watch_settings), style = MaterialTheme.typography.titleSmall) }
        item {
            Info(stringResource(R.string.watch_signed_in_as_label), signedIn?.person ?: self?.personName.orEmpty(), spec)
        }
        item { Info(stringResource(R.string.watch_workspace), signedIn?.org ?: self?.orgName.orEmpty(), spec) }
        askBot?.let { b -> item { Info(stringResource(R.string.watch_ask_uses), b.name, spec) } }
        item {
            SwitchButton(
                checked = switches.hideWhenWristDown,
                onCheckedChange = { graph.settings.setHideWhenWristDown(it) },
                label = { Text(stringResource(R.string.watch_hide_details), maxLines = 3) },
                modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                transformation = SurfaceTransformation(spec),
            )
        }
        item {
            SwitchButton(
                checked = switches.readRepliesAloud,
                onCheckedChange = { graph.settings.setReadRepliesAloud(it) },
                label = { Text(stringResource(R.string.watch_read_replies_aloud), maxLines = 3) },
                modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                transformation = SurfaceTransformation(spec),
            )
        }
        glance.glance?.credits?.let { c ->
            if (c.billing && !c.unlimited) {
                Format.percent(c.usedShare)?.let { p ->
                    item { Info(stringResource(R.string.watch_credits), "$p%", spec) }
                }
            }
        }
        item {
            FilledTonalButton(
                onClick = {
                    if (signingOut) return@FilledTonalButton
                    signingOut = true
                    scope.launch { session.signOut() }
                },
                colors = androidx.wear.compose.material3.ButtonDefaults.filledTonalButtonColors(
                    containerColor = CasamaColors.StopContainer,
                    contentColor = CasamaColors.OnStopContainer,
                ),
                modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                transformation = SurfaceTransformation(spec),
            ) {
                Text(stringResource(R.string.watch_sign_out), maxLines = 1)
            }
        }
    }
}

@Composable
private fun androidx.wear.compose.foundation.lazy.TransformingLazyColumnItemScope.Info(
    label: String,
    value: String,
    spec: androidx.wear.compose.material3.lazy.TransformationSpec,
) {
    Card(
        onClick = {},
        enabled = false,
        modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
        transformation = SurfaceTransformation(spec),
    ) {
        Text(label, style = MaterialTheme.typography.labelSmall, color = CasamaColors.Secondary)
        Text(value, style = MaterialTheme.typography.bodyMedium, maxLines = 2)
    }
}

/**
 * Signed out (§6.8, §8.2): the watch asks the phone, which signs it in with one tap there. With no
 * phone in reach, or on request, a code to type at casama.ai on any device. Never a password.
 */
@Composable
fun SignInScreen(auth: Session.Auth.SignedOut) {
    val context = LocalContext.current
    val session = context.graph.session
    // Only a watch that was never signed in asks the phone by itself; after a sign-out it waits
    // for the Sign in button below (Session.autoSignIn).
    LaunchedEffect(Unit) { if (auth.step == null) session.autoSignIn() }
    val manual = auth.step == null && auth.reason != Session.OutReason.FIRST_RUN

    val reasonLine = when (auth.reason) {
        Session.OutReason.REMOVED, Session.OutReason.FROM_PHONE, Session.OutReason.BY_PERSON -> stringResource(R.string.watch_signed_out)
        Session.OutReason.FIRST_RUN -> null
    }

    ListScreen(
        edgeButton = when (auth.step) {
            Session.SignIn.CodeExpired, Session.SignIn.CodeFailed -> {
                { EdgeButton(onClick = { session.startCode() }) { Text(stringResource(R.string.watch_new_code)) } }
            }
            else -> null
        },
    ) { spec ->
        item {
            Image(
                painterResource(BotArt.sleepy),
                contentDescription = null,
                modifier = Modifier.size(36.dp),
            )
        }
        reasonLine?.let { r -> item { Text(r, style = MaterialTheme.typography.bodySmall, color = CasamaColors.Secondary, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth()) } }
        when (val step = auth.step) {
            null -> if (manual) {
                item {
                    FilledTonalButton(onClick = { session.startSignIn() }, modifier = Modifier.fillMaxWidth().transformedHeight(this, spec), transformation = SurfaceTransformation(spec)) {
                        Text(stringResource(R.string.watch_sign_in))
                    }
                }
            } else {
                item { Message(stringResource(R.string.watch_signing_in), null) }
            }
            Session.SignIn.AskingPhone -> item { Message(stringResource(R.string.watch_signing_in), null) }
            Session.SignIn.ServerRefused -> {
                item { Message(stringResource(R.string.watch_needs_https), null) }
                item {
                    FilledTonalButton(onClick = { session.startSignIn() }, modifier = Modifier.fillMaxWidth().transformedHeight(this, spec), transformation = SurfaceTransformation(spec)) {
                        Text(stringResource(R.string.watch_try_again))
                    }
                }
            }
            Session.SignIn.WaitingForPhone -> {
                item { Message(stringResource(R.string.watch_open_phone_to_finish), null) }
                // The phone holds a request for a while only; this asks it again.
                item {
                    FilledTonalButton(onClick = { session.startSignIn() }, modifier = Modifier.fillMaxWidth().transformedHeight(this, spec), transformation = SurfaceTransformation(spec)) {
                        Text(stringResource(R.string.watch_try_again))
                    }
                }
            }
            Session.SignIn.GettingCode -> item { Message(stringResource(R.string.watch_use_code), null) }
            is Session.SignIn.Code -> {
                val shown = Format.code(step.code.code)
                item {
                    val codeLabel = stringResource(R.string.watch_code_a11y, step.code.code.toCharArray().joinToString(" "))
                    Text(
                        shown,
                        fontFamily = FontFamily.Monospace,
                        fontSize = 24.sp,
                        textAlign = TextAlign.Center,
                        color = CasamaColors.Orchid,
                        modifier = Modifier
                            .fillMaxWidth()
                            // Read letter by letter by TalkBack.
                            .semantics { contentDescription = codeLabel },
                    )
                }
                item { Text(stringResource(R.string.watch_code_help), style = MaterialTheme.typography.bodySmall, color = CasamaColors.Secondary, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth()) }
                item { Text(stringResource(R.string.watch_code_waiting), style = MaterialTheme.typography.bodySmall, color = CasamaColors.Secondary, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth()) }
                item {
                    FilledTonalButton(onClick = { session.startCode() }, modifier = Modifier.fillMaxWidth().transformedHeight(this, spec), transformation = SurfaceTransformation(spec)) {
                        Text(stringResource(R.string.watch_new_code))
                    }
                }
            }
            Session.SignIn.CodeExpired -> item { Message(stringResource(R.string.watch_code_help), null) }
            Session.SignIn.CodeFailed -> item { Message(stringResource(R.string.watch_couldnt_reach), stringResource(R.string.watch_try_again)) }
        }
        when (auth.step) {
            is Session.SignIn.Code, Session.SignIn.GettingCode, Session.SignIn.CodeExpired, Session.SignIn.CodeFailed -> Unit
            else -> item {
                FilledTonalButton(
                    onClick = { session.startCode() },
                    colors = androidx.wear.compose.material3.ButtonDefaults.filledTonalButtonColors(
                        containerColor = CasamaColors.Orchid,
                        contentColor = CasamaColors.OnOrchid,
                    ),
                    modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                    transformation = SurfaceTransformation(spec),
                ) {
                    Text(stringResource(R.string.watch_use_code), maxLines = 1)
                }
            }
        }
    }
}

/** "Signed in as Oliver", for a moment (DoneScreen closes itself), then Now. */
@Composable
fun GreetingScreen(person: String, onDone: () -> Unit) {
    DoneScreen(stringResource(R.string.watch_signed_in_as, person), null, onDone = onDone)
}
