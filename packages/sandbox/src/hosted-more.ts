/**
 * More hosted sandbox providers (D-139). Each is a `HostedControlPlane`: it starts Casama's own
 * computer image (computerd inside) and tells `HostedProvider` how to reach computerd's port, so
 * files, exec, checkpoints, sleep and live view are the same code as on Docker, E2B and Daytona.
 * Request shapes come from each provider's public API docs; they are tested against local
 * stand-ins (src/testing-hosted.ts) through the shared contract suite.
 */
import {
  call,
  e2bControlPlane,
  type HostedControlPlane,
  HostedProvider,
  type HostedProviderOptions,
} from "./hosted.ts";
import { type ComputerSpec, SandboxError } from "./types.ts";

const shortRef = (ref: string) =>
  ref
    .replace(/[^a-z0-9]/gi, "")
    .toLowerCase()
    .slice(0, 20);
const wait = (ms: number) => new Promise((r) => setTimeout(r, ms));
const imageFor = (spec: ComputerSpec, images: { headless: string; desktop: string }) =>
  spec.profile === "desktop" ? images.desktop : images.headless;

// ---------------------------------------------------------------------------
// Novita Agent Sandbox: E2B-compatible API and port URLs, on Novita's domain.

export interface NovitaOptions {
  apiKey: string;
  templates: { headless: string; desktop: string };
  apiUrl?: string;
  domain?: string;
  timeoutS?: number;
  portUrl?: (sandboxId: string, port: number) => Promise<string> | string;
}

export function novitaControlPlane(o: NovitaOptions): HostedControlPlane {
  return e2bControlPlane({
    ...o,
    apiUrl: o.apiUrl ?? "https://api.sandbox.novita.ai",
    domain: o.domain ?? "sandbox.novita.ai",
  });
}

// ---------------------------------------------------------------------------
// Kubernetes: one Pod per computer, reached through the API server's pod proxy (or the pod IP
// when the supervisor runs inside the cluster).

export interface KubernetesOptions {
  /** API server, for example https://kubernetes.default.svc. */
  apiUrl: string;
  /** A service account token allowed to create, list, delete and proxy pods in the namespace. */
  token: string;
  namespace: string;
  images: { headless: string; desktop: string };
  /** Reach pods by IP (supervisor inside the cluster) instead of through the API server proxy. */
  direct?: boolean;
  imagePullSecret?: string;
  runtimeClassName?: string;
  /** A fetch that trusts the cluster's CA (tests and clusters with private CAs). */
  fetch?: typeof fetch;
}

type Pod = {
  metadata: { name: string; labels?: Record<string, string>; deletionTimestamp?: string };
  status?: { phase?: string; podIP?: string; conditions?: Array<{ type: string; status: string }> };
};

export function kubernetesControlPlane(o: KubernetesOptions): HostedControlPlane {
  const api = o.apiUrl.replace(/\/$/, "");
  const ns = encodeURIComponent(o.namespace);
  const headers = { authorization: `Bearer ${o.token}`, "content-type": "application/json" };
  const f = o.fetch;
  const pods = `${api}/api/v1/namespaces/${ns}/pods`;
  const ips = new Map<string, string>();
  return {
    async create(spec, env) {
      const name = `casama-${shortRef(spec.ref)}-${Date.now().toString(36)}`;
      const cpus = spec.size?.cpus;
      const mem = spec.size?.memoryMb;
      await call(
        pods,
        {
          method: "POST",
          headers,
          fetch: f,
          body: JSON.stringify({
            apiVersion: "v1",
            kind: "Pod",
            metadata: { name, labels: { app: "casama-computer", casama_ref: spec.ref } },
            spec: {
              restartPolicy: "Never",
              ...(o.runtimeClassName ? { runtimeClassName: o.runtimeClassName } : {}),
              ...(o.imagePullSecret ? { imagePullSecrets: [{ name: o.imagePullSecret }] } : {}),
              automountServiceAccountToken: false,
              containers: [
                {
                  name: "computer",
                  image: imageFor(spec, o.images),
                  env: Object.entries(env).map(([n, value]) => ({ name: n, value })),
                  ports: [{ containerPort: 7070 }, { containerPort: 8080 }],
                  ...(cpus || mem
                    ? {
                        resources: {
                          limits: {
                            ...(cpus ? { cpu: String(cpus) } : {}),
                            ...(mem ? { memory: `${mem}Mi` } : {}),
                          },
                        },
                      }
                    : {}),
                },
              ],
            },
          }),
        },
        "kubernetes",
      );
      for (let i = 0; i < 240; i++) {
        const p = await call<Pod>(`${pods}/${name}`, { headers, fetch: f }, "kubernetes");
        if (p.status?.phase === "Running" && p.status.podIP) {
          ips.set(name, p.status.podIP);
          return { id: name, running: true };
        }
        if (p.status?.phase === "Failed" || p.status?.phase === "Succeeded")
          throw new SandboxError("kubernetes_error", `Pod ${name} is ${p.status.phase}`);
        await wait(500);
      }
      throw new SandboxError("computer_start_timeout", "Kubernetes pod did not start");
    },
    async find(ref) {
      const list = await call<{ items: Pod[] }>(
        `${pods}?labelSelector=${encodeURIComponent(`casama_ref=${ref}`)}`,
        { headers, fetch: f },
        "kubernetes",
      );
      const hit = list.items.find(
        (p) => !p.metadata.deletionTimestamp && p.metadata.labels?.casama_ref === ref,
      );
      if (hit?.status?.podIP) ips.set(hit.metadata.name, hit.status.podIP);
      return hit ? { id: hit.metadata.name, running: hit.status?.phase === "Running" } : null;
    },
    async kill(id) {
      ips.delete(id);
      await call(
        `${pods}/${encodeURIComponent(id)}`,
        { method: "DELETE", headers, fetch: f, expect: [200, 202, 404] },
        "kubernetes",
      );
    },
    async endpoint(id, port): Promise<{ url: string; headers: Record<string, string> }> {
      if (o.direct) {
        const ip =
          ips.get(id) ??
          (await call<Pod>(`${pods}/${id}`, { headers, fetch: f }, "kubernetes")).status?.podIP;
        if (!ip) throw new SandboxError("kubernetes_error", `Pod ${id} has no IP`);
        return { url: `http://${ip}:${port}`, headers: {} };
      }
      return {
        url: `${pods}/${encodeURIComponent(id)}:${port}/proxy`,
        headers: { authorization: `Bearer ${o.token}` },
      };
    },
  };
}

// ---------------------------------------------------------------------------
// Incus: a system container from the computer image (OCI remote), reached on its bridge address.

export interface IncusOptions {
  /** Incus REST API, for example https://incus.internal:8443. */
  apiUrl: string;
  /** A bearer token (OIDC) or a fetch with the trusted client certificate. */
  token?: string;
  fetch?: typeof fetch;
  /** OCI registry that serves the computer images, for example https://ghcr.io. */
  registry: string;
  images: { headless: string; desktop: string };
  project?: string;
  profiles?: string[];
  /** Override for tests: where an instance port is reachable. */
  portUrl?: (name: string, port: number) => Promise<string> | string;
}

type IncusOp = {
  type?: string;
  operation?: string;
  metadata?: { id?: string; status?: string; err?: string };
};
type IncusInstance = { name: string; status: string; config?: Record<string, string> };

export function incusControlPlane(o: IncusOptions): HostedControlPlane {
  const api = o.apiUrl.replace(/\/$/, "");
  const q = o.project ? `project=${encodeURIComponent(o.project)}` : "";
  const qs = (extra = "") => [q, extra].filter(Boolean).join("&");
  const headers: Record<string, string> = {
    "content-type": "application/json",
    ...(o.token ? { authorization: `Bearer ${o.token}` } : {}),
  };
  const f = o.fetch;
  const req = <T>(path: string, init: RequestInit & { expect?: number[] } = {}) =>
    call<T>(`${api}${path}`, { headers, fetch: f, ...init }, "incus");
  const waitOp = async (op: IncusOp) => {
    if (op.type !== "async" || !op.operation) return;
    const r = await req<{ metadata?: { status?: string; err?: string } }>(
      `${op.operation}/wait?${qs("timeout=120")}`,
    );
    if (r.metadata?.status && r.metadata.status !== "Success")
      throw new SandboxError("incus_error", `Incus: ${r.metadata.err || r.metadata.status}`);
  };
  return {
    async create(spec, env) {
      const name = `casama-${shortRef(spec.ref)}-${Date.now().toString(36)}`;
      const config: Record<string, string> = { "user.casama_ref": spec.ref };
      for (const [k, v] of Object.entries(env)) config[`environment.${k}`] = v;
      if (spec.size?.cpus) config["limits.cpu"] = String(spec.size.cpus);
      if (spec.size?.memoryMb) config["limits.memory"] = `${spec.size.memoryMb}MiB`;
      await waitOp(
        await req<IncusOp>(`/1.0/instances?${qs()}`, {
          method: "POST",
          body: JSON.stringify({
            name,
            type: "container",
            start: true,
            config,
            ...(o.profiles ? { profiles: o.profiles } : {}),
            source: {
              type: "image",
              mode: "pull",
              server: o.registry,
              protocol: "oci",
              alias: imageFor(spec, o.images),
            },
          }),
        }),
      );
      return { id: name, running: true };
    },
    async find(ref) {
      const list = await req<{ metadata: IncusInstance[] }>(
        `/1.0/instances?${qs(`recursion=1&filter=${encodeURIComponent(`config.user.casama_ref eq ${ref}`)}`)}`,
      );
      const hit = (list.metadata ?? []).find((i) => i.config?.["user.casama_ref"] === ref);
      return hit ? { id: hit.name, running: hit.status === "Running" } : null;
    },
    async kill(id) {
      const path = `/1.0/instances/${encodeURIComponent(id)}`;
      const stop = await req<IncusOp>(`${path}/state?${qs()}`, {
        method: "PUT",
        body: JSON.stringify({ action: "stop", force: true, timeout: 10 }),
        expect: [200, 202, 404],
      }).catch(() => null);
      if (stop) await waitOp(stop).catch(() => {});
      const del = await req<IncusOp | null>(`${path}?${qs()}`, {
        method: "DELETE",
        expect: [200, 202, 404],
      });
      if (del) await waitOp(del).catch(() => {});
    },
    async endpoint(id, port) {
      if (o.portUrl) return { url: await o.portUrl(id, port), headers: {} };
      const st = await req<{
        metadata: {
          network?: Record<
            string,
            { addresses?: Array<{ family: string; address: string; scope: string }> }
          >;
        };
      }>(`/1.0/instances/${encodeURIComponent(id)}/state?${qs()}`);
      for (const [nic, n] of Object.entries(st.metadata.network ?? {})) {
        if (nic === "lo") continue;
        const a = n.addresses?.find((x) => x.family === "inet" && x.scope === "global");
        if (a) return { url: `http://${a.address}:${port}`, headers: {} };
      }
      throw new SandboxError("incus_error", `Instance ${id} has no address yet`);
    },
  };
}

// ---------------------------------------------------------------------------
// Boat (boat.dev): a persistent VM per computer. Boat doesn't run OCI images directly, so the
// setup script runs the computer image with Docker inside the VM; computerd's port is hosted
// publicly (computerd still needs its own token on every call).

export interface BoatOptions {
  apiKey: string;
  images: { headless: string; desktop: string };
  apiUrl?: string;
  /** small, default, large or xlarge. */
  type?: string;
  /** Seconds of idle before Boat archives the VM (null: never). */
  ttlSeconds?: number | null;
}

type BoatSandbox = { id: string; state?: string; labels?: Record<string, string> };

export function boatControlPlane(o: BoatOptions): HostedControlPlane {
  const api = (o.apiUrl ?? "https://boat.dev/api/v1").replace(/\/$/, "");
  const headers = { authorization: `Bearer ${o.apiKey}`, "content-type": "application/json" };
  const urls = new Map<string, string>();
  const sh = (v: string) => `'${v.replace(/'/g, "'\\''")}'`;
  return {
    async create(spec, env) {
      const image = imageFor(spec, o.images);
      const envFlags = Object.keys(env)
        .map((k) => `-e ${k}`)
        .join(" ");
      const setupScript = [
        "set -e",
        `docker pull ${sh(image)}`,
        `docker run -d --name casama-computer --restart unless-stopped -p 7070:7070 -p 8080:8080 ${envFlags} ${sh(image)}`,
      ].join("\n");
      const r = await call<{ sandbox: BoatSandbox }>(
        `${api}/sandboxes`,
        {
          method: "POST",
          headers: { ...headers, "idempotency-key": `casama-${spec.ref}-${Date.now()}` },
          body: JSON.stringify({
            name: `casama-${shortRef(spec.ref)}`,
            labels: { casama_ref: spec.ref, ...spec.labels },
            env,
            type: o.type ?? "default",
            ttlSeconds: o.ttlSeconds === undefined ? 3600 : o.ttlSeconds,
            setupScript,
          }),
          expect: [200, 201, 202],
        },
        "boat",
      );
      return { id: r.sandbox.id, running: true };
    },
    async find(ref) {
      const r = await call<{ sandboxes?: BoatSandbox[]; data?: BoatSandbox[] }>(
        `${api}/sandboxes?label=${encodeURIComponent(`casama_ref=${ref}`)}`,
        { headers },
        "boat",
      );
      const hit = (r.sandboxes ?? r.data ?? []).find(
        (s) => s.labels?.casama_ref === ref && s.state !== "deleted",
      );
      return hit ? { id: hit.id, running: (hit.state ?? "running") === "running" } : null;
    },
    async kill(id) {
      for (const k of [...urls.keys()]) if (k.startsWith(`${id}:`)) urls.delete(k);
      await call(
        `${api}/sandboxes/${encodeURIComponent(id)}`,
        { method: "DELETE", headers, expect: [200, 202, 204, 404] },
        "boat",
      );
    },
    async endpoint(id, port) {
      const key = `${id}:${port}`;
      const cached = urls.get(key);
      if (cached) return { url: cached, headers: {} };
      const r = await call<{ url: string }>(
        `${api}/sandboxes/${encodeURIComponent(id)}/host`,
        { method: "POST", headers, body: JSON.stringify({ port, public: true }) },
        "boat",
      );
      const url = r.url.replace(/\/$/, "");
      urls.set(key, url);
      return { url, headers: {} };
    },
  };
}

// ---------------------------------------------------------------------------
// Railway: a service per computer in one project, deployed from the computer image, with a
// Railway domain for each port Casama needs. GraphQL (backboard.railway.com/graphql/v2).

export interface RailwayOptions {
  /** An account or workspace token (Bearer), or a project token. */
  token: string;
  projectToken?: boolean;
  projectId: string;
  environmentId: string;
  images: { headless: string; desktop: string };
  apiUrl?: string;
  /** Tests: the scheme for service domains (Railway serves https). */
  domainScheme?: "https" | "http";
}

export function railwayControlPlane(o: RailwayOptions): HostedControlPlane {
  const api = o.apiUrl ?? "https://backboard.railway.com/graphql/v2";
  const headers = {
    "content-type": "application/json",
    ...(o.projectToken
      ? { "project-access-token": o.token }
      : { authorization: `Bearer ${o.token}` }),
  };
  const domains = new Map<string, string>();
  const gql = async <T>(query: string, variables: Record<string, unknown>) => {
    const r = await call<{ data?: T; errors?: Array<{ message: string }> }>(
      api,
      { method: "POST", headers, body: JSON.stringify({ query, variables }) },
      "railway",
    );
    if (r.errors?.length)
      throw new SandboxError(
        "railway_error",
        `Railway: ${r.errors.map((e) => e.message).join("; ")}`,
      );
    return r.data as T;
  };
  const nameOf = (ref: string) => `casama-${shortRef(ref)}`;
  return {
    async create(spec, env) {
      const r = await gql<{ serviceCreate: { id: string } }>(
        "mutation ($input: ServiceCreateInput!) { serviceCreate(input: $input) { id name } }",
        {
          input: {
            projectId: o.projectId,
            environmentId: o.environmentId,
            name: nameOf(spec.ref),
            source: { image: imageFor(spec, o.images) },
            variables: env,
          },
        },
      );
      await gql(
        "mutation ($serviceId: String!, $environmentId: String!) { serviceInstanceDeployV2(serviceId: $serviceId, environmentId: $environmentId) }",
        {
          serviceId: r.serviceCreate.id,
          environmentId: o.environmentId,
        },
      );
      return { id: r.serviceCreate.id, running: true };
    },
    async find(ref) {
      const r = await gql<{
        project: { services: { edges: Array<{ node: { id: string; name: string } }> } };
      }>("query ($id: String!) { project(id: $id) { services { edges { node { id name } } } } }", {
        id: o.projectId,
      });
      const hit = r.project.services.edges.find((e) => e.node.name === nameOf(ref));
      return hit ? { id: hit.node.id, running: true } : null;
    },
    async kill(id) {
      for (const k of [...domains.keys()]) if (k.startsWith(`${id}:`)) domains.delete(k);
      await gql("mutation ($id: String!) { serviceDelete(id: $id) }", { id }).catch((e: Error) => {
        if (!/not found/i.test(e.message)) throw e;
      });
    },
    async endpoint(id, port) {
      const key = `${id}:${port}`;
      let d = domains.get(key);
      if (!d) {
        const r = await gql<{ serviceDomainCreate: { domain: string } }>(
          "mutation ($input: ServiceDomainCreateInput!) { serviceDomainCreate(input: $input) { id domain } }",
          { input: { serviceId: id, environmentId: o.environmentId, targetPort: port } },
        );
        d = r.serviceDomainCreate.domain;
        domains.set(key, d);
      }
      return { url: `${o.domainScheme ?? "https"}://${d}`, headers: {} };
    },
  };
}

export const novitaProvider = (o: NovitaOptions, h: HostedProviderOptions) =>
  new HostedProvider("novita", novitaControlPlane(o), h);
export const kubernetesProvider = (o: KubernetesOptions, h: HostedProviderOptions) =>
  new HostedProvider("kubernetes", kubernetesControlPlane(o), h);
export const incusProvider = (o: IncusOptions, h: HostedProviderOptions) =>
  new HostedProvider("incus", incusControlPlane(o), h);
export const boatProvider = (o: BoatOptions, h: HostedProviderOptions) =>
  new HostedProvider("boat", boatControlPlane(o), h);
export const railwayProvider = (o: RailwayOptions, h: HostedProviderOptions) =>
  new HostedProvider("railway", railwayControlPlane(o), h);

/** A fetch that trusts a private CA and/or presents a client certificate (Kubernetes, Incus). */
export async function tlsFetch(o: {
  ca?: string;
  cert?: string;
  key?: string;
}): Promise<typeof fetch> {
  const { Agent, fetch: undiciFetch } = await import("undici");
  const dispatcher = new Agent({ connect: { ca: o.ca, cert: o.cert, key: o.key } });
  return ((url: string | URL | Request, init?: RequestInit) =>
    undiciFetch(
      url as string,
      { ...(init as object), dispatcher } as never,
    )) as unknown as typeof fetch;
}
