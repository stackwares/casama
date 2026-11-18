/** Quiet hours (D-109): pushes wait; urgent approvals and per-bot "always" still push. */
import { NotificationService, RecordingPushSender } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let user: { id: string; token: string };
let orgId: string;
let botId: string;
const push = new RecordingPushSender();
let svc: NotificationService;

const hm = (d: Date) =>
  `${String(d.getUTCHours()).padStart(2, "0")}:${String(d.getUTCMinutes()).padStart(2, "0")}`;

beforeAll(async () => {
  h = await startHarness();
  user = await h.user("quiet@example.com");
  orgId = (
    await j(await h.request("/v1/orgs", { method: "POST", token: user.token, json: { name: "Q" } }))
  ).id;
  const [b] = await h.tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, name, created_by) values (${orgId}, 'Night owl', ${user.id}) returning id`;
  botId = b!.id;
  await h.tdb
    .admin`insert into public.devices (user_id, fcm_token, platform) values (${user.id}, 'tok-1', 'ios')`;
  // Quiet from an hour ago to an hour from now, in UTC.
  const now = Date.now();
  await h.tdb.admin`update public.profiles set timezone = 'UTC', quiet_hours = ${h.tdb.admin.json({
    enabled: true,
    start: hm(new Date(now - 3_600_000)),
    end: hm(new Date(now + 3_600_000)),
  })} where user_id = ${user.id}`;
  svc = new NotificationService(h.handle.db, push);
}, 60_000);
afterAll(async () => h?.stop());

describe("quiet hours", () => {
  it("are on by default, 22:00 to 07:00 (D-254)", async () => {
    // A sign-up straight into auth, as Supabase Auth makes it (the harness's users start with them off).
    const [u] = await h.tdb.admin<{ id: string }[]>`
      insert into auth.users (id, email, aud, role)
      values (gen_random_uuid(), 'new-quiet@example.com', 'authenticated', 'authenticated') returning id`;
    const [p] = await h.tdb.admin<{ quiet_hours: unknown }[]>`
      select quiet_hours from public.profiles where user_id = ${u!.id}`;
    expect(p?.quiet_hours).toEqual({ enabled: true, start: "22:00", end: "07:00" });
  });

  it("writes the inbox row now and holds the push", async () => {
    push.sent.length = 0;
    await svc.notify(user.id, orgId, "routine_result", { title: "Done", body: "x", bot_id: botId });
    expect(push.sent).toHaveLength(0);
    const [n] = await h.tdb.admin<{ push_status: string; push_after: Date }[]>`
      select push_status, push_after from public.notifications where user_id = ${user.id} order by created_at desc limit 1`;
    expect(n?.push_status).toBe("deferred");
    expect(new Date(n!.push_after).getTime()).toBeGreaterThan(Date.now() + 50 * 60_000);
  });

  it("still pushes urgent approvals, and bots the person lets through", async () => {
    push.sent.length = 0;
    await svc.notify(user.id, orgId, "approval_request", {
      title: "Approve?",
      body: "x",
      bot_id: botId,
      urgent: true,
    });
    expect(push.sent).toHaveLength(1);
    await h.tdb
      .admin`insert into public.user_bot_settings (user_id, bot_id, quiet) values (${user.id}, ${botId}, 'always')`;
    await svc.notify(user.id, orgId, "routine_result", { title: "Done", body: "y", bot_id: botId });
    expect(push.sent).toHaveLength(2);
    await h.tdb.admin`delete from public.user_bot_settings where user_id = ${user.id}`;
  });

  it("sends held pushes once the window ends, skipping ones already read", async () => {
    push.sent.length = 0;
    await h.tdb
      .admin`update public.notifications set push_after = now() - interval '1 minute' where push_status = 'deferred'`;
    await svc.notify(user.id, orgId, "routine_result", {
      title: "Read already",
      body: "z",
      bot_id: botId,
    });
    await h.tdb
      .admin`update public.notifications set push_after = now() - interval '1 minute', read_at = now()
      where payload->>'title' = 'Read already'`;
    expect(await svc.sendDeferred()).toBe(2);
    expect(push.sent.map((p) => p.message.title)).toEqual(["Done"]);
    expect(await svc.sendDeferred()).toBe(0);
  });
});
