package ai.casama.wear.core

/**
 * A minimal server-sent events reader for `GET /v1/watch/runs/{id}?stream=1`: the server sends
 * `run` events, each a whole WatchRun, and ends the stream after 110 seconds or when the run ends.
 * Feed it lines as they arrive; it returns an event at each blank line.
 */
class SseParser {
    data class Event(val name: String, val data: String, val id: String?)

    private var name: String? = null
    private val data = StringBuilder()
    private var id: String? = null

    /** One line without its line ending. Returns an event when [line] ends one. */
    fun feed(line: String): Event? {
        if (line.isEmpty()) {
            if (data.isEmpty()) {
                name = null // as the spec says: an event with no data isn't dispatched
                return null
            }
            val text = if (data.endsWith("\n")) data.substring(0, data.length - 1) else data.toString()
            val ev = Event(name ?: "message", text, id)
            name = null
            data.setLength(0)
            return ev
        }
        if (line.startsWith(":")) return null // comment / keep-alive
        val colon = line.indexOf(':')
        val field = if (colon < 0) line else line.substring(0, colon)
        var value = if (colon < 0) "" else line.substring(colon + 1)
        if (value.startsWith(" ")) value = value.substring(1)
        when (field) {
            "event" -> name = value
            "data" -> data.append(value).append('\n')
            "id" -> id = value
        }
        return null
    }
}
