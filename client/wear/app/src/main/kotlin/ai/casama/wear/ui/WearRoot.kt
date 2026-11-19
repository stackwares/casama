package ai.casama.wear.ui

import ai.casama.wear.core.Logic
import ai.casama.wear.data.Session
import ai.casama.wear.graph
import ai.casama.wear.ui.screens.AskScreen
import ai.casama.wear.ui.screens.BotsScreen
import ai.casama.wear.ui.screens.BriefScreen
import ai.casama.wear.ui.screens.ChatScreen
import ai.casama.wear.ui.screens.ElsewhereScreen
import ai.casama.wear.ui.screens.GreetingScreen
import ai.casama.wear.ui.screens.NeedsScreen
import ai.casama.wear.ui.screens.NowScreen
import ai.casama.wear.ui.screens.RequestScreen
import ai.casama.wear.ui.screens.SettingsScreen
import ai.casama.wear.ui.screens.SignInScreen
import ai.casama.wear.ui.screens.SuggestionScreen
import ai.casama.wear.ui.screens.TalkScreen
import ai.casama.wear.ui.screens.UpNextScreen
import ai.casama.wear.ui.screens.WorkingScreen
import ai.casama.wear.ui.theme.LocalAmbient
import ai.casama.wear.ui.theme.LocalShowWords
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.navigation.NavHostController
import androidx.wear.compose.material3.AppScaffold
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.flow.StateFlow

/**
 * Signed out: the sign-in screens. Signed in: the app's screens behind swipe-to-close navigation
 * (§6.7). Wrist down, every screen dims and the person's words give way to bars when the setting
 * is on (§6.8).
 */
@Composable
fun WearRoot(activity: MainActivity, ambientFlow: StateFlow<Boolean>) {
    val context = LocalContext.current
    val graph = context.graph
    val session = graph.session
    val auth by session.auth.collectAsState()
    val ambient by ambientFlow.collectAsState()
    val switches by graph.settings.switches.collectAsState()
    val self by session.self.collectAsState()
    val glance by session.glance.collectAsState()
    val showWords = Logic.showWords(
        private = glance.glance?.private == true,
        showDetails = self?.prefs?.showDetails ?: true,
        ambient = ambient,
        hideWhenWristDown = switches.hideWhenWristDown,
    )

    CompositionLocalProvider(LocalAmbient provides ambient, LocalShowWords provides showWords) {
        // The system's clock on top of every screen (AppScaffold's TimeText, as Wear OS 3 to 6
        // expect; Wear Compose 1.8 hands it to the system).
        AppScaffold {
            when (val a = auth) {
                is Session.Auth.SignedOut -> SignInScreen(a)
                is Session.Auth.SignedIn -> {
                    var greet by remember { mutableStateOf(graph.settings.greetPending) }
                    if (greet) {
                        GreetingScreen(a.person) {
                            session.greeted()
                            greet = false
                            activity.askForNotifications()
                        }
                    } else {
                        AppNav(activity)
                    }
                }
            }
        }
    }
}

@Composable
private fun AppNav(activity: MainActivity) {
    val nav = rememberSwipeDismissableNavController()
    val pending by activity.pendingRoute.collectAsState()
    // "Read aloud" from a notification: taken once by the screen it opens.
    val readAloud = remember { AtomicBoolean(false) }
    LaunchedEffect(pending) {
        val (route, aloud) = pending ?: return@LaunchedEffect
        activity.pendingRoute.value = null
        readAloud.set(aloud)
        if (route != Routes.NOW) nav.go(route)
    }

    SwipeDismissableNavHost(navController = nav, startDestination = Routes.NOW) {
        composable(Routes.NOW) { NowScreen(nav) }
        composable(Routes.NEEDS) { NeedsScreen(nav) }
        composable(Routes.REQUEST) { e -> RequestScreen(nav, Routes.arg(e.arguments?.getString("id")).orEmpty()) }
        composable(Routes.SUGGESTION) { e -> SuggestionScreen(nav, Routes.arg(e.arguments?.getString("id")).orEmpty()) }
        composable(Routes.ASK) { e ->
            AskScreen(nav, Routes.arg(e.arguments?.getString("bot")), listen = e.arguments?.getString("listen") == "1", conversationId = Routes.arg(e.arguments?.getString("conv")))
        }
        composable(Routes.WORKING) { e -> WorkingScreen(nav, Routes.arg(e.arguments?.getString("run")).orEmpty()) }
        composable(Routes.CHAT) { e ->
            val aloud = remember { readAloud.getAndSet(false) }
            ChatScreen(nav, Routes.arg(e.arguments?.getString("bot")).orEmpty(), Routes.arg(e.arguments?.getString("conv")), readAloud = aloud)
        }
        composable(Routes.BOTS) { BotsScreen(nav) }
        composable(Routes.UP_NEXT) { UpNextScreen(nav) }
        composable(Routes.BRIEF) {
            val aloud = remember { readAloud.getAndSet(false) }
            BriefScreen(readAloud = aloud)
        }
        composable(Routes.TALK) { e -> TalkScreen(nav, Routes.arg(e.arguments?.getString("bot"))) }
        composable(Routes.SETTINGS) { SettingsScreen(nav) }
        composable(Routes.ELSEWHERE) { e ->
            ElsewhereScreen(
                nav,
                Routes.text(e.arguments?.getString("link")) ?: "/",
                Routes.text(e.arguments?.getString("title")).orEmpty(),
                otherWorkspace = e.arguments?.getString("other") == "1",
            )
        }
    }
}

/** Opens [route] on top of Now, never stacking the same screen twice. */
fun NavHostController.go(route: String) {
    navigate(route) { launchSingleTop = true }
}

/** Replaces the current screen (the request after the Working screen, the reply after asking). */
fun NavHostController.replace(route: String) {
    val current = currentDestination?.route
    navigate(route) {
        if (current != null) popUpTo(current) { inclusive = true }
        launchSingleTop = true
    }
}
