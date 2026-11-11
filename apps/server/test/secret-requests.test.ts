/** Ask for a secret in chat (D-101): the run waits, the value goes to Vault and never into the run. */
import { fileURLToPath } from "node:url";
import { checkSecretHosts, registrableDomain } from "@casama/agent";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/secrets.json", import.meta.url));
const SECRET = "sk_live_super_secret_value_123";
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

let h: Harness;
let owner: { id: string; token: string };
let member: { id: string; token: string };
let orgId: string;
let botId: string;

const chat = async (token: string, text: string) => {
  const conv = await j(
    await h.request("/v1/conversations", { method: "POST", token, json: { bot_id: botId } }),
  );
  const sent = await j(
    await h.request(`/v1/conversations/${conv.id}/messages`, {
      method: "POST",
      token,
      json: { text },
    }),
  );
  return sent.run_id as string;
};
const waitStatus = async (runId: string, status: string) => {
  const until = Date.now() + 15_000;
  for (;;) {
    const r = await j(await h.request(`/v1/runs/${runId}`, { token: owner.token }));
    if (r.status === status) return r;
    if (Date.now() > until)
      throw new Error(`run is ${r.status}, wanted ${status}: ${JSON.stringify(r.error)}`);
    await sleep(150);
  }
};

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  owner = await h.user("secrets-owner@example.com");
  member = await h.user("secrets-member@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Keys" } }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
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
          name: "Biller",
          autonomy: "autonomous",
          visibility: "team",
          model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
        },
      }),
    )
  ).id;
}, 60_000);
afterAll(async () => h?.stop());

describe("hosts", () => {
  it("must belong to one service", () => {
    expect(registrableDomain("api.stripe.com")).toBe("stripe.com");
    expect(registrableDomain("api.example.co.uk")).toBe("example.co.uk");
    expect(checkSecretHosts(["API.stripe.com", "files.stripe.com"])).toEqual([
      "api.stripe.com",
      "files.stripe.com",
    ]);
    expect(() => checkSecretHosts(["api.stripe.com", "evil.example"])).toThrow(/one service/);
    expect(() => checkSecretHosts(["not a host"])).toThrow(/host name/);
  });
});

describe("secrets.request", () => {
  it("waits for the value, stores it for that bot and hosts, and never shows it to the run", async () => {
    const runId = await chat(member.token, "Please charge the customer $20.");
    await waitStatus(runId, "waiting_approval");
    const open = await j(
      await h.request(`/v1/secrets/requests?org_id=${orgId}`, { token: member.token }),
    );
    expect(open.items).toHaveLength(1);
    const ask = open.items[0];
    expect(ask).toMatchObject({
      name: "STRIPE_API_KEY",
      service: "Stripe",
      allowed_hosts: ["api.stripe.com"],
      status: "pending",
    });
    const [note] = await h.handle.db.execute<{ payload: { link: string } }>(
      sql`select payload from public.notifications where kind = 'secret' limit 1`,
    );
    expect(note?.payload.link).toContain(`/bots/${botId}/chat`);

    const outsider = await h.user("secrets-outsider@example.com");
    expect(
      (
        await h.request(`/v1/secrets/requests/${ask.id}/fulfill`, {
          method: "POST",
          token: outsider.token,
          json: { value: SECRET },
        })
      ).status,
    ).toBe(404);
    const res = await h.request(`/v1/secrets/requests/${ask.id}/fulfill`, {
      method: "POST",
      token: member.token,
      json: { value: SECRET },
    });
    expect(res.status).toBe(200);
    expect(JSON.stringify(await j(res))).not.toContain(SECRET);
    await waitStatus(runId, "completed");

    const [s] = await h.tdb.admin<{ allowed_hosts: string[]; allowed_bot_ids: string[] }[]>`
      select allowed_hosts, allowed_bot_ids from public.secrets where org_id = ${orgId} and name = 'STRIPE_API_KEY'`;
    expect(s).toEqual({ allowed_hosts: ["api.stripe.com"], allowed_bot_ids: [botId] });
    const leaks = await h.tdb.admin<{ n: number }[]>`
      select (select count(*) from public.run_events where payload::text like ${`%${SECRET}%`})
           + (select count(*) from public.messages where content::text like ${`%${SECRET}%`})
           + (select count(*) from public.audit_log where metadata::text like ${`%${SECRET}%`}) as n`;
    expect(Number(leaks[0]?.n)).toBe(0);
    const evs = (
      await j(await h.request(`/v1/runs/${runId}/events?limit=1000`, { token: owner.token }))
    ).items as Array<{
      type: string;
      payload: Record<string, unknown>;
    }>;
    expect(evs.find((e) => e.type === "secret.resolved")?.payload).toMatchObject({
      outcome: "fulfilled",
    });
    expect(JSON.stringify(evs.find((e) => e.type === "tool.completed")?.payload)).toContain(
      "Saved STRIPE_API_KEY for Stripe",
    );
    expect(
      (
        await h.request(`/v1/secrets/requests/${ask.id}/fulfill`, {
          method: "POST",
          token: member.token,
          json: { value: "x" },
        })
      ).status,
    ).toBe(409);
  });

  it("declining resumes the bot with that answer", async () => {
    await h.tdb.admin`delete from public.secrets where name = 'STRIPE_API_KEY'`;
    const runId = await chat(member.token, "Please charge the customer again.");
    await waitStatus(runId, "waiting_approval");
    const open = await j(
      await h.request(`/v1/secrets/requests?org_id=${orgId}`, { token: owner.token }),
    );
    const res = await h.request(`/v1/secrets/requests/${open.items[0].id}/decline`, {
      method: "POST",
      token: owner.token,
    });
    expect(res.status).toBe(200);
    await waitStatus(runId, "completed");
    const evs = (
      await j(await h.request(`/v1/runs/${runId}/events?limit=1000`, { token: owner.token }))
    ).items as Array<{
      type: string;
      payload: Record<string, unknown>;
    }>;
    expect(evs.find((e) => e.type === "secret.resolved")?.payload).toMatchObject({
      outcome: "declined",
    });
  });

  it("refuses hosts from more than one service without waiting", async () => {
    const runId = await chat(owner.token, "Use a key for two services.");
    await waitStatus(runId, "completed");
    const [n] = await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.secret_requests where name = 'MIXED_KEY'`;
    expect(n?.n).toBe(0);
  });

  it("asks for a sign-in code seed and checks it is one (D-102)", async () => {
    const runId = await chat(owner.token, "Please sign in with a code.");
    await waitStatus(runId, "waiting_approval");
    const open = await j(
      await h.request(`/v1/secrets/requests?org_id=${orgId}`, { token: owner.token }),
    );
    const ask = open.items.find((x: { name: string }) => x.name === "ACME_2FA");
    expect(ask.kind).toBe("totp");
    const bad = await h.request(`/v1/secrets/requests/${ask.id}/fulfill`, {
      method: "POST",
      token: owner.token,
      json: { value: "nope!" },
    });
    expect(bad.status).toBe(400);
    const ok = await h.request(`/v1/secrets/requests/${ask.id}/fulfill`, {
      method: "POST",
      token: owner.token,
      json: { value: "otpauth://totp/Acme:ada?secret=JBSWY3DPEHPK3PXP" },
    });
    expect(ok.status).toBe(200);
    await waitStatus(runId, "completed");
    const list = await j(await h.request(`/v1/secrets?org_id=${orgId}`, { token: owner.token }));
    expect(list.items.find((x: { name: string }) => x.name === "ACME_2FA")?.kind).toBe("totp");
    const evs = (
      await j(await h.request(`/v1/runs/${runId}/events?limit=1000`, { token: owner.token }))
    ).items as Array<{
      type: string;
      payload: Record<string, unknown>;
    }>;
    expect(JSON.stringify(evs)).toContain("{{totp:ACME_2FA}}");
    expect(JSON.stringify(evs)).not.toContain("JBSWY3DPEHPK3PXP");
  });

  it("admins add sign-in code secrets only with a valid seed", async () => {
    const bad = await h.request("/v1/secrets", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: orgId,
        name: "BAD_2FA",
        kind: "totp",
        value: "otpauth://hotp/x?secret=JBSWY3DPEHPK3PXP",
        allowed_hosts: ["x.example"],
      },
    });
    expect(bad.status).toBe(400);
    expect((await j(bad)).code).toBe("invalid_totp");
    const good = await j(
      await h.request("/v1/secrets", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "GH_2FA",
          kind: "totp",
          value: "JBSWY3DPEHPK3PXP",
          allowed_hosts: ["github.com"],
        },
      }),
    );
    expect(good.kind).toBe("totp");
  });
});
