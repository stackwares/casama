package ai.casama.wear.ui.screens

import ai.casama.wear.ui.theme.LocalAmbient
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.calculateEndPadding
import androidx.compose.foundation.layout.calculateStartPadding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.lazy.TransformingLazyColumn
import androidx.wear.compose.foundation.lazy.TransformingLazyColumnScope
import androidx.wear.compose.foundation.lazy.rememberTransformingLazyColumnState
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.ScreenScaffoldDefaults
import androidx.wear.compose.material3.lazy.TransformationSpec
import androidx.wear.compose.material3.lazy.rememberTransformationSpec

/**
 * Every list screen: a TransformingLazyColumn whose rows shrink toward the round edge, scrolled by
 * the crown or bezel with no extra code, with the scroll indicator and an optional EdgeButton that
 * hugs the bottom (§2.2). Wrist down, the edge button goes: nothing to tap in ambient.
 */
@Composable
fun ListScreen(
    edgeButton: (@Composable BoxScope.() -> Unit)? = null,
    content: TransformingLazyColumnScope.(TransformationSpec) -> Unit,
) {
    val state = rememberTransformingLazyColumnState()
    val spec = rememberTransformationSpec()
    val ambient = LocalAmbient.current
    val button = edgeButton?.takeIf { !ambient }
    val dir = LocalLayoutDirection.current
    val base = ScreenScaffoldDefaults.contentPadding
    val scaffoldPadding = PaddingValues(
        start = base.calculateStartPadding(dir),
        top = maxOf(base.calculateTopPadding(), 32.dp),
        end = base.calculateEndPadding(dir),
        bottom = maxOf(base.calculateBottomPadding(), 32.dp),
    )
    if (button != null) {
        ScreenScaffold(
            scrollState = state,
            contentPadding = scaffoldPadding,
            edgeButton = button,
            edgeButtonSpacing = 8.dp,
        ) { padding ->
            Column(state, padding, spec, content)
        }
    } else {
        ScreenScaffold(
            scrollState = state,
            contentPadding = scaffoldPadding,
        ) { padding ->
            Column(state, padding, spec, content)
        }
    }
}

@Composable
private fun Column(
    state: androidx.wear.compose.foundation.lazy.TransformingLazyColumnState,
    padding: PaddingValues,
    spec: TransformationSpec,
    content: TransformingLazyColumnScope.(TransformationSpec) -> Unit,
) {
    TransformingLazyColumn(state = state, contentPadding = padding, modifier = Modifier) {
        content(spec)
    }
}
