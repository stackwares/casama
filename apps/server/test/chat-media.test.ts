/** Chat media (D-205): generated images and videos served to workspace members, with byte ranges. */
import { execFileSync } from "node:child_process";
import { randomUUID } from "node:crypto";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { parseRange, videoPoster } from "../src/api/routes/chat-media.ts";
import {
  absoluteComputerPath,
  pdfPreviewable,
  pdfPreviewScript,
} from "../src/api/routes/computers.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

describe("byte ranges", () => {
  it("reads one range the way video players ask for it", () => {
    expect(parseRange("bytes=0-1", 10)).toEqual({ start: 0, end: 1 });
    expect(parseRange("bytes=4-", 10)).toEqual({ start: 4, end: 9 });
    expect(parseRange("bytes=-3", 10)).toEqual({ start: 7, end: 9 });
    expect(parseRange("bytes=2-99", 10)).toEqual({ start: 2, end: 9 });
    expect(parseRange("bytes=10-", 10)).toBeNull();
    expect(parseRange("bytes=5-2", 10)).toBeNull();
    expect(parseRange("bytes=-0", 10)).toBeNull();
    expect(parseRange("bytes=0-1,4-5", 10)).toBeNull();
    expect(parseRange("items=0-1", 10)).toBeNull();
  });
});

describe("pdf previews", () => {
  it("only office documents, at their real path, quoted for the shell", () => {
    expect(pdfPreviewable("reports/Q3.DOCX")).toBe(true);
    expect(pdfPreviewable("deck.pptx")).toBe(true);
    expect(pdfPreviewable("notes.txt")).toBe(false);
    expect(pdfPreviewable("docx")).toBe(false);
    expect(absoluteComputerPath("reports/a.docx")).toBe("/home/casama/workspace/reports/a.docx");
    expect(absoluteComputerPath("~/Downloads/a.xlsx")).toBe("/home/casama/Downloads/a.xlsx");
    expect(absoluteComputerPath("/tmp/a.odt")).toBe("/tmp/a.odt");
    expect(pdfPreviewScript("/home/casama/workspace/it's.docx")).toContain(
      "f='/home/casama/workspace/it'\\''s.docx'",
    );
  });
});

/** A two second test clip made with ffmpeg, or null where ffmpeg isn't installed. */
function testClip(): Buffer | null {
  const dir = mkdtempSync(join(tmpdir(), "casama-clip-"));
  try {
    const out = join(dir, "clip.mp4");
    execFileSync("ffmpeg", [
      "-hide_banner",
      "-loglevel",
      "error",
      "-f",
      "lavfi",
      "-i",
      "testsrc=size=1280x720:rate=10",
      "-t",
      "2",
      "-pix_fmt",
      "yuv420p",
      out,
    ]);
    return readFileSync(out);
  } catch {
    return null;
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}
const clip = testClip();

describe("video posters", () => {
  it.skipIf(!clip)("makes a JPEG at most 480 px on its longest side", async () => {
    const jpeg = await videoPoster(new Uint8Array(clip!), 2);
    expect(jpeg).not.toBeNull();
    expect(jpeg![0]).toBe(0xff);
    expect(jpeg![1]).toBe(0xd8);
    // The SOF0 marker carries the height and width.
    const sof = jpeg!.indexOf(Buffer.from([0xff, 0xc0]));
    expect(jpeg!.readUInt16BE(sof + 7)).toBe(480);
    expect(jpeg!.readUInt16BE(sof + 5)).toBe(270);
  });

  it("gives up quietly on what isn't a video, or without ffmpeg", async () => {
    expect(await videoPoster(new Uint8Array(Buffer.from("0123456789")), null)).toBeNull();
    expect(
      await videoPoster(new Uint8Array(clip ?? Buffer.from("x")), 2, "/nope/ffmpeg"),
    ).toBeNull();
  });
});

let h: Harness;
let owner: { id: string; token: string };
let stranger: { id: string; token: string };
let mediaId = "";
const BYTES = Buffer.from("0123456789");

beforeAll(async () => {
  h = await startHarness();
  owner = await h.user("media-owner@example.com");
  stranger = await h.user("media-stranger@example.com");
  const orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Media" } }),
    )
  ).id;
  const [row] = await h.tdb.admin<{ id: string }[]>`
    insert into public.chat_media (org_id, name, content_type, bytes, size)
    values (${orgId}, 'video.mp4', 'video/mp4', ${BYTES}, ${BYTES.length}) returning id`;
  mediaId = row!.id;
}, 60_000);
afterAll(async () => h?.stop());

describe("GET /v1/media/{id}", () => {
  it("serves members, hides it from everyone else", async () => {
    const res = await h.request(`/v1/media/${mediaId}`, { token: owner.token });
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toBe("video/mp4");
    expect(res.headers.get("accept-ranges")).toBe("bytes");
    expect(res.headers.get("cache-control")).toContain("private");
    expect(Buffer.from(await res.arrayBuffer()).equals(BYTES)).toBe(true);

    expect((await h.request(`/v1/media/${mediaId}`, { token: stranger.token })).status).toBe(404);
    expect((await h.request(`/v1/media/${mediaId}`)).status).toBe(401);
    expect((await h.request(`/v1/media/${randomUUID()}`, { token: owner.token })).status).toBe(404);
    expect((await h.request("/v1/media/nope", { token: owner.token })).status).toBe(404);
  });

  it("answers a byte range with just that slice", async () => {
    const part = await h.request(`/v1/media/${mediaId}`, {
      token: owner.token,
      headers: { range: "bytes=2-5" },
    });
    expect(part.status).toBe(206);
    expect(part.headers.get("content-range")).toBe("bytes 2-5/10");
    expect(Buffer.from(await part.arrayBuffer()).toString()).toBe("2345");

    const tail = await h.request(`/v1/media/${mediaId}`, {
      token: owner.token,
      headers: { range: "bytes=-3" },
    });
    expect(tail.status).toBe(206);
    expect(Buffer.from(await tail.arrayBuffer()).toString()).toBe("789");

    const bad = await h.request(`/v1/media/${mediaId}`, {
      token: owner.token,
      headers: { range: "bytes=50-" },
    });
    expect(bad.status).toBe(416);
    expect(bad.headers.get("content-range")).toBe("bytes */10");
  });
});

describe("GET /v1/media/{id}/poster", () => {
  it("serves a video's poster to members only, and says so when there is none", async () => {
    expect((await h.request(`/v1/media/${mediaId}/poster`)).status).toBe(401);
    expect((await h.request(`/v1/media/${mediaId}/poster`, { token: stranger.token })).status).toBe(
      404,
    );
    // Ten bytes aren't a video ffmpeg can read.
    const none = await h.request(`/v1/media/${mediaId}/poster`, { token: owner.token });
    expect(none.status).toBe(404);
    expect((await j(none)).code).toBe("poster_unavailable");
  });

  it.skipIf(!clip)("makes a JPEG once and keeps it", async () => {
    const orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Clips" },
        }),
      )
    ).id;
    const [row] = await h.tdb.admin<{ id: string }[]>`
      insert into public.chat_media (org_id, name, content_type, bytes, size, duration_s)
      values (${orgId}, 'clip.mp4', 'video/mp4', ${clip!}, ${clip!.length}, 2) returning id`;
    const res = await h.request(`/v1/media/${row!.id}/poster`, { token: owner.token });
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toBe("image/jpeg");
    expect(res.headers.get("cache-control")).toContain("immutable");
    const first = Buffer.from(await res.arrayBuffer());
    const again = Buffer.from(
      await (await h.request(`/v1/media/${row!.id}/poster`, { token: owner.token })).arrayBuffer(),
    );
    expect(again.equals(first)).toBe(true);
  });

  it("has none for pictures", async () => {
    const orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Pics" } }),
      )
    ).id;
    const [row] = await h.tdb.admin<{ id: string }[]>`
      insert into public.chat_media (org_id, name, content_type, bytes, size)
      values (${orgId}, 'a.png', 'image/png', ${BYTES}, ${BYTES.length}) returning id`;
    const res = await h.request(`/v1/media/${row!.id}/poster`, { token: owner.token });
    expect(res.status).toBe(404);
    expect((await j(res)).code).toBe("media_not_found");
  });
});

describe("GET /v1/computers/{id}/files/pdf-preview", () => {
  it("turns away files that have no PDF preview without waking a computer", async () => {
    const res = await h.request(
      `/v1/computers/${randomUUID()}/files/pdf-preview?path=${encodeURIComponent("notes.txt")}`,
      { token: owner.token },
    );
    expect(res.status).toBe(415);
    expect((await j(res)).code).toBe("preview_unsupported");
    expect(
      (await h.request(`/v1/computers/${randomUUID()}/files/pdf-preview?path=a.docx`)).status,
    ).toBe(401);
  });
});

describe("POST /v1/media (Casama for Chrome, D-323)", () => {
  const PNG = Buffer.from("89504e470d0a1a0a0000000d49484452", "hex");
  let orgId = "";
  beforeAll(async () => {
    orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Uploads" },
        }),
      )
    ).id;
  });
  const upload = (query: string, body: string | Uint8Array, type: string, token = owner.token) =>
    h.request(`/v1/media?org_id=${orgId}&${query}`, {
      method: "POST",
      token,
      headers: { "content-type": type },
      body,
    });

  it("keeps an attachment with the chat, out of the Library, and serves it to members", async () => {
    const res = await upload("name=shot.png", PNG, "image/png");
    expect(res.status).toBe(201);
    const m = await j(res);
    expect(m).toMatchObject({ path: `media:${m.id}`, mime_type: "image/png", size: PNG.length });
    expect(m.creation_id).toBeNull();
    const [row] = await h.tdb.admin<{ uploaded_by: string; in_library: boolean }[]>`
      select uploaded_by, in_library from public.chat_media where id = ${m.id}`;
    expect(row).toEqual({ uploaded_by: owner.id, in_library: false });
    const [c] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.creations where media_id = ${m.id}`;
    expect(c!.n).toBe(0);
    const got = await h.request(`/v1/media/${m.id}`, { token: owner.token });
    expect(Buffer.from(await got.arrayBuffer()).equals(PNG)).toBe(true);
  });

  it("saves to the Library for the person, in a project when asked", async () => {
    const [bot] = await h.tdb.admin<{ id: string }[]>`
      insert into public.bots (org_id, name, created_by) values (${orgId}, 'Reader', ${owner.id}) returning id`;
    const [project] = await h.tdb.admin<{ id: string }[]>`
      insert into public.projects (org_id, slug, title, goal_md, lead_bot_id, owner_user_id)
      values (${orgId}, 'reading', 'Reading', 'Read', ${bot!.id}, ${owner.id}) returning id`;
    const md = "# A page\n\nFrom https://example.com/a\n";
    const res = await upload(
      `name=A%20page.md&purpose=library&project_id=${project!.id}`,
      md,
      "text/markdown",
    );
    expect(res.status).toBe(201);
    const m = await j(res);
    expect(m.creation_id).toBeTruthy();
    const [c] = await h.tdb.admin<
      { made_for: string; kind: string; title: string; project_id: string }[]
    >`select made_for, kind, title, project_id from public.creations where id = ${m.creation_id}`;
    expect(c).toEqual({
      made_for: owner.id,
      kind: "document",
      title: "A page",
      project_id: project!.id,
    });
  });

  it("prints HTML as a PDF where the server can, and refuses raw HTML", async () => {
    expect((await upload("name=p.html", "<p>x</p>", "text/html")).status).toBe(400);
    const off = await upload("name=p.html&convert=pdf&purpose=library", "<p>x</p>", "text/html");
    expect(off.status).toBe(409);
    expect((await j(off)).code).toBe("pdf_unavailable");
    const seen: string[] = [];
    h.deps.pdf = {
      render: async (html) => {
        seen.push(html);
        return new Uint8Array(Buffer.from("%PDF-1.7 test"));
      },
    };
    try {
      const res = await upload(
        "name=Page.html&convert=pdf&purpose=library",
        '<meta http-equiv="refresh" content="0;url=file:///etc/passwd"><p>x</p><iframe src="file:///proc/self/environ"></iframe>',
        "text/html",
      );
      expect(res.status).toBe(201);
      expect(await j(res)).toMatchObject({ name: "Page.pdf", mime_type: "application/pdf" });
      // Printed under a policy that blocks files, the network, frames and scripts; no refresh.
      expect(seen).toHaveLength(1);
      expect(seen[0]).toMatch(
        /^<!doctype html><html><head><meta http-equiv="Content-Security-Policy" content="default-src 'none';/,
      );
      expect(seen[0]).not.toContain("refresh");
      expect(seen[0]).toContain("<p>x</p>");
    } finally {
      h.deps.pdf = null;
    }
  });

  it("counts attachments toward storage and refuses a body past the limit, length or not", async () => {
    const before = await h.tdb.admin<{ b: string }[]>`
      select storage_bytes::text as b from public.organizations where id = ${orgId}::uuid`;
    expect((await upload("name=s.png", PNG, "image/png")).status).toBe(201);
    const after = await h.tdb.admin<{ b: string }[]>`
      select storage_bytes::text as b from public.organizations where id = ${orgId}::uuid`;
    expect(Number(after[0]!.b) - Number(before[0]!.b)).toBe(PNG.length);
    const { readCapped } = await import("../src/api/routes/chat-media.ts");
    const stream = (n: number) =>
      new ReadableStream<Uint8Array>({
        pull(c) {
          if (n <= 0) return c.close();
          n -= 1;
          c.enqueue(new Uint8Array(10));
        },
      });
    await expect(readCapped(stream(3), 25, () => new Error("too big"))).rejects.toThrow("too big");
    expect((await readCapped(stream(2), 25, () => new Error("too big"))).length).toBe(20);
  });

  it("is only for members, and not empty", async () => {
    expect((await upload("name=a.png", PNG, "image/png", stranger.token)).status).toBe(404);
    expect(
      (await h.request(`/v1/media?org_id=${orgId}&name=a.png`, { method: "POST", body: PNG }))
        .status,
    ).toBe(401);
    expect((await upload("name=a.png", new Uint8Array(0), "image/png")).status).toBe(400);
    expect((await upload("name=a.png&project_id=nope", PNG, "image/png")).status).toBe(400);
  });
});
