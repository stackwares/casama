/** About you (D-169): the profile API, and the person's own key when a workspace encrypts. */
import { randomBytes } from "node:crypto";
import { savePersonFact, sweepEncryption } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let me: { id: string; token: string };
let orgId = "";

beforeAll(async () => {
  h = await startHarness({ contentKey: randomBytes(32).toString("base64") });
  me = await h.user("profile@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: me.token, json: { name: "Mine" } }),
    )
  ).id;
}, 60_000);
afterAll(async () => h?.stop());

const raw = async (q: string, id: string) =>
  (await h.tdb.admin.unsafe(q, [id]))[0] as Record<string, unknown>;
const call = (path: string, init: { method?: string; json?: unknown } = {}) =>
  h.request(path, { ...init, token: me.token });

describe("About you API", () => {
  it("reads and writes the profile, facts and the per-workspace switch", async () => {
    expect(await j(await call("/v1/me/about"))).toMatchObject({
      preferred_name: null,
      about: "",
      learn: true,
      name_asked: false,
    });
    const saved = await j(
      await call("/v1/me/about", {
        method: "PATCH",
        json: { preferred_name: "  Pat ", pronouns: "they/them", reply_style: "Short." },
      }),
    );
    expect(saved).toMatchObject({
      preferred_name: "Pat",
      pronouns: "they/them",
      reply_style: "Short.",
      name_asked: true,
    });
    // Only the fields sent change.
    expect(
      await j(await call("/v1/me/about", { method: "PATCH", json: { learn: false } })),
    ).toMatchObject({ preferred_name: "Pat", reply_style: "Short.", learn: false });

    const added = await j(
      await call("/v1/me/facts", {
        method: "POST",
        json: {
          items: [
            { content: "Grows tomatoes." },
            { kind: "preference", content: "Tea, not coffee." },
          ],
        },
      }),
    );
    expect(added.items).toHaveLength(2);
    const [first] = added.items;
    expect(
      await j(await call(`/v1/me/facts/${first.id}`, { method: "PATCH", json: { pinned: true } })),
    ).toMatchObject({ pinned: true, content: "Grows tomatoes." });
    expect((await j(await call("/v1/me/facts"))).items[0].id).toBe(first.id);

    // Someone else can't touch it.
    const other = await h.user("other-profile@example.com");
    expect(
      (await h.request(`/v1/me/facts/${first.id}`, { method: "DELETE", token: other.token }))
        .status,
    ).toBe(404);
    expect((await h.request(`/v1/me/profile-spaces/${orgId}`, { token: other.token })).status).toBe(
      404,
    );

    // The only member: shared by default; turning it off sticks.
    expect(await j(await call(`/v1/me/profile-spaces/${orgId}`))).toEqual({
      org_id: orgId,
      shared: true,
    });
    expect(
      await j(
        await call(`/v1/me/profile-spaces/${orgId}`, { method: "PUT", json: { shared: false } }),
      ),
    ).toEqual({ org_id: orgId, shared: false });
    await call(`/v1/me/profile-spaces/${orgId}`, { method: "PUT", json: { shared: true } });

    expect((await call(`/v1/me/facts/${first.id}`, { method: "DELETE" })).status).toBe(200);
    expect((await j(await call("/v1/me/facts"))).items).toHaveLength(1);
    await call("/v1/me/about", { method: "PATCH", json: { about: "Runs a bakery.", learn: true } });
  });

  it("seals the profile with the person's own key while a workspace of theirs encrypts", async () => {
    expect(
      (await call(`/v1/orgs/${orgId}/encryption`, { method: "PUT", json: { enabled: true } }))
        .status,
    ).toBe(200);
    for (let i = 0; i < 3; i++) await sweepEncryption(h.handle.db, 500, { recheckOn: true });

    const [key] = await h.tdb.admin`select id from public.user_keys where user_id = ${me.id}`;
    expect(key).toBeTruthy();
    expect(
      String((await raw("select about from public.user_about where user_id = $1", me.id)).about),
    ).toMatch(/^enc:v1:/);
    const facts = await h.tdb.admin<{ id: string; content: string }[]>`
      select id, content from public.user_facts where user_id = ${me.id}`;
    expect(facts.every((f) => f.content.startsWith("enc:v1:"))).toBe(true);

    // New writes are sealed straight away, from the API and from bots.
    const fresh = await j(
      await call("/v1/me/facts", { method: "POST", json: { items: [{ content: "Has a cat." }] } }),
    );
    expect(
      String(
        (await raw("select content from public.user_facts where id = $1", fresh.items[0].id))
          .content,
      ),
    ).toMatch(/^enc:v1:/);
    const bot = await savePersonFact(h.handle.db, {
      userId: me.id,
      orgId,
      botId: (
        await j(await call("/v1/bots", { method: "POST", json: { org_id: orgId, name: "Pal" } }))
      ).id,
      kind: "fact",
      content: "Lives near the coast.",
    });
    expect(
      String((await raw("select content from public.user_facts where id = $1", bot.id)).content),
    ).toMatch(/^enc:v1:/);

    // The API reads plaintext.
    expect((await j(await call("/v1/me/about"))).about).toBe("Runs a bakery.");
    expect(
      (await j(await call("/v1/me/facts"))).items.map((f: { content: string }) => f.content),
    ).toEqual(expect.arrayContaining(["Tea, not coffee.", "Has a cat.", "Lives near the coast."]));

    // Off again: the rows are opened and the key goes.
    await call(`/v1/orgs/${orgId}/encryption`, { method: "PUT", json: { enabled: false } });
    for (let i = 0; i < 4; i++) await sweepEncryption(h.handle.db, 500, { recheckOn: true });
    expect((await raw("select about from public.user_about where user_id = $1", me.id)).about).toBe(
      "Runs a bakery.",
    );
    const opened = await h.tdb.admin<{ content: string }[]>`
      select content from public.user_facts where user_id = ${me.id}`;
    expect(opened.some((f) => f.content.startsWith("enc:v1:"))).toBe(false);
    expect(
      (await h.tdb.admin`select 1 from public.user_keys where user_id = ${me.id}`).length,
    ).toBe(0);
  });
});
