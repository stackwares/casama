/**
 * Throwaway Postgres for tests. When TEST_DATABASE_URL is set (CI with `supabase start`),
 * it is used as is. Otherwise a temporary cluster is created with the local Postgres
 * binaries (PG_BIN, else Homebrew's postgresql@17 or Debian/Ubuntu's postgresql-17), the Supabase
 * shim and all migrations.
 */
import { execFileSync, spawn } from "node:child_process";
import { existsSync, mkdtempSync, readdirSync, readFileSync, rmSync } from "node:fs";
import { createServer } from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import postgres from "postgres";

const repoRoot = fileURLToPath(new URL("../../../", import.meta.url));
export const migrationsDir = join(repoRoot, "supabase/migrations");
const shimPath = fileURLToPath(new URL("../testing/supabase-shim.sql", import.meta.url));

export interface TestDatabase {
  url: string;
  /** Superuser connection (bypasses RLS). */
  admin: postgres.Sql;
  stop(): Promise<void>;
}

/** Where Postgres 17 lives when PG_BIN isn't set: Homebrew on macOS, the PGDG packages on Linux. */
const PG_BIN_DEFAULTS = [
  "/opt/homebrew/opt/postgresql@17/bin",
  "/usr/local/opt/postgresql@17/bin",
  "/usr/lib/postgresql/17/bin",
];

function pgBin(name: string) {
  const dirs = process.env.PG_BIN ? [process.env.PG_BIN] : PG_BIN_DEFAULTS;
  const found = dirs.map((dir) => join(dir, name)).find((p) => existsSync(p));
  if (!found)
    throw new Error(
      `Postgres binary not found: ${name} in ${dirs.join(", ")}. Set PG_BIN or TEST_DATABASE_URL.`,
    );
  return found;
}

async function freePort(): Promise<number> {
  return new Promise((resolve, reject) => {
    const srv = createServer();
    srv.listen(0, "127.0.0.1", () => {
      const addr = srv.address();
      srv.close(() =>
        typeof addr === "object" && addr ? resolve(addr.port) : reject(new Error("no port")),
      );
    });
  });
}

export async function applyMigrations(sql: postgres.Sql) {
  for (const file of readdirSync(migrationsDir)
    .filter((f) => f.endsWith(".sql"))
    .sort()) {
    await sql.unsafe(readFileSync(join(migrationsDir, file), "utf8"));
  }
}

export async function startTestDatabase(): Promise<TestDatabase> {
  if (process.env.TEST_DATABASE_URL) {
    const url = process.env.TEST_DATABASE_URL;
    const admin = postgres(url, { max: 4, onnotice: () => {} });
    return { url, admin, stop: () => admin.end() };
  }
  const dataDir = mkdtempSync(join(tmpdir(), "casama-pg-"));
  execFileSync(
    pgBin("initdb"),
    ["-D", dataDir, "-U", "postgres", "--auth=trust", "-E", "UTF8", "--no-locale"],
    {
      stdio: "ignore",
    },
  );
  const port = await freePort();
  const proc = spawn(
    pgBin("postgres"),
    [
      "-D",
      dataDir,
      "-p",
      String(port),
      "-k",
      dataDir,
      "-c",
      "listen_addresses=127.0.0.1",
      "-c",
      "fsync=off",
    ],
    { stdio: "ignore" },
  );
  const url = `postgres://postgres@127.0.0.1:${port}/postgres`;
  const admin = postgres(url, { max: 4, onnotice: () => {} });
  for (let i = 0; ; i++) {
    try {
      await admin`select 1`;
      break;
    } catch (e) {
      if (i > 100) throw e;
      await new Promise((r) => setTimeout(r, 100));
    }
  }
  await admin.unsafe(readFileSync(shimPath, "utf8"));
  await applyMigrations(admin);
  return {
    url,
    admin,
    async stop() {
      await admin.end();
      proc.kill("SIGINT");
      await new Promise((r) => proc.once("exit", r));
      rmSync(dataDir, { recursive: true, force: true });
    },
  };
}

/** Insert an auth user directly (tests only). */
export async function createAuthUser(admin: postgres.Sql, email: string) {
  const [row] = await admin<{ id: string }[]>`
    insert into auth.users (id, email, aud, role)
    values (gen_random_uuid(), ${email}, 'authenticated', 'authenticated')
    returning id`;
  if (!row) throw new Error("user insert returned nothing");
  // Quiet hours are on by default (D-254). Test users start with them off, so tests that push
  // pass at any hour of the day; the quiet-hours tests set their own.
  await admin`update public.profiles set quiet_hours = '{"enabled": false, "start": "22:00", "end": "07:00"}'::jsonb where user_id = ${row.id}`;
  return { id: row.id, email };
}
