/** Runs supabase/tests/*.test.sql against a throwaway database (no Docker needed). */
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { startTestDatabase } from "../src/testing.ts";

const testsDir = fileURLToPath(new URL("../../../supabase/tests/", import.meta.url));
const db = await startTestDatabase();
let failed = 0;
try {
  await db.admin`create extension if not exists pgtap with schema extensions`;
  for (const file of readdirSync(testsDir)
    .filter((f) => f.endsWith(".test.sql"))
    .sort()) {
    const sqlText = readFileSync(join(testsDir, file), "utf8");
    const lines: string[] = [];
    const conn = await db.admin.reserve();
    try {
      await conn.unsafe("set search_path = public, extensions");
      const results = await conn.unsafe(sqlText).catch((e: Error) => {
        lines.push(`not ok - ${file} errored: ${e.message}`);
        return [];
      });
      for (const r of results as unknown as Array<
        Array<Record<string, unknown>> | Record<string, unknown>
      >) {
        const rows = Array.isArray(r) ? r : [r];
        for (const row of rows)
          for (const v of Object.values(row ?? {})) if (typeof v === "string") lines.push(v);
      }
    } finally {
      await conn.unsafe("rollback").catch(() => {});
      conn.release();
    }
    const tap = lines.filter((l) => /^(not )?ok |^1\.\.|^#/.test(l));
    const bad = tap.filter((l) => l.startsWith("not ok") || /Looks like you/.test(l));
    console.log(
      `${bad.length ? "FAIL" : "PASS"} ${file} (${tap.filter((l) => /^ok /.test(l)).length} ok)`,
    );
    for (const l of bad) console.log(`  ${l}`);
    failed += bad.length;
  }
} finally {
  await db.stop();
}
process.exit(failed ? 1 : 0);
