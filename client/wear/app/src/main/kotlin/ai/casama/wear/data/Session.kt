package ai.casama.wear.data

import ai.casama.wear.BuildConfig
import ai.casama.wear.core.Decode
import ai.casama.wear.core.Glance
import ai.casama.wear.core.LinkMessage
import ai.casama.wear.core.SignInRequests
import ai.casama.wear.core.WatchCode
import ai.casama.wear.core.WatchKey
import ai.casama.wear.core.WatchSelf
import ai.casama.wear.link.PhoneLink
import ai.casama.wear.live.OngoingRun
import ai.casama.wear.notify.Notifier
import ai.casama.wear.notify.PushSetup
import ai.casama.wear.surfaces.Surfaces
import android.content.Context
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withTimeoutOrNull

/**
 * Who the watch is signed in as, the glance every screen reads, and signing in and out
 * (docs/WATCH-PLAN.md §8.2). Screens, tiles, complications and notifications all go through here,
 * so a 401 anywhere wipes everything at once (WATCH-PROTOCOL §1).
 */
class Session(
    private val context: Context,
    private val scope: CoroutineScope,
    val settings: Settings,
    private val keys: KeyStore,
    val cache: GlanceCache,
    val api: WatchApi,
) {
    enum class OutReason { FIRST_RUN, FROM_PHONE, REMOVED, BY_PERSON }

    /** Where signing in stands (§6.8). */
    sealed class SignIn {
        /** Asked the phone; "Signing you in". */
        data object AskingPhone : SignIn()
        /** The phone app hasn't answered: "Open Casama on your phone to finish", and the code. */
        data object WaitingForPhone : SignIn()
        /** Getting a code from the server. */
        data object GettingCode : SignIn()
        data class Code(val code: WatchCode) : SignIn()
        data object CodeExpired : SignIn()
        /** The code couldn't be fetched (offline, rate limited). */
        data object CodeFailed : SignIn()
        /** The phone signed the watch in to a server address this watch won't call (not https). */
        data object ServerRefused : SignIn()
    }

    sealed class Auth {
        data class SignedOut(val reason: OutReason, val step: SignIn?) : Auth()
        data class SignedIn(val person: String, val org: String) : Auth()
    }

    data class GlanceState(
        val glance: Glance?,
        val savedAt: Long?,
        /** The last refresh failed for want of a connection: show "as of". */
        val offline: Boolean,
        val loading: Boolean,
        /** The server has no watch routes (§6.8 "Server too old"). */
        val serverTooOld: Boolean,
    )

    private val _auth = MutableStateFlow(initialAuth())
    val auth: StateFlow<Auth> = _auth.asStateFlow()

    private val _glance = MutableStateFlow(cache.glance().let { GlanceState(it?.glance, it?.savedAt, false, false, false) })
    val glance: StateFlow<GlanceState> = _glance.asStateFlow()

    private val _self = MutableStateFlow(settings.selfJson?.let { runCatching { Decode.self(it) }.getOrNull() })
    val self: StateFlow<WatchSelf?> = _self.asStateFlow()

    private val refreshLock = Mutex()
    private var signInJob: Job? = null

    val isSignedIn: Boolean get() = _auth.value is Auth.SignedIn

    private fun initialAuth(): Auth =
        if (settings.signedIn && keys.exists() && settings.server != null) {
            Auth.SignedIn(settings.personName.orEmpty(), settings.orgName.orEmpty())
        } else {
            val reason = settings.signedOutReason?.let { r -> OutReason.entries.firstOrNull { it.name == r } } ?: OutReason.FIRST_RUN
            Auth.SignedOut(reason, null)
        }

    // --- the glance -------------------------------------------------------------------------------

    /** Fetches the glance (304 most of the time) and tells tiles and complications when it changed. */
    suspend fun refresh() {
        if (!isSignedIn) return
        refreshLock.withLock {
            _glance.update { it.copy(loading = true) }
            val before = cache.glance()?.glance?.version
            try {
                when (val r = api.glance(cache.glance()?.etag)) {
                    WatchApi.GlanceResult.NotModified -> cache.touch(System.currentTimeMillis())
                    is WatchApi.GlanceResult.Fresh -> cache.saveGlance(r.raw, r.glance, r.etag, System.currentTimeMillis())
                }
                val saved = cache.glance()
                _glance.value = GlanceState(saved?.glance, saved?.savedAt, offline = false, loading = false, serverTooOld = false)
                saved?.glance?.let { g ->
                    OngoingRun.reconcile(context, g)
                    if (g.version != before) Surfaces.update(context)
                }
            } catch (e: ApiError.SignedOut) {
                _glance.update { it.copy(loading = false) }
                onUnauthorized()
            } catch (e: ApiError.NotFound) {
                _glance.update { it.copy(loading = false, serverTooOld = true) }
            } catch (e: ApiError) {
                _glance.update { it.copy(loading = false, offline = true) }
            }
        }
    }

    suspend fun refreshSelf() {
        if (!isSignedIn) return
        try {
            val (me, raw) = api.me()
            settings.selfJson = raw
            settings.orgId = me.orgId
            settings.orgName = me.orgName
            settings.personName = me.personName
            _self.value = me
            _auth.value = Auth.SignedIn(me.personName, me.orgName)
        } catch (e: ApiError.SignedOut) {
            onUnauthorized()
        } catch (e: ApiError.NotFound) {
            _glance.update { it.copy(serverTooOld = true) }
        } catch (_: ApiError) {
            // Offline: the saved answer stands.
        }
    }

    /** Runs a call; a 401 signs the watch out everywhere before the error goes on. */
    suspend fun <T> call(block: suspend WatchApi.() -> T): T =
        try {
            api.block()
        } catch (e: ApiError.SignedOut) {
            onUnauthorized()
            throw e
        }

    // --- signing in ---------------------------------------------------------------------------------

    /**
     * The app opened signed out. Only a watch that was never signed in on this install asks the
     * phone by itself. After Sign out here, a removal on the phone or a refused key, it waits for
     * the person to tap Sign in: a watch that was signed out stays signed out (the phone signs in
     * a watch that asks without a question, unless its app lock is on).
     */
    fun autoSignIn() {
        val out = _auth.value as? Auth.SignedOut ?: return
        if (out.reason != OutReason.FIRST_RUN || out.step is SignIn.ServerRefused) return
        startSignIn()
    }

    /** Ask the phone (§8.2). With no phone app in reach, go straight to a code. */
    fun startSignIn() {
        if (isSignedIn || signInJob?.isActive == true) return
        // Showing a code: keep it (reopening the app shouldn't swap the code being typed).
        if ((_auth.value as? Auth.SignedOut)?.step is SignIn.Code) return
        signInJob = scope.launch {
            setStep(SignIn.AskingPhone)
            val requestId = UUID.randomUUID().toString()
            val fingerprint = keys.fingerprint()
            // Remembered with the key it is for: only an answer to one of these is taken.
            settings.signInRequests = SignInRequests.encode(
                SignInRequests.add(SignInRequests.decode(settings.signInRequests), requestId, fingerprint),
            )
            val sent = PhoneLink.requestSignIn(context, LinkMessage.SignIn(requestId, fingerprint, Device.describe(context)))
            if (!sent) {
                startCodeNow()
                return@launch
            }
            // The phone answers in a second or two when its app is running; otherwise the request
            // waits there until it opens.
            delay(8_000)
            if (stepIs<SignIn.AskingPhone>()) setStep(SignIn.WaitingForPhone)
        }
    }

    /** Sign in with a code (the second way Google requires): Casama Cloud only (§8.2). */
    fun startCode() {
        signInJob?.cancel()
        signInJob = scope.launch { startCodeNow() }
    }

    private suspend fun startCodeNow() {
        val server = BuildConfig.DEFAULT_SERVER
        setStep(SignIn.GettingCode)
        val code = try {
            api.requestCode(server, keys.fingerprint(), Device.describe(context))
        } catch (_: ApiError) {
            setStep(SignIn.CodeFailed)
            return
        }
        setStep(SignIn.Code(code))
        val until = code.expiresAt ?: (System.currentTimeMillis() + 10 * 60_000)
        while (System.currentTimeMillis() < until) {
            delay(code.pollEverySeconds * 1000L)
            if (isSignedIn) return // the phone got there first
            try {
                val (me, raw) = api.me(server)
                settings.selfJson = raw
                _self.value = me
                completeSignIn(server, me.orgId, me.orgName, me.personName)
                return
            } catch (_: ApiError.SignedOut) {
                // Not allowed yet: keep asking.
            } catch (e: ApiError.RateLimited) {
                delay(e.retryAfterSeconds * 1000L)
            } catch (_: ApiError) {
                // A dropped connection: keep asking until the code expires.
            }
        }
        setStep(SignIn.CodeExpired)
    }

    /** The phone's answer on the phone link (WATCH-PROTOCOL §2). */
    fun onPhoneMessage(message: LinkMessage) {
        when (message) {
            is LinkMessage.SignedIn -> {
                // Only an answer to a request this watch made for the key it still has: never one
                // made before a sign-out, for a key since wiped, or by another watch.
                if (!issued(message.requestId)) return
                if (!isSignedIn) {
                    scope.launch { completeSignIn(message.server, message.orgId, message.orgName, message.personName) }
                } else if (settings.server == message.server && settings.orgId != message.orgId) {
                    // Signed in already (with a code) when the phone answered a request it held:
                    // the server moved the key to the phone's workspace, so the watch follows.
                    moveTo(message.server, message.orgId, message.orgName, message.personName)
                }
            }
            is LinkMessage.SignedInBadServer -> {
                if (!issued(message.requestId) || isSignedIn || !askingPhone()) return
                signInJob?.cancel()
                setStep(SignIn.ServerRefused)
            }
            is LinkMessage.SignInFailed -> {
                if (issued(message.requestId) && !isSignedIn && askingPhone()) {
                    // The phone said no (nobody signed in there, or the person declined). The job
                    // would otherwise sit out its eight seconds and swallow a tap on Try again.
                    signInJob?.cancel()
                    setStep(SignIn.WaitingForPhone)
                }
            }
            is LinkMessage.Context -> {
                if (!isSignedIn) return
                moveTo(message.server, message.orgId, message.orgName, message.personName)
            }
            LinkMessage.SignOut -> {
                // Signed out already (or never in): nothing to do, and a code on screen stays.
                if (!isSignedIn) return
                scope.launch {
                    // The phone removes the key itself when it can; a phone whose session had
                    // already ended can't, so the watch removes its own before forgetting it.
                    runCatching { withTimeoutOrNull(5_000) { api.signOut() } }
                    wipe(OutReason.FROM_PHONE)
                }
            }
            else -> Unit
        }
    }

    /** Whether [requestId] is one this watch sent for the key it has now (WATCH-PROTOCOL §2). */
    private fun issued(requestId: String): Boolean =
        SignInRequests.issued(
            SignInRequests.decode(settings.signInRequests),
            requestId,
            keys.get()?.let { WatchKey.fingerprint(it) },
        )

    /** Waiting on the phone (not showing or fetching a code, which a late answer must not replace). */
    private fun askingPhone(): Boolean = when ((_auth.value as? Auth.SignedOut)?.step) {
        null, SignIn.AskingPhone, SignIn.WaitingForPhone -> true
        else -> false
    }

    /** The phone switched workspace (or server): the key was re-registered there. */
    private fun moveTo(server: String, orgId: String, orgName: String, person: String) {
        settings.server = server
        settings.orgId = orgId
        settings.orgName = orgName
        settings.personName = person
        _auth.value = Auth.SignedIn(person, orgName)
        cache.wipe()
        _glance.value = GlanceState(null, null, offline = false, loading = true, serverTooOld = false)
        scope.launch {
            refreshSelf()
            refresh()
        }
    }

    private suspend fun completeSignIn(server: String, orgId: String, orgName: String, person: String) {
        signInJob?.cancel()
        settings.server = server
        settings.orgId = orgId
        settings.orgName = orgName
        settings.personName = person
        settings.signedIn = true
        settings.signedOutReason = null
        settings.greetPending = true
        _auth.value = Auth.SignedIn(person, orgName)
        scope.launch {
            refreshSelf()
            refresh()
            PushSetup.register(context)
            Surfaces.update(context)
        }
    }

    fun greeted() {
        settings.greetPending = false
    }

    // --- signing out --------------------------------------------------------------------------------

    /** Sign out of this watch (§6.1 J): the key is deleted on the server, then everything here. */
    suspend fun signOut() {
        runCatching { api.signOut() }
        wipe(OutReason.BY_PERSON)
    }

    /** A 401 from anywhere: the key is gone (removed on the phone, or signed out there). */
    suspend fun onUnauthorized() {
        if (!isSignedIn) return
        wipe(OutReason.REMOVED)
    }

    private suspend fun wipe(reason: OutReason) {
        signInJob?.cancel()
        PushSetup.unregister(context)
        Notifier.cancelAll(context)
        OngoingRun.clearAll(context)
        keys.wipe()
        cache.wipe()
        AskOutbox(context).clear()
        settings.wipeAccount()
        settings.signedOutReason = reason.name
        _self.value = null
        _glance.value = GlanceState(null, null, offline = false, loading = false, serverTooOld = false)
        _auth.value = Auth.SignedOut(reason, null)
        Surfaces.update(context)
    }

    private fun setStep(step: SignIn) {
        val reason = (_auth.value as? Auth.SignedOut)?.reason ?: OutReason.FIRST_RUN
        if (!isSignedIn) _auth.value = Auth.SignedOut(reason, step)
    }

    private inline fun <reified T : SignIn> stepIs(): Boolean = ((_auth.value as? Auth.SignedOut)?.step) is T
}
