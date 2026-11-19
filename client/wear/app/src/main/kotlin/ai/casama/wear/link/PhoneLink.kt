package ai.casama.wear.link

import ai.casama.wear.core.LinkMessage
import ai.casama.wear.graph
import android.content.Context
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Node
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withTimeoutOrNull

/**
 * The phone link (WATCH-PROTOCOL §2): Data Layer messages on `/casama/watch` to the phone that has
 * Casama (capability `casama_phone`). It carries only the sign-in request (a fingerprint, never the
 * key), the phone's answer, and "open this on the phone".
 */
object PhoneLink {
    /** The phones with Casama installed, nearest first; empty when none is paired or reachable. */
    private suspend fun phones(context: Context): List<Node> {
        val info = withTimeoutOrNull(5_000) {
            runCatching {
                Wearable.getCapabilityClient(context)
                    .getCapability(LinkMessage.PHONE_CAPABILITY, CapabilityClient.FILTER_REACHABLE)
                    .await()
            }.getOrNull()
        } ?: return emptyList()
        return info.nodes.sortedByDescending { it.isNearby }
    }

    private suspend fun send(context: Context, message: LinkMessage): Boolean {
        val bytes = message.encode().toByteArray(Charsets.UTF_8)
        val client = Wearable.getMessageClient(context)
        var sent = false
        for (node in phones(context)) {
            val ok = withTimeoutOrNull(5_000) {
                runCatching { client.sendMessage(node.id, LinkMessage.PATH, bytes).await() }.isSuccess
            } ?: false
            sent = sent || ok
            if (ok && message is LinkMessage.Open) break // one phone opens it
        }
        return sent
    }

    /** Asks the phone to sign this watch in. False when no phone with Casama is in reach. */
    suspend fun requestSignIn(context: Context, message: LinkMessage.SignIn): Boolean = send(context, message)

    /**
     * Open on phone: the phone opens [link], or leaves a notification named [title] that does when
     * its app isn't in front. False when no phone took the message.
     */
    suspend fun openOnPhone(context: Context, link: String, title: String? = null): Boolean =
        // Always a route the phone has: a bare "/" would open nothing there (Logic.phoneRoute).
        send(context, LinkMessage.Open(ai.casama.wear.core.Logic.phoneRoute(link), title))
}

/**
 * Receives the phone's messages even when the app isn't running: the sign-in answer, a workspace
 * switch, sign out. Runs on a background thread; the session does the rest in its own scope.
 */
class PhoneLinkService : WearableListenerService() {
    override fun onMessageReceived(event: MessageEvent) {
        if (event.path != LinkMessage.PATH) return
        val message = LinkMessage.decode(event.data) ?: return
        val graph = applicationContext.graph
        graph.scope.launch { graph.session.onPhoneMessage(message) }
    }
}
