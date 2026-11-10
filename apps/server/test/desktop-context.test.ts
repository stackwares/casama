/** Desktop context (D-152): folder-watch triggers and file search on the person's own computer. */
import { registerDesktopContextTools, ToolRegistry } from "@kasama/agent";
import type { ExecChunk, SandboxHandle } from "@kasama/sandbox";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { matchesPattern } from "../src/worker/device-triggers.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const KEY = "desktop-mac-0001";
let h: Harness;
let owner: { id: string; token: string };
let orgId: string;
let botId: string;

beforeAll(async () => {
  h = await startHarness({});
  owner = await h.user("desk-owner@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Desk" } }),
    )
  ).id;
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Filer" },
      }),
    )
  ).id;
  await h.request(`/v1/device-sources/${KEY}`, {
    method: "PUT",
    token: owner.token,
    json: { name: "Mac", platform: "macos", kinds: {} },
  });
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

describe("desktop context", () => {
  it("file name patterns", () => {
    expect(matchesPattern("Invoice March.PDF", "*.pdf")).toBe(true);
    expect(matchesPattern("notes.txt", "*.pdf")).toBe(false);
    expect(matchesPattern("Invoice-12.pdf", "Invoice-??.pdf")).toBe(true);
    expect(matchesPattern("a(b).pdf", "a(b).pdf")).toBe(true);
  });

  it("a PDF dropped in Downloads starts the 'file it' routine; other files and folders don't", async () => {
    const r = await j(
      await h.request("/v1/routines", {
        method: "POST",
        token: owner.token,
        json: {
          bot_id: botId,
          name: "File it",
          instructions: "File new PDFs into the right folder.",
          trigger: "device",
          device: { event: "file_added", folder: "Downloads", pattern: "*.pdf" },
        },
      }),
    );
    expect(r.device).toEqual({ event: "file_added", folder: "Downloads", pattern: "*.pdf" });
    const send = (id: string, folder: string, name: string) =>
      h.request(`/v1/device-sources/${KEY}/events`, {
        method: "POST",
        token: owner.token,
        json: { events: [{ id, type: "file_added", at: new Date().toISOString(), folder, name }] },
      });
    expect((await j(await send("f1", "Downloads", "Invoice March.pdf"))).runs).toBe(1);
    expect((await j(await send("f2", "Downloads", "photo.jpg"))).runs).toBe(0);
    expect((await j(await send("f3", "Desktop", "Other.pdf"))).runs).toBe(0);
    expect((await send("f4", "Downloads", "")).status).toBe(400);
    const [run] = await h.tdb.admin<
      { id: string }[]
    >`select id from public.runs where routine_id = ${r.id}`;
    const [m] = await h.tdb.admin<
      { c: string }[]
    >`select content::text as c from public.messages where run_id = ${run!.id}`;
    expect(m?.c).toContain("Downloads: Invoice March.pdf");
  });

  it("file search runs Spotlight inside the allowed folders only, on the person's own computer", async () => {
    const registry = new ToolRegistry();
    registerDesktopContextTools(registry, { db: h.deps.db });
    const tool = registry.get("desktop.files.search")!;
    const ran: string[] = [];
    const handle = {
      async *exec(cmd: string): AsyncIterable<ExecChunk> {
        ran.push(cmd);
        yield {
          type: "stdout",
          data: "/Users/ana/Documents/tax-2026.pdf\n/Users/ana/Library/secret.pdf\n/Users/ana/Documents/old/tax-2025.pdf\n",
        };
        yield { type: "exit", code: 0, timedOut: false, killed: false, truncated: false };
      },
    } as unknown as SandboxHandle;
    const ctx = {
      runId: "00000000-0000-0000-0000-000000000000",
      botId,
      orgId,
      output: async () => {},
      emit: async () => {},
      computer: async () => handle,
    };
    // Not on a personal computer yet.
    await expect(tool.execute({ query: "tax" }, ctx)).rejects.toMatchObject({ code: "no_desktop" });
    const [c] = await h.tdb.admin<
      { id: string }[]
    >`insert into public.computers (org_id, kind, name, provider) values (${orgId}, 'local', 'Ana Mac', 'local') returning id`;
    await h.tdb
      .admin`insert into public.local_devices (org_id, user_id, computer_id, platform, token_hash, allowed_roots, name)
      values (${orgId}, ${owner.id}, ${c!.id}, 'macos', 'x', '{/Users/ana/Documents}', 'Mac')`;
    await h.tdb.admin`update public.bots set default_computer_id = ${c!.id} where id = ${botId}`;
    const res = await tool.execute({ query: "tax" }, ctx);
    expect(ran[0]).toContain("mdfind -onlyin '/Users/ana/Documents' 'tax'");
    expect(res.content).toContain("tax-2026.pdf");
    expect(res.content).toContain("old/tax-2025.pdf");
    expect(res.content).not.toContain("Library/secret.pdf");
  });
});
