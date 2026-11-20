/** Bot pictures (docs/BOT-PICTURES-PLAN.md §6): upload, serve, recent, undo, re-crop, rules. */
import { parseBotAvatar } from "@casama/domain";
import sharp from "sharp";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let me: { id: string; token: string };
let other: { id: string; token: string };
let orgId = "";
let botId = "";

const square = (rgb: [number, number, number], side = 768) =>
  sharp({
    create: {
      width: side,
      height: side,
      channels: 3,
      background: { r: rgb[0], g: rgb[1], b: rgb[2] },
    },
  })
    .png()
    .toBuffer();

beforeAll(async () => {
  h = await startHarness();
  me = await h.user("pictures@example.com");
  other = await h.user("stranger@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: me.token, json: { name: "Mine" } }),
    )
  ).id;
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: me.token,
        json: { org_id: orgId, name: "Ada", avatar_url: "mascot:wow" },
      }),
    )
  ).id;
}, 60_000);
afterAll(async () => h?.stop());

const call = (path: string, init: { method?: string; json?: unknown; token?: string } = {}) =>
  h.request(path, { token: me.token, ...init });

const upload = async (rgb: [number, number, number], extra: Record<string, unknown> = {}) =>
  call(`/v1/bots/${botId}/image`, {
    method: "PUT",
    json: { data: (await square(rgb)).toString("base64"), ...extra },
  });

describe("bot pictures", () => {
  it("sets a picture, serves it without a token and remembers the mascot", async () => {
    // A photo with GPS-like metadata goes in as the original; nothing of it comes back out.
    const original = await sharp({
      create: { width: 2400, height: 1600, channels: 3, background: "#3366cc" },
    })
      .jpeg()
      .withExif({ IFD0: { Make: "Casama Test Camera" } })
      .toBuffer();
    const res = await upload([40, 120, 220], {
      original: original.toString("base64"),
      crop: { x: 0.5, y: 0.4, scale: 0.8, rotation: 0, mirror: false, background: "none" },
    });
    expect(res.status).toBe(200);
    const bot = await j(res);
    const a = parseBotAvatar(bot.avatar_url);
    expect(a.kind).toBe("image");
    if (a.kind !== "image") return;

    const big = await h.request(`/v1/bot-images/${a.id}`);
    expect(big.status).toBe(200);
    expect(big.headers.get("content-type")).toBe("image/webp");
    expect(big.headers.get("cache-control")).toContain("immutable");
    expect(big.headers.get("x-content-type-options")).toBe("nosniff");
    expect((await sharp(Buffer.from(await big.arrayBuffer())).metadata()).width).toBe(512);
    const small = await h.request(`/v1/bot-images/${a.id}?size=128&format=png`);
    expect(small.headers.get("content-type")).toBe("image/png");
    expect((await sharp(Buffer.from(await small.arrayBuffer())).metadata()).width).toBe(128);
    expect((await h.request("/v1/bot-images/not-an-id")).status).toBe(404);

    const [row] = await h.tdb.admin<{ prior_mascot: string }[]>`
      select prior_mascot from public.bots where id = ${botId}`;
    expect(row?.prior_mascot).toBe("mascot:wow");

    // Re-crop gets the shrunk original back, without the camera's details.
    const list = await j(await call(`/v1/bots/${botId}/images`));
    expect(list.items[0]).toMatchObject({
      id: a.id,
      in_use: true,
      has_original: true,
      source: "upload",
    });
    expect(list.items[0].crop).toMatchObject({ y: 0.4 });
    const o = await call(`/v1/bots/${botId}/images/${a.id}/original`);
    expect(o.headers.get("content-type")).toBe("image/jpeg");
    const ob = Buffer.from(await o.arrayBuffer());
    expect((await sharp(ob).metadata()).width).toBe(2048);
    expect(ob.includes(Buffer.from("Casama Test Camera"))).toBe(false);
  });

  it("keeps recent pictures, switches back (undo) and removes back to the mascot", async () => {
    const first = parseBotAvatar((await j(await upload([200, 60, 60]))).avatar_url);
    const second = parseBotAvatar((await j(await upload([60, 200, 60]))).avatar_url);
    if (first.kind !== "image" || second.kind !== "image") throw new Error("no picture");
    const undo = await j(
      await call(`/v1/bots/${botId}/images/${first.id}/use`, { method: "POST" }),
    );
    expect(parseBotAvatar(undo.avatar_url)).toMatchObject({ id: first.id });
    const list = await j(await call(`/v1/bots/${botId}/images`));
    expect(list.items[0].id).toBe(first.id);
    expect(list.items.map((i: { id: string }) => i.id)).toContain(second.id);

    const removed = await j(await call(`/v1/bots/${botId}/image`, { method: "DELETE" }));
    expect(removed.avatar_url).toBe("mascot:wow");
  });

  it("a shared template carries the mascot the bot had before its picture, never the picture", async () => {
    await upload([90, 30, 160]);
    const exported = await j(await call(`/v1/bots/${botId}/export`));
    expect(exported.avatar).toBe("mascot:wow");
  });

  it("keeps only the five most recent and the originals of the newest two", async () => {
    for (let i = 0; i < 6; i++)
      await upload([20 * i, 100, 180], {
        original: (await square([20 * i, 0, 0], 300)).toString("base64"),
      });
    const [n] = await h.tdb.admin<{ all: number; originals: number }[]>`
      select count(*)::int as all, count(original)::int as originals from public.bot_images where bot_id = ${botId}`;
    expect(n).toEqual({ all: 5, originals: 2 });
  });

  it("refuses what isn't a picture, and people who can't manage the bot", async () => {
    const bad = await call(`/v1/bots/${botId}/image`, {
      method: "PUT",
      json: { data: Buffer.from("<svg onload=alert(1)>").toString("base64") },
    });
    expect(bad.status).toBe(400);
    expect((await j(bad)).code).toBe("picture_unreadable");
    const stranger = await call(`/v1/bots/${botId}/image`, {
      method: "PUT",
      token: other.token,
      json: { data: (await square([1, 2, 3])).toString("base64") },
    });
    expect(stranger.status).toBe(404);
  });

  it("only lets avatar_url name a mascot or this bot's own picture with its real colours", async () => {
    const [img] = await h.tdb.admin<{ id: string; colors: string }[]>`
      select id, colors from public.bot_images where bot_id = ${botId} limit 1`;
    const other = (
      await j(await call("/v1/bots", { method: "POST", json: { org_id: orgId, name: "Bea" } }))
    ).id;
    const tryValue = (bot: string, v: string) =>
      h.tdb.admin`update public.bots set avatar_url = ${v} where id = ${bot}`.then(
        () => "ok",
        (e: { code?: string }) => e.code,
      );
    expect(await tryValue(botId, "https://tracker.example/p.gif")).toBe("23514");
    expect(await tryValue(botId, "mascot:nobody")).toBe("23514");
    expect(await tryValue(botId, `image:${img!.id}:000000ffffff`)).toBe("23514");
    expect(await tryValue(other, `image:${img!.id}:${img!.colors}`)).toBe("23514");
    expect(await tryValue(botId, `image:${img!.id}:${img!.colors}`)).toBe("ok");
    expect(await tryValue(botId, "mascot:cool")).toBe("ok");
    // Creating a bot with a web link as its picture is refused by the API too.
    const created = await call("/v1/bots", {
      method: "POST",
      json: { org_id: orgId, name: "Cy", avatar_url: "https://tracker.example/p.gif" },
    });
    expect(created.status).toBe(400);
  });

  it("limits uploads to twenty a day per bot", async () => {
    await h.tdb.admin`update public.bot_image_counts set uploads = 20 where bot_id = ${botId}`;
    const res = await upload([5, 5, 5]);
    expect(res.status).toBe(429);
  });

  it("says why when drawing isn't possible", async () => {
    const res = await call(`/v1/bots/${botId}/images/generate`, {
      method: "POST",
      json: { style: "cloud" },
    });
    expect(res.status).toBe(409);
    expect((await j(res)).code).toBe("no_media_provider");
  });
});

describe("drawing pictures and the bot's own tool", () => {
  const drawn: string[] = [];
  const setup = async (actingUserId: string) => {
    const { registerAutonomyTools, ToolRegistry } = await import("@casama/agent");
    const reg = new ToolRegistry();
    let draw: ((a: never) => Promise<{ ids: string[] }>) | undefined;
    const png = await square([240, 120, 40], 1024);
    registerAutonomyTools(reg, {
      db: h.handle.db,
      fetch,
      exposeBotPictures: (api) => {
        draw = api.draw as never;
      },
      mediaFor: async () =>
        ({
          id: "fake",
          generateImage: async (req: { prompt: string }) => {
            drawn.push(req.prompt);
            return [
              { url: "", data: new Uint8Array(png), contentType: "image/png", costUsd: 0.03 },
            ];
          },
          generateVideo: async () => ({ url: "", contentType: "video/mp4" }),
        }) as never,
    });
    const [r] = await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, created_by) values (${orgId}, ${botId}, ${me.id}) returning id`;
    const ctx = {
      runId: r!.id,
      botId,
      orgId,
      actingUserId,
      output: async () => {},
      emit: async () => {},
    };
    return { reg, draw: draw!, ctx };
  };

  it("draws candidates that don't change the bot, charged as bot pictures", async () => {
    const { draw } = await setup(me.id);
    const before = (
      await h.tdb.admin<
        { avatar_url: string }[]
      >`select avatar_url from public.bots where id = ${botId}`
    )[0];
    const { ids } = await draw({ orgId, botId, userId: me.id, style: "cloud", count: 2 } as never);
    expect(ids).toHaveLength(2);
    expect(drawn.at(-1)).toContain("cloud mascot");
    expect(drawn.at(-1)).toContain('"Ada"'); // no description: from the bot's name
    const after = (
      await h.tdb.admin<
        { avatar_url: string }[]
      >`select avatar_url from public.bots where id = ${botId}`
    )[0];
    expect(after).toEqual(before);
    const rows = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.usage_ledger where org_id = ${orgId} and meta->>'purpose' = 'bot_picture'`;
    expect(rows[0]!.n).toBe(2);
    const list = await j(await call(`/v1/bots/${botId}/images?candidates=true`));
    expect(list.items.map((i: { id: string }) => i.id).sort()).toEqual([...ids].sort());
    // Using one makes it a normal recent picture.
    const used = await j(await call(`/v1/bots/${botId}/images/${ids[0]}/use`, { method: "POST" }));
    expect(parseBotAvatar(used.avatar_url)).toMatchObject({ id: ids[0] });
  });

  it("lets a manager ask the bot to draw itself, and undo it", async () => {
    const { reg, ctx } = await setup(me.id);
    const tool = reg.get("profile.set_picture")!;
    const before = (
      await h.tdb.admin<
        { avatar_url: string }[]
      >`select avatar_url from public.bots where id = ${botId}`
    )[0]!.avatar_url;
    const out = await tool.execute(
      { draw: "an owl with reading glasses", style: "flat" } as never,
      ctx as never,
    );
    expect(out.content).toContain("picture is changed");
    const now = (
      await h.tdb.admin<
        { avatar_url: string }[]
      >`select avatar_url from public.bots where id = ${botId}`
    )[0]!.avatar_url;
    expect(now).not.toBe(before);
    expect(drawn.at(-1)).toContain("owl with reading glasses");
    await tool.execute({ undo: true } as never, ctx as never);
    const back = (
      await h.tdb.admin<
        { avatar_url: string }[]
      >`select avatar_url from public.bots where id = ${botId}`
    )[0]!.avatar_url;
    expect(back).toBe(before);
  });

  it("refuses someone who doesn't manage the bot", async () => {
    const { reg, ctx } = await setup(other.id);
    await expect(
      reg.get("profile.set_picture")!.execute({ draw: "a cat" } as never, ctx as never),
    ).rejects.toMatchObject({ code: "forbidden" });
  });
});
