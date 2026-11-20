import { readFileSync } from "node:fs";
import { afterEach, describe, expect, it } from "vitest";
import {
  botAvatar,
  mascotFromAvatar,
  pictureFromAvatar,
  setPictureServer,
} from "../src/lib/look.ts";

const { vectors } = JSON.parse(
  readFileSync(
    new URL("../../../packages/domain/test/fixtures/bot-avatar-vectors.json", import.meta.url),
    "utf8",
  ),
) as {
  vectors: {
    value: string | null;
    kind: string;
    mascot?: string;
    id?: string;
    colors?: string[];
  }[];
};

describe("bot avatar values", () => {
  afterEach(() => setPictureServer(null));

  it.each(vectors)("reads $value as $kind", (v) => {
    const picture = pictureFromAvatar(v.value);
    const mascot = mascotFromAvatar(v.value);
    const kind = picture ? "image" : mascot ? "mascot" : "initials";
    expect(kind).toBe(v.kind);
    if (picture) expect(picture).toEqual({ id: v.id, colors: v.colors });
    if (mascot) expect(mascot).toBe(v.mascot);
  });

  it("draws a picture from the signed-in server and never loads a web link", () => {
    // Just enough of the DOM for h(): tag names and attributes.
    (globalThis as { document?: unknown }).document = {
      createElement: (tag: string) => {
        const attrs = new Map<string, string>();
        return {
          tagName: tag.toUpperCase(),
          className: "",
          setAttribute: (k: string, v: string) => attrs.set(k, v),
          getAttribute: (k: string) => attrs.get(k) ?? null,
          append: () => {},
          addEventListener: () => {},
        };
      },
    };
    setPictureServer("https://api.example.test/");
    const pic = botAvatar(
      "Ada",
      "image:6f1c2e9a-3b4d-4c5e-8f70-1a2b3c4d5e6f:7a90ff7de9f4",
      36,
    ) as HTMLImageElement;
    expect(pic.tagName).toBe("IMG");
    expect(pic.getAttribute("src")).toBe(
      "https://api.example.test/v1/bot-images/6f1c2e9a-3b4d-4c5e-8f70-1a2b3c4d5e6f?size=128",
    );
    const link = botAvatar("Ada", "https://tracker.example/p.gif", 36);
    expect(link.tagName).toBe("SPAN");
  });
});
