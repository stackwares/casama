/**
 * Casama's own Zoho app (D-350): one Zoho sign-in per person and workspace covers Zoho Mail, CRM,
 * Desk and Books. The connection is an `mcp` integration with `config.provider = "zoho"` (no new
 * kind, so shipped apps keep parsing it), its OAuth tokens in Vault like any app sign-in, and this
 * adapter calls Zoho's REST APIs directly with a hand-picked set of tools for the apps the person
 * actually has (found once after sign-in and kept in `config.zoho`).
 */

import type { Risk } from "./tools/registry.ts";
import { ToolError } from "./tools/registry.ts";

/** What the sign-in found, kept in the connection's config (members can read it: no secrets). */
export interface ZohoConfig {
  /** Accounts server of the person's data centre, e.g. https://accounts.zoho.eu. */
  accounts_server: string;
  /** Zoho's API domain for CRM and Books, from the token answer (https://www.zohoapis.eu). */
  api_domain: string;
  /** Zoho Mail's and Zoho Desk's API bases for that data centre. */
  mail_base: string;
  desk_base: string;
  mail: { account_id: string; email: string } | null;
  crm: boolean;
  desk: { org_id: string; name?: string } | null;
  books: { org_id: string; name?: string } | null;
}

/** Zoho's accounts servers (their data centres). China needs its own client and isn't here. */
const ZOHO_ACCOUNTS =
  /^https:\/\/accounts\.(zoho\.(com|eu|in|com\.au|jp|sa|uk|ca|ae|sg)|zohocloud\.ca)$/;

/** Whether an accounts server from Zoho's callback is one of Zoho's (or the configured one). */
export function zohoAccountsServerOk(server: string, configured?: string) {
  const s = server.replace(/\/$/, "");
  return ZOHO_ACCOUNTS.test(s) || (!!configured && s === configured.replace(/\/$/, ""));
}

/** Mail and Desk live on per-data-centre hosts: accounts.zoho.eu → mail.zoho.eu, desk.zoho.eu. */
export function zohoServiceBases(accountsServer: string) {
  const u = new URL(accountsServer);
  const suffix = u.hostname.startsWith("accounts.") ? u.hostname.slice("accounts.".length) : null;
  if (suffix && ZOHO_ACCOUNTS.test(u.origin))
    return { mail_base: `https://mail.${suffix}`, desk_base: `https://desk.${suffix}` };
  // A stand-in Zoho (tests): one server answers every API.
  return { mail_base: u.origin, desk_base: u.origin };
}

/** The scopes Casama asks for: only what its tools use. Zoho separates them with commas. */
export const ZOHO_SCOPES = [
  "ZohoMail.accounts.READ",
  "ZohoMail.messages.ALL",
  "ZohoMail.folders.READ",
  "ZohoCRM.modules.ALL",
  "ZohoCRM.settings.modules.READ",
  "ZohoCRM.org.READ",
  "Desk.basic.READ",
  "Desk.tickets.ALL",
  "Desk.contacts.READ",
  "Desk.search.READ",
  "ZohoBooks.settings.READ",
  "ZohoBooks.contacts.ALL",
  "ZohoBooks.invoices.ALL",
  "ZohoBooks.bills.READ",
].join(",");

type Fetch = typeof fetch;

/** A JSON request to Zoho with the OAuth token; Zoho's errors become ToolErrors a bot can act on. */
async function zohoJson(
  fetchImpl: Fetch,
  token: string,
  url: string,
  init: { method?: string; body?: unknown; headers?: Record<string, string> } = {},
): Promise<Record<string, unknown>> {
  const res = await fetchImpl(url, {
    method: init.method ?? "GET",
    headers: {
      authorization: `Zoho-oauthtoken ${token}`,
      accept: "application/json",
      ...(init.body !== undefined ? { "content-type": "application/json" } : {}),
      ...init.headers,
    },
    ...(init.body !== undefined ? { body: JSON.stringify(init.body) } : {}),
  });
  const text = await res.text();
  let json: Record<string, unknown> = {};
  try {
    json = text ? (JSON.parse(text) as Record<string, unknown>) : {};
  } catch {
    json = { raw: text.slice(0, 500) };
  }
  if (res.status === 204) return {};
  if (res.ok) return json;
  const detail = zohoErrorText(json) ?? `HTTP ${res.status}`;
  if (res.status === 401 || /INVALID_OAUTHTOKEN|invalid_token|AUTHENTICATION_FAILURE/i.test(detail))
    throw new ToolError(
      "zoho_reconnect",
      "Zoho's sign-in has expired or was revoked. Ask the person to reconnect Zoho in Connections.",
    );
  if (res.status === 429 || /LIMIT|too many|rate/i.test(detail))
    throw new ToolError(
      "zoho_limit",
      `Zoho's API limit for this account is used up for now (${detail}). Try again later.`,
    );
  if (/SCOPE|scope/i.test(detail))
    throw new ToolError(
      "zoho_scope",
      `Zoho didn't allow this (${detail}). Reconnecting Zoho grants the missing permission.`,
    );
  throw new ToolError("zoho_error", `Zoho said: ${detail}`);
}

function zohoErrorText(j: Record<string, unknown>): string | undefined {
  const status = j.status as { description?: string; code?: number } | undefined;
  const data = j.data as { errorCode?: string; moreInfo?: string } | undefined;
  const first = Array.isArray(j.data)
    ? (j.data[0] as { code?: string; message?: string } | undefined)
    : undefined;
  const parts = [
    status?.description,
    data && !Array.isArray(data) ? (data.errorCode ?? data.moreInfo) : undefined,
    typeof j.message === "string" ? j.message : undefined,
    typeof j.errorCode === "string" ? j.errorCode : undefined,
    typeof j.code === "string" ? j.code : undefined,
    first?.code && first.message ? `${first.code}: ${first.message}` : undefined,
  ].filter(Boolean);
  return parts.length ? parts.join(" · ") : undefined;
}

/** After sign-in: which of Mail, CRM, Desk and Books this Zoho account has, with their ids. */
export async function discoverZoho(
  fetchImpl: Fetch,
  token: string,
  base: Pick<ZohoConfig, "accounts_server" | "api_domain" | "mail_base" | "desk_base">,
): Promise<ZohoConfig> {
  const tryJson = (url: string, headers?: Record<string, string>) =>
    zohoJson(fetchImpl, token, url, { headers }).catch(() => null);
  const [mail, crm, desk, books] = await Promise.all([
    tryJson(`${base.mail_base}/api/accounts`),
    tryJson(`${base.api_domain}/crm/v8/org`),
    tryJson(`${base.desk_base}/api/v1/organizations`),
    tryJson(`${base.api_domain}/books/v3/organizations`),
  ]);
  const mailAcc = Array.isArray(mail?.data)
    ? (mail.data as Array<{ accountId?: string | number; primaryEmailAddress?: string }>)[0]
    : undefined;
  const deskOrg = Array.isArray(desk?.data)
    ? (desk.data as Array<{ id?: string | number; companyName?: string; isDefault?: boolean }>)
        .slice()
        .sort((a, b) => Number(!!b.isDefault) - Number(!!a.isDefault))[0]
    : undefined;
  const booksOrgs = Array.isArray(books?.organizations)
    ? (books.organizations as Array<{
        organization_id?: string;
        name?: string;
        is_default_org?: boolean;
      }>)
    : [];
  const booksOrg = booksOrgs.find((o) => o.is_default_org) ?? booksOrgs[0];
  return {
    ...base,
    mail: mailAcc?.accountId
      ? { account_id: String(mailAcc.accountId), email: mailAcc.primaryEmailAddress ?? "" }
      : null,
    crm: !!crm && Array.isArray(crm.org),
    desk: deskOrg?.id
      ? {
          org_id: String(deskOrg.id),
          ...(deskOrg.companyName ? { name: deskOrg.companyName } : {}),
        }
      : null,
    books: booksOrg?.organization_id
      ? {
          org_id: booksOrg.organization_id,
          ...(booksOrg.name ? { name: booksOrg.name } : {}),
        }
      : null,
  };
}

// ---------------------------------------------------------------------------
// Tools

interface ZohoTool {
  name: string;
  app: "mail" | "crm" | "desk" | "books";
  description: string;
  risk: Risk;
  input: Record<string, unknown>;
  run: (z: ZohoCall, args: Record<string, unknown>) => Promise<unknown>;
}

interface ZohoCall {
  cfg: ZohoConfig;
  get: (url: string, headers?: Record<string, string>) => Promise<Record<string, unknown>>;
  send: (
    method: string,
    url: string,
    body?: unknown,
    headers?: Record<string, string>,
  ) => Promise<Record<string, unknown>>;
}

const obj = (properties: Record<string, unknown>, required: string[] = []) => ({
  type: "object",
  properties,
  required,
  additionalProperties: false,
});
const s = (description: string) => ({ type: "string", description });
const n = (description: string, max = 50) => ({
  type: "integer",
  minimum: 1,
  maximum: max,
  description,
});
const arg = (a: Record<string, unknown>, k: string) => {
  const v = a[k];
  if (v === undefined || v === null || v === "")
    throw new ToolError("invalid_arguments", `${k} is required`);
  return String(v);
};
const lim = (a: Record<string, unknown>, k = "limit", d = 20, max = 50) =>
  Math.min(max, Math.max(1, Number(a[k] ?? d) || d));
const enc = encodeURIComponent;
const list = (v: unknown) =>
  (Array.isArray(v) ? v : typeof v === "string" ? v.split(",") : [])
    .map((x) => String(x).trim())
    .filter(Boolean);

/** Zoho Mail escapes text fields as HTML (`&lt;ana@x.com&gt;`). */
function decodeEntities(v: string) {
  return v
    .replace(/&nbsp;/g, " ")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d)))
    .replace(/&amp;/g, "&");
}
const text = (v: unknown) => (typeof v === "string" ? decodeEntities(v).trim() : undefined);

/** Zoho Mail answers HTML; bots read text. */
function htmlToText(html: string) {
  return decodeEntities(
    html
      .replace(/<(script|style)[\s\S]*?<\/\1>/gi, "")
      .replace(/<br\s*\/?>|<\/(p|div|li|tr|h\d)>/gi, "\n")
      .replace(/<[^>]+>/g, ""),
  )
    .replace(/\r/g, "")
    .replace(/[ \t\u00a0]+/g, " ")
    .split("\n")
    .map((l) => l.trim())
    .join("\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

const mailUrl = (z: ZohoCall, path: string) =>
  `${z.cfg.mail_base}/api/accounts/${z.cfg.mail?.account_id}${path}`;

type MailRow = {
  messageId?: string;
  folderId?: string;
  subject?: string;
  fromAddress?: string;
  sender?: string;
  toAddress?: string;
  receivedTime?: string;
  summary?: string;
  status?: string;
  hasAttachment?: string;
};
const mailRows = (j: Record<string, unknown>) =>
  (Array.isArray(j.data) ? (j.data as MailRow[]) : []).map((m) => ({
    message_id: m.messageId,
    folder_id: m.folderId,
    subject: text(m.subject),
    from:
      m.sender && m.sender !== m.fromAddress
        ? `${text(m.sender)} <${m.fromAddress ?? ""}>`
        : text(m.fromAddress),
    to: text(m.toAddress),
    received: m.receivedTime ? new Date(Number(m.receivedTime)).toISOString() : undefined,
    unread: m.status === "0",
    attachments: m.hasAttachment === "1",
    summary: text(m.summary)?.replace(/\s+/g, " "),
  }));

const crmUrl = (z: ZohoCall, path: string) => `${z.cfg.api_domain}/crm/v8${path}`;
const deskUrl = (z: ZohoCall, path: string) => `${z.cfg.desk_base}/api/v1${path}`;
const deskHeaders = (z: ZohoCall) => ({ orgId: z.cfg.desk?.org_id ?? "" });
const booksUrl = (z: ZohoCall, path: string, query = "") =>
  `${z.cfg.api_domain}/books/v3${path}?organization_id=${enc(z.cfg.books?.org_id ?? "")}${query}`;

export const ZOHO_TOOLS: ZohoTool[] = [
  // ------------------------------------------------------------------ Mail
  {
    name: "mail_search",
    app: "mail",
    description:
      "Search Zoho Mail. `query` is words to find anywhere, or Zoho's syntax such as `from:ana@x.com`, `subject:invoice`, `has:attachment`.",
    risk: "low",
    input: obj({ query: s("What to look for"), limit: n("How many (default 20)") }, ["query"]),
    run: async (z, a) => {
      const q = arg(a, "query");
      const key = /^\w+:/.test(q) ? q : `entire:${q}`;
      return mailRows(
        await z.get(mailUrl(z, `/messages/search?searchKey=${enc(key)}&limit=${lim(a)}`)),
      );
    },
  },
  {
    name: "mail_list_recent",
    app: "mail",
    description: "The newest messages in the inbox (or a folder), optionally only unread ones.",
    risk: "low",
    input: obj({
      folder_id: s("A folder from mail_list_folders (default: inbox)"),
      unread_only: { type: "boolean" },
      limit: n("How many (default 20)"),
    }),
    run: async (z, a) => {
      const q = [
        `limit=${lim(a)}`,
        a.folder_id ? `folderId=${enc(String(a.folder_id))}` : "",
        a.unread_only ? "status=unread" : "",
      ]
        .filter(Boolean)
        .join("&");
      return mailRows(await z.get(mailUrl(z, `/messages/view?${q}`)));
    },
  },
  {
    name: "mail_read",
    app: "mail",
    description: "Read one message in full (headers and text). Needs its message_id and folder_id.",
    risk: "low",
    input: obj({ message_id: s("From a search or list"), folder_id: s("From a search or list") }, [
      "message_id",
      "folder_id",
    ]),
    run: async (z, a) => {
      const path = `/folders/${enc(arg(a, "folder_id"))}/messages/${enc(arg(a, "message_id"))}`;
      const [details, content] = await Promise.all([
        z.get(mailUrl(z, `${path}/details`)),
        z.get(mailUrl(z, `${path}/content`)),
      ]);
      const d = (details.data ?? {}) as Record<string, string>;
      const c = (content.data ?? {}) as { content?: string };
      return {
        message_id: a.message_id,
        subject: text(d.subject),
        from: text(d.fromAddress),
        to: text(d.toAddress),
        ...(d.ccAddress && d.ccAddress !== "Not Provided" ? { cc: text(d.ccAddress) } : {}),
        received: d.receivedTime ? new Date(Number(d.receivedTime)).toISOString() : undefined,
        text: htmlToText(c.content ?? "").slice(0, 20_000),
      };
    },
  },
  {
    name: "mail_list_folders",
    app: "mail",
    description: "The mailbox's folders with their ids.",
    risk: "low",
    input: obj({}),
    run: async (z) => {
      const j = await z.get(mailUrl(z, "/folders"));
      return (
        Array.isArray(j.data)
          ? (j.data as Array<{ folderId?: string; folderName?: string; path?: string }>)
          : []
      ).map((f) => ({ folder_id: f.folderId, name: f.folderName, path: f.path }));
    },
  },
  {
    name: "mail_send",
    app: "mail",
    description: "Send a new email from the person's Zoho Mail address.",
    risk: "high",
    input: obj(
      {
        to: s("Recipients, comma-separated"),
        cc: s("Copy, comma-separated"),
        subject: s("Subject"),
        body: s("The message (plain text, or HTML when html is true)"),
        html: { type: "boolean" },
      },
      ["to", "subject", "body"],
    ),
    run: async (z, a) => {
      const j = await z.send("POST", mailUrl(z, "/messages"), {
        fromAddress: z.cfg.mail?.email,
        toAddress: list(a.to).join(","),
        ...(a.cc ? { ccAddress: list(a.cc).join(",") } : {}),
        subject: arg(a, "subject"),
        content: arg(a, "body"),
        mailFormat: a.html ? "html" : "plaintext",
      });
      return { sent: true, message_id: (j.data as { messageId?: string })?.messageId };
    },
  },
  {
    name: "mail_reply",
    app: "mail",
    description: "Reply to a message (to the sender, or everyone with reply_all).",
    risk: "high",
    input: obj(
      {
        message_id: s("The message to answer"),
        folder_id: s("Its folder"),
        body: s("The reply (plain text)"),
        reply_all: { type: "boolean" },
      },
      ["message_id", "folder_id", "body"],
    ),
    run: async (z, a) => {
      const id = arg(a, "message_id");
      const d = ((
        await z.get(mailUrl(z, `/folders/${enc(arg(a, "folder_id"))}/messages/${enc(id)}/details`))
      ).data ?? {}) as Record<string, string>;
      const emails = (v?: string) => text(v)?.match(/[^\s<>,;"]+@[^\s<>,;"]+/g) ?? [];
      const me = (z.cfg.mail?.email ?? "").toLowerCase();
      const to = a.reply_all
        ? [d.fromAddress, d.toAddress, d.ccAddress]
            .flatMap((x) => emails(x))
            .filter((x) => x.toLowerCase() !== me)
        : emails(d.fromAddress);
      if (!to.length) throw new ToolError("invalid_arguments", "Couldn't tell who to reply to");
      await z.send("POST", mailUrl(z, `/messages/${enc(id)}`), {
        action: "reply",
        fromAddress: z.cfg.mail?.email,
        toAddress: [...new Set(to)].join(","),
        subject: text(d.subject)?.startsWith("Re:")
          ? text(d.subject)
          : `Re: ${text(d.subject) ?? ""}`,
        content: arg(a, "body"),
        mailFormat: "plaintext",
      });
      return { replied: true, to };
    },
  },
  {
    name: "mail_save_draft",
    app: "mail",
    description: "Save an email as a draft for the person to review and send themselves.",
    risk: "medium",
    input: obj({ to: s("Recipients"), subject: s("Subject"), body: s("The message") }, [
      "subject",
      "body",
    ]),
    run: async (z, a) => {
      const j = await z.send("POST", mailUrl(z, "/messages"), {
        fromAddress: z.cfg.mail?.email,
        toAddress: list(a.to).join(","),
        subject: arg(a, "subject"),
        content: arg(a, "body"),
        mailFormat: "plaintext",
        mode: "draft",
      });
      return { draft: true, message_id: (j.data as { messageId?: string })?.messageId };
    },
  },
  {
    name: "mail_mark",
    app: "mail",
    description: "Mark messages read or unread, or move them to a folder.",
    risk: "medium",
    input: obj(
      {
        message_ids: { type: "array", items: { type: "string" }, maxItems: 50 },
        read: { type: "boolean", description: "true: mark read; false: unread" },
        move_to_folder_id: s("Move them here instead"),
      },
      ["message_ids"],
    ),
    run: async (z, a) => {
      const ids = list(a.message_ids);
      if (!ids.length) throw new ToolError("invalid_arguments", "message_ids is empty");
      const body = a.move_to_folder_id
        ? { mode: "moveMessage", messageId: ids, destfolderId: String(a.move_to_folder_id) }
        : { mode: a.read === false ? "markAsUnread" : "markAsRead", messageId: ids };
      await z.send("PUT", mailUrl(z, "/updatemessage"), body);
      return { updated: ids.length };
    },
  },
  // ------------------------------------------------------------------ CRM
  {
    name: "crm_list_modules",
    app: "crm",
    description:
      "The CRM's modules (Leads, Contacts, Deals, Accounts and custom ones) by API name.",
    risk: "low",
    input: obj({}),
    run: async (z) => {
      const j = await z.get(crmUrl(z, "/settings/modules"));
      return (
        Array.isArray(j.modules)
          ? (j.modules as Array<{
              api_name?: string;
              plural_label?: string;
              api_supported?: boolean;
            }>)
          : []
      )
        .filter((m) => m.api_supported !== false)
        .map((m) => ({ module: m.api_name, label: m.plural_label }));
    },
  },
  {
    name: "crm_search",
    app: "crm",
    description:
      "Search a CRM module (Leads, Contacts, Deals, Accounts…) by a word, an email or a phone number.",
    risk: "low",
    input: obj(
      {
        module: s("API name, e.g. Leads"),
        query: s("A word, email or phone"),
        limit: n("How many (default 20)", 100),
      },
      ["module", "query"],
    ),
    run: async (z, a) => {
      const q = arg(a, "query");
      const by = q.includes("@") ? "email" : /^\+?[\d\s()-]{6,}$/.test(q) ? "phone" : "word";
      const j = await z.get(
        crmUrl(
          z,
          `/${enc(arg(a, "module"))}/search?${by}=${enc(q)}&per_page=${lim(a, "limit", 20, 100)}`,
        ),
      );
      return Array.isArray(j.data) ? j.data : [];
    },
  },
  {
    name: "crm_get",
    app: "crm",
    description: "One CRM record with all its fields.",
    risk: "low",
    input: obj({ module: s("API name"), id: s("Record id") }, ["module", "id"]),
    run: async (z, a) => {
      const j = await z.get(crmUrl(z, `/${enc(arg(a, "module"))}/${enc(arg(a, "id"))}`));
      return Array.isArray(j.data) ? j.data[0] : j;
    },
  },
  {
    name: "crm_create",
    app: "crm",
    description:
      "Create a CRM record. `fields` uses the module's API field names, e.g. {Last_Name, Email, Company} for Leads.",
    risk: "medium",
    input: obj({ module: s("API name"), fields: { type: "object" } }, ["module", "fields"]),
    run: async (z, a) =>
      z.send("POST", crmUrl(z, `/${enc(arg(a, "module"))}`), { data: [a.fields ?? {}] }),
  },
  {
    name: "crm_update",
    app: "crm",
    description: "Change fields on a CRM record.",
    risk: "medium",
    input: obj({ module: s("API name"), id: s("Record id"), fields: { type: "object" } }, [
      "module",
      "id",
      "fields",
    ]),
    run: async (z, a) =>
      z.send("PUT", crmUrl(z, `/${enc(arg(a, "module"))}/${enc(arg(a, "id"))}`), {
        data: [a.fields ?? {}],
      }),
  },
  {
    name: "crm_add_note",
    app: "crm",
    description: "Add a note to a CRM record.",
    risk: "medium",
    input: obj(
      { module: s("API name"), id: s("Record id"), title: s("Title"), content: s("Note") },
      ["module", "id", "content"],
    ),
    run: async (z, a) =>
      z.send("POST", crmUrl(z, `/${enc(arg(a, "module"))}/${enc(arg(a, "id"))}/Notes`), {
        data: [{ Note_Title: a.title ?? "", Note_Content: arg(a, "content") }],
      }),
  },
  // ------------------------------------------------------------------ Desk
  {
    name: "desk_list_tickets",
    app: "desk",
    description: "Recent support tickets, optionally by status (Open, On Hold, Closed…).",
    risk: "low",
    input: obj({ status: s("e.g. Open"), limit: n("How many (default 20)", 100) }),
    run: async (z, a) => {
      const q = `limit=${lim(a, "limit", 20, 100)}&sortBy=-modifiedTime${a.status ? `&status=${enc(String(a.status))}` : ""}`;
      const j = await z.get(deskUrl(z, `/tickets?${q}`), deskHeaders(z));
      return Array.isArray(j.data) ? j.data : [];
    },
  },
  {
    name: "desk_search_tickets",
    app: "desk",
    description: "Search tickets by words in their subject or content.",
    risk: "low",
    input: obj({ query: s("Words to find"), limit: n("How many (default 20)", 100) }, ["query"]),
    run: async (z, a) => {
      const j = await z.get(
        deskUrl(
          z,
          `/search?module=tickets&searchStr=${enc(arg(a, "query"))}&limit=${lim(a, "limit", 20, 100)}`,
        ),
        deskHeaders(z),
      );
      return Array.isArray(j.data) ? j.data : [];
    },
  },
  {
    name: "desk_get_ticket",
    app: "desk",
    description: "One ticket with its latest conversation.",
    risk: "low",
    input: obj({ ticket_id: s("Ticket id") }, ["ticket_id"]),
    run: async (z, a) => {
      const id = enc(arg(a, "ticket_id"));
      const [ticket, threads] = await Promise.all([
        z.get(deskUrl(z, `/tickets/${id}`), deskHeaders(z)),
        z.get(deskUrl(z, `/tickets/${id}/threads?limit=10`), deskHeaders(z)),
      ]);
      return { ticket, threads: Array.isArray(threads.data) ? threads.data : [] };
    },
  },
  {
    name: "desk_update_ticket",
    app: "desk",
    description: "Change a ticket's status, priority or owner.",
    risk: "medium",
    input: obj(
      {
        ticket_id: s("Ticket id"),
        status: s("e.g. Closed"),
        priority: s("e.g. High"),
        assignee_id: s("Agent id"),
      },
      ["ticket_id"],
    ),
    run: async (z, a) =>
      z.send(
        "PATCH",
        deskUrl(z, `/tickets/${enc(arg(a, "ticket_id"))}`),
        {
          ...(a.status ? { status: a.status } : {}),
          ...(a.priority ? { priority: a.priority } : {}),
          ...(a.assignee_id ? { assigneeId: a.assignee_id } : {}),
        },
        deskHeaders(z),
      ),
  },
  {
    name: "desk_add_comment",
    app: "desk",
    description: "Add a private comment on a ticket (the customer doesn't see it).",
    risk: "medium",
    input: obj({ ticket_id: s("Ticket id"), content: s("Comment") }, ["ticket_id", "content"]),
    run: async (z, a) =>
      z.send(
        "POST",
        deskUrl(z, `/tickets/${enc(arg(a, "ticket_id"))}/comments`),
        { content: arg(a, "content"), isPublic: false, contentType: "plainText" },
        deskHeaders(z),
      ),
  },
  {
    name: "desk_reply",
    app: "desk",
    description: "Email a reply to the customer on a ticket.",
    risk: "high",
    input: obj(
      {
        ticket_id: s("Ticket id"),
        content: s("The reply"),
        from_address: s("The support address to send from (default: the ticket's)"),
      },
      ["ticket_id", "content"],
    ),
    run: async (z, a) => {
      const id = enc(arg(a, "ticket_id"));
      const t = await z.get(deskUrl(z, `/tickets/${id}`), deskHeaders(z));
      const from = a.from_address ? String(a.from_address) : (t.supportEmailAddress as string);
      if (!from)
        throw new ToolError(
          "invalid_arguments",
          "Give from_address: the ticket has no support address",
        );
      return z.send(
        "POST",
        deskUrl(z, `/tickets/${id}/sendReply`),
        {
          channel: "EMAIL",
          to: t.email,
          fromEmailAddress: from,
          content: arg(a, "content"),
          contentType: "plainText",
        },
        deskHeaders(z),
      );
    },
  },
  // ------------------------------------------------------------------ Books
  {
    name: "books_list_invoices",
    app: "books",
    description:
      "Invoices, optionally by status (draft, sent, overdue, paid, unpaid) or customer name.",
    risk: "low",
    input: obj({
      status: s("e.g. overdue"),
      customer: s("Customer name"),
      limit: n("How many", 200),
    }),
    run: async (z, a) => {
      const q = [
        a.status ? `&status=${enc(String(a.status))}` : "",
        a.customer ? `&customer_name_contains=${enc(String(a.customer))}` : "",
        `&per_page=${lim(a, "limit", 25, 200)}`,
      ].join("");
      const j = await z.get(booksUrl(z, "/invoices", q));
      return (Array.isArray(j.invoices) ? (j.invoices as Array<Record<string, unknown>>) : []).map(
        (i) => ({
          invoice_id: i.invoice_id,
          number: i.invoice_number,
          customer: i.customer_name,
          status: i.status,
          date: i.date,
          due_date: i.due_date,
          total: i.total,
          balance: i.balance,
          currency: i.currency_code,
        }),
      );
    },
  },
  {
    name: "books_get_invoice",
    app: "books",
    description: "One invoice with its line items.",
    risk: "low",
    input: obj({ invoice_id: s("Invoice id") }, ["invoice_id"]),
    run: async (z, a) =>
      (await z.get(booksUrl(z, `/invoices/${enc(arg(a, "invoice_id"))}`))).invoice ?? {},
  },
  {
    name: "books_list_contacts",
    app: "books",
    description: "Customers and vendors, optionally matching a name.",
    risk: "low",
    input: obj({ query: s("Name to match"), limit: n("How many", 200) }),
    run: async (z, a) => {
      const q = `${a.query ? `&contact_name_contains=${enc(String(a.query))}` : ""}&per_page=${lim(a, "limit", 25, 200)}`;
      const j = await z.get(booksUrl(z, "/contacts", q));
      return (Array.isArray(j.contacts) ? (j.contacts as Array<Record<string, unknown>>) : []).map(
        (c) => ({
          contact_id: c.contact_id,
          name: c.contact_name,
          company: c.company_name,
          type: c.contact_type,
          email: c.email,
          outstanding: c.outstanding_receivable_amount,
        }),
      );
    },
  },
  {
    name: "books_list_bills",
    app: "books",
    description: "Bills to pay, optionally by status (open, overdue, paid).",
    risk: "low",
    input: obj({ status: s("e.g. overdue"), limit: n("How many", 200) }),
    run: async (z, a) => {
      const q = `${a.status ? `&status=${enc(String(a.status))}` : ""}&per_page=${lim(a, "limit", 25, 200)}`;
      const j = await z.get(booksUrl(z, "/bills", q));
      return Array.isArray(j.bills) ? j.bills : [];
    },
  },
  {
    name: "books_create_contact",
    app: "books",
    description: "Add a customer (or vendor) to Zoho Books.",
    risk: "medium",
    input: obj(
      {
        name: s("Display name"),
        email: s("Email"),
        company: s("Company"),
        vendor: { type: "boolean", description: "A vendor instead of a customer" },
      },
      ["name"],
    ),
    run: async (z, a) => {
      const j = await z.send("POST", booksUrl(z, "/contacts"), {
        contact_name: arg(a, "name"),
        ...(a.company ? { company_name: a.company } : {}),
        contact_type: a.vendor ? "vendor" : "customer",
        ...(a.email ? { contact_persons: [{ email: a.email, is_primary_contact: true }] } : {}),
      });
      return j.contact ?? j;
    },
  },
  {
    name: "books_create_invoice",
    app: "books",
    description: "Create a draft invoice for a customer (sending it is a separate step).",
    risk: "medium",
    input: obj(
      {
        customer_id: s("contact_id from books_list_contacts"),
        items: {
          type: "array",
          minItems: 1,
          maxItems: 50,
          items: obj({ name: s("Item"), rate: { type: "number" }, quantity: { type: "number" } }, [
            "name",
            "rate",
          ]),
        },
        due_date: s("YYYY-MM-DD"),
        notes: s("Notes on the invoice"),
      },
      ["customer_id", "items"],
    ),
    run: async (z, a) => {
      const items = Array.isArray(a.items) ? (a.items as Array<Record<string, unknown>>) : [];
      const j = await z.send("POST", booksUrl(z, "/invoices"), {
        customer_id: arg(a, "customer_id"),
        line_items: items.map((i) => ({
          name: String(i.name ?? ""),
          rate: Number(i.rate ?? 0),
          quantity: Number(i.quantity ?? 1),
        })),
        ...(a.due_date ? { due_date: a.due_date } : {}),
        ...(a.notes ? { notes: a.notes } : {}),
      });
      return j.invoice ?? j;
    },
  },
  {
    name: "books_send_invoice",
    app: "books",
    description: "Email an invoice to the customer.",
    risk: "high",
    input: obj(
      { invoice_id: s("Invoice id"), to: s("Recipients (default: the customer's contacts)") },
      ["invoice_id"],
    ),
    run: async (z, a) =>
      z.send("POST", booksUrl(z, `/invoices/${enc(arg(a, "invoice_id"))}/email`), {
        ...(a.to ? { to_mail_ids: list(a.to) } : {}),
      }),
  },
];

const APP_LABEL = { mail: "Zoho Mail", crm: "Zoho CRM", desk: "Zoho Desk", books: "Zoho Books" };

/** The tools for the apps this account has. */
export function zohoToolsFor(cfg: ZohoConfig) {
  const has = { mail: !!cfg.mail, crm: cfg.crm, desk: !!cfg.desk, books: !!cfg.books };
  return ZOHO_TOOLS.filter((t) => has[t.app]).map((t) => ({
    name: t.name,
    description: `${APP_LABEL[t.app]}: ${t.description}`,
    inputSchema: t.input,
    risk: t.risk,
  }));
}

/** Runs one Zoho tool with an access token. Returns text for the model and the structured value. */
export async function callZohoTool(
  fetchImpl: Fetch,
  token: string,
  cfg: ZohoConfig,
  name: string,
  args: Record<string, unknown>,
): Promise<unknown> {
  const tool = ZOHO_TOOLS.find((t) => t.name === name);
  if (!tool || !zohoToolsFor(cfg).some((t) => t.name === name))
    throw new ToolError("tool_not_found", `No Zoho tool ${name} on this connection`);
  const call: ZohoCall = {
    cfg,
    get: (url, headers) => zohoJson(fetchImpl, token, url, { headers }),
    send: (method, url, body, headers) =>
      zohoJson(fetchImpl, token, url, { method, body, headers }),
  };
  return tool.run(call, args);
}

/** The adapter for a Zoho sign-in connection (`kind: "mcp"`, `config.provider: "zoho"`). */
export class ZohoAdapter {
  private readonly cfg: ZohoConfig;
  private readonly accessToken: string | null;
  private readonly fetchImpl: Fetch;
  constructor(accessToken: string | null, config: Record<string, unknown>, fetchImpl: Fetch) {
    this.accessToken = accessToken;
    this.fetchImpl = fetchImpl;
    const z = config.zoho as ZohoConfig | undefined;
    if (!z?.api_domain || !z.mail_base || !z.desk_base)
      throw new Error("Zoho connection is missing its account details; reconnect Zoho");
    this.cfg = z;
  }

  async listTools() {
    return zohoToolsFor(this.cfg);
  }

  async callTool(
    name: string,
    args: Record<string, unknown>,
    opts: { onStructured?: (value: unknown) => void } = {},
  ) {
    if (!this.accessToken)
      throw new ToolError(
        "zoho_reconnect",
        "Zoho isn't signed in. Ask the person to reconnect Zoho.",
      );
    const value = await callZohoTool(this.fetchImpl, this.accessToken, this.cfg, name, args);
    if (value && typeof value === "object") opts.onStructured?.(value);
    return JSON.stringify(value ?? {}, null, 2);
  }
}
