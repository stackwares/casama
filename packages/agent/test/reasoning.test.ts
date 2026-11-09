import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { describe, expect, it } from "vitest";
import { AiSdkGateway } from "../src/gateway/ai-sdk.ts";

/** Captures what the gateway sends to an OpenAI-compatible endpoint (OpenRouter's shape). */
async function capture(effort?: "none" | "medium") {
  const bodies: Record<string, unknown>[] = [];
  const server = createServer((req, res) => {
    let raw = "";
    req.on("data", (c) => (raw += c));
    req.on("end", () => {
      bodies.push(JSON.parse(raw));
      res.writeHead(200, { "content-type": "text/event-stream" });
      res.end(
        'data: {"id":"x","choices":[{"index":0,"delta":{"content":"ok"}}]}\n\n' +
          'data: {"id":"x","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":1,"completion_tokens":1}}\n\ndata: [DONE]\n\n',
      );
    });
  });
  await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
  const baseUrl = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  for await (const _ of new AiSdkGateway().stream({
    model: {
      provider: "openrouter",
      model: "openai/gpt-6-luna",
      apiKey: "k",
      baseUrl,
      reasoningEffort: effort,
    },
    system: ["s"],
    messages: [{ role: "user", content: "hi" }],
  })) {
    // drain
  }
  server.close();
  return bodies[0] as Record<string, unknown>;
}

describe("reasoning effort", () => {
  it("is sent to OpenRouter as reasoning.effort", async () => {
    const body = await capture("medium");
    expect(body.model).toBe("openai/gpt-6-luna");
    expect(body.reasoning).toEqual({ effort: "medium" });
  });

  it("is omitted when unset", async () => {
    expect((await capture()).reasoning).toBeUndefined();
  });
});
