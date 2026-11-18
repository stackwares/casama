/**
 * Reactions in chat apps (D-331 Phase 3). Slack names its emoji (`thumbsup`, `heart`); Telegram
 * lets bots react only with a fixed set. Emoji outside these maps are left out.
 */
import { normalizeReaction } from "@casama/domain";

/** Slack's names for the emoji people use most, both ways. */
const SLACK: Array<[string, string[]]> = [
  ["👍", ["+1", "thumbsup"]],
  ["👎", ["-1", "thumbsdown"]],
  ["❤️", ["heart"]],
  ["😂", ["joy"]],
  ["😮", ["open_mouth"]],
  ["😢", ["cry"]],
  ["😡", ["rage"]],
  ["😠", ["angry"]],
  ["🔥", ["fire"]],
  ["🎉", ["tada"]],
  ["🙏", ["pray"]],
  ["👏", ["clap"]],
  ["💯", ["100"]],
  ["😍", ["heart_eyes"]],
  ["🥰", ["smiling_face_with_3_hearts"]],
  ["✅", ["white_check_mark"]],
  ["✔️", ["heavy_check_mark"]],
  ["❌", ["x"]],
  ["⭐", ["star"]],
  ["🌟", ["star2"]],
  ["🙌", ["raised_hands"]],
  ["💪", ["muscle"]],
  ["😊", ["blush"]],
  ["😄", ["smile"]],
  ["😀", ["grinning"]],
  ["😆", ["laughing", "satisfied"]],
  ["😅", ["sweat_smile"]],
  ["🤣", ["rolling_on_the_floor_laughing"]],
  ["🙂", ["slightly_smiling_face"]],
  ["😉", ["wink"]],
  ["😎", ["sunglasses"]],
  ["🤩", ["star-struck"]],
  ["💖", ["sparkling_heart"]],
  ["💕", ["two_hearts"]],
  ["💔", ["broken_heart"]],
  ["😞", ["disappointed"]],
  ["😕", ["confused"]],
  ["🤦", ["face_palm"]],
  ["👀", ["eyes"]],
  ["🙄", ["face_with_rolling_eyes", "rolling_eyes"]],
  ["😤", ["triumph"]],
  ["💩", ["hankey", "poop", "shit"]],
  ["😭", ["sob"]],
  ["🤔", ["thinking_face"]],
  ["👌", ["ok_hand"]],
  ["👋", ["wave"]],
  ["🚀", ["rocket"]],
  ["😲", ["astonished"]],
  ["😱", ["scream"]],
  ["😒", ["unamused"]],
  ["😔", ["pensive"]],
  ["⛔", ["no_entry"]],
  ["⚠️", ["warning"]],
  ["💡", ["bulb"]],
  ["📝", ["memo", "pencil"]],
  ["🤝", ["handshake"]],
  ["🫡", ["saluting_face"]],
  ["🫠", ["melting_face"]],
  ["🤗", ["hugging_face", "hugs"]],
  ["⚡", ["zap"]],
  ["🏆", ["trophy"]],
  ["✨", ["sparkles"]],
  ["🤯", ["exploding_head"]],
  ["🥲", ["smiling_face_with_tear"]],
  ["😁", ["grin"]],
  ["🤷", ["shrug"]],
  ["😴", ["sleeping"]],
  ["🤬", ["face_with_symbols_on_mouth", "cursing_face"]],
];
const FROM_SLACK = new Map(SLACK.flatMap(([e, names]) => names.map((n) => [n, e] as const)));
const TO_SLACK = new Map(
  SLACK.map(([e, names]) => [e, names[names.length > 1 && names[0] === "+1" ? 1 : 0] as string]),
);
const SKIN = ["", "", "\u{1F3FB}", "\u{1F3FC}", "\u{1F3FD}", "\u{1F3FE}", "\u{1F3FF}"];

/** "thumbsup::skin-tone-3" → "👍🏼"; unknown names → null. */
export function emojiFromSlack(name: string): string | null {
  const [base, tone] = name.split("::");
  const e = FROM_SLACK.get(base ?? "");
  if (!e) return null;
  const n = /^skin-tone-([2-6])$/.exec(tone ?? "")?.[1];
  return normalizeReaction(n ? `${e.replace(/️$/, "")}${SKIN[Number(n)]}` : e);
}

/** "👍🏼" → "thumbsup::skin-tone-3"; emoji Slack has no name for here → null. */
export function slackNameOf(emoji: string): string | null {
  const tone = /[\u{1F3FB}-\u{1F3FF}]/u.exec(emoji)?.[0];
  const base = normalizeReaction(emoji.replace(/[\u{1F3FB}-\u{1F3FF}]/gu, "")) ?? emoji;
  const name = TO_SLACK.get(base);
  if (!name) return null;
  return tone ? `${name}::skin-tone-${SKIN.indexOf(tone)}` : name;
}

/** What Telegram lets bots react with (without the emoji variation selector, as Telegram has them). */
const TELEGRAM = new Set(
  "👍 👎 ❤ 🔥 🥰 👏 😁 🤔 🤯 😱 🤬 😢 🎉 🤩 🤮 💩 🙏 👌 🕊 🤡 🥱 🥴 😍 🐳 ❤‍🔥 🌚 🌭 💯 🤣 ⚡ 🍌 🏆 💔 🤨 😐 🍓 🍾 💋 🖕 😈 😴 😭 🤓 👻 👨‍💻 👀 🎃 🙈 😇 😨 🤝 ✍ 🤗 🫡 🎅 🎄 ☃ 💅 🤪 🗿 🆒 💘 🙉 🦄 😘 💊 🙊 😎 👾 🤷‍♂ 🤷 🤷‍♀ 😡".split(
    " ",
  ),
);
/** The nearest one Telegram allows, for quick reactions it doesn't. */
const TELEGRAM_NEAREST: Record<string, string> = {
  "😂": "🤣",
  "😮": "😱",
  "😄": "😁",
  "😊": "🥰",
  "😀": "😁",
  "😆": "🤣",
  "😠": "😡",
};

/** The emoji to send Telegram for [emoji], or null when it has nothing close. */
export function telegramReactionOf(emoji: string): string | null {
  const plain = emoji.replace(/️/g, "").replace(/[\u{1F3FB}-\u{1F3FF}]/gu, "");
  if (TELEGRAM.has(plain)) return plain;
  const near = TELEGRAM_NEAREST[plain];
  return near && TELEGRAM.has(near) ? near : null;
}
