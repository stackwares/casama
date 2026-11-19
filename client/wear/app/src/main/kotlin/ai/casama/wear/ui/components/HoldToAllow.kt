package ai.casama.wear.ui.components

import ai.casama.wear.R
import ai.casama.wear.ui.theme.CasamaColors
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.Text
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Hold to allow (§6.1 B, medium risk): the button fills over about 0.8 s while held, clicks on the
 * wrist when full, and only then allows. Letting go early empties it. With TalkBack the hold
 * becomes a tap that asks first ([onConfirmTap]), since a hold can't be done by double tap.
 */
@Composable
fun HoldToAllowButton(
    onAllow: () -> Unit,
    onConfirmTap: () -> Unit,
    onFilled: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val progress = remember { Animatable(0f) }
    val scope = rememberCoroutineScope()
    val talkBack = touchExploration()
    val label = stringResource(R.string.watch_hold_to_allow)
    val hint = stringResource(R.string.watch_hold_hint)
    Box(
        modifier
            .fillMaxWidth()
            .heightIn(min = 52.dp)
            .clip(RoundedCornerShape(26.dp))
            .background(CasamaColors.NeedsContainer)
            .semantics(mergeDescendants = true) {
                role = Role.Button
                contentDescription = "$label. $hint"
                onClick(label) {
                    onConfirmTap()
                    true
                }
            }
            .pointerInput(talkBack) {
                detectTapGestures(
                    onTap = { if (talkBack) onConfirmTap() },
                    onPress = {
                        if (talkBack) return@detectTapGestures
                        var filled = false
                        val fill = scope.launch {
                            // The fill is for looks. The hold itself is timed in real time: with
                            // "Remove animations" on the fill jumps to full at once, and a touch
                            // must still not allow.
                            launch { progress.animateTo(1f, tween(durationMillis = HOLD_MS, easing = LinearEasing)) }
                            delay(HOLD_MS.toLong())
                            progress.snapTo(1f)
                            // Held the whole time: allow now, with the click on the wrist.
                            filled = true
                            onFilled()
                            onAllow()
                        }
                        tryAwaitRelease()
                        if (!filled) {
                            fill.cancel()
                            scope.launch { progress.animateTo(0f, tween(150)) }
                        }
                    },
                )
            },
        contentAlignment = Alignment.CenterStart,
    ) {
        Box(
            Modifier
                .fillMaxHeight()
                .fillMaxWidth(progress.value.coerceIn(0f, 1f))
                .background(CasamaColors.Needs),
        )
        Row(Modifier.fillMaxWidth(), horizontalArrangement = androidx.compose.foundation.layout.Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
            val onFill = progress.value > 0.5f
            Icon(painterResource(R.drawable.ic_check), contentDescription = null, modifier = Modifier.size(18.dp), tint = if (onFill) CasamaColors.OnNeeds else CasamaColors.OnNeedsContainer)
            Spacer(Modifier.width(6.dp))
            Text(label, fontWeight = FontWeight.SemiBold, color = if (onFill) CasamaColors.OnNeeds else CasamaColors.OnNeedsContainer)
        }
    }
}

private const val HOLD_MS = 800
