/**
 * Password managers (SPEC: Post-v1 roadmap → Password managers; D-128).
 * - 1Password through a 1Password Connect server (REST, with a service account's Connect token).
 * - Bitwarden through its Vault Management API (`bw serve`), limited to organization collections.
 *
 * Bots refer to logins as {{login:Name:username}}, {{login:Name:password}} and
 * {{login:Name:otp}}. The executor fills them only into tools that accept secrets and only when
 * the destination is one of the item's own URLs; the model sees [login:Name], never the values.
 * One-time codes come from the item's TOTP seed (the sign-in codes flow, D-102).
 */
import type { Database } from "@kasama/db";
import { parseTotp, totpCode } from "@kasama/domain";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "./acting.ts";
import { ToolError, type ToolRegistry } from "./tools/registry.ts";

export interface Vault {
  id: string;
  name: string;
}
export interface LoginItem {
  id: string;
  vault: string;
  title: string;
  username: string | null;
  urls: string[];
  hasOtp: boolean;
}
export interface LoginSecret {
  username: string | null;
  password: string | null;
  totp: string | null;
}

export interface PasswordManagerClient {
  vaults(): Promise<Vault[]>;
  items(vaultIds: string[]): Promise<LoginItem[]>;
  secret(item: LoginItem): Promise<LoginSecret>;
}

const LOGIN = /\{\{login:([^:{}]{1,100}):(username|password|otp)\}\}/g;
export const hasLoginPlaceholders = (v: unknown) => JSON.stringify(v ?? null).includes("{{login:");

async function getJson<T>(
  f: typeof fetch,
  url: string,
  headers: Record<string, string>,
): Promise<T> {
  const r = await f(url, { headers: { accept: "application/json", ...headers } });
  if (r.status === 401 || r.status === 403)
    throw new ToolError("password_manager_auth", "The password manager rejected the token");
  if (!r.ok)
    throw new ToolError("password_manager_error", `The password manager answered ${r.status}`);
  return (await r.json()) as T;
}

/** 1Password Connect: /v1/vaults, /v1/vaults/{id}/items, /v1/vaults/{id}/items/{item}. */
export function onePassword(base: string, token: string, f: typeof fetch): PasswordManagerClient {
  const url = base.replace(/\/$/, "");
  const h = { authorization: `Bearer ${token}` };
  type Item = {
    id: string;
    title: string;
    category: string;
    vault: { id: string };
    urls?: Array<{ href: string }>;
    fields?: Array<{
      purpose?: string;
      type?: string;
      value?: string;
      totp?: string;
      label?: string;
    }>;
  };
  return {
    async vaults() {
      return (await getJson<Array<{ id: string; name: string }>>(f, `${url}/v1/vaults`, h)).map(
        (v) => ({ id: v.id, name: v.name }),
      );
    },
    async items(vaultIds) {
      const out: LoginItem[] = [];
      for (const v of vaultIds) {
        for (const it of await getJson<Item[]>(
          f,
          `${url}/v1/vaults/${encodeURIComponent(v)}/items`,
          h,
        )) {
          if (it.category !== "LOGIN") continue;
          out.push({
            id: it.id,
            vault: v,
            title: it.title,
            username: null,
            urls: (it.urls ?? []).map((u) => u.href),
            hasOtp: false,
          });
        }
      }
      return out;
    },
    async secret(item) {
      const it = await getJson<Item>(
        f,
        `${url}/v1/vaults/${encodeURIComponent(item.vault)}/items/${encodeURIComponent(item.id)}`,
        h,
      );
      const fields = it.fields ?? [];
      const otp = fields.find((x) => x.type === "OTP");
      return {
        username: fields.find((x) => x.purpose === "USERNAME")?.value ?? null,
        password: fields.find((x) => x.purpose === "PASSWORD")?.value ?? null,
        totp: otp?.value ?? null,
      };
    },
  };
}

/** Bitwarden Vault Management API (`bw serve`): collections and their login items. */
export function bitwarden(base: string, token: string, f: typeof fetch): PasswordManagerClient {
  const url = base.replace(/\/$/, "");
  const h: Record<string, string> = token ? { authorization: `Bearer ${token}` } : {};
  type Res<T> = { success: boolean; data: { data?: T[] } & Record<string, unknown> };
  type Item = {
    id: string;
    name: string;
    type: number;
    collectionIds?: string[];
    login?: { username?: string; password?: string; totp?: string; uris?: Array<{ uri: string }> };
  };
  return {
    async vaults() {
      return (
        (await getJson<Res<{ id: string; name: string }>>(f, `${url}/list/object/collections`, h))
          .data.data ?? []
      ).map((c) => ({ id: c.id, name: c.name }));
    },
    async items(vaultIds) {
      const out: LoginItem[] = [];
      for (const c of vaultIds) {
        for (const it of (
          await getJson<Res<Item>>(
            f,
            `${url}/list/object/items?collectionid=${encodeURIComponent(c)}`,
            h,
          )
        ).data.data ?? []) {
          if (it.type !== 1 || !it.login) continue;
          out.push({
            id: it.id,
            vault: c,
            title: it.name,
            username: it.login.username ?? null,
            urls: (it.login.uris ?? []).map((u) => u.uri),
            hasOtp: !!it.login.totp,
          });
        }
      }
      return out;
    },
    async secret(item) {
      const it = (
        await getJson<{ data: Item }>(f, `${url}/object/item/${encodeURIComponent(item.id)}`, h)
      ).data;
      return {
        username: it.login?.username ?? null,
        password: it.login?.password ?? null,
        totp: it.login?.totp ?? null,
      };
    },
  };
}

export function clientFor(provider: string, base: string, token: string, f: typeof fetch) {
  return provider === "1password" ? onePassword(base, token, f) : bitwarden(base, token, f);
}

/** Whether a destination host is one of the item's URLs (or a subdomain of one). */
export function itemCoversHost(item: LoginItem, host: string | null) {
  if (!host) return false;
  const h = host.toLowerCase();
  return item.urls.some((u) => {
    try {
      const ih = new URL(/^[a-z]+:\/\//i.test(u) ? u : `https://${u}`).hostname.toLowerCase();
      return h === ih || h.endsWith(`.${ih}`);
    } catch {
      return false;
    }
  });
}

/** The password managers a run may use: the workspace's, and those of the person it acts for. */
export async function managersFor(
  db: Database,
  run: { orgId: string; botId: string; runId: string },
) {
  const user = await actingUserOf(db, run.runId);
  return db.execute<{
    id: string;
    provider: string;
    name: string;
    url: string;
    token: string | null;
    allowed_vaults: string[];
  }>(sql`
    select m.id, m.provider, m.name, m.url, v.decrypted_secret as token, m.allowed_vaults from public.password_managers m
    left join vault.decrypted_secrets v on v.id = m.vault_secret_id
    where m.org_id = ${run.orgId}::uuid and cardinality(m.allowed_vaults) > 0
      and (m.allowed_bot_ids is null or ${run.botId}::uuid = any(m.allowed_bot_ids))
      and (m.user_id is null or m.user_id = ${user ?? null}::uuid)
    order by m.user_id nulls last, m.created_at`);
}

/** Every login the run may use, across its password managers. */
export async function loginsFor(
  db: Database,
  run: { orgId: string; botId: string; runId: string },
  f: typeof fetch,
) {
  const out: Array<{ manager: string; client: PasswordManagerClient; item: LoginItem }> = [];
  for (const m of await managersFor(db, run)) {
    const client = clientFor(m.provider, m.url, m.token ?? "", f);
    try {
      for (const item of await client.items(m.allowed_vaults))
        out.push({ manager: m.name, client, item });
    } catch (err) {
      await db.execute(
        sql`update public.password_managers set status = 'error', last_error = ${(err as Error).message.slice(0, 500)} where id = ${m.id}::uuid`,
      );
    }
  }
  return out;
}

/** Fills {{login:Name:field}} for a destination host; values are reported to `onValue` for redaction. */
export async function resolveLoginPlaceholders<T>(
  db: Database,
  run: { orgId: string; botId: string; runId: string },
  value: T,
  host: string | null,
  opts: { fetch: typeof fetch; onValue?: (v: string, label: string) => void; nowMs?: number },
): Promise<T> {
  const wanted = [...JSON.stringify(value).matchAll(LOGIN)].map((m) => m[1] as string);
  if (!wanted.length) return value;
  const logins = await loginsFor(db, run, opts.fetch);
  const filled = new Map<string, LoginSecret>();
  for (const name of new Set(wanted)) {
    const matches = logins.filter((l) => l.item.title.toLowerCase() === name.toLowerCase());
    if (!matches.length)
      throw new ToolError(
        "login_not_found",
        `There's no login named "${name}" in the password managers this bot may use.`,
      );
    const usable = matches.find((l) => itemCoversHost(l.item, host));
    if (!usable)
      throw new ToolError(
        "login_host_not_allowed",
        `The login "${name}" is only for ${matches[0]?.item.urls.join(", ") || "its own sites"}, not ${host ?? "this destination"}.`,
      );
    filled.set(name.toLowerCase(), await usable.client.secret(usable.item));
  }
  const replace = (s: string) =>
    s.replace(LOGIN, (_m, name: string, field: string) => {
      const sec = filled.get(name.toLowerCase()) as LoginSecret;
      let v: string | null;
      if (field === "otp") {
        if (!sec.totp)
          throw new ToolError("login_no_otp", `The login "${name}" has no one-time code.`);
        v = /^\d{6,8}$/.test(sec.totp) ? sec.totp : totpCode(parseTotp(sec.totp), opts.nowMs);
      } else v = field === "username" ? sec.username : sec.password;
      if (!v) throw new ToolError("login_field_missing", `The login "${name}" has no ${field}.`);
      opts.onValue?.(v, `login:${name}`);
      return v;
    });
  const walk = (v: unknown): unknown =>
    typeof v === "string"
      ? replace(v)
      : Array.isArray(v)
        ? v.map(walk)
        : v && typeof v === "object"
          ? Object.fromEntries(Object.entries(v).map(([k, x]) => [k, walk(x)]))
          : v;
  return walk(value) as T;
}

export function registerLoginTools(
  registry: ToolRegistry,
  deps: { db: Database; fetch: typeof fetch },
) {
  registry.register({
    name: "logins.list",
    readOnly: true,
    description:
      "Logins from the password managers you may use, for signing in to sites. You never see passwords: put {{login:Name:username}}, {{login:Name:password}} or {{login:Name:otp}} (the current one-time code) in browser.fill, and they are filled only on that login's own sites.",
    risk: "low",
    schema: z.object({
      site: z.string().max(200).optional().describe("Only logins for this site"),
    }),
    async execute(args, ctx) {
      const all = await loginsFor(deps.db, ctx, deps.fetch);
      const list = args.site
        ? all.filter((l) =>
            itemCoversHost(l.item, args.site?.replace(/^https?:\/\//, "").split("/")[0] ?? null),
          )
        : all;
      if (!list.length) return { content: "No logins available.", preview: "0 logins" };
      return {
        content: list
          .slice(0, 100)
          .map(
            (l) =>
              `[login:${l.item.title}] ${l.item.urls.join(", ") || "(no sites)"}${l.item.hasOtp ? " · has one-time codes" : ""} (${l.manager})`,
          )
          .join("\n"),
        preview: `${list.length} logins`,
      };
    },
  });
}
