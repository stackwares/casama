/**
 * Runs stuck in `running` (D-478): on 2026-11-21 local runs from five days before still said they
 * were working. A run with no event for six hours is failed, with what it held let go.
 */
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { failStaleRuns } from "../src/worker/workflows.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));
let h: Harness;
let me: { id: string; token: string };
let org = "";
let bot = "";

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  me = await h.user("stale-runs@example.com");
  org = (
    await j(await h.request("/v1/orgs", { method: "POST", token: me.token, json: { name: "S" } }))
  ).id;
  bot = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: me.token,
        json: { org_id: org, name: "B" },
      }),
    )
  ).id;
}, 120_000);
afterAll(() => h?.stop());

const run = async (trigger: string, status: string, startedHoursAgo: number) => {
  const [r] = await h.tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, created_by, trigger, status, started_at, created_at)
    values (${org}, ${bot}, ${me.id}, ${trigger}, ${status},
            now() - make_interval(hours => ${startedHoursAgo}), now() - make_interval(hours => ${startedHoursAgo}))
    returning id`;
  return r?.id as string;
};
const statusOf = async (id: string) =>
  (await h.tdb.admin<{ status: string }[]>`select status from public.runs where id = ${id}`)[0]
    ?.status;

describe("stale runs", () => {
  it("fails chat and routine runs silent for six hours, and only those", async () => {
    const chat = await run("chat", "running", 120);
    const routine = await run("routine", "running", 7);
    // Started long ago but still writing events: working.
    const busy = await run("chat", "running", 8);
    await h.tdb.admin`
      insert into public.run_events (run_id, org_id, bot_id, seq, type, payload)
      values (${busy}, ${org}, ${bot}, 1, 'text.delta', '{}'::jsonb)`;
    // Waiting for a person, too young, or not a chat or routine run: left alone.
    const waiting = await run("chat", "waiting_approval", 30);
    const young = await run("chat", "running", 2);
    const call = await run("voice", "running", 30);

    expect(await failStaleRuns(h.handle.db)).toBe(2);
    expect(await statusOf(chat)).toBe("failed");
    expect(await statusOf(routine)).toBe("failed");
    for (const id of [busy, young]) expect(await statusOf(id)).toBe("running");
    expect(await statusOf(waiting)).toBe("waiting_approval");
    expect(await statusOf(call)).toBe("running");
    const [failed] = await h.tdb.admin<{ error: { code: string }; ended: boolean }[]>`
      select error, ended_at is not null as ended from public.runs where id = ${chat}`;
    expect(failed).toMatchObject({ error: { code: "run_stale" }, ended: true });
    const events = await h.tdb.admin<{ type: string }[]>`
      select type from public.run_events where run_id = ${chat}`;
    expect(events.map((e) => e.type)).toContain("run.failed");
    // Once is enough.
    expect(await failStaleRuns(h.handle.db)).toBe(0);
  });
});
