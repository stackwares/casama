/**
 * A bot's mark as `bots.avatar_url` holds it (docs/BOT-PICTURES-PLAN.md §5.1):
 *
 * - `null` or empty: its initials on a gradient picked from its name;
 * - `mascot:<name>`: one of the cloud mascots the apps ship;
 * - `image:<uuid>:<rrggbb><rrggbb>`: a picture of its own (`public.bot_images`), with the two colours
 *   the server took from it, so surfaces drawn in the bot's colour match the picture without
 *   loading it.
 *
 * The same rules live in the app (client/lib/ui/bot_avatar.dart), the widgets and the watch
 * (client/ios/Shared/WatchLogic.swift, BotArt.kt) and the extension (apps/extension/src/lib/look.ts).
 * They all test against test/fixtures/bot-avatar-vectors.json.
 */
import { GALLERY_MASCOTS } from "./gallery-content.ts";

export type BotMascot = (typeof GALLERY_MASCOTS)[number];

export type BotAvatar =
  | { kind: "initials" }
  | { kind: "mascot"; mascot: BotMascot }
  | { kind: "image"; id: string; colors: [string, string] };

const IMAGE =
  /^image:([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}):([0-9a-f]{6})([0-9a-f]{6})$/;
const MASCOT = /^mascot:([a-z]+)$/;

/** Longest value: `image:` + uuid + `:` + 12 hex digits. */
export const BOT_AVATAR_MAX_LENGTH = 55;

/** What a stored value means. Anything unknown (an old web link, a typo) reads as initials. */
export function parseBotAvatar(value: string | null | undefined): BotAvatar {
  if (!value) return { kind: "initials" };
  const img = IMAGE.exec(value);
  if (img) return { kind: "image", id: img[1]!, colors: [`#${img[2]}`, `#${img[3]}`] };
  const m = MASCOT.exec(value)?.[1];
  if (m && (GALLERY_MASCOTS as readonly string[]).includes(m))
    return { kind: "mascot", mascot: m as BotMascot };
  return { kind: "initials" };
}

/** The stored value for a picture: its id and its two colours (`#rrggbb` or `rrggbb`). */
export function botImageAvatar(id: string, colors: readonly [string, string]): string {
  const hex = (c: string) => c.replace(/^#/, "").toLowerCase();
  const v = `image:${id.toLowerCase()}:${hex(colors[0])}${hex(colors[1])}`;
  if (!IMAGE.test(v)) throw new Error(`not a bot picture value: ${v}`);
  return v;
}

/** Whether [value] may be stored at all (the database checks the same shape). */
export function isValidBotAvatar(value: string | null | undefined): boolean {
  if (value == null) return true;
  return parseBotAvatar(value).kind !== "initials";
}

/** The mascot to fall back to where pictures don't travel (templates, packs, the gallery). */
export function portableBotAvatar(value: string | null | undefined, prior?: string | null) {
  const a = parseBotAvatar(value);
  if (a.kind === "mascot") return `mascot:${a.mascot}`;
  const p = parseBotAvatar(prior);
  return p.kind === "mascot" ? `mascot:${p.mascot}` : null;
}

/** The initials gradients, as the app picks them from a bot's name (bot_avatar.dart, `_palettes`). */
const NAME_PALETTES: readonly [string, string][] = [
  ["#14b8a6", "#0f766e"],
  ["#6366f1", "#4338ca"],
  ["#f59e0b", "#d97706"],
  ["#ec4899", "#be185d"],
  ["#3b82f6", "#1d4ed8"],
  ["#8b5cf6", "#6d28d9"],
  ["#10b981", "#047857"],
  ["#f97316", "#c2410c"],
];

/** botPalette: (h * 31 + code unit) & 0x7fffffff over the lower-cased name's UTF-16 units. */
export function botNamePalette(name: string): [string, string] {
  let h = 0;
  const s = name.toLowerCase();
  for (let i = 0; i < s.length; i++) h = (Math.imul(h, 31) + s.charCodeAt(i)) & 0x7fffffff;
  return [...NAME_PALETTES[h % NAME_PALETTES.length]!];
}
