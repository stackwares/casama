import { DockerApi, DockerProvider, egressControl, FsObjectStore, S3ObjectStore } from "@kasama/sandbox";
import { startSupervisor } from "./app.ts";

const env = process.env;
const need = (k: string) => {
  const v = env[k];
  if (!v) throw new Error(`${k} is required`);
  return v;
};
const token = need("SUPERVISOR_TOKEN");
if (token.length < 16) throw new Error("SUPERVISOR_TOKEN must be at least 16 characters");

const store =
  env.OBJECT_STORE === "s3"
    ? new S3ObjectStore({
        bucket: need("S3_BUCKET"),
        endpoint: env.S3_ENDPOINT,
        region: env.S3_REGION,
        accessKeyId: env.S3_ACCESS_KEY_ID,
        secretAccessKey: env.S3_SECRET_ACCESS_KEY,
        prefix: env.S3_PREFIX,
      })
    : new FsObjectStore(env.OBJECT_STORE_DIR ?? "/data/objects");

const provider = new DockerProvider({
  docker: new DockerApi(env.DOCKER_SOCKET ?? "/var/run/docker.sock"),
  store,
  images: {
    headless: env.COMPUTER_IMAGE_HEADLESS ?? "ghcr.io/kasama-dev/computer-headless:latest",
    desktop: env.COMPUTER_IMAGE_DESKTOP ?? "ghcr.io/kasama-dev/computer-desktop:latest",
  },
  runtime: env.SANDBOX_RUNTIME || undefined,
  tokenSecret: need("COMPUTER_TOKEN_SECRET"),
  egress: {
    containerName: env.EGRESS_CONTAINER ?? "kasama-egress",
    proxyPort: Number(env.EGRESS_PROXY_PORT ?? 3128),
    control: egressControl(env.EGRESS_CONTROL_URL ?? "http://kasama-egress:3129", need("EGRESS_CONTROL_TOKEN")),
  },
  supervisorContainer: env.SUPERVISOR_CONTAINER,
  namePrefix: env.NAME_PREFIX ?? "kasama",
  defaults: {
    cpus: env.COMPUTER_CPUS ? Number(env.COMPUTER_CPUS) : undefined,
    memoryMb: env.COMPUTER_MEMORY_MB ? Number(env.COMPUTER_MEMORY_MB) : undefined,
  },
});

const port = Number(env.PORT ?? 8788);
startSupervisor(provider, token, port);
console.log(JSON.stringify({ msg: "supervisor listening", port, runtime: env.SANDBOX_RUNTIME || "default" }));
for (const s of ["SIGTERM", "SIGINT"] as const) process.once(s, () => process.exit(0));
