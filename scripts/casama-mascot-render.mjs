// Renders SVGs to transparent PNGs with headless Chrome. Needs Google Chrome.
// Run from the repo root after scripts/casama-cloud-svg.py.
//
//   node scripts/casama-mascot-render.mjs [size=320] [name ...]
//       Still poses: client/assets/bots/casama-<name>.svg -> client/assets/mascots/<name>.png
//   node scripts/casama-mascot-render.mjs --svg <size> <in.svg> <out.png> [<in.svg> <out.png> ...]
//       Any square SVGs at <size> px (scripts/casama-mascot-lottie.py bakes the cloud body this way).
import { spawn } from "node:child_process";
import { mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const SRC = "client/assets/bots";
const OUT = "client/assets/mascots";
const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

const args = process.argv.slice(2);
let SIZE;
let jobs; // [in.svg, out.png]
if (args[0] === "--svg") {
  SIZE = Number(args[1]);
  jobs = [];
  for (let i = 2; i + 1 < args.length; i += 2) jobs.push([args[i], args[i + 1]]);
} else {
  SIZE = Number(args[0] ?? 320);
  const only = args.slice(1);
  jobs = readdirSync(SRC)
    .filter((f) => f.endsWith("-animated.svg"))
    .map((f) => f.replace(/^casama-|-animated\.svg$/g, ""))
    .filter((n) => !only.length || only.includes(n))
    .map((n) => [join(SRC, `casama-${n}.svg`), join(OUT, `${n}.png`)]);
}

const profile = mkdtempSync(join(tmpdir(), "casama-chrome-"));
const chrome = spawn(
  CHROME,
  [
    "--headless=new",
    "--remote-debugging-port=0",
    `--user-data-dir=${profile}`,
    "--hide-scrollbars",
    "about:blank",
  ],
  { stdio: ["ignore", "ignore", "pipe"] },
);
const wsUrl = await new Promise((res) =>
  chrome.stderr.on("data", (d) => {
    const m = /ws:\/\/\S+/.exec(String(d));
    if (m) res(m[0]);
  }),
);
const port = new URL(wsUrl).port;
const target = await (
  await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: "PUT" })
).json();
const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((r) => ws.addEventListener("open", r));
let seq = 0;
const pending = new Map();
ws.addEventListener("message", (e) => {
  const m = JSON.parse(e.data);
  if (m.id && pending.has(m.id)) {
    pending.get(m.id)(m);
    pending.delete(m.id);
  }
});
const send = (method, params = {}) =>
  new Promise((res, rej) => {
    const id = ++seq;
    pending.set(id, (m) =>
      m.error
        ? rej(new Error(`${method}: ${m.error.message} ${JSON.stringify(params).slice(0, 200)}`))
        : res(m.result),
    );
    ws.send(JSON.stringify({ id, method, params }));
  });

await send("Emulation.setDeviceMetricsOverride", {
  width: SIZE,
  height: SIZE,
  deviceScaleFactor: 1,
  mobile: false,
});
await send("Emulation.setDefaultBackgroundColorOverride", { color: { r: 0, g: 0, b: 0, a: 0 } });
const shot = async (file) =>
  writeFileSync(
    file,
    Buffer.from(
      (
        await send("Page.captureScreenshot", {
          format: "png",
          clip: { x: 0, y: 0, width: SIZE, height: SIZE, scale: 1 },
        })
      ).data,
      "base64",
    ),
  );
const load = async (svg) => {
  const html = `<!doctype html><html><body style="margin:0;background:transparent">${svg.replace("<svg ", `<svg width="${SIZE}" height="${SIZE}" `)}</body></html>`;
  await send("Runtime.evaluate", {
    expression: `document.open();document.write(${JSON.stringify(html)});document.close();`,
    awaitPromise: false,
  });
};

for (const [src, out] of jobs) {
  await load(readFileSync(src, "utf8"));
  await shot(out);
}
console.log(`rendered ${jobs.length} at ${SIZE}px`);

ws.close();
const exited = new Promise((r) => (chrome.exitCode !== null ? r() : chrome.once("exit", r)));
chrome.kill();
await Promise.race([exited, new Promise((r) => setTimeout(r, 3000))]);
if (chrome.exitCode === null) chrome.kill("SIGKILL");
rmSync(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });
process.exit(0);
