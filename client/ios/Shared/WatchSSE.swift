import Foundation

// MARK: - Server-sent events, by hand (D-410 §8.4)
//
// The run stream (GET /v1/watch/runs/{id}?stream=1) sends `run` events, each a whole WatchRun, and
// the server ends it after 110 seconds. URLSession's line reader drops the empty lines SSE uses to
// end an event, so bytes are split here and fed to a small parser that follows the spec's rules
// (field "event", multi-line "data", "id", comments starting with ":").

struct SSEEvent: Equatable {
  var event: String
  var data: String
  var id: String?
}

/// Splits a byte stream into lines on LF, CRLF or a lone CR.
struct SSELineSplitter {
  private var buffer: [UInt8] = []
  private var lastWasCR = false

  /// Feeds one byte; answers a whole line when one ends.
  mutating func push(_ byte: UInt8) -> String? {
    if byte == 0x0A {  // LF
      if lastWasCR {
        lastWasCR = false
        return nil  // The LF of a CRLF: the line was already given at the CR.
      }
      return take()
    }
    lastWasCR = false
    if byte == 0x0D {  // CR
      lastWasCR = true
      return take()
    }
    buffer.append(byte)
    return nil
  }

  /// What is left once the stream ends.
  mutating func flush() -> String? {
    buffer.isEmpty ? nil : take()
  }

  private mutating func take() -> String {
    let line = String(decoding: buffer, as: UTF8.self)
    buffer.removeAll(keepingCapacity: true)
    return line
  }
}

struct SSEParser {
  private var event = ""
  private var data: [String] = []
  private var lastId: String?

  /// Feeds one line; answers an event when an empty line ends one.
  mutating func feed(line: String) -> SSEEvent? {
    if line.isEmpty { return dispatch() }
    if line.hasPrefix(":") { return nil }  // A comment, used as a keep-alive.
    let field: Substring
    var value: Substring
    if let colon = line.firstIndex(of: ":") {
      field = line[..<colon]
      value = line[line.index(after: colon)...]
      if value.hasPrefix(" ") { value = value.dropFirst() }
    } else {
      field = Substring(line)
      value = ""
    }
    switch field {
    case "event": event = String(value)
    case "data": data.append(String(value))
    case "id": lastId = String(value)
    default: break  // "retry" and anything newer: the watch decides its own retries.
    }
    return nil
  }

  /// An event left unfinished when the stream closed is dropped, as the spec says.
  mutating func finish() -> SSEEvent? {
    event = ""
    data = []
    return nil
  }

  private mutating func dispatch() -> SSEEvent? {
    defer {
      event = ""
      data = []
    }
    guard !data.isEmpty else { return nil }
    return SSEEvent(event: event.isEmpty ? "message" : event, data: data.joined(separator: "\n"), id: lastId)
  }
}
