/** Encryption at rest (D-136): Postgres sees ciphertext; the API reads plaintext; sweep, rotation, data key replacement (D-238), off, KMS. */
import { randomBytes } from "node:crypto";
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import {
  EventBus,
  MemoryService,
  rewrapAllKeys,
  sweepEncryption,
  sweepReplacedKeys,
} from "@casama/agent";
import { AwsKmsKeyWrapper, contentKeys, LocalKeyWrapper } from "@casama/db";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const keyA = randomBytes(32).toString("base64");
const keyB = randomBytes(32).toString("base64");
const keyC = randomBytes(32).toString("base64");
let h: Harness;
let owner: { id: string; token: string };
let orgId = "";
let botId = "";

beforeAll(async () => {
  h = await startHarness({ contentKey: keyA });
  owner = await h.user("crypt@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Sealed" } }),
    )
  ).id;
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Vault" },
      }),
    )
  ).id;
}, 60_000);
afterAll(async () => h?.stop());

const raw = async (q: string, id: string) =>
  (await h.tdb.admin.unsafe(q, [id]))[0] as Record<string, unknown>;

describe("encryption at rest", () => {
  it("seals new writes, sweeps old rows, and the API still reads plaintext", async () => {
    // Before: plaintext rows.
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: botId },
      }),
    );
    await h.request(`/v1/conversations/${conv.id}/messages`, {
      method: "POST",
      token: owner.token,
      json: { text: "My locker code is 4417" },
    });
    const memory = new MemoryService(h.handle.db, null);
    const old = await memory.write({ orgId, botId, kind: "fact", content: "Prefers aisle seats" });
    expect((await raw("select content from public.memories where id = $1", old.id)).content).toBe(
      "Prefers aisle seats",
    );

    expect(
      await j(await h.request(`/v1/orgs/${orgId}/encryption`, { token: owner.token })),
    ).toMatchObject({ mode: "off", available: true, key: null });
    const member = await h.user("crypt-member@example.com");
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
    expect(
      (
        await h.request(`/v1/orgs/${orgId}/encryption`, {
          method: "PUT",
          token: member.token,
          json: { enabled: true },
        })
      ).status,
    ).toBe(403);
    const on = await j(
      await h.request(`/v1/orgs/${orgId}/encryption`, {
        method: "PUT",
        token: owner.token,
        json: { enabled: true },
      }),
    );
    expect(on).toMatchObject({ mode: "encrypting", key: "server_key" });

    // New writes are sealed before they reach Postgres.
    const sent = await j(
      await h.request(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token: owner.token,
        json: { text: "And my PIN is 0000" },
      }),
    );
    const [m] = await h.tdb.admin<
      { content: unknown }[]
    >`select content from public.messages where id = ${sent.message_id}`;
    expect(JSON.stringify(m!.content)).not.toContain("PIN");
    expect(m!.content).toEqual({ $enc: expect.stringMatching(/^enc:v1:/) });
    const fresh = await memory.write({
      orgId,
      botId,
      kind: "fact",
      content: "Allergic to peanuts",
    });
    expect(
      String((await raw("select content from public.memories where id = $1", fresh.id)).content),
    ).toMatch(/^enc:v1:/);
    const bus = new EventBus(h.handle.db);
    await bus.append(sent.run_id, "message.delta", {
      message_id: crypto.randomUUID(),
      text: "secret delta",
    });
    const [ev] = await h.tdb.admin<
      { payload: unknown }[]
    >`select payload from public.run_events where run_id = ${sent.run_id} order by seq desc limit 1`;
    expect(JSON.stringify(ev!.payload)).not.toContain("secret delta");

    // Reads through the API are plaintext.
    const events = await j(
      await h.request(`/v1/runs/${sent.run_id}/events`, { token: owner.token }),
    );
    expect(JSON.stringify(events)).toContain("secret delta");
    const mems = (
      await j(await h.request(`/v1/bots/${botId}/memories`, { token: owner.token }))
    ).items.map((x: { content: string }) => x.content);
    expect(mems).toEqual(expect.arrayContaining(["Allergic to peanuts", "Prefers aisle seats"]));

    // The sweep seals what was written before, then the workspace is fully on.
    expect(await sweepEncryption(h.handle.db)).toBeGreaterThan(0);
    expect(
      String((await raw("select content from public.memories where id = $1", old.id)).content),
    ).toMatch(/^enc:v1:/);
    const plain = await h.tdb
      .admin`select 1 from public.messages where org_id = ${orgId} and not (content ? '$enc')`;
    expect(plain).toHaveLength(0);
    await sweepEncryption(h.handle.db);
    expect(
      (await j(await h.request(`/v1/orgs/${orgId}/encryption`, { token: owner.token }))).mode,
    ).toBe("on");
    const thread = await j(
      await h.request(`/v1/conversations/${conv.id}/thread`, { token: owner.token }),
    );
    expect(JSON.stringify(thread)).toContain("My locker code is 4417");
    // The chats list preview is opened too, never ciphertext.
    const listed = (
      await j(await h.request(`/v1/bots?org_id=${orgId}`, { token: owner.token }))
    ).items.find((b: { id: string }) => b.id === botId);
    expect(listed.last_message.text).toBeTruthy();
    expect(listed.last_message.text).not.toMatch(/enc:v1|\$enc/);
  });

  it("rotation rewraps the data key without rewriting rows", async () => {
    const [before] = await h.tdb.admin<
      { wrapped_key: string; wrapper: string }[]
    >`select wrapped_key, wrapper from public.org_keys where org_id = ${orgId}`;
    const [row] = await h.tdb.admin<
      { id: string; content: string }[]
    >`select id, content from public.memories where org_id = ${orgId} limit 1`;
    contentKeys.configure(new LocalKeyWrapper(keyB, [keyA]));
    const r = await j(
      await h.request(`/v1/orgs/${orgId}/encryption/rotate`, {
        method: "POST",
        token: owner.token,
      }),
    );
    expect(r.rotated_at).not.toBeNull();
    const [after] = await h.tdb.admin<
      { wrapped_key: string; wrapper: string }[]
    >`select wrapped_key, wrapper from public.org_keys where org_id = ${orgId}`;
    expect(after!.wrapper).not.toBe(before!.wrapper);
    expect(after!.wrapped_key).not.toBe(before!.wrapped_key);
    expect((await raw("select content from public.memories where id = $1", row!.id)).content).toBe(
      row!.content,
    );
    // A server with only the new key still reads everything.
    contentKeys.configure(new LocalKeyWrapper(keyB));
    contentKeys.reset();
    await contentKeys.refresh();
    const mems = (
      await j(await h.request(`/v1/bots/${botId}/memories`, { token: owner.token }))
    ).items.map((x: { content: string }) => x.content);
    expect(mems).toContain("Allergic to peanuts");
  });

  it("replacing the data key reseals every row onto a new key, then deletes the old one", async () => {
    const active = async () =>
      (
        await h.tdb.admin<
          { id: string }[]
        >`select id from public.org_keys where org_id = ${orgId} and retired_at is null`
      )[0]!.id;
    const oldKey = await active();
    // About you gets a person's key while they're in a workspace that encrypts (D-169).
    await h.tdb
      .admin`insert into public.user_about (user_id, about) values (${owner.id}, 'Hikes on Sundays')`;
    await h.tdb
      .admin`insert into public.user_facts (user_id, content) values (${owner.id}, 'Has a dog named Miso')`;
    await sweepEncryption(h.handle.db, 500, { recheckOn: false });
    const [oldUserKey] = await h.tdb.admin<
      { id: string }[]
    >`select id from public.user_keys where user_id = ${owner.id}`;
    expect(
      String((await raw("select about from public.user_about where user_id = $1", owner.id)).about),
    ).toMatch(new RegExp(`^enc:v1:${oldUserKey!.id}:`));
    const sealedOld = await h.tdb.admin`
      select 1 from public.memories where org_id = ${orgId} and content like ${`enc:v1:${oldKey}:%`}`;
    expect(sealedOld.length).toBeGreaterThan(0);
    // A value sealed with the old key in a column the worker doesn't know about keeps the key alive.
    const [conv] = await h.tdb.admin<
      { id: string; title: string | null }[]
    >`select id, title from public.conversations where org_id = ${orgId} limit 1`;
    await h.tdb
      .admin`update public.conversations set title = ${contentKeys.sealWith(oldKey, "Stray")} where id = ${conv!.id}`;

    const member = await h.user("crypt-member2@example.com");
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
    expect(
      (
        await h.request(`/v1/orgs/${orgId}/encryption/replace-key`, {
          method: "POST",
          token: member.token,
        })
      ).status,
    ).toBe(403);
    const r = await j(
      await h.request(`/v1/orgs/${orgId}/encryption/replace-key`, {
        method: "POST",
        token: owner.token,
      }),
    );
    expect(r).toMatchObject({ mode: "on", rekeying: true, key: "server_key" });
    const newKey = await active();
    expect(newKey).not.toBe(oldKey);

    // New writes use the new key at once; old rows still read while they wait.
    const memory = new MemoryService(h.handle.db, null);
    const fresh = await memory.write({ orgId, botId, kind: "fact", content: "Takes oat milk" });
    expect(
      String((await raw("select content from public.memories where id = $1", fresh.id)).content),
    ).toMatch(new RegExp(`^enc:v1:${newKey}:`));
    const before = (
      await j(await h.request(`/v1/bots/${botId}/memories`, { token: owner.token }))
    ).items.map((x: { content: string }) => x.content);
    expect(before).toEqual(expect.arrayContaining(["Allergic to peanuts", "Takes oat milk"]));

    // The sweep moves every row; nothing in a covered column is left on the old key.
    expect(await sweepReplacedKeys(h.handle.db)).toBeGreaterThan(0);
    for (const q of [
      `select 1 from public.memories where content like 'enc:v1:${oldKey}:%'`,
      `select 1 from public.messages where content->>'$enc' like 'enc:v1:${oldKey}:%'`,
      `select 1 from public.run_events where payload->>'$enc' like 'enc:v1:${oldKey}:%'`,
      `select 1 from public.user_about where about like 'enc:v1:${oldUserKey!.id}:%'`,
      `select 1 from public.user_facts where content like 'enc:v1:${oldUserKey!.id}:%'`,
    ])
      expect(await h.tdb.admin.unsafe(q)).toHaveLength(0);
    expect(
      String((await raw("select about from public.user_about where user_id = $1", owner.id)).about),
    ).toMatch(/^enc:v1:/);
    // The old keys stay through the grace period.
    expect(await h.tdb.admin`select 1 from public.org_keys where id = ${oldKey}`).toHaveLength(1);
    await h.tdb
      .admin`update public.org_keys set retired_at = now() - interval '1 hour' where id = ${oldKey}`;
    await h.tdb
      .admin`update public.user_keys set retired_at = now() - interval '1 hour' where id = ${oldUserKey!.id}`;
    // The stray value still needs the old workspace key, so only the person's old key goes.
    await sweepReplacedKeys(h.handle.db, 500, { inUseCheckEveryMs: 0 });
    expect(await h.tdb.admin`select 1 from public.org_keys where id = ${oldKey}`).toHaveLength(1);
    expect(
      await h.tdb.admin`select 1 from public.user_keys where id = ${oldUserKey!.id}`,
    ).toHaveLength(0);
    expect(
      (await j(await h.request(`/v1/orgs/${orgId}/encryption`, { token: owner.token }))).rekeying,
    ).toBe(true);
    await h.tdb
      .admin`update public.conversations set title = ${conv!.title} where id = ${conv!.id}`;
    await sweepReplacedKeys(h.handle.db, 500, { inUseCheckEveryMs: 0 });
    expect(await h.tdb.admin`select 1 from public.org_keys where id = ${oldKey}`).toHaveLength(0);
    expect(
      (await j(await h.request(`/v1/orgs/${orgId}/encryption`, { token: owner.token }))).rekeying,
    ).toBe(false);

    // A server that never held the old keys reads everything.
    contentKeys.reset();
    await contentKeys.refresh();
    const after = (
      await j(await h.request(`/v1/bots/${botId}/memories`, { token: owner.token }))
    ).items.map((x: { content: string }) => x.content);
    expect(after).toEqual(
      expect.arrayContaining(["Allergic to peanuts", "Prefers aisle seats", "Takes oat milk"]),
    );
    const thread = await j(
      await h.request(`/v1/conversations/${conv!.id}/thread`, { token: owner.token }),
    );
    expect(JSON.stringify(thread)).not.toMatch(/enc:v1/);
    const about = await j(await h.request("/v1/me/about", { token: owner.token }));
    expect(JSON.stringify(about)).toContain("Hikes on Sundays");
  });

  it("changing the server key rewraps people's About you keys too", async () => {
    contentKeys.configure(new LocalKeyWrapper(keyC, [keyB]));
    expect(await rewrapAllKeys(h.handle.db)).toBeGreaterThanOrEqual(2);
    // Drop the previous key: everything still loads and reads.
    contentKeys.configure(new LocalKeyWrapper(keyC));
    contentKeys.reset();
    await contentKeys.refresh();
    const about = await j(await h.request("/v1/me/about", { token: owner.token }));
    expect(JSON.stringify(about)).toContain("Hikes on Sundays");
    const mems = (
      await j(await h.request(`/v1/bots/${botId}/memories`, { token: owner.token }))
    ).items.map((x: { content: string }) => x.content);
    expect(mems).toContain("Takes oat milk");
  });

  it("the instance owner can replace every data key at once", async () => {
    const other = await h.user("crypt-not-admin@example.com");
    expect(
      (await h.request("/v1/admin/encryption/replace-keys", { method: "POST", token: other.token }))
        .status,
    ).toBe(403);
    const r = await j(
      await h.request("/v1/admin/encryption/replace-keys", { method: "POST", token: owner.token }),
    );
    expect(r.workspaces).toBeGreaterThanOrEqual(1);
    expect(r.people).toBeGreaterThanOrEqual(1);
    await sweepReplacedKeys(h.handle.db);
    const retired = await h.tdb.admin<{ id: string }[]>`
      select id from public.org_keys where org_id = ${orgId} and retired_at is not null`;
    expect(retired).toHaveLength(1);
    expect(
      await h.tdb.admin.unsafe(
        `select 1 from public.memories where content like 'enc:v1:${retired[0]!.id}:%'`,
      ),
    ).toHaveLength(0);
  });

  it("turning it off opens every row again and deletes the key", async () => {
    expect(
      (
        await j(
          await h.request(`/v1/orgs/${orgId}/encryption`, {
            method: "PUT",
            token: owner.token,
            json: { enabled: false },
          }),
        )
      ).mode,
    ).toBe("decrypting");
    await sweepEncryption(h.handle.db);
    await sweepEncryption(h.handle.db);
    expect(
      (await j(await h.request(`/v1/orgs/${orgId}/encryption`, { token: owner.token }))).mode,
    ).toBe("off");
    expect(await h.tdb.admin`select 1 from public.org_keys where org_id = ${orgId}`).toHaveLength(
      0,
    );
    const mems = await h.tdb.admin<
      { content: string }[]
    >`select content from public.memories where org_id = ${orgId}`;
    expect(mems.map((x) => x.content).sort()).toEqual([
      "Allergic to peanuts",
      "Prefers aisle seats",
      "Takes oat milk",
    ]);
    const [m] = await h.tdb.admin<
      { content: Array<{ text: string }> }[]
    >`select content from public.messages where org_id = ${orgId} and role = 'user' order by created_at limit 1`;
    expect(m!.content[0]!.text).toBe("My locker code is 4417");
  });

  it("AWS KMS wraps and unwraps data keys with signed requests", async () => {
    const seen: Array<{ target: string; auth: string }> = [];
    const kms: Server = createServer(async (req, res) => {
      const chunks: Buffer[] = [];
      for await (const c of req) chunks.push(c as Buffer);
      const body = JSON.parse(Buffer.concat(chunks).toString());
      const target = String(req.headers["x-amz-target"]);
      seen.push({ target, auth: String(req.headers.authorization) });
      // A toy KMS: the "ciphertext" is the plaintext reversed, base64.
      const flip = (b64: string) =>
        Buffer.from(Buffer.from(b64, "base64").reverse()).toString("base64");
      res.writeHead(200, { "content-type": "application/x-amz-json-1.1" });
      res.end(
        JSON.stringify(
          target.endsWith("Encrypt")
            ? { CiphertextBlob: flip(body.Plaintext) }
            : { Plaintext: flip(body.CiphertextBlob) },
        ),
      );
    }).listen(0, "127.0.0.1");
    await once(kms, "listening");
    const w = new AwsKmsKeyWrapper({
      keyId: "alias/casama",
      region: "us-east-1",
      accessKeyId: "AKIDEXAMPLE",
      secretAccessKey: "secret",
      endpoint: `http://127.0.0.1:${(kms.address() as AddressInfo).port}`,
    });
    const dek = randomBytes(32);
    const wrapped = await w.wrap(dek);
    expect((await w.unwrap(wrapped)).equals(dek)).toBe(true);
    expect(w.id).toBe("kms:alias/casama");
    expect(seen.map((s) => s.target)).toEqual(["TrentService.Encrypt", "TrentService.Decrypt"]);
    expect(seen[0]!.auth).toMatch(
      /^AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE\/\d{8}\/us-east-1\/kms\/aws4_request, SignedHeaders=content-type;host;x-amz-date;x-amz-target, Signature=[0-9a-f]{64}$/,
    );
    kms.close();
  });
});
