/** Password managers (D-128): 1Password Connect and Bitwarden, chosen vaults, logins filled only on their own sites. */
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { registerLoginTools, resolveLoginPlaceholders, ToolRegistry } from "@casama/agent";
import { parseTotp, totpCode } from "@casama/domain";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let pm: Server;
let base = "";
let owner: { id: string; token: string };
let member: { id: string; token: string };
let orgId: string;
let botId: string;
let runId: string;

beforeAll(async () => {
  pm = createServer((req, res) => {
    const u = new URL(req.url ?? "/", "http://x");
    const send = (v: unknown, s = 200) =>
      res.writeHead(s, { "content-type": "application/json" }).end(JSON.stringify(v));
    // 1Password Connect
    if (u.pathname.startsWith("/op/")) {
      if (req.headers.authorization !== "Bearer op-token") return send({}, 401);
      const p = u.pathname.slice(3);
      if (p === "/v1/vaults")
        return send([
          { id: "v-work", name: "Work" },
          { id: "v-home", name: "Home" },
        ]);
      if (p === "/v1/vaults/v-work/items")
        return send([
          {
            id: "i1",
            title: "Expense portal",
            category: "LOGIN",
            vault: { id: "v-work" },
            urls: [{ href: "https://portal.example.com/login" }],
          },
          { id: "i2", title: "Wifi", category: "PASSWORD", vault: { id: "v-work" } },
        ]);
      if (p === "/v1/vaults/v-home/items")
        return send([
          {
            id: "i3",
            title: "Bank",
            category: "LOGIN",
            vault: { id: "v-home" },
            urls: [{ href: "https://bank.example.com" }],
          },
        ]);
      if (p === "/v1/vaults/v-work/items/i1")
        return send({
          id: "i1",
          title: "Expense portal",
          category: "LOGIN",
          vault: { id: "v-work" },
          fields: [
            { purpose: "USERNAME", value: "ana@acme.test" },
            { purpose: "PASSWORD", value: "s3cret-pass" },
            { type: "OTP", value: "otpauth://totp/Portal?secret=JBSWY3DPEHPK3PXP" },
          ],
        });
      return send({}, 404);
    }
    // Bitwarden `bw serve`
    if (u.pathname === "/bw/list/object/collections")
      return send({ success: true, data: { data: [{ id: "c-ops", name: "Ops" }] } });
    if (u.pathname === "/bw/list/object/items" && u.searchParams.get("collectionid") === "c-ops")
      return send({
        success: true,
        data: {
          data: [
            {
              id: "b1",
              name: "Status page",
              type: 1,
              login: { username: "ops", uris: [{ uri: "status.example.com" }] },
            },
          ],
        },
      });
    if (u.pathname === "/bw/object/item/b1")
      return send({
        success: true,
        data: {
          id: "b1",
          name: "Status page",
          type: 1,
          login: { username: "ops", password: "bw-pass" },
        },
      });
    send({}, 404);
  }).listen(0, "127.0.0.1");
  await once(pm, "listening");
  base = `http://127.0.0.1:${(pm.address() as AddressInfo).port}`;
  h = await startHarness();
  owner = await h.user("pm@example.com");
  member = await h.user("pm-member@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "P" } }),
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
          name: "Clerk",
          model_policy: { primary: { credential_id: cred.id, model: "m" } },
        },
      }),
    )
  ).id;
  const [r] = await h.tdb.admin<
    { id: string }[]
  >`insert into public.runs (org_id, bot_id, trigger, status, created_by) values (${orgId}, ${botId}, 'chat', 'running', ${member.id}) returning id`;
  runId = r!.id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
  pm?.close();
});

const run = () => ({ orgId, botId, runId });

describe("password managers", () => {
  let opId: string;

  it("connects 1Password for the workspace (admins only) after checking the token", async () => {
    const bad = await h.request("/v1/password-managers", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: orgId,
        scope: "workspace",
        provider: "1password",
        name: "Team 1Password",
        url: `${base}/op`,
        token: "wrong",
      },
    });
    expect(bad.status).toBe(400);
    expect(
      (
        await h.request("/v1/password-managers", {
          method: "POST",
          token: member.token,
          json: {
            org_id: orgId,
            scope: "workspace",
            provider: "1password",
            name: "x",
            url: `${base}/op`,
            token: "op-token",
          },
        })
      ).status,
    ).toBe(403);
    const created = await j(
      await h.request("/v1/password-managers", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          scope: "workspace",
          provider: "1password",
          name: "Team 1Password",
          url: `${base}/op`,
          token: "op-token",
        },
      }),
    );
    opId = created.id;
    expect(created).toMatchObject({ scope: "workspace", allowed_vaults: [], status: "ok" });
    expect(JSON.stringify(created)).not.toContain("op-token");
    // Nothing is usable until vaults are chosen.
    expect(
      await resolveLoginPlaceholders(h.handle.db, run(), "x", "portal.example.com", {
        fetch,
      }).catch((e) => e.message),
    ).toBe("x");
    await expect(
      resolveLoginPlaceholders(
        h.handle.db,
        run(),
        "{{login:Expense portal:password}}",
        "portal.example.com",
        { fetch },
      ),
    ).rejects.toThrow(/no login named/);
    const vaults = await j(
      await h.request(`/v1/password-managers/${opId}/vaults`, { token: owner.token }),
    );
    expect(
      vaults.items.map((v: { name: string; allowed: boolean }) => `${v.name}:${v.allowed}`),
    ).toEqual(["Work:false", "Home:false"]);
    await h.request(`/v1/password-managers/${opId}`, {
      method: "PATCH",
      token: owner.token,
      json: { allowed_vaults: ["v-work"] },
    });
    const after = await j(
      await h.request(`/v1/password-managers/${opId}/vaults`, { token: owner.token }),
    );
    expect(after.items[0]).toMatchObject({ allowed: true, logins: 1 });
  });

  it("the bot sees [login:Name] and fills values only on the item's own site", async () => {
    const reg = new ToolRegistry();
    registerLoginTools(reg, { db: h.handle.db, fetch });
    const list = await reg
      .get("logins.list")!
      .execute({} as never, { ...run(), output: async () => {}, emit: async () => {} } as never);
    expect(list.content).toBe(
      "[login:Expense portal] https://portal.example.com/login (Team 1Password)",
    );
    expect(list.content).not.toContain("s3cret-pass");
    expect(list.content).not.toContain("Bank");
    const redacted: string[] = [];
    const filled = await resolveLoginPlaceholders(
      h.handle.db,
      run(),
      {
        user: "{{login:Expense portal:username}}",
        pass: "{{login:expense portal:password}}",
        code: "{{login:Expense portal:otp}}",
      },
      "portal.example.com",
      { fetch, onValue: (v) => redacted.push(v), nowMs: 59_000 },
    );
    expect(filled).toEqual({
      user: "ana@acme.test",
      pass: "s3cret-pass",
      code: totpCode(parseTotp("otpauth://totp/Portal?secret=JBSWY3DPEHPK3PXP"), 59_000),
    });
    expect(redacted).toContain("s3cret-pass");
    await expect(
      resolveLoginPlaceholders(
        h.handle.db,
        run(),
        "{{login:Expense portal:password}}",
        "evil.example.net",
        { fetch },
      ),
    ).rejects.toThrow(/only for https:\/\/portal\.example\.com/);
    await expect(
      resolveLoginPlaceholders(h.handle.db, run(), "{{login:Expense portal:password}}", null, {
        fetch,
      }),
    ).rejects.toThrow(/not this destination/);
  });

  it("a person's own Bitwarden works only in runs acting for them", async () => {
    const bw = await j(
      await h.request("/v1/password-managers", {
        method: "POST",
        token: member.token,
        json: {
          org_id: orgId,
          scope: "personal",
          provider: "bitwarden",
          name: "My Bitwarden",
          url: `${base}/bw`,
          token: "",
        },
      }),
    );
    await h.request(`/v1/password-managers/${bw.id}`, {
      method: "PATCH",
      token: member.token,
      json: { allowed_vaults: ["c-ops"] },
    });
    // The owner can't see or change it.
    expect(
      (await j(await h.request(`/v1/password-managers?org_id=${orgId}`, { token: owner.token })))
        .items,
    ).toHaveLength(1);
    expect(
      (await h.request(`/v1/password-managers/${bw.id}`, { method: "DELETE", token: owner.token }))
        .status,
    ).toBe(404);
    expect(
      await resolveLoginPlaceholders(
        h.handle.db,
        run(),
        "{{login:Status page:password}}",
        "status.example.com",
        { fetch },
      ),
    ).toBe("bw-pass");
    const [other] = await h.tdb.admin<
      { id: string }[]
    >`insert into public.runs (org_id, bot_id, trigger, status, created_by) values (${orgId}, ${botId}, 'chat', 'running', ${owner.id}) returning id`;
    await expect(
      resolveLoginPlaceholders(
        h.handle.db,
        { orgId, botId, runId: other!.id },
        "{{login:Status page:password}}",
        "status.example.com",
        { fetch },
      ),
    ).rejects.toThrow(/no login named/);
    expect(
      (await h.request(`/v1/password-managers/${bw.id}`, { method: "DELETE", token: member.token }))
        .status,
    ).toBe(200);
  });
});
