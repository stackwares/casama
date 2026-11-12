/** Chat media (D-205): generated images and videos served to workspace members, with byte ranges. */
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { parseRange } from "../src/api/routes/chat-media.ts";
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
