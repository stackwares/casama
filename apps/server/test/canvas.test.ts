/** Bot widgets (docs/BOT-WIDGET-PLAN.md): the widget.* tools, the canvas routes and the grant. */

import { deflateSync } from "node:zlib";
import {
  GlancePusher,
  RecordingWidgetPushSender,
  registerWidgetTools,
  ToolError,
  ToolRegistry,
} from "@casama/agent";
import { CanvasList } from "@casama/contracts";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let me: { id: string; token: string };
let other: { id: string; token: string };
let orgId: string;
let botId: string;
let bot2: string;
let chatRun: string;
let otherRun: string;
let linkRun: string;
let widgetKey: string;
const reg = new ToolRegistry();
const events: Array<{ type: string; payload: Record<string, unknown> }> = [];
const pushes = new RecordingWidgetPushSender();
const changed: string[] = [];
const files: Record<string, Uint8Array> = {};

const ctx = (runId: string, bot = botId) =>
  ({
    runId,
    botId: bot,
    orgId,
    output: async () => {},
    emit: async (type: string, payload: Record<string, unknown>) =>
      void events.push({ type, payload }),
    computer: async () => ({
      readFile: async (p: string) => {
        const f = files[p];
        if (!f) throw new Error("not found");
        return f;
      },
    }),
  }) as never;
const call = (name: string, args: unknown, runId = chatRun, bot = botId) => {
  const def = reg.get(name)!;
  return def.execute(def.schema.parse(args) as never, ctx(runId, bot));
};
const widget = (path: string, init: RequestInit = {}) =>
  h.request(path, { ...init, headers: { authorization: `Widget ${widgetKey}`, ...init.headers } });
/** A plain PNG of one colour (no image library in this package). */
function png(width: number, height: number, rgb: [number, number, number]) {
  const crcTable = Array.from({ length: 256 }, (_, n) => {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    return c >>> 0;
  });
  const crc = (b: Buffer) => {
    let c = 0xffffffff;
    for (const x of b) c = (crcTable[(c ^ x) & 255] as number) ^ (c >>> 8);
    return (c ^ 0xffffffff) >>> 0;
  };
  const chunk = (type: string, data: Buffer) => {
    const len = Buffer.alloc(4);
    len.writeUInt32BE(data.length);
    const td = Buffer.concat([Buffer.from(type), data]);
    const c = Buffer.alloc(4);
    c.writeUInt32BE(crc(td));
    return Buffer.concat([len, td, c]);
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = 2;
  const row = Buffer.alloc(1 + width * 3);
  for (let x = 0; x < width; x++) row.set(rgb, 1 + x * 3);
  const raw = Buffer.concat(Array.from({ length: height }, () => row));
  return new Uint8Array(
    Buffer.concat([
      Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
      chunk("IHDR", ihdr),
      chunk("IDAT", deflateSync(raw)),
      chunk("IEND", Buffer.alloc(0)),
    ]),
  );
}

/** A JPEG's width and height, from its frame header. */
function jpegSize(b: Uint8Array) {
  let i = 2;
  while (i < b.length) {
    const marker = b[i + 1] as number;
    const len = ((b[i + 2] as number) << 8) | (b[i + 3] as number);
    if (marker >= 0xc0 && marker <= 0xc2)
      return {
        height: ((b[i + 5] as number) << 8) | (b[i + 6] as number),
        width: ((b[i + 7] as number) << 8) | (b[i + 8] as number),
      };
    i += 2 + len;
  }
  return null;
}

const list = async (token = me.token) =>
  CanvasList.parse(await j(await h.request(`/v1/canvases?org_id=${orgId}`, { token })));

beforeAll(async () => {
  h = await startHarness();
  h.deps.glance = new GlancePusher(h.handle.db, pushes, { urgentDelayMs: 5 });
  registerWidgetTools(reg, {
    db: h.handle.db,
    objects: null,
    changed: (u) => void changed.push(u),
  });
  me = await h.user("canvas-me@example.com");
  other = await h.user("canvas-other@example.com");
  orgId = (
    await j(await h.request("/v1/orgs", { method: "POST", token: me.token, json: { name: "C" } }))
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${other.id}, 'member')`;
  const [b] = await h.tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name, avatar_url) values (${orgId}, ${me.id}, 'Verse', 'mascot:winky') returning id`;
  botId = b!.id;
  const [b2] = await h.tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name) values (${orgId}, ${me.id}, 'Other') returning id`;
  bot2 = b2!.id;
  const [conv] = await h.tdb.admin<{ id: string }[]>`
    insert into public.conversations (org_id, bot_id, created_by) values (${orgId}, ${botId}, ${me.id}) returning id`;
  const run = async (who: string | null, trigger: string, bot = botId) =>
    (
      await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, trigger, status, created_by, conversation_id)
      values (${orgId}, ${bot}, ${trigger}, 'running', ${who}, ${conv!.id}) returning id`
    )[0]!.id;
  chatRun = await run(me.id, "chat");
  otherRun = await run(other.id, "chat");
  linkRun = await run(me.id, "link");
  await h.tdb
    .admin`update public.profiles set display_name = 'Oliver Test', timezone = 'Asia/Manila' where user_id = ${me.id}`;
  widgetKey = (
    await j(
      await h.request("/v1/widget-keys", {
        method: "POST",
        token: me.token,
        json: { org_id: orgId, platform: "ios", label: "Oliver's iPhone" },
      }),
    )
  ).key;
  await h.tdb
    .admin`update public.widget_keys set push_token = 'abcdef0123456789', push_kind = 'apns_widgets' where user_id = ${me.id}`;
});

afterAll(async () => {
  h.deps.glance?.stop();
  await h?.stop();
});

describe("widget.set", () => {
  it("waits for the person's yes the first time, with a preview", async () => {
    const r = await call("widget.set", {
      name: "Daily verse",
      text: "Be still, and know that I am God.",
      footer: "Ps 46:10",
      background: { painting: "night_sky" },
      font: "serif",
    });
    expect(r.content).toContain("Show on my widgets");
    const preview = events.find((e) => e.type === "canvas.preview");
    expect(preview?.payload.state).toBe("waiting");
    expect(changed).toHaveLength(0);
    const l = await list();
    expect(l.items[0]).toMatchObject({ name: "Daily verse", status: "waiting", bot: "Verse" });
    expect(l.items[0]?.entries[0]?.look).toMatchObject({ ink: "light", font: "serif" });
    // A widget sees only shown canvases.
    const w = CanvasList.parse(await j(await widget("/v1/canvases?sizes=lock_rect,home_small")));
    expect(w.items).toHaveLength(0);
  });

  it("Show on my widgets shows it and lets the bot write from then on", async () => {
    const res = await h.request("/v1/canvas-grants", {
      method: "PUT",
      token: me.token,
      json: { bot_id: botId, allowed: true },
    });
    expect(await j(res)).toMatchObject({ allowed: true, shown: 1 });
    const w = CanvasList.parse(await j(await widget("/v1/canvases?sizes=lock_rect,home_small")));
    expect(w.items[0]?.entries[0]).toMatchObject({
      template: "text",
      short: "Be still, and know that I am God. · Ps 46:10",
    });
    expect((await list()).grants.map((g) => g.bot_id)).toEqual([botId]);
    // The widget asked with its sizes: the bot can now say where it shows.
    events.length = 0;
    const r = await call("widget.set", {
      name: "Daily verse",
      text: "Rejoice always.",
      footer: "1 Thess 5:16",
    });
    expect(r.content).toContain("Showing on Oliver's iPhone (Lock Screen, Home Screen)");
    expect(r.content).toContain('The Lock Screen shows: "Rejoice always. · 1 Thess 5:16"');
    expect(changed).toContain(me.id);
    expect(events.find((e) => e.type === "canvas.preview")?.payload.state).toBe("shown");
  });

  it("answers 304 when nothing changed", async () => {
    const first = await widget("/v1/canvases");
    const etag = first.headers.get("etag")!;
    const again = await widget("/v1/canvases", { headers: { "if-none-match": etag } });
    expect(again.status).toBe(304);
  });

  it("a rotation deals the next 14 from one write, in the person's time zone", async () => {
    const r = await call("widget.set", {
      name: "Daily verse",
      rotate: { every: "day", at: "06:00", order: "shuffle" },
      rotate_items: Array.from({ length: 30 }, (_, i) => ({
        text: `Verse ${i}`,
        footer: `Ref ${i}`,
      })),
      background: { gradient: ["#0b1026", "#2b3a6b"] },
    });
    expect(r.content).toContain("A rotation of 30 items, every day at 06:00, shuffled");
    const w = CanvasList.parse(await j(await widget("/v1/canvases")));
    const c = w.items.find((x) => x.name === "Daily verse")!;
    expect(c.entries).toHaveLength(14);
    expect(c.rotation?.count).toBe(30);
    // 06:00 in Manila is 22:00 UTC.
    expect(c.entries[1]?.at?.endsWith("T22:00:00.000Z")).toBe(true);
    expect(new Set(c.entries.map((e) => e.text)).size).toBe(14);
  });

  it("appends from a file and keeps its place", async () => {
    files["~/workspace/verses.txt"] = new TextEncoder().encode("Extra one\nExtra two\n");
    const r = await call("widget.set", {
      name: "Daily verse",
      append: true,
      rotate_file: "workspace/verses.txt",
    });
    expect(r.content).toContain("A rotation of 32 items");
    const listed = await call("widget.list", {});
    expect(listed.content).toContain("Daily verse (shown)");
    expect(listed.content).toContain("rotation of 32 items");
  });

  it("a schedule needs gaps; a countdown clears itself a day after", async () => {
    const soon = new Date(Date.now() + 2 * 60_000).toISOString();
    await expect(
      call("widget.set", { name: "Plan", text: "a", schedule: [{ text: "b", at: soon }] }),
    ).rejects.toThrow(/5 minutes/);
    const target = new Date(Date.now() + 5 * 86_400_000).toISOString();
    await call("widget.set", { name: "Trip", template: "countdown", title: "Tokyo", target });
    const c = (await list()).items.find((x) => x.name === "Trip")!;
    expect(Date.parse(c.until!)).toBe(Date.parse(target) + 86_400_000);
    expect(c.entries[0]).toMatchObject({ template: "countdown", tiny: "Tokyo", count: "down" });
  });

  it("holds the per-bot limit", async () => {
    await call("widget.set", {
      name: "Third",
      template: "list",
      title: "Today",
      items: ["Call", "[x] Gym"],
    });
    const third = (await list()).items.find((x) => x.name === "Third")!;
    expect(third.entries[0]?.items).toEqual([
      { text: "Call", done: false },
      { text: "Gym", done: true },
    ]);
    await expect(call("widget.set", { name: "Fourth", text: "x" })).rejects.toThrow(ToolError);
  });

  it("pictures are fetched, shrunk, stored and served to the widget", async () => {
    files["~/photo.png"] = png(3000, 2000, [245, 240, 224]);
    await call("widget.set", {
      name: "Trip",
      template: "picture",
      picture: "~/photo.png",
      text: "Kyoto",
    });
    const c = (await list()).items.find((x) => x.name === "Trip")!;
    const e = c.entries[0]!;
    expect(e.picture).toMatch(/^[0-9a-f]{32}$/);
    expect(e.look.ink).toBe("dark");
    const res = await widget(`/v1/canvases/${c.id}/pictures/${e.picture}`);
    expect(res.status).toBe(200);
    const jpeg = new Uint8Array(await res.arrayBuffer());
    expect([jpeg[0], jpeg[1]]).toEqual([0xff, 0xd8]);
    expect(jpeg.length).toBeLessThanOrEqual(400 * 1024);
    expect(jpegSize(jpeg)).toEqual({ width: 1200, height: 800 });
    const painting = await widget(`/v1/canvases/${c.id}/pictures/painting-ocean`);
    expect(painting.status).toBe(200);
    // Not a picture: refused.
    files["~/notes.txt"] = new TextEncoder().encode("hello");
    await expect(
      call("widget.set", { name: "Trip", template: "picture", picture: "~/notes.txt" }),
    ).rejects.toThrow(/picture/);
    // A private address: refused by the safe fetch.
    await expect(
      call("widget.set", { name: "Trip", template: "picture", picture: "https://127.0.0.1/x.jpg" }),
    ).rejects.toThrow(ToolError);
  });

  it("is only ever for the person a run acts for", async () => {
    await expect(call("widget.set", { text: "x" }, linkRun)).rejects.toThrow(/one person/);
    // A teammate's chat with the same bot writes the teammate's own canvas, which waits for them.
    await call("widget.set", { text: "For the teammate" }, otherRun);
    expect((await list()).items.some((c) => c.entries[0]?.text === "For the teammate")).toBe(false);
    expect((await list(other.token)).items[0]).toMatchObject({ status: "waiting" });
    // And they can't touch mine.
    const mine = (await list()).items[0]!;
    expect(
      (await h.request(`/v1/canvases/${mine.id}`, { method: "DELETE", token: other.token })).status,
    ).toBe(404);
  });
});

describe("the person's controls", () => {
  it("pauses, hides on a locked phone and clears", async () => {
    const c = (await list()).items.find((x) => x.name === "Daily verse")!;
    const res = await h.request(`/v1/canvases/${c.id}`, {
      method: "PATCH",
      token: me.token,
      json: { status: "paused", hide_when_locked: true },
    });
    expect(await j(res)).toMatchObject({ status: "paused", hide_when_locked: true });
    const w = CanvasList.parse(await j(await widget("/v1/canvases")));
    expect(w.items.some((x) => x.id === c.id)).toBe(false);
    // A bot writing to a paused canvas leaves it paused.
    const r = await call("widget.set", { name: "Daily verse", text: "New" });
    expect(r.content).toContain("paused");
    expect(
      (await h.request(`/v1/canvases/${c.id}`, { method: "DELETE", token: me.token })).status,
    ).toBe(200);
  });

  it("a private widget key gets names only", async () => {
    await h.tdb.admin`update public.widget_keys set private = true where user_id = ${me.id}`;
    const w = CanvasList.parse(await j(await widget("/v1/canvases")));
    expect(w.private).toBe(true);
    expect(w.items.every((x) => x.entries.length === 0)).toBe(true);
    await h.tdb.admin`update public.widget_keys set private = false where user_id = ${me.id}`;
  });

  it("a widget key can't write", async () => {
    const c = (await list()).items[0]!;
    expect((await widget(`/v1/canvases/${c.id}`, { method: "DELETE" })).status).toBe(401);
    expect(
      (
        await widget("/v1/canvas-grants", {
          method: "PUT",
          body: JSON.stringify({ bot_id: botId, allowed: false }),
          headers: { "content-type": "application/json" },
        })
      ).status,
    ).toBe(401);
  });

  it("turning a bot off clears what it showed; widget.clear clears", async () => {
    await call("widget.set", { name: "Mine", text: "x" }, chatRun, bot2);
    expect((await call("widget.clear", { name: "Mine" }, chatRun, bot2)).content).toContain(
      "Cleared",
    );
    const res = await h.request("/v1/canvas-grants", {
      method: "PUT",
      token: me.token,
      json: { bot_id: botId, allowed: false },
    });
    expect((await j(res)).cleared).toBeGreaterThan(0);
    expect((await list()).items.filter((x) => x.bot_id === botId)).toHaveLength(0);
  });

  it("leaving the workspace takes the person's canvases", async () => {
    await h.tdb
      .admin`delete from public.memberships where org_id = ${orgId} and user_id = ${other.id}`;
    const [n] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.widget_canvases where user_id = ${other.id}`;
    expect(n?.n).toBe(0);
  });
});
