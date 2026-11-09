/** Copied from infra/egress-proxy/src/policy.ts (the proxy image has no workspace dependencies). Keep both in sync. */
import { BlockList, isIP } from "node:net";

/** Address ranges a computer may never reach: private, loopback, link-local (cloud metadata), CGNAT, multicast, reserved. */
export const DEFAULT_BLOCKED_CIDRS = [
  "0.0.0.0/8",
  "10.0.0.0/8",
  "100.64.0.0/10",
  "127.0.0.0/8",
  "169.254.0.0/16",
  "172.16.0.0/12",
  "192.0.0.0/24",
  "192.0.2.0/24",
  "192.168.0.0/16",
  "198.18.0.0/15",
  "198.51.100.0/24",
  "203.0.113.0/24",
  "224.0.0.0/4",
  "240.0.0.0/4",
  "::/128",
  "::1/128",
  "64:ff9b::/96",
  "100::/64",
  "fc00::/7",
  "fe80::/10",
  "ff00::/8",
];

export function makeBlockList(extra: string[] = []) {
  const list = new BlockList();
  for (const cidr of [...DEFAULT_BLOCKED_CIDRS, ...extra]) {
    const [net, bits] = cidr.split("/");
    if (!net || !bits) continue;
    list.addSubnet(net, Number(bits), isIP(net) === 6 ? "ipv6" : "ipv4");
  }
  return list;
}

/** A list of only the given CIDRs (for exemptions). */
export function makeExemptList(cidrs: string[]) {
  const list = new BlockList();
  for (const cidr of cidrs) {
    const [net, bits] = cidr.split("/");
    if (net && bits) list.addSubnet(net, Number(bits), isIP(net) === 6 ? "ipv6" : "ipv4");
  }
  return list;
}

/** True when the address is in a blocked range. IPv4-mapped IPv6 is checked as IPv4. */
export function isBlocked(list: BlockList, ip: string) {
  const mapped = ip.match(/^::ffff:(\d+\.\d+\.\d+\.\d+)$/i)?.[1];
  if (mapped) return list.check(mapped, "ipv4");
  const family = isIP(ip);
  if (family === 0) return true;
  return list.check(ip, family === 6 ? "ipv6" : "ipv4");
}

export interface DomainRules {
  /** When non-empty, only these domains (and their subdomains) are allowed. */
  allow?: string[];
  deny?: string[];
}

const matchesDomain = (host: string, rule: string) => {
  const r = rule.toLowerCase().replace(/^\*\./, "").replace(/\.$/, "");
  return host === r || host.endsWith(`.${r}`);
};

export function domainAllowed(host: string, rules: DomainRules) {
  const h = host.toLowerCase().replace(/\.$/, "");
  if (rules.deny?.some((d) => matchesDomain(h, d))) return false;
  if (rules.allow?.length) return rules.allow.some((d) => matchesDomain(h, d));
  return true;
}
