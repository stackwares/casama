/**
 * Message reactions (D-331): which strings count as one emoji, the quick six, and what a
 * reaction says about a bot's reply.
 */

/** The six offered first, in order (decision 2: 👎 instead of Facebook's 😡). */
export const QUICK_REACTIONS = ["👍", "❤️", "😂", "😮", "😢", "👎"] as const;

/** Liked: the reply worked. */
const POSITIVE = new Set([
  "👍",
  "❤️",
  "😂",
  "🔥",
  "🎉",
  "🙏",
  "👏",
  "💯",
  "😍",
  "🥰",
  "✅",
  "⭐",
  "🌟",
  "🙌",
  "💪",
  "😊",
  "😄",
  "🤩",
  "💖",
  "💕",
  "♥️",
]);
/** Something went wrong. */
const NEGATIVE = new Set([
  "👎",
  "😡",
  "😠",
  "😢",
  "😞",
  "😕",
  "🤦",
  "❌",
  "🙄",
  "😤",
  "💩",
  "😭",
  "🤬",
  "😒",
  "⛔",
]);

/** The longest emoji we keep, in code points (ZWJ families and tag flags fit). */
export const MAX_REACTION_CODE_POINTS = 16;

const SKIN_TONE = /[\u{1F3FB}-\u{1F3FF}]/gu;
const ALLOWED =
  /^(?:[\p{Extended_Pictographic}\p{Emoji_Component}\p{Regional_Indicator}\u{E0020}-\u{E007F}]|\u200D|\uFE0F|\u20E3)+$/u;
const SHOWS_AS_EMOJI = /\p{Extended_Pictographic}|\p{Regional_Indicator}{2}|\u20E3/u;

const segmenter =
  typeof Intl !== "undefined" && "Segmenter" in Intl
    ? new Intl.Segmenter(undefined, { granularity: "grapheme" })
    : null;

/**
 * The emoji as stored, or null when [raw] isn't exactly one emoji. A lone pictograph that
 * defaults to text (❤, ☺, ✌) gets the emoji variation selector, so "❤" and "❤️" count as one.
 */
export function normalizeReaction(raw: string): string | null {
  const s = raw.trim();
  if (!s) return null;
  const points = [...s];
  if (points.length > MAX_REACTION_CODE_POINTS) return null;
  if (!ALLOWED.test(s) || !SHOWS_AS_EMOJI.test(s)) return null;
  if (segmenter && [...segmenter.segment(s)].length !== 1) return null;
  if (
    points.length === 1 &&
    !/\p{Emoji_Presentation}/u.test(s) &&
    /\p{Extended_Pictographic}/u.test(s)
  )
    return `${s}️`;
  return s;
}

/** True when [raw] is exactly one emoji. */
export function isReactionEmoji(raw: string): boolean {
  return normalizeReaction(raw) !== null;
}

/** What a reaction on a bot's reply says: liked, something went wrong, or neither. */
export function reactionSentiment(emoji: string): "positive" | "negative" | null {
  const base = (normalizeReaction(emoji) ?? emoji).replace(SKIN_TONE, "");
  if (POSITIVE.has(base)) return "positive";
  if (NEGATIVE.has(base)) return "negative";
  return null;
}

/** One person's or bot's reaction, as the history and summaries read it. */
export interface ReactionRow {
  emoji: string;
  user_id: string | null;
  bot_id: string | null;
}

/** Reactions grouped by emoji, most first (ties: the first one added first). */
export function summarizeReactions(
  rows: ReactionRow[],
  me?: string,
): Array<{ emoji: string; count: number; mine: boolean; users: string[]; bots: string[] }> {
  const by = new Map<
    string,
    { emoji: string; count: number; mine: boolean; users: string[]; bots: string[]; first: number }
  >();
  rows.forEach((r, i) => {
    const g = by.get(r.emoji) ?? {
      emoji: r.emoji,
      count: 0,
      mine: false,
      users: [],
      bots: [],
      first: i,
    };
    g.count++;
    if (r.user_id) g.users.push(r.user_id);
    if (r.bot_id) g.bots.push(r.bot_id);
    if (me && r.user_id === me) g.mine = true;
    by.set(r.emoji, g);
  });
  return [...by.values()]
    .sort((a, b) => b.count - a.count || a.first - b.first)
    .map(({ first: _first, ...g }) => g);
}
