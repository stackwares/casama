import { sql } from "drizzle-orm";
import { drizzle, type PostgresJsDatabase } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import { contentKeys } from "./content-crypto.ts";
import * as relations from "./generated/relations.ts";
import * as schema from "./generated/schema.ts";

export { schema };
export const fullSchema = { ...schema, ...relations };
export type Database = PostgresJsDatabase<typeof fullSchema>;
export type Tx = Parameters<Parameters<Database["transaction"]>[0]>[0];

/** Verified JWT claims, as Supabase issues them. */
export interface JwtClaims {
  sub: string;
  email?: string;
  role?: string;
  aud?: string | string[];
  exp?: number;
  [key: string]: unknown;
}

export interface DbHandle {
  db: Database;
  client: postgres.Sql;
  close(): Promise<void>;
}

export function createDb(url: string, opts: { max?: number } = {}): DbHandle {
  // Encrypted content (D-136) is decrypted as rows are read.
  const client = postgres(url, {
    max: opts.max ?? 10,
    onnotice: () => {},
    prepare: false,
    transform: { value: { from: (v: unknown) => contentKeys.open(v) } },
  });
  const db = drizzle(client, { schema: fullSchema });
  return { db, client, close: () => client.end() };
}

/**
 * Runs fn in a transaction as the `authenticated` role with the caller's claims,
 * so every query obeys the same RLS policies as the client path.
 */
export async function withUserSession<T>(
  db: Database,
  claims: JwtClaims,
  fn: (tx: Tx) => Promise<T>,
): Promise<T> {
  return db.transaction(async (tx) => {
    await tx.execute(
      sql`select set_config('request.jwt.claims', ${JSON.stringify({ ...claims, role: "authenticated" })}, true),
                 set_config('role', 'authenticated', true)`,
    );
    return fn(tx);
  });
}

/** Thrown database errors carry a SQLSTATE code. */
export function pgErrorCode(err: unknown): string | undefined {
  let e: unknown = err;
  for (let i = 0; i < 4 && e && typeof e === "object"; i++) {
    const code = (e as { code?: unknown }).code;
    if (typeof code === "string" && /^[0-9A-Z]{5}$/.test(code)) return code;
    e = (e as { cause?: unknown }).cause;
  }
  return undefined;
}

export function pgErrorMessage(err: unknown): string | undefined {
  let e: unknown = err;
  for (let i = 0; i < 4 && e && typeof e === "object"; i++) {
    if ((e as { code?: unknown }).code && typeof (e as { message?: unknown }).message === "string")
      return (e as { message: string }).message;
    e = (e as { cause?: unknown }).cause;
  }
  return undefined;
}
export * from "./content-crypto.ts";
