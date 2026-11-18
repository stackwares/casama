import { sql } from "drizzle-orm";
import type { AppDeps } from "../api/types.ts";

/**
 * Whether a workspace's live calls run on the server's own Google AI key (it has no Gemini key of
 * its own). On Casama Cloud those calls are paid from the workspace's credits, at Google's price
 * times the markup (D-244), in the app and on the phone alike. Every call is Gemini Live (D-260),
 * so only a Google key counts: an OpenAI key used to count too, which made calls on the server's
 * key free (billing audit 2026-11-17).
 */
export async function billsCalls(deps: Pick<AppDeps, "db" | "env" | "billing">, orgId: string) {
  if (!deps.billing?.enabled || !deps.env.GOOGLE_AI_API_KEY) return false;
  const [own] = await deps.db.execute(sql`
    select 1 from public.model_credentials
    where org_id = ${orgId}::uuid and provider = 'google' and vault_secret_id is not null limit 1`);
  return !own;
}
