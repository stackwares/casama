/** Encryption at rest (D-136): Postgres sees ciphertext; the API reads plaintext; sweep, rotation, off, KMS. */
import { randomBytes } from "node:crypto";
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { EventBus, MemoryService, sweepEncryption } from "@kasama/agent";
import { AwsKmsKeyWrapper, contentKeys, LocalKeyWrapper } from "@kasama/db";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const keyA = randomBytes(32).toString("base64");
const keyB = randomBytes(32).toString("base64");
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
      keyId: "alias/kasama",
      region: "us-east-1",
      accessKeyId: "AKIDEXAMPLE",
      secretAccessKey: "secret",
      endpoint: `http://127.0.0.1:${(kms.address() as AddressInfo).port}`,
    });
    const dek = randomBytes(32);
    const wrapped = await w.wrap(dek);
    expect((await w.unwrap(wrapped)).equals(dek)).toBe(true);
    expect(w.id).toBe("kms:alias/kasama");
    expect(seen.map((s) => s.target)).toEqual(["TrentService.Encrypt", "TrentService.Decrypt"]);
    expect(seen[0]!.auth).toMatch(
      /^AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE\/\d{8}\/us-east-1\/kms\/aws4_request, SignedHeaders=content-type;host;x-amz-date;x-amz-target, Signature=[0-9a-f]{64}$/,
    );
    kms.close();
  });
});
