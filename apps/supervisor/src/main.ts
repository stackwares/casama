import { existsSync, readFileSync } from "node:fs";
import {
  boatProvider,
  DockerApi,
  DockerProvider,
  daytonaProvider,
  e2bProvider,
  egressControl,
  FsObjectStore,
  incusProvider,
  kubernetesProvider,
  novitaProvider,
  railwayProvider,
  S3ObjectStore,
  type SandboxProvider,
  tlsFetch,
} from "@casama/sandbox";
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

if (store instanceof S3ObjectStore && env.S3_CREATE_BUCKET === "true") await store.ensureBucket();

// DEFAULT_PROVIDER (D-147): computers that ask for the default ("docker") run on this provider
// instead, for example kubernetes when the supervisor runs in a cluster without a Docker socket.
const defaultName = env.DEFAULT_PROVIDER || "docker";
const provider: SandboxProvider | undefined =
  defaultName !== "docker"
    ? undefined
    : new DockerProvider({
        docker: new DockerApi(env.DOCKER_SOCKET ?? "/var/run/docker.sock"),
        store,
        images: {
          headless: env.COMPUTER_IMAGE_HEADLESS ?? "ghcr.io/casama-dev/computer-headless:latest",
          desktop: env.COMPUTER_IMAGE_DESKTOP ?? "ghcr.io/casama-dev/computer-desktop:latest",
        },
        runtime: env.SANDBOX_RUNTIME || undefined,
        tokenSecret: need("COMPUTER_TOKEN_SECRET"),
        egress: {
          containerName: env.EGRESS_CONTAINER ?? "casama-egress",
          proxyPort: Number(env.EGRESS_PROXY_PORT ?? 3128),
          control: egressControl(
            env.EGRESS_CONTROL_URL ?? "http://casama-egress:3129",
            need("EGRESS_CONTROL_TOKEN"),
          ),
        },
        supervisorContainer: env.SUPERVISOR_CONTAINER,
        turn: env.TURN_SECRET
          ? {
              containerName: env.TURN_CONTAINER ?? "casama-turn",
              secret: env.TURN_SECRET,
              port: env.TURN_PORT ? Number(env.TURN_PORT) : undefined,
            }
          : undefined,
        namePrefix: env.NAME_PREFIX ?? "casama",
        defaults: {
          cpus: env.COMPUTER_CPUS ? Number(env.COMPUTER_CPUS) : undefined,
          memoryMb: env.COMPUTER_MEMORY_MB ? Number(env.COMPUTER_MEMORY_MB) : undefined,
        },
        // Warm pool (D-148): started headless computers waiting to be claimed; 0 turns it off.
        warmPool: Number(env.WARM_POOL_SIZE ?? 0) || undefined,
      });

// Hosted providers (D-056, D-057): same image and computerd, reached over the provider's port URLs.
const hostedOpts = {
  store,
  tokenSecret: need("COMPUTER_TOKEN_SECRET"),
  turn:
    env.TURN_SECRET && env.TURN_PUBLIC_HOST
      ? { host: env.TURN_PUBLIC_HOST, port: Number(env.TURN_PORT ?? 3478), secret: env.TURN_SECRET }
      : undefined,
};
const hosted: Record<string, SandboxProvider> = {};
if (env.E2B_API_KEY)
  hosted.e2b = e2bProvider(
    {
      apiKey: env.E2B_API_KEY,
      apiUrl: env.E2B_API_URL,
      templates: {
        headless: env.E2B_TEMPLATE_HEADLESS ?? "casama-computer-headless",
        desktop: env.E2B_TEMPLATE_DESKTOP ?? "casama-computer-desktop",
      },
    },
    hostedOpts,
  );
if (env.DAYTONA_API_KEY)
  hosted.daytona = daytonaProvider(
    {
      apiKey: env.DAYTONA_API_KEY,
      apiUrl: env.DAYTONA_API_URL,
      organizationId: env.DAYTONA_ORGANIZATION_ID,
      snapshots: {
        headless: env.DAYTONA_SNAPSHOT_HEADLESS ?? "casama-computer-headless",
        desktop: env.DAYTONA_SNAPSHOT_DESKTOP ?? "casama-computer-desktop",
      },
    },
    hostedOpts,
  );

// More hosted providers (D-139).
if (env.NOVITA_API_KEY)
  hosted.novita = novitaProvider(
    {
      apiKey: env.NOVITA_API_KEY,
      apiUrl: env.NOVITA_API_URL,
      templates: {
        headless: env.NOVITA_TEMPLATE_HEADLESS ?? "casama-computer-headless",
        desktop: env.NOVITA_TEMPLATE_DESKTOP ?? "casama-computer-desktop",
      },
    },
    hostedOpts,
  );
const images = {
  headless: env.HOSTED_IMAGE_HEADLESS ?? "ghcr.io/casama-dev/computer-headless:latest",
  desktop: env.HOSTED_IMAGE_DESKTOP ?? "ghcr.io/casama-dev/computer-desktop:latest",
};
if (env.K8S_NAMESPACE) {
  // In a cluster: the pod's service account and CA; outside: K8S_API_URL, K8S_TOKEN and K8S_CA_FILE.
  const sa = "/var/run/secrets/kubernetes.io/serviceaccount";
  const inCluster = !!env.KUBERNETES_SERVICE_HOST && existsSync(`${sa}/token`);
  const caFile = env.K8S_CA_FILE ?? (inCluster ? `${sa}/ca.crt` : undefined);
  hosted.kubernetes = kubernetesProvider(
    {
      apiUrl:
        env.K8S_API_URL ??
        `https://${env.KUBERNETES_SERVICE_HOST}:${env.KUBERNETES_SERVICE_PORT ?? 443}`,
      token: env.K8S_TOKEN ?? readFileSync(`${sa}/token`, "utf8").trim(),
      namespace: env.K8S_NAMESPACE,
      images,
      direct: inCluster,
      imagePullSecret: env.K8S_IMAGE_PULL_SECRET,
      runtimeClassName: env.K8S_RUNTIME_CLASS,
      fetch: caFile ? await tlsFetch({ ca: readFileSync(caFile, "utf8") }) : undefined,
    },
    hostedOpts,
  );
}
if (env.INCUS_URL)
  hosted.incus = incusProvider(
    {
      apiUrl: env.INCUS_URL,
      token: env.INCUS_TOKEN,
      registry: env.INCUS_REGISTRY ?? "https://ghcr.io",
      images: {
        headless: images.headless.replace(/^ghcr\.io\//, ""),
        desktop: images.desktop.replace(/^ghcr\.io\//, ""),
      },
      project: env.INCUS_PROJECT,
      fetch:
        env.INCUS_CLIENT_CERT_FILE || env.INCUS_CA_FILE
          ? await tlsFetch({
              cert: env.INCUS_CLIENT_CERT_FILE
                ? readFileSync(env.INCUS_CLIENT_CERT_FILE, "utf8")
                : undefined,
              key: env.INCUS_CLIENT_KEY_FILE
                ? readFileSync(env.INCUS_CLIENT_KEY_FILE, "utf8")
                : undefined,
              ca: env.INCUS_CA_FILE ? readFileSync(env.INCUS_CA_FILE, "utf8") : undefined,
            })
          : undefined,
    },
    hostedOpts,
  );

if (env.BOAT_API_KEY)
  hosted.boat = boatProvider(
    { apiKey: env.BOAT_API_KEY, apiUrl: env.BOAT_API_URL, images, type: env.BOAT_SANDBOX_TYPE },
    hostedOpts,
  );
if (env.RAILWAY_TOKEN && env.RAILWAY_PROJECT_ID && env.RAILWAY_ENVIRONMENT_ID)
  hosted.railway = railwayProvider(
    {
      token: env.RAILWAY_TOKEN,
      projectToken: env.RAILWAY_TOKEN_KIND === "project",
      projectId: env.RAILWAY_PROJECT_ID,
      environmentId: env.RAILWAY_ENVIRONMENT_ID,
      images,
    },
    hostedOpts,
  );

const port = Number(env.PORT ?? 8788);
const main = provider ?? hosted[defaultName];
if (!main) throw new Error(`DEFAULT_PROVIDER=${defaultName} isn't configured on this supervisor`);
startSupervisor(main, token, port, hosted);
console.log(
  JSON.stringify({
    msg: "supervisor listening",
    port,
    runtime: env.SANDBOX_RUNTIME || "default",
    default_provider: defaultName,
    hosted: Object.keys(hosted),
  }),
);
if (provider instanceof DockerProvider && provider.opts.warmPool) {
  const fill = () =>
    provider
      .fillPool()
      .catch((e: Error) =>
        console.error(JSON.stringify({ msg: "warm pool fill failed", error: e.message })),
      );
  void fill();
  setInterval(fill, 60_000).unref();
}
for (const s of ["SIGTERM", "SIGINT"] as const) process.once(s, () => process.exit(0));
