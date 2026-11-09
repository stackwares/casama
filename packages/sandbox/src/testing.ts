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
  stop(): Promise<void>;
}

export const TEST_IMAGES = {
  headless: process.env.TEST_COMPUTER_IMAGE ?? "kasama/computer-headless:dev",
  supervisor: process.env.TEST_SUPERVISOR_IMAGE ?? "kasama/supervisor:dev",
  egress: process.env.TEST_EGRESS_IMAGE ?? "kasama/egress-proxy:dev",
};

export async function dockerAvailable() {
  try {
    await docker("info", "--format", "{{.ServerVersion}}");
    return true;
  } catch {
    return false;
  }
}

export async function startSandboxStack(
  opts: { egressExemptCidrs?: string } = {},
): Promise<SandboxStack> {
  const prefix = `kt${randomBytes(3).toString("hex")}`;
  const token = randomBytes(24).toString("hex");
  const egressToken = randomBytes(24).toString("hex");
  const control = `${prefix}-control`;
  const egress = `${prefix}-egress`;
  const sup = `${prefix}-sup`;
  await docker("network", "create", "--label", "dev.kasama.test=1", control);
  await docker(
    "run",
    "-d",
    "--name",
    egress,
    "--network",
    control,
    "--label",
    "dev.kasama.test=1",
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
    sup,
    "--network",
    control,
    "--label",
    "dev.kasama.test=1",
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
    "-e",
    `COMPUTER_IMAGE_HEADLESS=${TEST_IMAGES.headless}`,
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
    async stop() {
      for (const ref of await provider.list().catch(() => [] as string[]))
        await provider.destroy(ref).catch(() => {});
      await docker("rm", "-f", sup, egress).catch(() => {});
      // Remove anything a failed test left behind.
      const leftovers = await docker("ps", "-aq", "--filter", `name=${prefix}-c-`).catch(() => "");
      if (leftovers) await docker("rm", "-f", ...leftovers.split("\n")).catch(() => {});
      const nets = await docker("network", "ls", "-q", "--filter", `name=${prefix}-`).catch(
        () => "",
      );
      if (nets) await docker("network", "rm", ...nets.split("\n")).catch(() => {});
      const vols = await docker("volume", "ls", "-q", "--filter", `name=${prefix}-h-`).catch(
        () => "",
      );
      if (vols) await docker("volume", "rm", "-f", ...vols.split("\n")).catch(() => {});
    },
  };
}

/** Runs a command in a container (for network isolation tests). */
export const dockerExec = (container: string, ...cmd: string[]) =>
  docker("exec", container, ...cmd);
