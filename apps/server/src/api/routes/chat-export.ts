/**
 * Taking a chat out of Casama (D-282): a Markdown or JSON download, and a public read-only link
 * on the pages origin. Both read the chat in the person's own session, so they see only what
 * row-level security lets them see.
 */
import { hashPageToken, newPageToken } from "@casama/agent";
import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { requireClaims } from "./autonomy.ts";

export interface ExportedMessage {
  role: "user" | "assistant";
  author: string;
  text: string;
  attachments: string[];
  created_at: string;
}

/** The readable messages of a chat's shown branch, oldest first. */
export async function readableThread(
  tx: Parameters<Parameters<typeof withUserSession>[2]>[0],
  conversationId: string,
  botName: string,
): Promise<ExportedMessage[]> {
  const rows = await tx.execute<{
    role: string;
    content: Array<Record<string, unknown>> | null;
    created_at: string | Date;
  }>(
    sql`select role, content, created_at from public.conversation_thread(${conversationId}::uuid, null, null, null)`,
  );
  const out: ExportedMessage[] = [];
  for (const r of rows) {
    if (r.role !== "user" && r.role !== "assistant") continue;
    const parts = Array.isArray(r.content) ? r.content : [];
    const text = parts
      .filter((p) => p.type === "text" && typeof p.text === "string")
      .map((p) => p.text as string)
      .join("\n\n")
      .trim();
    const attachments = parts
      .filter((p) => p.type === "file" || p.type === "page" || p.type === "creation")
      .map((p) => String(p.name ?? p.title ?? p.path ?? "attachment"));
    if (!text && !attachments.length) continue;
    out.push({
      role: r.role,
      author: r.role === "user" ? "You" : botName,
      text,
      attachments,
      created_at: new Date(r.created_at).toISOString(),
    });
  }
  return out;
}

export function threadMarkdown(title: string, messages: ExportedMessage[]) {
  const lines = [`# ${title}`, ""];
  for (const m of messages) {
    lines.push(`**${m.author}** · ${m.created_at.slice(0, 16).replace("T", " ")} UTC`, "");
    if (m.text) lines.push(m.text, "");
    for (const a of m.attachments) lines.push(`- 📎 ${a}`);
    if (m.attachments.length) lines.push("");
  }
  return `${lines.join("\n").trim()}\n`;
}

export function registerChatExportRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  const conversationOf = async (claims: JwtClaims, id: string) => {
    const [c] = await withUserSession(db, claims, (tx) =>
      tx.execute<{
        id: string;
        title: string | null;
        bot_name: string;
        private: boolean;
        can_share: boolean;
      }>(sql`
        select c.id, c.title, b.name as bot_name, c.private,
               (c.created_by = ${claims.sub}::uuid or public.can_manage_bot(c.bot_id)) as can_share
        from public.conversations c join public.bots b on b.id = c.bot_id where c.id = ${id}::uuid`),
    );
    if (!c) throw new ApiError(404, "conversation_not_found", "Conversation not found");
    return c;
  };

  app.openapi(routes.exportConversation, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const format = c.req.valid("query").format ?? "markdown";
    const conv = await conversationOf(claims, id);
    const messages = await withUserSession(db, claims, (tx) =>
      readableThread(tx, id, conv.bot_name),
    );
    const title = conv.title?.trim() || `Chat with ${conv.bot_name}`;
    const name =
      title
        .replace(/[^\w -]+/g, "")
        .trim()
        .slice(0, 80) || "chat";
    if (format === "json")
      return c.body(JSON.stringify({ title, bot: conv.bot_name, messages }, null, 2), 200, {
        "content-type": "application/json; charset=utf-8",
        "content-disposition": `attachment; filename="${name}.json"`,
      }) as never;
    return c.body(threadMarkdown(title, messages), 200, {
      "content-type": "text/markdown; charset=utf-8",
      "content-disposition": `attachment; filename="${name}.md"`,
    }) as never;
  });

  app.openapi(routes.shareConversation, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { public: on } = c.req.valid("json");
    const conv = await conversationOf(claims, id);
    if (!conv.can_share)
      throw new ApiError(
        403,
        "forbidden",
        "Only the person who started this chat or the bot's managers can share it",
      );
    if (on && conv.private)
      throw new ApiError(
        409,
        "chat_private",
        "This chat holds personal data from a device, so it can't be shared publicly",
      );
    const token = on ? newPageToken() : null;
    await db.execute(sql`
      update public.conversations set public_token_hash = ${token ? hashPageToken(token) : null},
        shared_at = ${on ? sql`now()` : sql`null`}
      where id = ${id}::uuid`);
    return c.json(
      { url: token ? `${deps.env.PAGES_URL.replace(/\/$/, "")}/t/${token}` : null },
      200,
    );
  });
}
