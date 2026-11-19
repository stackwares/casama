/**
 * `@App` mentions in chat (D-434): `@Gmail`, `@Google Calendar`, `@Linear`.
 *
 * Follows the same boundary and longest-name-first rules as bot mentions (`mentions.ts`):
 * - `alice@gmail.com` does not match (char before `@` is a word char).
 * - Multi-word names (`@Google Calendar`) win over shorter prefixes (`@Google`).
 * - In group chats, bot names win on name collision when matching plain text; picking an app from
 *   the `@` menu passes `integration_id` explicitly so it still resolves.
 * - If two connected apps share the exact same name or alias, plain-text matching skips the
 *   ambiguous token instead of guessing the wrong account.
 */

export const MAX_APP_MENTIONS = 3;

export interface MentionableApp {
  integrationId: string;
  /** Hub toolkit/app slug (Composio or Pipedream); omitted for direct integrations. */
  toolkit?: string;
  /** Display name shown on the pill and in the model hint (e.g. "Gmail", "Google Calendar"). */
  label: string;
  /** Additional exact match tokens (integration slug, catalog id, hub toolkit slug). */
  aliases?: string[];
  /** Catalog or gallery app id, used for brand logos. */
  appId?: string;
  /** Integration kind (`mcp`, `composio`, `pipedream`, `openapi`, `local_mcp`, `computer_mcp`, `a2a`). */
  kind?: string;
}

export interface AppMentionRefInput {
  integration_id: string;
  toolkit?: string;
}

export interface ParsedAppMention {
  integrationId: string;
  toolkit?: string;
  label: string;
  appId?: string;
  kind?: string;
  /** Character index of `@` in the source text. */
  index: number;
  /** Character length of the matched `@...` token. */
  length: number;
}

export interface ResolvedAppMention {
  integrationId: string;
  toolkit?: string;
  label: string;
  appId?: string;
  kind?: string;
  source: "picker" | "typed";
}

export const appMentionKey = (integrationId: string, toolkit?: string) =>
  `${integrationId}:${(toolkit ?? "").toLowerCase()}`;

function markSpans(lower: string, needle: string, taken: Array<[number, number]>) {
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
  }
}

/**
 * Finds `@App` mentions in plain text among `apps`, in order of appearance, capped at `limit`.
 * `reservedNames` (e.g. group chat bot names + `everyone`/`all`/`team`) claim their spans first.
 */
export function parseAppMentions(
  text: string,
  apps: MentionableApp[],
  opts: { reservedNames?: string[]; limit?: number } = {},
): ParsedAppMention[] {
  if (!text || !apps.length) return [];
  const lower = text.toLowerCase();
  const limit = opts.limit ?? MAX_APP_MENTIONS;
  const taken: Array<[number, number]> = [];

  // Bot names (and @everyone/@all/@team in group chats) win text collisions.
  const reserved = [...(opts.reservedNames ?? [])]
    .map((n) => n.trim().toLowerCase())
    .filter(Boolean)
    .sort((a, b) => b.length - a.length);
  for (const name of reserved) markSpans(lower, `@${name}`, taken);

  // Build normalized candidate -> distinct app keys map so ambiguous names don't guess.
  const owners = new Map<string, Set<string>>();
  const byKey = new Map<string, MentionableApp>();
  const appNeedles = new Map<string, Set<string>>();

  for (const app of apps) {
    const key = appMentionKey(app.integrationId, app.toolkit);
    if (!byKey.has(key)) byKey.set(key, app);
    const needles = appNeedles.get(key) ?? new Set<string>();
    const raw = [app.label, ...(app.aliases ?? [])];
    for (const candidate of raw) {
      const norm = candidate.trim().toLowerCase();
      if (!norm) continue;
      needles.add(norm);
      const set = owners.get(norm) ?? new Set<string>();
      set.add(key);
      owners.set(norm, set);
    }
    appNeedles.set(key, needles);
  }

  // Only unambiguous candidates participate in plain-text matching; longest wins first.
  const candidates: Array<{ needle: string; key: string; app: MentionableApp }> = [];
  for (const [key, needles] of appNeedles) {
    const app = byKey.get(key) as MentionableApp;
    for (const norm of needles) {
      if ((owners.get(norm)?.size ?? 0) !== 1) continue;
      candidates.push({ needle: `@${norm}`, key, app });
    }
  }
  candidates.sort((a, b) => b.needle.length - a.needle.length);

  const found = new Map<string, ParsedAppMention>();
  for (const c of candidates) {
    let from = 0;
    for (;;) {
      const i = lower.indexOf(c.needle, from);
      if (i < 0) break;
      from = i + c.needle.length;
      const before = i === 0 ? " " : (lower[i - 1] as string);
      const after = lower[i + c.needle.length] ?? " ";
      if (/[\w@]/.test(before) || /\w/.test(after)) continue;
      if (taken.some(([s, e]) => i < e && i + c.needle.length > s)) continue;
      taken.push([i, i + c.needle.length]);
      const prev = found.get(c.key);
      if (!prev || i < prev.index) {
        found.set(c.key, {
          integrationId: c.app.integrationId,
          ...(c.app.toolkit ? { toolkit: c.app.toolkit } : {}),
          label: c.app.label,
          ...(c.app.appId ? { appId: c.app.appId } : {}),
          ...(c.app.kind ? { kind: c.app.kind } : {}),
          index: i,
          length: c.needle.length,
        });
      }
    }
  }

  return [...found.values()].sort((a, b) => a.index - b.index).slice(0, limit);
}

/**
 * Resolves explicit picker references (`picked`) plus plain-text `@App` mentions against a bot's
 * usable `apps`, deduplicated and capped at `limit` (default 3).
 *
 * Explicit picker refs take precedence over text matches and are checked by exact
 * `(integration_id, toolkit)`. Any picked ref not present in `apps` is returned in
 * `unresolvedPicked` so callers (e.g. group chats) can post a notice when no woken bot has it.
 */
export function resolveAppMentions(
  text: string,
  apps: MentionableApp[],
  picked?: AppMentionRefInput[],
  opts: { reservedNames?: string[]; limit?: number } = {},
): { resolved: ResolvedAppMention[]; unresolvedPicked: AppMentionRefInput[] } {
  const limit = opts.limit ?? MAX_APP_MENTIONS;
  const byKey = new Map<string, MentionableApp>();
  for (const app of apps) {
    const key = appMentionKey(app.integrationId, app.toolkit);
    if (!byKey.has(key)) byKey.set(key, app);
  }

  const resolved: ResolvedAppMention[] = [];
  const unresolvedPicked: AppMentionRefInput[] = [];
  const seen = new Set<string>();

  for (const ref of picked ?? []) {
    if (resolved.length >= limit) break;
    const key = appMentionKey(ref.integration_id, ref.toolkit);
    if (seen.has(key)) continue;
    const match = byKey.get(key);
    if (!match) {
      unresolvedPicked.push(ref);
      continue;
    }
    seen.add(key);
    resolved.push({
      integrationId: match.integrationId,
      ...(match.toolkit ? { toolkit: match.toolkit } : {}),
      label: match.label,
      ...(match.appId ? { appId: match.appId } : {}),
      ...(match.kind ? { kind: match.kind } : {}),
      source: "picker",
    });
  }

  if (resolved.length < limit) {
    const fromText = parseAppMentions(text, apps, {
      reservedNames: opts.reservedNames,
      limit: Number.MAX_SAFE_INTEGER,
    });
    for (const m of fromText) {
      if (resolved.length >= limit) break;
      const key = appMentionKey(m.integrationId, m.toolkit);
      if (seen.has(key)) continue;
      seen.add(key);
      resolved.push({
        integrationId: m.integrationId,
        ...(m.toolkit ? { toolkit: m.toolkit } : {}),
        label: m.label,
        ...(m.appId ? { appId: m.appId } : {}),
        ...(m.kind ? { kind: m.kind } : {}),
        source: "typed",
      });
    }
  }

  return { resolved, unresolvedPicked };
}
