/**
 * Import an agent (D-122): reads an OpenClaw or Hermes Agent folder (a ZIP, or the files of a
 * folder the desktop app picked) into a bot template the person reviews; the existing template
 * import (D-110) then creates the bot. Files nothing maps to are kept for a day and copied to
 * ~/imported/ on the new bot's computer on request. Also: ChatGPT or Claude memory, pasted back.
 */
import type { OpenAPIHono } from "@hono/zod-openapi";
import { botComputerId } from "@kasama/agent";
import { routes } from "@kasama/contracts";
import { type JwtClaims, withUserSession, contentKeys } from "@kasama/db";
import { AgentImportError, MEMORY_EXPORT_PROMPT, parseMemoryExport, planAgentImport } from "@kasama/domain";
import { sql } from "drizzle-orm";
import { unzipSync } from "fflate";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

const MAX_FILES = 3000;
const MAX_BYTES = 50 * 1024 * 1024;

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

/** Safe relative paths only: no absolute paths, no "..", forward slashes. */
const cleanPath = (p: string) => {
  const parts = p.replaceAll("\\", "/").split("/").filter((x) => x && x !== ".");
  if (parts.includes("..") || p.startsWith("/")) return null;
  return parts.join("/");
};

export function registerAgentImportRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  app.openapi(routes.startAgentImport, async (c) => {
    const claims = claimsOf(c);
    const b = c.req.valid("json");
    const [member] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.is_member(${b.org_id}::uuid) as ok`),
    );
    if (!member?.ok) throw new ApiError(404, "org_not_found", "Workspace not found");
    const files = new Map<string, Uint8Array>();
    let total = 0;
    const add = (path: string, data: Uint8Array) => {
      const p = cleanPath(path);
      if (!p || path.endsWith("/")) return;
      total += data.byteLength;
      if (files.size >= MAX_FILES || total > MAX_BYTES)
        throw new ApiError(400, "import_too_large", "The folder is over 50 MB or 3,000 files. Leave out logs, sessions and databases.");
      files.set(p, data);
    };
    if (b.zip_base64) {
      let entries: Record<string, Uint8Array>;
      try {
        entries = unzipSync(Buffer.from(b.zip_base64, "base64"), {
          filter: (f) => f.originalSize <= MAX_BYTES && !f.name.startsWith("__MACOSX/"),
        });
      } catch {
        throw new ApiError(400, "import_bad_zip", "That isn't a ZIP file we can read.");
      }
      for (const [name, data] of Object.entries(entries)) add(name, data);
    } else if (b.files?.length) {
      for (const f of b.files) add(f.path, Buffer.from(f.content_base64, "base64"));
    } else throw new ApiError(400, "import_empty", "Upload a ZIP or pick a folder.");

    let plan: ReturnType<typeof planAgentImport>;
    try {
      plan = planAgentImport(files);
    } catch (err) {
      if (err instanceof AgentImportError) throw new ApiError(400, "import_not_recognized", err.message);
      throw err;
    }
    const [row] = await db.execute<{ id: string }>(sql`
      insert into public.agent_imports (org_id, user_id, kind) values (${b.org_id}::uuid, ${claims.sub}::uuid, ${plan.kind}) returning id`);
    const id = row?.id as string;
    const leftovers: Array<{ path: string; size: number }> = [];
    for (const rel of plan.leftovers) {
      const data = files.get(plan.root + rel) ?? files.get(rel);
      if (!data) continue;
      leftovers.push({ path: rel, size: data.byteLength });
      await db.execute(sql`
        insert into public.agent_import_files (import_id, path, content)
        values (${id}::uuid, ${rel}, decode(${Buffer.from(data).toString("base64")}, 'base64'))`);
    }
    // Old uploads go after a day.
    await db.execute(sql`delete from public.agent_imports where expires_at < now()`);
    return c.json(
      {
        id,
        kind: plan.kind,
        template: {
          format: "kasama.bot" as const,
          version: 1,
          name: plan.name,
          description: plan.kind === "openclaw" ? "Imported from OpenClaw" : "Imported from Hermes Agent",
          persona_md: plan.persona_md,
          autonomy: "ask_risky" as const,
          skills: plan.skills.map(({ source: _s, ...k }) => k),
          routines: plan.routines.map(({ source: _s, ...r }) => r),
          memories: plan.memories.map(({ source: _s, ...m }) => m),
          connections: [],
        },
        sources: {
          skills: plan.skills.map((s) => s.source),
          routines: plan.routines.map((r) => r.source),
          memories: plan.memories.map((m) => m.source),
        },
        leftovers,
        skipped: plan.skipped,
        notes: plan.notes,
      },
      201,
    );
  });

  app.openapi(routes.writeAgentImportFiles, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const { bot_id } = c.req.valid("json");
    const [imp] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string; kind: string; org_id: string }>(sql`
        select id, kind, org_id from public.agent_imports where id = ${id}::uuid and expires_at > now()`),
    );
    if (!imp) throw new ApiError(404, "import_not_found", "This upload has expired. Import the folder again.");
    const [bot] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ manage: boolean; org_id: string }>(sql`
        select public.can_manage_bot(id) as manage, org_id from public.bots where id = ${bot_id}::uuid`),
    );
    if (!bot || bot.org_id !== imp.org_id) throw new ApiError(404, "bot_not_found", "Bot not found");
    if (!bot.manage) throw new ApiError(403, "forbidden", "Only people who manage this bot can add files to its computer");
    const computerId = await botComputerId(db, bot_id);
    if (!deps.computers || !computerId)
      throw new ApiError(409, "no_computer", "This bot has no computer yet. Give it one, then copy the files.");
    const h = await deps.computers.ensureRunning(computerId);
    const folder = `~/imported/${imp.kind}`;
    const files = await db.execute<{ path: string; content: Buffer }>(
      sql`select path, content from public.agent_import_files where import_id = ${id}::uuid`,
    );
    for (const f of files) await h.writeFile(`${folder}/${f.path}`, new Uint8Array(f.content));
    await db.execute(sql`update public.agent_imports set bot_id = ${bot_id}::uuid, files_written_at = now() where id = ${id}::uuid`);
    return c.json({ written: files.length, folder }, 200);
  });

  app.openapi(routes.getMemoryImportPrompt, async (c) => {
    claimsOf(c);
    return c.json({ prompt: MEMORY_EXPORT_PROMPT }, 200);
  });

  app.openapi(routes.parseMemoryImport, async (c) => {
    claimsOf(c);
    return c.json({ memories: parseMemoryExport(c.req.valid("json").text) }, 200);
  });

  app.openapi(routes.saveImportedMemories, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const [bot] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ manage: boolean; org_id: string }>(sql`
        select public.can_manage_bot(id) as manage, org_id from public.bots where id = ${id}::uuid and archived_at is null`),
    );
    if (!bot) throw new ApiError(404, "bot_not_found", "Bot not found");
    if (!bot.manage) throw new ApiError(403, "forbidden", "Only people who manage this bot can change its memory");
    const { memories } = c.req.valid("json");
    await db.transaction(async (tx) => {
      for (const m of memories)
        await tx.execute(sql`
          insert into public.memories (org_id, bot_id, kind, content, importance)
          values (${bot.org_id}::uuid, ${id}::uuid, ${m.kind}, ${contentKeys.seal(bot.org_id, m.content)}, ${m.kind === "preference" ? 0.7 : 0.6})`);
    });
    return c.json({ saved: memories.length }, 200);
  });
}
