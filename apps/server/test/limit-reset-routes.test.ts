import { afterAll, beforeAll, expect, it } from "vitest";
import { type Harness, startHarness } from "./helpers.ts";

let h: Harness;
let token: string;
let admin: { token: string };
beforeAll(async () => {
  h = await startHarness({ env: { INSTANCE_ADMIN_EMAILS: "reset-instance-owner@example.com" } });
  token = (await h.user("ordinary-reset-user@example.com")).token;
  admin = await h.user("reset-instance-owner@example.com");
}, 120000);
afterAll(async () => h?.stop());
it("refuses every admin route before accessing saved-reset state", async () => {
  const id = "11111111-1111-4111-8111-111111111111";
  for (const [method, path] of [
    ["GET", ""],
    ["GET", "/settings"],
    ["GET", "/events"],
    ["GET", `/workspaces/${id}`],
  ]) {
    const r = await h.request(`/v1/admin/limit-resets${path}`, { method, token });
    expect(r.status).toBe(403);
  }
  const r = await h.request("/v1/admin/limit-resets/settings", {
    method: "PUT",
    token,
    json: { enabled: true, per_period: 1, max_held: 3, notify_owners: true },
  });
  expect(r.status).toBe(403);
});
it("rejects writes and CSV export for ordinary users and hosted tools", async () => {
  const id = "11111111-1111-4111-8111-111111111111";
  const input = {
    name: "Denied",
    message: "Denied",
    audience: {},
    starts_at: "2026-11-20T00:00:00Z",
    expires_at: "2026-12-04T00:00:00Z",
  };
  for (const [method, path, json] of [
    ["POST", "", input],
    ["POST", "/preview", input],
    ["PUT", `/${id}`, input],
    ["POST", `/${id}/action`, { action: "cancel" }],
    ["POST", `/workspaces/${id}`, input],
    ["POST", `/resets/${id}/action`, { action: "undo" }],
    ["GET", "/events.csv", undefined],
  ] as const) {
    const response = await h.request(`/v1/admin/limit-resets${path}`, { method, token, json });
    expect(response.status).toBe(403);
  }
  const response = await h.app.request(
    "/v1/admin/limit-resets/settings",
    {},
    { casamaClaims: { sub: id } },
  );
  expect(response.status).toBe(403);
});
it("allows the instance owner to change settings and export the resulting audit event", async () => {
  const r = await h.request("/v1/admin/limit-resets/settings", {
    method: "PUT",
    token: admin.token,
    json: { enabled: true, per_period: 2, max_held: 4, notify_owners: false },
  });
  expect(r.status).toBe(200);
  const csv = await h.request("/v1/admin/limit-resets/events.csv", { token: admin.token });
  expect(csv.status).toBe(200);
  expect(csv.headers.get("content-type")).toContain("text/csv");
  expect(await csv.text()).toContain('"settings"');
});
it("refuses a one-off reset while saved resets are switched off", async () => {
  const off = await h.request("/v1/admin/limit-resets/settings", {
    method: "PUT",
    token: admin.token,
    json: { enabled: false, per_period: 1, max_held: 3, notify_owners: false },
  });
  expect(off.status).toBe(200);
  const r = await h.request(`/v1/admin/limit-resets/workspaces/${crypto.randomUUID()}`, {
    method: "POST",
    token: admin.token,
    json: {
      name: "One-off",
      message: "Sorry about that",
      audience: {},
      starts_at: new Date(Date.now() - 1000).toISOString(),
      expires_at: new Date(Date.now() + 86400000).toISOString(),
    },
  });
  expect(r.status).toBe(409);
  expect(JSON.stringify(await r.json())).toContain("Turn saved resets on");
});
