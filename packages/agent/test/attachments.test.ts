import { describe, expect, it } from "vitest";
import { toModelMessages } from "../src/gateway/ai-sdk.ts";
import { capabilitiesOf } from "../src/gateway/registry.ts";
import { partsFiles, partsText } from "../src/run.ts";

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
    expect(text).toBe("Here you go.\n\n(You showed the person a generated image/png: image.png.)");
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
