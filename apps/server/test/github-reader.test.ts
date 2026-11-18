/**
 * GitHubReader takes public file contents from raw.githubusercontent.com, so a plugin or pack of
 * N files costs one REST call (the tree) instead of N + 1 against GitHub's 60-an-hour limit.
 */
import { describe, expect, it } from "vitest";
import { GitHubReader } from "../src/services/skills.ts";

const COMMIT = "a".repeat(40);
const ref = { owner: "acme", repo: "kit", ref: null, path: "packs/one" };

function fakeGitHub(opts: { rawFails?: boolean } = {}) {
  const calls: string[] = [];
  const fetchImpl = (async (input: string | URL | Request, init?: RequestInit) => {
    const url = String(input);
    calls.push(url);
    const json = (v: unknown) =>
      new Response(JSON.stringify(v), { headers: { "content-type": "application/json" } });
    if (url.includes(`/git/trees/${COMMIT}`))
      return json({
        tree: [
          { path: "packs/one/plugin.json", type: "blob", sha: "s1", size: 2, mode: "100644" },
          { path: "packs/one/run me.sh", type: "blob", sha: "s2", size: 4, mode: "100755" },
          { path: "other/x.txt", type: "blob", sha: "s3", size: 1, mode: "100644" },
        ],
      });
    if (url.includes("/git/blobs/s1"))
      return json({ content: Buffer.from("{}").toString("base64"), encoding: "base64" });
    if (url.includes("/git/blobs/s2"))
      return json({ content: Buffer.from("echo").toString("base64"), encoding: "base64" });
    if (url.startsWith("https://raw.githubusercontent.com/")) {
      if (opts.rawFails) return new Response("nope", { status: 429 });
      expect((init?.headers as Record<string, string>)?.authorization).toBeUndefined();
      if (url.endsWith("/plugin.json")) return new Response("{}");
      if (url.endsWith("/run%20me.sh")) return new Response("echo");
    }
    return new Response("not found", { status: 404 });
  }) as typeof fetch;
  return { calls, fetchImpl };
}

const limits = { maxFiles: 10, maxBytes: 1024 };

describe("GitHubReader", () => {
  it("reads public files from raw.githubusercontent.com: one API call for the whole folder", async () => {
    const g = fakeGitHub();
    const files = await new GitHubReader({ fetch: g.fetchImpl }).fetchFolder(ref, COMMIT, limits);
    expect(files.map((f) => [f.path, f.content.toString(), f.executable])).toEqual([
      ["plugin.json", "{}", false],
      ["run me.sh", "echo", true],
    ]);
    expect(g.calls.filter((u) => u.startsWith("https://api.github.com"))).toHaveLength(1);
    expect(g.calls).toContain(
      `https://raw.githubusercontent.com/acme/kit/${COMMIT}/packs/one/run%20me.sh`,
    );
  });

  it("falls back to the blob API when a raw fetch fails", async () => {
    const g = fakeGitHub({ rawFails: true });
    const files = await new GitHubReader({ fetch: g.fetchImpl }).fetchFolder(ref, COMMIT, limits);
    expect(files.map((f) => f.content.toString())).toEqual(["{}", "echo"]);
    expect(g.calls.filter((u) => u.includes("/git/blobs/"))).toHaveLength(2);
  });

  it("uses the API with a token (private repositories), never the raw host", async () => {
    const g = fakeGitHub();
    await new GitHubReader({ fetch: g.fetchImpl, token: "t" }).fetchFolder(ref, COMMIT, limits);
    expect(g.calls.some((u) => u.startsWith("https://raw.githubusercontent.com"))).toBe(false);
    expect(g.calls.filter((u) => u.includes("/git/blobs/"))).toHaveLength(2);
  });

  it("keeps a custom API (tests, GitHub Enterprise) off the public raw host", async () => {
    const g = fakeGitHub();
    await new GitHubReader({
      fetch: g.fetchImpl,
      apiUrl: "https://ghe.example.com/api/v3",
    }).fetchFolder(ref, COMMIT, limits);
    expect(g.calls.some((u) => u.startsWith("https://raw.githubusercontent.com"))).toBe(false);
  });
});
