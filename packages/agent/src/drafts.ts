/**
 * Cards the person confirms (D-335, D-337). A bot shows an email, chat message or post as a
 * MessageDraft, or an event as an Event card; the person checks it, maybe edits it, and taps Send
 * or Add to calendar. That tap is their yes for exactly that, so the bot's matching tool call doesn't
 * stop for a second approval. A call that adds a recipient or guest, or changes the text or time,
 * still asks as before.
 */

export type DraftFields = {
  surfaceId: string;
  to: string[];
  cc: string[];
  bcc: string[];
  from: string | null;
  subject: string | null;
  body: string;
};

type Part = { type?: unknown; [k: string]: unknown };

const parts = (content: unknown): Part[] =>
  Array.isArray(content) ? (content.filter((p) => p && typeof p === "object") as Part[]) : [];

const list = (v: unknown): string[] =>
  (Array.isArray(v) ? v : typeof v === "string" ? v.split(/[,;\n]/) : [])
    .filter((x): x is string => typeof x === "string")
    .map((x) => x.trim())
    .filter(Boolean);

const text = (v: unknown) => (typeof v === "string" && v.trim() ? v.trim() : null);

export type EventFields = {
  surfaceId: string;
  title: string;
  /** "2026-11-20" and "14:00" (null for an all-day event), as the card showed them. */
  date: string;
  time: string | null;
  attendees: string[];
  location: string | null;
  description: string | null;
};

/** What a confirmed card approves: a message to send or an event to add. */
export type ConfirmedCard = ({ kind: "draft" } & DraftFields) | ({ kind: "event" } & EventFields);

/** Whether a shown UI's messages hold a component of [name]. */
function showsComponent(messages: unknown, name: string) {
  if (!Array.isArray(messages)) return false;
  return messages.some((m) => {
    const comps = (m as { updateComponents?: { components?: unknown } })?.updateComponents
      ?.components;
    return (
      Array.isArray(comps) && comps.some((c) => (c as { component?: unknown })?.component === name)
    );
  });
}

/** The action in the person's message, when this chat showed its surface with [component]. */
function confirmedAction(current: unknown, earlier: unknown[], name: string, component: string) {
  const action = parts(current).find((p) => p.type === "ui_action" && p.name === name);
  if (!action || typeof action.surface_id !== "string") return null;
  const surfaceId = action.surface_id;
  const shown = earlier.some((content) =>
    parts(content).some(
      (p) => p.type === "ui" && p.surface_id === surfaceId && showsComponent(p.messages, component),
    ),
  );
  if (!shown) return null;
  return { surfaceId, ctx: (action.context ?? {}) as Record<string, unknown> };
}

/**
 * The draft the person sent from: the "draft.send" action in their message, when the bot's
 * earlier message in this chat showed that surface with a MessageDraft. ui.show refuses "draft."
 * events on any other component, so the action came from the draft's own Send button.
 */
export function confirmedDraft(current: unknown, earlier: unknown[]): DraftFields | null {
  const found = confirmedAction(current, earlier, "draft.send", "MessageDraft");
  const body = text(found?.ctx.body);
  if (!found || !body) return null;
  const { ctx } = found;
  return {
    surfaceId: found.surfaceId,
    to: list(ctx.to),
    cc: list(ctx.cc),
    bcc: list(ctx.bcc),
    from: text(ctx.from),
    subject: text(ctx.subject),
    body,
  };
}

/** The event the person added from an Event card's own Add to calendar ("event.add"). */
export function confirmedEvent(current: unknown, earlier: unknown[]): EventFields | null {
  const found = confirmedAction(current, earlier, "event.add", "Event");
  const title = text(found?.ctx.title);
  const start = /^(\d{4}-\d{2}-\d{2})(?:[T ](\d{2}:\d{2}))?/.exec(text(found?.ctx.start) ?? "");
  if (!found || !title || !start?.[1]) return null;
  const { ctx } = found;
  return {
    surfaceId: found.surfaceId,
    title,
    date: start[1],
    time: ctx.allDay === true ? null : (start[2] ?? null),
    attendees: list(ctx.attendees),
    location: text(ctx.location),
    description: text(ctx.description),
  };
}

/** The card the person confirmed in this message, if any. */
export function confirmedCard(current: unknown, earlier: unknown[]): ConfirmedCard | null {
  const draft = confirmedDraft(current, earlier);
  if (draft) return { kind: "draft", ...draft };
  const event = confirmedEvent(current, earlier);
  return event ? { kind: "event", ...event } : null;
}

/** Whether a tool call does exactly what the confirmed card showed. */
export function cardCovers(card: ConfirmedCard, args: unknown): boolean {
  return card.kind === "draft" ? draftCovers(card, args) : eventCovers(card, args);
}

const EMAIL = /[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}/gi;

/** Text with markup and spacing taken out, for comparing a message in any format. */
function plain(s: string) {
  return s
    .replace(/<br\s*\/?>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&#39;|&apos;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/[*_`]/g, "")
    .replace(/\s+/g, " ")
    .trim()
    .toLowerCase();
}

/** Every string in a tool call's arguments, with base64 parts (a raw MIME message) decoded too. */
function strings(v: unknown, out: string[] = [], depth = 0): string[] {
  if (depth > 8) return out;
  if (typeof v === "string") {
    out.push(v);
    if (v.length >= 40 && /^[A-Za-z0-9+/_=-]+$/.test(v)) {
      const decoded = Buffer.from(v.replace(/-/g, "+").replace(/_/g, "/"), "base64").toString(
        "utf8",
      );
      // Bytes that aren't UTF-8 text decode with replacement characters: not a message.
      if (!decoded.includes("\uFFFD")) out.push(decoded);
    }
  } else if (Array.isArray(v)) for (const x of v) strings(x, out, depth + 1);
  else if (v && typeof v === "object") for (const x of Object.values(v)) strings(x, out, depth + 1);
  return out;
}

/**
 * Whether a tool call sends the draft as the person last saw it: one of its texts is the body
 * itself (nothing added or left out), the subject and every recipient are in it, and it addresses
 * no one the draft didn't.
 */
export function draftCovers(draft: DraftFields, args: unknown): boolean {
  const all = strings(args);
  const body = plain(draft.body);
  // A raw MIME message carries headers before its body.
  const bodies = all.flatMap((s) => [
    s,
    s
      .split(/\r?\n\r?\n/)
      .slice(1)
      .join("\n\n"),
  ]);
  if (!bodies.some((s) => plain(s) === body)) return false;
  const joined = plain(all.join(" \n "));
  if (draft.subject && !joined.includes(plain(draft.subject))) return false;
  const people = [...draft.to, ...draft.cc, ...draft.bcc];
  for (const p of people) if (!joined.includes(plain(p))) return false;
  const allowed = new Set(
    // Addresses written in the message itself ("reach me at …") are part of what was approved.
    [...people, draft.from ?? "", draft.subject ?? "", draft.body]
      .flatMap((p) => p.match(EMAIL) ?? [])
      .map((e) => e.toLowerCase()),
  );
  const found = all.join(" ").match(EMAIL) ?? [];
  return found.every((e) => allowed.has(e.toLowerCase()));
}

/** Strings with the key they sit under, skipping the calendar or account a call names itself. */
function keyed(v: unknown, key = "", out: string[] = [], depth = 0): string[] {
  if (depth > 8) return out;
  if (/calendar|organi[sz]er|owner|account|user/i.test(key)) return out;
  if (typeof v === "string") out.push(v);
  else if (Array.isArray(v)) for (const x of v) keyed(x, key, out, depth + 1);
  else if (v && typeof v === "object")
    for (const [k, x] of Object.entries(v)) keyed(x, k, out, depth + 1);
  return out;
}

/**
 * Whether a tool call adds the event as the card showed it: its title, its day and start time, and
 * every guest are in it, and it invites nobody the card didn't.
 */
export function eventCovers(event: EventFields, args: unknown): boolean {
  const all = strings(args);
  const joined = plain(all.join(" \n "));
  if (!joined.includes(plain(event.title))) return false;
  const time = event.time;
  if (!all.some((s) => s.includes(event.date) && (!time || s.includes(time)))) return false;
  for (const p of event.attendees) if (!joined.includes(plain(p))) return false;
  const allowed = new Set(
    [...event.attendees, event.location ?? "", event.description ?? "", event.title]
      .flatMap((p) => p.match(EMAIL) ?? [])
      .map((e) => e.toLowerCase()),
  );
  const found = keyed(args).join(" ").match(EMAIL) ?? [];
  return found.every((e) => allowed.has(e.toLowerCase()));
}
