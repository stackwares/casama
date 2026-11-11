/** Import an agent (D-122): an OpenClaw ZIP becomes a reviewed bot; leftovers go to ~/imported/. */
import { strToU8, zipSync } from "fflate";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let orgId: string;
let credId: string;
const written = new Map<string, string>();
const handle = {
  ref: "x",
  writeFile: async (p: string, d: Uint8Array) => void written.set(p, new TextDecoder().decode(d)),
};

beforeAll(async () => {
  h = await startHarness();
  (h.deps as { computers?: unknown }).computers = { ensureRunning: async () => handle };
  owner = await h.user("import@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "I" } }),
    )
  ).id;
  credId = (
    await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          provider: "openrouter",
          label: "k",
          api_key: "sk-or-v1-abcdefabcdef",
        },
      }),
    )
  ).id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

const zip = zipSync({
  "my-agent/workspace/SOUL.md": strToU8("You are Juno."),
  "my-agent/workspace/IDENTITY.md": strToU8("Name: Juno"),
  "my-agent/workspace/USER.md": strToU8("- Prefers mornings"),
  "my-agent/workspace/skills/triage/SKILL.md": strToU8(
    "---\nname: triage\ndescription: Triage the inbox\n---\nSort by urgency.",
  ),
  "my-agent/workspace/notes/plan.md": strToU8("The plan"),
  "my-agent/.env": strToU8("TOKEN=secret"),
  "my-agent/cron/jobs.json": strToU8(
    JSON.stringify([
      {
        name: "Brief",
        schedule: { kind: "cron", expr: "0 7 * * *" },
        payload: { message: "Brief me" },
      },
    ]),
  ),
});

describe("import an agent", () => {
  it("maps a ZIP for review, then the template import creates the bot and the files land in ~/imported/", async () => {
    const res = await h.request("/v1/agent-imports", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, zip_base64: Buffer.from(zip).toString("base64") },
    });
    expect(res.status).toBe(201);
    const plan = await j(res);
    expect(plan.kind).toBe("openclaw");
    expect(plan.template).toMatchObject({ name: "Juno", format: "casama.bot" });
    expect(plan.template.skills.map((s: { name: string }) => s.name)).toEqual(["triage"]);
    expect(plan.template.routines).toEqual([
      { name: "Brief", instructions_md: "Brief me", schedule_cron: "0 7 * * *" },
    ]);
    expect(plan.template.memories).toEqual([{ kind: "preference", content: "Prefers mornings" }]);
    expect(plan.leftovers).toEqual([{ path: "workspace/notes/plan.md", size: 8 }]);
    expect(plan.skipped).toEqual([{ path: ".env", reason: "secrets" }]);

    // The person unticks nothing here; the existing template import creates the bot.
    const imported = await j(
      await h.request("/v1/bots/import", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          template: plan.template,
          credential_id: credId,
          model: "m",
          include_memories: true,
          include_routines: true,
        },
      }),
    );
    expect(imported).toMatchObject({ skills: 1, routines: 1, memories: 1 });
    // No computer yet: a clear answer.
    const none = await h.request(`/v1/agent-imports/${plan.id}/files`, {
      method: "POST",
      token: owner.token,
      json: { bot_id: imported.bot_id },
    });
    expect(none.status).toBe(409);
    await h.tdb
      .admin`insert into public.computers (org_id, kind, owner_bot_id, name, provider) values (${orgId}, 'private', ${imported.bot_id}, 'c', 'e2b')`;
    const w = await j(
      await h.request(`/v1/agent-imports/${plan.id}/files`, {
        method: "POST",
        token: owner.token,
        json: { bot_id: imported.bot_id },
      }),
    );
    expect(w).toEqual({ written: 1, folder: "~/imported/openclaw" });
    expect(written.get("~/imported/openclaw/workspace/notes/plan.md")).toBe("The plan");
  });

  it("refuses folders it doesn't recognize and unsafe paths", async () => {
    const bad = await h.request("/v1/agent-imports", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: orgId,
        files: [{ path: "README.md", content_base64: Buffer.from("hi").toString("base64") }],
      },
    });
    expect(bad.status).toBe(400);
    expect((await j(bad)).code).toBe("import_not_recognized");
    const plan = await j(
      await h.request("/v1/agent-imports", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          files: [
            { path: "SOUL.md", content_base64: Buffer.from("x").toString("base64") },
            { path: "../../etc/evil", content_base64: Buffer.from("x").toString("base64") },
          ],
        },
      }),
    );
    expect(plan.leftovers).toEqual([]);
  });

  it("turns ChatGPT or Claude memory pasted back into memories the person picks", async () => {
    const { prompt } = await j(await h.request("/v1/memory-import/prompt", { token: owner.token }));
    expect(prompt).toContain("FACT:");
    const parsed = await j(
      await h.request("/v1/memory-import/parse", {
        method: "POST",
        token: owner.token,
        json: { text: "FACT: Has a dog\nPREFERENCE: Metric units" },
      }),
    );
    expect(parsed.memories).toEqual([
      { kind: "fact", content: "Has a dog" },
      { kind: "preference", content: "Metric units" },
    ]);
    const [bot] = await h.tdb.admin<
      { id: string }[]
    >`select id from public.bots where org_id = ${orgId} limit 1`;
    const saved = await j(
      await h.request(`/v1/bots/${bot!.id}/memories/import`, {
        method: "POST",
        token: owner.token,
        json: { memories: [parsed.memories[1]] },
      }),
    );
    expect(saved.saved).toBe(1);
    const [m] = await h.tdb.admin<
      { kind: string }[]
    >`select kind from public.memories where content = 'Metric units'`;
    expect(m?.kind).toBe("preference");
  });
});
