/**
 * Starts a throwaway sandbox stack in Docker for tests: an egress proxy and a supervisor
 * (with the Docker socket) on a private control network, using locally built images.
 */
import { execFile } from "node:child_process";
import { randomBytes } from "node:crypto";
import { promisify } from "node:util";
import { SupervisorProvider } from "./supervisor-client.ts";

const run = promisify(execFile);
const docker = async (...args: string[]) =>
  (await run("docker", args, { maxBuffer: 16 * 1024 * 1024 })).stdout.trim();

export interface SandboxStack {
  provider: SupervisorProvider;
  supervisorUrl: string;
  token: string;
  prefix: string;
  egressContainer: string;
  /** TURN relay reachable from this machine (for live-view tests). */
  turn: { secret: string; host: string; udpPort: number; tcpPort: number; container: string };
  stop(): Promise<void>;
}

export const TEST_IMAGES = {
  headless: process.env.TEST_COMPUTER_IMAGE ?? "casama/computer-headless:dev",
  desktop: process.env.TEST_DESKTOP_IMAGE ?? "casama/computer-desktop:dev",
  turn: process.env.TEST_TURN_IMAGE ?? "casama/turn:dev",
  supervisor: process.env.TEST_SUPERVISOR_IMAGE ?? "casama/supervisor:dev",
  egress: process.env.TEST_EGRESS_IMAGE ?? "casama/egress-proxy:dev",
};

export async function dockerAvailable() {
  try {
    await docker("info", "--format", "{{.ServerVersion}}");
    return true;
  } catch {
    return false;
  }
}

/**
 * Every stack carries the pid of the test process that made it, so a later run can remove stacks
 * whose process died before its afterAll ran (killed by turbo, a crash, Ctrl-C). Leaked stacks
 * otherwise pile up and use up Docker's address pools ("all predefined address pools have been
 * fully subnetted"), which then fails every Docker test on the machine.
 */
const OWNER_LABEL = "dev.casama.test.owner";

function processAlive(pid: number) {
  try {
    process.kill(pid, 0);
    return true;
  } catch (e) {
    // EPERM: it exists but belongs to someone else, so it's alive.
    return (e as NodeJS.ErrnoException).code === "EPERM";
  }
}

/** Removes everything a stack with this prefix made: its containers, computers, networks, homes. */
async function removeStack(prefix: string) {
  const containers = await docker("ps", "-aq", "--filter", `name=${prefix}-`).catch(() => "");
  if (containers) await docker("rm", "-f", ...containers.split("\n")).catch(() => {});
  const nets = await docker("network", "ls", "-q", "--filter", `name=${prefix}-`).catch(() => "");
  if (nets) await docker("network", "rm", ...nets.split("\n")).catch(() => {});
  const vols = await docker("volume", "ls", "-q", "--filter", `name=${prefix}-h-`).catch(() => "");
  if (vols) await docker("volume", "rm", "-f", ...vols.split("\n")).catch(() => {});
}

/** Removes test stacks whose owning test process is gone. Stacks of running tests are kept. */
export async function sweepOrphanedStacks() {
  const rows = await docker(
    "network",
    "ls",
    "--filter",
    `label=${OWNER_LABEL}`,
    "--format",
    `{{.Name}} {{.Label "${OWNER_LABEL}"}}`,
  ).catch(() => "");
  for (const row of rows.split("\n").filter(Boolean)) {
    const [name, pid] = row.split(" ");
    if (!name?.endsWith("-control") || processAlive(Number(pid))) continue;
    await removeStack(name.slice(0, -"-control".length));
  }
}

export async function startSandboxStack(
  opts: {
    egressExemptCidrs?: string;
    streamIdleStopMs?: number;
    warmPool?: number;
    /** host:port of a relay outside the stack that the relay container forwards computers to. */
    turnForwardTo?: string;
  } = {},
): Promise<SandboxStack> {
  const prefix = `kt${randomBytes(3).toString("hex")}`;
  const token = randomBytes(24).toString("hex");
  const egressToken = randomBytes(24).toString("hex");
  const control = `${prefix}-control`;
  const egress = `${prefix}-egress`;
  const sup = `${prefix}-sup`;
  const turnName = `${prefix}-turn`;
  const turnSecret = randomBytes(24).toString("hex");
  await sweepOrphanedStacks();
  const owner = `${OWNER_LABEL}=${process.pid}`;
  await docker("network", "create", "--label", "dev.casama.test=1", "--label", owner, control);
  try {
    await docker(
      "run",
      "-d",
      "--name",
      egress,
      "--network",
      control,
      "--label",
      "dev.casama.test=1",
      "--label",
      owner,
      "-e",
      `EGRESS_CONTROL_TOKEN=${egressToken}`,
      ...(opts.egressExemptCidrs ? ["-e", `EGRESS_EXEMPT_CIDRS=${opts.egressExemptCidrs}`] : []),
      TEST_IMAGES.egress,
    );
    // The default bridge gives the proxy (and only the proxy) a route to the internet.
    await docker("network", "connect", "bridge", egress);
    await docker(
      "run",
      "-d",
      "--name",
      turnName,
      "--network",
      control,
      "--label",
      "dev.casama.test=1",
      "--label",
      owner,
      "-p",
      "127.0.0.1::3478/udp",
      "-p",
      "127.0.0.1::3478/tcp",
      "-e",
      `TURN_SECRET=${turnSecret}`,
      // Casama Link (D-296): forward computers to a relay outside, as with remote access on.
      ...(opts.turnForwardTo
        ? [
            "-e",
            "TURN_FORWARD=on",
            "-e",
            `TURN_FORWARD_TO=${opts.turnForwardTo}`,
            ...(process.env.FORWARD_DEBUG ? ["-e", "FORWARD_DEBUG=1"] : []),
          ]
        : []),
      TEST_IMAGES.turn,
    );
    const turnPort = async (proto: string) =>
      Number((await docker("port", turnName, `3478/${proto}`)).split("\n")[0]?.split(":").pop());
    await docker(
      "run",
      "-d",
      "--name",
      sup,
      "--network",
      control,
      "--label",
      "dev.casama.test=1",
      "--label",
      owner,
      "-v",
      "/var/run/docker.sock:/var/run/docker.sock",
      "-p",
      "127.0.0.1::8788",
      "-e",
      `SUPERVISOR_TOKEN=${token}`,
      "-e",
      `COMPUTER_TOKEN_SECRET=${randomBytes(24).toString("hex")}`,
      "-e",
      `EGRESS_CONTAINER=${egress}`,
      "-e",
      `EGRESS_CONTROL_URL=http://${egress}:3129`,
      "-e",
      `EGRESS_CONTROL_TOKEN=${egressToken}`,
      "-e",
      `SUPERVISOR_CONTAINER=${sup}`,
      "-e",
      `NAME_PREFIX=${prefix}`,
      ...(opts.warmPool ? ["-e", `WARM_POOL_SIZE=${opts.warmPool}`] : []),
      "-e",
      `COMPUTER_IMAGE_HEADLESS=${TEST_IMAGES.headless}`,
      "-e",
      `COMPUTER_IMAGE_DESKTOP=${TEST_IMAGES.desktop}`,
      "-e",
      `TURN_SECRET=${turnSecret}`,
      "-e",
      `TURN_CONTAINER=${turnName}`,
      "-e",
      `STREAM_IDLE_STOP_MS=${opts.streamIdleStopMs ?? 60_000}`,
      "-e",
      "OBJECT_STORE_DIR=/data/objects",
      TEST_IMAGES.supervisor,
    );
    const port = (await docker("port", sup, "8788/tcp")).split("\n")[0]?.split(":").pop();
    const supervisorUrl = `http://127.0.0.1:${port}`;
    for (let i = 0; ; i++) {
      try {
        if ((await fetch(`${supervisorUrl}/healthz`)).ok) break;
      } catch {}
      if (i > 100)
        throw new Error(`supervisor did not start: ${await docker("logs", sup).catch(() => "")}`);
      await new Promise((r) => setTimeout(r, 100));
    }
    const provider = new SupervisorProvider(supervisorUrl, token);
    return {
      provider,
      supervisorUrl,
      token,
      prefix,
      egressContainer: egress,
      turn: {
        secret: turnSecret,
        host: "127.0.0.1",
        udpPort: await turnPort("udp"),
        tcpPort: await turnPort("tcp"),
        container: turnName,
      },
      async stop() {
        for (const ref of await provider.list().catch(() => [] as string[]))
          await provider.destroy(ref).catch(() => {});
        // The stack's own containers plus anything a failed test left behind.
        await removeStack(prefix);
      },
    };
  } catch (e) {
    // A stack that didn't finish starting removes what it did start.
    await removeStack(prefix);
    throw e;
  }
}

/** Runs a command in a container (for network isolation tests). */
export const dockerExec = (container: string, ...cmd: string[]) =>
  docker("exec", container, ...cmd);
