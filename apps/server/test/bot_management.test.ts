/** Bots that manage bots (D-100): limits, revisions with the acting bot, archive, folders. */
import { registerAutonomyTools, registerBotTools, ToolRegistry } from "@kasama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let orgId: string;
let botId: string;
let runId: string;
const reg = new ToolRegistry();

const ctx = () => ({ runId, botId, orgId, output: async () => {}, emit: async () => {} }) as never;
const call = (name: string, args: unknown) => reg.get(name)!.execute(args as never, ctx());

beforeAll(async () => {
  h = await startHarness();
  owner = await h.user("botmgr@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Mgr" } }),
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
          name: "Boss",
          autonomy: "ask_risky",
          budget: { per_run_usd: 2, daily_usd: 20 },
          model_policy: { primary: { credential_id: cred.id, model: "m" } },
        },
      }),
    )
  ).id;
  const [run] = await h.tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, trigger, status, created_by)
    values (${orgId}, ${botId}, 'chat', 'running', ${owner.id}) returning id`;
  runId = run!.id;
  registerBotTools(reg, { db: h.handle.db });
  registerAutonomyTools(reg, { db: h.handle.db } as never);
}, 60_000);
afterAll(async () => h?.stop());

describe("bot tools", () => {
  it("creates a bot within its own limits, owned by the person it acts for", async () => {
    await expect(call("bots.create", { name: "Wild", autonomy: "autonomous" })).rejects.toThrow(
      /more autonomy/,
    );
    await expect(call("bots.create", { name: "Rich", budget: { daily_usd: 50 } })).rejects.toThrow(
      /larger daily_usd/,
    );
    const r = await call("bots.create", {
      name: "Scout",
      instructions: "Find things.",
      model: "m2",
    });
    expect(r.content).toContain("Created the bot Scout");
    const [b] = await h.tdb.admin<{ created_by: string; model: string; autonomy: string }[]>`
      select created_by, model_policy #>> '{primary,model}' as model, autonomy from public.bots where name = 'Scout'`;
    expect(b).toMatchObject({ created_by: owner.id, model: "m2", autonomy: "ask_risky" });
    await expect(call("bots.create", { name: "scout" })).rejects.toThrow(/already/);
    expect((await call("bots.list", {})).content).toMatch(/Boss \(you\)[\s\S]*Scout/);
  });

  it("changes another bot, keeps a revision naming the acting bot, and the high-risk bump", async () => {
    const t = reg.get("bots.update")!;
    expect(t.riskFor?.({ bot: "Scout", autonomy: "ask_always" } as never)).toBe("high");
    expect(t.riskFor?.({ bot: "Scout", name: "S" } as never)).toBe("medium");
    await call("bots.update", { bot: "Scout", instructions: "Find better things." });
    const [rev] = await h.tdb.admin<
      { snapshot: { persona_md: string }; changed_fields: string[]; changed_by_bot: string }[]
    >`
      select r.snapshot, r.changed_fields, r.changed_by_bot from public.bot_revisions r
      join public.bots b on b.id = r.bot_id where b.name = 'Scout'`;
    expect(rev).toMatchObject({
      snapshot: { persona_md: "Find things." },
      changed_fields: ["persona_md"],
      changed_by_bot: botId,
    });
    await expect(call("bots.update", { autonomy: "autonomous" })).rejects.toThrow(/more autonomy/);
  });

  it("manages another bot's routines", async () => {
    await call("routines.create", {
      bot: "Scout",
      name: "Daily",
      instructions: "Look around.",
      schedule_cron: "0 9 * * *",
    });
    const [r] = await h.tdb.admin<{ name: string }[]>`
      select b.name from public.routines rt join public.bots b on b.id = rt.bot_id where rt.name = 'Daily'`;
    expect(r?.name).toBe("Scout");
  });

  it("organizes folders and archives other bots, never itself", async () => {
    await call("sidebar.organize", { folders: [{ name: "Research", bots: ["Scout"] }] });
    const [f] = await h.tdb.admin<{ name: string }[]>`
      select f.name from public.bots b join public.bot_folders f on f.id = b.folder_id where b.name = 'Scout'`;
    expect(f?.name).toBe("Research");
    await expect(call("bots.archive", { bot: "Boss" })).rejects.toThrow(/yourself/);
    await call("bots.archive", { bot: "Scout" });
    const list = await j(await h.request(`/v1/bots?org_id=${orgId}`, { token: owner.token }));
    expect(list.items.map((b: { name: string }) => b.name)).toEqual(["Boss"]);
    const archived = await j(
      await h.request(`/v1/bots?org_id=${orgId}&archived=true`, { token: owner.token }),
    );
    expect(archived.items[0]).toMatchObject({ name: "Scout", folder_id: expect.any(String) });
    expect(archived.items[0].archived_at).not.toBeNull();
  });
});
