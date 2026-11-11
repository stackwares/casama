/**
 * About you (SPEC: About you; D-169). One profile per person that every bot they use reads: what to
 * call them, pronouns and how they like replies everywhere; "About me" and the facts bots learn
 * about them only where `profile_shared_in` allows (personal spaces, or a team space they turned
 * on). Facts about the person are saved here, private to them, never in the bot's shared memory.
 */
import { contentKeys, type Database } from "@casama/db";
import { sql } from "drizzle-orm";

export interface PersonContext {
  name: string;
  pronouns?: string;
  replyStyle?: string;
  /** "About me" and learned facts; present only where the person shares them in this space. */
  about?: string;
  facts: string[];
  /** Whether bots may save what they learn about the person. */
  learn: boolean;
}

/** Facts given to each run (newest and pinned first). */
const FACTS_IN_PROMPT = 40;
/** Facts per person; the database trigger enforces the same cap. */
export const MAX_USER_FACTS = 200;

const normalize = (s: string) =>
  s
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, " ")
    .trim();

/** The profile of the person a run acts for, filtered for this workspace. */
export async function loadPerson(
  db: Database,
  userId: string | null | undefined,
  orgId: string,
): Promise<PersonContext | null> {
  if (!userId) return null;
  const [row] = await db.execute<{
    name: string | null;
    pronouns: string | null;
    about: string | null;
    reply_style: string | null;
    learn: boolean | null;
    shared: boolean;
  }>(sql`
    select coalesce(nullif(btrim(p.preferred_name), ''), nullif(split_part(btrim(p.display_name), ' ', 1), '')) as name,
           nullif(btrim(p.pronouns), '') as pronouns, a.about, a.reply_style, a.learn,
           public.profile_shared_in(${userId}::uuid, ${orgId}::uuid) as shared
    from public.profiles p left join public.user_about a on a.user_id = p.user_id
    where p.user_id = ${userId}::uuid`);
  if (!row) return null;
  const facts = row.shared
    ? (
        await db.execute<{ content: string }>(sql`
          select content from public.user_facts where user_id = ${userId}::uuid
          order by pinned desc, updated_at desc limit ${FACTS_IN_PROMPT}`)
      ).map((f) => f.content)
    : [];
  return {
    name: row.name ?? "",
    ...(row.pronouns ? { pronouns: row.pronouns } : {}),
    ...(row.reply_style?.trim() ? { replyStyle: row.reply_style.trim() } : {}),
    ...(row.shared && row.about?.trim() ? { about: row.about.trim() } : {}),
    facts,
    learn: row.learn ?? true,
  };
}

/** Saves a fact about the person, updating the same fact instead of adding it twice. */
export async function savePersonFact(
  db: Database,
  input: {
    userId: string;
    orgId: string;
    botId: string;
    runId?: string;
    kind: "fact" | "preference";
    content: string;
  },
): Promise<{ id: string; created: boolean }> {
  const content = input.content.trim().slice(0, 500);
  const existing = await db.execute<{ id: string; content: string }>(
    sql`select id, content from public.user_facts where user_id = ${input.userId}::uuid`,
  );
  const same = existing.find((f) => normalize(f.content) === normalize(content));
  if (same) {
    await db.execute(
      sql`update public.user_facts set updated_at = now() where id = ${same.id}::uuid`,
    );
    return { id: same.id, created: false };
  }
  const [row] = await db.execute<{ id: string }>(sql`
    insert into public.user_facts (user_id, kind, content, source_org_id, source_bot_id, source_run_id)
    values (${input.userId}::uuid, ${input.kind}, ${contentKeys.sealForUser(input.userId, content)}, ${input.orgId}::uuid, ${input.botId}::uuid,
            ${input.runId ?? null}::uuid)
    returning id`);
  if (!row) throw new Error("user fact insert returned nothing");
  return { id: row.id, created: true };
}

/** The "Who you're talking with" block for the system prompt. */
export function personBlock(p: PersonContext | null | undefined): string {
  if (!p) return "";
  const lines: string[] = [];
  if (p.name)
    lines.push(
      `You're talking with ${p.name}${p.pronouns ? ` (pronouns: ${p.pronouns})` : ""}. Call them ${p.name}.`,
    );
  else if (p.pronouns)
    lines.push(`The person you're talking with uses the pronouns ${p.pronouns}.`);
  if (p.replyStyle) lines.push(`How they like replies (follow this):\n${p.replyStyle}`);
  if (p.about) lines.push(`What they shared about themselves:\n${p.about}`);
  if (p.facts.length)
    lines.push(`What you know about them:\n${p.facts.map((f) => `- ${f}`).join("\n")}`);
  return lines.join("\n\n");
}
