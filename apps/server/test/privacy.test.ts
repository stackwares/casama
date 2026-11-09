import { fileURLToPath } from "node:url";
import { sql } from "drizzle-orm";
import { strFromU8, unzipSync } from "fflate";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { applyRetention, purgeDueAccounts } from "../src/services/privacy.ts";
import { sendTelemetry, telemetryPayload } from "../src/services/telemetry.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const CHAT = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));

describe("privacy, metrics and telemetry (Phase 8)", () => {
  let h: Harness;
  let owner: { id: string; token: string };
  let member: { id: string; token: string };
  let orgId: string;

  beforeAll(async () => {
    h = await startHarness({
      worker: { fixtures: CHAT },
      env: { ACCOUNT_DELETION_GRACE_DAYS: "0" },
    });
    owner = await h.user("privacy-owner@example.com");
    member = await h.user("privacy-member@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Private Co" },
        }),
      )
    ).id;
    await h.handle.db.execute(
      sql`insert into public.memberships (org_id, user_id, role) values (${orgId}::uuid, ${member.id}::uuid, 'member')`,
    );
    const cred = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          provider: "openrouter",
          label: "k",
          api_key: "sk-privacy-secret-key",
        },
      }),
    );
    const bot = await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Exporter",
          model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
        },
      }),
    );
    await h.request("/v1/secrets", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: orgId,
        name: "API_TOKEN",
        value: "privacy-secret-value",
        allowed_hosts: ["example.com"],
      },
    });
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: bot.id },
      }),
    );
    const sent = await j(
      await h.request(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token: owner.token,
        json: { text: "Hello export" },
      }),
    );
    for (let i = 0; i < 100; i++) {
      if (
        (await j(await h.request(`/v1/runs/${sent.run_id}`, { token: owner.token }))).status ===
        "completed"
      )
        break;
      await new Promise((r) => setTimeout(r, 200));
    }
  }, 180_000);
  afterAll(async () => h?.stop());

  it("exports everything the user can see as a ZIP, without secrets or keys", async () => {
    const res = await h.request("/v1/me/export", { token: owner.token });
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toBe("application/zip");
    const files = unzipSync(new Uint8Array(await res.arrayBuffer()));
    const names = Object.keys(files);
    expect(names).toContain("account.json");
    expect(names).toContain("workspaces/private-co/bots.json");
    expect(names).toContain("workspaces/private-co/messages.json");
    const all = names.map((n) => strFromU8(files[n] as Uint8Array)).join("\n");
    expect(all).toContain("Hello export");
    expect(all).toContain("API_TOKEN");
    expect(all).not.toContain("privacy-secret-value");
    expect(all).not.toContain("sk-privacy-secret-key");
    expect(all).not.toContain("vault_secret_id");
    const [a] = await h.handle.db.execute<{ n: number }>(
      sql`select count(*)::int as n from public.audit_log where action = 'privacy.export' and org_id = ${orgId}::uuid`,
    );
    expect(a?.n).toBe(1);
  });

  it("retention is a workspace setting (admins only) and old run events are dropped", async () => {
    const s = await j(await h.request(`/v1/orgs/${orgId}/settings`, { token: member.token }));
    expect(s.run_event_retention_days).toBe(180);
    const denied = await h.request(`/v1/orgs/${orgId}/settings`, {
      method: "PATCH",
      token: member.token,
      json: { run_event_retention_days: 30 },
    });
    expect(denied.status).toBe(403);
    const bad = await h.request(`/v1/orgs/${orgId}/settings`, {
      method: "PATCH",
      token: owner.token,
      json: { run_event_retention_days: 1 },
    });
    expect(bad.status).toBe(400);
    const ok = await j(
      await h.request(`/v1/orgs/${orgId}/settings`, {
        method: "PATCH",
        token: owner.token,
        json: { run_event_retention_days: 30 },
      }),
    );
    expect(ok.run_event_retention_days).toBe(30);
    await h.handle.db.execute(
      sql`update public.run_events set created_at = now() - interval '45 days' where org_id = ${orgId}::uuid`,
    );
    expect(await applyRetention(h.handle.db)).toBeGreaterThan(0);
    const [left] = await h.handle.db.execute<{ n: number }>(
      sql`select count(*)::int as n from public.run_events where org_id = ${orgId}::uuid`,
    );
    expect(left?.n).toBe(0);
  });

  it("serves the dashboard metrics in Prometheus format", async () => {
    const text = await (await h.request("/metrics")).text();
    expect(text).toContain("# TYPE kasama_runs_15m gauge");
    expect(text).toMatch(/kasama_runs_15m\{status="completed"\} \d+/);
    expect(text).toContain('kasama_time_to_first_token_seconds{quantile="0.95"}');
    expect(text).toContain("kasama_run_failure_ratio_15m");
    expect(text).not.toContain("Hello export");
  });

  it("telemetry sends only an instance id, the version and two counts", async () => {
    const p = await telemetryPayload(h.handle.db, "0.8.0");
    expect(Object.keys(p).sort()).toEqual([
      "instance_id",
      "version",
      "weekly_active_bots",
      "weekly_active_users",
    ]);
    expect(p.weekly_active_bots).toBeGreaterThan(0);
    expect((await telemetryPayload(h.handle.db, "0.8.0")).instance_id).toBe(p.instance_id);
    let sent = "";
    await sendTelemetry(h.handle.db, "https://telemetry.example/v1/ping", "0.8.0", (async (
      _u: string,
      init: RequestInit,
    ) => {
      sent = String(init.body);
      return new Response("{}");
    }) as typeof fetch);
    expect(sent).not.toMatch(/@|privacy|Private Co|Exporter/);
  });

  it("deleting an account signs the user out and purges their workspaces after the grace period", async () => {
    const wrong = await h.request("/v1/me", {
      method: "DELETE",
      token: owner.token,
      json: { confirm_email: "someone@example.com" },
    });
    expect(wrong.status).toBe(400);
    const res = await j(
      await h.request("/v1/me", {
        method: "DELETE",
        token: owner.token,
        json: { confirm_email: "privacy-owner@example.com" },
      }),
    );
    expect(res.workspaces_deleted, JSON.stringify(res)).toEqual(["Private Co"]);
    const [u] = await h.handle.db.execute<{ banned_until: Date | null }>(
      sql`select banned_until from auth.users where id = ${owner.id}::uuid`,
    );
    expect(u?.banned_until).not.toBeNull();
    expect(await purgeDueAccounts(h.handle.db)).toBe(1);
    const [left] = await h.handle.db.execute<{ orgs: number; users: number; member: number }>(sql`
      select (select count(*)::int from public.organizations where id = ${orgId}::uuid) as orgs,
             (select count(*)::int from auth.users where id = ${owner.id}::uuid) as users,
             (select count(*)::int from auth.users where id = ${member.id}::uuid) as member`);
    expect(left).toEqual({ orgs: 0, users: 0, member: 1 });
  });
});
