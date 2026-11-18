import type { Database } from "@casama/db";
import type { SQL } from "drizzle-orm";
import { PgDialect } from "drizzle-orm/pg-core";
import { describe, expect, it } from "vitest";
import type { ComputerService } from "../src/computers.ts";
import { toModelMessages } from "../src/gateway/ai-sdk.ts";
import { capabilitiesOf } from "../src/gateway/registry.ts";
import { loadImages, partsFiles, partsText } from "../src/run.ts";

describe("attachments", () => {
  const content = [
    { type: "text", text: "What is in this photo?" },
    {
      type: "file",
      path: "workspace/uploads/20261110-cat.jpg",
      name: "cat.jpg",
      mime_type: "image/jpeg",
      size: 204_800,
    },
    {
      type: "file",
      path: "workspace/uploads/20261110-notes.pdf",
      name: "notes.pdf",
      mime_type: "application/pdf",
      size: 3_145_728,
    },
  ];

  it("lists attached files in the message text so any model knows where they are", () => {
    const text = partsText(content);
    expect(text).toContain("What is in this photo?");
    expect(text).toContain("- workspace/uploads/20261110-cat.jpg (image/jpeg, 200 KB)");
    expect(text).toContain("- workspace/uploads/20261110-notes.pdf (application/pdf, 3.0 MB)");
    expect(partsFiles(content).map((f) => f.name)).toEqual(["cat.jpg", "notes.pdf"]);
    expect(partsText([{ type: "text", text: "plain" }])).toBe("plain");
  });

  it("notes generated media the bot showed instead of listing it as a computer file (D-205)", () => {
    const text = partsText([
      { type: "text", text: "Here you go." },
      { type: "file", path: "media:0b6f", name: "image.png", mime_type: "image/png", size: 10 },
    ]);
    expect(text).toBe(
      "Here you go.\n\n[Casama note, not part of your reply: under this message you showed the person image.png (image/png), media:0b6f. To change it, pass media:0b6f to a tool that takes a file, or files.from_chat to copy it onto your computer.]",
    );
    expect(text).not.toContain("Attached files");
  });

  it("sends images to vision models as image parts", () => {
    const data = new Uint8Array([1, 2, 3]);
    const [m] = toModelMessages([
      { role: "user", content: "look", images: [{ data, mediaType: "image/png" }] },
    ]);
    expect(m).toEqual({
      role: "user",
      content: [
        { type: "text", text: "look" },
        { type: "image", image: data, mediaType: "image/png" },
      ],
    });
    expect(toModelMessages([{ role: "user", content: "hi" }])[0]).toEqual({
      role: "user",
      content: "hi",
    });
  });

  it("knows GPT-6 models take images", () => {
    expect(capabilitiesOf("openai/gpt-6-luna").vision).toBe(true);
    expect(capabilitiesOf("openai/gpt-6-luna").contextWindow).toBe(1_050_000);
  });
});

describe("pictures a person sends from the browser (D-323)", () => {
  const ORG = "00000000-0000-4000-8000-000000000001";
  const MINE = "11111111-1111-4111-8111-111111111111";
  const THEIRS = "22222222-2222-4222-8222-222222222222";
  const PNG = new Uint8Array([0x89, 0x50, 0x4e, 0x47]);
  const dialect = new PgDialect();
  /** A database with one picture in ORG and one in another workspace. */
  const db = {
    execute: async (q: SQL) => {
      const { sql: text, params } = dialect.sqlToQuery(q);
      const id = params[0];
      const rows: Record<string, { org: string }> = {
        [MINE]: { org: ORG },
        [THEIRS]: { org: "another" },
      };
      const row = rows[id as string];
      if (text.includes("select content_type"))
        return row && row.org === params[1] ? [{ content_type: "image/png" }] : [];
      if (text.includes("select blob_key"))
        return row ? [{ blob_key: null, size: PNG.length }] : [];
      if (text.includes("select bytes")) return row ? [{ bytes: Buffer.from(PNG) }] : [];
      throw new Error(`unexpected query: ${text}`);
    },
  } as unknown as Database;
  const file = (id: string) => ({
    path: `media:${id}`,
    name: "shot.png",
    mime_type: "image/png",
    size: PNG.length,
    uploaded: true,
  });

  it("reads them from the chat's store without a computer, only from this workspace", async () => {
    const computers = {
      forBot: () => {
        throw new Error("no computer should start");
      },
    } as unknown as ComputerService;
    const images = await loadImages({ db, computers }, { orgId: ORG, botId: "b" }, [
      file(MINE),
      file(THEIRS),
    ]);
    expect(images).toEqual([{ data: PNG, mediaType: "image/png" }]);
  });

  it("tells the model where the file is", () => {
    const text = partsText([
      { type: "text", text: "What's this?" },
      { type: "file", ...file(MINE) },
    ]);
    expect(text).toContain(`Sent with this message: shot.png (image/png, 1 KB), media:${MINE}`);
    expect(text).toContain("files.from_chat");
    expect(text).not.toContain("generated");
    expect(text).not.toContain("Attached files");
  });
});
