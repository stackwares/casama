/** Calendar triggers (D-132): a routine 15 minutes before meetings with outside guests. */
import { once } from "node:events";
import { createServer, type IncomingMessage, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { checkCalendarTriggers } from "@casama/agent";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { z } from "zod";
import { fireDueCalendarRuns } from "../src/worker/routines.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let cal: Server;
let calUrl = "";
const start = new Date(Date.now() + 60 * 60_000); // in an hour
const calls: unknown[] = [];
/** Audit 2026-11: the external meeting can be cancelled after its fire is scheduled. */
let cancelled = false;

beforeAll(async () => {
  cal = createServer(async (req: IncomingMessage, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    const raw = Buffer.concat(chunks).toString();
    const server = new McpServer({ name: "calendar", version: "1.0.0" });
    server.registerTool(
      "list_events",
      { description: "List events", inputSchema: { timeMin: z.string(), timeMax: z.string() } },
      async (args) => {
        calls.push(args);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                items: [
                  ...(cancelled
                    ? []
                    : [
                        {
                          id: "ext",
                          summary: "Call with Globex",
                          start: { dateTime: start.toISOString() },
                          attendees: [
                            { email: "ana@example.com", self: true },
                            { email: "lee@globex.test" },
                          ],
                        },
                      ]),
                  {
                    id: "int",
                    summary: "Standup",
                    start: { dateTime: start.toISOString() },
                    attendees: [
                      { email: "ana@example.com", self: true },
                      { email: "ben@example.com" },
                    ],
                  },
                ],
              }),
            },
          ],
        };
      },
    );
    const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
    res.on("close", () => void transport.close());
    await server.connect(transport);
    await transport.handleRequest(req, res, raw ? JSON.parse(raw) : undefined);
  }).listen(0, "127.0.0.1");
  await once(cal, "listening");
  calUrl = `http://127.0.0.1:${(cal.address() as AddressInfo).port}/mcp`;
  h = await startHarness();
}, 60_000);
afterAll(async () => {
  await h?.stop();
  cal?.close();
});

describe("calendar triggers", () => {
  it("runs 15 minutes before meetings with outside guests, once, with the event in context", async () => {
    const ana = await h.user("ana@example.com");
    const orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: ana.token, json: { name: "C" } }),
      )
    ).id;
    const botId = (
      await j(
        await h.request("/v1/bots", {
          method: "POST",
          token: ana.token,
          json: { org_id: orgId, name: "Prep" },
        }),
      )
    ).id;
    const [i] = await h.tdb.admin<{ id: string }[]>`
      insert into public.integrations (org_id, kind, name, config, status, tools_cache, tools_cached_at)
      values (${orgId}, 'mcp', 'google_calendar', ${JSON.stringify({ url: calUrl, app: "google_calendar" })}::text::jsonb, 'ok',
              ${JSON.stringify([{ name: "list_events", description: "List events", inputSchema: { type: "object", properties: { timeMin: {}, timeMax: {} } } }])}::text::jsonb, now())
      returning id`;
    const res = await h.request("/v1/routines", {
      method: "POST",
      token: ana.token,
      json: {
        bot_id: botId,
        name: "Meeting prep",
        instructions: "Prepare a one-page brief on the people I'm meeting.",
        trigger: "calendar_event",
        calendar: { integration_id: i!.id, offset_minutes: -15, outside_guests: true },
      },
    });
    expect(res.status).toBe(201);
    const routine = await j(res);
    expect(routine).toMatchObject({
      trigger: "calendar_event",
      calendar: { offset_minutes: -15, outside_guests: true },
    });

    const now = new Date();
    expect(await checkCalendarTriggers({ db: h.handle.db, fetch }, now)).toBe(1);
    expect(calls).toHaveLength(1);
    // Checked again within 5 minutes: no new read.
    expect(
      await checkCalendarTriggers({ db: h.handle.db, fetch }, new Date(now.getTime() + 60_000)),
    ).toBe(0);
    expect(calls).toHaveLength(1);
    // Not yet due; then due at start − 15 min (within the minute).
    expect(await fireDueCalendarRuns(h.handle.db, new Date(start.getTime() - 16 * 60_000))).toEqual(
      [],
    );
    const runs = await fireDueCalendarRuns(
      h.handle.db,
      new Date(start.getTime() - 15 * 60_000 + 30_000),
    );
    expect(runs).toHaveLength(1);
    expect(await fireDueCalendarRuns(h.handle.db, new Date(start.getTime()))).toEqual([]);
    const [m] = await h.tdb.admin<
      { content: Array<{ text: string }> }[]
    >`select content from public.messages where run_id = ${runs[0] as string}`;
    expect(m?.content[0]?.text).toContain("Event: Call with Globex");
    expect(m?.content[0]?.text).toContain('<untrusted source="calendar">');
    expect(m?.content[0]?.text).not.toContain("Standup");
  });

  it("a cancelled meeting's fire is dropped at the next check, and stale fires never run (audit 2026-11)", async () => {
    const ana = await h.user("ana2@example.com");
    const orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: ana.token, json: { name: "C2" } }),
      )
    ).id;
    const botId = (
      await j(
        await h.request("/v1/bots", {
          method: "POST",
          token: ana.token,
          json: { org_id: orgId, name: "Prep2" },
        }),
      )
    ).id;
    const [i] = await h.tdb.admin<{ id: string }[]>`
      insert into public.integrations (org_id, kind, name, config, status, tools_cache, tools_cached_at)
      values (${orgId}, 'mcp', 'google_calendar', ${JSON.stringify({ url: calUrl, app: "google_calendar" })}::text::jsonb, 'ok',
              ${JSON.stringify([{ name: "list_events", description: "List events", inputSchema: { type: "object", properties: { timeMin: {}, timeMax: {} } } }])}::text::jsonb, now())
      returning id`;
    const routine = await j(
      await h.request("/v1/routines", {
        method: "POST",
        token: ana.token,
        json: {
          bot_id: botId,
          name: "Prep 2",
          instructions: "Prepare.",
          trigger: "calendar_event",
          calendar: { integration_id: i!.id, offset_minutes: -15, outside_guests: true },
        },
      }),
    );
    const now = new Date();
    cancelled = false;
    expect(await checkCalendarTriggers({ db: h.handle.db, fetch }, now)).toBe(1);
    cancelled = true;
    await checkCalendarTriggers({ db: h.handle.db, fetch }, new Date(now.getTime() + 5 * 60_000));
    expect(
      await h.tdb
        .admin`select 1 from public.calendar_fires where routine_id = ${routine.id} and fired_at is null`,
    ).toHaveLength(0);
    cancelled = false;
    // A fire left over from long ago (the worker was down) doesn't run now.
    await h.tdb
      .admin`insert into public.calendar_fires (routine_id, event_id, org_id, fire_at, event)
      values (${routine.id}, 'old', ${orgId}, now() - interval '2 hours', '{"id":"old","title":"Old"}'::jsonb)`;
    expect(await fireDueCalendarRuns(h.handle.db)).toEqual([]);
  });
});
