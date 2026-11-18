/**
 * Route 1 of signing in (plan §9.2, E1): "Connect Chrome" in the web app sends this extension a
 * sign-in link with `chrome.runtime.sendMessage(<extension id>, message)`. Chrome only delivers
 * messages from the pages the manifest's `externally_connectable` lists (app.casama.ai; the dev
 * build adds local addresses), and each page may only sign in to its own server.
 *
 * Messages:
 * - `{ type: "casama.ping" }` → `{ ok: true, version }`, so the web app can tell it's installed.
 * - `{ type: "casama.signIn", link }` → `{ ok: true, email }`, or `{ ok: true, pending: true }`
 *   when the first-run screen opened to finish it, or `{ ok: false, error }`.
 */
import { productName } from "../lib/browser.ts";
import { hasConsent } from "../lib/consent.ts";
import { gate, remoteConfig } from "../lib/remote-config.ts";
import { CLOUD_API, parseSignInLink } from "../lib/servers.ts";
import { signInWithLink } from "../lib/session.ts";
import { updateSession } from "../lib/store.ts";

export type HandoverMessage = { type: "casama.ping" } | { type: "casama.signIn"; link: string };
export type HandoverReply =
  | { ok: true; version?: string; email?: string; pending?: boolean }
  | { ok: false; error: string };

/**
 * Servers a page may sign this extension in to: Casama Cloud's web app only to Casama Cloud.
 * Undefined means any (a local web app in the dev build); null means the page may not at all.
 */
export function allowedServersFor(
  origin: string | undefined,
  target: "dev" | "store",
): string[] | undefined | null {
  if (origin === "https://app.casama.ai") return [CLOUD_API];
  if (target !== "dev") return null;
  if (origin === "https://app-dev.casama.ai") return ["https://api-dev.casama.ai"];
  if (origin && /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)) return undefined;
  return null;
}

export async function handleHandover(
  message: unknown,
  origin: string | undefined,
  target: "dev" | "store",
  openFirstRun: () => Promise<void>,
): Promise<HandoverReply> {
  const allowed = allowedServersFor(origin, target);
  if (allowed === null) return { ok: false, error: `This page can't sign ${productName()} in.` };
  const m = message as Partial<HandoverMessage & { link: unknown }> | null;
  if (m?.type === "casama.ping") return { ok: true, version: __CASAMA_VERSION__ };
  if (m?.type !== "casama.signIn" || typeof m.link !== "string" || m.link.length > 2000)
    return { ok: false, error: "Unknown message." };
  try {
    const { server } = parseSignInLink(m.link);
    if (!server || (allowed && !allowed.includes(server)))
      return { ok: false, error: "This page can't sign in to that server." };
    // The server's kill switch and minimum version apply here too.
    const g = gate(await remoteConfig(server), __CASAMA_VERSION__);
    if (g.state === "off") return { ok: false, error: `${productName()} is turned off for now.` };
    if (g.state === "update")
      return { ok: false, error: `Update ${productName()} to ${g.minVersion} or newer first.` };
    if (!(await hasConsent())) {
      // The person hasn't seen what the extension does yet: show that first, then finish.
      const link = m.link;
      await updateSession((s) => {
        s.pendingHandover = {
          link,
          at: Date.now(),
          ...(allowed ? { allowedServers: allowed } : {}),
        };
      });
      await openFirstRun();
      return { ok: true, pending: true };
    }
    const account = await signInWithLink(m.link, { allowedServers: allowed });
    return { ok: true, email: account.email };
  } catch (e) {
    return { ok: false, error: (e as Error).message };
  }
}
