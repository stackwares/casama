/** Parses a newline-delimited JSON byte stream. */
export async function* ndjson<T>(body: ReadableStream<Uint8Array>): AsyncIterable<T> {
  const decoder = new TextDecoder();
  let buffer = "";
  for await (const chunk of body as unknown as AsyncIterable<Uint8Array>) {
    buffer += decoder.decode(chunk, { stream: true });
    let nl = buffer.indexOf("\n");
    while (nl >= 0) {
      const line = buffer.slice(0, nl).trim();
      buffer = buffer.slice(nl + 1);
      if (line) yield JSON.parse(line) as T;
      nl = buffer.indexOf("\n");
    }
  }
  const rest = (buffer + decoder.decode()).trim();
  if (rest) yield JSON.parse(rest) as T;
}
