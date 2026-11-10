/** Device connections (D-149): owner-only device data, per-bot grants, fresh reads and writes. */
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/devices.json", import.meta.url));
const KEY = "phone-key-0001";
let h: Harness;
let owner: { id: string; token: string };
let mate: { id: string; token: string };
let orgId: string;
let botId: string;

const waitFor = async <T>(fn: () => Promise<T | undefined | null | false>, what: string, ms = 30_000): Promise<T> => {
  const until = Date.now() + ms;
  for (;;) {
    const v = await fn();
    if (v) return v;
    if (Date.now() > until) throw new Error(`timed out waiting for ${what}`);
    await new Promise((r) => setTimeout(r, 100));
  }
};
type Ev = { type: string; payload: Record<string, unknown> };
async function start(user: { token: string }, text: string) {
  const conv = await j(await h.request("/v1/conversations", { method: "POST", token: user.token, json: { bot_id: botId } }));
  return (await j(await h.request(`/v1/conversations/${conv.id}/messages`, { method: "POST", token: user.token, json: { text } }))).run_id as string;
}
async function finish(user: { token: string }, runId: string) {
  const run = await waitFor(async () => {
    const r = await j(await h.request(`/v1/runs/${runId}`, { token: user.token }));
    return ["completed", "failed"].includes(r.status) ? r : null;
  }, "run");
  const evs = (await j(await h.request(`/v1/runs/${runId}/events?limit=200`, { token: user.token }))).items as Ev[];
  const text = evs.filter((e) => e.type === "message.delta" || e.type === "text.delta").map((e) => String(e.payload.text ?? e.payload.delta ?? "")).join("");
  return { run, evs, text };
}
const say = async (user: { token: string }, text: string) => finish(user, await start(user, text));
const tomorrow = () => {
  const d = new Date(Date.now() + 86_400_000);
  d.setUTCHours(9, 0, 0, 0);
  return d;
};
const save = (kinds: Record<string, unknown>) => h.request(`/v1/device-sources/${KEY}`, { method: "PUT", token: owner.token, json: { name: "Ana's iPhone", platform: "ios", kinds } });

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES, deviceWaitMs: { read: 4000, write: 4000 } } });
  owner = await h.user("device-owner@example.com");
  mate = await h.user("device-mate@example.com");
  orgId = (await j(await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Devices" } }))).id;
  await h.tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${mate.id}, 'member')`;
  const cred = await j(await h.request("/v1/credentials", { method: "POST", token: owner.token, json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-devices" } }));
  botId = (await j(await h.request("/v1/bots", { method: "POST", token: owner.token, json: { org_id: orgId, name: "Pal", model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } } } }))).id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

describe("device connections", () => {
  it("a device registers its kinds and uploads summaries; kinds that are off are refused", async () => {
    const s = await j(await save({ calendar: {}, reminders: { retention_days: 30 } }));
    expect(s).toMatchObject({ name: "Ana's iPhone", platform: "ios", kinds: { calendar: {}, reminders: { retention_days: 30 } } });
    const t = tomorrow();
    const day = { kind: "calendar", period_start: new Date(t.getTime() - 9 * 3600_000).toISOString(), period_end: new Date(t.getTime() + 15 * 3600_000).toISOString(), external_id: t.toISOString().slice(0, 10) };
    const up = await h.request(`/v1/device-sources/${KEY}/readings`, { method: "POST", token: owner.token, json: { readings: [{ ...day, summary: { events: [{ title: "Dentist", start: t.toISOString() }] } }] } });
    expect(await j(up)).toEqual({ stored: 1 });
    // Re-uploading the same day replaces it.
    await h.request(`/v1/device-sources/${KEY}/readings`, { method: "POST", token: owner.token, json: { readings: [{ ...day, summary: { events: [{ title: "Dentist", start: t.toISOString(), location: "Main St" }] } }] } });
    const mine = await j(await h.request("/v1/device-readings?kind=calendar", { token: owner.token }));
    expect(mine.items).toHaveLength(1);
    expect(mine.items[0].summary.events[0].location).toBe("Main St");
    const off = await h.request(`/v1/device-sources/${KEY}/readings`, { method: "POST", token: owner.token, json: { readings: [{ ...day, kind: "health", summary: {} }] } });
    expect(off.status).toBe(400);
    // Nobody else sees it, and another person's key is a different device.
    expect((await j(await h.request("/v1/device-readings", { token: mate.token }))).items).toHaveLength(0);
    expect((await h.request(`/v1/device-sources/${KEY}/readings`, { method: "POST", token: mate.token, json: { readings: [] } })).status).toBe(404);
    // The same key from someone else is their own device; deleting it leaves the owner's alone.
    expect((await h.request(`/v1/device-sources/${KEY}`, { method: "PUT", token: mate.token, json: { name: "Mine", platform: "android", kinds: {} } })).status).toBe(200);
    expect((await h.request(`/v1/device-sources/${KEY}`, { method: "DELETE", token: mate.token })).status).toBe(200);
    expect((await j(await h.request("/v1/device-sources", { token: owner.token }))).items).toMatchObject([{ name: "Ana's iPhone", platform: "ios" }]);
    expect((await j(await h.request("/v1/device-readings?kind=calendar", { token: owner.token }))).items).toHaveLength(1);
  });

  it("a bot without access asks with a card; with it, it answers from the phone, freshly read", async () => {
    const first = await say(owner, "What's on tomorrow?");
    expect(first.evs.find((e) => e.type === "tool.failed")?.payload).toMatchObject({ error_code: "no_device_access" });
    expect(first.evs.find((e) => e.type === "device.access_requested")?.payload).toMatchObject({ kind: "calendar", bot_id: botId });

    const g = await j(await h.request("/v1/device-grants", { method: "PUT", token: owner.token, json: { bot_id: botId, kind: "calendar", allowed: true } }));
    expect(g.items).toMatchObject([{ bot_id: botId, bot_name: "Pal", kind: "calendar" }]);

    // The phone answers the fresh-read request while the run waits.
    const runId = await start(owner, "What's on tomorrow?");
    const req = await waitFor(async () => (await j(await h.request(`/v1/device-sources/${KEY}/requests`, { token: owner.token }))).items[0], "device request");
    expect(req).toMatchObject({ kind: "calendar", action: "read" });
    const t = tomorrow();
    await h.request(`/v1/device-sources/${KEY}/readings`, {
      method: "POST",
      token: owner.token,
      json: { request_id: req.id, readings: [{ kind: "calendar", period_start: t.toISOString(), period_end: t.toISOString(), external_id: t.toISOString().slice(0, 10), summary: { events: [{ title: "Dentist", start: t.toISOString(), location: "Main St" }] } }] },
    });
    const done = await finish(owner, runId);
    expect(done.evs.find((e) => e.type === "tool.completed" && e.payload.call_id === "r1")).toBeTruthy();
    expect(done.evs.find((e) => e.type === "device.data_used")?.payload).toMatchObject({ kind: "calendar", count: 1, devices: ["Ana's iPhone"] });
    const [msg] = await h.tdb.admin<{ content: string }[]>`select content::text as content from public.messages where run_id = ${runId} and role = 'assistant' order by created_at desc limit 1`;
    expect(msg?.content).toContain("dentist");
    // The conversation is now private to its starter: a teammate using the same bot can't read it
    // or its run (audit 2026-11).
    expect((await h.request(`/v1/runs/${runId}/events`, { token: mate.token })).status).toBe(404);
    const theirs = await j(await h.request(`/v1/bots/${botId}/conversations`, { token: mate.token }));
    const [conv] = await h.tdb.admin<{ conversation_id: string }[]>`select conversation_id from public.runs where id = ${runId}`;
    expect(theirs.items.map((c: { id: string }) => c.id)).not.toContain(conv!.conversation_id);
    expect((await h.request(`/v1/runs/${runId}/events`, { token: owner.token })).status).toBe(200);
  });

  it("only the owner's own runs see it: a teammate using the same bot gets nothing", async () => {
    const r = await say(mate, "What's on tomorrow?");
    expect(r.evs.find((e) => e.type === "tool.failed")?.payload).toMatchObject({ error_code: "no_device_access" });
  });

  it("writes go through approval and the device; turning a kind off deletes its data", async () => {
    await h.request("/v1/device-grants", { method: "PUT", token: owner.token, json: { bot_id: botId, kind: "calendar", allowed: true } });
    const runId = await start(owner, "Please add lunch with Sam on Friday");
    const approval = await waitFor(async () => {
      const p = await j(await h.request(`/v1/approvals?org_id=${orgId}&status=pending`, { token: owner.token }));
      return p.items.find((a: { run_id: string }) => a.run_id === runId);
    }, "approval");
    expect(approval).toMatchObject({ tool_name: "device.calendar.create", summary: expect.stringContaining("Lunch with Sam") });
    await h.request(`/v1/approvals/${approval.id}/decision`, { method: "POST", token: owner.token, json: { decision: "approved" } });
    const req = await waitFor(async () => (await j(await h.request(`/v1/device-sources/${KEY}/requests`, { token: owner.token }))).items?.find((x: { action: string }) => x.action === "calendar.create"), "write request");
    expect(req.params).toMatchObject({ title: "Lunch with Sam" });
    expect((await h.request(`/v1/device-requests/${req.id}/result`, { method: "POST", token: mate.token, json: { ok: true } })).status).toBe(404);
    await h.request(`/v1/device-requests/${req.id}/result`, { method: "POST", token: owner.token, json: { ok: true, result: { event_id: "E1" } } });
    const done = await finish(owner, runId);
    expect(done.evs.find((e) => e.type === "tool.completed" && e.payload.call_id === "c1")?.payload.result_preview).toContain("added on Ana's iPhone");

    // Calendar off: its data goes; reminders stay.
    await save({ reminders: { retention_days: 30 } });
    expect((await j(await h.request("/v1/device-readings?kind=calendar", { token: owner.token }))).items).toHaveLength(0);
    const after = await say(owner, "What's on tomorrow?");
    expect(after.evs.find((e) => e.type === "tool.failed")?.payload).toMatchObject({ error_code: "device_kind_off" });
  });

  it("grants only for bots you can use; revoking works", async () => {
    const other = await h.user("device-other@example.com");
    expect((await h.request("/v1/device-grants", { method: "PUT", token: other.token, json: { bot_id: botId, kind: "calendar", allowed: true } })).status).toBe(404);
    const g = await j(await h.request("/v1/device-grants", { method: "PUT", token: owner.token, json: { bot_id: botId, kind: "calendar", allowed: false } }));
    expect(g.items).toEqual([]);
  });

  it("retention removes summaries older than the kind allows", async () => {
    const { purgeDeviceData } = await import("@kasama/agent");
    const old = new Date(Date.now() - 40 * 86_400_000).toISOString();
    await h.request(`/v1/device-sources/${KEY}/readings`, { method: "POST", token: owner.token, json: { readings: [{ kind: "reminders", period_start: old, period_end: old, external_id: "r-old", summary: { title: "x" } }, { kind: "reminders", period_start: new Date().toISOString(), period_end: new Date().toISOString(), external_id: "r-new", summary: { title: "y" } }] } });
    expect(await purgeDeviceData(h.deps.db)).toBe(1);
    expect((await j(await h.request("/v1/device-readings?kind=reminders", { token: owner.token }))).items.map((r: { external_id: string }) => r.external_id)).toEqual(["r-new"]);
  });
});
