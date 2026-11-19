package ai.casama.wear.data

import ai.casama.wear.core.Decode
import ai.casama.wear.core.DecodeException
import ai.casama.wear.core.Encode
import ai.casama.wear.core.Glance
import ai.casama.wear.core.LinkMessage
import ai.casama.wear.core.SseParser
import ai.casama.wear.core.WatchApproval
import ai.casama.wear.core.WatchAsked
import ai.casama.wear.core.WatchChat
import ai.casama.wear.core.WatchCode
import ai.casama.wear.core.WatchRun
import ai.casama.wear.core.WatchSelf
import ai.casama.wear.core.strOrNull
import java.io.File
import java.io.IOException
import java.util.UUID
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import okhttp3.Call
import okhttp3.Callback
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response

/** Why a call didn't work, in the terms the screens care about. */
sealed class ApiError(message: String) : Exception(message) {
    /** 401: the key is gone (WATCH-PROTOCOL §1). While a code is pending it means "not yet". */
    class SignedOut : ApiError("signed out")
    class RateLimited(val retryAfterSeconds: Int) : ApiError("rate limited")
    /** No connection, or the server didn't answer. */
    class Offline(cause: Throwable?) : ApiError("offline: ${cause?.message}")
    /**
     * 404. [code] tells them apart (WATCH-PROTOCOL §1): `not_found` is "not in this watch's
     * workspace", `approval_not_found` and the like are "gone".
     */
    class NotFound(val code: String? = null) : ApiError("not found $code") {
        /** The thing is in another workspace than this watch's key, or isn't the watch's to touch. */
        val elsewhere: Boolean get() = code == "not_found"
    }
    /** 409: already answered, already stopped, no voice service. */
    class Conflict(val code: String? = null) : ApiError("conflict $code")
    /** 403: the server refused (the watch's limits). [detail] is its reason for a refused Allow. */
    class Forbidden(val code: String?, val detail: String? = null) : ApiError("forbidden $code")
    /** Another 4xx: the server won't take this, and asking again won't change that. */
    class Refused(val status: Int, val code: String?) : ApiError("refused $status $code")
    /** 5xx: the server had a problem; trying again later may work. */
    class Server(val status: Int) : ApiError("server $status")
    /** The answer couldn't be read. */
    class Bad(message: String) : ApiError(message)
}

/**
 * The watch's calls (docs/WATCH-PLAN.md §8.4), all with `Authorization: Watch <key>`. Every write
 * carries an Idempotency-Key so a retry on a bad connection can't do it twice. Suspends; never
 * blocks the main thread.
 */
class WatchApi(
    private val settings: Settings,
    private val keys: KeyStore,
    private val userAgent: String,
) {
    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(40, TimeUnit.SECONDS)
        .writeTimeout(40, TimeUnit.SECONDS)
        .retryOnConnectionFailure(true)
        .build()

    /** The run stream: the server ends it after 110 s; a little longer than that without a byte is a dead link. */
    private val streamClient = client.newBuilder().readTimeout(130, TimeUnit.SECONDS).build()

    private val json = "application/json; charset=utf-8".toMediaType()

    private fun base(server: String? = null): String {
        val url = (server ?: settings.server ?: throw ApiError.SignedOut()).trimEnd('/')
        // The key only travels over https, or plain http to a home-network address (the manifest
        // allows cleartext for that alone; this is the gate).
        if (!LinkMessage.isServerUrl(url)) throw ApiError.Offline(IOException("not a server address this watch calls"))
        return url
    }

    private fun request(path: String, server: String? = null, auth: Boolean = true): Request.Builder {
        val b = Request.Builder().url(base(server) + path).header("User-Agent", userAgent)
        if (auth) b.header("Authorization", "Watch " + (keys.get() ?: throw ApiError.SignedOut()))
        return b
    }

    // --- reads ------------------------------------------------------------------------------

    sealed class GlanceResult {
        data object NotModified : GlanceResult()
        data class Fresh(val glance: Glance, val raw: String, val etag: String?) : GlanceResult()
    }

    suspend fun glance(etag: String?): GlanceResult {
        val req = request("/v1/glance").apply { if (etag != null) header("If-None-Match", etag) }.get().build()
        return send(req) { res, body ->
            if (res.code == 304) GlanceResult.NotModified
            else {
                val g = Decode.glance(body)
                GlanceResult.Fresh(g, body, res.header("ETag") ?: g.version.takeIf { it.isNotEmpty() }?.let { "\"$it\"" })
            }
        }
    }

    /** GET /v1/watch/me. [server] is given while signing in, before it is saved. */
    suspend fun me(server: String? = null): Pair<WatchSelf, String> =
        send(request("/v1/watch/me", server).get().build()) { _, body -> Decode.self(body) to body }

    suspend fun chat(botId: String, conversationId: String?): Pair<WatchChat, String> {
        val q = conversationId?.let { "?conversation_id=$it" } ?: ""
        return send(request("/v1/watch/chats/${seg(botId)}$q").get().build()) { _, body -> Decode.chat(body) to body }
    }

    suspend fun approval(id: String): WatchApproval =
        send(request("/v1/watch/approvals/${seg(id)}").get().build()) { _, body -> Decode.approval(body) }

    suspend fun run(id: String): WatchRun =
        send(request("/v1/watch/runs/${seg(id)}").get().build()) { _, body -> Decode.run(body) }

    /** Read aloud: the bot's voice as MP3, saved to [into]. */
    suspend fun speech(messageId: String, into: File): File =
        send(request("/v1/messages/${seg(messageId)}/speech").get().build(), bytes = { bytes ->
            into.writeBytes(bytes)
            into
        })

    // --- signing in ---------------------------------------------------------------------------

    /** POST /v1/watch/codes: signed out, so no key header; only the fingerprint goes. */
    suspend fun requestCode(server: String, fingerprint: String, device: Encode.Device): WatchCode =
        send(request("/v1/watch/codes", server, auth = false).post(Encode.codeRequest(fingerprint, device).toRequestBody(json)).build()) { _, body ->
            Decode.code(body)
        }

    suspend fun updateSelf(pushToken: String?, appVersion: String?, osVersion: String?) {
        send(request("/v1/watch-keys/current").put(Encode.selfUpdate(pushToken, appVersion, osVersion).toRequestBody(json)).build()) { _, _ -> }
    }

    suspend fun signOut() {
        send(request("/v1/watch-keys/current").delete().build()) { _, _ -> }
    }

    // --- writes ---------------------------------------------------------------------------------

    suspend fun ask(body: String, idempotencyKey: String): WatchAsked =
        send(write("/v1/watch/ask", body, idempotencyKey)) { _, text -> Decode.asked(text) }

    suspend fun decide(approvalId: String, allow: Boolean, idempotencyKey: String = newKey()) {
        send(write("/v1/approvals/${seg(approvalId)}/decision", Encode.decision(allow), idempotencyKey)) { _, _ -> }
    }

    suspend fun acceptSuggestion(id: String, idempotencyKey: String = newKey()) {
        send(write("/v1/suggestions/${seg(id)}/accept", Encode.EMPTY, idempotencyKey)) { _, _ -> }
    }

    suspend fun dismissSuggestion(id: String, idempotencyKey: String = newKey()) {
        send(write("/v1/suggestions/${seg(id)}/dismiss", Encode.dismiss(), idempotencyKey)) { _, _ -> }
    }

    /** Run Now. Returns the run's id when the server says it. */
    suspend fun runRoutine(id: String, idempotencyKey: String = newKey()): String? =
        send(write("/v1/routines/${seg(id)}/run", Encode.EMPTY, idempotencyKey)) { _, body ->
            runCatching { Decode.parse(body).strOrNull("run_id") }.getOrNull()
        }

    suspend fun cancelRun(id: String, idempotencyKey: String = newKey()) {
        send(write("/v1/runs/${seg(id)}/cancel", Encode.EMPTY, idempotencyKey)) { _, _ -> }
    }

    suspend fun handoff(link: String, title: String) {
        send(write("/v1/watch/handoff", Encode.handoff(link, title), newKey())) { _, _ -> }
    }

    private fun write(path: String, body: String, idempotencyKey: String): Request =
        request(path).header("Idempotency-Key", idempotencyKey).post(body.toRequestBody(json)).build()

    // --- the run stream -------------------------------------------------------------------------

    /**
     * A run's snapshots as they change: `run` events from `?stream=1`. The server ends a stream
     * after 110 seconds or when the run ends; while the run is live this asks again, backing off
     * when the connection fails. The flow ends when the run does, or throws [ApiError.SignedOut] /
     * [ApiError.NotFound].
     */
    fun runStream(id: String): Flow<WatchRun> = flow {
        var failures = 0
        while (true) {
            var last: WatchRun? = null
            try {
                val req = request("/v1/watch/runs/${seg(id)}?stream=1").header("Accept", "text/event-stream").get().build()
                val call = streamClient.newCall(req)
                val res = call.await()
                res.use { r ->
                    if (!r.isSuccessful) throw errorFor(r)
                    val source = r.body.source()
                    val parser = SseParser()
                    while (true) {
                        val line = source.readUtf8Line() ?: break
                        val ev = parser.feed(line) ?: continue
                        if (ev.name != "run" && ev.name != "message") continue
                        val run = runCatching { Decode.run(ev.data) }.getOrNull() ?: continue
                        last = run
                        failures = 0
                        emit(run)
                        if (!run.phase.live) return@flow
                    }
                }
            } catch (e: ApiError.SignedOut) {
                throw e
            } catch (e: ApiError.NotFound) {
                throw e
            } catch (e: IOException) {
                failures++
            } catch (e: ApiError) {
                failures++
            }
            if (last?.phase?.live == false) return@flow
            // The server's own end after 110 s: ask again at once. A failure: back off up to 15 s.
            if (failures > 0) delay((1000L shl (failures - 1).coerceAtMost(4)).coerceAtMost(15_000L))
        }
    }.flowOn(Dispatchers.IO)

    // --- plumbing ---------------------------------------------------------------------------------

    private suspend fun <T> send(
        req: Request,
        bytes: ((ByteArray) -> T)? = null,
        parse: ((Response, String) -> T)? = null,
    ): T = withContext(Dispatchers.IO) {
        val res = try {
            client.newCall(req).await()
        } catch (e: IOException) {
            throw ApiError.Offline(e)
        }
        res.use { r ->
            if (r.code != 304 && !r.isSuccessful) throw errorFor(r)
            try {
                if (bytes != null) bytes(r.body.bytes())
                else parse!!(r, if (r.code == 304) "" else r.body.string())
            } catch (e: IOException) {
                throw ApiError.Offline(e)
            } catch (e: DecodeException) {
                throw ApiError.Bad(e.message ?: "bad answer")
            }
        }
    }

    private fun errorFor(r: Response): ApiError {
        val body = runCatching { r.peekBody(4096).string() }.getOrDefault("")
        val problem = runCatching { Decode.parse(body) }.getOrNull()
        val code = problem?.strOrNull("code")
        return when (r.code) {
            401 -> ApiError.SignedOut()
            403 -> ApiError.Forbidden(code, problem?.strOrNull("detail"))
            404 -> ApiError.NotFound(code)
            409 -> ApiError.Conflict(code)
            429 -> ApiError.RateLimited(r.header("Retry-After")?.toIntOrNull() ?: 30)
            in 500..599 -> ApiError.Server(r.code)
            else -> ApiError.Refused(r.code, code)
        }
    }

    private fun seg(id: String): String = id.filter { it.isLetterOrDigit() || it == '-' }

    companion object {
        fun newKey(): String = UUID.randomUUID().toString()
    }
}

/** OkHttp's callback API as a cancellable suspend call. */
private suspend fun Call.await(): Response = suspendCancellableCoroutine { cont ->
    cont.invokeOnCancellation { runCatching { cancel() } }
    enqueue(object : Callback {
        override fun onResponse(call: Call, response: Response) {
            cont.resume(response) { _, r, _ -> r.close() }
        }

        override fun onFailure(call: Call, e: IOException) {
            if (!cont.isCancelled) cont.resumeWithException(e)
        }
    })
}
