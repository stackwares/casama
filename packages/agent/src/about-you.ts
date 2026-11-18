/**
 * About you (SPEC: About you; D-169). One profile per person that every bot they use reads: what to
 * call them, pronouns and how they like replies everywhere; "About me" and the facts bots learn
 * about them only where `profile_shared_in` allows (personal spaces, or a team space they turned
 * on). Facts about the person are saved here, private to them, never in the bot's shared memory.
 */
import { contentKeys, type Database } from "@casama/db";
import { sql } from "drizzle-orm";
import { permissionLines } from "./permission-cards.ts";

export interface PersonContext {
  name: string;
  pronouns?: string;
  replyStyle?: string;
  /** "About me" and learned facts; present only where the person shares them in this space. */
  about?: string;
  facts: string[];
  /** Whether bots may save what they learn about the person. */
  learn: boolean;
  /** Device connections (D-149): kinds the person shares from a device, and those this bot may read. */
  devices?: { shared: string[]; allowed: string[] };
  /** System permissions that are off on their devices, one line per device (D-376). */
  permissions?: string[];
}

const DEVICE_LABEL: Record<string, string> = {
  health: "health data (sleep, steps, heart rate, workouts)",
  activity: "computer activity",
  places: "places (visits)",
};

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
  botId?: string,
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
  // What they share from their phone or computer, so the bot reaches for device.read instead of
  // saying nothing is connected (it once looked only at connected apps).
  const devices = botId
    ? await db.execute<{ kind: string; allowed: boolean }>(sql`
        select k.kind, exists (select 1 from public.device_grants g where g.user_id = ${userId}::uuid
          and g.bot_id = ${botId}::uuid and g.kind = k.kind) as allowed
        from (select distinct jsonb_object_keys(kinds) as kind from public.device_sources where user_id = ${userId}::uuid) k
        order by k.kind`)
    : [];
  // What's switched off on their devices, so the bot doesn't try what can't work (D-376).
  const permissions = botId ? await permissionLines(db, userId, botId).catch(() => []) : [];
  return {
    ...(permissions.length ? { permissions } : {}),
    ...(devices.length
      ? {
          devices: {
            shared: devices.map((d) => d.kind),
            allowed: devices.filter((d) => d.allowed).map((d) => d.kind),
          },
        }
      : {}),
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
  if (p.devices?.shared.length) {
    const label = (k: string) => DEVICE_LABEL[k] ?? k;
    const waiting = p.devices.shared.filter((k) => !p.devices!.allowed.includes(k));
    lines.push(
      [
        `They share from their own phone or computer: ${p.devices.shared.map(label).join(", ")}. Read it with device.read (tools group "device"), not a connected app.`,
        p.devices.allowed.length ? `You may read: ${p.devices.allowed.map(label).join(", ")}.` : "",
        waiting.length
          ? `Not allowed for you yet: ${waiting.map(label).join(", ")}. Try device.read anyway when you need it: they get a one-tap card to allow it.`
          : "",
      ]
        .filter(Boolean)
        .join(" "),
    );
  }
  if (p.permissions?.length)
    lines.push(
      `Off on their devices: ${p.permissions.join(" ")} If you need one, device.request_permission shows them a card to turn it on.`,
    );
  return lines.join("\n\n");
}
