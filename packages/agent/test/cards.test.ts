import { describe, expect, it } from "vitest";
import { cardCovers, confirmedCard, confirmedEvent, eventCovers } from "../src/drafts.ts";
import { partsText } from "../src/run.ts";
import { checkComponents, ensureSubmit, ensureWayOut } from "../src/tools/ui.ts";

const event = {
  id: "root",
  component: "Event",
  title: "Design review",
  start: "2026-11-20T14:00",
  end: "2026-11-20T15:00",
  location: "Room 4",
  attendees: ["sarah@acme.com"],
};

const shown = (components: unknown[]) => [
  {
    type: "ui",
    surface_id: "ui_e",
    messages: [{ version: "1.0", updateComponents: { surfaceId: "ui_e", components } }],
  },
];

const add = (context: Record<string, unknown>) => [
  { type: "text", text: "Add to calendar" },
  { type: "ui_action", surface_id: "ui_e", name: "event.add", context },
];

describe("Casama's cards in ui.show (D-337)", () => {
  const valid: Array<Record<string, unknown>> = [
    event,
    { id: "root", component: "Agenda", events: [{ title: "Standup", start: "2026-11-20T09:00" }] },
    {
      id: "root",
      component: "MessageList",
      messages: [{ id: "m1", from: "Sarah", subject: "Review", unread: true }],
    },
    { id: "root", component: "Checklist", items: [{ id: "t1", text: "Book flights" }] },
    {
      id: "root",
      component: "Stats",
      stats: [{ label: "Sleep", value: "7h 12m", change: "+8%", trend: "up", good: "up" }],
      chart: { type: "line", labels: ["Mon", "Tue"], series: [{ values: [6.5, 7.2] }] },
    },
    {
      id: "root",
      component: "Results",
      items: [{ title: "Blue Bottle", rating: 4.6, url: "https://example.com" }],
      choose: true,
    },
    { id: "root", component: "PersonPicker", people: [{ name: "Sarah Lee", detail: "s@x.com" }] },
    {
      id: "root",
      component: "Schedule",
      kind: "routine",
      title: "Brief",
      when: "Weekdays at 8",
      ref: "rt_1",
    },
    { id: "root", component: "Details", rows: [{ label: "Total", value: "$42" }] },
  ];

  it("accepts each card and adds no buttons to it", () => {
    for (const c of valid) {
      expect(() => checkComponents([c]), String(c.component)).not.toThrow();
      expect(ensureWayOut(ensureSubmit([c]))).toEqual([c]);
    }
  });

  it("says what's wrong with a card", () => {
    expect(() => checkComponents([{ ...event, title: undefined }])).toThrow(/needs title/);
    expect(() => checkComponents([{ ...event, start: "next Friday" }])).toThrow(/ISO time/);
    expect(() => checkComponents([{ ...event, attendees: "sarah" }])).toThrow(/list of text/);
    expect(() => checkComponents([{ id: "root", component: "Checklist", items: [] }])).toThrow(
      /needs items/,
    );
    expect(() =>
      checkComponents([{ id: "root", component: "Checklist", items: [{ text: "x" }] }]),
    ).toThrow(/items 1 needs id/);
    expect(() => checkComponents([{ id: "root", component: "Stats" }])).toThrow(/stats, a chart/);
    expect(() =>
      checkComponents([
        {
          id: "root",
          component: "Stats",
          chart: { labels: ["a", "b"], series: [{ values: [1] }] },
        },
      ]),
    ).toThrow(/one number per label/);
    expect(() => checkComponents([{ ...event, action: { event: { name: "go" } } }])).toThrow(
      /own buttons/,
    );
  });

  it("keeps each card's events for its own buttons", () => {
    for (const name of ["event.add", "checklist.save", "person.pick", "schedule.cancel"])
      expect(() =>
        checkComponents([
          { id: "root", component: "Button", child: "t", action: { event: { name } } },
          { id: "t", component: "Text", text: "OK" },
        ]),
      ).toThrow(/belong to/);
  });

  it("tells the bot to add exactly the event", () => {
    expect(partsText(add({ title: "Design review" }))).toMatch(
      /tapped Add to calendar.*without asking me again/s,
    );
  });
});

describe("Add to calendar approves the matching event (D-337)", () => {
  const fields = { ...event, id: undefined, component: undefined };
  const confirmed = confirmedEvent(add(fields), [shown([event])]);
  if (!confirmed) throw new Error("no event");

  it("finds the event only when this chat showed it", () => {
    expect(confirmed).toMatchObject({ title: "Design review", date: "2026-11-20", time: "14:00" });
    expect(confirmedEvent(add(fields), [])).toBeNull();
    expect(
      confirmedEvent(add(fields), [shown([{ ...event, component: "MessageDraft", body: "x" }])]),
    ).toBeNull();
    expect(confirmedCard(add(fields), [shown([event])])?.kind).toBe("event");
  });

  it("covers Google's and the device's create calls for that event", () => {
    const google = {
      calendar_id: "me@gmail.com",
      summary: "Design review",
      start_datetime: "2026-11-20T14:00:00",
      event_duration_hour: 1,
      attendees: ["sarah@acme.com"],
      location: "Room 4",
    };
    expect(eventCovers(confirmed, google)).toBe(true);
    expect(cardCovers({ kind: "event", ...confirmed }, google)).toBe(true);
    expect(
      eventCovers(confirmed, {
        title: "Design review",
        start: { dateTime: "2026-11-20T14:00:00+08:00" },
        attendees: [{ email: "sarah@acme.com" }],
      }),
    ).toBe(true);
  });

  it("doesn't cover another time, title or an added guest", () => {
    const base = {
      summary: "Design review",
      start_datetime: "2026-11-20T14:00:00",
      attendees: ["sarah@acme.com"],
    };
    expect(eventCovers(confirmed, { ...base, start_datetime: "2026-11-21T14:00:00" })).toBe(false);
    expect(eventCovers(confirmed, { ...base, start_datetime: "2026-11-20T16:00:00" })).toBe(false);
    expect(eventCovers(confirmed, { ...base, summary: "Something else" })).toBe(false);
    expect(eventCovers(confirmed, { ...base, attendees: ["sarah@acme.com", "eve@x.com"] })).toBe(
      false,
    );
  });
});
