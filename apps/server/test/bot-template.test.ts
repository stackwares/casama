/** Share a bot as a template (D-110): export, links, preview and import; never secrets. */
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let ada: { id: string; token: string };
let eve: { id: string; token: string };
let orgA: string;
let orgB: string;
let botId: string;
let credB: string;

const cred = async (user: { token: string }, org: string) =>
  (
    await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: user.token,
        json: { org_id: org, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
      }),
    )
  ).id as string;

beforeAll(async () => {
  h = await startHarness();
  ada = await h.user("share-ada@example.com");
  eve = await h.user("share-eve@example.com");
  orgA = (
    await j(await h.request("/v1/orgs", { method: "POST", token: ada.token, json: { name: "A" } }))
  ).id;
  orgB = (
    await j(await h.request("/v1/orgs", { method: "POST", token: eve.token, json: { name: "B" } }))
  ).id;
  const credA = await cred(ada, orgA);
  credB = await cred(eve, orgB);
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: ada.token,
        json: {
          org_id: orgA,
          name: "Invoicer",
          persona_md: "You chase unpaid invoices politely.",
          avatar_url: "mascot:cool",
          model_policy: { primary: { credential_id: credA, model: "m" } },
        },
      }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.skills (org_id, bot_id, name, description, body_md) values (${orgA}, ${botId}, 'dunning', 'Follow-up cadence', '1. Day 7')`;
  const [s] = await h.tdb.admin<
    { id: string }[]
  >`select id from public.skills where name = 'dunning'`;
  await h.tdb
    .admin`insert into public.skill_files (org_id, skill_id, path, content, executable) values (${orgA}, ${s!.id}, 'templates/email.md', convert_to('Hello {name}', 'UTF8'), false)`;
  await h.tdb
    .admin`insert into public.routines (org_id, bot_id, name, instructions_md, schedule_cron, timezone, trigger, next_run_at)
    values (${orgA}, ${botId}, 'Weekly chase', 'Chase overdue invoices.', '0 9 * * 1', 'UTC', '{"type":"schedule"}', now())`;
  await h.tdb
    .admin`insert into public.memories (org_id, bot_id, kind, content) values (${orgA}, ${botId}, 'fact', 'Acme pays late')`;
  await h.request("/v1/secrets", {
    method: "POST",
    token: ada.token,
    json: {
      org_id: orgA,
      name: "STRIPE_KEY",
      value: "sk_live_never_share_me",
      allowed_hosts: ["api.stripe.com"],
    },
  });
}, 60_000);
afterAll(async () => h?.stop());

describe("bot templates", () => {
  it("exports instructions, skills with files and routines; memories only when asked; never secrets", async () => {
    const t = await j(await h.request(`/v1/bots/${botId}/export`, { token: ada.token }));
    expect(t).toMatchObject({
      format: "kasama.bot",
      version: 1,
      name: "Invoicer",
      avatar: "mascot:cool",
      memories: [],
    });
    expect(t.skills[0]).toMatchObject({
      name: "dunning",
      files: [
        {
          path: "templates/email.md",
          content_base64: Buffer.from("Hello {name}").toString("base64"),
        },
      ],
    });
    expect(t.routines).toEqual([
      {
        name: "Weekly chase",
        instructions_md: "Chase overdue invoices.",
        schedule_cron: "0 9 * * 1",
      },
    ]);
    const withMem = await j(
      await h.request(`/v1/bots/${botId}/export?memories=true`, { token: ada.token }),
    );
    expect(withMem.memories).toEqual([{ kind: "fact", content: "Acme pays late" }]);
    expect(JSON.stringify(withMem)).not.toContain("sk_live_never_share_me");
    expect(JSON.stringify(withMem)).not.toContain("sk-or-v1");
    expect((await h.request(`/v1/bots/${botId}/export`, { token: eve.token })).status).toBe(404);
  });

  it("shares a link that someone in another workspace previews and imports", async () => {
    const link = await j(
      await h.request(`/v1/bots/${botId}/share`, {
        method: "POST",
        token: ada.token,
        json: { include_memories: false },
      }),
    );
    expect(link.url).toContain(`/import/${link.token}`);
    expect((await h.request(`/v1/bot-shares/${link.token}x`, { token: eve.token })).status).toBe(
      404,
    );
    const preview = await j(await h.request(`/v1/bot-shares/${link.token}`, { token: eve.token }));
    expect(preview.name).toBe("Invoicer");
    const res = await h.request("/v1/bots/import", {
      method: "POST",
      token: eve.token,
      json: { org_id: orgB, template: preview, credential_id: credB, model: "m2" },
    });
    expect(res.status).toBe(201);
    const out = await j(res);
    expect(out).toMatchObject({ skills: 1, routines: 1, memories: 0 });
    const [b] = await h.tdb.admin<{ org_id: string; created_by: string; model: string }[]>`
      select org_id, created_by, model_policy #>> '{primary,model}' as model from public.bots where id = ${out.bot_id}`;
    expect(b).toEqual({ org_id: orgB, created_by: eve.id, model: "m2" });
    const [f] = await h.tdb.admin<{ text: string }[]>`
      select convert_from(f.content, 'UTF8') as text from public.skill_files f join public.skills s on s.id = f.skill_id where s.bot_id = ${out.bot_id}`;
    expect(f?.text).toBe("Hello {name}");
  });

  it("rejects bad templates and someone else's key", async () => {
    const t = await j(await h.request(`/v1/bots/${botId}/export`, { token: ada.token }));
    const bad = await h.request("/v1/bots/import", {
      method: "POST",
      token: eve.token,
      json: {
        org_id: orgB,
        template: { ...t, routines: [{ name: "x", instructions_md: "y", schedule_cron: "nope" }] },
        credential_id: credB,
        model: "m",
      },
    });
    expect(bad.status).toBe(400);
    const theirs = await h.request("/v1/bots/import", {
      method: "POST",
      token: eve.token,
      json: {
        org_id: orgB,
        template: t,
        credential_id: "00000000-0000-0000-0000-000000000000",
        model: "m",
      },
    });
    expect(theirs.status).toBe(400);
  });
});
