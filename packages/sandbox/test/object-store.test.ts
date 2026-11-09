import { execFile } from "node:child_process";
import { randomBytes } from "node:crypto";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import { CreateBucketCommand, S3Client } from "@aws-sdk/client-s3";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { FsObjectStore, type ObjectStore, S3ObjectStore } from "../src/object-store.ts";
import { dockerAvailable } from "../src/testing.ts";

const run = promisify(execFile);
const enabled = (await dockerAvailable()) && process.env.SKIP_DOCKER_TESTS !== "1";
const SEAWEED = process.env.TEST_SEAWEEDFS_IMAGE ?? "chrislusf/seaweedfs:4.53";

const read = async (s: ReadableStream<Uint8Array>) =>
  Buffer.from(await new Response(s).arrayBuffer());

function storeContract(name: string, make: () => ObjectStore) {
  describe(`ObjectStore: ${name}`, () => {
    it("puts, streams back and deletes large objects", async () => {
      const store = make();
      const data = randomBytes(12 * 1024 * 1024 + 7);
      const half = data.length >> 1;
      const body = new ReadableStream<Uint8Array>({
        start(c) {
          c.enqueue(data.subarray(0, half));
          c.enqueue(data.subarray(half));
          c.close();
        },
      });
      expect((await store.put("snapshots/a/home.tar.gz", body)).size).toBe(data.length);
      expect((await read(await store.get("snapshots/a/home.tar.gz"))).equals(data)).toBe(true);
      await store.delete("snapshots/a/home.tar.gz");
      await expect(store.get("snapshots/a/home.tar.gz")).rejects.toThrow();
    }, 60_000);
  });
}

describe("object stores", () => {
  let dir: string;
  beforeAll(async () => {
    dir = await mkdtemp(join(tmpdir(), "kasama-store-"));
  });
  afterAll(async () => rm(dir, { recursive: true, force: true }));
  storeContract("filesystem", () => new FsObjectStore(dir));
});

// S3-compatible self-hosted storage (SeaweedFS, D-062); the same code talks to R2 and AWS S3.
describe.skipIf(!enabled)("object stores on S3", () => {
  const name = `kseaweed-${randomBytes(3).toString("hex")}`;
  let endpoint = "";
  let cfgDir = "";
  const creds = { accessKeyId: "kasama-test", secretAccessKey: randomBytes(16).toString("hex") };
  beforeAll(async () => {
    cfgDir = await mkdtemp(join(tmpdir(), "kasama-s3cfg-"));
    await writeFile(
      join(cfgDir, "s3.json"),
      JSON.stringify({
        identities: [
          {
            name: "kasama",
            credentials: [{ accessKey: creds.accessKeyId, secretKey: creds.secretAccessKey }],
            actions: ["Read", "Write", "List", "Admin"],
          },
        ],
      }),
    );
    await run("docker", [
      "run",
      "-d",
      "--name",
      name,
      "--label",
      "dev.kasama.test=1",
      "-p",
      "127.0.0.1::8333",
      "-v",
      `${cfgDir}:/etc/kasama:ro`,
      SEAWEED,
      "server",
      "-s3",
      "-s3.config=/etc/kasama/s3.json",
      "-dir=/data",
    ]);
    const port = (await run("docker", ["port", name, "8333/tcp"])).stdout
      .trim()
      .split("\n")[0]
      ?.split(":")
      .pop();
    endpoint = `http://127.0.0.1:${port}`;
    const s3 = new S3Client({
      endpoint,
      region: "us-east-1",
      forcePathStyle: true,
      credentials: creds,
    });
    for (let i = 0; ; i++) {
      try {
        await s3.send(new CreateBucketCommand({ Bucket: "kasama" }));
        break;
      } catch (err) {
        if (i > 60) throw err;
        await new Promise((r) => setTimeout(r, 500));
      }
    }
  }, 120_000);
  afterAll(async () => {
    await run("docker", ["rm", "-f", name]).catch(() => {});
    await rm(cfgDir, { recursive: true, force: true });
  });

  storeContract(
    "s3 (SeaweedFS)",
    () =>
      new S3ObjectStore({
        bucket: "kasama",
        endpoint,
        region: "us-east-1",
        prefix: "t/",
        ...creds,
      }),
  );

  it("creates a missing bucket once", async () => {
    const store = new S3ObjectStore({
      bucket: "kasama-new",
      endpoint,
      region: "us-east-1",
      ...creds,
    });
    await store.ensureBucket();
    await store.ensureBucket();
    expect((await store.put("k", new Uint8Array([1, 2, 3]))).size).toBe(3);
  });

  it("rejects requests without valid credentials", async () => {
    const bad = new S3ObjectStore({
      bucket: "kasama",
      endpoint,
      region: "us-east-1",
      accessKeyId: "nope",
      secretAccessKey: "wrong-secret",
    });
    await expect(bad.put("x", new Uint8Array([1]))).rejects.toThrow();
  });
});
