import { createReadStream, createWriteStream } from "node:fs";
import { mkdir, readdir, rm, stat } from "node:fs/promises";
import { dirname, join, relative, resolve, sep } from "node:path";
import { Readable } from "node:stream";
import { pipeline } from "node:stream/promises";
import {
  CreateBucketCommand,
  DeleteObjectCommand,
  GetObjectCommand,
  HeadBucketCommand,
  ListObjectsV2Command,
  S3Client,
} from "@aws-sdk/client-s3";
import { Upload } from "@aws-sdk/lib-storage";

export interface StoredObject {
  key: string;
  size: number;
  lastModified: Date;
}

/** S3-compatible object storage (Supabase Storage, Cloudflare R2, MinIO) or a local directory. */
export interface ObjectStore {
  put(key: string, body: ReadableStream<Uint8Array> | Uint8Array): Promise<{ size: number }>;
  get(key: string): Promise<ReadableStream<Uint8Array>>;
  delete(key: string): Promise<void>;
  list(prefix: string): Promise<StoredObject[]>;
}

const toNodeStream = (body: ReadableStream<Uint8Array> | Uint8Array) =>
  body instanceof Uint8Array ? Readable.from([body]) : Readable.fromWeb(body as never);

/** Stores objects as files under a root directory (development and single-machine installs). */
export class FsObjectStore implements ObjectStore {
  readonly root: string;
  constructor(root: string) {
    this.root = resolve(root);
  }

  private path(key: string) {
    const p = resolve(this.root, key);
    if (p !== this.root && !p.startsWith(this.root + sep))
      throw new Error("object key escapes the store");
    return p;
  }

  async put(key: string, body: ReadableStream<Uint8Array> | Uint8Array) {
    const p = this.path(key);
    await mkdir(dirname(p), { recursive: true });
    const tmp = `${p}.part-${process.pid}-${Date.now()}`;
    await pipeline(toNodeStream(body), createWriteStream(tmp));
    const { rename } = await import("node:fs/promises");
    await rename(tmp, p);
    return { size: (await stat(p)).size };
  }

  async get(key: string) {
    const p = this.path(key);
    await stat(p);
    return Readable.toWeb(createReadStream(p)) as unknown as ReadableStream<Uint8Array>;
  }

  async delete(key: string) {
    await rm(this.path(key), { force: true });
  }

  async list(prefix: string) {
    const dir = this.path(prefix.endsWith("/") ? prefix : dirname(prefix));
    const out: StoredObject[] = [];
    const walk = async (d: string) => {
      let entries: import("node:fs").Dirent[];
      try {
        entries = await readdir(d, { withFileTypes: true });
      } catch {
        return;
      }
      for (const e of entries) {
        const full = join(d, e.name);
        if (e.isDirectory()) await walk(full);
        else if (!e.name.includes(".part-")) {
          const key = relative(this.root, full).split(sep).join("/");
          if (!key.startsWith(prefix)) continue;
          const s = await stat(full);
          out.push({ key, size: s.size, lastModified: s.mtime });
        }
      }
    };
    await walk(dir);
    return out.sort((a, b) => a.key.localeCompare(b.key));
  }
}

export interface S3StoreOptions {
  bucket: string;
  region?: string;
  endpoint?: string;
  accessKeyId?: string;
  secretAccessKey?: string;
  forcePathStyle?: boolean;
  prefix?: string;
}

export class S3ObjectStore implements ObjectStore {
  private readonly s3: S3Client;
  private readonly bucket: string;
  private readonly prefix: string;
  constructor(opts: S3StoreOptions) {
    this.bucket = opts.bucket;
    this.prefix = opts.prefix ?? "";
    this.s3 = new S3Client({
      region: opts.region ?? "auto",
      endpoint: opts.endpoint,
      forcePathStyle: opts.forcePathStyle ?? !!opts.endpoint,
      credentials:
        opts.accessKeyId && opts.secretAccessKey
          ? { accessKeyId: opts.accessKeyId, secretAccessKey: opts.secretAccessKey }
          : undefined,
    });
  }

  /** Creates the bucket if it does not exist (self-hosted S3 such as SeaweedFS). */
  async ensureBucket() {
    try {
      await this.s3.send(new HeadBucketCommand({ Bucket: this.bucket }));
    } catch {
      await this.s3.send(new CreateBucketCommand({ Bucket: this.bucket }));
    }
  }

  async put(key: string, body: ReadableStream<Uint8Array> | Uint8Array) {
    let size = 0;
    const counted = toNodeStream(body).on("data", (c: Buffer) => {
      size += c.length;
    });
    await new Upload({
      client: this.s3,
      params: { Bucket: this.bucket, Key: this.prefix + key, Body: counted },
    }).done();
    return { size };
  }

  async get(key: string) {
    const r = await this.s3.send(
      new GetObjectCommand({ Bucket: this.bucket, Key: this.prefix + key }),
    );
    if (!r.Body) throw new Error(`object ${key} has no body`);
    return r.Body.transformToWebStream() as ReadableStream<Uint8Array>;
  }

  async delete(key: string) {
    await this.s3.send(new DeleteObjectCommand({ Bucket: this.bucket, Key: this.prefix + key }));
  }

  async list(prefix: string) {
    const out: StoredObject[] = [];
    let token: string | undefined;
    do {
      const r = await this.s3.send(
        new ListObjectsV2Command({
          Bucket: this.bucket,
          Prefix: this.prefix + prefix,
          ContinuationToken: token,
        }),
      );
      for (const o of r.Contents ?? []) {
        if (o.Key)
          out.push({
            key: o.Key.slice(this.prefix.length),
            size: o.Size ?? 0,
            lastModified: o.LastModified ?? new Date(0),
          });
      }
      token = r.IsTruncated ? r.NextContinuationToken : undefined;
    } while (token);
    return out;
  }
}

/**
 * The object store a server process is configured with: S3 when OBJECT_STORE=s3, else a directory
 * when OBJECT_STORE_DIR is set, else none (D-276: the API and the worker keep Library files here).
 */
export function objectStoreFromEnv(env: Record<string, string | undefined>): ObjectStore | null {
  if (env.OBJECT_STORE === "s3") {
    if (!env.S3_BUCKET) throw new Error("S3_BUCKET is required when OBJECT_STORE=s3");
    return new S3ObjectStore({
      bucket: env.S3_BUCKET,
      endpoint: env.S3_ENDPOINT,
      region: env.S3_REGION,
      accessKeyId: env.S3_ACCESS_KEY_ID,
      secretAccessKey: env.S3_SECRET_ACCESS_KEY,
      prefix: env.S3_PREFIX,
    });
  }
  return env.OBJECT_STORE_DIR ? new FsObjectStore(env.OBJECT_STORE_DIR) : null;
}

/** Reads a whole object into memory (Library files are capped at 50 MB). */
export async function readObject(store: ObjectStore, key: string): Promise<Uint8Array> {
  const chunks: Uint8Array[] = [];
  const reader = (await store.get(key)).getReader();
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    if (value) chunks.push(value);
  }
  return new Uint8Array(Buffer.concat(chunks));
}
