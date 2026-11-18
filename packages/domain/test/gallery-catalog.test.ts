import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { APP_CATALOG } from "../src/apps.ts";
import {
  compareGalleryVersions,
  type GalleryMeta,
  galleryAccessFor,
  galleryInSeason,
  parseGalleryMeta,
} from "../src/gallery.ts";
import {
  buildGalleryAuthors,
  checkGalleryInputsUsage,
  checkGalleryInputValues,
  checkGalleryRefs,
  checkGalleryTests,
  checkSetDocument,
  fillGalleryDocument,
  galleryAuthorSlug,
  galleryInputDefaults,
  galleryManifestCovers,
  galleryManifestJson,
  galleryTemplateOf,
  galleryTestedFor,
  generateGalleryKeyPair,
  parseGalleryManifest,
  parseGalleryTested,
  signGalleryManifest,
  verifyGalleryManifest,
} from "../src/gallery-catalog.ts";

const base = {
  name: "Morning plan",
  author: { name: "Casama", url: "https://casama.ai", handle: "casama" },
  license: "MIT",
  tags: ["planning"],
  version: 1,
  added: "2026-11-13",
};

describe("gallery v2 item fields", () => {
  it("requires added, unless a submission may leave it out", () => {
    const { added: _added, ...noDate } = base;
    expect(parseGalleryMeta(noDate, ["MIT"]).errors).toEqual([
      "added must be the YYYY-MM-DD it was added",
    ]);
    expect(parseGalleryMeta(noDate, ["MIT"], { allowMissingAdded: true }).errors).toEqual([]);
    expect(parseGalleryMeta({ ...base, added: "2026-02-30" }, ["MIT"]).errors).toEqual([
      "added must be a YYYY-MM-DD date",
    ]);
  });

  it("reads every new field and works out updated", () => {
    const { meta, errors } = parseGalleryMeta(
      {
        ...base,
        featured: true,
        pick: "Five lines each morning.",
        version: 2,
        changelog: [
          { version: 2, date: "2026-11-15", note: "Asks for your city.", breaking: true },
          { version: 1, date: "2026-11-13", note: "First version." },
        ],
        access: { reads: ["calendar"], credits: "low" },
        needs: { apps: ["google_calendar"], skills: ["digest"] },
        inputs: [{ key: "time", label: "When?", type: "time", default: "07:30" }],
        remix_of: { type: "routine", id: "weekly-review" },
        min_app: "0.2.0",
        min_server: "0.1.1",
        season: { from: "12-01", to: "01-06" },
      },
      ["MIT"],
      { kind: "routine" },
    );
    expect(errors).toEqual([]);
    expect(meta?.updated).toBe("2026-11-15");
    expect(meta?.author.handle).toBe("casama");
    expect(meta?.changelog?.[0]?.breaking).toBe(true);
    expect(meta?.season).toEqual({ from: "12-01", to: "01-06" });
  });

  it("rejects fields on the wrong kind and a pick without featured", () => {
    const { errors } = parseGalleryMeta(
      { ...base, pick: "Nice", examples: ["Try me"], needs: { skills: ["x"] } },
      ["MIT"],
      { kind: "theme" },
    );
    expect(errors).toEqual([
      "pick is only for featured items",
      "examples aren't for a theme",
      "needs aren't for a theme",
    ]);
  });

  it("needs a changelog past version 1, newest first and matching the version", () => {
    expect(parseGalleryMeta({ ...base, version: 2 }, ["MIT"]).errors).toEqual([
      "changelog is required once version is above 1",
    ]);
    const bad = parseGalleryMeta(
      {
        ...base,
        version: 3,
        changelog: [
          { version: 1, date: "2026-11-13", note: "a" },
          { version: 2, date: "2026-11-14", note: "b" },
        ],
      },
      ["MIT"],
    );
    expect(bad.errors).toEqual([
      "changelog versions must go strictly down, newest first",
      "changelog dates must not go up, newest first",
      "changelog's top entry must be version 3",
    ]);
  });

  it("checks install questions: defaults fit their type", () => {
    const { errors } = parseGalleryMeta(
      {
        ...base,
        inputs: [
          { key: "time", label: "When?", type: "time", default: "7:30am" },
          { key: "size", label: "Size", type: "choice", options: ["s", "m"], default: "l" },
          { key: "city", label: "City", type: "text" },
        ],
      },
      ["MIT"],
      { kind: "routine" },
    );
    expect(errors).toEqual([
      "inputs[0].default must be a time such as 07:30",
      "inputs[1].default must be one of the options",
      "inputs[2].default must be 1 to 120 characters (what older servers use)",
    ]);
  });

  it("marks code and a computer when a skill brings scripts", () => {
    expect(galleryAccessFor("skill", { reads: ["files"] }, ["SKILL.md", "scripts/a.py"])).toEqual({
      access: { reads: ["files"], runs_code: true, computer: true },
      errors: [],
    });
    expect(galleryAccessFor("skill", { runs_code: false }, ["run.sh"]).errors).toHaveLength(1);
    expect(galleryAccessFor("skill", undefined, ["SKILL.md", "notes.md"]).access).toBeUndefined();
  });

  it("knows seasons across the year end and compares versions", () => {
    const winter = { from: "12-01", to: "01-06" };
    expect(galleryInSeason(winter, "2026-12-24")).toBe(true);
    expect(galleryInSeason(winter, "2027-01-03")).toBe(true);
    expect(galleryInSeason(winter, "2027-02-01")).toBe(false);
    expect(compareGalleryVersions("0.10.0", "0.9.9")).toBeGreaterThan(0);
    expect(compareGalleryVersions("1.0.0", "1.0.0")).toBe(0);
  });
});

describe("install questions and placeholders", () => {
  const inputs = [
    { key: "time", label: "When?", type: "time" as const, default: "07:30" },
    { key: "city", label: "City", type: "text" as const, default: "my city" },
  ];
  const raw = {
    instructions_md: "Plan my day with the weather in {{city}}.",
    schedule_cron: "{{time.minute}} {{time.hour}} * * 1-5",
  };

  it("fills defaults for older servers and keeps the template", () => {
    expect(checkGalleryInputsUsage("routine", inputs, raw)).toEqual([]);
    expect(fillGalleryDocument("routine", raw, galleryInputDefaults(inputs))).toEqual({
      instructions_md: "Plan my day with the weather in my city.",
      schedule_cron: "30 7 * * 1-5",
    });
    expect(galleryTemplateOf("routine", { ...raw, icon: "sunrise" })).toEqual(raw);
  });

  it("finds unasked and unused questions", () => {
    expect(
      checkGalleryInputsUsage("routine", [inputs[1] as (typeof inputs)[number]], {
        instructions_md: "Hi {{name}} at {{time.hour}}",
        schedule_cron: "{{city}} 7 * * *",
      }),
    ).toEqual([
      "{{name}} in instructions_md has no input",
      "{{time.hour}} in instructions_md has no input",
      "schedule_cron can only use {{time.minute}} and {{time.hour}}",
    ]);
    expect(checkGalleryInputsUsage("bot", inputs, { persona: "No placeholders here." })).toEqual([
      "input time isn't used",
      "input city isn't used",
    ]);
  });

  it("checks someone's answers by key", () => {
    expect(checkGalleryInputValues(inputs, { time: "06:15" })).toEqual({
      values: { time: "06:15", city: "my city" },
      errors: {},
    });
    expect(checkGalleryInputValues(inputs, { time: "noon", extra: "x" }).errors).toEqual({
      extra: "isn't a question this item asks",
      time: "must be a time such as 07:30",
    });
  });
});

describe("skill tests, sets, references and authors", () => {
  it("checks tests.json and folds passes on the current version", () => {
    expect(checkGalleryTests({ cases: [{ prompt: "Hi", expect: "Says hi" }] }).errors).toEqual([]);
    expect(checkGalleryTests({ cases: [] }).errors).toEqual(["tests.json needs 1 to 5 cases"]);
    const { tested } = parseGalleryTested({
      proofread: { version: 2, passed: true, date: "2026-11-16" },
      digest: { version: 1, passed: false, date: "2026-11-16" },
    });
    expect(galleryTestedFor(tested, "proofread", 2)).toEqual({ version: 2, date: "2026-11-16" });
    expect(galleryTestedFor(tested, "proofread", 3)).toBeUndefined();
    expect(galleryTestedFor(tested, "digest", 1)).toBeUndefined();
  });

  it("checks a starter set", () => {
    const ok = checkSetDocument({
      description: "Founder things.",
      icon: "rocket",
      items: [
        { type: "skill", id: "decision-memo" },
        { type: "app", id: "todoist" },
      ],
    });
    expect(ok.errors).toEqual([]);
    expect(
      checkSetDocument({ description: "x", icon: "rocket", items: [{ type: "set", id: "a" }] })
        .errors,
    ).toEqual(["items must be 2 to 12 gallery items"]);
  });

  it("checks references across the catalog", () => {
    const meta = (extra: Partial<GalleryMeta>): GalleryMeta => ({
      name: "x",
      author: { name: "Casama" },
      license: "MIT",
      tags: [],
      featured: false,
      retired: false,
      version: 1,
      ...extra,
    });
    const errors = checkGalleryRefs(
      [
        { type: "skill", id: "digest", meta: meta({}) },
        { type: "skill", id: "old", meta: meta({ retired: true }) },
        {
          type: "routine",
          id: "plan",
          meta: meta({
            needs: { apps: ["google_calendar", "nope"], skills: ["digest", "missing"] },
            remix_of: { type: "routine", id: "gone" },
            replaced_by: { type: "skill", id: "digest" },
          }),
        },
        {
          type: "set",
          id: "kit",
          meta: meta({}),
          setItems: [
            { type: "skill", id: "old" },
            { type: "app", id: "todoist" },
          ],
        },
      ],
      ["google_calendar"],
    );
    expect(errors).toEqual([
      "routine/plan: needs skill missing, which isn't in the gallery",
      "routine/plan: needs app nope, which isn't a gallery or built-in app",
      "routine/plan: remix_of routine/gone isn't in the gallery",
      "routine/plan: replaced_by is only for retired items",
      "set/kit: skill/old is retired",
      "set/kit: app/todoist isn't in the gallery",
    ]);
  });

  it("groups authors by handle, else by name", () => {
    expect(galleryAuthorSlug("Jesse Vincent")).toBe("jesse-vincent");
    expect(galleryAuthorSlug("Zoë  O'Brien!")).toBe("zoe-o-brien");
    const { authors } = buildGalleryAuthors([
      { type: "skill", id: "b", author: { name: "Casama", handle: "casama" } },
      {
        type: "app",
        id: "a",
        author: { name: "Casama", url: "https://casama.ai", handle: "casama" },
      },
      { type: "skill", id: "c", author: { name: "Matt Pocock" } },
      { type: "skill", id: "d", retired: true, author: { name: "Gone" } },
    ]);
    expect(authors).toEqual([
      {
        handle: "casama",
        name: "Casama",
        url: "https://casama.ai",
        items: [
          { type: "app", id: "a" },
          { type: "skill", id: "b" },
        ],
      },
      { handle: "matt-pocock", name: "Matt Pocock", items: [{ type: "skill", id: "c" }] },
    ]);
  });
});

describe("the signed manifest", () => {
  // A throwaway key pair for this test only; the production key never lives in the repo.
  const pair = generateGalleryKeyPair();

  it("signs and verifies manifest.json, and catches tampering", () => {
    const index = '{"schema":1,"items":[]}\n';
    const manifest = galleryManifestJson([{ name: "index.json", bytes: index }], "2026-11-16");
    const sig = signGalleryManifest(manifest, pair.privateKeyPem);
    expect(verifyGalleryManifest(manifest, sig, pair.publicKeyBase64)).toBe(true);
    expect(verifyGalleryManifest(`${manifest} `, sig, pair.publicKeyBase64)).toBe(false);
    expect(verifyGalleryManifest(manifest, sig, generateGalleryKeyPair().publicKeyBase64)).toBe(
      false,
    );
    expect(verifyGalleryManifest(manifest, "not base64!", "short")).toBe(false);
    const parsed = parseGalleryManifest(JSON.parse(manifest));
    expect(parsed && galleryManifestCovers(parsed, "index.json", index)).toBe(true);
    expect(parsed && galleryManifestCovers(parsed, "index.json", `${index} `)).toBe(false);
    expect(parsed && galleryManifestCovers(parsed, "apps.json", index)).toBe(false);
  });

  it("accepts a raw 32-byte seed as the signing key", () => {
    const seed = Buffer.alloc(32, 7).toString("base64");
    const sig = signGalleryManifest("{}", seed);
    expect(sig).toMatch(/^[A-Za-z0-9+/]+=*$/);
  });
});

describe("gallery/check.mjs", () => {
  it("knows the same built-in app ids as APP_CATALOG", () => {
    const source = readFileSync(new URL("../../../gallery/check.mjs", import.meta.url), "utf8");
    const block = /const BUILT_IN_APPS = \[([\s\S]*?)\];/.exec(source)?.[1] ?? "";
    const ids = [...block.matchAll(/"([a-z0-9_-]+)"/g)].map((m) => m[1]);
    expect(ids.sort()).toEqual(APP_CATALOG.map((a) => a.id).sort());
  });
});
