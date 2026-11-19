package ai.casama.wear.ui.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.wear.compose.material3.ColorScheme
import androidx.wear.compose.material3.MaterialTheme

/**
 * The look (§6.9, WATCH-PROTOCOL §6): black, dark grey cards, and colour only where it means
 * something: amber needs you, green working, orchid the one main button, red Stop and high risk.
 * The system may recolour other buttons to match the watch face; these stay as they are.
 */
object CasamaColors {
    val Needs = Color(0xFFF0A84A)
    val NeedsContainer = Color(0xFF4A3413)
    val OnNeedsContainer = Color(0xFFFFE2B0)
    val OnNeeds = Color(0xFF2B1A00)
    val Working = Color(0xFF5FD49A)
    val WorkingContainer = Color(0xFF17382A)
    val OnWorkingContainer = Color(0xFFB5E6CD)
    val Orchid = Color(0xFFF2B0EC)
    val OnOrchid = Color(0xFF3B0A3D)
    val Tone = Color(0xFF6B1F69)
    val OnTone = Color(0xFFFADDF5)
    val Stop = Color(0xFFFF6B6B)
    val StopContainer = Color(0xFF5C1F1A)
    val OnStopContainer = Color(0xFFFFB4A9)
    val Secondary = Color(0xFF9A9AA0)
    val Card = Color(0xFF1C1C1E)
    val Dim = Color(0xFF5A5A60)
}

/** Wrist down (ambient): dimmed, words hidden when the person asked for that (§6.8). */
val LocalAmbient = staticCompositionLocalOf { false }

/** Whether the person's words may show on this screen now (Logic.showWords). */
val LocalShowWords = staticCompositionLocalOf { true }

@Composable
fun CasamaTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = ColorScheme(
            primary = CasamaColors.Orchid,
            onPrimary = CasamaColors.OnOrchid,
            primaryContainer = CasamaColors.Tone,
            onPrimaryContainer = CasamaColors.OnTone,
            secondaryContainer = CasamaColors.Tone,
            onSecondaryContainer = CasamaColors.OnTone,
            surfaceContainerLow = Color(0xFF141416),
            surfaceContainer = CasamaColors.Card,
            surfaceContainerHigh = Color(0xFF2A2A2E),
            onSurface = Color.White,
            onSurfaceVariant = CasamaColors.Secondary,
            background = Color.Black,
            onBackground = Color.White,
            error = CasamaColors.Stop,
            errorContainer = CasamaColors.StopContainer,
            onErrorContainer = CasamaColors.OnStopContainer,
        ),
        content = content,
    )
}
