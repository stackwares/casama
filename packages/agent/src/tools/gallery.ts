/**
 * Gallery tools (D-315): bots look in the gallery before building something themselves, offer a
 * find as a card in the chat (the person taps **Add**; the app runs the install), and turn work
 * that went well into a skill draft the person can keep or submit. Cards are chat message parts,
 * drawn natively by the app: `gallery_suggestion` and `gallery_draft`.
 */
import type { Database } from "@casama/db";
import { parseSkillMd, SKILL_NAME } from "@casama/domain";
import { sql } from "drizzle-orm";
import { z } from "zod";
import {
  GALLERY_AGENT_KINDS,
  GALLERY_DRAFT_PART,
  GALLERY_LOOK_KINDS,
  GALLERY_SHOWN_EVENT,
  GALLERY_SUGGESTION_PART,
  type GalleryCatalog,
  type GalleryEntry,
  searchGallery,
  suggestionItem,
} from "../gallery.ts";
import { type ToolContext, ToolError, type ToolRegistry } from "./registry.ts";

export interface GalleryToolDeps {
  db: Database;
  /** The gallery with the workspace's policy applied. Without it only gallery.draft_skill exists. */
  gallery?: GalleryCatalog;
}

const Kind = z.enum(GALLERY_AGENT_KINDS);

/** `<type>/<id>` keys already in the workspace: gallery skills and connected apps, plus the server's. */
async function installedKeys(deps: GalleryToolDeps, orgId: string): Promise<Set<string>> {
  const keys = new Set<string>();
  const rows = await deps.db
    .execute<{ key: string }>(sql`
      select 'skill/' || (source_ref ->> 'id') as key from public.skills
      where org_id = ${orgId}::uuid and source in ('gallery', 'catalog') and source_ref ->> 'id' is not null
      union
      select 'app/' || (config ->> 'app') as key from public.integrations
      where org_id = ${orgId}::uuid and config ->> 'app' is not null and status <> 'error'`)
    // "Installed" is a hint for the bot; a failed lookup only loses the hint.
    .catch(() => [] as Array<{ key: string }>);
  for (const r of rows) {
    keys.add(r.key);
    // Built-in app ids use _, gallery ones -; either spelling means the same app.
    if (r.key.startsWith("app/")) keys.add(r.key.replaceAll("_", "-"));
  }
  for (const k of (await deps.gallery?.installed?.(orgId).catch(() => [])) ?? []) keys.add(k);
  return keys;
}

/** Gallery cards already shown in this conversation (and in this run, for the one-per-turn rule). */
async function shownCards(db: Database, runId: string) {
  const rows = await db.execute<{ run_id: string; payload: Record<string, unknown> }>(sql`
    select e.run_id, e.payload from public.run_events e
    where e.type = ${GALLERY_SHOWN_EVENT} and e.run_id in (
      select r.id from public.runs r where r.id = ${runId}::uuid
      union
      select r.id from public.runs r
      where r.conversation_id = (select conversation_id from public.runs where id = ${runId}::uuid))`);
  return rows.map((r) => {
    const p = r.payload ?? {};
    const item = (p.item ?? {}) as { type?: string; id?: string };
    return {
      thisRun: r.run_id === runId,
      part: String(p.type ?? ""),
      key: item.type && item.id ? `${item.type}/${item.id}` : null,
    };
  });
}

/**
 * One card of each kind per reply, even when the model calls the tool twice in one round and the
 * calls run side by side: the claim is taken synchronously, before any await, so a second call in
 * the same run sees it. A run executes in one process; claims expire after ten minutes.
 */
const replyClaims = new Map<string, number>();
function claimReplyCard(runId: string, part: string): boolean {
  const now = Date.now();
  for (const [k, at] of replyClaims) if (now - at > 10 * 60_000) replyClaims.delete(k);
  const key = `${runId}:${part}`;
  if (replyClaims.has(key)) return false;
  replyClaims.set(key, now);
  return true;
}
const releaseReplyCard = (runId: string, part: string) => replyClaims.delete(`${runId}:${part}`);

async function addPart(ctx: ToolContext, part: Record<string, unknown>) {
  await ctx.emit(GALLERY_SHOWN_EVENT, part);
}

const hitLine = (e: GalleryEntry, installed: boolean) =>
  JSON.stringify({
    type: e.type,
    id: e.id,
    name: e.name,
    description: e.description ?? "",
    ...(e.access ? { access: e.access } : {}),
    ...(e.needs && (e.needs.apps?.length || e.needs.skills?.length) ? { needs: e.needs } : {}),
    installed,
  });

/** "Weekly report" → "weekly-report", the skill's id and SKILL.md name. */
export function skillIdFor(name: string) {
  return name
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[^\w\s-]/g, "")
    .trim()
    .replace(/[\s_]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 63);
}

export function registerGalleryTools(registry: ToolRegistry, deps: GalleryToolDeps) {
  const gallery = deps.gallery;
  if (gallery) {
    registry.register({
      name: "gallery.search",
      description:
        "Search the Casama gallery for ready-made skills, routines, bots, apps, plugins and looks (themes, color schemes, wallpapers). Look here first when the person wants something you can't do yet, something that should run on a schedule, or a new look (\"make me a dark green theme\"), before building it yourself. Returns up to 5 matches with what each can access and whether it's already installed. Offer one with gallery.suggest.",
      risk: "low",
      readOnly: true,
      schema: z.object({
        query: z.string().min(1).max(200).describe('Plain words, e.g. "summarize unread email"'),
        types: z
          .array(Kind)
          .max(GALLERY_AGENT_KINDS.length)
          .optional()
          .describe("Only these kinds; all kinds when left out"),
      }),
      async execute(args, ctx) {
        const items = await gallery.items(ctx.orgId).catch(() => null);
        if (!items)
          return { content: "The gallery can't be reached right now.", preview: "gallery offline" };
        const synonyms = await gallery.searchWords?.().catch(() => undefined);
        const hits = searchGallery(items, args.query, { types: args.types, limit: 5, synonyms });
        if (!hits.length)
          return {
            content: `Nothing in the gallery matches "${args.query}". Build it yourself if you can (a skill with skills.create, a routine with routines.create), or say what's missing.`,
            preview: "no matches",
          };
        const have = await installedKeys(deps, ctx.orgId);
        return {
          content: `Gallery matches (best first):\n${hits.map((h) => hitLine(h, have.has(`${h.type}/${h.id}`))).join("\n")}\n\nOffer the one that fits with gallery.suggest; use an installed one directly.`,
          preview: `${hits.length} match${hits.length === 1 ? "" : "es"}`,
        };
      },
    });

    registry.register({
      name: "gallery.suggest",
      description:
        "Offer one gallery item (from gallery.search) as a card in the chat with an Add button; the person reviews what it can access and adds it themselves, answering any setup questions. One card per reply, never the same item twice in a conversation. You don't hear back; keep going, and don't say it's installed.",
      risk: "low",
      readOnly: true,
      schema: z.object({
        type: Kind,
        id: z.string().min(1).max(128),
        reason: z
          .string()
          .min(1)
          .max(300)
          .describe("One sentence for the person: why this helps with what they asked"),
      }),
      async execute(args, ctx) {
        const items = await gallery.items(ctx.orgId).catch(() => null);
        if (!items)
          throw new ToolError("gallery_unavailable", "The gallery can't be reached right now.");
        const item = items.find((i) => i.type === args.type && i.id === args.id);
        if (!item)
          throw new ToolError(
            "gallery_item_not_found",
            `No ${args.type} called ${args.id} in the gallery. Use an id from gallery.search.`,
          );
        if (item.retired)
          throw new ToolError("gallery_item_retired", `${item.name} is retired; pick another.`);
        if (item.blocked)
          throw new ToolError(
            "gallery_blocked",
            `This workspace doesn't allow ${item.name}. Don't offer it.`,
          );
        const key = `${item.type}/${item.id}`;
        if (
          !GALLERY_LOOK_KINDS.includes(item.type) &&
          (await installedKeys(deps, ctx.orgId)).has(key)
        )
          return {
            content: `${item.name} is already installed in this workspace; use it instead of offering it.`,
            preview: "already installed",
          };
        const oneOnly = () =>
          new ToolError(
            "one_suggestion_per_reply",
            "You already offered a gallery item in this reply. Offer at most one per reply.",
          );
        if (!claimReplyCard(ctx.runId, GALLERY_SUGGESTION_PART)) throw oneOnly();
        try {
          const shown = (await shownCards(deps.db, ctx.runId)).filter(
            (s) => s.part === GALLERY_SUGGESTION_PART,
          );
          if (shown.some((s) => s.thisRun)) throw oneOnly();
          if (shown.some((s) => s.key === key))
            throw new ToolError(
              "already_suggested",
              `You already offered ${item.name} in this conversation. Don't offer it again.`,
            );
          await addPart(ctx, {
            type: GALLERY_SUGGESTION_PART,
            item: suggestionItem(item),
            reason: args.reason.trim(),
          });
        } catch (e) {
          releaseReplyCard(ctx.runId, GALLERY_SUGGESTION_PART);
          throw e;
        }
        return {
          content: `The card for ${item.name} is under your reply. The person adds it there if they want; don't say it's installed.`,
          preview: `suggested ${item.name}`,
        };
      },
    });
  }

  registry.register({
    name: "gallery.draft_skill",
    description:
      'Turn something that worked well into a skill draft: shows a card under your reply with "Save to my skills" and "Submit to the gallery". Use it when the person says "make this a skill", or offer it after a multi-step task they\'ll likely repeat. Write instructions another bot can follow: numbered steps, what to ask first, what to produce. No secrets, names or private details.',
    risk: "low",
    readOnly: true,
    schema: z.object({
      name: z.string().min(2).max(60).describe('A short title, e.g. "Weekly report"'),
      description: z
        .string()
        .min(10)
        .max(300)
        .describe("One sentence: what it does and when to use it"),
      instructions_md: z
        .string()
        .min(20)
        .max(20_000)
        .describe("The skill's instructions in Markdown (no front matter)"),
    }),
    async execute(args, ctx) {
      const id = skillIdFor(args.name);
      if (!SKILL_NAME.test(id))
        throw new ToolError("bad_name", "Give the skill a name with some letters or digits.");
      const description = args.description.replace(/\s+/g, " ").trim();
      const body = args.instructions_md.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n?/, "").trim();
      const skillMd = `---\nname: ${id}\ndescription: ${description}\n---\n\n${body.startsWith("#") ? "" : `# ${args.name.trim()}\n\n`}${body}\n`;
      try {
        parseSkillMd(skillMd);
      } catch (e) {
        throw new ToolError("bad_skill", `That isn't a valid skill: ${(e as Error).message}`);
      }
      const oneDraft = () =>
        new ToolError("one_draft_per_reply", "You already made a skill draft in this reply.");
      if (!claimReplyCard(ctx.runId, GALLERY_DRAFT_PART)) throw oneDraft();
      const shown = await shownCards(deps.db, ctx.runId).catch((e) => {
        releaseReplyCard(ctx.runId, GALLERY_DRAFT_PART);
        throw e;
      });
      if (shown.some((s) => s.thisRun && s.part === GALLERY_DRAFT_PART)) throw oneDraft();
      await addPart(ctx, {
        type: GALLERY_DRAFT_PART,
        draft: {
          type: "skill",
          id,
          item: {
            name: args.name.trim(),
            description,
            license: "Apache-2.0",
            tags: [],
            featured: false,
            version: 1,
          },
          files: { "SKILL.md": skillMd },
        },
      });
      return {
        content: `The draft "${args.name.trim()}" is under your reply; the person saves it to their skills or submits it to the gallery there.`,
        preview: `drafted ${id}`,
      };
    },
  });
}
