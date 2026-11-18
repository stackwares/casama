import { afterEach, beforeEach, describe, expect, it } from "vitest";
import {
  capture,
  enqueue,
  flushQueue,
  fromBase64,
  QUEUE_MAX,
  queued,
  toBase64,
} from "../src/lib/capture.ts";
import { setFetch, signInWithLink } from "../src/lib/session.ts";
import type { Account } from "../src/lib/store.ts";
import { fakeBackend, installFakeChrome } from "./fake-chrome.ts";

let be: ReturnType<typeof fakeBackend>;
let account: Account;
const realFetch = globalThis.fetch;

beforeEach(async () => {
  installFakeChrome();
  be = fakeBackend();
  setFetch(be.fetch);
  globalThis.fetch = be.fetch;
  account = await signInWithLink(
    `https://casama.ai/pair#v=1&s=${encodeURIComponent(be.server)}&c=${be.state.validCode}`,
  );
});
afterEach(() => {
  globalThis.fetch = realFetch;
});

const page = () => ({
  kind: "library" as const,
  orgId: "org-1",
  name: "A page.md",
  data: toBase64(new TextEncoder().encode("# A page")),
  type: "text/markdown",
  projectId: "p-1",
});

describe("captures (B1–B5)", () => {
  it("saves a page to the Library, in a project", async () => {
    const r = await capture(account, page());
    expect(r).toMatchObject({ state: "sent", id: expect.stringMatching(/^c-/) });
    expect(be.state.uploads).toEqual([
      {
        query: { org_id: "org-1", name: "A page.md", purpose: "library", project_id: "p-1" },
        type: "text/markdown",
        size: 8,
      },
    ]);
  });

  it("remembers a fact in About you", async () => {
    await capture(account, { kind: "fact", text: "I prefer tea" });
    expect(be.state.facts).toEqual([{ kind: "fact", content: "I prefer tea" }]);
  });

  it("keeps captures made offline and sends them when back", async () => {
    be.state.unreachable.add(new URL(be.server).origin);
    expect(await capture(account, page())).toEqual({ state: "queued" });
    expect(await capture(account, { kind: "fact", text: "x" })).toEqual({ state: "queued" });
    expect(await queued()).toHaveLength(2);
    // Not due yet, and still offline when due.
    expect(await flushQueue()).toEqual({ sent: 0, left: 2 });
    expect(await flushQueue(Date.now() + 60_000)).toEqual({ sent: 0, left: 2 });
    expect((await queued())[0]!.tries).toBe(1);
    be.state.unreachable.clear();
    expect(await flushQueue(Date.now() + 10 * 60_000)).toEqual({ sent: 2, left: 0 });
    expect(be.state.uploads).toHaveLength(1);
    expect(be.state.facts).toHaveLength(1);
  });

  it("drops what belongs to an account that signed out, and won't fill the disk", async () => {
    await enqueue("someone-else", { kind: "fact", text: "x" });
    expect(await flushQueue(Date.now() + 60_000)).toEqual({ sent: 0, left: 0 });
    for (let i = 0; i < QUEUE_MAX; i++)
      await enqueue(account.id, { kind: "fact", text: String(i) });
    await expect(enqueue(account.id, { kind: "fact", text: "one more" })).rejects.toThrow(
      /Too many/,
    );
  });

  it("shows a refusal instead of queueing it", async () => {
    be.state.uploadStatus = 409;
    await expect(capture(account, page())).rejects.toThrow(/Library is full/);
    expect(await queued()).toHaveLength(0);
    expect(fromBase64(toBase64(new Uint8Array([0, 255, 7])))).toEqual(new Uint8Array([0, 255, 7]));
  });
});
