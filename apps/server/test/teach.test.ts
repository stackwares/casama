/** Teach a task by showing it (D-120): recording under control, secrets, drafting, saving. */
import { fileURLToPath } from "node:url";
import type { ExecChunk } from "@kasama/sandbox";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/teach.json", import.meta.url));
let h: Harness;
let owner: { id: string; token: string };
let other: { id: string; token: string };
let orgId: string;
let botId: string;
let computerId: string;

/** What the fake computer's screen shows after each step. */
let screen = { snapshot: '- textbox "Amount" [ref=e1]', url: "https://finance.example.com/new" };
const fakeHandle = {
  screenshot: async () => new Uint8Array([137, 80, 78, 71]),
  async *exec(cmd: string): AsyncIterable<ExecChunk> {
    const out = cmd.startsWith("agent-desktop snapshot")
      ? screen.snapshot
      : cmd.startsWith("agent-browser get url")
        ? screen.url
        : "";
    yield { type: "stdout", data: out };
    yield { type: "exit", code: 0, timedOut: false, killed: false, truncated: false };
  },
};

const settle = async () => {
  for (let i = 0; i < 200; i++) {
    const [r] = await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.runs where status in ('queued', 'running')`;
    if (!r?.n) return;
    await new Promise((res) => setTimeout(res, 100));
  }
};
const takeControl = (user: { id: string }) =>
  h.tdb
    .admin`insert into public.computer_leases (org_id, computer_id, holder_type, holder_id, mode, expires_at)
    values (${orgId}, ${computerId}, 'user', ${user.id}, 'control', now() + interval '15 minutes')`;
const step = (id: string, json: unknown, token = owner.token) =>
  h.request(`/v1/teach/${id}/steps`, { method: "POST", token, json });

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  (h.deps as { computers?: unknown }).computers = { ensureRunning: async () => fakeHandle };
  owner = await h.user("teach@example.com");
  other = await h.user("other@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "T" } }),
    )
  ).id;
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
    }),
  );
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Clerk",
          model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
        },
      }),
    )
  ).id;
  const [k] = await h.tdb.admin<
    { id: string }[]
  >`insert into public.computers (org_id, kind, owner_bot_id, name, provider)
    values (${orgId}, 'private', ${botId}, 'Clerk computer', 'e2b') returning id`;
  computerId = k!.id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

describe("teach a task", () => {
  let id: string;

  it("only records while you hold control", async () => {
    const res = await h.request("/v1/teach", {
      method: "POST",
      token: owner.token,
      json: { computer_id: computerId, bot_id: botId },
    });
    expect(res.status).toBe(409);
    expect((await j(res)).code).toBe("not_in_control");
    await takeControl(owner);
    const s = await j(
      await h.request("/v1/teach", {
        method: "POST",
        token: owner.token,
        json: { computer_id: computerId, bot_id: botId },
      }),
    );
    expect(s.status).toBe("recording");
    id = s.id;
    // One recording per computer.
    expect(
      (
        await h.request("/v1/teach", {
          method: "POST",
          token: owner.token,
          json: { computer_id: computerId, bot_id: botId },
        })
      ).status,
    ).toBe(409);
    // Someone else can't see it.
    expect((await h.request(`/v1/teach/${id}`, { token: other.token })).status).toBe(404);
  });

  it("captures the screen after each step and never stores password keystrokes", async () => {
    const click = await j(await step(id, { kind: "click", x: 120, y: 340, button: 1 }));
    expect(click).toMatchObject({
      seq: 1,
      kind: "click",
      url: "https://finance.example.com/new",
      has_screenshot: true,
    });
    const typed = await j(await step(id, { kind: "type", text: "42.50" }));
    expect(typed).toMatchObject({ seq: 2, text: "42.50", password: false });
    screen = {
      snapshot: '- textbox "Password" [focused, password] [ref=e7]',
      url: "https://finance.example.com/login",
    };
    const pw = await j(await step(id, { kind: "type", text: "hunter2" }));
    expect(pw).toMatchObject({ seq: 3, text: null, password: true, secret_name: "PASSWORD" });
    const [stored] = await h.tdb.admin<
      { text: string | null }[]
    >`select text from public.teach_steps where session_id = ${id} and seq = 3`;
    expect(stored?.text).toBeNull();
    screen = {
      snapshot: '- textbox "Employee ID" [focused]',
      url: "https://finance.example.com/login",
    };
    await step(id, { kind: "type", text: "E-1234" });
    const marked = await j(
      await h.request(`/v1/teach/${id}/steps/4/secret`, {
        method: "POST",
        token: owner.token,
        json: { secret_name: "EMPLOYEE_ID" },
      }),
    );
    expect(marked).toMatchObject({ text: null, secret_name: "EMPLOYEE_ID" });
    await step(id, { kind: "key", key: "Enter" });
  });

  it("stops when control ends", async () => {
    await h.tdb
      .admin`update public.computer_leases set released_at = now() where computer_id = ${computerId}`;
    const res = await step(id, { kind: "click", x: 1, y: 1 });
    expect(res.status).toBe(409);
    expect((await j(res)).code).toBe("control_ended");
  });

  it("stopping drafts a skill from the recording, without secrets in the transcript", async () => {
    const stopped = await j(
      await h.request(`/v1/teach/${id}/stop`, { method: "POST", token: owner.token }),
    );
    expect(stopped.status).toBe("drafting");
    await settle();
    const [msg] = await h.tdb.admin<{ content: Array<{ text: string }> }[]>`
      select m.content from public.messages m join public.teach_sessions s on s.run_id = m.run_id where s.id = ${id} and m.role = 'user'`;
    const transcript = msg?.content[0]?.text ?? "";
    expect(transcript).toContain("On https://finance.example.com/new");
    expect(transcript).toContain('type "42.50"');
    expect(transcript).toContain("{{secret:PASSWORD}}");
    expect(transcript).toContain("{{secret:EMPLOYEE_ID}}");
    expect(transcript).not.toContain("hunter2");
    expect(transcript).not.toContain("E-1234");
    const s = await j(await h.request(`/v1/teach/${id}`, { token: owner.token }));
    expect(s.status).toBe("drafted");
    expect(s.draft).toMatchObject({
      name: "file-expense",
      checks: ["The portal shows Expense submitted"],
    });
    expect(s.draft.body).toContain("## Inputs");
    expect(s.draft.body).toContain("{{secret:PASSWORD}}");
    expect(s.draft.body).toContain("## Success checks");
  });

  it("saves the edited draft as the bot's skill and tries it right away", async () => {
    const saved = await j(
      await h.request(`/v1/teach/${id}/save`, {
        method: "POST",
        token: owner.token,
        json: {
          name: "file-expense",
          description: "File an expense report.",
          body: "Edited steps.",
          try_now: true,
        },
      }),
    );
    expect(saved.skill_id).toBeTruthy();
    expect(saved.run_id).toBeTruthy();
    await settle();
    const [sk] = await h.tdb.admin<
      { bot_id: string; body_md: string; source: string }[]
    >`select bot_id, body_md, source from public.skills where id = ${saved.skill_id}`;
    expect(sk).toEqual({ bot_id: botId, body_md: "Edited steps.", source: "manual" });
    const [r] = await h.tdb.admin<
      { status: string }[]
    >`select status from public.runs where id = ${saved.run_id}`;
    expect(r?.status).toBe("completed");
    expect(
      (
        await h.request(`/v1/teach/${id}/save`, {
          method: "POST",
          token: owner.token,
          json: { name: "x", description: "d", body: "b" },
        })
      ).status,
    ).toBe(409);
  });

  it("discarding deletes everything captured", async () => {
    expect(
      (await h.request(`/v1/teach/${id}`, { method: "DELETE", token: owner.token })).status,
    ).toBe(200);
    const [n] = await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.teach_steps where session_id = ${id}`;
    expect(n?.n).toBe(0);
  });
});
