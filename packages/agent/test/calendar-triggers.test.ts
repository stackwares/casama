import { describe, expect, it } from "vitest";
import { describeEvent, eventMatches, listArgs, parseEvents } from "../src/calendar-triggers.ts";

const google = JSON.stringify({
  items: [
    {
      id: "e1",
      summary: "Pricing call with Globex",
      start: { dateTime: "2026-11-11T10:00:00Z" },
      end: { dateTime: "2026-11-11T10:30:00Z" },
      attendees: [{ email: "ana@acme.test", self: true }, { email: "lee@globex.test" }],
      hangoutLink: "https://meet.google.com/abc-defg-hij",
    },
    {
      id: "e2",
      summary: "Team standup",
      start: { dateTime: "2026-11-11T09:00:00Z" },
      attendees: [{ email: "ana@acme.test", self: true }, { email: "ben@acme.test" }],
    },
    {
      id: "e3",
      summary: "Cancelled",
      status: "cancelled",
      start: { dateTime: "2026-11-11T11:00:00Z" },
    },
  ],
});
const graph = JSON.stringify({
  value: [
    {
      id: "m1",
      subject: "Review",
      start: { dateTime: "2026-11-11T12:00:00" },
      attendees: [{ emailAddress: { address: "x@other.test" } }],
      body: { content: "Join https://teams.microsoft.com/l/meetup-join/123" },
    },
  ],
});

describe("calendar triggers", () => {
  it("reads Google and Microsoft event shapes, skipping cancelled ones", () => {
    const g = parseEvents(google);
    expect(g.map((e) => e.id)).toEqual(["e1", "e2"]);
    expect(g[0]).toMatchObject({
      title: "Pricing call with Globex",
      selfEmail: "ana@acme.test",
      link: "https://meet.google.com/abc-defg-hij",
    });
    const m = parseEvents(graph);
    expect(m[0]).toMatchObject({
      title: "Review",
      attendees: ["x@other.test"],
      link: "https://teams.microsoft.com/l/meetup-join/123",
    });
    expect(parseEvents("not json")).toEqual([]);
  });

  it("filters by outside guests, title and video link", () => {
    const [ext, internal] = parseEvents(google) as [
      ReturnType<typeof parseEvents>[0],
      ReturnType<typeof parseEvents>[0],
    ];
    const t = { type: "calendar_event" as const, integration_id: "i", offset_minutes: -15 };
    expect(eventMatches(ext, { ...t, outside_guests: true }, null)).toBe(true);
    expect(eventMatches(internal, { ...t, outside_guests: true }, null)).toBe(false);
    expect(eventMatches(internal, { ...t, has_video_link: true }, null)).toBe(false);
    expect(eventMatches(ext, { ...t, title_match: "globex" }, null)).toBe(true);
    expect(describeEvent(ext)).toContain("Attendees: ana@acme.test, lee@globex.test");
  });

  it("names list arguments the way the tool's schema does", () => {
    const from = new Date("2026-11-11T00:00:00Z");
    const to = new Date("2026-11-12T00:00:00Z");
    expect(
      listArgs({ properties: { timeMin: {}, timeMax: {}, singleEvents: {} } }, from, to),
    ).toEqual({ timeMin: from.toISOString(), timeMax: to.toISOString(), singleEvents: true });
    expect(
      Object.keys(listArgs({ properties: { startDateTime: {}, endDateTime: {} } }, from, to)),
    ).toEqual(["startDateTime", "endDateTime"]);
  });
});
