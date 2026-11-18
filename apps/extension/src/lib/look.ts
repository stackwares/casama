/**
 * Pieces drawn the app's way: a bot's avatar (client/lib/ui/bot_avatar.dart) and the empty state
 * with a Casama cloud bot (client/lib/core/widgets.dart EmptyState). The bots' still poses are in
 * public/mascots, copied from client/assets/mascots. The app's Plain theme has fewer effects on, so it
 * shows these stills too rather than the animated loops.
 */
import { h } from "./dom.ts";

export const MASCOTS = [
  "winky",
  "sleepy",
  "starry",
  "lovey",
  "cool",
  "thinker",
  "giggly",
  "shy",
  "focused",
  "wow",
] as const;
export type Mascot = (typeof MASCOTS)[number];

export const mascotSrc = (m: Mascot) => `/mascots/${m}.png`;

/** The mascot a bot's `avatar_url` points at (`mascot:<name>`), or null. */
export function mascotFromAvatar(avatarUrl: string | null | undefined): Mascot | null {
  const key = /^mascot:(\w+)$/.exec(avatarUrl ?? "")?.[1];
  return (MASCOTS as readonly string[]).includes(key ?? "") ? (key as Mascot) : null;
}

/** The gradients bots draw from, picked by name so a bot keeps its colour everywhere. */
const PALETTES: [string, string][] = [
  ["#14B8A6", "#0F766E"],
  ["#6366F1", "#4338CA"],
  ["#F59E0B", "#D97706"],
  ["#EC4899", "#BE185D"],
  ["#3B82F6", "#1D4ED8"],
  ["#8B5CF6", "#6D28D9"],
  ["#10B981", "#047857"],
  ["#F97316", "#C2410C"],
];

export function botPalette(name: string): [string, string] {
  let hash = 0;
  for (const c of name.toLowerCase()) hash = (hash * 31 + c.charCodeAt(0)) & 0x7fffffff;
  return PALETTES[hash % PALETTES.length]!;
}

export function botInitials(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (!parts.length) return "?";
  const first = (s: string) => [...s][0]!.toUpperCase();
  return parts.length === 1 ? first(parts[0]!) : first(parts[0]!) + first(parts[1]!);
}

/** A bot's mark: its mascot (no tile), its own https picture, or its initials on its gradient. */
export function botAvatar(name: string, avatarUrl: string | null | undefined, size = 36) {
  const style = `width:${size}px;height:${size}px`;
  const mascot = mascotFromAvatar(avatarUrl);
  if (mascot)
    return h("img", { className: "bot-avatar mascot", src: mascotSrc(mascot), alt: "", style });
  if (avatarUrl && /^https:\/\//.test(avatarUrl))
    return h("img", { className: "bot-avatar photo", src: avatarUrl, alt: "", style });
  const [a, b] = botPalette(name || "?");
  const initials = botInitials(name || "?");
  return h(
    "span",
    {
      className: "bot-avatar initials",
      "aria-hidden": "true",
      style: `${style};border-radius:${Math.round(size * 0.32)}px;background:linear-gradient(135deg,${a},${b});font-size:${Math.round(size * (initials.length > 1 ? 0.36 : 0.44))}px`,
    },
    initials,
  );
}

type Badge = "check" | "bot" | "sparkles";

/**
 * "Nothing here": a cloud bot over a soft halo with the state's icon in a badge, then the line.
 * [compact] is for a quiet section inside a longer view: a smaller bot and no badge.
 */
export function emptyState(opts: {
  message: string;
  mascot?: Mascot;
  art?: HTMLElement;
  badge?: Badge;
  compact?: boolean;
  testid?: string;
}) {
  const art =
    opts.art ?? h("img", { className: "mascot", src: mascotSrc(opts.mascot ?? "sleepy"), alt: "" });
  return h(
    "div",
    {
      className: `empty empty-state${opts.compact ? " compact" : ""}`,
      "data-testid": opts.testid,
    },
    h(
      "div",
      { className: "empty-art", "aria-hidden": "true" },
      art,
      opts.badge && !opts.compact
        ? h("span", { className: "empty-badge", "data-badge": opts.badge })
        : "",
    ),
    h("p", {}, opts.message),
  );
}
