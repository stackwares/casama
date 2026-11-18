package ai.casama.wear.ui

import ai.casama.wear.data.AskOutbox
import ai.casama.wear.graph
import ai.casama.wear.notify.PushSetup
import ai.casama.wear.ui.theme.CasamaTheme
import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import androidx.wear.ambient.AmbientLifecycleObserver
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch

/** The one activity: Compose for Wear OS, Material 3 Expressive (§8.8). */
class MainActivity : ComponentActivity() {
    /** Wrist down: the app stays on screen dimmed (targetSdk 36, Wear OS 6+). */
    private val ambient = MutableStateFlow(false)

    /** A route asked for by a notification, tile or complication: (route, read aloud). */
    val pendingRoute = MutableStateFlow<Pair<String, Boolean>?>(null)

    private val notificationPermission = registerForActivityResult(ActivityResultContracts.RequestPermission()) { }

    private val ambientCallback = object : AmbientLifecycleObserver.AmbientLifecycleCallback {
        override fun onEnterAmbient(ambientDetails: AmbientLifecycleObserver.AmbientDetails) {
            ambient.value = true
        }

        override fun onExitAmbient() {
            ambient.value = false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        lifecycle.addObserver(AmbientLifecycleObserver(this, ambientCallback))
        takeRoute(intent)
        setContent {
            CasamaTheme {
                WearRoot(activity = this, ambientFlow = ambient)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        takeRoute(intent)
    }

    override fun onResume() {
        super.onResume()
        val graph = graph
        val session = graph.session
        if (session.isSignedIn) {
            lifecycleScope.launch {
                session.refresh()
                session.refreshSelf()
                PushSetup.ensureRegistered(applicationContext)
                if (graph.outbox.items().isNotEmpty()) AskOutbox.schedule(applicationContext)
            }
            askForNotifications()
        } else {
            session.startSignIn()
        }
    }

    /** Wear OS 4+ asks before notifications; only once signed in, when they mean something. */
    fun askForNotifications() {
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            notificationPermission.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    private fun takeRoute(intent: Intent?) {
        val route = intent?.getStringExtra(Routes.EXTRA_ROUTE) ?: return
        pendingRoute.value = route to intent.getBooleanExtra(Routes.EXTRA_READ_ALOUD, false)
        intent.removeExtra(Routes.EXTRA_ROUTE)
    }
}
