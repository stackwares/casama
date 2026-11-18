/** Renaming an authenticator app (two-step sign-in): only your own, and names stay unique. */
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, startHarness } from "./helpers.ts";

let h: Harness;
let ana: { id: string; token: string };
let ben: { id: string; token: string };

beforeAll(async () => {
  h = await startHarness({});
  ana = await h.user("rename-ana@example.com");
  ben = await h.user("rename-ben@example.com");
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

describe("renaming an authenticator", () => {
  it("renames your own factor, keeping its unique suffix, and not someone else's", async () => {
    const mine = randomUUID();
    await h.tdb
      .admin`insert into auth.mfa_factors (id, user_id, friendly_name) values (${mine}, ${ana.id}, 'Authenticator 1 · 1731000000')`;
    const r = await h.request(`/v1/me/two-step/${mine}`, {
      method: "PATCH",
      token: ana.token,
      json: { name: "Work phone" },
    });
    expect(r.status).toBe(204);
    const [f] = await h.tdb.admin<
      { friendly_name: string }[]
    >`select friendly_name from auth.mfa_factors where id = ${mine}`;
    expect(f!.friendly_name).toBe("Work phone · 1731000000");

    const other = await h.request(`/v1/me/two-step/${mine}`, {
      method: "PATCH",
      token: ben.token,
      json: { name: "Mine now" },
    });
    expect(other.status).toBe(404);
  });
});
