/**
 * Mentions in group chats (D-118): `@Name` wakes that bot, `@everyone` wakes the lead with the team.
 * Names may contain spaces; the longest matching name wins ("@Ada Lovelace" before "@Ada").
 */
export interface Mentionable {
  id: string;
  name: string;
}

export function parseMentions(text: string, bots: Mentionable[]) {
  const lower = text.toLowerCase();
  const everyone = /(^|[^\w@])@(everyone|all|team)\b/i.test(text);
  const sorted = [...bots].sort((a, b) => b.name.length - a.name.length);
  const ids: string[] = [];
  const taken: Array<[number, number]> = [];
  for (const b of sorted) {
    const needle = `@${b.name.toLowerCase()}`;
    let from = 0;
    for (;;) {
      const i = lower.indexOf(needle, from);
      if (i < 0) break;
      from = i + needle.length;
      const before = i === 0 ? " " : (lower[i - 1] as string);
      const after = lower[i + needle.length] ?? " ";
      if (/[\w@]/.test(before) || /\w/.test(after)) continue;
      if (taken.some(([s, e]) => i < e && i + needle.length > s)) continue;
      taken.push([i, i + needle.length]);
      if (!ids.includes(b.id)) ids.push(b.id);
    }
  }
  // In the order they appear in the text.
  const firstAt = (id: string) => {
    const name = `@${bots.find((b) => b.id === id)?.name.toLowerCase()}`;
    return lower.indexOf(name);
  };
  return { everyone, botIds: ids.sort((a, b) => firstAt(a) - firstAt(b)) };
}
