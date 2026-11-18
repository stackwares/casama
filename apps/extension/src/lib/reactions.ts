/** Emoji reactions in the side panel (D-331): the same six quick ones as the app, and the change
 * shown before the server answers. */

export const QUICK_REACTIONS = ["👍", "❤️", "😂", "😮", "😢", "👎"] as const;

export interface Reaction {
  emoji: string;
  count: number;
  mine: boolean;
}

/** Your emoji among [groups], if any. */
export function mineOf(groups: readonly Reaction[]): string | null {
  return groups.find((g) => g.mine)?.emoji ?? null;
}

/** [groups] with your reaction set to [emoji] (null takes it back): one per person per message. */
export function withMine(groups: readonly Reaction[], emoji: string | null): Reaction[] {
  const out: Reaction[] = [];
  for (const g of groups) {
    if (!g.mine) out.push(g);
    else if (g.count > 1) out.push({ emoji: g.emoji, count: g.count - 1, mine: false });
  }
  if (emoji === null) return out;
  const at = out.findIndex((g) => g.emoji === emoji);
  if (at >= 0) out[at] = { emoji, count: out[at]!.count + 1, mine: true };
  else out.push({ emoji, count: 1, mine: true });
  return out;
}

/** What tapping [emoji] does: takes yours back when it's already yours, else sets it. */
export function toggled(groups: readonly Reaction[], emoji: string): string | null {
  return mineOf(groups) === emoji ? null : emoji;
}

/** A chip's spoken label: "👍, 2 reactions, including yours". */
export function chipLabel(g: Reaction): string {
  return `${g.emoji}, ${g.count === 1 ? "1 reaction" : `${g.count} reactions`}${g.mine ? ", including yours" : ""}`;
}
