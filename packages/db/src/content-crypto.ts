/**
 * Encryption at rest (SPEC: Encryption at rest; D-136). Envelope encryption with AES-256-GCM:
 * each workspace has a data key, wrapped by the server's key (CONTENT_ENCRYPTION_KEY) or AWS KMS.
 * Postgres only sees ciphertext for the covered columns:
 * - text: `enc:v1:<keyId>:<base64(iv | ciphertext | tag)>`
 * - jsonb: `{"$enc": "enc:v1:..."}`
 * Reads are decrypted transparently by the database client (a postgres.js value transform) from a
 * key ring kept in memory and refreshed when keys change (LISTEN kasama_org_keys).
 */
import { createCipheriv, createDecipheriv, createHash, createHmac, randomBytes } from "node:crypto";
import type postgres from "postgres";

const PREFIX = "enc:v1:";

/** Wraps and unwraps data keys. */
export interface KeyWrapper {
  /** Recorded with each wrapped key, so rotation knows which wrapper made it. */
  readonly id: string;
  wrap(dataKey: Buffer): Promise<string>;
  unwrap(wrapped: string, wrapperId: string): Promise<Buffer>;
}

function gcmSeal(key: Buffer, plain: Buffer) {
  const iv = randomBytes(12);
  const c = createCipheriv("aes-256-gcm", key, iv);
  const ct = Buffer.concat([c.update(plain), c.final()]);
  return Buffer.concat([iv, ct, c.getAuthTag()]);
}
function gcmOpen(key: Buffer, blob: Buffer) {
  const d = createDecipheriv("aes-256-gcm", key, blob.subarray(0, 12));
  d.setAuthTag(blob.subarray(blob.length - 16));
  return Buffer.concat([d.update(blob.subarray(12, blob.length - 16)), d.final()]);
}

/** The server's own key (base64, 32 bytes); older keys still unwrap during a rotation. */
export class LocalKeyWrapper implements KeyWrapper {
  readonly id: string;
  private readonly keys = new Map<string, Buffer>();
  constructor(current: string, previous: string[] = []) {
    const parse = (k: string) => {
      const b = Buffer.from(k, "base64");
      if (b.length !== 32)
        throw new Error("CONTENT_ENCRYPTION_KEY must be 32 bytes, base64-encoded");
      return b;
    };
    const fp = (b: Buffer) => `local:${createHash("sha256").update(b).digest("hex").slice(0, 12)}`;
    const cur = parse(current);
    this.id = fp(cur);
    this.keys.set(this.id, cur);
    for (const p of previous) {
      const b = parse(p);
      this.keys.set(fp(b), b);
    }
  }
  async wrap(dataKey: Buffer) {
    return gcmSeal(this.keys.get(this.id) as Buffer, dataKey).toString("base64");
  }
  async unwrap(wrapped: string, wrapperId: string) {
    const k = this.keys.get(wrapperId);
    if (!k)
      throw new Error(
        `No key for ${wrapperId}; keep the old CONTENT_ENCRYPTION_KEY in CONTENT_ENCRYPTION_KEY_PREVIOUS until rotation finishes`,
      );
    return gcmOpen(k, Buffer.from(wrapped, "base64"));
  }
}

/** AWS KMS Encrypt and Decrypt (JSON 1.1 API, Signature Version 4), from AWS's public docs. */
export class AwsKmsKeyWrapper implements KeyWrapper {
  readonly id: string;
  private readonly o: {
    keyId: string;
    region: string;
    accessKeyId: string;
    secretAccessKey: string;
    sessionToken?: string;
    endpoint: string;
    fetch: typeof fetch;
  };
  constructor(o: {
    keyId: string;
    region: string;
    accessKeyId: string;
    secretAccessKey: string;
    sessionToken?: string;
    endpoint?: string;
    fetch?: typeof fetch;
  }) {
    this.o = {
      ...o,
      endpoint: o.endpoint ?? `https://kms.${o.region}.amazonaws.com`,
      fetch: o.fetch ?? fetch,
    };
    this.id = `kms:${o.keyId}`;
  }

  private async call(target: "Encrypt" | "Decrypt", body: Record<string, unknown>) {
    const url = new URL(this.o.endpoint);
    const payload = JSON.stringify(body);
    const now = new Date();
    const amzDate = now.toISOString().replace(/[:-]|\.\d{3}/g, "");
    const day = amzDate.slice(0, 8);
    const sha = (s: string) => createHash("sha256").update(s).digest("hex");
    const headers: Record<string, string> = {
      "content-type": "application/x-amz-json-1.1",
      host: url.host,
      "x-amz-date": amzDate,
      "x-amz-target": `TrentService.${target}`,
      ...(this.o.sessionToken ? { "x-amz-security-token": this.o.sessionToken } : {}),
    };
    const names = Object.keys(headers).sort();
    const canonical = [
      "POST",
      url.pathname || "/",
      "",
      ...names.map((n) => `${n}:${headers[n]}`),
      "",
      names.join(";"),
      sha(payload),
    ].join("\n");
    const scope = `${day}/${this.o.region}/kms/aws4_request`;
    const toSign = ["AWS4-HMAC-SHA256", amzDate, scope, sha(canonical)].join("\n");
    const hmac = (k: Buffer | string, s: string) => createHmac("sha256", k).update(s).digest();
    const signing = hmac(
      hmac(hmac(hmac(`AWS4${this.o.secretAccessKey}`, day), this.o.region), "kms"),
      "aws4_request",
    );
    const signature = createHmac("sha256", signing).update(toSign).digest("hex");
    const { host: _h, ...send } = headers;
    const res = await this.o.fetch(url.toString(), {
      method: "POST",
      headers: {
        ...send,
        authorization: `AWS4-HMAC-SHA256 Credential=${this.o.accessKeyId}/${scope}, SignedHeaders=${names.join(";")}, Signature=${signature}`,
      },
      body: payload,
    });
    if (!res.ok)
      throw new Error(
        `AWS KMS ${target} failed with ${res.status}: ${(await res.text()).slice(0, 200)}`,
      );
    return (await res.json()) as Record<string, string>;
  }

  async wrap(dataKey: Buffer) {
    const r = await this.call("Encrypt", {
      KeyId: this.o.keyId,
      Plaintext: dataKey.toString("base64"),
    });
    return r.CiphertextBlob as string;
  }
  async unwrap(wrapped: string) {
    const r = await this.call("Decrypt", { CiphertextBlob: wrapped, KeyId: this.o.keyId });
    return Buffer.from(r.Plaintext as string, "base64");
  }
}

export interface OrgKeyRow {
  id: string;
  org_id: string;
  wrapped_key: string;
  wrapper: string;
  /** off, encrypting, on or decrypting (from organizations.content_encryption). */
  mode: string;
}

/** Unwrapped data keys in memory, and which workspaces seal new writes. */
export class KeyRing {
  private wrapper: KeyWrapper | null = null;
  private readonly keys = new Map<string, Buffer>();
  private readonly sealing = new Map<string, string>();
  private sql: postgres.Sql | null = null;
  private listening = false;

  get configured() {
    return this.wrapper !== null;
  }
  get wrapperId() {
    return this.wrapper?.id ?? null;
  }
  configure(wrapper: KeyWrapper | null) {
    this.wrapper = wrapper;
  }
  /** Forgets every key (tests). */
  reset() {
    this.keys.clear();
    this.sealing.clear();
  }

  /** Loads every workspace key; keeps loading when they change. */
  async attach(sql: postgres.Sql) {
    this.sql = sql;
    await this.refresh();
    if (!this.listening) {
      this.listening = true;
      await sql
        .listen("kasama_org_keys", () => void this.refresh().catch(() => {}))
        .catch(() => {
          this.listening = false;
        });
    }
  }

  async refresh() {
    if (!this.sql || !this.wrapper) return;
    const rows = await this.sql<OrgKeyRow[]>`
      select k.id, k.org_id, k.wrapped_key, k.wrapper, o.content_encryption as mode
      from public.org_keys k join public.organizations o on o.id = k.org_id`;
    this.sealing.clear();
    for (const r of rows) await this.add(r);
  }

  async add(r: OrgKeyRow) {
    if (!this.wrapper) throw new Error("Encryption at rest isn't configured on this server");
    if (!this.keys.has(r.id))
      this.keys.set(r.id, await this.wrapper.unwrap(r.wrapped_key, r.wrapper));
    if (r.mode === "encrypting" || r.mode === "on") this.sealing.set(r.org_id, r.id);
    else this.sealing.delete(r.org_id);
  }

  /** A new data key, wrapped (the caller stores it). */
  async newKey() {
    if (!this.wrapper) throw new Error("Encryption at rest isn't configured on this server");
    const dek = randomBytes(32);
    return { dek, wrapped: await this.wrapper.wrap(dek), wrapper: this.wrapper.id };
  }
  async rewrap(wrapped: string, wrapperId: string) {
    if (!this.wrapper) throw new Error("Encryption at rest isn't configured on this server");
    return {
      wrapped: await this.wrapper.wrap(await this.wrapper.unwrap(wrapped, wrapperId)),
      wrapper: this.wrapper.id,
    };
  }

  /** Whether any workspace seals writes (a cheap check before looking one up). */
  get anySealing() {
    return this.sealing.size > 0;
  }

  /** Whether new writes for this workspace are sealed. */
  seals(orgId: string | null | undefined) {
    return !!orgId && this.sealing.has(orgId);
  }

  /** Text for a covered column: ciphertext when the workspace encrypts, else unchanged. */
  seal<T extends string | null | undefined>(orgId: string | null | undefined, text: T): T {
    if (text === null || text === undefined || !orgId || isSealed(text)) return text;
    const id = this.sealing.get(orgId);
    if (!id) return text;
    return this.sealWith(id, text) as T;
  }
  sealWith(keyId: string, text: string) {
    const key = this.keys.get(keyId) as Buffer;
    return `${PREFIX}${keyId}:${gcmSeal(key, Buffer.from(text, "utf8")).toString("base64")}`;
  }

  /** JSON text for a covered jsonb column (pass it as `${...}::jsonb`). */
  sealJson(orgId: string | null | undefined, value: unknown): string {
    const json = typeof value === "string" ? value : JSON.stringify(value);
    if (!orgId || !this.sealing.has(orgId)) return json;
    return JSON.stringify({ $enc: this.seal(orgId, json) });
  }

  /** Decrypts a value read from the database; anything else passes through. */
  open(value: unknown): unknown {
    if (typeof value === "string") {
      if (!value.startsWith(PREFIX)) return value;
      return this.openText(value) ?? value;
    }
    if (value && typeof value === "object" && !Array.isArray(value)) {
      const enc = (value as { $enc?: unknown }).$enc;
      if (typeof enc === "string" && enc.startsWith(PREFIX)) {
        const t = this.openText(enc);
        if (t === null) return value;
        try {
          return JSON.parse(t);
        } catch {
          return value;
        }
      }
    }
    return value;
  }

  openText(sealed: string): string | null {
    const rest = sealed.slice(PREFIX.length);
    const i = rest.indexOf(":");
    const key = this.keys.get(rest.slice(0, i));
    if (!key) {
      // A key this process hasn't loaded yet: refresh for next time.
      void this.refresh().catch(() => {});
      return null;
    }
    try {
      return gcmOpen(key, Buffer.from(rest.slice(i + 1), "base64")).toString("utf8");
    } catch {
      return null;
    }
  }
}

export const isSealed = (v: unknown) =>
  (typeof v === "string" && v.startsWith(PREFIX)) ||
  (!!v && typeof v === "object" && typeof (v as { $enc?: unknown }).$enc === "string");

/** The process-wide key ring (the API and the worker configure it at startup). */
export const contentKeys = new KeyRing();
