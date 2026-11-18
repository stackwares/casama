/** A server-sent event, as the stream sends it. */
export interface SseMessage {
  event: string;
  data: string;
  id: string | undefined;
}

/**
 * Reads a text/event-stream body into messages. Handles chunks that split lines or events, CRLF
 * line ends and multi-line `data:` fields; skips comments.
 */
export async function* readSse(body: ReadableStream<Uint8Array>): AsyncGenerator<SseMessage> {
  const reader = body.getReader();
  const decoder = new TextDecoder();
  let buffer = "";
  let event = "";
  let data: string[] = [];
  let id: string | undefined;
  try {
    while (true) {
      const { value, done } = await reader.read();
      buffer += done ? decoder.decode() : decoder.decode(value, { stream: true });
      let nl = buffer.search(/\r\n|\r|\n/);
      while (nl >= 0) {
        // A CR at the very end may be the first half of a CRLF split across chunks.
        if (!done && nl === buffer.length - 1 && buffer[nl] === "\r") break;
        const line = buffer.slice(0, nl);
        buffer = buffer.slice(nl + (buffer.startsWith("\r\n", nl) ? 2 : 1));
        if (line === "") {
          if (data.length > 0) yield { event: event || "message", data: data.join("\n"), id };
          event = "";
          data = [];
          id = undefined;
        } else if (!line.startsWith(":")) {
          const colon = line.indexOf(":");
          const field = colon < 0 ? line : line.slice(0, colon);
          let value = colon < 0 ? "" : line.slice(colon + 1);
          if (value.startsWith(" ")) value = value.slice(1);
          if (field === "event") event = value;
          else if (field === "data") data.push(value);
          else if (field === "id") id = value;
        }
        nl = buffer.search(/\r\n|\r|\n/);
      }
      if (done) break;
    }
  } finally {
    // Also closes the connection when the caller stops reading early.
    await reader.cancel().catch(() => {});
  }
}
