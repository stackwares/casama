import { describe, expect, it } from "vitest";
import { withFallback } from "../src/gateway/fallback.ts";
import type { GatewayEvent, ModelGateway, ResolvedModel } from "../src/gateway/types.ts";

const model: ResolvedModel = { provider: "openrouter", model: "meta/muse-ember", apiKey: "k" };

/** A gateway that stalls (sends nothing until aborted) for the first `stalls` calls. */
function stalling(stalls: number) {
  let calls = 0;
  const gateway: ModelGateway = {
    async *stream(req): AsyncIterable<GatewayEvent> {
      calls++;
      if (calls <= stalls) {
        await new Promise((_, reject) =>
          req.abortSignal?.addEventListener("abort", () =>
            reject(Object.assign(new Error("aborted"), { name: "AbortError" })),
          ),
        );
      }
      yield { type: "text", text: "hi" };
    },
  };
  return { gateway, calls: () => calls };
}

const run = (g: ModelGateway) =>
  (async () => {
    let text = "";
    for await (const ev of withFallback(g, [model], {
      firstTokenTimeoutMs: 20,
      sleep: async () => {},
    })({ system: [], messages: [] }))
      if (ev.type === "text") text += ev.text;
    return text;
  })();

describe("withFallback with one model", () => {
  it("tries the model again after a stall", async () => {
    const g = stalling(1);
    expect(await run(g.gateway)).toBe("hi");
    expect(g.calls()).toBe(2);
  });

  it("reports a stall as a timeout, not an abort", async () => {
    const g = stalling(2);
    await expect(run(g.gateway)).rejects.toMatchObject({ code: "model_timeout" });
    expect(g.calls()).toBe(2);
  });
});

describe("withFallback idle timeout", () => {
  it("ends a stream that goes quiet after output started", async () => {
    let calls = 0;
    const gateway: ModelGateway = {
      async *stream(req): AsyncIterable<GatewayEvent> {
        calls++;
        yield { type: "text", text: "partial" };
        await new Promise((_, reject) =>
          req.abortSignal?.addEventListener("abort", () =>
            reject(Object.assign(new Error("aborted"), { name: "AbortError" })),
          ),
        );
      },
    };
    let text = "";
    const stream = withFallback(gateway, [model], {
      firstTokenTimeoutMs: 1000,
      idleTimeoutMs: 20,
      sleep: async () => {},
    })({ system: [], messages: [] });
    await expect(
      (async () => {
        for await (const ev of stream) if (ev.type === "text") text += ev.text;
      })(),
    ).rejects.toMatchObject({ code: "model_timeout" });
    expect(text).toBe("partial");
    // Output already reached the caller, so it isn't retried.
    expect(calls).toBe(1);
  });

  it("doesn't count time the caller spends handling an event", async () => {
    const gateway: ModelGateway = {
      async *stream(): AsyncIterable<GatewayEvent> {
        yield { type: "text", text: "a" };
        yield { type: "text", text: "b" };
      },
    };
    let text = "";
    for await (const ev of withFallback(gateway, [model], { idleTimeoutMs: 20 })({
      system: [],
      messages: [],
    })) {
      if (ev.type === "text") text += ev.text;
      await new Promise((r) => setTimeout(r, 60));
    }
    expect(text).toBe("ab");
  });
});
