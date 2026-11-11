/**
 * Live checks against a real model (D-064): skipped unless CASAMA_LIVE=1 and OPENROUTER_API_KEY is
 * set (scripts/live-check.sh loads it from ~/.config/casama/openrouter.env). CI and the default test
 * run use recorded fixtures and need no key. Output tokens are capped and only a few calls are made.
 */
import { dockerAvailable, type SandboxStack, startSandboxStack } from "@casama/sandbox/testing";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const key = process.env.OPENROUTER_API_KEY ?? "";
const enabled = process.env.CASAMA_LIVE === "1" && key.length > 0 && (await dockerAvailable());

describe.skipIf(!enabled)("live model (GPT-6 Luna on OpenRouter)", () => {
  let stack: SandboxStack;
  let h: Harness;
  let owner: { token: string };
  let orgId: string;
  let credId: string;

  beforeAll(async () => {
    stack = await startSandboxStack();
    h = await startHarness({ worker: { maxOutputTokens: 1500 }, sandbox: stack });
    owner = await h.user("live-model@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Live" } }),
      )
    ).id;
    credId = (
      await j(
        await h.request("/v1/credentials", {
          method: "POST",
          token: owner.token,
          json: { org_id: orgId, provider: "openrouter", label: "live", api_key: key },
        }),
      )
    ).id;
  }, 240_000);
  afterAll(async () => {
    await h?.stop();
    await stack?.stop();
  }, 180_000);

  it("the key works with the default model", async () => {
    const res = await j(
      await h.request(`/v1/credentials/${credId}/test`, {
        method: "POST",
        token: owner.token,
        json: {},
      }),
    );
    expect(res).toMatchObject({ ok: true, model: "openai/gpt-6-luna" });
  }, 60_000);

  it("a live tool call drives a real Docker computer", async () => {
    const bot = await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Live",
          autonomy: "autonomous",
          model_policy: { primary: { credential_id: credId, model: "openai/gpt-6-luna" } },
        },
      }),
    );
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: bot.id },
      }),
    );
    const sent = await j(
      await h.request(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token: owner.token,
        json: {
          text: "Use the shell.exec tool to run exactly: echo casama-live-$((6*7)) . Then reply with only the command's output.",
        },
      }),
    );
    let run: { status: string; cost_usd: number };
    const until = Date.now() + 180_000;
    for (;;) {
      run = await j(await h.request(`/v1/runs/${sent.run_id}`, { token: owner.token }));
      if (["completed", "failed", "cancelled"].includes(run.status) || Date.now() > until) break;
      await new Promise((r) => setTimeout(r, 1000));
    }
    const events = (
      await j(await h.request(`/v1/runs/${sent.run_id}/events?limit=1000`, { token: owner.token }))
    ).items as Array<{ type: string; payload: Record<string, unknown> }>;
    const started = events.find((e) => e.type === "tool.started");
    const output = events
      .filter((e) => e.type === "tool.output")
      .map((e) => e.payload.chunk)
      .join("");
    const final = events.find((e) => e.type === "message.completed");
    console.log(
      `live run: ${run.status}, tool ${started?.payload.tool}, cost $${Number(run.cost_usd).toFixed(5)}, ${events.length} events`,
    );
    expect(run.status).toBe("completed");
    expect(started?.payload.tool).toBe("shell.exec");
    expect(output).toContain("casama-live-42");
    expect(JSON.stringify(final?.payload)).toContain("casama-live-42");
    // The key never appears in anything the run recorded.
    expect(JSON.stringify(events)).not.toContain(key);
  }, 240_000);
});
