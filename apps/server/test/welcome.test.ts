/** Welcome chat (D-129): scripted questions, intro and connection card, first task, interview, "What I learned". */
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/welcome.json", import.meta.url));
let h: Harness;
let ana: { id: string; token: string };
let w: { org_id: string; bot_id: string; conversation_id: string };

type Part = {
  type: string;
  text?: string;
  surface_id?: string;
  messages?: Array<Record<string, unknown>>;
};
// Waits until no run is queued or running for three checks in a row (a welcome step can start the
// next run right after one finishes), for up to a minute under a loaded test machine.
const settle = async () => {
  let quiet = 0;
  for (let i = 0; i < 600 && quiet < 3; i++) {
    const [r] = await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.runs where status in ('queued', 'running')`;
    quiet = r?.n ? 0 : quiet + 1;
    await new Promise((res) => setTimeout(res, 100));
  }
};
const last = async () => {
  const [m] = await h.tdb.admin<
    { content: Part[] }[]
  >`select content from public.messages where conversation_id = ${w.conversation_id} and role = 'assistant' order by created_at desc limit 1`;
  return m?.content ?? [];
};
const components = (parts: Part[]) =>
  parts.flatMap((p) =>
    (p.messages ?? []).flatMap(
      (m) =>
        (m.updateComponents as { components?: Array<Record<string, unknown>> })?.components ?? [],
    ),
  );
const actions = (parts: Part[]) =>
  components(parts).flatMap((c) =>
    (c.action as { event?: { name: string; context?: Record<string, unknown> } })?.event
      ? [(c.action as { event: { name: string; context?: Record<string, unknown> } }).event]
      : [],
  );
const surface = (parts: Part[]) => parts.find((p) => p.type === "ui")?.surface_id as string;
const act = async (parts: Part[], name: string, context: Record<string, unknown>, text = name) =>
  j(
    await h.request(`/v1/conversations/${w.conversation_id}/messages`, {
      method: "POST",
      token: ana.token,
      json: { text, ui_action: { surface_id: surface(parts), name, context } },
    }),
  );

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  ana = await h.user("ana@example.com");
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

describe("welcome chat", () => {
  it("creates a personal space, bot and chat that opens with the focus question", async () => {
    w = await j(
      await h.request("/v1/welcome", {
        method: "POST",
        token: ana.token,
        json: { first_name: "ana" },
      }),
    );
    expect(w).toMatchObject({ created: true });
    const [org] = await h.tdb.admin<
      { name: string }[]
    >`select name from public.organizations where id = ${w.org_id}`;
    expect(org?.name).toBe("Ana's space");
    const [bot] = await h.tdb.admin<
      { name: string; avatar_url: string; visibility: string }[]
    >`select name, avatar_url, visibility from public.bots where id = ${w.bot_id}`;
    expect(bot).toEqual({ name: "Casama", avatar_url: "mascot:winky", visibility: "private" });
    const open = await last();
    expect(open[0]?.text).toMatch(/^Hi! I'm Casama/);
    // About you (D-169): first, what to call them, with the given first name filled in.
    expect(components(open).find((c) => c.component === "TextField")).toBeTruthy();
    expect(JSON.stringify(open)).toContain('"name":"Ana"');
    const [persona] = await h.tdb.admin<
      { persona_md: string }[]
    >`select persona_md from public.bots where id = ${w.bot_id}`;
    expect(persona?.persona_md).not.toContain("Ana");
    await act(open, "welcome.name", { name: "  Annie " }, "Annie");
    const [profile] = await h.tdb.admin<
      { preferred_name: string }[]
    >`select preferred_name from public.profiles where user_id = ${ana.id}`;
    expect(profile?.preferred_name).toBe("Annie");
    const focus = await last();
    expect(focus[0]?.text).toBe("Nice to meet you, Annie!");
    expect(components(focus).find((c) => c.component === "ChoicePicker")).toBeTruthy();
    // Again: the same chat.
    expect(
      await j(await h.request("/v1/welcome", { method: "POST", token: ana.token, json: {} })),
    ).toMatchObject({ conversation_id: w.conversation_id, created: false });
  });

  it("answers the scripted questions without a model and offers the right connection", async () => {
    const r = await act(await last(), "welcome.focus", { focus: ["coding"], other: "" }, "Coding");
    expect(r.run_id).toBeTruthy();
    const scope = await last();
    expect(actions(scope).map((a) => a.context?.scope ?? a.name)).toEqual([
      "just_me",
      "team",
      "business",
      "welcome.scope",
    ]);
    await act(scope, "welcome.scope", { scope: "team" }, "My team");
    const intro = await last();
    const all = actions(intro);
    expect(intro[0]?.text).toContain("repositories");
    // One card at a time. No model yet, so only the model card. GitHub and the invite wait.
    expect(all.filter((a) => a.name === "app:route").map((a) => a.context?.path)).toContain(
      "/settings/keys",
    );
    expect(all.filter((a) => a.name === "app:connect")).toEqual([]);
    expect(all.some((a) => a.name === "app:invite")).toBe(false);
    expect(all.some((a) => a.name === "welcome.next")).toBe(true);
    const mems = await h.tdb.admin<
      { content: string }[]
    >`select content from public.memories where bot_id = ${w.bot_id} order by created_at`;
    expect(mems.map((m) => m.content)).toEqual([
      "Wants help first with: Coding.",
      "Uses Casama with their team.",
    ]);
    const [runs] = await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.runs where conversation_id = ${w.conversation_id} and trigger <> 'welcome'`;
    expect(runs?.n).toBe(0);
  });

  it("without a model, going on shows the model card again instead of starting a run", async () => {
    await act(await last(), "welcome.next", {}, "Done, next");
    const again = await last();
    expect(components(again).find((c) => c.id === "t")?.text).toMatch(/I need a model/);
    expect(actions(again).map((a) => `${a.name}:${a.context?.provider ?? ""}`)).toEqual([
      "app:route:chatgpt",
      "app:route:",
      "app:route:openai_compatible",
      "welcome.next:",
    ]);
    // A task typed before any key exists doesn't start a run that can only fail.
    await act(again, "welcome.task", { text: "Fix the login bug" }, "Fix the login bug");
    expect(components(await last()).find((c) => c.id === "t")?.text).toMatch(/I need a model/);
    const [runs] = await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.runs where conversation_id = ${w.conversation_id} and trigger <> 'welcome'`;
    expect(runs?.n).toBe(0);
  });

  it("with a key added, the first task runs on the model, then the setup interview and 'What I learned'", async () => {
    await h.request("/v1/credentials", {
      method: "POST",
      token: ana.token,
      json: {
        org_id: w.org_id,
        provider: "openrouter",
        label: "k",
        api_key: "sk-or-v1-abcdefabcdef",
      },
    });
    await h.tdb.admin`update public.bots set autonomy = 'autonomous' where id = ${w.bot_id}`;
    await act(await last(), "welcome.next", {}, "Continue");
    const connect = await last();
    expect(actions(connect).filter((a) => a.name === "app:connect").map((a) => a.context?.app)).toEqual([
      "github",
    ]);
    expect(actions(connect).some((a) => a.name === "app:invite")).toBe(false);
    await act(connect, "welcome.next", {}, "Done, next");
    const invite = await last();
    expect(actions(invite).some((a) => a.name === "app:invite")).toBe(true);
    expect(actions(invite).some((a) => a.name === "app:connect")).toBe(false);
    await act(invite, "welcome.next", {}, "Done, next");
    const task = await last();
    expect(components(task).find((c) => c.component === "TextField")?.label).toContain(
      "github.com",
    );
    const go = actions(task).find((a) => a.name === "welcome.task");
    await act(task, "welcome.task", {
      text: "https://github.com/ana/parser",
      prefix: go?.context?.prefix,
    });
    await settle();
    const [bot] = await h.tdb.admin<
      { model_policy: { primary: { model: string } } }[]
    >`select model_policy from public.bots where id = ${w.bot_id}`;
    expect(bot?.model_policy.primary.model).toBe("meta/muse-ember");
    const offer = await last();
    expect(offer[0]?.text).toContain("a few quick questions");
    await act(offer, "welcome.setup", {}, "Let's do it");
    await settle();
    const learned = await last();
    expect(learned[0]?.text).toContain("Here's what I learned");
    const options = (components(learned).find((c) => c.component === "ChoicePicker")?.options ??
      []) as Array<{ label: string; value: string }>;
    expect(options.map((o) => o.label)).toEqual([
      "Wants help first with: Coding.",
      "Uses Casama with their team.",
      "Prefers TypeScript",
      "Reviews PRs in the morning",
    ]);
    const keep = options
      .filter((o) => o.label !== "Reviews PRs in the morning")
      .map((o) => o.value);
    await act(learned, "welcome.learned", { keep }, "Looks right");
    const mems = await h.tdb.admin<
      { content: string }[]
    >`select content from public.memories where bot_id = ${w.bot_id} order by created_at`;
    expect(mems.map((m) => m.content)).not.toContain("Reviews PRs in the morning");
    const [conv] = await h.tdb.admin<
      { purpose: string; welcome: { step: string } }[]
    >`select purpose, welcome from public.conversations where id = ${w.conversation_id}`;
    expect(conv).toMatchObject({ purpose: "chat", welcome: { step: "done" } });
  });

  it("people who joined by invite don't get a welcome chat", async () => {
    const bob = await h.user("bob@example.com");
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${w.org_id}, ${bob.id}, 'member')`;
    expect(
      (await h.request("/v1/welcome", { method: "POST", token: bob.token, json: {} })).status,
    ).toBe(409);
  });

  it("a name given in the app's name step first skips the chat's name question", async () => {
    const bea = await h.user("bea@example.com");
    await h.request("/v1/me/about", {
      method: "PATCH",
      token: bea.token,
      json: { preferred_name: "Bea" },
    });
    const bw = await j(
      await h.request("/v1/welcome", { method: "POST", token: bea.token, json: {} }),
    );
    const [m] = await h.tdb.admin<
      { content: Part[] }[]
    >`select content from public.messages where conversation_id = ${bw.conversation_id} and role = 'assistant'`;
    const open = m?.content ?? [];
    expect(open[0]?.text).toMatch(/^Hi Bea! I'm Casama/);
    expect(components(open).find((c) => c.id === "name")).toBeFalsy();
    expect(components(open).find((c) => c.component === "ChoicePicker")).toBeTruthy();
  });

  it("answering the name elsewhere moves a waiting welcome chat on, once", async () => {
    const cy = await h.user("cy@example.com");
    const cw = await j(
      await h.request("/v1/welcome", {
        method: "POST",
        token: cy.token,
        json: { first_name: "cy" },
      }),
    );
    const messages = () =>
      h.tdb.admin<
        { role: string; content: Part[] }[]
      >`select role, content from public.messages where conversation_id = ${cw.conversation_id} order by created_at`;
    const [opening] = await messages();
    for (let i = 0; i < 2; i++)
      await h.request("/v1/me/about", {
        method: "PATCH",
        token: cy.token,
        json: { preferred_name: "Cyrus" },
      });
    const all = await messages();
    expect(all.map((x) => x.role)).toEqual(["assistant", "user", "assistant"]);
    // The old name card shows as answered, then the focus question.
    expect(all[1]?.content.find((p) => p.type === "ui_action")).toMatchObject({
      surface_id: surface(opening?.content ?? []),
      name: "welcome.name",
    });
    expect(all[2]?.content[0]?.text).toBe("Nice to meet you, Cyrus!");
    expect(
      components(all[2]?.content ?? []).find((c) => c.component === "ChoicePicker"),
    ).toBeTruthy();
    const [conv] = await h.tdb.admin<
      { welcome: { step: string } }[]
    >`select welcome from public.conversations where id = ${cw.conversation_id}`;
    expect(conv?.welcome.step).toBe("focus");
  });
});
