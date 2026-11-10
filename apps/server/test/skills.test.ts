/** Skills library (D-104): catalog, GitHub import pinned to a commit with update diffs, bot tools. */
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import { registerSkillTools, ToolRegistry } from "@kasama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/skills.json", import.meta.url));
const C1 = "a".repeat(40);
const C2 = "b".repeat(40);
let head = C1;
const md = (v: string) =>
  `---\nname: pr-labels\ndescription: Label pull requests\n---\n\n# Steps\n\n${v}\n`;
const blobs: Record<string, string> = {
  m1: md("Read the diff."),
  m2: md("Read the diff and the tests."),
  s1: "#!/bin/sh\necho label\n",
};
const trees: Record<
  string,
  Array<{ path: string; type: string; sha: string; size: number; mode: string }>
> = {
  [C1]: [
    { path: "skills/pr-labels/SKILL.md", type: "blob", sha: "m1", size: 10, mode: "100644" },
    { path: "skills/pr-labels/label.sh", type: "blob", sha: "s1", size: 10, mode: "100755" },
    { path: "README.md", type: "blob", sha: "s1", size: 10, mode: "100644" },
  ],
  [C2]: [{ path: "skills/pr-labels/SKILL.md", type: "blob", sha: "m2", size: 10, mode: "100644" }],
};

let gh: Server;
let h: Harness;
let owner: { id: string; token: string };
let member: { id: string; token: string };
let orgId: string;
let botId: string;
const auth: string[] = [];

beforeAll(async () => {
  gh = createServer((req, res) => {
    auth.push(String(req.headers.authorization ?? ""));
    const url = req.url ?? "";
    res.setHeader("content-type", "application/json");
    const send = (v: unknown) => res.end(JSON.stringify(v));
    if (url === "/repos/acme/skills") return send({ default_branch: "main" });
    if (url === "/repos/acme/skills/commits/main") return send({ sha: head });
    const t = /^\/repos\/acme\/skills\/git\/trees\/([0-9a-f]{40})\?recursive=1$/.exec(url);
    if (t?.[1] && trees[t[1]]) return send({ tree: trees[t[1]], truncated: false });
    const b = /^\/repos\/acme\/skills\/git\/blobs\/(\w+)$/.exec(url);
    if (b?.[1] && blobs[b[1]])
      return send({
        content: Buffer.from(blobs[b[1]] as string).toString("base64"),
        encoding: "base64",
      });
    res.writeHead(404).end("{}");
  }).listen(0, "127.0.0.1");
  await new Promise((r) => gh.once("listening", r));
  h = await startHarness({
    env: { GITHUB_API_URL: `http://127.0.0.1:${(gh.address() as AddressInfo).port}` },
    worker: { fixtures: FIXTURES },
  });
  owner = await h.user("skills-owner@example.com");
  member = await h.user("skills-member@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Skills" } }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
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
        json: {
          org_id: orgId,
          name: "Scribe",
          model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
        },
      }),
    )
  ).id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
  gh?.close();
});

describe("catalog", () => {
  it("lists bundled skills and installs them with their files", async () => {
    const cat = await j(await h.request("/v1/skills/catalog", { token: owner.token }));
    expect(cat.categories).toContain("work");
    const csv = cat.items.find((s: { id: string }) => s.id === "csv-cleanup");
    expect(csv.files).toEqual(["scripts/clean.py"]);
    expect(
      (
        await h.request("/v1/skills/install", {
          method: "POST",
          token: member.token,
          json: { org_id: orgId, catalog_id: "csv-cleanup" },
        })
      ).status,
    ).toBe(403);
    const res = await h.request("/v1/skills/install", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, catalog_id: "csv-cleanup" },
    });
    expect(res.status).toBe(201);
    expect(await j(res)).toMatchObject({
      name: "csv-cleanup",
      source: "catalog",
      category: "data",
      file_count: 1,
      bot_id: null,
    });
    const [f] = await h.tdb.admin<{ executable: boolean; n: number }[]>`
      select executable, octet_length(content) as n from public.skill_files where path = 'scripts/clean.py'`;
    expect(f?.executable).toBe(true);
    expect(
      (
        await h.request("/v1/skills/install", {
          method: "POST",
          token: owner.token,
          json: { org_id: orgId, catalog_id: "csv-cleanup" },
        })
      ).status,
    ).toBe(409);
    await h.request("/v1/skills/install", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, catalog_id: "meeting-notes" },
    });
  });
});

describe("GitHub import", () => {
  let skillId: string;
  const url = "https://github.com/acme/skills/tree/main/skills/pr-labels";

  it("previews the folder's files at a pinned commit", async () => {
    const p = await j(
      await h.request("/v1/skills/github/preview", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, url },
      }),
    );
    expect(p).toMatchObject({
      repo: "acme/skills",
      path: "skills/pr-labels",
      commit: C1,
      name: "pr-labels",
    });
    expect(p.files).toEqual([
      { path: "label.sh", size: 21, executable: true, text: "#!/bin/sh\necho label\n" },
    ]);
    const bad = await h.request("/v1/skills/github/preview", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, url: "https://gitlab.com/x/y" },
    });
    expect(bad.status).toBe(400);
  });

  it("installs for one bot at that commit, and shows a diff before updating", async () => {
    head = C1;
    const res = await h.request("/v1/skills/github/install", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, bot_id: botId, url, commit: C1 },
    });
    expect(res.status).toBe(201);
    const s = await j(res);
    skillId = s.id;
    expect(s).toMatchObject({
      bot_id: botId,
      source: "github",
      source_ref: { repo: "acme/skills", commit: C1 },
    });
    expect(
      (await j(await h.request(`/v1/skills/${skillId}/update`, { token: owner.token }))).has_update,
    ).toBe(false);
    head = C2;
    const check = await j(await h.request(`/v1/skills/${skillId}/update`, { token: owner.token }));
    expect(check).toMatchObject({
      has_update: true,
      latest_commit: C2,
      files_removed: ["label.sh"],
    });
    expect(check.diff).toContain("+ Read the diff and the tests.");
    const updated = await j(
      await h.request(`/v1/skills/${skillId}/update`, {
        method: "POST",
        token: owner.token,
        json: { commit: C2 },
      }),
    );
    expect(updated).toMatchObject({ file_count: 0, source_ref: { commit: C2 } });
  });

  it("uses the workspace's GITHUB_TOKEN for private repositories", async () => {
    await h.request("/v1/secrets", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: orgId,
        name: "GITHUB_TOKEN",
        value: "ghp_testtoken123",
        allowed_hosts: ["api.github.com"],
      },
    });
    auth.length = 0;
    await h.request("/v1/skills/github/preview", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, url },
    });
    expect(auth).toContain("Bearer ghp_testtoken123");
  });
});

describe("bot skill tools and the / picker", () => {
  const ctx = () =>
    ({
      runId: "00000000-0000-0000-0000-000000000000",
      botId,
      orgId,
      output: async () => {},
      emit: async () => {},
    }) as never;
  const reg = new ToolRegistry();

  it("saves a method as the bot's own skill and shows a diff for updates", async () => {
    registerSkillTools(reg, { db: h.handle.db });
    const create = reg.get("skills.create")!;
    expect(
      (
        await create.approvalDetails?.(
          { name: "triage", description: "Triage mail", instructions: "1. Read" } as never,
          { orgId, botId },
        )
      )?.preview,
    ).toContain("name: triage");
    await create.execute(
      { name: "triage", description: "Triage mail", instructions: "1. Read" } as never,
      ctx(),
    );
    const update = reg.get("skills.update")!;
    const d = await update.approvalDetails?.(
      { name: "triage", instructions: "1. Read\n2. Label" } as never,
      { orgId, botId },
    );
    expect(String(d?.diff)).toContain("+ 2. Label");
    await update.execute({ name: "triage", instructions: "1. Read\n2. Label" } as never, ctx());
    const [s] = await h.tdb.admin<{ source: string; body_md: string; updated_by_bot: string }[]>`
      select source, body_md, updated_by_bot from public.skills where name = 'triage'`;
    expect(s).toMatchObject({ source: "bot", body_md: "1. Read\n2. Label", updated_by_bot: botId });
    await expect(
      update.execute({ name: "csv-cleanup", instructions: "x" } as never, ctx()),
    ).rejects.toThrow(/workspace skill/);
  });

  it("loads skills picked with / up front", async () => {
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: botId },
      }),
    );
    const sent = await j(
      await h.request(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token: owner.token,
        json: { text: "Here are today's notes", skills: ["meeting-notes"] },
      }),
    );
    for (let i = 0; i < 100; i++) {
      const r = await j(await h.request(`/v1/runs/${sent.run_id}`, { token: owner.token }));
      if (r.status === "completed") break;
      await new Promise((res) => setTimeout(res, 100));
    }
    const msgs = await h.tdb.admin<{ content: Array<{ type: string; text?: string }> }[]>`
      select content from public.messages where conversation_id = ${conv.id} and role = 'assistant'`;
    expect(JSON.stringify(msgs)).toContain("Using the meeting notes skill.");
  });
});
