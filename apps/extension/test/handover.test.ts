import { beforeEach, describe, expect, it } from "vitest";
import { allowedServersFor, handleHandover } from "../src/background/handover.ts";
import { giveConsent } from "../src/lib/consent.ts";
import { setFetch } from "../src/lib/session.ts";
import { getLocal, getSession } from "../src/lib/store.ts";
import { fakeBackend, installFakeChrome } from "./fake-chrome.ts";

let be: ReturnType<typeof fakeBackend>;
let opened: string[];

beforeEach(() => {
  opened = installFakeChrome().opened;
  be = fakeBackend({ server: "http://localhost:8797" });
  setFetch(be.fetch);
});

const open = async () => void opened.push("first-run");
const link = () =>
  `https://casama.ai/pair#v=1&s=${encodeURIComponent(be.server)}&c=${be.state.validCode}`;

describe("which pages may sign the extension in", () => {
  it("lets Casama Cloud's web app sign in to Casama Cloud only", () => {
    expect(allowedServersFor("https://app.casama.ai", "store")).toEqual(["https://api.casama.ai"]);
    expect(allowedServersFor("https://app-dev.casama.ai", "store")).toBeNull();
    expect(allowedServersFor("http://localhost:8098", "store")).toBeNull();
    expect(allowedServersFor("https://evil.example", "dev")).toBeNull();
    expect(allowedServersFor(undefined, "dev")).toBeNull();
  });

  it("lets local web apps sign the dev build in anywhere", () => {
    expect(allowedServersFor("http://localhost:8098", "dev")).toBeUndefined();
    expect(allowedServersFor("https://app-dev.casama.ai", "dev")).toEqual([
      "https://api-dev.casama.ai",
    ]);
  });
});

describe("handover", () => {
  it("answers a ping with its version", async () => {
    expect(
      await handleHandover({ type: "casama.ping" }, "https://app.casama.ai", "store", open),
    ).toEqual({
      ok: true,
      version: "0.1.0",
    });
  });

  it("refuses pages it doesn't know and messages it doesn't understand", async () => {
    expect(
      await handleHandover({ type: "casama.ping" }, "https://evil.example", "store", open),
    ).toMatchObject({ ok: false });
    expect(
      await handleHandover({ type: "x" }, "https://app.casama.ai", "store", open),
    ).toMatchObject({ ok: false });
    expect(
      await handleHandover(
        { type: "casama.signIn", link: 5 },
        "https://app.casama.ai",
        "store",
        open,
      ),
    ).toMatchObject({
      ok: false,
    });
  });

  it("shows the first-run screen before signing in someone who hasn't agreed", async () => {
    const reply = await handleHandover(
      { type: "casama.signIn", link: link() },
      "http://localhost:8098",
      "dev",
      open,
    );
    expect(reply).toEqual({ ok: true, pending: true });
    expect(opened).toEqual(["first-run"]);
    expect((await getSession()).pendingHandover?.link).toBe(link());
    expect((await getLocal()).accounts).toEqual([]);
    expect(be.calls.filter((c) => c.url.includes("/redeem"))).toHaveLength(0);
  });

  it("follows the server's kill switch", async () => {
    await giveConsent();
    const f = be.fetch;
    setFetch(async (input, init) => {
      const url = new URL(input instanceof Request ? input.url : String(input));
      if (url.pathname === "/v1/app-config")
        return new Response(
          JSON.stringify({
            min_versions: {},
            update_urls: {},
            maintenance: null,
            announcements: [],
            flags: { chrome_extension: false },
          }),
          { headers: { "content-type": "application/json" } },
        );
      return f(input, init);
    });
    const reply = await handleHandover(
      { type: "casama.signIn", link: link() },
      "http://localhost:8098",
      "dev",
      open,
    );
    expect(reply).toEqual({ ok: false, error: "Casama for Chrome is turned off for now." });
    expect((await getLocal()).accounts).toEqual([]);
  });

  it("signs in once the person has agreed", async () => {
    await giveConsent();
    const reply = await handleHandover(
      { type: "casama.signIn", link: link() },
      "http://localhost:8098",
      "dev",
      open,
    );
    expect(reply).toEqual({ ok: true, email: "ada@example.test" });
    expect((await getLocal()).accounts).toHaveLength(1);
  });

  it("checks the server before waiting for the agreement", async () => {
    const reply = await handleHandover(
      { type: "casama.signIn", link: link() },
      "https://app.casama.ai",
      "store",
      open,
    );
    expect(reply).toMatchObject({ ok: false });
    expect(opened).toEqual([]);
    expect((await getSession()).pendingHandover).toBeNull();
  });

  it("keeps the page's allowed servers with a waiting sign-in", async () => {
    const cloud = `https://casama.ai/pair#v=1&s=${encodeURIComponent("https://api.casama.ai")}&c=${be.state.validCode}`;
    await handleHandover(
      { type: "casama.signIn", link: cloud },
      "https://app.casama.ai",
      "store",
      open,
    );
    expect((await getSession()).pendingHandover).toMatchObject({
      allowedServers: ["https://api.casama.ai"],
    });
  });

  it("won't let Casama Cloud's web app sign in to another server", async () => {
    await giveConsent();
    const reply = await handleHandover(
      { type: "casama.signIn", link: link() },
      "https://app.casama.ai",
      "store",
      open,
    );
    expect(reply).toMatchObject({ ok: false });
    expect(be.calls).toHaveLength(0);
  });
});
