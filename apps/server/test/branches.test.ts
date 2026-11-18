/** Edit and resend (D-108): an edit forks the conversation and reruns; the old branch stays. */
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/branches.json", import.meta.url));
let h: Harness;
let owner: { id: string; token: string };
let convId: string;

const done = async (runId: string) => {
  for (let i = 0; i < 150; i++) {
    const r = await j(await h.request(`/v1/runs/${runId}`, { token: owner.token }));
    if (["completed", "failed"].includes(r.status)) return r;
    await new Promise((res) => setTimeout(res, 100));
  }
  throw new Error("run did not finish");
};
const send = async (text: string) =>
  j(
    await h.request(`/v1/conversations/${convId}/messages`, {
      method: "POST",
      token: owner.token,
      json: { text },
    }),
  );
const thread = async () =>
  h.tdb.admin<
    {
      id: string;
      role: string;
      content: Array<{ text?: string }>;
      sibling_index: number;
      sibling_count: number;
    }[]
  >`
    select * from public.conversation_thread(${convId})`;
const texts = async () => (await thread()).map((m) => m.content[0]?.text);

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  owner = await h.user("branch-owner@example.com");
  const orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "B" } }),
    )
  ).id;
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
    }),
  );
  const bot = await j(
    await h.request("/v1/bots", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: orgId,
        name: "Echo",
        model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
      },
    }),
  );
  convId = (
    await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: bot.id },
      }),
    )
  ).id;
}, 60_000);
afterAll(async () => h?.stop());

describe("message branches", () => {
  let first: string;
  it("keeps a straight thread for normal chat", async () => {
    const a = await send("first question");
    first = a.message_id;
    await done(a.run_id);
    await done((await send("second question")).run_id);
    expect(await texts()).toEqual([
      "first question",
      "Reply one.",
      "second question",
      "Reply two.",
    ]);
  });

  it("edits fork at the message, rerun, and keep the old branch", async () => {
    const res = await h.request(`/v1/conversations/${convId}/messages/${first}/edit`, {
      method: "POST",
      token: owner.token,
      json: { text: "edited question" },
    });
    expect(res.status).toBe(202);
    await done((await j(res)).run_id);
    const t = await thread();
    expect(t.map((m) => m.content[0]?.text)).toEqual(["edited question", "Reply to the edit."]);
    expect(t[0]).toMatchObject({ sibling_index: 2, sibling_count: 2 });

    const back = await j(
      await h.request(`/v1/conversations/${convId}/branch`, {
        method: "POST",
        token: owner.token,
        json: { message_id: first },
      }),
    );
    expect(back.head_message_id).toBeTruthy();
    expect(await texts()).toEqual([
      "first question",
      "Reply one.",
      "second question",
      "Reply two.",
    ]);
    expect((await thread())[0]).toMatchObject({ sibling_index: 1, sibling_count: 2 });
  });

  it("refuses to edit while a run is going and only edits your messages", async () => {
    const t = await thread();
    const reply = t.find((m) => m.role === "assistant")!;
    expect(
      (
        await h.request(`/v1/conversations/${convId}/messages/${reply.id}/edit`, {
          method: "POST",
          token: owner.token,
          json: { text: "x" },
        })
      ).status,
    ).toBe(400);
  });
});
