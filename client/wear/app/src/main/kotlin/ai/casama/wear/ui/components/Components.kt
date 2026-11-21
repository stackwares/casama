package ai.casama.wear.ui.components

import ai.casama.wear.R
import ai.casama.wear.art.BotArt
import ai.casama.wear.ui.theme.CasamaColors
import ai.casama.wear.ui.theme.LocalAmbient
import ai.casama.wear.ui.theme.LocalShowWords
import android.provider.Settings
import android.text.format.DateFormat
import android.view.accessibility.AccessibilityManager
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text
import java.util.Date
import java.text.SimpleDateFormat
import java.time.ZoneId
import ai.casama.wear.core.Format
import androidx.compose.ui.platform.LocalConfiguration
import kotlinx.coroutines.delay

/** A bot's face: its mascot, or its initials tile drawn as bot_avatar.dart draws it (§6.9). */
@Composable
fun BotFace(name: String, avatar: String?, size: Dp, modifier: Modifier = Modifier) {
    val res = BotArt.mascotRes(avatar)
    val ambient = LocalAmbient.current
    if (res != null) {
        Image(
            painter = painterResource(res),
            contentDescription = null,
            modifier = modifier.size(size).alpha(if (ambient) 0.6f else 1f),
        )
    } else {
        val (top, bottom) = BotArt.palette(name)
        val fill = if (ambient) Brush.linearGradient(listOf(Color.Black, Color.Black))
        else Brush.linearGradient(listOf(Color(top), Color(bottom)))
        Box(
            modifier = modifier
                .size(size)
                .clip(RoundedCornerShape(size * 0.32f))
                .background(fill),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                BotArt.initials(name),
                color = Color.White,
                fontWeight = FontWeight.Bold,
                fontSize = with(LocalDensity.current) { (size * if (name.trim().contains(' ')) 0.36f else 0.44f).toSp() },
                maxLines = 1,
            )
        }
    }
}

/**
 * The person's words, or grey bars in their place when they may not show (wrist down with the
 * setting on, the app lock, details off on the phone). TalkBack reads nothing for bars.
 */
@Composable
fun Words(
    text: String,
    modifier: Modifier = Modifier,
    color: Color = Color.Unspecified,
    maxLines: Int = 2,
    style: androidx.compose.ui.text.TextStyle = MaterialTheme.typography.bodyMedium,
    textAlign: TextAlign? = null,
) {
    if (LocalShowWords.current || text.isEmpty()) {
        Text(text, modifier = modifier, color = color, maxLines = maxLines, style = style, textAlign = textAlign, overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis)
    } else {
        Bars(modifier.clearAndSetSemantics { })
    }
}

@Composable
fun Bars(modifier: Modifier = Modifier) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(5.dp)) {
        Box(Modifier.width(86.dp).height(8.dp).clip(CircleShape).background(CasamaColors.Dim))
        Box(Modifier.width(54.dp).height(8.dp).clip(CircleShape).background(CasamaColors.Dim))
    }
}

/** "No connection · as of 9:12" (§6.8). Shown whenever what's on screen may be old. */
@Composable
fun AsOf(savedAt: Long?, offline: Boolean, modifier: Modifier = Modifier) {
    if (!offline || savedAt == null) return
    val time = clockTime(savedAt)
    Row(modifier.padding(horizontal = 6.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Center) {
        Icon(painterResource(R.drawable.ic_offline), contentDescription = stringResource(R.string.watch_offline), modifier = Modifier.size(13.dp), tint = CasamaColors.Secondary)
        Spacer(Modifier.width(5.dp))
        Text(stringResource(R.string.watch_as_of, time), color = CasamaColors.Secondary, style = MaterialTheme.typography.labelSmall, maxLines = 1)
    }
}

/** A clock time in the person's 12/24-hour setting ("9:12", "21:12"). */
@Composable
fun clockTime(at: Long): String {
    val context = LocalContext.current
    return remember(at) { DateFormat.getTimeFormat(context).format(Date(at)) }
}

/**
 * A time that has passed: the clock time today, the weekday within the last week ("Tue"), else
 * the date ("Nov 12"). A bare "8:36" for something days old reads as this morning.
 */
@Composable
fun pastTime(at: Long): String {
    val days = Format.dayOffset(System.currentTimeMillis(), at, ZoneId.systemDefault())
    if (days >= 0) return clockTime(at)
    val locale = LocalConfiguration.current.locales[0]
    return remember(at, days, locale) {
        val skeleton = if (days >= -6) "EEE" else "MMMd"
        SimpleDateFormat(DateFormat.getBestDateTimePattern(locale, skeleton), locale).format(Date(at))
    }
}

/** A clock that runs from [start] ("2:14"), ticking each second; still when [running] is false. */
@Composable
fun runningClock(start: Long?, end: Long? = null, running: Boolean = true): String {
    val now by produceState(System.currentTimeMillis(), start, running) {
        while (running) {
            value = System.currentTimeMillis()
            delay(1000 - (value % 1000))
        }
    }
    if (start == null) return ""
    return ai.casama.wear.core.Format.elapsed((end ?: now) - start)
}

/** Whether TalkBack is exploring by touch: holds become a tap and a confirmation (§6.7). */
@Composable
fun touchExploration(): Boolean {
    val context = LocalContext.current
    return remember { context.getSystemService(AccessibilityManager::class.java)?.isTouchExplorationEnabled == true }
}

/** Reduce motion: animations off when the person set the animator scale to zero. */
@Composable
fun reduceMotion(): Boolean {
    val context = LocalContext.current
    return remember {
        Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
    }
}

/** Large text: show fewer rows rather than shrink or cut them (§6.8). */
@Composable
fun largeText(): Boolean = LocalDensity.current.fontScale >= 1.3f

/**
 * The end of an action (§6.1 B): a full-screen tick, a tap on the wrist, and it closes itself
 * after a second.
 */
@Composable
fun DoneScreen(title: String, subtitle: String?, good: Boolean = true, onDone: () -> Unit) {
    LaunchedEffect(Unit) {
        delay(1_200)
        onDone()
    }
    Column(
        Modifier.fillMaxSize().padding(horizontal = 24.dp).semantics(mergeDescendants = true) { contentDescription = listOfNotNull(title, subtitle).joinToString(". ") },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Box(
            Modifier.size(58.dp).clip(CircleShape).background(if (good) CasamaColors.WorkingContainer else CasamaColors.StopContainer),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                painterResource(if (good) R.drawable.ic_check else R.drawable.ic_close),
                contentDescription = null,
                tint = if (good) CasamaColors.Working else CasamaColors.OnStopContainer,
                modifier = Modifier.size(30.dp),
            )
        }
        Spacer(Modifier.height(8.dp))
        Text(title, style = MaterialTheme.typography.titleMedium, textAlign = TextAlign.Center)
        subtitle?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = CasamaColors.Secondary, textAlign = TextAlign.Center, maxLines = 2) }
    }
}

/** A centred message with an optional face, for empty and signed-out states. */
@Composable
fun Message(title: String, body: String?, faceRes: Int? = null, modifier: Modifier = Modifier) {
    Column(
        modifier.fillMaxWidth().padding(horizontal = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        faceRes?.let {
            Image(painterResource(it), contentDescription = null, modifier = Modifier.size(58.dp).alpha(if (LocalAmbient.current) 0.6f else 1f))
            Spacer(Modifier.height(4.dp))
        }
        Text(title, style = MaterialTheme.typography.titleMedium, textAlign = TextAlign.Center)
        body?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = CasamaColors.Secondary, textAlign = TextAlign.Center) }
    }
}

/** A small caps label above a card ("NEEDS YOU · 2"). */
@Composable
fun Eyebrow(text: String, color: Color, modifier: Modifier = Modifier) {
    Text(
        text.uppercase(),
        modifier = modifier,
        color = if (LocalAmbient.current) CasamaColors.Secondary else color,
        fontSize = 11.sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = 0.4.sp,
        maxLines = 1,
    )
}

/** A mutable flag remembered across recompositions; shorthand used by the screens. */
@Composable
fun rememberFlag(initial: Boolean = false) = remember { mutableStateOf(initial) }
