import { describe, expect, it, vi } from "vitest";
import { isMeetCall, transcript } from "../src/lib/captions.ts";
import { flatten, toMarkdown } from "../src/lib/device/bookmarks.ts";
import {
  addMinute,
  finishedHours,
  historyItems,
  hourKey,
  tabSummary,
  wanted,
} from "../src/lib/device/pure.ts";
import { Realtime, realtimeUrl } from "../src/lib/device/realtime.ts";
import { carriesPage, privateVerdict } from "../src/lib/private-model.ts";
import { clock, recordingName } from "../src/lib/record.ts";
import type { Chips } from "../src/lib/settings.ts";

describe("the browser as a device (E2–E6)", () => {
  it("sends a tab capped like the server's strict schema", () => {
    const s = tabSummary({
      url: `https://example.com/${"a".repeat(3000)}`,
      title: "T".repeat(400),
      selection: "s".repeat(6000),
      text: "x".repeat(30000),
    });
    expect(s.type).toBe("tab");
    expect(s.url.length).toBe(2000);
    expect(s.title.length).toBe(300);
    expect(s.selection?.length).toBe(5000);
    expect(s.text?.length).toBe(20000);
    expect(tabSummary({ url: "https://a.example/", title: "A" })).toEqual({
      type: "tab",
      url: "https://a.example/",
      title: "A",
    });
  });

  it("finds history and bookmarks newest first, once each, without guarded pages", () => {
    const items = historyItems(
      [
        { url: "https://news.example/a", title: "Article A", lastVisitTime: 3000 },
        { url: "https://bank.example/login", title: "Bank", lastVisitTime: 5000 },
        { url: "chrome://settings", title: "Settings", lastVisitTime: 6000 },
        { url: "https://news.example/b", title: "", lastVisitTime: 1000 },
      ],
      [{ url: "https://news.example/a", title: "Article A (saved)", dateAdded: 4000 }],
      (u) => u.includes("bank."),
    );
    expect(items.map((i) => [i.url, i.source])).toEqual([
      ["https://news.example/a", "bookmark"],
      ["https://news.example/b", "history"],
    ]);
    expect(items[1]?.title).toBe("https://news.example/b");
    expect(items[0]?.visited_at).toBe(new Date(4000).toISOString());
    const many = Array.from({ length: 80 }, (_, i) => ({
      url: `https://x.example/${i}`,
      lastVisitTime: i,
    }));
    expect(historyItems(many, [], () => false)).toHaveLength(50);
  });

  it("counts minutes per site per hour and sends only finished hours, names only", () => {
    let b = {};
    for (let i = 0; i < 70; i++) b = addMinute(b, "2026-11-17T09", "docs.example");
    b = addMinute(b, "2026-11-17T09", "news.example");
    b = addMinute(b, "2026-11-17T10", "docs.example");
    const hours = finishedHours(b, "2026-11-17T10");
    expect(hours).toEqual([
      {
        type: "hour",
        hour: "2026-11-17T09",
        total_minutes: 60,
        apps: [
          { app: "docs.example", minutes: 60 },
          { app: "news.example", minutes: 1 },
        ],
      },
    ]);
    expect(hourKey(new Date("2026-11-17T09:41:00Z"))).toBe("2026-11-17T09");
  });

  it("sends an event only when one of the person's routines starts on it", () => {
    const triggers = [
      { event: "site_opened" as const, site: "wiki.example.com" },
      { event: "download_done" as const, pattern: "*.pdf" },
    ];
    expect(wanted(triggers, { event: "site_opened", host: "wiki.example.com" })).toBe(true);
    expect(wanted(triggers, { event: "site_opened", host: "team.wiki.example.com" })).toBe(true);
    expect(wanted(triggers, { event: "site_opened", host: "news.example" })).toBe(false);
    expect(wanted(triggers, { event: "download_done", name: "Invoice.PDF" })).toBe(true);
    expect(wanted(triggers, { event: "download_done", name: "photo.jpg" })).toBe(false);
    expect(wanted(triggers, { event: "bookmark_added" })).toBe(false);
    expect(wanted([], { event: "site_opened", host: "wiki.example.com" })).toBe(false);
  });
});

describe("Realtime: device requests the moment they're made", () => {
  class FakeSocket {
    static last: FakeSocket;
    readyState = 0;
    sent: Array<{ topic: string; event: string; payload: Record<string, unknown> }> = [];
    onopen?: () => void;
    onmessage?: (e: { data: string }) => void;
    onclose?: () => void;
    onerror?: () => void;
    readonly url: string;
    constructor(url: string) {
      this.url = url;
      FakeSocket.last = this;
    }
    send(s: string) {
      this.sent.push(JSON.parse(s));
    }
    close() {
      this.readyState = 3;
      this.onclose?.();
    }
    open() {
      this.readyState = 1;
      this.onopen?.();
    }
    receive(m: unknown) {
      this.onmessage?.({ data: JSON.stringify(m) });
    }
  }

  it("builds the socket address from the auth server", () => {
    expect(realtimeUrl("https://auth.casama.ai", "anon")).toBe(
      "wss://auth.casama.ai/realtime/v1/websocket?apikey=anon&vsn=1.0.0",
    );
    expect(realtimeUrl("http://127.0.0.1:54321/", "k")).toBe(
      "ws://127.0.0.1:54321/realtime/v1/websocket?apikey=k&vsn=1.0.0",
    );
  });

  it("joins the private topic, passes broadcasts on, refreshes the token and reconnects", async () => {
    vi.useFakeTimers();
    let token = "t1";
    const got: Array<[string, Record<string, unknown>]> = [];
    const status: boolean[] = [];
    const rt = new Realtime({
      authUrl: "https://auth.example",
      anonKey: "anon",
      topic: "user:u1",
      token: async () => token,
      onBroadcast: (e, p) => got.push([e, p]),
      onStatus: (j) => status.push(j),
      WebSocketImpl: FakeSocket as unknown as typeof WebSocket,
      heartbeatMs: 1000,
    });
    await rt.start();
    const ws = FakeSocket.last;
    ws.open();
    expect(ws.sent[0]).toMatchObject({
      topic: "realtime:user:u1",
      event: "phx_join",
      payload: { access_token: "t1", config: { private: true } },
    });
    ws.receive({ topic: "realtime:user:u1", event: "phx_reply", payload: { status: "ok" } });
    expect(rt.joined).toBe(true);
    ws.receive({
      topic: "realtime:user:u1",
      event: "broadcast",
      payload: { event: "device_request", payload: { id: "r1", source_id: "s1" } },
    });
    ws.receive({
      topic: "realtime:user:other",
      event: "broadcast",
      payload: { event: "device_request", payload: { id: "r2" } },
    });
    expect(got).toEqual([["device_request", { id: "r1", source_id: "s1" }]]);
    token = "t2";
    await vi.advanceTimersByTimeAsync(1000);
    expect(ws.sent.some((m) => m.event === "heartbeat" && m.topic === "phoenix")).toBe(true);
    expect(ws.sent.find((m) => m.event === "access_token")?.payload).toEqual({
      access_token: "t2",
    });
    ws.close();
    expect(status).toEqual([true, false]);
    await vi.advanceTimersByTimeAsync(1000);
    expect(FakeSocket.last).not.toBe(ws);
    rt.stop();
    vi.useRealTimers();
  });
});

describe("bookmarks into knowledge (B11)", () => {
  it("flattens folders and writes one Markdown list", () => {
    const items = flatten([
      {
        id: "0",
        title: "",
        children: [
          {
            id: "1",
            title: "Bookmarks bar",
            children: [
              { id: "2", title: "Docs [v2]", url: "https://docs.example/" },
              {
                id: "3",
                title: "Work",
                children: [{ id: "4", title: "", url: "https://wiki.example/" }],
              },
            ],
          },
        ],
      },
    ] as chrome.bookmarks.BookmarkTreeNode[]);
    expect(items).toEqual([
      { title: "Docs [v2]", url: "https://docs.example/", folder: "Bookmarks bar" },
      {
        title: "https://wiki.example/",
        url: "https://wiki.example/",
        folder: "Bookmarks bar / Work",
      },
    ]);
    const md = toMarkdown(items, [{ title: "Later", url: "https://read.example/" }]);
    expect(md.count).toBe(3);
    expect(md.text).toContain("## Bookmarks bar / Work");
    expect(md.text).toContain("- [Docs v2](https://docs.example/)");
    expect(md.text).toContain("## Reading list\n\n- [Later](https://read.example/)");
  });
});

describe("the private model rule (F3)", () => {
  const off: Chips = { page: false, selection: false, text: false, screenshot: false };
  it("knows when a message carries the page", () => {
    expect(carriesPage(off, { url: "https://a.example/" }, 0)).toBe(false);
    expect(carriesPage({ ...off, page: true }, { url: "https://a.example/" }, 0)).toBe(true);
    expect(carriesPage({ ...off, text: true }, { url: "https://a.example/" }, 0)).toBe(false);
    expect(carriesPage({ ...off, text: true }, { url: "https://a.example/", text: "Hi" }, 0)).toBe(
      true,
    );
    expect(carriesPage({ ...off, screenshot: true }, { url: "https://a.example/" }, 0)).toBe(true);
    expect(carriesPage(off, { url: "https://a.example/" }, 1)).toBe(true);
    // A blocked page sends nothing of its own.
    expect(
      carriesPage({ ...off, page: true }, { url: "https://bank.example/", blocked: "Banking" }, 0),
    ).toBe(false);
  });
  it("sends to private bots, answers here when it can, else refuses", () => {
    const base = { rule: true, carries: true, botPrivate: false, localModel: true };
    expect(privateVerdict({ ...base, rule: false })).toBe("send");
    expect(privateVerdict({ ...base, carries: false })).toBe("send");
    expect(privateVerdict({ ...base, botPrivate: true })).toBe("send");
    expect(privateVerdict(base)).toBe("local");
    expect(privateVerdict({ ...base, localModel: false })).toBe("refuse");
  });
});

describe("meeting captions (E7) and recordings (B12)", () => {
  it("recognizes a Meet call", () => {
    expect(isMeetCall("https://meet.google.com/abc-defg-hij")).toBe(true);
    expect(isMeetCall("https://meet.google.com/abc-defg-hij?authuser=0")).toBe(true);
    expect(isMeetCall("https://meet.google.com/")).toBe(false);
    expect(isMeetCall("https://meet.google.com.evil.example/abc-defg-hij")).toBe(false);
    expect(isMeetCall(undefined)).toBe(false);
  });
  it("runs a speaker's lines together, with when they began", () => {
    const at = new Date(2026, 10, 17, 9, 5).getTime();
    expect(
      transcript(
        [
          { speaker: "Ana", text: "Morning.", at },
          { speaker: "Ana", text: "Shall we start?", at: at + 1000 },
          { speaker: "Ben", text: "Yes.", at: at + 60_000 },
          { speaker: "", text: "  ", at: at + 61_000 },
        ],
        "Weekly sync",
      ),
    ).toBe("Meeting: Weekly sync\n\n[09:05] Ana: Morning. Shall we start?\n[09:06] Ben: Yes.");
  });
  it("names recordings and shows the time", () => {
    expect(recordingName(new Date(2026, 10, 17, 9, 5))).toBe("Tab recording 2026-11-17 09.05.webm");
    expect(clock(0)).toBe("0:00");
    expect(clock(75.6)).toBe("1:15");
  });
});
