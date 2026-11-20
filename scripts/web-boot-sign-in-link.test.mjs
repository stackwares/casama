// The web app's boot script takes an address out of a sign-in link before the app starts, so the
// address is never in the page URL that analytics record (client/web/boot.js).
// Run: node --test scripts/web-boot-sign-in-link.test.mjs
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import vm from "node:vm";

const source = readFileSync(new URL("../client/web/boot.js", import.meta.url), "utf8");

/** Runs boot.js against a page at `hash` and returns where it ended up and what it stored. */
function boot(hash, { storage = true } = {}) {
  const location = { pathname: "/", search: "", hash, href: `https://app.casama.ai/${hash}` };
  const stored = new Map();
  const window = {
    location,
    sessionStorage: {
      setItem(k, v) {
        if (!storage) throw new Error("storage is off");
        stored.set(k, v);
      },
    },
  };
  const history = {
    replaceState(_s, _t, url) {
      const at = url.indexOf("#");
      location.hash = at < 0 ? "" : url.slice(at);
    },
  };
  const document = { baseURI: "https://app.casama.ai/" };
  try {
    vm.runInNewContext(source, { window, history, document, URL, URLSearchParams });
  } catch {
    // The rest of the loading screen needs a real page; the link is handled before it.
  }
  return { hash: location.hash, stored: Object.fromEntries(stored) };
}

test("an address in a sign-in link leaves the page address and waits in session storage", () => {
  const r = boot("#/sign-in?email=rae%2Bnews%40example.com");
  assert.equal(r.hash, "#/sign-in");
  assert.deepEqual(r.stored, { "casama-sign-in-email": "rae+news@example.com" });
});

test("other parts of the link stay, and only the address goes", () => {
  const r = boot("#/sign-in?from=invite&email=rae%40example.com");
  assert.equal(r.hash, "#/sign-in?from=invite");
  assert.equal(r.stored["casama-sign-in-email"], "rae@example.com");
});

test("links without an address, and other screens, are left alone", () => {
  for (const hash of ["#/sign-in", "#/sign-in?from=invite", "#/bots?email=rae%40example.com", "#/link?code=ABC", ""]) {
    const r = boot(hash);
    assert.equal(r.hash, hash, hash);
    assert.deepEqual(r.stored, {}, hash);
  }
});

test("with storage turned off the address still leaves the page address", () => {
  const r = boot("#/sign-in?email=rae%40example.com", { storage: false });
  assert.equal(r.hash, "#/sign-in");
  assert.deepEqual(r.stored, {});
});
