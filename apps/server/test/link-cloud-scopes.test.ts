/**
 * Cloud computers need a Casama Link key with the computers scope (D-071). A key made by linking
 * (D-296) has only remote_access and push: making a cloud computer says so (link_cloud_off)
 * instead of failing later at Casama Cloud with computers_unavailable.
 */
import { createServer, type Server } from "node:http";
import { SandboxError } from "@casama/sandbox";
import { afterAll, beforeAll, expect, it } from "vitest";
import { sandboxApiError } from "../src/api/routes/computers.ts";
import { cloudKeyHasComputers } from "../src/billing/index.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let cloud: Server;
let cloudUrl = "";
let owner: { id: string; token: string };
let orgId = "";
let botId = "";
let asked = 0;

beforeAll(async () => {
  // A stand-in Casama Cloud: the linked key has remote access and push, the other has computers.
  cloud = createServer((req, res) => {
    asked++;
    const auth = req.headers.authorization ?? "";
    if (req.url !== "/link/v1/whoami" || !auth.startsWith("Bearer ")) {
      res.writeHead(404).end();
      return;
    }
    const key = auth.slice(7);
    if (key === "kcc_unknown") {
      res.writeHead(401, { "content-type": "application/json" }).end("{}");
      return;
    }
    res.writeHead(200, { "content-type": "application/json" }).end(
      JSON.stringify({
        scopes: key === "kcc_full" ? ["computers", "models"] : ["remote_access", "push"],
        computers: key === "kcc_full",
        remote_access: key !== "kcc_full",
        push: key !== "kcc_full",
      }),
    );
  });
  await new Promise<void>((r) => cloud.listen(0, "127.0.0.1", () => r()));
  const addr = cloud.address();
  cloudUrl = `http://127.0.0.1:${typeof addr === "object" && addr ? addr.port : 0}`;
  h = await startHarness({ env: { CASAMA_CLOUD_URL: cloudUrl, CASAMA_CLOUD_KEY: "kcc_linked" } });
  owner = await h.user("cloud-scopes@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Linked" } }),
    )
  ).id;
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Boxer" },
      }),
    )
  ).id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
  await new Promise((r) => cloud?.close(r));
});

it("a linked key without the computers scope can't make a cloud computer", async () => {
  const res = await h.request("/v1/computers", {
    method: "POST",
    token: owner.token,
    json: {
      org_id: orgId,
      kind: "private",
      owner_bot_id: botId,
      name: "Cloud box",
      provider: "casama-cloud",
    },
  });
  expect(res.status).toBe(409);
  const body = await j(res);
  expect(body.code).toBe("link_cloud_off");
  expect(body.detail ?? body.message).toMatch(/doesn't include cloud computers/);
});

it("reads the key's scopes from Casama Cloud, and remembers the answer for a while", async () => {
  expect(await cloudKeyHasComputers({ url: cloudUrl, key: "kcc_full" })).toBe(true);
  expect(await cloudKeyHasComputers({ url: cloudUrl, key: "kcc_unknown" })).toBe(false);
  const before = asked;
  expect(await cloudKeyHasComputers({ url: `${cloudUrl}/`, key: "kcc_full" })).toBe(true);
  expect(asked).toBe(before);
  // A cloud that can't be reached doesn't block: the answer is unknown.
  expect(await cloudKeyHasComputers({ url: "http://127.0.0.1:1", key: "kcc_other" })).toBeNull();
});

it("Casama Cloud refusing the key later is explained the same way", () => {
  const e = sandboxApiError(
    new SandboxError(
      "computers_unavailable",
      "Cloud computers are not available for this key",
      403,
    ),
  );
  expect(e.status).toBe(409);
  expect(e.code).toBe("link_cloud_off");
});
