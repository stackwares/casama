import { request } from "node:http";
import { SandboxError } from "../types.ts";

/** Minimal Docker Engine API client over the Unix socket. */
export class DockerApi {
  readonly socketPath: string;
  readonly version: string;
  constructor(socketPath: string, version = "v1.47") {
    this.socketPath = socketPath;
    this.version = version;
  }

  call<T = unknown>(method: string, path: string, body?: unknown, okStatuses: number[] = [200, 201, 204, 304]): Promise<T> {
    return new Promise((resolve, reject) => {
      const data = body === undefined ? undefined : JSON.stringify(body);
      const req = request(
        {
          socketPath: this.socketPath,
          method,
          path: `/${this.version}${path}`,
          headers: data ? { "content-type": "application/json", "content-length": Buffer.byteLength(data) } : {},
        },
        (res) => {
          const chunks: Buffer[] = [];
          res.on("data", (c: Buffer) => chunks.push(c));
          res.on("end", () => {
            const text = Buffer.concat(chunks).toString();
            const status = res.statusCode ?? 0;
            if (!okStatuses.includes(status)) {
              let message = text;
              try {
                message = (JSON.parse(text) as { message?: string }).message ?? text;
              } catch {}
              return reject(new SandboxError(status === 404 ? "not_found" : "docker_error", `docker ${method} ${path}: ${status} ${message}`, status));
            }
            if (!text) return resolve(undefined as T);
            try {
              resolve(JSON.parse(text) as T);
            } catch {
              resolve(text as T);
            }
          });
        },
      );
      req.on("error", (err) => reject(new SandboxError("docker_unreachable", `docker socket: ${err.message}`)));
      if (data) req.write(data);
      req.end();
    });
  }

  async ping() {
    return (await this.call<string>("GET", "/_ping")) === "OK";
  }

  /** Returns null instead of throwing when the object does not exist. */
  async inspectOrNull<T>(path: string): Promise<T | null> {
    try {
      return await this.call<T>("GET", path);
    } catch (err) {
      if (err instanceof SandboxError && err.status === 404) return null;
      throw err;
    }
  }
}

export interface ContainerInspect {
  Id: string;
  Name: string;
  State: { Running: boolean; Status: string; ExitCode: number };
  Config: { Labels: Record<string, string>; Env: string[]; Image: string };
  NetworkSettings: { Networks: Record<string, { IPAddress: string }> };
}
