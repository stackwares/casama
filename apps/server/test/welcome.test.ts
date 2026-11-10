/** Welcome chat (D-129): scripted questions, intro and connection card, first task, interview, "What I learned". */
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/welcome.json", import.meta.url));
let h: Harness;
let ana: { id: string; token: string };
let w: { org_id: string; bot_id: string; conversation_id: string };

type Part = { type: string; text?: string; surface_id?: string; messages?: Array<Record<string, unknown>> };
const settle = async () => {
  for (let i = 0; i < 200; i++) {
    const [r] = await h.tdb.admin<{ n: number }[]>`select count(*)::int as n from public.runs where status in ('queued', 'running')`;
    if (!r?.n) return;
    await new Promise((res) => setTimeout(res, 100));
  }
};
const last = async () => {
  const [m] = await h.tdb.admin<{ content: Part[] }[]>`select content from public.messages where conversation_id = ${w.conversation_id} and role = 'assistant' order by created_at desc limit 1`;
  return m?.content ?? [];
};
const components = (parts: Part[]) =>
  parts.flatMap((p) => (p.messages ?? []).flatMap((m) => ((m.updateComponents as { components?: Array<Record<string, unknown>> })?.components ?? [])));
const actions = (parts: Part[]) => components(parts).flatMap((c) => ((c.action as { event?: { name: string; context?: Record<string, unknown> } })?.event ? [(c.action as { event: { name: string; context?: Record<string, unknown> } }).event] : []));
const surface = (parts: Part[]) => parts.find((p) => p.type === "ui")?.surface_id as string;
const act = async (parts: Part[], name: string, context: Record<string, unknown>, text = name) =>
  j(await h.request(`/v1/conversations/${w.conversation_id}/messages`, { method: "POST", token: ana.token, json: { text, ui_action: { surface_id: surface(parts), name, context } } }));

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  ana = await h.user("ana@example.com");
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

describe("welcome chat", () => {
  it("creates a personal space, bot and chat that opens with the focus question", async () => {
    w = await j(await h.request("/v1/welcome", { method: "POST", token: ana.token, json: { first_name: "ana" } }));
    expect(w).toMatchObject({ created: true });
    const [org] = await h.tdb.admin<{ name: string }[]>`select name from public.organizations where id = ${w.org_id}`;
    expect(org?.name).toBe("Ana's space");
    const [bot] = await h.tdb.admin<{ name: string; avatar_url: string; visibility: string }[]>`select name, avatar_url, visibility from public.bots where id = ${w.bot_id}`;
    expect(bot).toEqual({ name: "Kasama", avatar_url: "mascot:winky", visibility: "private" });
    const open = await last();
    expect(open[0]?.text).toMatch(/^Hi! I'm Kasama/);
    expect(components(open).find((c) => c.component === "ChoicePicker")).toBeTruthy();
    // Again: the same chat.
    expect(await j(await h.request("/v1/welcome", { method: "POST", token: ana.token, json: {} }))).toMatchObject({ conversation_id: w.conversation_id, created: false });
  });

  it("answers the scripted questions without a model and offers the right connection", async () => {
    const r = await act(await last(), "welcome.focus", { focus: ["coding"], other: "" }, "Coding");
    expect(r.run_id).toBeTruthy();
    const scope = await last();
    expect(actions(scope).map((a) => a.context?.scope ?? a.name)).toEqual(["just_me", "team", "business", "welcome.scope"]);
    await act(scope, "welcome.scope", { scope: "team" }, "My team");
    const intro = await last();
    const all = actions(intro);
    expect(intro[0]?.text).toContain("repositories");
    // No model yet: the model card first. Coding: GitHub, not Google. Team: an invite card.
    expect(all.filter((a) => a.name === "app:route").map((a) => a.context?.path)).toContain("/settings/keys");
    expect(all.filter((a) => a.name === "app:connect").map((a) => a.context?.app)).toEqual(["github"]);
    expect(all.some((a) => a.name === "app:invite")).toBe(true);
    const mems = await h.tdb.admin<{ content: string }[]>`select content from public.memories where bot_id = ${w.bot_id} order by created_at`;
    expect(mems.map((m) => m.content)).toEqual(["Wants help first with: Coding.", "Uses Kasama with their team."]);
    const [runs] = await h.tdb.admin<{ n: number }[]>`select count(*)::int as n from public.runs where conversation_id = ${w.conversation_id} and trigger <> 'welcome'`;
    expect(runs?.n).toBe(0);
  });

  it("with a key added, the first task runs on the model, then the setup interview and 'What I learned'", async () => {
    await h.request("/v1/credentials", {
      method: "POST",
      token: ana.token,
      json: { org_id: w.org_id, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
    });
    await h.tdb.admin`update public.bots set autonomy = 'autonomous' where id = ${w.bot_id}`;
    await act(await last(), "welcome.next", {}, "Done, next");
    const task = await last();
    expect(components(task).find((c) => c.component === "TextField")?.label).toContain("github.com");
    const go = actions(task).find((a) => a.name === "welcome.task");
    await act(task, "welcome.task", { text: "https://github.com/ana/parser", prefix: go?.context?.prefix });
    await settle();
    const [bot] = await h.tdb.admin<{ model_policy: { primary: { model: string } } }[]>`select model_policy from public.bots where id = ${w.bot_id}`;
    expect(bot?.model_policy.primary.model).toBe("openai/gpt-6-luna");
    const offer = await last();
    expect(offer[0]?.text).toContain("a few quick questions");
    await act(offer, "welcome.setup", {}, "Let's do it");
    await settle();
    const learned = await last();
    expect(learned[0]?.text).toContain("Here's what I learned");
    const options = (components(learned).find((c) => c.component === "ChoicePicker")?.options ?? []) as Array<{ label: string; value: string }>;
    expect(options.map((o) => o.label)).toEqual(["Wants help first with: Coding.", "Uses Kasama with their team.", "Prefers TypeScript", "Reviews PRs in the morning"]);
    const keep = options.filter((o) => o.label !== "Reviews PRs in the morning").map((o) => o.value);
    await act(learned, "welcome.learned", { keep }, "Looks right");
    const mems = await h.tdb.admin<{ content: string }[]>`select content from public.memories where bot_id = ${w.bot_id} order by created_at`;
    expect(mems.map((m) => m.content)).not.toContain("Reviews PRs in the morning");
    const [conv] = await h.tdb.admin<{ purpose: string; welcome: { step: string } }[]>`select purpose, welcome from public.conversations where id = ${w.conversation_id}`;
    expect(conv).toMatchObject({ purpose: "chat", welcome: { step: "done" } });
  });

  it("people who joined by invite don't get a welcome chat", async () => {
    const bob = await h.user("bob@example.com");
    await h.tdb.admin`insert into public.memberships (org_id, user_id, role) values (${w.org_id}, ${bob.id}, 'member')`;
    expect((await h.request("/v1/welcome", { method: "POST", token: bob.token, json: {} })).status).toBe(409);
  });
});
