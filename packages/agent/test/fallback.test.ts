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
