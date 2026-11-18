import { generateKeyPairSync } from "node:crypto";
import { expect, it } from "vitest";
import { eraseGa4User } from "../src/services/analytics-erase.ts";

const { privateKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
const account = JSON.stringify({
  client_email: "erase@casama.iam.gserviceaccount.com",
  private_key: privateKey.export({ type: "pkcs8", format: "pem" }).toString(),
});

it("asks GA4 to delete the person by user id and derived client id, and does nothing when off", async () => {
  const calls: { url: string; init: RequestInit }[] = [];
  const fake = (async (url: string, init: RequestInit) => {
    calls.push({ url, init });
    if (url.includes("oauth2")) return Response.json({ access_token: "tok" });
    return Response.json({});
  }) as unknown as typeof fetch;
  const on = { enabled: true, propertyId: "123456", serviceAccountJson: account, fetch: fake };

  expect(await eraseGa4User("user-1", on)).toBe("queued");
  expect(calls[0]?.url).toBe("https://oauth2.googleapis.com/token");
  const upserts = calls.slice(1).map((c) => JSON.parse(String(c.init.body)));
  expect(upserts.map((u) => u.id.type)).toEqual(["USER_ID", "CLIENT_ID"]);
  expect(upserts[0]).toEqual({
    kind: "analytics#userDeletionRequest",
    id: { type: "USER_ID", userId: "user-1" },
    propertyId: "123456",
  });
  expect(((calls[1]?.init.headers ?? {}) as Record<string, string>).authorization).toBe(
    "Bearer tok",
  );

  expect(await eraseGa4User("user-1", { ...on, enabled: false })).toBe("skipped");
  expect(await eraseGa4User("user-1", { ...on, propertyId: "" })).toBe("skipped");
  expect(calls).toHaveLength(3);

  const failing = (async (url: string) =>
    url.includes("oauth2")
      ? Response.json({ access_token: "t" })
      : new Response("no", { status: 403 })) as unknown as typeof fetch;
  await expect(eraseGa4User("user-1", { ...on, fetch: failing })).rejects.toThrow("403");
});
