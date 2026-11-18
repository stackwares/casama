/**
 * The private model rule (D-323 F3): when the person keeps this browser's content to private
 * models, page content goes only to a bot whose models all run privately. Otherwise Chrome's
 * built-in model answers on this computer, or nothing is sent.
 */
import type { CasamaClient } from "@casama/client";
import type { PageContext } from "./context.ts";
import type { Chips } from "./settings.ts";

/** Whether a message would carry anything from the page. */
export function carriesPage(chips: Chips, ctx: PageContext, extras: number): boolean {
  if (ctx.blocked) return extras > 0;
  return (
    extras > 0 ||
    chips.screenshot ||
    (chips.text && !!ctx.text) ||
    (chips.selection && !!ctx.selection) ||
    (chips.page && !!ctx.url)
  );
}

export type Verdict = "send" | "local" | "refuse";

/** What to do with a message under the rule. */
export function privateVerdict(o: {
  rule: boolean;
  carries: boolean;
  botPrivate: boolean;
  localModel: boolean;
}): Verdict {
  if (!o.rule || !o.carries || o.botPrivate) return "send";
  return o.localModel ? "local" : "refuse";
}

const cache = new Map<string, { at: number; value: boolean }>();
/** Whether every model [botId] uses runs privately, asked of the server (cached 5 minutes). */
export async function botIsPrivate(api: CasamaClient, botId: string): Promise<boolean> {
  const hit = cache.get(botId);
  if (hit && Date.now() - hit.at < 5 * 60_000) return hit.value;
  const r = await api.unwrap(
    api.GET("/v1/bots/{id}/model-privacy", { params: { path: { id: botId } } }),
  );
  cache.set(botId, { at: Date.now(), value: r.private_model });
  return r.private_model;
}

export const REFUSED =
  "You keep page content to private models (Settings, This browser as a device), and this bot uses a hosted model. Switch off the page chips, or ask a bot on a private model.";
