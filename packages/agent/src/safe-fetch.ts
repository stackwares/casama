import { lookup } from "node:dns";
import { isIP } from "node:net";
import { Agent, fetch as undiciFetch } from "undici";
import { isBlocked, makeBlockList, makeExemptList } from "./net-policy.ts";

export class BlockedAddressError extends Error {
  readonly code = "blocked_address";
}

/**
 * fetch for calls the worker makes on a bot's behalf (http.request, MCP, OpenAPI, media downloads).
 * Every connection's resolved address is vetted at connect time, so private ranges, cloud metadata
 * and DNS rebinding are refused. `exemptCidrs` exists for tests and local development only.
 */
export function createSafeFetch(
  opts: { exemptCidrs?: string[]; timeoutMs?: number } = {},
): typeof fetch {
  const blocked = makeBlockList();
  const exempt = opts.exemptCidrs?.length ? makeExemptList(opts.exemptCidrs) : null;
  const denied = (ip: string) => isBlocked(blocked, ip) && !(exempt && isBlocked(exempt, ip));
  const agent = new Agent({
    connect: {
      timeout: opts.timeoutMs ?? 15_000,
      lookup(hostname, options, callback) {
        if (isIP(hostname)) {
          if (denied(hostname))
            return callback(new BlockedAddressError(`blocked address ${hostname}`), "", 0);
          return callback(null, hostname, isIP(hostname));
        }
        lookup(hostname, { all: true }, (err, addresses) => {
          if (err) return callback(err, "", 0);
          const list = addresses as Array<{ address: string; family: number }>;
          if (!list.length || list.some((a) => denied(a.address))) {
            return callback(new BlockedAddressError(`blocked address for ${hostname}`), "", 0);
          }
          const first = list[0] as { address: string; family: number };
          if ((options as { all?: boolean }).all)
            return (callback as unknown as (e: null, a: typeof list) => void)(null, list);
          callback(null, first.address, first.family);
        });
      },
    },
  });
  const f = ((input: Parameters<typeof fetch>[0], init?: RequestInit) => {
    const url = typeof input === "string" ? input : input instanceof URL ? input.href : input.url;
    const host = new URL(url).hostname.replace(/^\[|\]$/g, "");
    if (isIP(host) && denied(host))
      return Promise.reject(new BlockedAddressError(`blocked address ${host}`));
    return undiciFetch(
      input as never,
      { ...(init as object), dispatcher: agent } as never,
    ) as unknown as Promise<Response>;
  }) as typeof fetch;
  return f;
}

/** The default guarded fetch (no exemptions). */
export const safeFetch = createSafeFetch();

export function isBlockedError(err: unknown) {
  let e: unknown = err;
  for (let i = 0; i < 5 && e; i++) {
    if (e instanceof BlockedAddressError || (e as { code?: string }).code === "blocked_address")
      return true;
    e = (e as { cause?: unknown }).cause;
  }
  return false;
}
