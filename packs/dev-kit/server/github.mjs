#!/usr/bin/env node
// The Dev kit's pull request tools: a minimal MCP server over stdio with no dependencies
// (newline-delimited JSON-RPC 2.0). Casama runs it inside the bot's computer. It reads public
// repositories through GitHub's REST API without signing in, so it needs no key; GitHub allows
// about 60 such calls an hour from one address. For private repositories the bot uses its GitHub
// connection instead.
//
// Each result carries `structuredContent`, which com.casama/cards/<tool>.json turns into a card.

import { createInterface } from "node:readline";

const repoArg = {
  type: "string",
  description: "The repository as owner/name, e.g. stackwares/casama",
};

const tools = [
  {
    name: "get_pull_request",
    description:
      "One pull request on a public GitHub repository: title, state, author, branches, size, checks summary and link.",
    inputSchema: {
      type: "object",
      properties: { repo: repoArg, number: { type: "integer", minimum: 1 } },
      required: ["repo", "number"],
    },
    annotations: { title: "Get a pull request", readOnlyHint: true },
  },
  {
    name: "list_pull_requests",
    description:
      "Open (or closed) pull requests on a public GitHub repository, oldest first, up to 20.",
    inputSchema: {
      type: "object",
      properties: {
        repo: repoArg,
        state: { type: "string", enum: ["open", "closed", "all"], default: "open" },
      },
      required: ["repo"],
    },
    annotations: { title: "List pull requests", readOnlyHint: true },
  },
];

const REPO = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/;

async function github(path) {
  const res = await fetch(`https://api.github.com${path}`, {
    headers: {
      accept: "application/vnd.github+json",
      "user-agent": "casama-dev-kit",
      "x-github-api-version": "2022-11-28",
    },
    signal: AbortSignal.timeout(20_000),
  });
  if (res.status === 404)
    throw new Error("Not found. The repository may be private: use the GitHub connection for it.");
  if (res.status === 403 || res.status === 429)
    throw new Error("GitHub's limit for calls without signing in is reached; try again later.");
  if (!res.ok) throw new Error(`GitHub answered ${res.status}.`);
  return res.json();
}

const day = (iso) => (typeof iso === "string" ? iso.slice(0, 10) : undefined);

async function call(name, args) {
  const repo = String(args.repo ?? "").trim();
  if (!REPO.test(repo)) throw new Error("repo must be owner/name, like stackwares/casama.");
  if (name === "get_pull_request") {
    const n = Number(args.number);
    if (!Number.isInteger(n) || n < 1) throw new Error("number must be a pull request number.");
    const pr = await github(`/repos/${repo}/pulls/${n}`);
    return {
      repo,
      number: pr.number,
      title: pr.title,
      state: pr.merged_at ? "merged" : pr.draft ? "draft" : pr.state,
      author: pr.user?.login,
      head: pr.head?.ref,
      base: pr.base?.ref,
      changes: `+${pr.additions} −${pr.deletions} in ${pr.changed_files} file${pr.changed_files === 1 ? "" : "s"}`,
      comments: (pr.comments ?? 0) + (pr.review_comments ?? 0),
      mergeable: pr.mergeable_state,
      created: day(pr.created_at),
      updated: day(pr.updated_at),
      url: pr.html_url,
      body: typeof pr.body === "string" ? pr.body.slice(0, 4000) : "",
    };
  }
  if (name === "list_pull_requests") {
    const state = ["open", "closed", "all"].includes(args.state) ? args.state : "open";
    const list = await github(
      `/repos/${repo}/pulls?state=${state}&sort=created&direction=asc&per_page=20`,
    );
    return {
      repo,
      state,
      count: list.length,
      pull_requests: list.map((pr) => ({
        number: pr.number,
        title: pr.title,
        author: pr.user?.login,
        draft: pr.draft === true,
        created: day(pr.created_at),
        url: pr.html_url,
      })),
    };
  }
  throw new Error(`Unknown tool ${name}`);
}

async function handle(msg) {
  const { id, method, params } = msg;
  switch (method) {
    case "initialize":
      return {
        protocolVersion: params?.protocolVersion ?? "2025-06-18",
        capabilities: { tools: {} },
        serverInfo: { name: "casama-dev-kit-github", version: "1.0.0" },
      };
    case "ping":
      return {};
    case "tools/list":
      return { tools };
    case "tools/call":
      try {
        const data = await call(params.name, params.arguments ?? {});
        // The text is for the model and older clients; the structured copy fills the card.
        return {
          content: [{ type: "text", text: JSON.stringify(data, null, 2) }],
          structuredContent: data,
        };
      } catch (err) {
        return { content: [{ type: "text", text: String(err.message ?? err) }], isError: true };
      }
    default:
      if (id === undefined) return undefined;
      throw Object.assign(new Error(`Method not found: ${method}`), { code: -32601 });
  }
}

const send = (m) => process.stdout.write(`${JSON.stringify(m)}\n`);

createInterface({ input: process.stdin }).on("line", async (line) => {
  if (!line.trim()) return;
  let msg;
  try {
    msg = JSON.parse(line);
  } catch {
    return send({ jsonrpc: "2.0", id: null, error: { code: -32700, message: "Parse error" } });
  }
  try {
    const result = await handle(msg);
    if (msg.id !== undefined && result !== undefined) send({ jsonrpc: "2.0", id: msg.id, result });
  } catch (err) {
    send({
      jsonrpc: "2.0",
      id: msg.id ?? null,
      error: { code: err.code ?? -32603, message: err.message },
    });
  }
});
