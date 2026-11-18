/**
 * Gallery v2 (D-315): stats, every kind in one list, install with questions and needs, Installed
 * and updates, workspace rules and approvals, the requests board, submissions (a fake GitHub),
 * and the worker jobs (rollup, rewards, monthly picks, health).
 */
import { readFile } from "node:fs/promises";
import { createServer, type IncomingMessage } from "node:http";
import type { AddressInfo } from "node:net";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { generateGalleryKeyPair, sha256Hex, signGalleryManifest } from "@casama/domain";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { sendAccountEmails } from "../src/services/account-emails.ts";
import { galleryIndex, resetGalleryCache } from "../src/services/gallery.ts";
import {
  checkGalleryHealth,
  parseGalleryRewards,
  queueGalleryDigests,
  rewardGalleryContributors,
} from "../src/services/gallery-jobs.ts";
import { resetGalleryStatsCache, rollupGalleryStats } from "../src/services/gallery-usage.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const galleryRoot = fileURLToPath(new URL("../../../gallery", import.meta.url));

type Site = { url: string; overrides: Map<string, string>; close: () => Promise<void> };

/** gallery/ served locally; `overrides` replaces a file's text (a newer catalog). */
function serveGallery(): Promise<Site> {
  const overrides = new Map<string, string>();
  return new Promise((resolve) => {
    const server = createServer(async (req, res) => {
      const path = decodeURIComponent(new URL(req.url ?? "/", "http://127.0.0.1").pathname);
      if (path.includes("..")) {
        res.statusCode = 400;
        res.end();
        return;
      }
      const over = overrides.get(path.slice(1));
      if (over !== undefined) {
        res.setHeader("content-type", "application/json");
        res.end(over);
        return;
      }
      try {
        res.end(await readFile(join(galleryRoot, path)));
      } catch {
        res.statusCode = 404;
        res.end();
      }
    });
    server.listen(0, "127.0.0.1", () => {
      resolve({
        url: `http://127.0.0.1:${(server.address() as AddressInfo).port}`,
        overrides,
        close: () => new Promise((done) => server.close(() => done())),
      });
    });
  });
}

/** A fake GitHub: records calls and answers what openGalleryPullRequest needs. */
function fakeGitHub() {
  const calls: { method: string; path: string; body: Record<string, unknown> }[] = [];
  let merged = false;
  return new Promise<{
    url: string;
    calls: typeof calls;
    merge: () => void;
    close: () => Promise<void>;
  }>((resolve) => {
    const server = createServer(async (req: IncomingMessage, res) => {
      let text = "";
      for await (const chunk of req) text += chunk;
      const body = text ? (JSON.parse(text) as Record<string, unknown>) : {};
      const path = new URL(req.url ?? "/", "http://x").pathname;
      calls.push({ method: req.method ?? "", path, body });
      res.setHeader("content-type", "application/json");
      if (req.headers.authorization !== "Bearer ghp_test") {
        res.statusCode = 401;
        res.end("{}");
        return;
      }
      if (req.method === "GET" && path === "/repos/stackwares/casama-gallery")
        return res.end(JSON.stringify({ default_branch: "main" }));
      if (path.endsWith("/git/ref/heads/main"))
        return res.end(JSON.stringify({ object: { sha: "abc123" } }));
      if (path.endsWith("/git/refs")) return res.end(JSON.stringify({ ref: body.ref }));
      if (path.includes("/contents/")) return res.end(JSON.stringify({ content: {} }));
      if (req.method === "POST" && path.endsWith("/pulls"))
        return res.end(JSON.stringify({ number: 7, html_url: "https://github.com/x/pull/7" }));
      if (req.method === "GET" && path.endsWith("/pulls/7"))
        return res.end(JSON.stringify({ state: merged ? "closed" : "open", merged }));
      res.statusCode = 404;
      res.end("{}");
    });
    server.listen(0, "127.0.0.1", () => {
      resolve({
        url: `http://127.0.0.1:${(server.address() as AddressInfo).port}`,
        calls,
        merge: () => {
          merged = true;
        },
        close: () => new Promise((done) => server.close(() => done())),
      });
    });
  });
}

describe("gallery v2", () => {
  let h: Harness;
  let site: Site;
  let github: Awaited<ReturnType<typeof fakeGitHub>>;
  let owner: { id: string; token: string };
  let member: { id: string; token: string };
  let outsider: { id: string; token: string };
  let orgId: string;
  let botId: string;

  const post = (token: string, path: string, json: unknown) =>
    h.request(path, { method: "POST", token, json });

  beforeAll(async () => {
    resetGalleryCache();
    resetGalleryStatsCache();
    site = await serveGallery();
    github = await fakeGitHub();
    h = await startHarness({
      email: true,
      env: {
        GALLERY_URL: site.url,
        // Casama Cloud counts its own (a self-hosted server would read GALLERY_STATS_URL).
        BILLING_ENABLED: "false",
        GALLERY_STATS_URL: "off",
        GALLERY_SUBMIT_TOKEN: "ghp_test",
        GITHUB_API_URL: github.url,
      },
    });
    owner = await h.user("gv2-owner@example.com");
    member = await h.user("gv2-member@example.com");
    outsider = await h.user("gv2-outsider@example.com");
    orgId = (await j(await post(owner.token, "/v1/orgs", { name: "Gallery v2" }))).id;
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
    botId = (await j(await post(owner.token, "/v1/bots", { org_id: orgId, name: "Helper" }))).id;
  }, 120_000);

  afterAll(async () => {
    await h?.stop();
    await site?.close();
    await github?.close();
    resetGalleryCache();
  });

  it("serves public stats with CORS and leaves out small numbers", async () => {
    for (let i = 0; i < 12; i++)
      await h.tdb.admin`insert into public.gallery_installs (item_key, user_hash)
        values ('theme/lagoon', ${sha256Hex(`u${i}`)})`;
    await h.tdb.admin`insert into public.gallery_installs (item_key, user_hash)
      values ('theme/orchard', ${sha256Hex("one")})`;
    await rollupGalleryStats(h.handle.db, h.deps.env);
    // Cloud mode serves its own counts.
    (h.deps.env as { BILLING_ENABLED: boolean }).BILLING_ENABLED = true;
    resetGalleryStatsCache();
    const res = await h.request("/v1/gallery/stats", {
      headers: { origin: "https://gallery.casama.ai" },
    });
    (h.deps.env as { BILLING_ENABLED: boolean }).BILLING_ENABLED = false;
    expect(res.status).toBe(200);
    expect(res.headers.get("access-control-allow-origin")).toBe("*");
    expect(res.headers.get("cache-control")).toContain("max-age=600");
    const body = await j(res);
    expect(body.items["theme/lagoon"]).toEqual({ installers: 12, trending: 12, active: 12 });
    expect(body.items["theme/orchard"]).toBeUndefined();
    const pre = await h.request("/v1/gallery/stats", {
      method: "OPTIONS",
      headers: { origin: "https://casama.ai", "access-control-request-method": "GET" },
    });
    expect(pre.status).toBe(204);
    expect(pre.headers.get("access-control-allow-origin")).toBe("*");
  });

  it("lists every kind with kinds=all and reads any kind by id", async () => {
    const old = await j(await h.request("/v1/gallery", { token: owner.token }));
    expect(
      old.items.every((i: { type: string }) =>
        ["theme", "scheme", "wallpaper", "skill"].includes(i.type),
      ),
    ).toBe(true);
    const all = await j(await h.request("/v1/gallery?kinds=all", { token: owner.token }));
    const types = new Set(all.items.map((i: { type: string }) => i.type));
    for (const t of ["theme", "skill", "app", "bot", "routine", "plugin", "set"])
      expect(types).toContain(t);
    const routine = await j(
      await h.request("/v1/gallery/routine/morning-plan", { token: owner.token }),
    );
    expect(routine.inputs[0].key).toBe("time");
    expect(routine.template.schedule_cron).toContain("{{time.minute}}");
    const sets = await j(await h.request("/v1/gallery?type=set", { token: owner.token }));
    expect(sets.items.length).toBeGreaterThan(0);
    const setList = await j(await h.request("/v1/gallery/sets", { token: owner.token }));
    expect(
      setList.items.find((s: { id: string }) => s.id === "founder-kit").items.length,
    ).toBeGreaterThan(1);
    const authors = await j(await h.request("/v1/gallery/authors", { token: owner.token }));
    expect(authors.items.length).toBeGreaterThan(0);
    // Routine ideas carry install questions; starter bots theirs.
    const ideas = await j(await h.request("/v1/routine-ideas", { token: owner.token }));
    expect(ideas.items.find((i: { id: string }) => i.id === "morning-plan").inputs).toHaveLength(2);
  });

  it("installs a routine with answers, and checks them per key", async () => {
    const bad = await post(owner.token, "/v1/gallery/install", {
      org_id: orgId,
      type: "routine",
      id: "morning-plan",
      bot_id: botId,
      inputs: { time: "25:99", nope: "x" },
    });
    expect(bad.status).toBe(400);
    const problem = await j(bad);
    expect(problem.code).toBe("inputs_invalid");
    expect(problem.errors.map((e: { path: string }) => e.path).sort()).toEqual(["nope", "time"]);
    expect(
      (
        await post(owner.token, "/v1/gallery/install", {
          org_id: orgId,
          type: "routine",
          id: "morning-plan",
        })
      ).status,
    ).toBe(400);
    const res = await post(owner.token, "/v1/gallery/install", {
      org_id: orgId,
      type: "routine",
      id: "morning-plan",
      bot_id: botId,
      inputs: { time: "06:15", city: "Berlin" },
    });
    expect(res.status).toBe(201);
    const out = await j(res);
    expect(out.status).toBe("installed");
    const [r] = await h.tdb.admin<{ schedule_cron: string; instructions_md: string }[]>`
      select schedule_cron, instructions_md from public.routines where id = ${out.installed.id}`;
    expect(r?.schedule_cron).toBe("15 6 * * 1-5");
    expect(r?.instructions_md).toContain("weather in Berlin");
    // Outsiders can't install into the workspace.
    const no = await post(outsider.token, "/v1/gallery/install", {
      org_id: orgId,
      type: "routine",
      id: "morning-plan",
      bot_id: botId,
    });
    expect(no.status).toBe(404);
  });

  it("brings needed skills along and returns apps to connect", async () => {
    const out = await j(
      await post(owner.token, "/v1/gallery/install", {
        org_id: orgId,
        type: "routine",
        id: "meeting-notes",
        bot_id: botId,
      }),
    );
    expect(out.missing.apps).toEqual([expect.objectContaining({ id: "google_calendar" })]);
    expect(out.missing.skills).toEqual([]);
    const [s] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.skills where org_id = ${orgId} and name = 'meeting-notes' and bot_id = ${botId}`;
    expect(s?.n).toBe(1);
  });

  it("makes a starter bot with answers and records it", async () => {
    const res = await post(owner.token, "/v1/gallery/install", {
      org_id: orgId,
      type: "bot",
      id: "study-buddy",
      inputs: { level: "university" },
    });
    expect(res.status).toBe(201);
    const out = await j(res);
    const [b] = await h.tdb.admin<{ persona_md: string }[]>`
      select persona_md from public.bots where id = ${out.installed.id}`;
    expect(b?.persona_md).toContain("studying at university level");
    const [l] = await h.tdb.admin<{ inputs: Record<string, string> }[]>`
      select inputs from public.gallery_links where target_id = ${out.installed.id}`;
    expect(l?.inputs).toEqual({ level: "university" });
    // Updates and removal refuse outsiders.
    const no = await post(outsider.token, "/v1/gallery/installed/update", {
      org_id: orgId,
      type: "bot",
      id: "study-buddy",
    });
    expect(no.status).toBe(404);
  });

  it("lists installed items, asks before an update that can reach more, then updates", async () => {
    const list = await j(
      await h.request(`/v1/gallery/installed?org_id=${orgId}`, { token: owner.token }),
    );
    const plan = list.items.find((i: { id: string }) => i.id === "morning-plan");
    expect(plan).toMatchObject({
      type: "routine",
      installed_version: 1,
      latest_version: 1,
      update: false,
      retired: false,
    });
    expect(
      list.items.some(
        (i: { type: string; id: string }) => i.type === "skill" && i.id === "meeting-notes",
      ),
    ).toBe(true);
    expect(
      (await h.request(`/v1/gallery/installed?org_id=${orgId}`, { token: outsider.token })).status,
    ).toBe(404);
    // A newer catalog: version 2 reads email too.
    const routines = JSON.parse(await readFile(join(galleryRoot, "routines.json"), "utf8"));
    const rec = routines.items.find((i: { id: string }) => i.id === "morning-plan");
    rec.version = 2;
    rec.changelog = [
      { version: 2, date: "2026-11-16", note: "Reads your inbox too" },
      { version: 1, date: "2026-11-01", note: "First version" },
    ];
    rec.access = { ...(rec.access ?? {}), reads: [...(rec.access?.reads ?? []), "email"] };
    rec.template.instructions_md = `${rec.template.instructions_md} Also the inbox for {{city}}.`;
    site.overrides.set("routines.json", JSON.stringify(routines));
    resetGalleryCache();
    const again = await j(
      await h.request(`/v1/gallery/installed?org_id=${orgId}`, { token: owner.token }),
    );
    const v2 = again.items.find((i: { id: string }) => i.id === "morning-plan");
    expect(v2).toMatchObject({ update: true, latest_version: 2, breaking: false });
    expect(v2.access_added.reads).toEqual(["email"]);
    expect(v2.changelog).toHaveLength(1);
    const asked = await post(owner.token, "/v1/gallery/installed/update", {
      org_id: orgId,
      type: "routine",
      id: "morning-plan",
    });
    expect(asked.status).toBe(409);
    const p = await j(asked);
    expect(p.code).toBe("access_changed");
    expect(p.errors).toEqual([{ path: "reads", message: "email" }]);
    const ok = await post(owner.token, "/v1/gallery/installed/update", {
      org_id: orgId,
      type: "routine",
      id: "morning-plan",
      accept_access: true,
    });
    expect(await j(ok)).toEqual({ updated: 1, version: 2 });
    const [r] = await h.tdb.admin<{ instructions_md: string; schedule_cron: string }[]>`
      select r.instructions_md, r.schedule_cron from public.routines r
      join public.gallery_links l on l.target_id = r.id::text where l.item_key = 'routine/morning-plan'`;
    // The same answers fill the newer version.
    expect(r?.instructions_md).toContain("inbox for Berlin");
    expect(r?.schedule_cron).toBe("15 6 * * 1-5");
    site.overrides.clear();
    resetGalleryCache();
  });

  it("removes what an item added", async () => {
    const res = await h.request(`/v1/gallery/installed/routine/morning-plan?org_id=${orgId}`, {
      method: "DELETE",
      token: owner.token,
    });
    expect(res.status).toBe(204);
    const [n] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.gallery_links where item_key = 'routine/morning-plan'`;
    expect(n?.n).toBe(0);
  });

  it("enforces the workspace's rules: blocks, and approvals through admins", async () => {
    const policy = await h.request(`/v1/orgs/${orgId}/gallery-policy`, { token: member.token });
    expect(await j(policy)).toEqual({ mode: "open", allow: [], block: [], approval_for: [] });
    const denied = await h.request(`/v1/orgs/${orgId}/gallery-policy`, {
      method: "PUT",
      token: member.token,
      json: { mode: "approval", allow: [], block: [], approval_for: [] },
    });
    expect(denied.status).toBe(403);
    const set = await h.request(`/v1/orgs/${orgId}/gallery-policy`, {
      method: "PUT",
      token: owner.token,
      json: { mode: "approval", allow: [], block: ["skill/proofread"], approval_for: [] },
    });
    expect(set.status).toBe(200);
    // Blocked for everyone, on the old route too.
    const blocked = await post(owner.token, "/v1/skills/install", {
      org_id: orgId,
      gallery_id: "proofread",
    });
    expect(blocked.status).toBe(403);
    expect((await j(blocked)).code).toBe("gallery_blocked");
    // A member asks; admins get it to approve.
    const asked = await post(member.token, "/v1/gallery/install", {
      org_id: orgId,
      type: "skill",
      id: "research-brief",
    });
    expect(asked.status).toBe(202);
    const pending = await j(asked);
    expect(pending.status).toBe("approval_pending");
    const old = await post(member.token, "/v1/skills/install", {
      org_id: orgId,
      gallery_id: "research-brief",
    });
    expect((await j(old)).code).toBe("approval_pending");
    const notes = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.notifications where user_id = ${owner.id} and kind = 'gallery_approval'`;
    expect(notes[0]?.n).toBe(1);
    const list = await j(
      await h.request(`/v1/orgs/${orgId}/gallery-approvals?status=pending`, { token: owner.token }),
    );
    expect(list.items).toHaveLength(1);
    expect(list.items[0]).toMatchObject({
      type: "skill",
      item_id: "research-brief",
      requested_by: member.id,
    });
    expect(
      (
        await post(member.token, `/v1/gallery-approvals/${pending.approval_id}/decision`, {
          decision: "approved",
        })
      ).status,
    ).toBe(403);
    const decided = await j(
      await post(owner.token, `/v1/gallery-approvals/${pending.approval_id}/decision`, {
        decision: "approved",
      }),
    );
    expect(decided.status).toBe("approved");
    const [s] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.skills where org_id = ${orgId} and name = 'research-brief'`;
    expect(s?.n).toBe(1);
    expect(
      (
        await post(owner.token, `/v1/gallery-approvals/${pending.approval_id}/decision`, {
          decision: "denied",
        })
      ).status,
    ).toBe(409);
    await h.request(`/v1/orgs/${orgId}/gallery-policy`, {
      method: "PUT",
      token: owner.token,
      json: { mode: "open", allow: [], block: [], approval_for: [] },
    });
  });

  it("installs a starter set", async () => {
    const set = (await j(await h.request("/v1/gallery/sets", { token: owner.token }))).items[0];
    const res = await post(owner.token, `/v1/gallery/sets/${set.id}/install`, {
      org_id: orgId,
      bot_id: botId,
    });
    expect(res.status).toBe(200);
    const out = await j(res);
    expect(out.items).toHaveLength(set.items.length);
    expect(
      out.items.some((i: { status: string }) => i.status === "installed" || i.status === "skipped"),
    ).toBe(true);
    expect(out.missing).toHaveProperty("apps");
  });

  it("counts looks once per person, and limits the rate", async () => {
    const res = await post(member.token, "/v1/gallery/theme/nightshift/used", {});
    expect(res.status).toBe(204);
    await post(member.token, "/v1/gallery/theme/nightshift/used", {});
    const [n] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.gallery_installs where item_key = 'theme/nightshift'`;
    expect(n?.n).toBe(1);
    // No user id is stored, only a keyed hash.
    const rows = await h.tdb.admin<
      { user_hash: string }[]
    >`select user_hash from public.gallery_installs`;
    expect(rows.some((r) => r.user_hash.includes(member.id))).toBe(false);
    let last = 204;
    for (let i = 0; i < 31; i++)
      last = (await post(outsider.token, "/v1/gallery/theme/lagoon/used", {})).status;
    expect(last).toBe(429);
  });

  it("runs the requests board: dedupes, votes, owner status, reports", async () => {
    const a = await post(owner.token, "/v1/gallery/requests", {
      kind: "skill",
      title: "Recipe planner for the week",
    });
    expect(a.status).toBe(201);
    const first = await j(a);
    const b = await post(member.token, "/v1/gallery/requests", {
      kind: "skill",
      title: "A recipe planner for the week!",
    });
    expect(b.status).toBe(200);
    const same = await j(b);
    expect(same).toMatchObject({ id: first.id, votes: 2, voted: true, mine: false });
    const un = await j(
      await h.request(`/v1/gallery/requests/${first.id}/vote`, {
        method: "DELETE",
        token: member.token,
      }),
    );
    expect(un).toMatchObject({ votes: 1, voted: false });
    const top = await j(await h.request("/v1/gallery/requests?sort=top", { token: member.token }));
    expect(top.items[0].id).toBe(first.id);
    expect(
      (
        await h.request(`/v1/gallery/requests/${first.id}`, {
          method: "PATCH",
          token: member.token,
          json: { status: "planned" },
        })
      ).status,
    ).toBe(403);
    const planned = await j(
      await h.request(`/v1/gallery/requests/${first.id}`, {
        method: "PATCH",
        token: owner.token,
        json: { status: "planned" },
      }),
    );
    expect(planned.status).toBe("planned");
    const rep = await post(member.token, "/v1/reports", {
      target_kind: "gallery_request",
      target_id: first.id,
      reason: "spam",
    });
    expect(rep.status).toBe(200);
    const queue = await j(await h.request("/v1/admin/content-reports", { token: owner.token }));
    const mine = queue.items.find(
      (r: { target_id: string }) => r.target_id === `request/${first.id}`,
    );
    expect(mine.target_kind).toBe("gallery_item");
    for (let i = 0; i < 5; i++)
      await post(outsider.token, "/v1/gallery/requests", {
        kind: "theme",
        title: `Totally different idea ${i} ${"x".repeat(i)}`,
      });
    const limited = await post(outsider.token, "/v1/gallery/requests", {
      kind: "theme",
      title: "One more new thing",
    });
    expect(limited.status).toBe(429);
  });

  it("opens a pull request for a submission and tracks it", async () => {
    await h.tdb.admin`update public.profiles set display_name = 'Ana' where user_id = ${member.id}`;
    const scheme = JSON.parse(
      await readFile(join(galleryRoot, "schemes/orchid/scheme.json"), "utf8"),
    );
    const bad = await post(member.token, "/v1/gallery/submissions", {
      type: "skill",
      item: { name: "Bad", license: "MIT", tags: [] },
      files: { "SKILL.md": "not a skill", "run.sh": "echo hi" },
    });
    expect(bad.status).toBe(400);
    const res = await post(member.token, "/v1/gallery/submissions", {
      type: "scheme",
      id: "ana-orchid",
      item: { name: "Ana orchid", license: "CC0-1.0", tags: ["purple"] },
      files: { "scheme.json": JSON.stringify(scheme) },
      remix_of: { type: "scheme", id: "orchid" },
    });
    expect(res.status).toBe(201);
    const sub = await j(res);
    expect(sub).toMatchObject({
      type: "scheme",
      item_id: "ana-orchid",
      status: "open",
      pr_url: "https://github.com/x/pull/7",
    });
    const pr = github.calls.find((c) => c.method === "POST" && c.path.endsWith("/pulls"));
    expect(String(pr?.body.body)).toContain("Author: Ana");
    expect(String(pr?.body.body)).toContain("casama_user:");
    expect(String(pr?.body.body)).not.toContain("gv2-member@example.com");
    const item = github.calls.find((c) => c.path.endsWith("/ana-orchid/item.json"));
    const written = JSON.parse(Buffer.from(String(item?.body.content), "base64").toString("utf8"));
    expect(written.remix_of).toEqual({ type: "scheme", id: "orchid" });
    expect(written.author.name).toBe("Ana");
    github.merge();
    await h.tdb
      .admin`update public.gallery_submissions set status_checked_at = now() - interval '1 hour'`;
    const mine = await j(await h.request("/v1/gallery/submissions", { token: member.token }));
    expect(mine.items[0].status).toBe("merged");
    await h.tdb
      .admin`insert into public.gallery_item_stats (item_key, installers, installers_7d, active_14d) values ('scheme/ana-orchid', 3, 1, 2)`;
    const items = await j(await h.request("/v1/gallery/me/items", { token: member.token }));
    expect(items.items[0]).toMatchObject({
      type: "scheme",
      id: "ana-orchid",
      stats: { installers: 3, active: 2 },
    });
  });

  it("says submissions are off without a token", async () => {
    const env = h.deps.env as { GALLERY_SUBMIT_TOKEN?: string };
    const token = env.GALLERY_SUBMIT_TOKEN;
    env.GALLERY_SUBMIT_TOKEN = undefined;
    const res = await post(member.token, "/v1/gallery/submissions", {
      type: "theme",
      item: {},
      files: {},
    });
    env.GALLERY_SUBMIT_TOKEN = token;
    expect(res.status).toBe(503);
    expect((await j(res)).code).toBe("submissions_off");
  });

  it("grants contributor rewards once per milestone", async () => {
    expect(parseGalleryRewards('{"250":20,"50":5}')).toEqual([
      { active: 50, usd: 5 },
      { active: 250, usd: 20 },
    ]);
    expect(parseGalleryRewards("off")).toEqual([]);
    const env = { BILLING_ENABLED: true, GALLERY_REWARDS: '{"2":5,"100":20}' };
    // 2 active people on the shown count, but none who qualify: nothing.
    expect(await rewardGalleryContributors(h.handle.db, env)).toBe(0);
    await h.tdb
      .admin`update public.gallery_item_stats set qualified_14d = 2 where item_key = 'scheme/ana-orchid'`;
    expect(await rewardGalleryContributors(h.handle.db, env)).toBe(1);
    expect(await rewardGalleryContributors(h.handle.db, env)).toBe(0);
    const ledger = await h.tdb.admin<{ delta: string; reference: string }[]>`
      select delta::text, reference from public.credit_ledger where reference like 'gallery_reward:%'`;
    expect(ledger).toEqual([
      { delta: "5.000000", reference: "gallery_reward:scheme/ana-orchid:2" },
    ]);
  });

  it("counts only confirmed, week-old people with a succeeded run, never the author, for rewards", async () => {
    const bot = (await j(await post(owner.token, "/v1/bots", { org_id: orgId, name: "Rewards" })))
      .id;
    const key = "bot/reward-check";
    await h.tdb
      .admin`insert into public.gallery_links (org_id, target_kind, target_id, item_key, installed_by)
      values (${orgId}, 'bot', ${bot}, ${key}, ${owner.id})`;
    const fresh = await h.user("gv2-fresh@example.com");
    const young = await h.user("gv2-young@example.com");
    const real = await h.user("gv2-real@example.com");
    const author = await h.user("gv2-author@example.com");
    await h.tdb.admin`update auth.users set email_confirmed_at = now()
      where id in (${young.id}, ${real.id}, ${author.id})`;
    // The server's owner is its first account: keep the owner first.
    await h.tdb
      .admin`update auth.users set created_at = now() - interval '30 days' where id = ${owner.id}`;
    await h.tdb.admin`update auth.users set created_at = now() - interval '8 days'
      where id in (${real.id}, ${author.id})`;
    await h.tdb.admin`insert into public.gallery_submissions (user_id, item_key, name, status)
      values (${author.id}, ${key}, 'Reward check', 'merged')`;
    for (const u of [fresh, young, real, author])
      await h.tdb.admin`insert into public.runs (org_id, bot_id, created_by, status)
        values (${orgId}, ${bot}, ${u.id}, 'completed')`;
    await rollupGalleryStats(h.handle.db, h.deps.env);
    const [s] = await h.tdb.admin<{ active_14d: number; qualified_14d: number }[]>`
      select active_14d, qualified_14d from public.gallery_item_stats where item_key = ${key}`;
    // Everyone shows in the public count; only the confirmed, week-old non-author counts for rewards.
    expect(s).toEqual({ active_14d: 4, qualified_14d: 1 });

    // A look has no run that points at it: a succeeded run after first use counts instead.
    const look = "theme/reward-look";
    for (const u of [young, real, fresh])
      expect((await post(u.token, `/v1/gallery/${look}/used`, {})).status).toBe(204);
    await rollupGalleryStats(h.handle.db, h.deps.env);
    let [l] = await h.tdb.admin<{ qualified_14d: number }[]>`
      select qualified_14d from public.gallery_item_stats where item_key = ${look}`;
    expect(l?.qualified_14d).toBe(0);
    for (const u of [young, real, fresh])
      await h.tdb.admin`insert into public.runs (org_id, bot_id, created_by, status)
        values (${orgId}, ${bot}, ${u.id}, 'completed')`;
    await rollupGalleryStats(h.handle.db, h.deps.env);
    [l] = await h.tdb.admin<{ qualified_14d: number }[]>`
      select qualified_14d from public.gallery_item_stats where item_key = ${look}`;
    expect(l?.qualified_14d).toBe(1);
  });

  it("pays a contributor at most $110 a month and holds the rest for next month", async () => {
    const maker = await h.user("gv2-maker@example.com");
    await post(maker.token, "/v1/orgs", { name: "Maker" });
    await h.tdb
      .admin`update public.gallery_item_stats set qualified_14d = 0 where item_key = 'scheme/ana-orchid'`;
    for (const key of ["skill/cap-a", "skill/cap-b"]) {
      await h.tdb.admin`insert into public.gallery_submissions (user_id, item_key, name, status)
        values (${maker.id}, ${key}, 'Cap', 'merged')`;
      await h.tdb
        .admin`insert into public.gallery_item_stats (item_key, installers, active_14d, qualified_14d)
        values (${key}, 3, 3, 3)`;
    }
    const env = { BILLING_ENABLED: true, GALLERY_REWARDS: '{"1":10,"2":25,"3":75}' };
    const march = new Date("2027-03-10T12:00:00Z");
    // $220 due across two items: $110 (cap-a's three) now, cap-b's held.
    expect(await rewardGalleryContributors(h.handle.db, env, { now: march })).toBe(3);
    expect(await rewardGalleryContributors(h.handle.db, env, { now: march })).toBe(0);
    const paidOf = async () =>
      h.tdb.admin<{ item_key: string; paid: boolean }[]>`
        select item_key, bool_and(paid_at is not null) as paid from public.gallery_rewards
        where user_id = ${maker.id} group by item_key order by item_key`;
    expect(await paidOf()).toEqual([
      { item_key: "skill/cap-a", paid: true },
      { item_key: "skill/cap-b", paid: false },
    ]);
    const [march$] = await h.tdb.admin<{ total: string }[]>`
      select sum(delta)::text as total from public.credit_ledger where reference like 'gallery_reward:skill/cap-%'`;
    expect(Number(march$?.total)).toBe(110);
    // Next month pays what was held.
    const april = new Date("2027-04-01T00:30:00Z");
    expect(await rewardGalleryContributors(h.handle.db, env, { now: april })).toBe(3);
    expect(await paidOf()).toEqual([
      { item_key: "skill/cap-a", paid: true },
      { item_key: "skill/cap-b", paid: true },
    ]);
    const [all$] = await h.tdb.admin<{ total: string }[]>`
      select sum(delta)::text as total from public.credit_ledger where reference like 'gallery_reward:skill/cap-%'`;
    expect(Number(all$?.total)).toBe(220);
  });

  it("rolls up runs of linked routines into run success", async () => {
    const out = await j(
      await post(owner.token, "/v1/gallery/install", {
        org_id: orgId,
        type: "routine",
        id: "weekly-review",
        bot_id: botId,
      }),
    );
    for (const status of ["completed", "failed"])
      await h.tdb.admin`insert into public.runs (org_id, bot_id, routine_id, trigger, status)
        values (${orgId}, ${botId}, ${out.installed.id}, 'routine', ${status})`;
    const r = await rollupGalleryStats(h.handle.db, h.deps.env);
    expect(r.touched).toBeGreaterThan(0);
    const [s] = await h.tdb.admin<{ runs_ok: number; runs_total: number; active_14d: number }[]>`
      select runs_ok, runs_total, active_14d from public.gallery_item_stats where item_key = 'routine/weekly-review'`;
    expect(s).toEqual({ runs_ok: 1, runs_total: 2, active_14d: 1 });
  });

  it("emails monthly picks to people who opted in, with an unsubscribe", async () => {
    const prefs = await j(await h.request("/v1/me/email-preferences", { token: owner.token }));
    expect(prefs).toEqual({ tips: true, gallery_digest: false });
    const on = await h.request("/v1/me/email-preferences", {
      method: "PUT",
      token: owner.token,
      json: { tips: true, gallery_digest: true },
    });
    expect((await j(on)).gallery_digest).toBe(true);
    // Leaving it out keeps it as it is.
    await h.request("/v1/me/email-preferences", {
      method: "PUT",
      token: owner.token,
      json: { tips: true },
    });
    expect(
      (await j(await h.request("/v1/me/email-preferences", { token: owner.token }))).gallery_digest,
    ).toBe(true);
    await h.tdb.admin`update auth.users set email_confirmed_at = now() where id = ${owner.id}`;
    const routines = JSON.parse(await readFile(join(galleryRoot, "routines.json"), "utf8"));
    const newest = routines.items
      .map((i: { added: string }) => i.added)
      .sort()
      .at(-1);
    const now = new Date(`${newest}T12:00:00Z`);
    now.setUTCDate(now.getUTCDate() + 1);
    expect(await queueGalleryDigests(h.handle.db, h.deps.env, { now })).toBe(1);
    expect(await queueGalleryDigests(h.handle.db, h.deps.env, { now })).toBe(1);
    const [q] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.email_outbox where kind = 'gallery_digest'`;
    expect(q?.n).toBe(1);
    h.outbox.length = 0;
    await sendAccountEmails({
      db: h.handle.db,
      email: h.deps.email,
      env: { ...h.deps.env, EMAIL_POSTAL_ADDRESS: "1 Main St", ACCOUNT_EMAILS: true },
    });
    const mail = h.outbox.find((m) => m.subject.includes("gallery"));
    expect(mail?.to).toBe("gv2-owner@example.com");
    const link = /\/v1\/email\/unsubscribe\/[^\s"<>)]+\?list=gallery/.exec(mail?.text ?? "")?.[0];
    expect(link).toBeTruthy();
    await h.request(link as string, { method: "POST" });
    expect(
      (await j(await h.request("/v1/me/email-preferences", { token: owner.token }))).gallery_digest,
    ).toBe(false);
  });

  it("files nightly health findings once", async () => {
    for (const email of ["r1@example.com", "r2@example.com", "r3@example.com"]) {
      const u = await h.user(email);
      await post(u.token, "/v1/reports", {
        target_kind: "gallery_item",
        target_id: "theme/lagoon",
        reason: "spam",
      });
    }
    const local = (async (url: string | URL, init?: RequestInit) =>
      String(url).startsWith(site.url)
        ? fetch(url, init)
        : new Response("", { status: 404 })) as typeof fetch;
    const first = await checkGalleryHealth(h.handle.db, h.deps.env, { fetch: local });
    expect(first.filed).toBeGreaterThan(0);
    const again = await checkGalleryHealth(h.handle.db, h.deps.env, { fetch: local });
    expect(again.filed).toBe(0);
    const rows = await h.tdb.admin<{ reason: string; target_id: string }[]>`
      select reason, target_id from public.content_reports where reporter_id is null`;
    expect(rows.some((r) => r.reason === "health:reports" && r.target_id === "theme/lagoon")).toBe(
      true,
    );
    expect(rows.some((r) => r.reason === "health:app_unreachable")).toBe(true);
    // Older apps read the queue: health reasons show as "other" with the check in the note.
    const queue = await j(await h.request("/v1/admin/content-reports", { token: owner.token }));
    const finding = queue.items.find((r: { note: string | null }) =>
      r.note?.startsWith("health:reports"),
    );
    expect(finding.reason).toBe("other");
  });
});

describe("gallery v2 catalogs", () => {
  const index = (items: unknown[]) => JSON.stringify({ schema: 1, items });
  const look = (id: string, extra: Record<string, unknown> = {}) => ({
    id,
    type: "theme",
    name: id,
    author: { name: "A" },
    license: "CC0-1.0",
    tags: [],
    featured: false,
    retired: false,
    version: 1,
    sha256: "x",
    files: [],
    ...extra,
  });
  const serve = (files: Record<string, string>) =>
    (async (url: string | URL) => {
      const u = new URL(String(url));
      const key = `${u.host}${u.pathname}`;
      return key in files ? new Response(files[key]) : new Response("", { status: 404 });
    }) as typeof fetch;
  const env = (extra: Record<string, string>) =>
    ({
      GALLERY_URL: "https://g.example.org",
      GALLERY_SIGNATURE: "optional",
      GALLERY_SOURCES: "",
      ...extra,
    }) as never;

  it("verifies the signed manifest and each file's hash", async () => {
    const keys = generateGalleryKeyPair();
    const body = index([look("one")]);
    const manifest = JSON.stringify({
      schema: 1,
      created: "2026-11-16",
      files: { "index.json": sha256Hex(body) },
    });
    const sig = signGalleryManifest(manifest, keys.privateKeyPem);
    const files = {
      "g.example.org/index.json": body,
      "g.example.org/manifest.json": manifest,
      "g.example.org/manifest.sig": `${sig}\n`,
    };
    resetGalleryCache();
    const good = await galleryIndex(
      env({ GALLERY_PUBLIC_KEY: keys.publicKeyBase64 }),
      serve(files),
    );
    expect(good.available).toBe(true);
    expect(good.items.map((i) => i.id)).toEqual(["one"]);
    // A file that isn't what the manifest vouches for.
    resetGalleryCache();
    const tampered = await galleryIndex(
      env({ GALLERY_PUBLIC_KEY: keys.publicKeyBase64 }),
      serve({ ...files, "g.example.org/index.json": index([look("evil")]) }),
    );
    expect(tampered.available).toBe(false);
    // A signature by another key: unavailable even in optional mode.
    resetGalleryCache();
    const other = generateGalleryKeyPair();
    const wrong = await galleryIndex(
      env({ GALLERY_PUBLIC_KEY: other.publicKeyBase64 }),
      serve(files),
    );
    expect(wrong.available).toBe(false);
    // No signature: fine when optional, unavailable when required.
    const unsigned = { "g.example.org/index.json": body };
    resetGalleryCache();
    expect(
      (await galleryIndex(env({ GALLERY_PUBLIC_KEY: keys.publicKeyBase64 }), serve(unsigned)))
        .available,
    ).toBe(true);
    resetGalleryCache();
    expect(
      (
        await galleryIndex(
          env({ GALLERY_PUBLIC_KEY: keys.publicKeyBase64, GALLERY_SIGNATURE: "required" }),
          serve(unsigned),
        )
      ).available,
    ).toBe(false);
    // No key for a custom address: not checked.
    resetGalleryCache();
    expect(
      (await galleryIndex(env({ GALLERY_SIGNATURE: "required" }), serve(unsigned))).available,
    ).toBe(true);
    resetGalleryCache();
  });

  it("joins extra catalogs with namespaced ids and drops items too new for this server", async () => {
    const files = {
      "g.example.org/index.json": index([look("one"), look("future", { min_server: "99.0.0" })]),
      "team.example.org/index.json": index([look("one"), look("Bad Id")]),
    };
    resetGalleryCache();
    const got = await galleryIndex(
      env({ GALLERY_SOURCES: "team=https://team.example.org" }),
      serve(files),
    );
    expect(got.items.map((i) => [i.id, i.source ?? null])).toEqual([
      ["one", null],
      ["team:one", "team"],
    ]);
    resetGalleryCache();
  });
});
