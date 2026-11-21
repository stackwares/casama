import { fileURLToPath } from "node:url";
import { PLATFORM_OPENROUTER_CREDENTIAL_ID } from "@casama/agent";
import { DEFAULT_MODEL_ACCESS, setModelAccess } from "@casama/domain";
import { sql } from "drizzle-orm";
import { afterAll, afterEach, beforeAll, describe, expect, it } from "vitest";
import { claimDueRoutines } from "../src/worker/routines.ts";
import { billingEnv, type FakeBilling, startFakeBilling } from "./fake-billing.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const CHAT = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));

describe("own model provider on Casama Cloud & model access switch (OWN-KEYS-PLAN)", () => {
  let f: FakeBilling;
  let h: Harness;
  let adminOwner: { id: string; token: string };
  let made = 0;

  const newOrg = async (name: string) => {
    const maker = await h.user(`own-key-maker-${++made}@example.com`);
    const id = (
      await j(await h.request("/v1/orgs", { method: "POST", token: maker.token, json: { name } }))
    ).id as string;
    return { orgId: id, user: maker };
  };

  const waitRun = async (runId: string, token: string) => {
    let run: { status: string; error?: { code?: string; message?: string } } = { status: "queued" };
    for (let i = 0; i < 100 && !["failed", "completed", "cancelled"].includes(run.status); i++) {
      await new Promise((r) => setTimeout(r, 150));
      run = await j(await h.request(`/v1/runs/${runId}`, { token }));
    }
    return run;
  };

  beforeAll(async () => {
    f = await startFakeBilling();
    h = await startHarness({
      env: {
        ...billingEnv(f),
        CLOUD_MODEL_UPSTREAM_KEY: "sk-casama-platform-key",
      },
      worker: { fixtures: CHAT },
      casamaLink: {
        models: { url: "http://127.0.0.1:1", key: "sk-casama-platform-key" },
      },
    });
    await h.handle.db.execute(sql`update public.billing_settings set max_owned_workspaces = 100`);
    // The first user is the instance owner when INSTANCE_ADMIN_EMAILS is unset.
    adminOwner = await h.user("instance-owner-own-keys@example.com");
    await h.handle.db.execute(sql`
      update auth.users set created_at = '2020-01-01T00:00:00Z' where id = ${adminOwner.id}::uuid`);
    await h.request("/v1/orgs", {
      method: "POST",
      token: adminOwner.token,
      json: { name: "Admin Org" },
    });
  }, 180_000);

  afterEach(async () => {
    setModelAccess(DEFAULT_MODEL_ACCESS);
    await h.handle.db.execute(sql`delete from public.instance_settings where key = 'model_access'`);
  });

  afterAll(async () => {
    setModelAccess(DEFAULT_MODEL_ACCESS);
    await h?.stop();
    await f?.stop();
  });

  it("exposes own_providers in /v1/config and allows GET/PUT /v1/admin/model-access with audit log", async () => {
    const cfg1 = await j(await h.request("/v1/config"));
    expect(cfg1.own_providers).toBe(false);

    const getRes = await h.request("/v1/admin/model-access", { token: adminOwner.token });
    expect(getRes.status).toBe(200);
    expect(await j(getRes)).toEqual(DEFAULT_MODEL_ACCESS);

    const putRes = await h.request("/v1/admin/model-access", {
      method: "PUT",
      token: adminOwner.token,
      json: {
        own_providers: true,
        casama_models: { default: "on", plans: { free: "off" } },
        note: "Free tier now requires your own key.",
      },
    });
    expect(putRes.status).toBe(200);
    expect(await j(putRes)).toEqual({
      own_providers: true,
      casama_models: { default: "on", plans: { free: "off" } },
      note: "Free tier now requires your own key.",
    });

    const cfg2 = await j(await h.request("/v1/config"));
    expect(cfg2.own_providers).toBe(true);
    expect(cfg2.key_providers.cloud).toContain("openai");
    expect(cfg2.key_providers.cloud).toContain("anthropic");

    const [audit] = await h.handle.db.execute<{ action: string; metadata: unknown }>(sql`
      select action, metadata from public.audit_log
      where action = 'admin.model_access' order by created_at desc limit 1`);
    expect(audit?.action).toBe("admin.model_access");
  });

  it("runs a Cloud bot on an own key at 0 credits and past cloud_daily_usd, recording billable=false", async () => {
    await h.request("/v1/admin/model-access", {
      method: "PUT",
      token: adminOwner.token,
      json: {
        own_providers: true,
        casama_models: { default: "on", plans: {} },
        note: null,
      },
    });
    const { orgId, user } = await newOrg("Zero Credits Own Key");
    // Drain all credits and exceed cloud_daily_usd.
    await h.handle.db.execute(sql`
      insert into public.usage_ledger (org_id, kind, quantity, cost_usd, billable, created_at)
      values (${orgId}::uuid, 'tokens_in', 1000, 5.0, true, now())`);
    await h.deps.billing?.settle();

    const summary = await j(await h.request(`/v1/orgs/${orgId}/billing`, { token: user.token }));
    expect(summary.credits_usd).toBeLessThanOrEqual(0);

    const cred = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: user.token,
        json: {
          org_id: orgId,
          provider: "openai",
          label: "My OpenAI",
          api_key: "sk-own-openai-1234",
        },
      }),
    );
    expect(cred.id).toBeDefined();

    // Set workspace default to the own key.
    const patchedOrg = await j(
      await h.request(`/v1/orgs/${orgId}`, {
        method: "PATCH",
        token: user.token,
        json: {
          model_default: {
            source: "own",
            credential_id: cred.id,
            model: "fixture-main",
          },
        },
      }),
    );
    expect(patchedOrg.model_default).toEqual({
      source: "own",
      credential_id: cred.id,
      model: "fixture-main",
    });

    // Create a bot following the workspace default.
    const bot = await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: user.token,
        json: { org_id: orgId, name: "OwnKeyBot" },
      }),
    );
    expect(bot.model_policy.primary.credential_id).toBe(cred.id);

    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: user.token,
        json: { bot_id: bot.id },
      }),
    );
    const sent = await j(
      await h.request(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token: user.token,
        json: { text: "hello" },
      }),
    );
    const run = await waitRun(sent.run_id, user.token);
    expect(run.status).toBe("completed");

    // Token usage rows for this run must be non-billable (billable = false).
    const rows = await h.handle.db.execute<{ billable: boolean; source: string }>(sql`
      select billable, source from public.usage_ledger
      where run_id = ${sent.run_id}::uuid and kind in ('tokens_in', 'tokens_out')`);
    expect(rows.length).toBeGreaterThan(0);
    expect(rows.every((r) => r.billable === false && r.source === "key")).toBe(true);
  }, 60_000);

  it("refuses Free runs on Casama's key with own_provider_required when Free is off, while Pro runs and own-key Free runs succeed", async () => {
    await h.request("/v1/admin/model-access", {
      method: "PUT",
      token: adminOwner.token,
      json: {
        own_providers: true,
        casama_models: { default: "on", plans: { free: "off", pro: "on" } },
        note: "Free workspaces now use your own model key.",
      },
    });

    // 1. Free workspace without an own key: billing summary reports casama_models = "off",
    //    /v1/credentials omits Casama Cloud, and a run fails with own_provider_required.
    const { orgId: freeOrg, user: freeUser } = await newOrg("Free Blocked");
    const freeBilling = await j(
      await h.request(`/v1/orgs/${freeOrg}/billing`, { token: freeUser.token }),
    );
    expect(freeBilling.casama_models).toBe("off");
    expect(freeBilling.casama_models_note).toBe("Free workspaces now use your own model key.");

    const freeCreds = await j(
      await h.request(`/v1/credentials?org_id=${freeOrg}`, { token: freeUser.token }),
    );
    expect(
      freeCreds.items.some((c: { id: string }) => c.id === PLATFORM_OPENROUTER_CREDENTIAL_ID),
    ).toBe(false);

    // Insert a bot that was created before the switch (pointing at Casama's key).
    const [freeBot] = await h.handle.db.execute<{ id: string }>(sql`
      insert into public.bots (org_id, created_by, name, model_policy)
      values (${freeOrg}::uuid, ${freeUser.id}::uuid, 'Helper', ${JSON.stringify({
        primary: { credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID, model: "fixture-main" },
      })}::jsonb)
      returning id`);
    const freeConv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: freeUser.token,
        json: { bot_id: freeBot!.id },
      }),
    );
    const freeSent = await j(
      await h.request(`/v1/conversations/${freeConv.id}/messages`, {
        method: "POST",
        token: freeUser.token,
        json: { text: "hello" },
      }),
    );
    const freeRun = await waitRun(freeSent.run_id, freeUser.token);
    expect(freeRun.status).toBe("failed");
    expect(freeRun.error?.code).toBe("own_provider_required");
    expect(freeRun.error?.message).toContain("Free workspaces now use your own model key.");

    // 2. Adding an own chat key to that same Free workspace automatically unblocks the bot!
    await h.request("/v1/credentials", {
      method: "POST",
      token: freeUser.token,
      json: {
        org_id: freeOrg,
        provider: "openai",
        label: "Backup Key",
        api_key: "sk-free-own-key",
      },
    });
    const freeSent2 = await j(
      await h.request(`/v1/conversations/${freeConv.id}/messages`, {
        method: "POST",
        token: freeUser.token,
        json: { text: "hello again" },
      }),
    );
    const freeRun2 = await waitRun(freeSent2.run_id, freeUser.token);
    expect(freeRun2.status).toBe("completed");

    // 3. Pro workspace without an own key: still runs on Casama's models.
    const { orgId: proOrg, user: proUser } = await newOrg("Pro Allowed");
    await h.handle.db.execute(sql`
      update public.entitlements set plan_code = 'pro' where org_id = ${proOrg}::uuid`);
    const proBilling = await j(
      await h.request(`/v1/orgs/${proOrg}/billing`, { token: proUser.token }),
    );
    expect(proBilling.casama_models).toBe("on");
    const proBot = await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: proUser.token,
        json: { org_id: proOrg, name: "ProBot" },
      }),
    );
    expect(proBot.model_policy.primary.credential_id).toBe(PLATFORM_OPENROUTER_CREDENTIAL_ID);
  }, 60_000);

  it("marks routines waiting_for_model = true on first refusal, skips later ticks silently, and resumes when a key is added", async () => {
    await h.request("/v1/admin/model-access", {
      method: "PUT",
      token: adminOwner.token,
      json: {
        own_providers: true,
        casama_models: { default: "off", plans: {} },
        note: "Bring your own key.",
      },
    });

    const { orgId, user } = await newOrg("Routine Wait Org");
    const [bot] = await h.handle.db.execute<{ id: string }>(sql`
      insert into public.bots (org_id, created_by, name, model_policy)
      values (${orgId}::uuid, ${user.id}::uuid, 'Watchdog', ${JSON.stringify({
        primary: { credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID, model: "fixture-main" },
      })}::jsonb)
      returning id`);
    const [routine] = await h.handle.db.execute<{ id: string }>(sql`
      insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, trigger, enabled, next_run_at)
      values (${orgId}::uuid, ${bot!.id}::uuid, ${user.id}::uuid, 'Morning Check', 'Say hi', '0 * * * *', 'UTC', '{"type":"schedule"}'::jsonb, true, now() - interval '1 minute')
      returning id`);

    // First due tick: claims the routine, enqueues the run, fails with own_provider_required, and marks waiting_for_model = true.
    const claimed1 = await claimDueRoutines(h.handle.db, new Date());
    expect(claimed1.length).toBe(1);
    await h.deps.workflows.startRun(claimed1[0]!);
    const run1 = await waitRun(claimed1[0]!, user.token);
    expect(run1.status).toBe("failed");
    expect(run1.error?.code).toBe("own_provider_required");

    const [after1] = await h.handle.db.execute<{ waiting_for_model: boolean }>(sql`
      select waiting_for_model from public.routines where id = ${routine!.id}::uuid`);
    expect(after1?.waiting_for_model).toBe(true);

    // Move next_run_at back into the past to simulate the next scheduled tick while still waiting.
    await h.handle.db.execute(sql`
      update public.routines set next_run_at = now() - interval '1 minute' where id = ${routine!.id}::uuid`);
    const claimed2 = await claimDueRoutines(h.handle.db, new Date());
    // Skipped silently: no new run created!
    expect(claimed2.length).toBe(0);

    // Now add an own chat key: waiting_for_model is cleared automatically!
    await h.request("/v1/credentials", {
      method: "POST",
      token: user.token,
      json: {
        org_id: orgId,
        provider: "openai",
        label: "Unblock Key",
        api_key: "sk-unblock-routine",
      },
    });
    const [afterKey] = await h.handle.db.execute<{ waiting_for_model: boolean }>(sql`
      select waiting_for_model from public.routines where id = ${routine!.id}::uuid`);
    expect(afterKey?.waiting_for_model).toBe(false);
  }, 60_000);

  it("gates /link/v1/whoami and /link/v1/models/chat/completions when Casama's models are off for the plan", async () => {
    const { orgId, user } = await newOrg("Link Relay Org");
    const createdKey = await j(
      await h.request(`/v1/orgs/${orgId}/link/keys`, {
        method: "POST",
        token: user.token,
        json: { instance_name: "Home Server" },
      }),
    );
    expect(createdKey.key).toBeDefined();

    await h.request("/v1/admin/model-access", {
      method: "PUT",
      token: adminOwner.token,
      json: {
        own_providers: true,
        casama_models: { default: "on", plans: { free: "off" } },
        note: "Add a key on your self-hosted server.",
      },
    });

    const whoami = await j(
      await h.request("/link/v1/whoami", {
        headers: { authorization: `Bearer ${createdKey.key}` },
      }),
    );
    expect(whoami.models).toBe(false);

    const chatRes = await h.request("/link/v1/models/chat/completions", {
      method: "POST",
      headers: {
        authorization: `Bearer ${createdKey.key}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: "deepseek/deepseek-v4.1-flash-1017",
        messages: [{ role: "user", content: "hi" }],
      }),
    });
    expect(chatRes.status).toBe(402);
    const body = await j(chatRes);
    expect(body.code).toBe("own_provider_required");
    expect(body.message).toContain("Add a key on your self-hosted server.");
  });
});
