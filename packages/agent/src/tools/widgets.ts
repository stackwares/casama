/**
 * Bot widgets (docs/BOT-WIDGET-PLAN.md §8): `widget.set`, `widget.clear` and `widget.list`. A bot
 * puts a verse, a countdown, a number, a list or a picture on the person's Canvas widget, kept
 * changing by a rotation (a list written once, cycled by the clock), a schedule of dated entries,
 * or a routine writing on the day. The person allows each bot once (Show on my widgets); after
 * that it writes without asking, from chats and routines.
 */
import type { Database } from "@casama/db";
import {
  CANVAS_FONTS,
  CANVAS_LIMITS,
  CANVAS_PAINTING_NAMES,
  type CanvasBackground,
  type CanvasContent,
  type CanvasEntryBody,
  CanvasError,
  type CanvasLook,
  type CanvasPainting,
  type CanvasRhythm,
  checkEntry,
  checkSchedule,
  DEFAULT_LOOK,
  type EntryInput,
  isValidTimezone,
  normalizeColor,
  parseClock,
  parseItemsFile,
  rhythmWords,
  rotationAt,
} from "@casama/domain";
import type { ObjectStore } from "@casama/sandbox";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "../acting.ts";
import {
  CanvasLimitError,
  type CanvasRow,
  canvasOut,
  clearCanvases,
  listCanvases,
  type Placement,
  picturesOf,
  placements,
  placementWords,
  saveCanvas,
  widgetsAllowed,
  writesLeft,
} from "../canvas.ts";
import {
  type CanvasPicture,
  loadPictureSource,
  preparePicture,
  prunePictures,
  storePicture,
} from "../canvas-pictures.ts";
import { readMedia } from "../media-store.ts";
import { type ToolContext, ToolError, type ToolRegistry } from "./registry.ts";

export interface WidgetToolDeps {
  db: Database;
  objects?: ObjectStore | null;
  /** Fetches picture links (the egress-guarded fetch). */
  fetch?: typeof fetch;
  /** A shown canvas changed: tell the person's widgets (GlancePusher.changed, urgent). */
  changed?: (userId: string) => void;
}

const Color = z.string().regex(/^#?[0-9a-fA-F]{6}$/, "a colour as #rrggbb");
const PictureRef = z
  .string()
  .min(3)
  .max(2000)
  .describe(
    "An https link to a picture, media:<id> of a chat file or Library item, or a file on your computer",
  );

const Background = z
  .object({
    color: Color.optional(),
    gradient: z.array(Color).length(2).optional().describe("Two colours, top to bottom"),
    picture: PictureRef.optional(),
    painting: z.enum(CANVAS_PAINTING_NAMES as [CanvasPainting, ...CanvasPainting[]]).optional(),
  })
  .describe(
    `One of: color, gradient, picture, or a built-in painting (${CANVAS_PAINTING_NAMES.join(", ")}). Leave it out for the app's own white or dark surface. You never choose the text colour: it is picked for contrast.`,
  );

/** The fields of one entry (§6.1). */
const entryFields = {
  template: z
    .enum(["text", "countdown", "number", "list", "picture"])
    .optional()
    .describe("text (default), countdown, number, list or picture"),
  title: z.string().max(200).optional(),
  text: z.string().max(1000).optional().describe("text: the words; picture: the caption"),
  footer: z
    .string()
    .max(200)
    .optional()
    .describe('A small line under it: "Ps 46:10", "Keep going"'),
  target: z
    .string()
    .max(40)
    .optional()
    .describe("countdown: the moment, ISO 8601 with the person's offset"),
  count: z.enum(["down", "up"]).optional().describe("countdown: up counts the time since"),
  value: z.number().optional().describe("number: the value"),
  of: z.number().optional().describe("number: the goal, drawn as a ring or bar"),
  unit: z.string().max(40).optional(),
  items: z
    .array(z.string().max(200))
    .max(10)
    .optional()
    .describe('list: up to 5 rows; start a row with "[x] " when it is done'),
  picture: PictureRef.optional().describe("picture: the picture"),
  short: z
    .string()
    .max(200)
    .optional()
    .describe("Optional: up to 80 characters for the Lock Screen rectangle and watches"),
  tiny: z
    .string()
    .max(100)
    .optional()
    .describe("Optional: up to 24 characters for the line above the clock"),
};
const EntryArgs = z.object({
  ...entryFields,
  background: Background.optional(),
  icon: z.string().max(32).optional(),
});
const ScheduledArgs = EntryArgs.extend({
  at: z.string().max(40).describe("When it shows from, ISO 8601 with offset"),
});

const SetArgs = z.object({
  name: z
    .string()
    .max(40)
    .optional()
    .describe(
      'Which canvas, e.g. "Daily verse". A new name makes a new one (up to 3). Default "Main"',
    ),
  ...entryFields,
  background: Background.optional(),
  font: z.enum(CANVAS_FONTS).optional().describe("plain (default), serif, rounded or mono"),
  align: z.enum(["start", "center"]).optional(),
  icon: z.string().max(32).optional().describe("One emoji or an icon name"),
  accent: Color.optional().describe("Colour of rings and bars"),
  schedule: z
    .array(ScheduledArgs)
    .max(13)
    .optional()
    .describe("Up to 13 more entries after this one, each with at: the widget switches by itself"),
  rotate: z
    .object({
      every: z.enum(["day", "week", "hours"]),
      hours: z.number().int().min(1).max(23).optional().describe('With every "hours": how many'),
      at: z
        .string()
        .max(5)
        .optional()
        .describe('Days and weeks: the local time it changes, "06:00"'),
      weekday: z
        .enum(["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"])
        .optional(),
      order: z.enum(["in_order", "shuffle"]).optional(),
      at_end: z
        .enum(["loop", "stop"])
        .optional()
        .describe("At the end: loop (default) or stop on the last"),
    })
    .optional()
    .describe(
      "Make it a rotation: the canvas cycles through items on this rhythm with no more runs",
    ),
  rotate_items: z
    .array(EntryArgs)
    .max(CANVAS_LIMITS.itemsPerCall)
    .optional()
    .describe(
      `The rotation's items, up to ${CANVAS_LIMITS.itemsPerCall} per call, each like an entry ({text, footer} for a verse). For more, use append or rotate_file`,
    ),
  rotate_file: z
    .string()
    .max(1000)
    .optional()
    .describe(
      "The rotation's items from a file on your computer or media:<id>: JSON (a list of strings or entries), CSV with a header row (text, footer, title…), or one item per line",
    ),
  append: z.boolean().optional().describe("Add the items to the rotation already there"),
  until: z.string().max(40).optional().describe("When to clear it by itself, ISO 8601"),
  private: z
    .boolean()
    .optional()
    .describe("True for anything personal: it then isn't shown on a locked phone"),
});
type SetArgs = z.infer<typeof SetArgs>;

const WEEKDAYS = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"];

const DESCRIPTION = `Put something on the person's Canvas widget (iPhone, iPad and Mac widgets, the Lock Screen, Android home and lock screen): a text (a verse, a quote, a status), a countdown, a number (a streak, a goal), a short list or a picture, with a background, a type style and an icon.
Keep it changing the cheapest way that fits: rotate (write a list once, up to 400 items; it cycles every day, week or few hours with no more runs: verses, quotes, words, photos), schedule (up to 14 dated entries in one call: this week's plan), or write on the day from a routine only for what can't be known ahead (a headline, the weather).
The Lock Screen shows only about 80 characters (short) and 24 above the clock (tiny); they're made for you if you leave them out. Never put secrets, codes, another person's details or advertising on a widget; set private for anything personal. Say where it shows only from this tool's answer: the person may still need to add the Canvas widget.`;

export function registerWidgetTools(registry: ToolRegistry, deps: WidgetToolDeps) {
  const { db } = deps;

  /** The person a run acts for: a canvas is never for anyone else (not the bot's maker). */
  const person = async (ctx: ToolContext) => {
    const acting = await actingUserOf(db, ctx.runId);
    if (!acting)
      throw new ToolError(
        "no_person",
        "This run isn't working for one person, so it has no widgets to write to.",
      );
    const [p] = await db.execute<{ timezone: string | null }>(sql`
      select timezone from public.profiles where user_id = ${acting}::uuid`);
    const tz = p?.timezone && isValidTimezone(p.timezone) ? p.timezone : "UTC";
    return { userId: acting, timezone: tz };
  };

  const runTrigger = async (runId: string, userId: string) => {
    const [r] = await db.execute<{ trigger: string; name: string | null }>(sql`
      select r.trigger, (select split_part(p.display_name, ' ', 1) from public.profiles p
                         where p.user_id = ${userId}::uuid) as name
      from public.runs r where r.id = ${runId}::uuid`);
    return { chat: r?.trigger === "chat" || r?.trigger === "welcome", name: r?.name || null };
  };

  /** Turns the bot's background into a look's, fetching a picture when there is one. */
  const background = async (
    bg: z.infer<typeof Background> | undefined,
    pic: (ref: string) => Promise<CanvasPicture>,
  ): Promise<CanvasBackground | undefined> => {
    if (!bg) return undefined;
    const given = [bg.color, bg.gradient, bg.picture, bg.painting].filter((v) => v !== undefined);
    if (given.length > 1)
      throw new ToolError(
        "bad_background",
        "Give one background: color, gradient, picture or painting.",
      );
    if (bg.color) return { kind: "color", color: normalizeColor(bg.color) as string };
    if (bg.gradient)
      return {
        kind: "gradient",
        from: normalizeColor(bg.gradient[0]) as string,
        to: normalizeColor(bg.gradient[1]) as string,
      };
    if (bg.painting) return { kind: "painting", name: bg.painting };
    if (bg.picture) {
      const p = await pic(bg.picture);
      return { kind: "picture", picture: p.hash, tone: p.tone };
    }
    return { kind: "auto" };
  };

  const entryOf = async (
    a: z.infer<typeof EntryArgs> | string,
    pic: (ref: string) => Promise<CanvasPicture>,
    where: string | undefined,
    cuts: string[],
  ): Promise<CanvasEntryBody> => {
    const input: EntryInput & { picture?: string } =
      typeof a === "string"
        ? { text: a }
        : {
            ...a,
            items: (a.items as Array<string | { text: string; done?: boolean }> | undefined)?.map(
              (t) => {
                if (typeof t !== "string") return t;
                const done = /^\s*\[x\]\s*/i.exec(t);
                return done
                  ? { text: t.slice(done[0].length), done: true }
                  : { text: t, done: false };
              },
            ),
          };
    const p = typeof a !== "string" && a.picture ? await pic(a.picture) : undefined;
    const { entry, cut } = (() => {
      try {
        return checkEntry(input, {
          picture: p ? { hash: p.hash, tone: p.tone } : undefined,
          where,
        });
      } catch (e) {
        if (e instanceof CanvasError) throw new ToolError(e.code, e.message);
        throw e;
      }
    })();
    cuts.push(...cut);
    if (typeof a !== "string") {
      const look: Partial<CanvasLook> = {};
      const bg = await background(a.background, pic);
      if (bg) look.background = bg;
      if (a.icon) look.icon = a.icon.trim();
      if (Object.keys(look).length) entry.look = look;
    }
    return entry;
  };

  const readItemsFile = async (
    ref: string,
    ctx: ToolContext,
  ): Promise<{ text: string; name: string }> => {
    const media = /^media:([0-9a-f-]{36})$/i.exec(ref.trim())?.[1];
    if (media) {
      const [row] = await db.execute<{ name: string | null }>(sql`
        select name from public.chat_media where id = ${media}::uuid and org_id = ${ctx.orgId}::uuid`);
      const data = row ? await readMedia(db, deps.objects, media) : null;
      if (!data) throw new ToolError("file_not_found", `There's no chat file ${ref}.`);
      return { text: new TextDecoder().decode(data.subarray(0, 2_000_000)), name: row?.name ?? "" };
    }
    if (!ctx.computer)
      throw new ToolError(
        "file_not_found",
        `${ref} would be on your computer, and you don't have one here.`,
      );
    const path = ref.trim().startsWith("workspace/") ? `~/${ref.trim()}` : ref.trim();
    const data = await (await ctx.computer()).readFile(path).catch(() => {
      throw new ToolError("file_not_found", `There's no file at ${ref} on your computer.`);
    });
    if (data.length > 2_000_000)
      throw new ToolError("file_too_large", "The items file is over 2 MB.");
    return { text: new TextDecoder().decode(data), name: path.split("/").pop() ?? "" };
  };

  const answerWhere = (list: Placement[], name: string | null) => {
    const who = name ?? "The person";
    if (!list.length)
      return `${who} hasn't added the Canvas widget yet, so it isn't showing anywhere. The card in the chat shows how to add it: tell them.`;
    return `Showing on ${placementWords(list)}.`;
  };

  const lockForm = (r: CanvasRow) => {
    const out = canvasOut(r);
    const e = out.entries[0];
    return e ? `The Lock Screen shows: "${e.short}"; above the clock: "${e.tiny}".` : "";
  };

  registry.register({
    name: "widget.set",
    description: DESCRIPTION,
    risk: "low",
    selfOnly: true,
    schema: SetArgs,
    async execute(args: SetArgs, ctx) {
      const { userId, timezone } = await person(ctx);
      const now = new Date();
      const name =
        (args.name ?? "Main").replace(/\s+/g, " ").trim().slice(0, CANVAS_LIMITS.name) || "Main";
      const cuts: string[] = [];
      const pictures = new Map<string, CanvasPicture>();
      const byRef = new Map<string, CanvasPicture>();
      const pic = async (ref: string) => {
        const hit = byRef.get(ref);
        if (hit) return hit;
        if (byRef.size >= CANVAS_LIMITS.rotationPictures)
          throw new ToolError(
            "too_many_pictures",
            `A canvas holds at most ${CANVAS_LIMITS.rotationPictures} different pictures.`,
          );
        const p = await preparePicture(await loadPictureSource(ref, ctx, deps));
        byRef.set(ref, p);
        pictures.set(p.hash, p);
        return p;
      };

      const [old] = await listCanvases(db, { userId, orgId: ctx.orgId, botId: ctx.botId }).then(
        (l) => l.filter((c) => c.name === name),
      );

      // The look: what the bot gave, else what this canvas had (an append keeps it).
      const baseLook = old?.content.look ?? DEFAULT_LOOK;
      const look: CanvasLook = {
        background:
          (await background(args.background, pic)) ??
          (args.append ? baseLook.background : DEFAULT_LOOK.background),
        font: args.font ?? (args.append ? baseLook.font : "plain"),
        align: args.align ?? (args.append ? baseLook.align : "start"),
        icon: args.icon?.trim() || (args.append ? baseLook.icon : null),
        accent:
          (args.accent && normalizeColor(args.accent)) || (args.append ? baseLook.accent : null),
      };

      let content: CanvasContent;
      const wantsRotation =
        !!args.rotate || !!args.rotate_items || !!args.rotate_file || !!args.append;
      if (wantsRotation) {
        const prev = old?.content.rotation;
        const inputs: Array<z.infer<typeof EntryArgs> | string> = [...(args.rotate_items ?? [])];
        if (args.rotate_file) {
          const f = await readItemsFile(args.rotate_file, ctx);
          try {
            inputs.push(...(parseItemsFile(f.text, f.name) as Array<z.infer<typeof EntryArgs>>));
          } catch (e) {
            if (e instanceof CanvasError) throw new ToolError(e.code, e.message);
            throw e;
          }
        }
        const items: CanvasEntryBody[] = args.append && prev ? [...prev.items] : [];
        for (const a of inputs) items.push(await entryOf(a, pic, `item ${items.length + 1}`, cuts));
        if (!items.length)
          throw new ToolError(
            "empty",
            args.append && !prev
              ? "There's no rotation on this canvas to add to. Give rotate with rotate_items or rotate_file."
              : "A rotation needs items: rotate_items or rotate_file.",
          );
        if (items.length > CANVAS_LIMITS.rotationItems)
          throw new ToolError(
            "too_many_items",
            `A rotation holds at most ${CANVAS_LIMITS.rotationItems} items (this would be ${items.length}).`,
          );
        const r = args.rotate;
        if (!r && !prev)
          throw new ToolError(
            "no_rhythm",
            'Say how often it changes: rotate {every: "day", at: "06:00"}.',
          );
        const at = r?.at ?? prev?.at ?? "06:00";
        if (parseClock(at) === null)
          throw new ToolError("bad_time", 'rotate.at is a local time like "06:00".');
        const rhythm: CanvasRhythm = r
          ? {
              every: r.every === "hours" ? (r.hours ?? 1) : r.every,
              at,
              weekday:
                r.every === "week"
                  ? r.weekday
                    ? WEEKDAYS.indexOf(r.weekday)
                    : (prev?.weekday ?? 1)
                  : undefined,
              order: r.order ?? prev?.order ?? "in_order",
              at_end: r.at_end ?? prev?.at_end ?? "loop",
            }
          : (prev as CanvasRhythm);
        // Adding items keeps the rotation where it is; a new rhythm or list starts it from now.
        const keepPlace = !!(args.append && prev && !r);
        content = {
          look,
          rotation: {
            ...rhythm,
            items,
            started_at: keepPlace ? (prev as { started_at: string }).started_at : now.toISOString(),
            tz: keepPlace ? (prev as { tz: string }).tz : timezone,
          },
        };
      } else {
        const first = await entryOf(args, pic, undefined, cuts);
        const later = [];
        for (const [i, s] of (args.schedule ?? []).entries()) {
          const t = Date.parse(s.at);
          if (Number.isNaN(t))
            throw new ToolError("bad_time", `schedule ${i + 1}: at must be ISO 8601 with offset.`);
          later.push({
            ...(await entryOf(s, pic, `schedule ${i + 1}`, cuts)),
            at: new Date(t).toISOString(),
          });
        }
        const entries = [{ ...first, at: null }, ...later];
        try {
          checkSchedule(entries, now);
        } catch (e) {
          if (e instanceof CanvasError) throw new ToolError(e.code, e.message);
          throw e;
        }
        content = { look, entries };
      }

      let until: Date | null = null;
      if (args.until) {
        const t = Date.parse(args.until);
        if (Number.isNaN(t) || t <= now.getTime())
          throw new ToolError("bad_time", "until must be a future time, ISO 8601 with offset.");
        until = new Date(t);
      } else {
        // A countdown clears a day after its last target.
        const targets = (content.entries ?? [])
          .filter((e) => e.template === "countdown" && e.count !== "up" && e.target)
          .map((e) => Date.parse(e.target as string));
        if (targets.length && targets.length === (content.entries ?? []).length)
          until = new Date(Math.max(...targets) + 86_400_000);
      }

      const allowed = await widgetsAllowed(db, userId, ctx.botId);
      let row: CanvasRow;
      try {
        row = await saveCanvas(db, {
          orgId: ctx.orgId,
          userId,
          botId: ctx.botId,
          runId: ctx.runId,
          name,
          content,
          allowed,
          private: args.private === true,
          until,
          now,
        });
      } catch (e) {
        if (e instanceof CanvasLimitError) throw new ToolError(e.code, e.message);
        throw e;
      }
      for (const p of pictures.values())
        await storePicture(db, deps.objects, { orgId: ctx.orgId, canvasId: row.id, picture: p });
      await prunePictures(db, row.id, picturesOf(content));
      if (row.status === "shown") deps.changed?.(userId);

      const where = await placements(db, userId, ctx.orgId);
      const run = await runTrigger(ctx.runId, userId);
      const state = !allowed ? "waiting" : where.length ? "shown" : "not_placed";
      // The chat shows the canvas as the widget will (§8.5); a routine's write shows a card only
      // when the person still has to allow this bot.
      if (run.chat || !allowed)
        await ctx.emit("canvas.preview", {
          canvas_id: row.id,
          bot_id: ctx.botId,
          state,
          canvas: canvasOut(row, { now: now.getTime() }),
        });

      const parts: string[] = [];
      const who = run.name ?? "The person";
      if (!allowed)
        parts.push(
          `${who} has a preview in the chat with a Show on my widgets button. It will show once they tap it. Don't call widget.set again for this; end your turn.`,
        );
      else if (row.status === "paused")
        parts.push(
          `Saved, but ${who} paused this canvas: it shows again when they resume it in Settings → Widgets.`,
        );
      else {
        parts.push(answerWhere(where, run.name));
        parts.push(lockForm(row));
      }
      if (content.rotation) {
        const spot = rotationAt(content.rotation, row.id, now.getTime());
        parts.push(
          `A rotation of ${content.rotation.items.length} items, ${rhythmWords(content.rotation)}. Item ${spot.item + 1} shows now; it changes by itself with no more runs.`,
        );
      } else if ((content.entries ?? []).length > 1)
        parts.push(
          `${content.entries?.length} entries planned; the widget switches at their times by itself.`,
        );
      if (cuts.length) parts.push(`Cut to fit: ${cuts.slice(0, 8).join("; ")}.`);
      if (row.hide_when_locked) parts.push("It is hidden on a locked phone.");
      return {
        content: parts.filter(Boolean).join("\n"),
        preview: `${allowed ? "set" : "proposed"} the ${name} canvas`,
      };
    },
  });

  registry.register({
    name: "widget.clear",
    description:
      "Clear what you show on the person's Canvas widget: one canvas by name, or all of yours.",
    risk: "low",
    selfOnly: true,
    schema: z.object({ name: z.string().max(40).optional() }),
    async execute(args, ctx) {
      const { userId } = await person(ctx);
      const gone = await clearCanvases(db, { userId, botId: ctx.botId, name: args.name?.trim() });
      if (gone.length) deps.changed?.(userId);
      return {
        content: gone.length
          ? `Cleared ${gone.length === 1 ? "it" : `${gone.length} canvases`}.`
          : args.name
            ? `You have no canvas named ${args.name} for this person.`
            : "You show nothing on this person's widgets.",
        preview: "cleared a canvas",
      };
    },
  });

  registry.register({
    name: "widget.list",
    description:
      "What you show on the person's Canvas widget: each canvas, what shows now and next, where a rotation stands, where it's placed, and the changes left today.",
    risk: "low",
    readOnly: true,
    schema: z.object({}),
    async execute(_args, ctx) {
      const { userId } = await person(ctx);
      const now = Date.now();
      const rows = await listCanvases(db, { userId, orgId: ctx.orgId, botId: ctx.botId });
      const allowed = await widgetsAllowed(db, userId, ctx.botId);
      const where = await placements(db, userId, ctx.orgId, now);
      const left = await writesLeft(db, userId);
      const lines = [
        allowed
          ? "You may show things on this person's widgets."
          : "This person hasn't let you show things on their widgets yet: widget.set shows them a preview to allow.",
        where.length
          ? `A Canvas widget is placed on ${placementWords(where)}.`
          : "No Canvas widget is placed yet.",
        `${left} changes left today across their canvases.`,
      ];
      if (!rows.length) lines.push("You have no canvases for them.");
      for (const r of rows) {
        const out = canvasOut(r, { now });
        const e = out.entries[0];
        const next = out.entries[1];
        lines.push(
          `- ${r.name} (${r.status}${r.hide_when_locked ? ", hidden when locked" : ""}): ${e ? `${e.template} "${e.short}"` : "nothing now"}${next ? `; next at ${next.at}: "${next.short}"` : ""}${
            r.content.rotation && out.rotation
              ? `; rotation of ${out.rotation.count} items, ${out.rotation.every}; ${out.rotation.left} left before it ${r.content.rotation.at_end === "loop" ? "starts again" : "stops"}`
              : ""
          }${r.until ? `; clears ${r.until.toISOString()}` : ""}`,
        );
      }
      return { content: lines.join("\n"), preview: `${rows.length} canvases` };
    },
  });
}
