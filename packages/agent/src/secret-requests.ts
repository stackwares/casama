/**
 * Ask for a secret in chat (SPEC: Post-v1 roadmap → Ask for a secret; D-101). `secrets.request`
 * pauses the run (durably, in the run loop) until a person saves the value through a protected card
 * or declines. The run only ever learns "Saved NAME for SERVICE"; the value goes to Vault.
 */
import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";
import { z } from "zod";
import type { EventBus } from "./events.ts";
import type { NotificationService } from "./notifications.ts";
import { ToolError, type ToolRegistry } from "./tools/registry.ts";

export const SECRET_REQUEST_TOOL = "secrets.request";
export const SECRET_REQUEST_TTL_MS = 24 * 3600 * 1000;

const HOST = /^(\*\.)?([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$/;
// Second-level labels under country codes that act as public suffixes (co.uk, com.au, …).
const SECOND_LEVEL = new Set(["co", "com", "net", "org", "gov", "ac", "edu", "or", "ne", "go"]);

/** The registrable domain of a host (example.com, example.co.uk). */
export function registrableDomain(host: string): string {
  const labels = host.toLowerCase().replace(/^\*\./, "").split(".");
  const tld = labels.at(-1) ?? "";
  const sld = labels.at(-2) ?? "";
  const take = tld.length === 2 && SECOND_LEVEL.has(sld) && labels.length >= 3 ? 3 : 2;
  return labels.slice(-take).join(".");
}

export const SecretRequestArgs = z.object({
  name: z
    .string()
    .regex(/^[A-Z][A-Z0-9_]{0,63}$/, "UPPER_SNAKE_CASE, starting with a letter")
    .describe("The secret's name, e.g. STRIPE_API_KEY; use it later as {{secret:NAME}}"),
  service: z.string().min(1).max(80).describe("The service the key is for, e.g. Stripe"),
  allowed_hosts: z
    .array(z.string().min(3).max(253))
    .min(1)
    .max(10)
    .describe("Hosts the secret may be sent to, all of one service (e.g. api.stripe.com)"),
  reason: z.string().max(1000).describe("Why you need it, shown to the person"),
  kind: z
    .enum(["value", "totp"])
    .optional()
    .describe(
      "totp: ask for a two-step sign-in seed instead; then use {{totp:NAME}} where a code goes",
    ),
});
export type SecretRequestArgs = z.infer<typeof SecretRequestArgs>;

/** Checks the hosts: valid names, all under one registrable domain. Returns them normalized. */
export function checkSecretHosts(hosts: string[]): string[] {
  const out = hosts.map((h) => h.trim().toLowerCase());
  const bad = out.find((h) => !HOST.test(h));
  if (bad) throw new ToolError("invalid_host", `${bad} is not a host name (like api.example.com).`);
  const domains = new Set(out.map(registrableDomain));
  if (domains.size > 1)
    throw new ToolError(
      "hosts_not_one_service",
      `allowed_hosts must all belong to one service; got ${[...domains].join(", ")}. Ask for one secret per service.`,
    );
  return [...new Set(out)];
}

export function registerSecretRequestTool(registry: ToolRegistry) {
  registry.register({
    name: SECRET_REQUEST_TOOL,
    description:
      "Ask the person for a secret (an API key, password, or a two-step sign-in seed with kind totp) for one service. They type it into a protected card; it goes straight to the vault and you never see it. You wait until they save or decline, then use it as {{secret:NAME}} in tools that accept secrets, only on the hosts you list. Never ask for secrets in plain chat.",
    risk: "low",
    schema: SecretRequestArgs,
    async execute() {
      throw new ToolError("internal", "secrets.request runs in the run loop");
    },
  });
}

type Bus = () => Promise<EventBus>;

/** Creates the request, marks the run as waiting on a person and notifies who can answer. */
export async function createSecretRequest(
  db: Database,
  info: {
    runId: string;
    orgId: string;
    botId: string;
    botName: string;
    conversationId: string | null;
  },
  args: SecretRequestArgs,
  bus: Bus,
  notifications?: NotificationService,
): Promise<{ id: string } | { error: string }> {
  let hosts: string[];
  try {
    hosts = checkSecretHosts(args.allowed_hosts);
  } catch (err) {
    return { error: (err as Error).message };
  }
  const [row] = await db.execute<{ id: string; expires_at: string }>(sql`
    insert into public.secret_requests (org_id, bot_id, run_id, conversation_id, name, service, allowed_hosts, reason, kind, expires_at)
    values (${info.orgId}::uuid, ${info.botId}::uuid, ${info.runId}::uuid, ${info.conversationId}::uuid, ${args.name},
            ${args.service}, array(select jsonb_array_elements_text(${JSON.stringify(hosts)}::jsonb)), ${args.reason}, ${args.kind ?? "value"},
            now() + make_interval(secs => ${SECRET_REQUEST_TTL_MS / 1000}))
    returning id, expires_at`);
  const id = (row as { id: string }).id;
  await db.execute(sql`update public.runs set status = 'waiting_approval'
    where id = ${info.runId}::uuid and status = 'running'`);
  await (await bus()).append(info.runId, "secret.requested", {
    request_id: id,
    name: args.name,
    service: args.service,
    allowed_hosts: hosts,
    reason: args.reason,
    kind: args.kind ?? "value",
    expires_at: new Date(String(row?.expires_at)).toISOString(),
  });
  if (notifications) {
    const people = await db.execute<{ user_id: string }>(sql`
      select distinct m.user_id from public.runs r join public.memberships m on m.org_id = r.org_id
      where r.id = ${info.runId}::uuid and (m.role in ('owner', 'admin') or m.user_id = r.created_by)`);
    const link = info.conversationId
      ? `/bots/${info.botId}/chat?c=${info.conversationId}`
      : `/bots/${info.botId}/chat`;
    await Promise.all(
      people.map((p) =>
        notifications
          .notify(p.user_id, info.orgId, "secret", {
            title: `${info.botName} needs a ${args.service} key`,
            body: args.reason || `Save ${args.name} so ${info.botName} can continue.`,
            link,
            secret_request_id: id,
          })
          .catch(() => {}),
      ),
    );
  }
  return { id };
}

/** pending | fulfilled | declined | expired | cancelled (expiring it when past due). */
export async function secretRequestState(db: Database, id: string): Promise<string> {
  await db.execute(sql`update public.secret_requests set status = 'expired', resolved_at = now()
    where id = ${id}::uuid and status = 'pending' and expires_at <= now()`);
  const [row] = await db.execute<{ status: string; cancel: Date | null }>(sql`
    select s.status, r.cancel_requested_at as cancel from public.secret_requests s
    join public.runs r on r.id = s.run_id where s.id = ${id}::uuid`);
  if (row?.cancel) return "cancelled";
  return row?.status ?? "expired";
}

/** Ends the wait: resumes the run, records the outcome and returns what the model is told. */
export async function finishSecretRequest(db: Database, runId: string, id: string, bus: Bus) {
  const [r] = await db.execute<{ status: string; name: string; service: string; kind: string }>(sql`
    select status, name, service, kind from public.secret_requests where id = ${id}::uuid`);
  const status = r?.status ?? "expired";
  const outcome =
    status === "fulfilled" ? "fulfilled" : status === "declined" ? "declined" : "expired";
  await db.execute(sql`update public.runs set status = 'running'
    where id = ${runId}::uuid and status = 'waiting_approval'`);
  await (await bus()).append(runId, "secret.resolved", { request_id: id, outcome });
  if (outcome === "fulfilled")
    return r?.kind === "totp"
      ? `Saved the sign-in code seed ${r?.name} for ${r?.service}. Write {{totp:${r?.name}}} where a code goes.`
      : `Saved ${r?.name} for ${r?.service}. Use it as {{secret:${r?.name}}}.`;
  if (outcome === "declined")
    return `The person declined to give ${r?.name}. Continue without it or explain what you need it for.`;
  return `Nobody saved ${r?.name} within 24 hours. Continue without it or ask again later.`;
}
