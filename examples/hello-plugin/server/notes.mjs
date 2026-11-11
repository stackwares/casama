#!/usr/bin/env node
// A minimal MCP server over stdio, with no dependencies: newline-delimited JSON-RPC 2.0.
// Kasama runs it inside the bot's computer. It keeps notes as Markdown files in NOTES_DIR (under
// PLUGIN_DATA, which survives plugin updates) and signs each one with the NOTES_SIGNATURE secret.
//
// A real plugin would usually use the official SDK (@modelcontextprotocol/sdk) and ship it bundled
// (see the plugins guide); this one is plain Node so it runs with nothing installed.

import { mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { createInterface } from "node:readline";

const dir = process.env.NOTES_DIR ?? join(process.cwd(), "notes");
const signature = process.env.NOTES_SIGNATURE ?? "";

const tools = [
  {
    name: "list_notes",
    description: "List saved notes, newest first.",
    inputSchema: { type: "object", properties: {} },
    annotations: { title: "List notes", readOnlyHint: true },
  },
  {
    name: "read_note",
    description: "Read one saved note by its title.",
    inputSchema: {
      type: "object",
      properties: { title: { type: "string" } },
      required: ["title"],
    },
    annotations: { title: "Read a note", readOnlyHint: true },
  },
  {
    name: "save_note",
    description: "Save a note (Markdown). A note with the same title is replaced.",
    inputSchema: {
      type: "object",
      properties: { title: { type: "string" }, body: { type: "string" } },
      required: ["title", "body"],
    },
    // Not read-only and not destructive: Kasama treats it as medium risk.
    annotations: { title: "Save a note", readOnlyHint: false, destructiveHint: false },
  },
];

const fileFor = (title) =>
  join(
    dir,
    `${
      String(title)
        .replace(/[^A-Za-z0-9 _-]+/g, "")
        .trim()
        .slice(0, 80) || "note"
    }.md`,
  );

function call(name, args) {
  mkdirSync(dir, { recursive: true });
  if (name === "list_notes") {
    const notes = readdirSync(dir)
      .filter((f) => f.endsWith(".md"))
      .sort()
      .reverse();
    return notes.length ? notes.map((f) => f.slice(0, -3)).join("\n") : "No notes yet.";
  }
  if (name === "read_note") return readFileSync(fileFor(args.title), "utf8");
  if (name === "save_note") {
    const body = signature ? `${args.body.trimEnd()}\n\n— ${signature}\n` : `${args.body}\n`;
    writeFileSync(fileFor(args.title), body);
    return `Saved "${args.title}".`;
  }
  throw new Error(`Unknown tool ${name}`);
}

function handle(msg) {
  const { id, method, params } = msg;
  switch (method) {
    case "initialize":
      return {
        protocolVersion: params?.protocolVersion ?? "2025-06-18",
        capabilities: { tools: {} },
        serverInfo: { name: "hello-kasama-notes", version: "1.0.0" },
      };
    case "ping":
      return {};
    case "tools/list":
      return { tools };
    case "tools/call":
      try {
        return { content: [{ type: "text", text: call(params.name, params.arguments ?? {}) }] };
      } catch (err) {
        // Tool failures go back as a result the model can read, not as a protocol error.
        return { content: [{ type: "text", text: String(err.message ?? err) }], isError: true };
      }
    default:
      if (id === undefined) return undefined; // a notification: nothing to answer
      throw Object.assign(new Error(`Method not found: ${method}`), { code: -32601 });
  }
}

const send = (m) => process.stdout.write(`${JSON.stringify(m)}\n`);

createInterface({ input: process.stdin }).on("line", (line) => {
  if (!line.trim()) return;
  let msg;
  try {
    msg = JSON.parse(line);
  } catch {
    return send({ jsonrpc: "2.0", id: null, error: { code: -32700, message: "Parse error" } });
  }
  try {
    const result = handle(msg);
    if (msg.id !== undefined && result !== undefined) send({ jsonrpc: "2.0", id: msg.id, result });
  } catch (err) {
    send({
      jsonrpc: "2.0",
      id: msg.id ?? null,
      error: { code: err.code ?? -32603, message: err.message },
    });
  }
});
