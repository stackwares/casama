/** Team computer layout (D-148): a folder per bot next to shared/, and a cap on desktop users. */
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import { serve } from "@hono/node-server";
import { teamFolder } from "@kasama/agent";
import { type ExecChunk, type ExecOptions, SupervisorProvider } from "@kasama/sandbox";
import type { SandboxStack } from "@kasama/sandbox/testing";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { createSupervisorApp } from "../../supervisor/src/app.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/team-computer.json", import.meta.url));
let h: Harness;
let owner: { id: string; token: string };
let orgId: string;
let teamId: string;
const bots = {} as Record<"Researcher" | "Designer" | "researcher!", string>;
const calls: string[] = [];

const handle = {
  ref: "team",
  health: async () => ({ ok: true }),
  async *exec(cmd: string, opts?: ExecOptions): AsyncIterable<ExecChunk> {
    calls.push(`exec ${cmd} @${opts?.cwd ?? ""}`);
    yield {
      type: "stdout",
      data: cmd.startsWith("agent-desktop") ? '{"ok":true,"data":"- window \\"Editor\\""}' : "",
    };
    yield { type: "exit", code: 0, timedOut: false, killed: false, truncated: false };
  },
  writeFile: async (p: string) => void calls.push(`write ${p}`),
  listDir: async (p: string) => {
    calls.push(`list ${p}`);
    return [];
  },
};

const waitFor = async <T>(
  fn: () => Promise<T | undefined | null | false>,
  what: string,
  ms = 30_000,
): Promise<T> => {
  const until = Date.now() + ms;
  for (;;) {
    const v = await fn();
    if (v) return v;
    if (Date.now() > until) throw new Error(`timed out waiting for ${what}`);
    await new Promise((r) => setTimeout(r, 100));
  }
};
async function say(bot: keyof typeof bots, text: string) {
  const conv = await j(
    await h.request("/v1/conversations", {
      method: "POST",
      token: owner.token,
      json: { bot_id: bots[bot] },
    }),
  );
  const runId = (
    await j(
      await h.request(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token: owner.token,
        json: { text },
      }),
    )
  ).run_id as string;
  await waitFor(
    async () =>
      ["completed", "failed"].includes(
        (await j(await h.request(`/v1/runs/${runId}`, { token: owner.token }))).status,
      ),
    "run",
  );
  const evs = (
    await j(await h.request(`/v1/runs/${runId}/events?limit=200`, { token: owner.token }))
  ).items as Array<{ type: string; payload: Record<string, unknown> }>;
  return { runId, evs };
}

// A real supervisor app in front of a fake computer, so the worker goes through the usual client.
const TOKEN = "supervisor-token-0123456789";
const fake = {
  id: "docker" as const,
  capabilities: { desktop: true, snapshots: true, liveStream: false },
  create: async () => handle,
  resume: async () => handle,
  get: async () => handle,
  sleep: async () => ({ key: "k", size: 0, createdAt: new Date().toISOString() }),
  destroy: async () => {},
  list: async () => [],
};
let sup: ReturnType<typeof serve>;

beforeAll(async () => {
  sup = serve({
    fetch: createSupervisorApp(fake as never, TOKEN).fetch,
    port: 0,
    hostname: "127.0.0.1",
  });
  await new Promise((r) => sup.once("listening", r));
  const url = `http://127.0.0.1:${(sup.address() as AddressInfo).port}`;
  const sandbox = {
    supervisorUrl: url,
    token: TOKEN,
    provider: new SupervisorProvider(url, TOKEN),
    turn: { secret: "t", host: "127.0.0.1", udpPort: 1, tcpPort: 1, container: "none" },
  };
  h = await startHarness({
    worker: { fixtures: FIXTURES },
    sandbox: sandbox as unknown as SandboxStack,
  });
  owner = await h.user("team-computer@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Team" } }),
    )
  ).id;
  const [team] = await h.tdb.admin<
    { id: string }[]
  >`update public.computers set profile = 'desktop' where org_id = ${orgId} and kind = 'team' returning id`;
  teamId = team!.id;
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-teamcomputer" },
    }),
  );
  for (const name of ["Researcher", "Designer", "researcher!"] as const) {
    bots[name] = (
      await j(
        await h.request("/v1/bots", {
          method: "POST",
          token: owner.token,
          json: {
            org_id: orgId,
            name,
            model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
          },
        }),
      )
    ).id;
  }
}, 60_000);
afterAll(async () => {
  await h?.stop();
  sup?.close();
});

describe("team computer layout", () => {
  it("each bot works in its own folder, told so in its prompt; shared/ is reachable from anywhere", async () => {
    const { evs } = await say("Researcher", "Please save the notes");
    expect(
      evs.find((e) => e.type === "tool.completed" && e.payload.call_id === "w1")?.payload,
    ).toMatchObject({ artifact_path: "bots/researcher/notes.md" });
    expect(calls).toContain(
      "exec mkdir -p /home/kasama/workspace/bots/researcher /home/kasama/workspace/shared @",
    );
    expect(calls).toContain("write bots/researcher/notes.md");
    expect(calls).toContain("list shared");
    // The folder name is kept on the bot, and a second bot with a clashing name gets its own.
    const rows = await h.tdb.admin<
      { name: string; team_folder: string | null }[]
    >`select name, team_folder from public.bots where org_id = ${orgId} order by name`;
    expect(rows.find((r) => r.name === "Researcher")?.team_folder).toBe("researcher");
    await h.tdb.admin`update public.bots set name = 'Scout' where id = ${bots.Researcher}`;
    expect(
      (
        await h.tdb.admin<
          { team_folder: string }[]
        >`select team_folder from public.bots where id = ${bots.Researcher}`
      )[0]?.team_folder,
    ).toBe("researcher");
    expect(await teamFolder(h.deps.db, bots["researcher!"])).toBe("researcher-2");
  });

  it("only max_desktops bots use the desktop at once; the lease ends with the run", async () => {
    // The Researcher holds the desktop right now.
    await h.tdb
      .admin`insert into public.computer_desktop_leases (computer_id, bot_id, org_id, expires_at) values (${teamId}, ${bots.Researcher}, ${orgId}, now() + interval '2 minutes')`;
    const busy = await say("Designer", "look at the screen");
    const failed = busy.evs.find((e) => e.type === "tool.failed")?.payload;
    expect(failed).toMatchObject({ error_code: "desktop_busy" });
    expect(String(failed?.message)).toContain("Scout");
    expect(calls.some((c) => c.startsWith("exec agent-desktop"))).toBe(false);

    // Only team computers take a cap; then two bots may share the screen.
    const [priv] = await h.tdb.admin<
      { id: string }[]
    >`insert into public.computers (org_id, kind, owner_bot_id, name, provider) values (${orgId}, 'private', ${bots.Designer}, 'D', 'e2b') returning id`;
    expect(
      (
        await h.request(`/v1/computers/${priv!.id}`, {
          method: "PATCH",
          token: owner.token,
          json: { max_desktops: 2 },
        })
      ).status,
    ).toBe(400);
    const set = await j(
      await h.request(`/v1/computers/${teamId}`, {
        method: "PATCH",
        token: owner.token,
        json: { max_desktops: 2 },
      }),
    );
    expect(set.max_desktops).toBe(2);
    await h.tdb.admin`delete from public.computers where id = ${priv!.id}`;
    const ok = await say("Designer", "look at the screen");
    expect(
      ok.evs.find((e) => e.type === "tool.completed" && e.payload.call_id === "d1"),
    ).toBeTruthy();
    expect(calls.some((c) => c.startsWith("exec agent-desktop snapshot"))).toBe(true);
    // The Designer's lease went with its run; the Researcher's is still there.
    // (Released in the run's finally, which can land just after the status changes.)
    await waitFor(async () => {
      const leases = await h.tdb.admin<
        { bot_id: string }[]
      >`select bot_id from public.computer_desktop_leases where computer_id = ${teamId}`;
      return leases.length === 1 && leases[0]?.bot_id === bots.Researcher;
    }, "lease released");
  });
});
