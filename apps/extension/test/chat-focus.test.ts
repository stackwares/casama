import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { ChatFocus, FOCUS_REFRESH_MS, focusClientId } from "../src/lib/chat-focus.ts";
import { installFakeChrome } from "./fake-chrome.ts";

vi.mock("../src/lib/session.ts", () => ({
  accessToken: async () => "token",
  clientFor: () => ({}),
}));

const account = (id: string, userId: string) => ({
  id,
  server: "https://api.example.test",
  authUrl: "https://auth.example.test",
  anonKey: "anon",
  userId,
  email: `${userId}@example.test`,
  refreshToken: "r",
  addedAt: "2026-11-17T00:00:00Z",
});

function fakeDoc() {
  const listeners: (() => void)[] = [];
  return {
    visibilityState: "visible" as DocumentVisibilityState,
    addEventListener: (_: string, fn: () => void) => void listeners.push(fn),
    fire() {
      for (const fn of listeners) fn();
    },
  };
}

let sent: { user_id: string; client_id: string; conversation_id: string | null }[];

beforeEach(() => {
  installFakeChrome();
  vi.useFakeTimers();
  sent = [];
  vi.stubGlobal(
    "fetch",
    vi.fn(async (url: string, init: RequestInit) => {
      expect(url).toBe(
        "https://auth.example.test/rest/v1/chat_focus?on_conflict=user_id,client_id",
      );
      sent.push(JSON.parse(String(init.body)));
      return new Response(null, { status: 201 });
    }),
  );
});

afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

const settle = () => vi.advanceTimersByTimeAsync(0);

describe("the chat on screen (D-325)", () => {
  it("keeps one client id per browser profile", async () => {
    const id = await focusClientId();
    expect(id).toMatch(/^chrome-/);
    expect(await focusClientId()).toBe(id);
  });

  it("reports the open chat, refreshes it, and clears it when hidden or left", async () => {
    const doc = fakeDoc();
    const focus = new ChatFocus(doc);
    const a = account("a", "user-a");
    focus.set(a, null);
    await settle();
    expect(sent).toEqual([]); // nothing to clear on a fresh start
    focus.set(a, "conv-1");
    await settle();
    expect(sent.map((s) => s.conversation_id)).toEqual(["conv-1"]);
    expect(sent[0]!.user_id).toBe("user-a");
    await vi.advanceTimersByTimeAsync(FOCUS_REFRESH_MS);
    expect(sent.map((s) => s.conversation_id)).toEqual(["conv-1", "conv-1"]);
    doc.visibilityState = "hidden";
    doc.fire();
    await settle();
    expect(sent.at(-1)!.conversation_id).toBeNull();
    await vi.advanceTimersByTimeAsync(FOCUS_REFRESH_MS * 2);
    expect(sent).toHaveLength(3); // no refresh while hidden
    doc.visibilityState = "visible";
    doc.fire();
    await settle();
    expect(sent.at(-1)!.conversation_id).toBe("conv-1");
    focus.set(a, null);
    await settle();
    expect(sent.at(-1)!.conversation_id).toBeNull();
  });

  it("clears the old account's focus when another account takes the panel", async () => {
    const focus = new ChatFocus(fakeDoc());
    focus.set(account("a", "user-a"), "conv-1");
    await settle();
    focus.set(account("b", "user-b"), "conv-2");
    await settle();
    expect(sent.map((s) => [s.user_id, s.conversation_id])).toEqual([
      ["user-a", "conv-1"],
      ["user-a", null],
      ["user-b", "conv-2"],
    ]);
  });
});
