/**
 * Audit-log forwarding (D-146, enterprise): each forwarder streams its workspace's audit_log rows
 * to a signed webhook, an OTLP/HTTP logs endpoint, or S3-compatible storage. Rows go in order from
 * a (created_at, id) cursor, which moves only after the destination accepts a batch, so delivery is
 * at least once. Shapes follow the public OTLP/HTTP JSON and S3 (Signature Version 4) specs.
 */
import { createHash, createHmac } from "node:crypto";
import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";

export type AuditRow = {
  id: string;
  created_at: string;
  org_id: string;
  actor_type: string;
  actor_id: string | null;
  action: string;
  target_type: string | null;
  target_id: string | null;
  metadata: Record<string, unknown> | null;
};

export type Forwarder = {
  id: string;
  org_id: string;
  kind: "webhook" | "otlp" | "s3";
  config: { url?: string; endpoint?: string; region?: string; bucket?: string; prefix?: string };
  secret: string | null;
  cursor_at: string | null;
  cursor_id: string | null;
};

const iso = (v: string | Date) => new Date(v).toISOString();

/** Webhook: JSON body, with X-Kasama-Signature t=<unix>,v1=<hex HMAC-SHA256 of "t.body">. */
export function signAuditBatch(secret: string, body: string, t = Math.floor(Date.now() / 1000)) {
  return `t=${t},v1=${createHmac("sha256", secret).update(`${t}.${body}`).digest("hex")}`;
}

export function otlpLogs(rows: AuditRow[]) {
  const attr = (key: string, v: unknown) => ({ key, value: { stringValue: typeof v === "string" ? v : JSON.stringify(v ?? null) } });
  return {
    resourceLogs: [
      {
        resource: { attributes: [attr("service.name", "kasama"), attr("kasama.org_id", rows[0]?.org_id ?? "")] },
        scopeLogs: [
          {
            scope: { name: "kasama.audit" },
            logRecords: rows.map((r) => ({
              timeUnixNano: String(BigInt(new Date(r.created_at).getTime()) * 1_000_000n),
              severityText: "INFO",
              body: { stringValue: r.action },
              attributes: [
                attr("audit.id", r.id),
                attr("audit.actor_type", r.actor_type),
                attr("audit.actor_id", r.actor_id ?? ""),
                attr("audit.target_type", r.target_type ?? ""),
                attr("audit.target_id", r.target_id ?? ""),
                attr("audit.metadata", r.metadata ?? {}),
              ],
            })),
          },
        ],
      },
    ],
  };
}

/** PUT an object with Signature Version 4 (path-style, so MinIO and R2 endpoints work too). */
async function s3Put(o: { endpoint?: string; region: string; bucket: string; key: string; accessKeyId: string; secretAccessKey: string; body: string; fetch: typeof fetch }) {
  const base = (o.endpoint ?? `https://s3.${o.region}.amazonaws.com`).replace(/\/$/, "");
  const url = new URL(`${base}/${o.bucket}/${o.key.split("/").map(encodeURIComponent).join("/")}`);
  const now = new Date();
  const amzDate = now.toISOString().replace(/[:-]|\.\d{3}/g, "");
  const day = amzDate.slice(0, 8);
  const sha = (s: string) => createHash("sha256").update(s).digest("hex");
  const payloadHash = sha(o.body);
  const headers: Record<string, string> = { host: url.host, "x-amz-content-sha256": payloadHash, "x-amz-date": amzDate, "content-type": "application/x-ndjson" };
  const names = Object.keys(headers).sort();
  const canonical = ["PUT", url.pathname, "", ...names.map((n) => `${n}:${headers[n]}`), "", names.join(";"), payloadHash].join("\n");
  const scope = `${day}/${o.region}/s3/aws4_request`;
  const toSign = ["AWS4-HMAC-SHA256", amzDate, scope, sha(canonical)].join("\n");
  const hmac = (k: Buffer | string, s: string) => createHmac("sha256", k).update(s).digest();
  const signing = hmac(hmac(hmac(hmac(`AWS4${o.secretAccessKey}`, day), o.region), "s3"), "aws4_request");
  const signature = createHmac("sha256", signing).update(toSign).digest("hex");
  const { host: _h, ...send } = headers;
  return o.fetch(url.toString(), {
    method: "PUT",
    headers: { ...send, authorization: `AWS4-HMAC-SHA256 Credential=${o.accessKeyId}/${scope}, SignedHeaders=${names.join(";")}, Signature=${signature}` },
    body: o.body,
  });
}

/** Sends one batch to a forwarder's destination; throws when it isn't accepted. */
export async function sendBatch(f: Forwarder, rows: AuditRow[], fetchFn: typeof fetch = fetch) {
  const events = rows.map((r) => ({ ...r, created_at: iso(r.created_at) }));
  if (f.kind === "webhook") {
    const body = JSON.stringify({ forwarder_id: f.id, events });
    const res = await fetchFn(String(f.config.url), {
      method: "POST",
      headers: { "content-type": "application/json", "x-kasama-signature": signAuditBatch(f.secret ?? "", body), "x-kasama-batch": `${events[0]?.id}-${events.at(-1)?.id}` },
      body,
    });
    if (!res.ok) throw new Error(`The webhook answered ${res.status}`);
    return;
  }
  if (f.kind === "otlp") {
    let extra: Record<string, string> = {};
    try {
      extra = f.secret ? (JSON.parse(f.secret) as Record<string, string>) : {};
    } catch {}
    const res = await fetchFn(`${String(f.config.url).replace(/\/$/, "").replace(/\/v1\/logs$/, "")}/v1/logs`, {
      method: "POST",
      headers: { "content-type": "application/json", ...extra },
      body: JSON.stringify(otlpLogs(rows)),
    });
    if (!res.ok) throw new Error(`The OTLP endpoint answered ${res.status}`);
    return;
  }
  const creds = JSON.parse(f.secret ?? "{}") as { access_key_id?: string; secret_access_key?: string };
  const first = new Date(rows[0]?.created_at ?? Date.now());
  const key = `${(f.config.prefix ?? "kasama-audit").replace(/\/$/, "")}/${f.org_id}/${first.toISOString().slice(0, 10).replace(/-/g, "/")}/${first.getTime()}-${rows[0]?.id}.jsonl`;
  const res = await s3Put({
    endpoint: f.config.endpoint,
    region: f.config.region ?? "us-east-1",
    bucket: String(f.config.bucket),
    key,
    accessKeyId: creds.access_key_id ?? "",
    secretAccessKey: creds.secret_access_key ?? "",
    body: `${events.map((e) => JSON.stringify(e)).join("\n")}\n`,
    fetch: fetchFn,
  });
  if (!res.ok) throw new Error(`S3 answered ${res.status}: ${(await res.text()).slice(0, 200)}`);
}

/** One pass for every enabled forwarder (the worker runs it every minute when licensed). */
export async function forwardAuditLogs(db: Database, opts: { fetch?: typeof fetch; batch?: number; maxBatches?: number } = {}) {
  const forwarders = await db.execute<Forwarder>(sql`
    select f.id, f.org_id, f.kind, f.config, v.decrypted_secret as secret, f.cursor_at, f.cursor_id
    from public.audit_forwarders f left join vault.decrypted_secrets v on v.id = f.vault_secret_id where f.enabled`);
  let sent = 0;
  for (const f of forwarders) {
    for (let b = 0; b < (opts.maxBatches ?? 10); b++) {
      const rows = await db.execute<AuditRow>(sql`
        select id, created_at, org_id, actor_type, actor_id, action, target_type, target_id, metadata from public.audit_log
        where org_id = ${f.org_id}::uuid
          -- Compared in SQL: timestamps keep their microseconds (JavaScript dates would round them).
          and (created_at, id) > (select coalesce(cursor_at, '-infinity'::timestamptz), coalesce(cursor_id, '00000000-0000-0000-0000-000000000000'::uuid)
                                  from public.audit_forwarders where id = ${f.id}::uuid)
        order by created_at, id limit ${opts.batch ?? 500}`);
      if (!rows.length) break;
      try {
        await sendBatch(f, rows, opts.fetch);
      } catch (e) {
        // The cursor stays put: the same rows go again next time (at least once).
        await db.execute(sql`update public.audit_forwarders set last_error = ${(e as Error).message.slice(0, 500)} where id = ${f.id}::uuid`);
        break;
      }
      const last = rows.at(-1) as AuditRow;
      await db.execute(sql`
        update public.audit_forwarders set cursor_at = (select created_at from public.audit_log where id = ${last.id}::uuid), cursor_id = ${last.id}::uuid,
          sent_rows = sent_rows + ${rows.length}, last_sent_at = now(), last_error = null where id = ${f.id}::uuid`);
      sent += rows.length;
      if (rows.length < (opts.batch ?? 500)) break;
    }
  }
  return sent;
}
