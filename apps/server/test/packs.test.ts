/**
 * Packs (docs/PLUGINS-AND-PACKS-PLAN.md): preview, install with answers and secrets, edits kept
 * through an update, reach checks, the gallery's rules and approvals, export with the key scan,
 * share links, removal, the shelf, and plugin settings. GitHub, the gallery and the bot's
 * computer are local fakes; the database is real.
 */
import { once } from "node:events";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { createServer, type IncomingMessage, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import type { ExecChunk, McpServerSpec } from "@casama/sandbox";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { resetGalleryCache } from "../src/services/gallery.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const PACK_DIR = fileURLToPath(new URL("../../../examples/hello-pack", import.meta.url));
const C1 = "a".repeat(40);
const C2 = "b".repeat(40);
let head = C1;
let listed = C1;
let services: Server;
let servicesUrl = "";

/** The example pack's files, path → text. */
function readPack(dir: string, prefix = ""): Map<string, string> {
  const out = new Map<string, string>();
  for (const name of readdirSync(dir)) {
    const full = join(dir, name);
    const rel = prefix ? `${prefix}/${name}` : name;
    if (statSync(full).isDirectory()) for (const [k, v] of readPack(full, rel)) out.set(k, v);
    else out.set(rel, readFileSync(full, "utf8"));
  }
  return out;
}

const v1 = readPack(PACK_DIR);
// The bot brings a rule that narrows and a website it reads.
const bot1 = JSON.parse(v1.get("com.casama/bots/standup.json") as string);
bot1.rules = [{ match_kind: "category", match_value: "send", rule: "ask" }];
bot1.knowledge = [
  { kind: "website", name: "Team handbook", url: "https://handbook.example.com/", max_pages: 30 },
];
v1.set("com.casama/bots/standup.json", JSON.stringify(bot1));
// No gallery includes in the test pack (the fake gallery has no skills).
const packJson = JSON.parse(v1.get("com.casama/pack.json") as string);
packJson.includes = [];
v1.set("com.casama/pack.json", JSON.stringify(packJson));
// The newer version: a reworded persona, a later schedule, and a remote server (reach grows).
const v2 = new Map(v1);
const bot2 = JSON.parse(v1.get("com.casama/bots/standup.json") as string) as typeof bot1;
bot2.persona = `${bot2.persona} Always end with one encouraging line.`;
v2.set("com.casama/bots/standup.json", JSON.stringify(bot2));
const rt2 = JSON.parse(v1.get("com.casama/routines/monday-recap.json") as string);
rt2.schedule_cron = "{{time.minute}} {{time.hour}} * * 1,5";
v2.set("com.casama/routines/monday-recap.json", JSON.stringify(rt2));
const mcp2 = JSON.parse(v1.get("mcp.json") as string);
mcp2.mcpServers.search = { type: "streamable-http", url: "https://search.example.com/mcp" };
v2.set("mcp.json", JSON.stringify(mcp2));
const plugin2 = JSON.parse(v1.get("plugin.json") as string);
plugin2.version = "1.1.0";
v2.set("plugin.json", JSON.stringify(plugin2));
const versions: Record<string, Map<string, string>> = { [C1]: v1, [C2]: v2 };

const PACK_URL = "https://github.com/acme/packs/tree/main/hello-pack";

// Two starter sets: one with the same id as the pack (a pack replaces it on the shelf), one not.
const gallerySet = (id: string, featured: boolean) => ({
  id,
  type: "set",
  name: id === "hello-pack" ? "Hello set" : "Zebra set",
  author: { name: "Casama" },
  license: "CC0-1.0",
  tags: [],
  featured,
  retired: false,
  version: 1,
  description: "A starter set",
  document: {
    description: "A starter set",
    icon: "rocket",
    items: [
      { type: "skill", id: "decision-memo" },
      { type: "skill", id: "write-spec" },
    ],
  },
});
const gallerySetsDoc = {
  schema: 1,
  items: [gallerySet("hello-pack", true), gallerySet("zebra-set", true)],
};

const galleryPlugins = () =>
  JSON.stringify({
    schema: 1,
    items: [
      {
        id: "hello-pack",
        type: "plugin",
        name: "Hello pack",
        author: { name: "Casama" },
        license: "Apache-2.0",
        tags: [],
        featured: true,
        retired: false,
        version: 1,
        pick: "A good first pack",
        description: "An example pack",
        access: { runs_code: true, computer: true },
        document: {
          description: "An example pack",
          url: PACK_URL,
          commit: listed,
          icon: "megaphone",
          adds: ["A stand-up bot"],
        },
      },
    ],
  });

const computer = {
  servers: {} as Record<string, McpServerSpec>,
  files: new Map<string, Uint8Array>(),
};
const handle = {
  ref: "fake-computer",
  async *exec(cmd: string): AsyncIterable<ExecChunk> {
    yield { type: "stdout", data: cmd.startsWith("printf") ? "/home/casama" : "" };
    yield { type: "exit", code: 0, timedOut: false, killed: false, truncated: false };
  },
  readFile: async (p: string) => {
    const f = computer.files.get(p);
    if (!f) throw new Error("not found");
    return f;
  },
  writeFile: async (p: string, d: Uint8Array) => void computer.files.set(p, d),
  setMcpServers: async (s: Record<string, McpServerSpec>) => void (computer.servers = s),
  // The notes server answers MCP with no tools: enough to start a session and list.
  mcpFetch: async (_url: string | URL, init?: RequestInit) => {
    const msg = JSON.parse(String(init?.body ?? "{}")) as { id?: number; method?: string };
    if (msg.id === undefined) return new Response(null, { status: 202 });
    const result =
      msg.method === "initialize"
        ? {
            protocolVersion: "2025-06-18",
            capabilities: { tools: {} },
            serverInfo: { name: "notes", version: "1.0.0" },
          }
        : { tools: [] };
    return new Response(JSON.stringify({ jsonrpc: "2.0", id: msg.id, result }), {
      headers: { "content-type": "application/json" },
    });
  },
};

let h: Harness;
let owner: { id: string; token: string };
let member: { id: string; token: string };
let orgId: string;
let cred: string;

const post = (token: string, path: string, json: unknown) =>
  h.request(path, { method: "POST", token, json });

const setPolicy = async (policy: unknown) => {
  const res = await h.request(`/v1/orgs/${orgId}/gallery-policy`, {
    method: "PUT",
    token: owner.token,
    json: policy,
  });
  expect(res.status, await res.clone().text()).toBe(200);
};

const filesOf = (m: Map<string, string>, rename?: string) =>
  [...m].map(([path, text]) => {
    let t = text;
    if (rename && path === "plugin.json") {
      const p = JSON.parse(text);
      p.name = rename;
      t = JSON.stringify(p);
    }
    return { path, base64: Buffer.from(t).toString("base64") };
  });

beforeAll(async () => {
  services = createServer(async (req: IncomingMessage, res) => {
    for await (const _ of req);
    const url = new URL(req.url ?? "/", "http://x");
    const send = (v: unknown, status = 200) =>
      res.writeHead(status, { "content-type": "application/json" }).end(JSON.stringify(v));
    if (url.pathname === "/gallery/plugins.json")
      return res.writeHead(200, { "content-type": "application/json" }).end(galleryPlugins());
    if (url.pathname === "/gallery/sets.json") return send(gallerySetsDoc);
    if (url.pathname === "/repos/acme/packs") return send({ default_branch: "main" });
    if (url.pathname === "/repos/acme/packs/commits/main") return send({ sha: head });
    const t = /^\/repos\/acme\/packs\/git\/trees\/([0-9a-f]{40})$/.exec(url.pathname);
    if (t?.[1] && versions[t[1]])
      return send({
        tree: [...(versions[t[1]] as Map<string, string>)].map(([path, text]) => ({
          path: `hello-pack/${path}`,
          type: "blob",
          sha: `${t[1]}-${Buffer.from(path).toString("hex")}`,
          size: text.length,
          mode: "100644",
        })),
        truncated: false,
      });
    const b = /^\/repos\/acme\/packs\/git\/blobs\/([0-9a-f]{40})-([0-9a-f]+)$/.exec(url.pathname);
    if (b?.[1] && b[2]) {
      const text = versions[b[1]]?.get(Buffer.from(b[2], "hex").toString());
      if (text !== undefined)
        return send({ content: Buffer.from(text).toString("base64"), encoding: "base64" });
    }
    send({}, 404);
  }).listen(0, "127.0.0.1");
  await once(services, "listening");
  servicesUrl = `http://127.0.0.1:${(services.address() as AddressInfo).port}`;
  resetGalleryCache();
  h = await startHarness({
    env: {
      GITHUB_API_URL: servicesUrl,
      GALLERY_URL: `${servicesUrl}/gallery`,
      GALLERY_SIGNATURE: "off",
      GALLERY_STATS_URL: "off",
      INSTANCE_ADMIN_EMAILS: "packs@example.com",
    },
  });
  (h.deps as { computers?: unknown }).computers = {
    ensureRunning: async () => handle,
    byId: async () => ({ state: "running" }),
  };
  owner = await h.user("packs@example.com");
  member = await h.user("packs-member@example.com");
  orgId = (await j(await post(owner.token, "/v1/orgs", { name: "Packs" }))).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
  cred = (
    await j(
      await post(owner.token, "/v1/credentials", {
        org_id: orgId,
        provider: "openrouter",
        label: "k",
        api_key: "sk-or-v1-abcdefabcdef",
      }),
    )
  ).id;
}, 60_000);

afterAll(async () => {
  await h?.stop();
  services?.close();
});

describe("packs", () => {
  let packId: string;
  let botId: string;

  it("previews everything a pack brings, reviewed when the directory lists that commit", async () => {
    const res = await post(owner.token, "/v1/packs/preview", { org_id: orgId, url: PACK_URL });
    const p = await j(res);
    expect(res.status, JSON.stringify(p)).toBe(200);
    expect(p).toMatchObject({
      name: "hello-pack",
      version: "1.0.0",
      summary: expect.stringContaining("stand-up"),
      icon: "megaphone",
      reviewed: true,
      commit: C1,
      installed: null,
      source: { kind: "gallery", gallery_id: "hello-pack", repo: "acme/packs" },
    });
    expect(p.bots).toHaveLength(1);
    expect(p.bots[0]).toMatchObject({ id: "standup", name: "Stand-up", mascot: "focused" });
    expect(p.routines[0]).toMatchObject({ id: "monday-recap", bot: "standup", runs_per_week: 1 });
    const scopes = Object.fromEntries(
      p.skills.map((s: { name: string; scope: string }) => [s.name, s.scope]),
    );
    expect(scopes).toEqual({ "house-style": "workspace", "team-standup": "bot" });
    expect(p.apps[0]).toMatchObject({ id: "hello-pack.deepwiki", host: "mcp.deepwiki.com" });
    expect(p.looks[0]).toMatchObject({ type: "theme" });
    expect(p.needs_apps).toEqual([{ id: "notion", name: "Notion" }]);
    expect(p.settings.map((s: { name: string }) => s.name)).toEqual(["NOTES_FOLDER"]);
    expect(p.secrets.map((s: { name: string }) => s.name)).toEqual(["NOTES_SIGNATURE"]);
    expect(p.reach).toMatchObject({
      runs_code: true,
      computer: true,
      knowledge_sources: 1,
      knowledge_pages: 30,
    });
    expect(p.reach.hosts).toContain("handbook.example.com");
    expect(p.bots[0].rules).toEqual([{ match_kind: "category", match_value: "send", rule: "ask" }]);
  });

  it("refuses a plain plugin and someone outside the workspace", async () => {
    const plain = new Map([...v1].filter(([k]) => !k.startsWith("com.casama/")));
    const res = await post(owner.token, "/v1/packs/preview", {
      org_id: orgId,
      files: filesOf(plain),
    });
    expect(res.status).toBe(400);
    expect((await j(res)).code).toBe("pack_not_a_pack");
    const stranger = await h.user("packs-stranger@example.com");
    expect(
      (await post(stranger.token, "/v1/packs/preview", { org_id: orgId, url: PACK_URL })).status,
    ).toBe(404);
  });

  it("installs bots, skills, routines, tools, apps and looks with the person's answers", async () => {
    const res = await post(owner.token, "/v1/packs", {
      org_id: orgId,
      url: PACK_URL,
      commit: C1,
      inputs: { team: "Rocket", time: "08:30" },
      secrets: { NOTES_SIGNATURE: "— Rocket" },
    });
    const r = await j(res);
    expect(res.status, JSON.stringify(r)).toBe(201);
    packId = r.pack.id;
    const status = Object.fromEntries(
      r.items.map((i: { kind: string; id: string; status: string }) => [
        `${i.kind}:${i.id}`,
        i.status,
      ]),
    );
    expect(status).toMatchObject({
      "bot:standup": "installed",
      "skill:team-standup": "installed",
      "skill:house-style": "installed",
      "routine:monday-recap": "installed",
      "tools:tools": "installed",
      "app:deepwiki": "installed",
      "look:theme/standup-orange": "device",
    });
    expect(r.looks).toHaveLength(1);
    expect(r.missing.apps.map((a: { id: string }) => a.id).sort()).toEqual([
      "hello-pack.deepwiki",
      "notion",
    ]);
    botId = r.items.find((i: { kind: string }) => i.kind === "bot").target_id;
    const [bot] = await h.tdb.admin<
      { persona_md: string; avatar_url: string; autonomy: string }[]
    >`select persona_md, avatar_url, autonomy::text from public.bots where id = ${botId}`;
    expect(bot?.persona_md).toContain("Rocket");
    expect(bot?.avatar_url).toBe("mascot:focused");
    expect(bot?.autonomy).toBe("ask_risky");
    const [rule] = await h.tdb.admin<{ match_value: string; rule: string }[]>`
      select match_value, rule from public.action_rules where bot_id = ${botId}`;
    expect(rule).toEqual({ match_value: "send", rule: "ask" });
    const [ks] = await h.tdb.admin<{ kind: string; name: string }[]>`
      select kind, name from public.knowledge_sources where bot_id = ${botId}`;
    expect(ks).toEqual({ kind: "website", name: "Team handbook" });
    const [rt] = await h.tdb.admin<
      { schedule_cron: string; enabled: boolean; bot_id: string }[]
    >`select schedule_cron, enabled, bot_id from public.routines where bot_id = ${botId}`;
    expect(rt).toMatchObject({ schedule_cron: "30 8 * * 1", enabled: true });
    const skills = await h.tdb.admin<{ name: string; bot_id: string | null }[]>`
      select name, bot_id from public.skills where org_id = ${orgId} order by name`;
    expect(skills).toEqual([
      { name: "house-style", bot_id: null },
      { name: "team-standup", bot_id: botId },
    ]);
    // The tools are an ordinary plugin row on the bot, marked with the pack, without the skills.
    const [pl] = await h.tdb.admin<{ id: string; pack_id: string }[]>`
      select id, pack_id from public.plugins where bot_id = ${botId}`;
    expect(pl?.pack_id).toBe(packId);
    const [cfg] = await h.tdb.admin<{ config: { env: Record<string, string> } }[]>`
      select config from public.integrations where plugin_id = ${pl?.id as string}`;
    expect(cfg?.config.env.NOTES_FOLDER).toBe("notes");
    expect(JSON.stringify(cfg?.config)).not.toContain("Rocket");
    const [n] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.skills where plugin_id = ${pl?.id as string}`;
    expect(n?.n).toBe(0);
    // The pack's app shows up in this workspace's catalog only.
    const apps = await j(await h.request(`/v1/apps?org_id=${orgId}`, { token: owner.token }));
    expect(apps.apps.some((a: { id: string }) => a.id === "hello-pack.deepwiki")).toBe(true);
    const plainApps = await j(await h.request("/v1/apps", { token: owner.token }));
    expect(plainApps.apps.some((a: { id: string }) => a.id === "hello-pack.deepwiki")).toBe(false);
  });

  it("won't install the same pack twice, and lists it", async () => {
    const again = await post(owner.token, "/v1/packs", {
      org_id: orgId,
      url: PACK_URL,
      commit: C1,
    });
    expect(again.status).toBe(409);
    const list = await j(await h.request(`/v1/packs?org_id=${orgId}`, { token: member.token }));
    expect(list.items.map((p: { name: string }) => p.name)).toEqual(["hello-pack"]);
    expect(list.items[0].items.every((i: { edited: boolean }) => !i.edited)).toBe(true);
  });

  it("changes a plugin's plain settings without touching its secrets", async () => {
    const [pl] = await h.tdb.admin<{ id: string }[]>`
      select id from public.plugins where pack_id = ${packId}`;
    const res = await h.request(`/v1/plugins/${pl?.id}/settings`, {
      method: "PATCH",
      token: owner.token,
      json: { settings: { NOTES_FOLDER: "standups" } },
    });
    const p = await j(res);
    expect(res.status, JSON.stringify(p)).toBe(200);
    expect(p.settings).toEqual([
      expect.objectContaining({ name: "NOTES_FOLDER", value: "standups" }),
    ]);
    expect(p.pack_name).toBe("Hello pack");
    const bad = await h.request(`/v1/plugins/${pl?.id}/settings`, {
      method: "PATCH",
      token: owner.token,
      json: { settings: { NOPE: "x" } },
    });
    expect(bad.status).toBe(400);
  });

  it("an update shows a diff, asks when reach grows, and keeps what the person edited", async () => {
    await h.tdb.admin`update public.bots set persona_md = 'My own words.' where id = ${botId}`;
    head = C2;
    // The directory reviews the newer commit.
    listed = C2;
    resetGalleryCache();
    const u = await j(await h.request(`/v1/packs/${packId}/update`, { token: owner.token }));
    expect(u).toMatchObject({
      up_to_date: false,
      can_check: true,
      from_version: "1.0.0",
      reach_grew: true,
      edited: [{ kind: "bot", id: "standup" }],
    });
    expect(u.to_commit).toBe(C2);
    expect(u.bots.changed.map((c: { id: string }) => c.id)).toEqual(["standup"]);
    expect(u.servers.added).toEqual(["search"]);
    expect(u.schedules_changed).toEqual(["monday-recap"]);
    const res = await h.request(`/v1/packs/${packId}/update`, {
      method: "POST",
      token: owner.token,
      json: { commit: C2 },
    });
    expect(res.status).toBe(409);
    expect((await j(res)).code).toBe("pack_reach_grew");
    const ok = await h.request(`/v1/packs/${packId}/update`, {
      method: "POST",
      token: owner.token,
      json: { commit: C2, confirm_reach: true },
    });
    const r = await j(ok);
    expect(ok.status, JSON.stringify(r)).toBe(200);
    expect(r.pack).toMatchObject({ version: "1.1.0", commit: C2, reviewed: true });
    const [bot] = await h.tdb.admin<{ persona_md: string }[]>`
      select persona_md from public.bots where id = ${botId}`;
    expect(bot?.persona_md).toBe("My own words.");
    const [rt] = await h.tdb.admin<{ schedule_cron: string }[]>`
      select schedule_cron from public.routines where bot_id = ${botId}`;
    expect(rt?.schedule_cron).toBe("30 8 * * 1,5");
    // The secret and the changed setting carried over; the new server is there.
    const ints = await h.tdb.admin<{ config: { server: string; env?: Record<string, string> } }[]>`
      select i.config from public.integrations i join public.plugins p on p.id = i.plugin_id where p.pack_id = ${packId}`;
    expect(ints.map((i) => i.config.server).sort()).toEqual(["notes", "search"]);
    expect(ints.find((i) => i.config.server === "notes")?.config.env?.NOTES_FOLDER).toBe(
      "standups",
    );
    const [sec] = await h.tdb.admin<{ secret: string }[]>`
      select v.decrypted_secret as secret from public.integrations i join public.plugins p on p.id = i.plugin_id
      join vault.decrypted_secrets v on v.id = i.vault_secret_id where p.pack_id = ${packId}`;
    expect(sec?.secret).toContain("Rocket");
  });

  it("follows the gallery's rules: a member's pack waits for an admin, who installs it", async () => {
    await setPolicy({ mode: "open", allow: [], block: [], approval_for: ["runs_code"] });
    const res = await post(member.token, "/v1/packs", {
      org_id: orgId,
      files: filesOf(v1, "team-pack"),
      skip: [{ kind: "skill", id: "house-style" }],
    });
    const r = await j(res);
    expect(res.status, JSON.stringify(r)).toBe(202);
    expect(r.status).toBe("approval_pending");
    const list = await j(
      await h.request(`/v1/orgs/${orgId}/gallery-approvals`, { token: owner.token }),
    );
    const a = list.items.find((x: { id: string }) => x.id === r.approval_id);
    expect(a).toMatchObject({ type: "plugin", pack: true, name: "team-pack" });
    const d = await post(owner.token, `/v1/gallery-approvals/${r.approval_id}/decision`, {
      decision: "approved",
    });
    const dj = await j(d);
    expect(d.status, JSON.stringify(dj)).toBe(200);
    expect(dj.status).toBe("approved");
    const packs = await j(await h.request(`/v1/packs?org_id=${orgId}`, { token: owner.token }));
    expect(packs.items.map((p: { name: string }) => p.name)).toContain("team-pack");
    const team = packs.items.find((p: { name: string }) => p.name === "team-pack");
    expect(team.source.kind).toBe("upload");
    // Unreviewed: its routine starts off.
    const routineId = team.items.find((i: { kind: string }) => i.kind === "routine").target_id;
    const [rt] = await h.tdb.admin<{ enabled: boolean }[]>`
      select enabled from public.routines where id = ${routineId}`;
    expect(rt?.enabled).toBe(false);
    await setPolicy({ mode: "open", allow: [], block: [], approval_for: [] });
  });

  it("a plugin link follows the rules too, and approving lets the person add it", async () => {
    await setPolicy({ mode: "open", allow: [], block: ["repo/acme:packs"], approval_for: [] });
    const res = await post(owner.token, "/v1/plugins", {
      org_id: orgId,
      bot_id: botId,
      url: "https://github.com/acme/packs/tree/main/hello-pack",
      // Not the directory's commit, so it's a plain link.
      commit: C1,
    });
    expect(res.status).toBe(403);
    expect((await j(res)).code).toBe("gallery_blocked");
    await setPolicy({ mode: "open", allow: [], block: [], approval_for: [] });
  });

  it("exports bots as a pack, catches keys, and shares it behind a link", async () => {
    await h.tdb.admin`
      update public.skills set body_md = body_md || ${"\nUse key sk-ant-abcdefghijklmnopqrstuvwxyz0123 for the API."}
      where bot_id = ${botId} and name = 'team-standup'`;
    const body = { name: "My Stand-up Kit", summary: "Our stand-up bot", bot_ids: [botId] };
    const ex = await j(await post(owner.token, `/v1/orgs/${orgId}/packs/export`, body));
    expect(ex.name).toBe("my-stand-up-kit");
    const paths = ex.files.map((f: { path: string }) => f.path);
    expect(paths).toContain("com.casama/pack.json");
    expect(paths).toContain("plugin.json");
    expect(paths.some((p: string) => p.startsWith("com.casama/bots/"))).toBe(true);
    expect(paths).toContain("skills/team-standup/SKILL.md");
    expect(ex.findings).toEqual([
      expect.objectContaining({ path: "skills/team-standup/SKILL.md", what: expect.any(String) }),
    ]);
    const refused = await post(owner.token, `/v1/orgs/${orgId}/packs/share`, body);
    expect(refused.status).toBe(409);
    expect((await j(refused)).code).toBe("pack_has_secrets");
    const shared = await post(owner.token, `/v1/orgs/${orgId}/packs/share`, {
      ...body,
      ignore_findings: true,
    });
    const s = await j(shared);
    expect(shared.status, JSON.stringify(s)).toBe(201);
    expect(s.url).toContain(`/packs/share/${s.token}`);
    const stranger = await h.user("packs-viewer@example.com");
    const view = await j(await h.request(`/v1/pack-shares/${s.token}`, { token: stranger.token }));
    expect(view.preview).toMatchObject({ name: "my-stand-up-kit", reviewed: false });
    expect(view.preview.bots[0].name).toBe("Stand-up");
    // The exported pack checks as a pack: preview it by token in another workspace.
    const otherOrg = (await j(await post(stranger.token, "/v1/orgs", { name: "Other" }))).id;
    const pv = await post(stranger.token, "/v1/packs/preview", {
      org_id: otherOrg,
      share_token: s.token,
    });
    expect(pv.status).toBe(200);
    expect(
      (await h.request(`/v1/pack-shares/${s.token}`, { method: "DELETE", token: stranger.token }))
        .status,
    ).toBe(404);
    expect(
      (await h.request(`/v1/pack-shares/${s.token}`, { method: "DELETE", token: owner.token }))
        .status,
    ).toBe(200);
    expect((await h.request(`/v1/pack-shares/${s.token}`, { token: stranger.token })).status).toBe(
      404,
    );
  });

  it("a shared pack can be reported, and taking it down ends the link", async () => {
    const s = await j(
      await post(owner.token, `/v1/orgs/${orgId}/packs/share`, {
        name: "Reported kit",
        summary: "To report",
        bot_ids: [botId],
        ignore_findings: true,
      }),
    );
    const viewer = await h.user("packs-reporter@example.com");
    const view = await j(await h.request(`/v1/pack-shares/${s.token}`, { token: viewer.token }));
    const rep = await post(viewer.token, "/v1/reports", {
      target_kind: "pack_share",
      target_id: view.id,
      reason: "spam",
    });
    expect(rep.status, await rep.clone().text()).toBe(200);
    const queue = await j(await h.request("/v1/admin/content-reports", { token: owner.token }));
    const item = queue.items.find(
      (r: { target_id: string }) => r.target_id === `pack_share/${view.id}`,
    );
    expect(item).toMatchObject({ target_kind: "gallery_item" });
    const done = await h.request(`/v1/admin/content-reports/${item.id}`, {
      method: "POST",
      token: owner.token,
      json: { decision: "actioned" },
    });
    expect(done.status, await done.clone().text()).toBe(200);
    expect((await h.request(`/v1/pack-shares/${s.token}`, { token: viewer.token })).status).toBe(
      404,
    );
  });

  it("removing a pack takes its tools and untouched items and leaves what was edited", async () => {
    const res = await h.request(`/v1/packs/${packId}`, { method: "DELETE", token: owner.token });
    const r = await j(res);
    expect(res.status, JSON.stringify(r)).toBe(200);
    expect(r.deleted).toBe(packId);
    // The bot is kept (default) and the skill edited above stays; the rest goes.
    expect(r.kept).toBe(2);
    const [n] = await h.tdb.admin<{ plugins: number; routines: number; bots: number }[]>`
      select (select count(*)::int from public.plugins where bot_id = ${botId}) as plugins,
             (select count(*)::int from public.routines where bot_id = ${botId}) as routines,
             (select count(*)::int from public.bots where id = ${botId} and archived_at is null) as bots`;
    expect(n).toEqual({ plugins: 0, routines: 0, bots: 1 });
    const skills = await h.tdb.admin<{ name: string }[]>`
      select name from public.skills where org_id = ${orgId} and (bot_id = ${botId} or bot_id is null) order by name`;
    expect(skills.map((s) => s.name)).toEqual(["team-standup"]);
  });

  it("the shelf lists reviewed packs with what's inside", async () => {
    const shelf = await j(await h.request("/v1/gallery/packs", { token: member.token }));
    const p = shelf.items.find((x: { id: string }) => x.id === "hello-pack");
    expect(p).toMatchObject({
      kind: "pack",
      reviewed: true,
      featured: true,
      commit: C2,
      contents: { bots: 1, skills: 2, routines: 1, apps: 1, looks: 1, tools: 2 },
    });
    // The pack replaces the set with its id; packs come before the other sets, featured or not.
    const ids = shelf.items.map((x: { kind: string; id: string }) => `${x.kind}/${x.id}`);
    expect(ids).toEqual(["pack/hello-pack", "set/zebra-set"]);
  });

  it("the three first-party packs install", async () => {
    for (const name of ["founder-kit", "dev-kit", "meetings-handled"]) {
      const dir = fileURLToPath(new URL(`../../../packs/${name}`, import.meta.url));
      const res = await post(owner.token, "/v1/packs", {
        org_id: orgId,
        files: filesOf(readPack(dir)),
      });
      const r = await j(res);
      expect(res.status, JSON.stringify(r)).toBe(201);
      const bad = r.items.filter(
        (i: { kind: string; status: string }) => i.kind !== "include" && i.status === "failed",
      );
      expect(bad, name).toEqual([]);
      expect(r.items.filter((i: { kind: string }) => i.kind === "bot")).toHaveLength(1);
    }
  });

  it("a gallery plugin installs through the plugins route", async () => {
    const other = await j(
      await post(owner.token, "/v1/bots", {
        org_id: orgId,
        name: "Second",
        model_policy: { primary: { credential_id: cred, model: "m" } },
      }),
    );
    const res = await post(owner.token, "/v1/gallery/install", {
      org_id: orgId,
      type: "plugin",
      id: "hello-pack",
      bot_id: other.id,
    });
    const r = await j(res);
    // It asks for its secret: the call reached the plugins route (it used to 404).
    expect(r.code ?? r.status, JSON.stringify(r)).toBe("plugin_secrets_missing");
  });
});
