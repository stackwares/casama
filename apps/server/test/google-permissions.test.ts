/** Google sign-in and permissions (D-130): no restricted scopes in Kasama's own app; inbox through Composio on Cloud. */
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { APP_CATALOG } from "@kasama/domain";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { catalogFor } from "../src/api/routes/apps.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let composio: Server;
const calls: Array<{ path: string; key: string; body: unknown }> = [];

beforeAll(async () => {
  composio = createServer(async (req, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    calls.push({
      path: req.url ?? "",
      key: String(req.headers["x-api-key"]),
      body: chunks.length ? JSON.parse(Buffer.concat(chunks).toString()) : null,
    });
    res.setHeader("content-type", "application/json");
    if (req.url === "/api/v3/auth_configs")
      return res.end(JSON.stringify({ auth_config: { id: "ac_1" } }));
    if (req.url === "/api/v3/connected_accounts")
      return res.end(JSON.stringify({ redirect_url: "https://composio.example/signin/123" }));
    res.writeHead(404).end("{}");
  }).listen(0, "127.0.0.1");
  await once(composio, "listening");
  h = await startHarness({
    env: {
      COMPOSIO_API_KEY: "cmp-key",
      COMPOSIO_API_URL: `http://127.0.0.1:${(composio.address() as AddressInfo).port}`,
    },
  });
}, 60_000);
afterAll(async () => {
  await h?.stop();
  composio?.close();
});

describe("Google permissions", () => {
  it("Kasama's Google apps ask only for non-restricted scopes; the inbox is separate", () => {
    const google = APP_CATALOG.filter((a) => a.category === "google");
    const scopes = google.filter((a) => !a.inbox).flatMap((a) => a.scopes ?? []);
    expect(scopes.sort()).toEqual([
      "https://www.googleapis.com/auth/calendar.events",
      "https://www.googleapis.com/auth/drive.file",
      "https://www.googleapis.com/auth/gmail.send",
    ]);
    expect(google.find((a) => a.inbox)?.scopes).toEqual([
      "https://www.googleapis.com/auth/gmail.modify",
    ]);
  });

  it("on Kasama Cloud the inbox goes through Composio, or is hidden without a key; self-hosted keeps its own client", () => {
    const inbox = (o: { cloud: boolean; composio: boolean }) =>
      catalogFor(APP_CATALOG, o).find((a) => a.id === "gmail_inbox");
    expect(inbox({ cloud: true, composio: false })).toBeUndefined();
    expect(inbox({ cloud: true, composio: true })?.auth).toEqual(["managed"]);
    expect(inbox({ cloud: false, composio: false })?.auth).toEqual(["oauth"]);
  });

  it("connecting the inbox through Composio's managed sign-in returns the sign-in page", async () => {
    const owner = await h.user("google@example.com");
    const orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "G" } }),
      )
    ).id;
    const r = await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, app_id: "gmail_inbox", method: "managed" },
      }),
    );
    expect(r).toMatchObject({
      status: "authorize",
      authorize_url: "https://composio.example/signin/123",
    });
    expect(calls[0]).toMatchObject({
      path: "/api/v3/auth_configs",
      key: "cmp-key",
      body: { toolkit: { slug: "gmail" } },
    });
    expect(calls[1]?.body).toMatchObject({ connection: { user_id: orgId } });
    const [i] = await h.tdb.admin<
      { kind: string; config: { toolkits: string[]; managed: boolean } }[]
    >`select kind, config from public.integrations where org_id = ${orgId}`;
    expect(i).toMatchObject({ kind: "composio", config: { managed: true, toolkits: ["gmail"] } });
  });
});
