/**
 * Two public DNS-over-HTTPS resolvers in one local server (the JSON form Cloudflare and Google
 * answer), for proving connected domains (D-329). Tests set records, make the two resolvers
 * disagree, or make one fail.
 */
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";

export interface FakeDnsZone {
  cname?: string;
  txt?: string[];
  ns?: string[];
  a?: string[];
}

export interface FakeDns {
  /** Both resolvers' URLs, comma-separated, for CASAMA_SITES_DOH_URLS. */
  urls: string;
  /** Records both resolvers see, by name. */
  records: Map<string, FakeDnsZone>;
  /** Records only resolver "b" sees differently (a stale cache). */
  staleB: Map<string, FakeDnsZone>;
  set(name: string, zone: FakeDnsZone): void;
  /** Adds to a name's records. */
  add(name: string, zone: FakeDnsZone): void;
  remove(name: string): void;
  /** The next [times] questions answer 500. */
  failNext(times?: number): void;
  /** Questions asked, as "type name". */
  asked: string[];
  env(): Record<string, string>;
  stop(): Promise<void>;
}

const TYPE = { A: 1, NS: 2, CNAME: 5, TXT: 16 } as const;

export async function startFakeDns(): Promise<FakeDns> {
  const records = new Map<string, FakeDnsZone>();
  const staleB = new Map<string, FakeDnsZone>();
  const asked: string[] = [];
  let failing = 0;

  const server: Server = createServer((req, res) => {
    const url = new URL(req.url ?? "/", "http://fake");
    const name = (url.searchParams.get("name") ?? "").toLowerCase().replace(/\.$/, "");
    const type = (url.searchParams.get("type") ?? "A").toUpperCase() as keyof typeof TYPE;
    asked.push(`${type} ${name}`);
    const send = (status: number, body: unknown) => {
      res.writeHead(status, { "content-type": "application/dns-json" });
      res.end(JSON.stringify(body));
    };
    if (failing > 0) {
      failing--;
      return send(500, {});
    }
    const which = url.pathname.startsWith("/b/") ? staleB : null;
    const lookup = (n: string) => (which?.get(n) ?? records.get(n)) || undefined;
    const zone = lookup(name);
    const answer: Array<{ name: string; type: number; TTL: number; data: string }> = [];
    if (type === "A") {
      // The CNAME chain on the way, then an address.
      let at = name;
      let z = zone;
      for (let i = 0; i < 6 && z?.cname; i++) {
        answer.push({ name: `${at}.`, type: TYPE.CNAME, TTL: 300, data: `${z.cname}.` });
        at = z.cname;
        z = lookup(at);
      }
      const addresses = z?.a ?? (answer.length ? ["192.0.2.10"] : []);
      for (const a of addresses) answer.push({ name: `${at}.`, type: TYPE.A, TTL: 300, data: a });
    } else if (type === "TXT")
      for (const t of zone?.txt ?? [])
        answer.push({ name: `${name}.`, type: TYPE.TXT, TTL: 300, data: `"${t}"` });
    else if (type === "NS")
      for (const n of zone?.ns ?? [])
        answer.push({ name: `${name}.`, type: TYPE.NS, TTL: 300, data: `${n}.` });
    if (!zone && !answer.length) return send(200, { Status: 3, Answer: [] });
    return send(200, { Status: 0, Answer: answer });
  });
  await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
  const base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  const urls = `${base}/a/dns-query,${base}/b/dns-query`;
  return {
    urls,
    records,
    staleB,
    asked,
    set: (name, zone) => void records.set(name.toLowerCase(), zone),
    add(name, zone) {
      const cur = records.get(name.toLowerCase()) ?? {};
      records.set(name.toLowerCase(), {
        ...cur,
        ...zone,
        txt: [...(cur.txt ?? []), ...(zone.txt ?? [])],
      });
    },
    remove: (name) => void records.delete(name.toLowerCase()),
    failNext(times = 1) {
      failing = times;
    },
    env: () => ({ CASAMA_SITES_DOH_URLS: urls }),
    stop: () => new Promise<void>((r) => server.close(() => r())),
  };
}
