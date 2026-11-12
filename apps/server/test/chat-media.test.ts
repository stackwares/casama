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
