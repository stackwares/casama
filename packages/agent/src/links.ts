/**
 * Linked agents (SPEC: Linked agents; D-143). `links.ask(contact, request)` sends a structured
 * request to a linked bot. On the same server it runs as the other bot under its own owner (their
 * approvals, rules and budgets); across Kasama servers it goes over A2A with the link's token.
 * The answering bot is told to share only what the request needs. Both sides record the exchange,
 * and the receiving owner is notified.
 */
import { createHash, randomBytes } from "node:crypto";
import type { Database } from "@kasama/db";
import { contentKeys } from "@kasama/db";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { A2aClient } from "./a2a.ts";
import type { NotificationService } from "./notifications.ts";
import { ToolError, type ToolRegistry } from "./tools/registry.ts";

export const hashLinkToken = (t: string) => createHash("sha256").update(t).digest("hex");
export const newLinkToken = () => `klink_${randomBytes(24).toString("base64url")}`;

/** The text a linked bot receives. */
export function linkedRequestText(o: { fromBot: string; fromOwner: string; request: string }) {
  return [
    `(A request from ${o.fromBot}, the linked assistant of ${o.fromOwner}.)`,
    o.request,
    "",
    "Answer for your own person, under their rules. Share only what this request needs (for a scheduling question, the times that work, not why). Say no to anything your person wouldn't want shared.",
  ].join("\n");
}

type LinkRow = {
  id: string;
  org_id: string;
  bot_id: string;
  name: string;
  peer_link_id: string | null;
  peer_bot_id: string | null;
  peer_bot_name: string | null;
  remote_url: string | null;
  outbound_token: string | null;
};

/** Starts a run on a local bot for a linked request; returns the run id. */
export async function startLinkedRun(db: Database, link: { id: string; org_id: string; bot_id: string; owner_user_id: string }, text: string) {
  const [conv] = await db.execute<{ id: string }>(sql`
    insert into public.conversations (org_id, bot_id, title, created_by, last_message_at)
    values (${link.org_id}::uuid, ${link.bot_id}::uuid, ${`Linked: ${text.split("\n")[1]?.slice(0, 60) ?? "request"}`}, ${link.owner_user_id}::uuid, now()) returning id`);
  const [run] = await db.execute<{ id: string }>(sql`
    insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger)
    values (${link.org_id}::uuid, ${link.bot_id}::uuid, ${conv?.id}::uuid, ${link.owner_user_id}::uuid, 'link') returning id`);
  await db.execute(sql`
    insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
    values (${link.org_id}::uuid, ${conv?.id}::uuid, 'user', ${link.owner_user_id}::uuid, ${contentKeys.sealJson(link.org_id, [{ type: "text", text }])}::jsonb, ${run?.id}::uuid)`);
  return run?.id as string;
}

/** The final answer of a finished run, or null while it's still going. */
export async function runAnswer(db: Database, runId: string): Promise<{ done: boolean; ok: boolean; text: string }> {
  const [r] = await db.execute<{ status: string }>(sql`select status from public.runs where id = ${runId}::uuid`);
  if (!r || !["completed", "failed", "cancelled"].includes(r.status)) return { done: false, ok: false, text: "" };
  const [m] = await db.execute<{ content: Array<{ type?: string; text?: string }> }>(sql`
    select content from public.messages where run_id = ${runId}::uuid and role = 'assistant' order by created_at desc limit 1`);
  const text = (Array.isArray(m?.content) ? m.content : []).filter((p) => p.type === "text").map((p) => p.text ?? "").join("");
  return { done: true, ok: r.status === "completed", text };
}

export interface LinkToolDeps {
  db: Database;
  notifications?: NotificationService;
  startRun?: (runId: string) => Promise<void>;
  fetch?: typeof fetch;
  maxWaitMs?: number;
}

export function registerLinkTools(registry: ToolRegistry, deps: LinkToolDeps) {
  const { db } = deps;
  registry.register({
    name: "links.ask",
    description:
      "Ask a linked contact's assistant something on the person's behalf (\"find a dinner slot for 4 next week\", \"is Thursday's meeting still on?\"). Name the contact as the link is named, and say exactly what you need; their assistant answers under its own person's rules and shares only what's needed. Include only what the request needs from your side too.",
    risk: "medium",
    category: "send",
    schema: z.object({ contact: z.string().min(1).max(100), request: z.string().min(1).max(4000) }),
    async execute(args, ctx) {
      const links = await db.execute<LinkRow>(sql`
        select l.id, l.org_id, l.bot_id, l.name, l.peer_link_id, l.peer_bot_id, l.peer_bot_name, l.remote_url, v.decrypted_secret as outbound_token
        from public.bot_links l left join vault.decrypted_secrets v on v.id = l.outbound_secret_id
        where l.bot_id = ${ctx.botId}::uuid and l.status = 'active'`);
      const want = args.contact.toLowerCase();
      const link = links.find((l) => l.name.toLowerCase() === want || l.peer_bot_name?.toLowerCase() === want) ?? links.find((l) => l.name.toLowerCase().includes(want));
      if (!link) throw new ToolError("no_such_link", links.length ? `No linked contact called "${args.contact}". Linked: ${links.map((l) => l.name).join(", ")}.` : "This bot has no linked contacts yet.");
      const [me] = await db.execute<{ bot: string; owner: string }>(sql`
        select b.name as bot, coalesce(p.display_name, 'their person') as owner
        from public.runs r join public.bots b on b.id = r.bot_id left join public.profiles p on p.user_id = r.created_by
        where r.id = ${ctx.runId}::uuid`);
      const text = linkedRequestText({ fromBot: me?.bot ?? "an assistant", fromOwner: me?.owner ?? "their person", request: args.request });
      const [ex] = await db.execute<{ id: string }>(sql`
        insert into public.link_exchanges (link_id, org_id, direction, request, run_id) values (${link.id}::uuid, ${link.org_id}::uuid, 'out', ${args.request}, ${ctx.runId}::uuid) returning id`);
      const finish = async (answer: string, ok: boolean) => {
        await db.execute(sql`update public.link_exchanges set response = ${answer.slice(0, 20_000)}, status = ${ok ? "answered" : "failed"}, answered_at = now() where id = ${ex?.id}::uuid`);
        return { content: ok ? `${link.name} answered:\n${answer}` : `${link.name}'s assistant couldn't answer${answer ? `: ${answer}` : "."}`, preview: ok ? answer.slice(0, 120) : "no answer" };
      };

      if (link.remote_url) {
        // Another Kasama server: A2A with this link's token.
        if (!link.outbound_token || !link.peer_bot_id) throw new ToolError("link_broken", "This link is missing its connection details; link again.");
        const client = new A2aClient({ url: `${link.remote_url.replace(/\/$/, "")}/a2a/${link.peer_bot_id}`, token: link.outbound_token, fetch: deps.fetch });
        try {
          const r = await client.send(text, { waitMs: deps.maxWaitMs ?? 5 * 60_000, onProgress: (s) => void ctx.output(`${s}\n`).catch(() => {}) });
          return finish(r.text, r.task?.status.state === "TASK_STATE_COMPLETED" || r.kind === "message");
        } catch (e) {
          return finish((e as Error).message, false);
        }
      }

      // Same server: the other bot runs under its own owner.
      const [peer] = await db.execute<{ id: string; org_id: string; bot_id: string; owner_user_id: string; status: string }>(sql`
        select id, org_id, bot_id, owner_user_id, status from public.bot_links where id = ${link.peer_link_id}::uuid`);
      if (!peer || peer.status !== "active") throw new ToolError("link_revoked", `${link.name} isn't linked anymore.`);
      const runId = await startLinkedRun(db, peer, text);
      const [inEx] = await db.execute<{ id: string }>(sql`
        insert into public.link_exchanges (link_id, org_id, direction, request, run_id) values (${peer.id}::uuid, ${peer.org_id}::uuid, 'in', ${args.request}, ${runId}::uuid) returning id`);
      await deps.notifications
        ?.notify(peer.owner_user_id, peer.org_id, "link_exchange", { title: `${me?.bot ?? "A linked assistant"} asked your bot`, body: args.request.slice(0, 200), link: `/bots/${peer.bot_id}/links`, bot_id: peer.bot_id })
        .catch(() => {});
      await deps.startRun?.(runId);
      const until = Date.now() + (deps.maxWaitMs ?? 5 * 60_000);
      for (;;) {
        const a = await runAnswer(db, runId);
        if (a.done) {
          await db.execute(sql`update public.link_exchanges set response = ${a.text.slice(0, 20_000)}, status = ${a.ok ? "answered" : "failed"}, answered_at = now() where id = ${inEx?.id}::uuid`);
          return finish(a.text, a.ok);
        }
        if (Date.now() > until) return { content: `${link.name}'s assistant is still working on it (it may be waiting for its person's approval).`, preview: "still working" };
        await new Promise((r) => setTimeout(r, 500));
      }
    },
  });
}
