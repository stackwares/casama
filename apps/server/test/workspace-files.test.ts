/** Routines and skills as files (D-124): export, import, and git sync both ways with conflicts. */
import { createHash, createHmac } from "node:crypto";
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { syncWorkspaceRepo } from "@kasama/agent";
import { strToU8, unzipSync, zipSync } from "fflate";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

/** A tiny in-memory GitHub repository (git data API + pulls). */
const repo = {
  blobs: new Map<string, Buffer>(),
  trees: new Map<string, Map<string, string>>(),
  commits: new Map<string, { tree: string; parents: string[] }>(),
  refs: new Map<string, string>(),
  pulls: [] as Array<{ head: string; base: string; title: string }>,
};
const blobSha = (b: Buffer) => createHash("sha1").update(`blob ${b.length}\0`).update(b).digest("hex");
const putTree = (m: Map<string, string>) => {
  const sha = createHash("sha1").update(JSON.stringify([...m].sort())).digest("hex");
  repo.trees.set(sha, m);
  return sha;
};
const putCommit = (tree: string, parents: string[]) => {
  const sha = createHash("sha1").update(`${tree}${parents.join()}${Math.random()}`).digest("hex");
  repo.commits.set(sha, { tree, parents });
  return sha;
};
const filesAt = (ref = "main") => {
  const c = repo.commits.get(repo.refs.get(ref) as string);
  const t = repo.trees.get(c?.tree as string) ?? new Map();
  return new Map([...t].map(([p, s]) => [p, (repo.blobs.get(s) as Buffer).toString()]));
};
/** Someone pushing to the repo. */
const pushToRepo = (changes: Record<string, string | null>) => {
  const head = repo.refs.get("main") as string;
  const m = new Map(repo.trees.get(repo.commits.get(head)?.tree as string));
  for (const [p, v] of Object.entries(changes)) {
    if (v === null) m.delete(p);
    else {
      const b = Buffer.from(v);
      repo.blobs.set(blobSha(b), b);
      m.set(p, blobSha(b));
    }
  }
  repo.refs.set("main", putCommit(putTree(m), [head]));
};
repo.refs.set("main", putCommit(putTree(new Map()), []));

let gh: Server;
let ghUrl = "";
let h: Harness;
let owner: { id: string; token: string };
let member: { id: string; token: string };
let orgId: string;
let botId: string;

beforeAll(async () => {
  gh = createServer(async (req, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    const body = chunks.length ? JSON.parse(Buffer.concat(chunks).toString()) : {};
    const send = (v: unknown, s = 200) => res.writeHead(s, { "content-type": "application/json" }).end(JSON.stringify(v));
    if (req.headers.authorization !== "Bearer ghp-test") return send({}, 401);
    const u = new URL(req.url ?? "/", "http://x").pathname.replace("/repos/acme/kasama-config", "");
    let m: RegExpExecArray | null;
    if ((m = /^\/git\/ref\/heads\/(.+)$/.exec(u))) return repo.refs.has(m[1] as string) ? send({ object: { sha: repo.refs.get(m[1] as string) } }) : send({}, 404);
    if ((m = /^\/git\/commits\/(\w+)$/.exec(u))) return send({ tree: { sha: repo.commits.get(m[1] as string)?.tree } });
    if ((m = /^\/git\/trees\/(\w+)$/.exec(u)))
      return send({ tree: [...(repo.trees.get(m[1] as string) ?? [])].map(([path, sha]) => ({ path, sha, type: "blob" })) });
    if ((m = /^\/git\/blobs\/(\w+)$/.exec(u))) return send({ content: repo.blobs.get(m[1] as string)?.toString("base64"), encoding: "base64" });
    if (u === "/git/trees" && req.method === "POST") {
      const t = new Map(repo.trees.get(body.base_tree));
      for (const e of body.tree as Array<{ path: string; content?: string; sha?: null }>) {
        if (e.sha === null) t.delete(e.path);
        else {
          const b = Buffer.from(e.content as string);
          repo.blobs.set(blobSha(b), b);
          t.set(e.path, blobSha(b));
        }
      }
      return send({ sha: putTree(t) }, 201);
    }
    if (u === "/git/commits" && req.method === "POST") return send({ sha: putCommit(body.tree, body.parents) }, 201);
    if ((m = /^\/git\/refs\/heads\/(.+)$/.exec(u)) && req.method === "PATCH") {
      repo.refs.set(m[1] as string, body.sha);
      return send({});
    }
    if (u === "/git/refs" && req.method === "POST") {
      repo.refs.set(String(body.ref).replace("refs/heads/", ""), body.sha);
      return send({}, 201);
    }
    if (u === "/pulls" && req.method === "POST") {
      repo.pulls.push(body);
      return send({ html_url: `https://github.com/acme/kasama-config/pull/${repo.pulls.length}` }, 201);
    }
    send({}, 404);
  }).listen(0, "127.0.0.1");
  await once(gh, "listening");
  ghUrl = `http://127.0.0.1:${(gh.address() as AddressInfo).port}`;
  h = await startHarness();
  owner = await h.user("files@example.com");
  member = await h.user("files-member@example.com");
  orgId = (await j(await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "F" } }))).id;
  await h.tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
    }),
  );
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Ada", model_policy: { primary: { credential_id: cred.id, model: "m" } } },
      }),
    )
  ).id;
  await h.tdb.admin`insert into public.routines (org_id, bot_id, name, instructions_md, schedule_cron, timezone, trigger, next_run_at)
    values (${orgId}, ${botId}, 'Morning brief', 'Send my brief.', '0 7 * * *', 'Asia/Manila', '{"type":"schedule"}', now())`;
  await h.tdb.admin`insert into public.skills (org_id, bot_id, name, description, body_md) values (${orgId}, ${botId}, 'pr-labels', 'Label PRs', 'Read the diff.')`;
  await h.tdb.admin`insert into public.secrets (org_id, name, vault_secret_id, allowed_hosts)
    values (${orgId}, 'GITHUB_TOKEN', (select vault.create_secret('ghp-test', null, 'gh')), '{api.github.com}')`;
}, 60_000);
afterAll(async () => {
  await h?.stop();
  gh?.close();
});

const sync = () => syncWorkspaceRepo({ db: h.handle.db, fetch, apiUrl: ghUrl }, orgId);
const routine = async () =>
  (await h.tdb.admin<{ schedule_cron: string; instructions_md: string }[]>`select schedule_cron, instructions_md from public.routines where name = 'Morning brief'`)[0];

describe("routines and skills as files", () => {
  it("exports Markdown files and imports changes back, with a dry run first", async () => {
    expect((await h.request(`/v1/orgs/${orgId}/files/export`, { method: "POST", token: member.token })).status).toBe(403);
    const ex = await j(await h.request(`/v1/orgs/${orgId}/files/export`, { method: "POST", token: owner.token }));
    const files = unzipSync(Buffer.from(ex.zip_base64, "base64"));
    expect(Object.keys(files).sort()).toEqual(["ada/routines/morning-brief.md", "ada/skills/pr-labels/SKILL.md", "kasama.json"]);
    const md = Buffer.from(files["ada/routines/morning-brief.md"] as Uint8Array).toString();
    expect(md).toContain('schedule: "0 7 * * *"');
    expect(md).toContain("timezone: Asia/Manila");

    files["ada/routines/morning-brief.md"] = strToU8(md.replace("0 7 * * *", "30 7 * * 1-5"));
    files["ada/routines/weekly.md"] = strToU8("---\nname: Weekly review\nschedule: 0 16 * * 5\n---\nReview my week.");
    files["ada/routines/bad.md"] = strToU8("---\nname: Bad\nschedule: whenever\n---\nx");
    files["nobody/routines/x.md"] = strToU8("---\nname: X\nschedule: 0 1 * * *\n---\nx");
    const zip = Buffer.from(zipSync(files)).toString("base64");
    const dry = await j(await h.request(`/v1/orgs/${orgId}/files/import`, { method: "POST", token: owner.token, json: { zip_base64: zip, dry_run: true } }));
    expect(dry).toMatchObject({ created: ["ada/routines/weekly.md"], updated: ["ada/routines/morning-brief.md"], unchanged: 1, dry_run: true });
    expect(dry.errors).toHaveLength(2);
    expect((await routine())?.schedule_cron).toBe("0 7 * * *");
    const real = await j(await h.request(`/v1/orgs/${orgId}/files/import`, { method: "POST", token: owner.token, json: { zip_base64: zip } }));
    expect(real.updated).toEqual(["ada/routines/morning-brief.md"]);
    expect((await routine())?.schedule_cron).toBe("30 7 * * 1-5");
  });

  it("git sync pushes Kasama's files, then applies the repo's pushes", async () => {
    const st = await j(await h.request(`/v1/orgs/${orgId}/git-sync`, { method: "PUT", token: owner.token, json: { repo: "acme/kasama-config", path: "kasama" } }));
    expect(st).toMatchObject({ configured: true, has_token: true, branch: "main" });
    expect(st.webhook_secret).toHaveLength(48);
    const first = await sync();
    expect(first.pushed.sort()).toContain("ada/routines/morning-brief.md");
    expect(filesAt().get("kasama/ada/skills/pr-labels/SKILL.md")).toContain("Read the diff.");

    // Someone edits the routine in the repo; the webhook makes it due.
    pushToRepo({ "kasama/ada/routines/morning-brief.md": (filesAt().get("kasama/ada/routines/morning-brief.md") as string).replace("Send my brief.", "Send my brief, with the weather.") });
    const payload = JSON.stringify({ ref: "refs/heads/main" });
    const bad = await h.app.request(`/hooks/git-sync/${orgId}`, { method: "POST", body: payload, headers: { "x-hub-signature-256": "sha256=00" } });
    expect(bad.status).toBe(401);
    const sig = `sha256=${createHmac("sha256", st.webhook_secret).update(payload).digest("hex")}`;
    expect((await h.app.request(`/hooks/git-sync/${orgId}`, { method: "POST", body: payload, headers: { "x-hub-signature-256": sig } })).status).toBe(202);
    const second = await sync();
    expect(second.pulled).toEqual(["ada/routines/morning-brief.md"]);
    expect((await routine())?.instructions_md).toBe("Send my brief, with the weather.");
    expect(second.pushed).toEqual([]);

    // An app change goes to the repo.
    await h.tdb.admin`update public.skills set body_md = 'Read the diff and the tests.' where name = 'pr-labels'`;
    expect((await sync()).pushed).toEqual(["ada/skills/pr-labels/SKILL.md"]);
    expect(filesAt().get("kasama/ada/skills/pr-labels/SKILL.md")).toContain("and the tests");
  });

  it("when both sides change a file, Kasama keeps its version and opens a pull request with it", async () => {
    const before = repo.refs.get("main");
    await h.tdb.admin`update public.routines set instructions_md = 'App version.' where name = 'Morning brief'`;
    pushToRepo({ "kasama/ada/routines/morning-brief.md": (filesAt().get("kasama/ada/routines/morning-brief.md") as string).replace(/\n\n[\s\S]*$/, "\n\nRepo version.\n") });
    const r = await sync();
    expect(r.conflicts).toEqual(["ada/routines/morning-brief.md"]);
    expect(r.pullRequest).toBe("https://github.com/acme/kasama-config/pull/1");
    expect((await routine())?.instructions_md).toBe("App version.");
    expect(filesAt().get("kasama/ada/routines/morning-brief.md")).toContain("Repo version.");
    expect(repo.refs.get("main")).not.toBe(before);
    const pr = repo.pulls[0] as { head: string; base: string };
    expect(pr.base).toBe("main");
    expect(filesAt(pr.head).get("kasama/ada/routines/morning-brief.md")).toContain("App version.");
    // Nothing more to do until someone merges or edits again.
    const quiet = await sync();
    expect([...quiet.pushed, ...quiet.pulled, ...quiet.conflicts]).toEqual([]);
  });

  it("a file deleted in the repo deletes the skill; a bad file is reported and left alone", async () => {
    pushToRepo({ "kasama/ada/skills/pr-labels/SKILL.md": null, "kasama/ada/routines/weekly.md": "---\nname: Weekly review\nschedule: never\n---\nx" });
    const r = await sync();
    expect(r.pulled).toContain("ada/skills/pr-labels/SKILL.md");
    expect(r.errors.join()).toMatch(/weekly\.md.*valid cron/);
    expect((await h.tdb.admin`select 1 from public.skills where name = 'pr-labels'`).length).toBe(0);
    const [w] = await h.tdb.admin<{ schedule_cron: string }[]>`select schedule_cron from public.routines where name = 'Weekly review'`;
    expect(w?.schedule_cron).toBe("0 16 * * 5");
    const st = await j(await h.request(`/v1/orgs/${orgId}/git-sync`, { token: owner.token }));
    expect(st.last_error).toMatch(/valid cron/);
    expect(st.open_pr_url).toBe("https://github.com/acme/kasama-config/pull/1");
  });
});
