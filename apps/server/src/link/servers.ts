/**
 * Casama Link, cloud side (D-296): linking self-hosted servers to a workspace and keeping each
 * one's public address. See tunnels.ts for what an address is made of.
 *
 * No database transaction is held across a call to the tunnel provider: those calls can take longer
 * than a transaction may sit idle. Each change is claimed in the row first (status and generation),
 * then carried out, then confirmed, and whatever a failure leaves behind is finished by sweep().
 * A server whose connector stops working asks for its address again, which repairs the rest.
 */
import { createHash, randomBytes, randomInt } from "node:crypto";
import type { Database } from "@casama/db";
import { captureError } from "@casama/observability";
import { sql } from "drizzle-orm";
import { orgLimits } from "../billing/limits.ts";
import { type LinkCaller, newLinkKey } from "./keys.ts";
import {
  appHost,
  pagesHost,
  type TunnelOrigins,
  type TunnelProvider,
  TunnelProviderError,
  type TunnelState,
} from "./tunnels.ts";

/** Scopes of a key made by linking: neither can spend the workspace's money. */
export const LINK_SCOPES = ["remote_access", "push"] as const;

export class LinkError extends Error {
  readonly status: number;
  readonly code: string;
  constructor(status: number, code: string, message: string) {
    super(message);
    this.name = "LinkError";
    this.status = status;
    this.code = code;
  }
}

export type ServerStatus = "active" | "parked" | "released" | "suspended";

/** A timestamp as a raw query returns it. */
type Ts = string | Date;
const date = (v: Ts) => (v instanceof Date ? v : new Date(v));

export type ServerRow = {
  id: string;
  org_id: string;
  key_id: string | null;
  instance_id: string;
  instance_name: string;
  label: string;
  tunnel_id: string | null;
  generation: number;
  status: ServerStatus;
  status_reason: string | null;
  platform: string | null;
  version: string | null;
  last_seen_at: Ts | null;
  released_at: Ts | null;
  created_at: Ts;
};

export interface ServerInfo {
  instance_id: string;
  instance_name?: string;
  platform?: string;
  version?: string;
}

export interface SweepReport {
  mode: "off" | "dry-run" | "on";
  parked: number;
  removed: number;
  forgotten: number;
  failed: number;
}

export interface LinkServersOptions {
  db: Database;
  tunnels: TunnelProvider;
  /** The page where a workspace admin approves a link; the code is added as ?code=. */
  linkUrl: string;
  origins?: TunnelOrigins;
  now?: () => Date;
  /** A server not seen for this long loses its tunnel until it comes back (the address is kept). */
  parkAfterDays?: number;
  /** How long a parked or released address stays reserved. */
  keepDays?: number;
}

// No vowels, so a code never spells a word; no 0, 1, O or I.
const CODE_ALPHABET = "BCDFGHJKLMNPQRSTVWXZ23456789";
const LABEL_FIRST = "abcdefghjkmnpqrstuvwxyz";
const LABEL_REST = "abcdefghjkmnpqrstuvwxyz23456789";
const LINK_TTL_MS = 15 * 60_000;
export const LINK_POLL_SECONDS = 3;
const INSTANCE_ID = /^[A-Za-z0-9-]{8,64}$/;

const pick = (alphabet: string, n: number) =>
  Array.from({ length: n }, () => alphabet[randomInt(alphabet.length)]).join("");
const hash = (v: string) => createHash("sha256").update(v).digest("hex");
/** 12 characters, 59 bits: an address can't be guessed or found by scanning. */
export const newLabel = () => pick(LABEL_FIRST, 1) + pick(LABEL_REST, 11);
const newUserCode = () => `${pick(CODE_ALPHABET, 4)}-${pick(CODE_ALPHABET, 4)}`;
/** "k7qm 2xfd", "K7QM2XFD" and "k7qm-2xfd" are the same code. */
export const normalizeUserCode = (v: string) => {
  const s = v.toUpperCase().replace(/[^A-Z0-9]/g, "");
  return s.length === 8 ? `${s.slice(0, 4)}-${s.slice(4)}` : "";
};
const clip = (v: string | undefined, n: number) => (v ? v.slice(0, n) : null);

const COLUMNS = sql`id, org_id, key_id, instance_id, instance_name, label, tunnel_id, generation,
  status, status_reason, platform, version, last_seen_at, released_at, created_at`;

export class LinkServers {
  private readonly o: LinkServersOptions;
  private readonly db: Database;
  private readonly tunnels: TunnelProvider;
  private readonly now: () => Date;
  private readonly parkAfterDays: number;
  private readonly keepDays: number;

  constructor(o: LinkServersOptions) {
    this.o = o;
    this.db = o.db;
    this.tunnels = o.tunnels;
    this.now = o.now ?? (() => new Date());
    this.parkAfterDays = o.parkAfterDays ?? 14;
    this.keepDays = o.keepDays ?? 90;
  }

  get zone() {
    return this.tunnels.zone;
  }

  /** Now, as the database takes it (a timestamp in text). */
  private at() {
    return this.now().toISOString();
  }

  /** Tunnels held at the provider (it includes 1,000), or null when it didn't answer. */
  async tunnelCount() {
    try {
      return await this.tunnels.count();
    } catch {
      return null;
    }
  }

  addresses(label: string) {
    return {
      address: `https://${appHost(label, this.zone)}`,
      pages_address: `https://${pagesHost(label, this.zone)}`,
    };
  }

  // -------------------------------------------------------------------------
  // Linking
  // -------------------------------------------------------------------------

  /** A server asks to be linked. It shows the user code and keeps the device code to itself. */
  async startLink(info: ServerInfo) {
    if (!INSTANCE_ID.test(info.instance_id))
      throw new LinkError(400, "bad_instance", "A server needs an instance id");
    const name = (info.instance_name ?? "").trim().slice(0, 80) || "Casama server";
    const deviceCode = `kcl_${randomBytes(32).toString("base64url")}`;
    const expires = new Date(this.now().getTime() + LINK_TTL_MS);
    await this.db.execute(
      sql`delete from public.link_sign_in_requests where expires_at < ${this.at()}::timestamptz - interval '1 day'`,
    );
    for (let attempt = 0; ; attempt++) {
      const userCode = newUserCode();
      const rows = await this.db.execute<{ id: string }>(sql`
        insert into public.link_sign_in_requests
          (device_code_hash, user_code, instance_id, instance_name, platform, version, expires_at)
        values (${hash(deviceCode)}, ${userCode}, ${info.instance_id}, ${name},
                ${clip(info.platform, 40)}, ${clip(info.version, 40)}, ${expires.toISOString()}::timestamptz)
        on conflict (user_code) do nothing returning id`);
      if (rows.length) {
        const url = new URL(this.o.linkUrl);
        url.searchParams.set("code", userCode);
        return {
          device_code: deviceCode,
          user_code: userCode,
          verification_url: url.toString(),
          interval: LINK_POLL_SECONDS,
          expires_in: Math.round(LINK_TTL_MS / 1000),
        };
      }
      if (attempt >= 4) throw new LinkError(503, "try_again", "Couldn't make a code; try again");
    }
  }

  /** What the approval page shows before anyone approves. */
  async describeLink(userCode: string) {
    const code = normalizeUserCode(userCode);
    const [r] = await this.db.execute<{
      instance_name: string;
      platform: string | null;
      version: string | null;
      approved_at: Ts | null;
      expires_at: Ts;
    }>(sql`
      select instance_name, platform, version, approved_at, expires_at
      from public.link_sign_in_requests where user_code = ${code}`);
    if (!r || date(r.expires_at).getTime() <= this.now().getTime()) return null;
    return {
      user_code: code,
      instance_name: r.instance_name,
      platform: r.platform,
      version: r.version,
      approved: !!r.approved_at,
      expires_at: date(r.expires_at),
    };
  }

  /** A workspace admin approves the code their server shows (the caller has checked the role). */
  async approveLink(userCode: string, orgId: string, userId: string) {
    const code = normalizeUserCode(userCode);
    const [r] = await this.db.execute<{ instance_name: string }>(sql`
      update public.link_sign_in_requests
      set org_id = ${orgId}::uuid, approved_by = ${userId}::uuid, approved_at = ${this.at()}::timestamptz
      where user_code = ${code} and approved_at is null and expires_at > ${this.at()}::timestamptz
      returning instance_name`);
    if (!r)
      throw new LinkError(404, "link_not_found", "That code isn't valid any more. Start again.");
    await this.audit(orgId, { kind: "user", id: userId }, "casama_link.link_approved", null, {
      instance_name: r.instance_name,
    });
    return { instance_name: r.instance_name };
  }

  /** The server polls with its device code; once approved it gets its key, a single time. */
  async pollLink(deviceCode: string) {
    const [r] = await this.db.execute<{
      id: string;
      org_id: string | null;
      approved_by: string | null;
      approved_at: Ts | null;
      consumed_at: Ts | null;
      expires_at: Ts;
      instance_name: string;
    }>(sql`
      select id, org_id, approved_by, approved_at, consumed_at, expires_at, instance_name
      from public.link_sign_in_requests where device_code_hash = ${hash(deviceCode)}`);
    if (!r || r.consumed_at || date(r.expires_at).getTime() <= this.now().getTime())
      return { status: "expired" as const };
    if (!r.approved_at || !r.org_id) return { status: "pending" as const };
    const key = newLinkKey();
    const orgId = r.org_id;
    const made = await this.db.transaction(async (tx) => {
      // Two polls at once: only the one that marks the request gets a key.
      const taken = await tx.execute<{ id: string }>(sql`
        update public.link_sign_in_requests set consumed_at = ${this.at()}::timestamptz
        where id = ${r.id}::uuid and consumed_at is null returning id`);
      if (!taken.length) return null;
      const [org] = await tx.execute<{ name: string; suspended: boolean }>(sql`
        select name, suspended_at is not null as suspended from public.organizations where id = ${orgId}::uuid`);
      if (!org || org.suspended) return null;
      const [k] = await tx.execute<{ id: string }>(sql`
        insert into public.link_keys (org_id, key_hash, key_hint, instance_name, scopes, created_by)
        values (${orgId}::uuid, ${key.hash}, ${key.hint}, ${r.instance_name},
                ${`{${LINK_SCOPES.join(",")}}`}::text[], ${r.approved_by}::uuid)
        returning id`);
      await tx.execute(sql`
        insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
        values (${orgId}::uuid, 'user', ${r.approved_by}::uuid, 'casama_link.key_created', 'link_key',
                ${k?.id}::uuid, ${JSON.stringify({ instance_name: r.instance_name, scopes: LINK_SCOPES, via: "link" })}::jsonb)`);
      return { name: org.name };
    });
    if (!made) return { status: "expired" as const };
    return {
      status: "approved" as const,
      key: key.key,
      workspace: made.name,
      scopes: [...LINK_SCOPES],
    };
  }

  // -------------------------------------------------------------------------
  // A server's address
  // -------------------------------------------------------------------------

  private async find(orgId: string, instanceId: string) {
    const [row] = await this.db.execute<ServerRow>(sql`
      select ${COLUMNS} from public.link_servers
      where org_id = ${orgId}::uuid and instance_id = ${instanceId}`);
    return row ?? null;
  }

  private requireScope(caller: LinkCaller) {
    if (!caller.scopes.includes("remote_access"))
      throw new LinkError(
        403,
        "remote_access_unavailable",
        "This key can't give a server an address",
      );
  }

  /** Counted against the plan: every server that holds an address, connected or not. */
  private async overLimit(tx: Pick<Database, "execute">, orgId: string, exceptId?: string) {
    const limit = (await orgLimits(this.db, orgId)).remote_servers;
    const allowed = typeof limit === "number" ? limit : 1;
    const [n] = await tx.execute<{ n: number }>(sql`
      select count(*)::int as n from public.link_servers
      where org_id = ${orgId}::uuid and status in ('active', 'parked')
        and id is distinct from ${exceptId ?? null}::uuid`);
    return (n?.n ?? 0) >= allowed ? allowed : null;
  }

  /**
   * Gives the server its address and the connector's secret. Safe to repeat: the same server gets
   * the same address, and a tunnel that went missing is made again.
   */
  async provision(caller: LinkCaller, info: ServerInfo) {
    this.requireScope(caller);
    if (!INSTANCE_ID.test(info.instance_id))
      throw new LinkError(400, "bad_instance", "A server needs an instance id");
    const name = (info.instance_name ?? "").trim().slice(0, 80) || caller.instance;

    // Claim: find or make the row, with the checks, under a lock so two requests can't both pass.
    const row = await this.db.transaction(async (tx) => {
      await tx.execute(
        sql`select pg_advisory_xact_lock(hashtextextended(${`${caller.orgId}:${info.instance_id}`}, 7))`,
      );
      const [org] = await tx.execute<{ suspended: boolean }>(
        sql`select suspended_at is not null as suspended from public.organizations where id = ${caller.orgId}::uuid`,
      );
      if (!org || org.suspended)
        throw new LinkError(403, "suspended", "This workspace is suspended");
      const [existing] = await tx.execute<ServerRow>(sql`
        select ${COLUMNS} from public.link_servers
        where org_id = ${caller.orgId}::uuid and instance_id = ${info.instance_id} for update`);
      if (existing?.status === "suspended")
        throw new LinkError(403, "suspended", "Remote access was turned off for this server");
      // A released address no longer counts, so coming back from one is checked like a new server.
      if (!existing || existing.status === "released") {
        const allowed = await this.overLimit(tx, caller.orgId, existing?.id);
        if (allowed != null)
          throw new LinkError(
            402,
            "plan_limit",
            `Your plan connects ${allowed} ${allowed === 1 ? "server" : "servers"}. Remove one or upgrade to add more.`,
          );
      }
      if (existing) return existing;
      for (let attempt = 0; ; attempt++) {
        const [made] = await tx.execute<ServerRow>(sql`
          insert into public.link_servers (org_id, key_id, instance_id, instance_name, label, platform, version)
          values (${caller.orgId}::uuid, ${caller.keyId}::uuid, ${info.instance_id}, ${name}, ${newLabel()},
                  ${clip(info.platform, 40)}, ${clip(info.version, 40)})
          on conflict (label) do nothing returning ${COLUMNS}`);
        if (made) return made;
        if (attempt >= 4)
          throw new LinkError(503, "try_again", "Couldn't pick an address; try again");
      }
    });

    let tunnelId = row.status === "active" ? row.tunnel_id : null;
    let token: string | null = null;
    let changed = false;
    try {
      if (tunnelId) {
        try {
          token = await this.tunnels.token(tunnelId);
        } catch (e) {
          // The tunnel is gone (removed by hand, or by a sweep that raced this server coming back).
          if (!(e instanceof TunnelProviderError) || e.status !== 404) throw e;
          tunnelId = null;
        }
      }
      if (!tunnelId) {
        ({ tunnelId } = await this.tunnels.provision(row.label, this.o.origins));
        token = await this.tunnels.token(tunnelId);
        changed = true;
      }
    } catch (e) {
      throw this.providerFailure(e);
    }

    const [saved] = await this.db.execute<ServerRow>(sql`
      update public.link_servers
      set tunnel_id = ${tunnelId}, status = 'active', status_reason = null, released_at = null,
          generation = generation + ${changed || row.status !== "active" ? 1 : 0},
          key_id = ${caller.keyId}::uuid, instance_name = ${name},
          platform = coalesce(${clip(info.platform, 40)}, platform),
          version = coalesce(${clip(info.version, 40)}, version),
          last_seen_at = ${this.at()}::timestamptz, updated_at = ${this.at()}::timestamptz
      where id = ${row.id}::uuid returning ${COLUMNS}`);
    const now = saved ?? row;
    if (changed)
      await this.audit(row.org_id, { kind: "system" }, "casama_link.address_ready", row.id, {
        instance_name: name,
        label: row.label,
      });
    return {
      server_id: row.id,
      ...this.addresses(row.label),
      token: token as string,
      generation: now.generation,
    };
  }

  /**
   * The server says it is alive and learns whether its tunnel is still the one it holds.
   * ok: nothing to do. replaced or parked: ask for the address again. released, suspended and
   * unknown: it has no address until someone turns remote access on again.
   */
  async heartbeat(caller: LinkCaller, info: ServerInfo & { generation?: number }) {
    this.requireScope(caller);
    const [row] = await this.db.execute<ServerRow & { org_suspended: boolean }>(sql`
      update public.link_servers s
      set last_seen_at = ${this.at()}::timestamptz,
          version = coalesce(${clip(info.version, 40)}, s.version)
      from public.organizations o
      where o.id = s.org_id and s.org_id = ${caller.orgId}::uuid and s.instance_id = ${info.instance_id}
      returning s.id, s.org_id, s.key_id, s.instance_id, s.instance_name, s.label, s.tunnel_id, s.generation,
        s.status, s.status_reason, s.platform, s.version, s.last_seen_at, s.released_at, s.created_at,
        o.suspended_at is not null as org_suspended`);
    if (!row) return { status: "unknown" as const };
    const base = { generation: row.generation, ...this.addresses(row.label) };
    if (row.org_suspended || row.status === "suspended")
      return { status: "suspended" as const, reason: row.status_reason, ...base };
    if (row.status === "released")
      return { status: "released" as const, reason: row.status_reason, ...base };
    if (row.status === "parked" || !row.tunnel_id) return { status: "parked" as const, ...base };
    if (info.generation !== row.generation) return { status: "replaced" as const, ...base };
    return { status: "ok" as const, ...base };
  }

  /** The address and whether a connector is attached, for the server's own status screen. */
  async describe(caller: LinkCaller, instanceId: string) {
    this.requireScope(caller);
    const row = await this.find(caller.orgId, instanceId);
    if (!row) return null;
    let connector: TunnelState | null = null;
    if (row.status === "active" && row.tunnel_id) {
      try {
        connector = await this.tunnels.status(row.tunnel_id);
      } catch {
        // The provider not answering mustn't break the status screen.
      }
    }
    return {
      status: row.status,
      reason: row.status_reason,
      generation: row.generation,
      ...this.addresses(row.label),
      connector: connector
        ? { state: connector.state, since: connector.since?.toISOString() ?? null }
        : null,
      last_seen_at: row.last_seen_at ? date(row.last_seen_at).toISOString() : null,
    };
  }

  /** The server turns remote access off. Its address stays reserved for a while. */
  async release(caller: LinkCaller, instanceId: string) {
    this.requireScope(caller);
    const row = await this.find(caller.orgId, instanceId);
    if (!row) return false;
    if (row.status !== "suspended") await this.takeDown(row, "released", "turned_off");
    return true;
  }

  // -------------------------------------------------------------------------
  // Workspace admins and the instance owner
  // -------------------------------------------------------------------------

  async list(orgId?: string) {
    return this.db.execute<ServerRow & { org_name: string }>(sql`
      select s.id, s.org_id, s.key_id, s.instance_id, s.instance_name, s.label, s.tunnel_id, s.generation,
        s.status, s.status_reason, s.platform, s.version, s.last_seen_at, s.released_at, s.created_at,
        o.name as org_name
      from public.link_servers s join public.organizations o on o.id = s.org_id
      where ${orgId ?? null}::uuid is null or s.org_id = ${orgId ?? null}::uuid
      order by s.created_at desc limit 500`);
  }

  private async byId(id: string, orgId?: string) {
    const [row] = await this.db.execute<ServerRow>(sql`
      select ${COLUMNS} from public.link_servers
      where id = ${id}::uuid and (${orgId ?? null}::uuid is null or org_id = ${orgId ?? null}::uuid)`);
    return row ?? null;
  }

  /** A workspace admin removes a server, also one that is offline or gone: it frees the place. */
  async removeServer(orgId: string, serverId: string, userId: string) {
    const row = await this.byId(serverId, orgId);
    if (!row) return false;
    await this.takeDown(row, "released", "removed");
    await this.audit(orgId, { kind: "user", id: userId }, "casama_link.server_removed", row.id, {
      instance_name: row.instance_name,
    });
    return true;
  }

  /** The instance owner takes one address down (abuse). It stays down until lifted. */
  async suspendServer(serverId: string, reason: string, userId: string) {
    const row = await this.byId(serverId);
    if (!row) return false;
    await this.takeDown(row, "suspended", reason.slice(0, 200) || "suspended");
    await this.audit(
      row.org_id,
      { kind: "user", id: userId },
      "casama_link.server_suspended",
      row.id,
      {
        reason,
      },
    );
    return true;
  }

  /** Lifts a suspension: the server gets its tunnel back the next time it checks in. */
  async unsuspendServer(serverId: string, userId: string) {
    const [row] = await this.db.execute<ServerRow>(sql`
      update public.link_servers
      set status = 'parked', status_reason = null, updated_at = ${this.at()}::timestamptz
      where id = ${serverId}::uuid and status = 'suspended' returning ${COLUMNS}`);
    if (!row) return false;
    await this.audit(
      row.org_id,
      { kind: "user", id: userId },
      "casama_link.server_unsuspended",
      row.id,
      {},
    );
    return true;
  }

  /** A suspended workspace loses its addresses at once; sweep() would get to them anyway. */
  async suspendOrg(orgId: string) {
    const rows = await this.db.execute<ServerRow>(sql`
      select ${COLUMNS} from public.link_servers
      where org_id = ${orgId}::uuid and status in ('active', 'parked')`);
    for (const row of rows) await this.takeDown(row, "parked", "workspace_suspended");
    return rows.length;
  }

  /** A revoked key takes the addresses it made with it. */
  async releaseForKey(keyId: string) {
    const rows = await this.db.execute<ServerRow>(sql`
      select ${COLUMNS} from public.link_servers
      where key_id = ${keyId}::uuid and status in ('active', 'parked')`);
    for (const row of rows) await this.takeDown(row, "released", "key_revoked");
    return rows.length;
  }

  /**
   * Marks the row first (so the server is told at its next check-in whatever happens next), then
   * removes the tunnel. A removal that fails leaves `tunnel_id` set, and sweep() tries again.
   */
  private async takeDown(row: ServerRow, status: Exclude<ServerStatus, "active">, reason: string) {
    const [claimed] = await this.db.execute<{ generation: number; tunnel_id: string | null }>(sql`
      update public.link_servers
      set status = ${status}, status_reason = ${reason}, generation = generation + 1,
          released_at = case when ${status} = 'released' then ${this.at()}::timestamptz else released_at end,
          updated_at = ${this.at()}::timestamptz
      where id = ${row.id}::uuid and generation = ${row.generation}
      returning generation, tunnel_id`);
    // Someone else changed the row meanwhile (the server came back, or another removal): theirs stands.
    if (!claimed) return false;
    return this.removeTunnel(row.id, row.label, claimed.tunnel_id, claimed.generation);
  }

  private async removeTunnel(
    id: string,
    label: string,
    tunnelId: string | null,
    generation: number,
  ) {
    try {
      await this.tunnels.remove(label, tunnelId);
    } catch (e) {
      captureError(e, { where: "casama_link.remove_tunnel", server_id: id });
      return false;
    }
    await this.db.execute(sql`
      update public.link_servers set tunnel_id = null
      where id = ${id}::uuid and generation = ${generation} and status <> 'active'`);
    return true;
  }

  // -------------------------------------------------------------------------
  // Upkeep
  // -------------------------------------------------------------------------

  /**
   * Parks servers that haven't checked in for a while (the provider counts idle tunnels toward the
   * amount it includes), finishes removals that failed, and forgets addresses nobody came back for.
   *
   * Parking follows [mode]: on parks, dry-run only counts what it would park, off leaves idle
   * servers alone. The rest always runs: a tunnel whose removal failed, or one that belongs to a
   * suspended workspace, has to go whatever parking is set to.
   */
  async sweep(mode: "off" | "dry-run" | "on", limit = 100): Promise<SweepReport> {
    const report: SweepReport = { mode, parked: 0, removed: 0, forgotten: 0, failed: 0 };
    const now = this.at();
    if (mode !== "off") {
      const idle = await this.db.execute<ServerRow>(sql`
        select ${COLUMNS} from public.link_servers
        where status = 'active'
          and coalesce(last_seen_at, created_at) < ${now}::timestamptz - make_interval(days => ${this.parkAfterDays})
        order by coalesce(last_seen_at, created_at) limit ${limit}`);
      if (mode === "dry-run") report.parked = idle.length;
      else
        for (const row of idle) {
          if (await this.takeDown(row, "parked", "not_seen")) report.parked++;
          else report.failed++;
        }
    }
    // Removals that failed earlier, and servers of workspaces suspended since.
    const leftovers = await this.db.execute<ServerRow>(sql`
      select ${COLUMNS} from public.link_servers
      where status <> 'active' and tunnel_id is not null limit ${limit}`);
    for (const row of leftovers) {
      if (await this.removeTunnel(row.id, row.label, row.tunnel_id, row.generation))
        report.removed++;
      else report.failed++;
    }
    const suspended = await this.db.execute<ServerRow>(sql`
      select s.id, s.org_id, s.key_id, s.instance_id, s.instance_name, s.label, s.tunnel_id, s.generation,
        s.status, s.status_reason, s.platform, s.version, s.last_seen_at, s.released_at, s.created_at
      from public.link_servers s join public.organizations o on o.id = s.org_id
      where s.status = 'active' and o.suspended_at is not null limit ${limit}`);
    for (const row of suspended) {
      if (await this.takeDown(row, "parked", "workspace_suspended")) report.removed++;
      else report.failed++;
    }
    const forgotten = await this.db.execute<{ id: string }>(sql`
      delete from public.link_servers
      where tunnel_id is null
        and ((status = 'released' and released_at < ${now}::timestamptz - make_interval(days => ${this.keepDays}))
          or (status = 'parked' and coalesce(last_seen_at, created_at)
                < ${now}::timestamptz - make_interval(days => ${this.keepDays + this.parkAfterDays})))
      returning id`);
    report.forgotten = forgotten.length;
    return report;
  }

  private providerFailure(e: unknown) {
    if (e instanceof LinkError) return e;
    captureError(e, { where: "casama_link.provision" });
    const retry = e instanceof TunnelProviderError && e.retryable;
    return new LinkError(
      retry ? 503 : 502,
      "address_unavailable",
      "The address couldn't be set up just now. Try again in a minute.",
    );
  }

  private async audit(
    orgId: string,
    by: { kind: "user" | "system"; id?: string },
    action: string,
    serverId: string | null,
    metadata: Record<string, unknown>,
  ) {
    await this.db.execute(sql`
      insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${orgId}::uuid, ${by.kind}, ${by.id ?? null}::uuid, ${action}, 'link_server',
              ${serverId}::uuid, ${JSON.stringify(metadata)}::jsonb)`);
  }
}
