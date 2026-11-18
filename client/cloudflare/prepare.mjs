// Gets build/web ready for the casama-app Worker (D-316). Run by scripts/deploy-app-web.sh.
//
// Cloudflare static assets take files up to 25 MiB each. Any build file at or past that size goes
// to the R2 bucket instead, under a key named after its content, with Brotli and gzip copies made
// here so the Worker sends compressed bytes without compressing on the fly. Source maps are never
// published (scripts/upload-symbols.sh sends them to error tracking).
//
// Writes, all under build/ (gitignored):
//   build/web/.assetsignore            what wrangler must not upload as static assets
//   build/web-host/large-files.json    path -> R2 key, bundled into the Worker
//   build/web-host/r2/<key>[.br|.gz]   the objects to upload
//   build/web-host/uploads.tsv         key, file, content type: one line per object
import { createHash } from "node:crypto";
import { mkdirSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { brotliCompressSync, constants, gzipSync } from "node:zlib";

const client = join(dirname(fileURLToPath(import.meta.url)), "..");
const web = join(client, "build/web");
const out = join(client, "build/web-host");
const LIMIT = 25 * 1024 * 1024;

const TYPES = {
  ".wasm": "application/wasm",
  ".js": "text/javascript",
  ".mjs": "text/javascript",
  ".json": "application/json",
  ".bin": "application/octet-stream",
};
const typeOf = (path) => TYPES[path.slice(path.lastIndexOf("."))] ?? "application/octet-stream";

function* walk(dir) {
  for (const name of readdirSync(dir)) {
    const full = join(dir, name);
    if (statSync(full).isDirectory()) yield* walk(full);
    else yield full;
  }
}

// Large files only reach the Worker if wrangler.jsonc sends their path to it first; otherwise the
// single-page fallback would answer with index.html.
const config = readFileSync(join(client, "wrangler.jsonc"), "utf8");
const workerFirst = new Set(
  [...(config.match(/"run_worker_first"\s*:\s*\[([^\]]*)\]/)?.[1] ?? "").matchAll(/"([^"]+)"/g)].map((m) => m[1]),
);

rmSync(out, { recursive: true, force: true });
mkdirSync(join(out, "r2"), { recursive: true });

const ignore = [".assetsignore", "*.map"];
const large = {};
const uploads = [];
const missing = [];

for (const file of walk(web)) {
  const path = "/" + relative(web, file).split("\\").join("/");
  if (path.endsWith(".map") || path === "/.assetsignore") continue;
  const size = statSync(file).size;
  if (size < LIMIT) continue;
  if (!workerFirst.has(path)) missing.push(path);

  const body = readFileSync(file);
  const hash = createHash("sha256").update(body).digest("hex");
  const key = `${hash.slice(0, 16)}${path}`;
  const type = typeOf(path);
  const br = brotliCompressSync(body, {
    params: {
      [constants.BROTLI_PARAM_QUALITY]: 11,
      [constants.BROTLI_PARAM_LGWIN]: 24,
      [constants.BROTLI_PARAM_SIZE_HINT]: body.length,
    },
  });
  const gz = gzipSync(body, { level: 9 });

  for (const [suffix, bytes] of [["", body], [".br", br], [".gz", gz]]) {
    const target = join(out, "r2", key + suffix);
    mkdirSync(dirname(target), { recursive: true });
    writeFileSync(target, bytes);
    uploads.push([key + suffix, relative(client, target), type].join("\t"));
  }
  large[path] = { key, hash, type, size };
  ignore.push(path.slice(1));
  const mb = (n) => (n / 1024 / 1024).toFixed(1);
  console.log(`R2: ${path} ${mb(size)} MB (Brotli ${mb(br.length)} MB, gzip ${mb(gz.length)} MB) as ${key}`);
}

if (missing.length) {
  console.error(
    `These files are over 25 MiB but client/wrangler.jsonc doesn't send them to the Worker first:\n  ${missing.join("\n  ")}\n` +
      'Add each path to assets.run_worker_first.',
  );
  process.exit(1);
}

writeFileSync(join(web, ".assetsignore"), ignore.join("\n") + "\n");
writeFileSync(join(out, "large-files.json"), JSON.stringify(large, null, 2) + "\n");
writeFileSync(join(out, "uploads.tsv"), uploads.length ? uploads.join("\n") + "\n" : "");
if (!uploads.length) console.log("No file is over 25 MiB; everything goes out as static assets.");
