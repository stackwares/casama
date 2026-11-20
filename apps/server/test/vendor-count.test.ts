/**
 * Own vendor counts (docs/VENDOR-USAGE-PLAN.md, phase 1): the atomic daily upsert, the checks on
 * what is counted, and that every wrapper counts successful server-owned calls only.
 */
import type { SearchProvider } from "@casama/agent";
import { createDb, type DbHandle } from "@casama/db";
import { startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { type EmailMessage, type EmailSender, resendEmail } from "../src/services/email.ts";
import {
  COUNTED_VENDORS,
  countingEmail,
  countingSearch,
  countingWallpapers,
  createVendorCounter,
  parseResendQuota,
  smtpVendor,
  type VendorCounter,
  validCount,
} from "../src/services/vendors/count.ts";
import type { WallpaperSource } from "../src/services/wallpapers.ts";

let tdb: TestDatabase;
let handle: DbHandle;

beforeAll(async () => {
  tdb = await startTestDatabase();
  handle = createDb(tdb.url, { max: 5 });
});
afterAll(async () => {
  await handle?.close();
  await tdb?.stop();
});
beforeEach(async () => {
  await tdb.admin`delete from public.vendor_counts`;
  await tdb.admin`delete from public.vendor_limits`;
  for (const vendor of [...COUNTED_VENDORS]) {
    await tdb.admin`
      insert into public.vendor_limits (vendor, label, kind, unit) values (${vendor}, ${vendor}, 'quota', 'calls')`;
  }
});

const today = async () =>
  (await tdb.admin`select (now() at time zone 'utc')::date::text as d`)[0]?.d as string;
const counts = async () =>
  Object.fromEntries(
    (
      await tdb.admin`select vendor, day::text as day, count::int as count from public.vendor_counts`
    ).map((r) => [r.vendor as string, { day: r.day as string, count: r.count as number }]),
  );

/** A counter that remembers its writes, so a test can wait for the fire-and-forget ones. */
function recording(inner: VendorCounter) {
  const pending: Promise<boolean>[] = [];
  const counter: VendorCounter = {
    count(vendor, n) {
      const p = inner.count(vendor, n);
      pending.push(p);
      return p;
    },
  };
  return { counter, settled: () => Promise.all(pending) };
}

const message: EmailMessage = { to: "person@casama.ai", subject: "Hi", text: "Hello" };

describe("createVendorCounter", () => {
  it("adds to one row per vendor and UTC day", async () => {
    const counter = createVendorCounter(handle.db);
    expect(await counter.count("serper")).toBe(true);
    expect(await counter.count("serper", 4)).toBe(true);
    expect(await counter.count("resend")).toBe(true);
    expect(await counts()).toEqual({
      serper: { day: await today(), count: 5 },
      resend: { day: await today(), count: 1 },
    });
  });

  it("does not lose counts when many calls land at once", async () => {
    const counter = createVendorCounter(handle.db);
    const results = await Promise.all(Array.from({ length: 60 }, () => counter.count("parallel")));
    expect(results.every(Boolean)).toBe(true);
    expect((await counts()).parallel?.count).toBe(60);
  });

  it("starts a new row for a new day and leaves the old one alone", async () => {
    await tdb.admin`insert into public.vendor_counts (vendor, day, count) values ('resend', '2020-01-01', 7)`;
    await createVendorCounter(handle.db).count("resend");
    const rows = await tdb.admin`
      select day::text as day, count::int as count from public.vendor_counts order by day`;
    expect(rows.map((r) => [r.day, r.count])).toEqual([
      ["2020-01-01", 7],
      [await today(), 1],
    ]);
  });

  it("only counts whole numbers, zero or more", async () => {
    const logs: string[] = [];
    const counter = createVendorCounter(handle.db, { log: (m) => logs.push(m) });
    for (const bad of [-1, Number.NaN, Number.POSITIVE_INFINITY, 1.5, "2", null, 2 ** 60]) {
      expect(await counter.count("serper", bad as number)).toBe(false);
    }
    expect(await counter.count("", 1)).toBe(false);
    expect(await counter.count("   ", 1)).toBe(false);
    expect(await counts()).toEqual({});
    expect(logs.length).toBeGreaterThan(0);
    // Zero is a valid count that changes nothing.
    expect(await counter.count("serper", 0)).toBe(true);
    expect(await counts()).toEqual({});
  });

  it("never rejects when the database says no, and logs once a minute without secrets", async () => {
    const logs: Array<{ msg: string; extra?: Record<string, unknown> }> = [];
    let clock = 1_000_000;
    const counter = createVendorCounter(handle.db, {
      log: (msg, extra) => logs.push({ msg, extra }),
      now: () => clock,
    });
    // No vendor_limits row for this vendor: the foreign key refuses it.
    expect(await counter.count("not-a-vendor")).toBe(false);
    expect(await counter.count("not-a-vendor")).toBe(false);
    expect(logs).toHaveLength(1);
    expect(logs[0]?.msg).toBe("vendor count not saved");
    expect(logs[0]?.extra?.vendor).toBe("not-a-vendor");
    expect(JSON.stringify(logs[0])).not.toMatch(/postgres(ql)?:\/\/|password|params/i);
    clock += 61_000;
    await counter.count("not-a-vendor");
    expect(logs).toHaveLength(2);
    expect(await counts()).toEqual({});
  });

  it("survives a database that throws and a logger that throws", async () => {
    const broken = createVendorCounter(
      {
        execute() {
          throw new Error("connection to postgres://user:hunter2@db/x refused");
        },
      },
      {
        log: () => {
          throw new Error("logger down");
        },
      },
    );
    await expect(broken.count("resend")).resolves.toBe(false);
    const rejecting = createVendorCounter({ execute: () => Promise.reject(new Error("boom")) });
    await expect(rejecting.count("resend")).resolves.toBe(false);
  });
});

describe("validCount", () => {
  it("accepts only finite whole numbers of zero or more", () => {
    expect([0, 1, 12345].every(validCount)).toBe(true);
    expect([-1, 0.5, Number.NaN, Number.POSITIVE_INFINITY, "1", undefined].some(validCount)).toBe(
      false,
    );
  });
});

describe("countingEmail", () => {
  const sender = (fail = false): EmailSender & { sent: EmailMessage[] } => {
    const sent: EmailMessage[] = [];
    return {
      enabled: true,
      sent,
      async send(msg) {
        if (fail) throw new Error("refused");
        sent.push(msg);
      },
    };
  };

  it("counts a send that went through, at the vendor it was given", async () => {
    const r = recording(createVendorCounter(handle.db));
    const inner = sender();
    const counted = countingEmail(inner, "zeptomail", r.counter);
    await counted.send(message);
    await counted.send({ ...message, to: "other@casama.ai" });
    await r.settled();
    expect(inner.sent).toHaveLength(2);
    expect((await counts()).zeptomail?.count).toBe(2);
  });

  it("does not count a failed send, and the error still reaches the caller", async () => {
    const r = recording(createVendorCounter(handle.db));
    const counted = countingEmail(sender(true), "resend", r.counter);
    await expect(counted.send(message)).rejects.toThrow("refused");
    await r.settled();
    expect(await counts()).toEqual({});
  });

  it("does not count an address that can never receive mail", async () => {
    const r = recording(createVendorCounter(handle.db));
    await countingEmail(sender(), "resend", r.counter).send({ ...message, to: "a@example.com" });
    await r.settled();
    expect(await counts()).toEqual({});
  });

  it("never fails a send because counting failed", async () => {
    const counted = countingEmail(
      sender(),
      "resend",
      createVendorCounter({ execute: () => Promise.reject(new Error("db down")) }),
    );
    await expect(counted.send(message)).resolves.toBeUndefined();
  });

  it("counts a real Resend send once, and the backup only when it takes over", async () => {
    const r = recording(createVendorCounter(handle.db));
    let status = 200;
    const fetchImpl = (async () =>
      new Response("{}", {
        status,
        headers: { "x-resend-daily-quota": "12", "x-resend-monthly-quota": "340" },
      })) as unknown as typeof fetch;
    const seen: Array<ReturnType<typeof parseResendQuota>> = [];
    const resend = countingEmail(
      resendEmail("key", "Casama <hello@notify.casama.ai>", fetchImpl, (res) =>
        seen.push(parseResendQuota(res.headers)),
      ),
      "resend",
      r.counter,
    );
    await resend.send(message);
    status = 429;
    await expect(resend.send(message)).rejects.toThrow("429");
    await r.settled();
    expect((await counts()).resend?.count).toBe(1);
    // The headers are seen on every answer, failed or not.
    expect(seen).toEqual([
      { daily: 12, monthly: 340 },
      { daily: 12, monthly: 340 },
    ]);
  });
});

describe("smtpVendor", () => {
  it("names ZeptoMail by its host and no other SMTP server", () => {
    expect(smtpVendor("smtp.zeptomail.com")).toBe("zeptomail");
    expect(smtpVendor(" smtp.zeptomail.eu ")).toBe("zeptomail");
    expect(smtpVendor("smtp.zoho.com")).toBeNull();
    expect(smtpVendor("mail.example.com")).toBeNull();
    expect(smtpVendor("notzeptomail.com")).toBeNull();
    expect(smtpVendor(undefined)).toBeNull();
  });
});

describe("parseResendQuota", () => {
  it("reads both headers and turns anything invalid into null", () => {
    expect(parseResendQuota(new Headers({ "x-resend-daily-quota": "3" }))).toEqual({
      daily: 3,
      monthly: null,
    });
    expect(
      parseResendQuota(
        new Headers({ "x-resend-daily-quota": "-1", "x-resend-monthly-quota": "lots" }),
      ),
    ).toEqual({ daily: null, monthly: null });
    expect(parseResendQuota(new Headers())).toEqual({ daily: null, monthly: null });
  });
});

describe("countingSearch", () => {
  const provider = (id: string, outcome: "ok" | "empty" | "fail"): SearchProvider => ({
    id,
    costUsd: 0.001,
    async search() {
      if (outcome === "fail") throw new Error(`${id} returned 500`);
      return outcome === "empty" ? [] : [{ title: "t", url: "https://example.org", snippet: "s" }];
    },
  });

  it("counts Parallel and Serper queries that got an answer, empty ones too", async () => {
    const r = recording(createVendorCounter(handle.db));
    const serper = countingSearch(provider("serper", "ok"), r.counter);
    const parallel = countingSearch(provider("parallel", "empty"), r.counter);
    expect(serper.id).toBe("serper");
    expect(serper.costUsd).toBe(0.001);
    expect(await serper.search("a")).toHaveLength(1);
    await serper.search("b");
    expect(await parallel.search("c")).toEqual([]);
    await r.settled();
    const c = await counts();
    expect(c.serper?.count).toBe(2);
    expect(c.parallel?.count).toBe(1);
  });

  it("does not count a failed query and passes the error on", async () => {
    const r = recording(createVendorCounter(handle.db));
    const failing = countingSearch(provider("serper", "fail"), r.counter);
    await expect(failing.search("a")).rejects.toThrow("serper returned 500");
    await r.settled();
    expect(await counts()).toEqual({});
  });

  it("leaves providers that aren't counted here untouched", () => {
    const r = recording(createVendorCounter(handle.db));
    for (const id of ["deepseek", "searxng", "brave_search", "tavily"]) {
      const p = provider(id, "ok");
      expect(countingSearch(p, r.counter)).toBe(p);
    }
  });
});

describe("countingWallpapers", () => {
  const source = (fail = false): WallpaperSource & { downloads: string[] } => {
    const downloads: string[] = [];
    return {
      name: "unsplash",
      downloads,
      async search() {
        if (fail) throw new Error("unsplash 403");
        return [];
      },
      async trackDownload(location) {
        downloads.push(location);
      },
    };
  };

  it("counts photo searches that worked, not failed ones or download reports", async () => {
    const r = recording(createVendorCounter(handle.db));
    const inner = source();
    const counted = countingWallpapers(inner, r.counter);
    expect(counted.name).toBe("unsplash");
    await counted.search("sea", 1);
    await counted.search(undefined, 2);
    await counted.trackDownload("https://api.unsplash.com/photos/x/download");
    await r.settled();
    expect(inner.downloads).toEqual(["https://api.unsplash.com/photos/x/download"]);
    expect((await counts()).unsplash?.count).toBe(2);

    const failing = countingWallpapers(source(true), r.counter);
    await expect(failing.search("sea", 1)).rejects.toThrow("unsplash 403");
    await r.settled();
    expect((await counts()).unsplash?.count).toBe(2);
  });
});
