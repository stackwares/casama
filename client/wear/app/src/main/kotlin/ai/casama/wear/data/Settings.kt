package ai.casama.wear.data

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * What the watch remembers that isn't secret: its server, who it is signed in as, and the two
 * switches it owns (§6.1 J). Everything else is set on the phone. Wiped at sign-out except the
 * person's own switches.
 */
class Settings(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("casama_settings", Context.MODE_PRIVATE)

    data class Switches(val hideWhenWristDown: Boolean, val readRepliesAloud: Boolean)

    private val _switches = MutableStateFlow(readSwitches())
    val switches: StateFlow<Switches> = _switches.asStateFlow()

    private fun readSwitches() = Switches(
        hideWhenWristDown = prefs.getBoolean(K_HIDE_WRIST_DOWN, true),
        readRepliesAloud = prefs.getBoolean(K_READ_ALOUD, false),
    )

    fun setHideWhenWristDown(on: Boolean) {
        prefs.edit { putBoolean(K_HIDE_WRIST_DOWN, on) }
        _switches.value = readSwitches()
    }

    fun setReadRepliesAloud(on: Boolean) {
        prefs.edit { putBoolean(K_READ_ALOUD, on) }
        _switches.value = readSwitches()
    }

    /** The server this watch's key belongs to; set by the phone or the code sign-in. */
    var server: String?
        get() = prefs.getString(K_SERVER, null)
        set(v) = prefs.edit { putString(K_SERVER, v) }

    /** The key is accepted by [server]. */
    var signedIn: Boolean
        get() = prefs.getBoolean(K_SIGNED_IN, false)
        set(v) = prefs.edit { putBoolean(K_SIGNED_IN, v) }

    var orgId: String?
        get() = prefs.getString(K_ORG_ID, null)
        set(v) = prefs.edit { putString(K_ORG_ID, v) }

    var orgName: String?
        get() = prefs.getString(K_ORG_NAME, null)
        set(v) = prefs.edit { putString(K_ORG_NAME, v) }

    var personName: String?
        get() = prefs.getString(K_PERSON, null)
        set(v) = prefs.edit { putString(K_PERSON, v) }

    /** The last WatchSelf answer (JSON), so settings and quick replies work offline. */
    var selfJson: String?
        get() = prefs.getString(K_SELF, null)
        set(v) = prefs.edit { putString(K_SELF, v) }

    /** The bot the person last asked: Ask opens to it (§6.1 C). */
    var lastAskBotId: String?
        get() = prefs.getString(K_LAST_ASK, null)
        set(v) = prefs.edit { putString(K_LAST_ASK, v) }

    /** The bot the Bot tile shows, picked on the watch. */
    var tileBotId: String?
        get() = prefs.getString(K_TILE_BOT, null)
        set(v) = prefs.edit { putString(K_TILE_BOT, v) }

    /** The open phone sign-in request (WATCH-PROTOCOL §2), so a late answer can be matched. */
    var signInRequestId: String?
        get() = prefs.getString(K_REQUEST, null)
        set(v) = prefs.edit { putString(K_REQUEST, v) }

    /** The Firebase token the server has for this watch; null when none was registered. */
    var registeredPushToken: String?
        get() = prefs.getString(K_PUSH, null)
        set(v) = prefs.edit { putString(K_PUSH, v) }

    /** Why the watch is signed out, for the right words on the sign-in screen. */
    var signedOutReason: String?
        get() = prefs.getString(K_OUT_REASON, null)
        set(v) = prefs.edit { putString(K_OUT_REASON, v) }

    /** "Signed in as Oliver" is shown once (§6.8). */
    var greetPending: Boolean
        get() = prefs.getBoolean(K_GREET, false)
        set(v) = prefs.edit { putBoolean(K_GREET, v) }

    /** Forgets the account; the person's own switches stay. */
    fun wipeAccount() {
        prefs.edit {
            listOf(K_SERVER, K_SIGNED_IN, K_ORG_ID, K_ORG_NAME, K_PERSON, K_SELF, K_LAST_ASK, K_TILE_BOT, K_REQUEST, K_PUSH, K_GREET)
                .forEach { remove(it) }
        }
    }

    private companion object {
        const val K_SERVER = "server"
        const val K_SIGNED_IN = "signed_in"
        const val K_ORG_ID = "org_id"
        const val K_ORG_NAME = "org_name"
        const val K_PERSON = "person_name"
        const val K_SELF = "self_json"
        const val K_LAST_ASK = "last_ask_bot"
        const val K_TILE_BOT = "tile_bot"
        const val K_REQUEST = "sign_in_request"
        const val K_PUSH = "push_token"
        const val K_OUT_REASON = "signed_out_reason"
        const val K_GREET = "greet_pending"
        const val K_HIDE_WRIST_DOWN = "hide_wrist_down"
        const val K_READ_ALOUD = "read_aloud"
    }
}
