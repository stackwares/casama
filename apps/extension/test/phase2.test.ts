/** Phase 2's pure pieces: send less (F2), page keys (A20), live call messages (A12), site helpers (A17). */
import { describe, expect, it } from "vitest";
import { helperFor, SITE_HELPERS } from "../src/content/helpers.ts";
import { HELPERS } from "../src/content/protocol.ts";
import { privateHost } from "../src/lib/hosts.ts";
import { floatToPcm16, LiveEvents, pcm16ToFloat, toBase64 } from "../src/lib/live.ts";
import { pageKey } from "../src/lib/page-index.ts";
import { sendLess, TRIM_FROM } from "../src/lib/trim.ts";

describe("sendLess", () => {
  const filler = (n: number) =>
    Array.from(
      { length: n },
      (_, i) => `Paragraph ${i} talks about gardening, soil and weather patterns in general.`,
    ).join("\n\n");

  it("leaves short pages alone", () => {
    const r = sendLess("A short page.", "anything");
    expect(r).toEqual({ text: "A short page.", from: 13, trimmed: false });
  });

  it("keeps the opening and the paragraphs that match the question, in page order", () => {
    const page = `Intro: a guide to kettles.\n\n${filler(150)}\n\nThe descaling procedure uses vinegar and takes twenty minutes.\n\n${filler(150)}`;
    expect(page.length).toBeGreaterThan(TRIM_FROM);
    const r = sendLess(page, "How do I descale it with vinegar?");
    expect(r.trimmed).toBe(true);
    expect(r.text.length).toBeLessThanOrEqual(8_000);
    expect(r.text.startsWith("Intro: a guide to kettles.")).toBe(true);
    expect(r.text).toContain("descaling procedure uses vinegar");
    expect(r.text).toContain("[…]");
  });
});

describe("pageKey", () => {
  it("matches the server's rule", () => {
    expect(pageKey("https://Example.com/a/?utm_source=x&id=3&fbclid=y#top")).toBe(
      "https://example.com/a?id=3",
    );
    expect(pageKey("https://example.com/")).toBe("https://example.com");
    expect(pageKey("https://news.example/story/?utm_source=chrome")).toBe(
      "https://news.example/story",
    );
    expect(pageKey("not a url")).toBe("not a url");
  });
});

describe("LiveEvents", () => {
  it("reads setup, audio, transcripts, tool calls and usage", () => {
    const ev = new LiveEvents();
    expect(ev.handle(JSON.stringify({ setupComplete: {} })).setup).toBe(true);
    expect(ev.handle(JSON.stringify({ setupComplete: {} })).setup).toBe(false);
    ev.handle(JSON.stringify({ serverContent: { inputTranscription: { text: "What's on " } } }));
    ev.handle(JSON.stringify({ serverContent: { inputTranscription: { text: "this page?" } } }));
    const a = ev.handle(
      JSON.stringify({
        serverContent: {
          modelTurn: { parts: [{ inlineData: { data: "AAAA" } }] },
          outputTranscription: { text: "A kettle." },
        },
      }),
    );
    expect(a.audio).toEqual(["AAAA"]);
    ev.handle(
      JSON.stringify({
        serverContent: { turnComplete: true },
        usageMetadata: {
          promptTokensDetails: [{ modality: "AUDIO", tokenCount: 10 }],
          responseTokensDetails: [
            { modality: "AUDIO", tokenCount: 20 },
            { modality: "TEXT", tokenCount: 3 },
          ],
        },
      }),
    );
    expect(ev.turns).toEqual([
      { role: "user", text: "What's on this page?" },
      { role: "assistant", text: "A kettle." },
    ]);
    expect(ev.usage).toEqual({
      input_audio_tokens: 10,
      input_text_tokens: 0,
      output_audio_tokens: 20,
      output_text_tokens: 3,
    });
    const t = ev.handle(
      JSON.stringify({
        toolCall: { functionCalls: [{ id: "c1", name: "web_search", args: { q: "kettle" } }] },
      }),
    );
    expect(t.tools).toEqual([{ id: "c1", name: "web_search", args: { q: "kettle" } }]);
    expect(ev.toolResponse("c1", "done")).toEqual({
      toolResponse: {
        functionResponses: [{ id: "c1", name: "web_search", response: { result: "done" } }],
      },
    });
    expect(ev.handle("not json")).toEqual({
      audio: [],
      tools: [],
      interrupted: false,
      setup: false,
    });
  });

  it("converts audio both ways", () => {
    const back = pcm16ToFloat(toBase64(floatToPcm16(new Float32Array([0, 0.5, -0.5, 1, -1]))));
    expect([...back].map((v) => Math.round(v * 100) / 100)).toEqual([0, 0.5, -0.5, 1, -1]);
  });
});

describe("site helpers", () => {
  const doc = (present: string[], ld = false) =>
    ({
      querySelector: (sel: string) =>
        sel.split(",").some((s) => present.includes(s.trim())) ? {} : null,
      querySelectorAll: () => (ld ? [{ textContent: '{"@type": "Product"}' }] : []),
    }) as unknown as Document;

  it("has one helper per switch", () => {
    expect(SITE_HELPERS.map((h) => h.name).sort()).toEqual([...HELPERS].sort());
  });

  it("matches pages by address, and the anchor decides whether it shows", () => {
    const on = [...HELPERS];
    const yt = new URL("https://www.youtube.com/watch?v=x");
    expect(helperFor(yt, doc([]), on)?.name).toBe("youtube");
    expect(helperFor(yt, doc([]), on)?.anchor(doc([]))).toBeNull();
    expect(
      helperFor(yt, doc(["#above-the-fold #title"]), on)?.anchor(doc(["#above-the-fold #title"])),
    ).not.toBeNull();
    expect(helperFor(new URL("https://mail.google.com/mail/u/0/#inbox/1"), doc([]), on)?.name).toBe(
      "gmail",
    );
    expect(
      helperFor(new URL("https://github.com/a/b/pull/3"), doc([]), on)?.actions(
        new URL("https://github.com/a/b/pull/3"),
      ),
    ).toHaveLength(2);
    expect(
      helperFor(new URL("https://github.com/a/b/issues/3"), doc([]), on)?.actions(
        new URL("https://github.com/a/b/issues/3"),
      ),
    ).toHaveLength(1);
    expect(helperFor(new URL("https://www.google.com/search?q=kettles"), doc([]), on)?.name).toBe(
      "search",
    );
    expect(helperFor(new URL("https://x.com/a/status/123"), doc([]), on)?.name).toBe("threads");
    expect(helperFor(new URL("https://shop.example/kettle"), doc([], true), on)?.name).toBe(
      "shopping",
    );
    expect(helperFor(new URL("https://shop.example/kettle"), doc([]), on)).toBeNull();
    // Switched off: no helper.
    expect(
      helperFor(
        yt,
        doc([]),
        on.filter((n) => n !== "youtube"),
      ),
    ).toBeNull();
  });
});

describe("privateHost (send a link's file)", () => {
  it("refuses this computer and its network, allows the public web", () => {
    for (const u of [
      "http://localhost:3000/a.pdf",
      "http://127.0.0.1/x",
      "http://10.0.0.5/x",
      "http://192.168.1.2/x",
      "http://172.20.0.1/x",
      "http://169.254.169.254/latest",
      "http://printer.local/scan.pdf",
      "http://[::1]/x",
      "http://[fd00::1]/x",
      "not a url",
    ])
      expect(privateHost(u), u).toBe(true);
    for (const u of ["https://example.com/a.pdf", "https://172.32.0.1/x", "https://fdroid.org/x"])
      expect(privateHost(u), u).toBe(false);
  });
});
