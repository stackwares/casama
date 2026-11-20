package ai.casama.app.canvas

/**
 * A small JSON reader for the Canvas widget's model (docs/BOT-WIDGET-PLAN.md §10.2). The phone app
 * reads its other documents with Android's org.json, which isn't on a plain JVM; this one has no
 * Android in it, so the model is tested with kotlinc (scripts/test-canvas-kotlin.sh).
 *
 * Objects become `Map<String, Any?>`, arrays `List<Any?>`, numbers `Double`, and `null` is null.
 */
internal object MiniJson {
  fun parse(text: String): Any? {
    val r = Reader(text)
    r.space()
    val v = r.value()
    r.space()
    if (r.i != text.length) throw IllegalArgumentException("JSON: trailing text at ${r.i}")
    return v
  }

  private class Reader(val s: String) {
    var i = 0

    fun space() {
      while (i < s.length && (s[i] == ' ' || s[i] == '\n' || s[i] == '\r' || s[i] == '\t')) i++
    }

    fun fail(what: String): Nothing = throw IllegalArgumentException("JSON: $what at $i")

    fun value(): Any? {
      if (i >= s.length) fail("unexpected end")
      return when (val c = s[i]) {
        '{' -> obj()
        '[' -> arr()
        '"' -> str()
        't' -> word("true", true)
        'f' -> word("false", false)
        'n' -> word("null", null)
        else -> if (c == '-' || c in '0'..'9') num() else fail("unexpected '$c'")
      }
    }

    private fun word(w: String, v: Any?): Any? {
      if (!s.startsWith(w, i)) fail("expected $w")
      i += w.length
      return v
    }

    private fun obj(): Map<String, Any?> {
      val out = LinkedHashMap<String, Any?>()
      i++
      space()
      if (i < s.length && s[i] == '}') { i++; return out }
      while (true) {
        space()
        if (i >= s.length || s[i] != '"') fail("expected a key")
        val k = str()
        space()
        if (i >= s.length || s[i] != ':') fail("expected ':'")
        i++
        space()
        out[k] = value()
        space()
        if (i >= s.length) fail("unexpected end")
        when (s[i]) {
          ',' -> i++
          '}' -> { i++; return out }
          else -> fail("expected ',' or '}'")
        }
      }
    }

    private fun arr(): List<Any?> {
      val out = ArrayList<Any?>()
      i++
      space()
      if (i < s.length && s[i] == ']') { i++; return out }
      while (true) {
        space()
        out.add(value())
        space()
        if (i >= s.length) fail("unexpected end")
        when (s[i]) {
          ',' -> i++
          ']' -> { i++; return out }
          else -> fail("expected ',' or ']'")
        }
      }
    }

    private fun str(): String {
      i++
      val b = StringBuilder()
      while (true) {
        if (i >= s.length) fail("unterminated string")
        val c = s[i++]
        when (c) {
          '"' -> return b.toString()
          '\\' -> {
            if (i >= s.length) fail("bad escape")
            when (val e = s[i++]) {
              '"' -> b.append('"')
              '\\' -> b.append('\\')
              '/' -> b.append('/')
              'b' -> b.append('\b')
              'f' -> b.append('\u000C')
              'n' -> b.append('\n')
              'r' -> b.append('\r')
              't' -> b.append('\t')
              'u' -> {
                if (i + 4 > s.length) fail("bad \\u escape")
                b.append(s.substring(i, i + 4).toIntOrNull(16)?.toChar() ?: fail("bad \\u escape"))
                i += 4
              }
              else -> fail("bad escape '\\$e'")
            }
          }
          else -> b.append(c)
        }
      }
    }

    private fun num(): Double {
      val start = i
      if (s[i] == '-') i++
      while (i < s.length && (s[i] in '0'..'9' || s[i] == '.' || s[i] == 'e' || s[i] == 'E' || s[i] == '+' || s[i] == '-')) i++
      return s.substring(start, i).toDoubleOrNull() ?: fail("bad number")
    }
  }
}
