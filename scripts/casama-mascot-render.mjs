// Renders the Casama cloud bot SVGs into app assets Flutter can play natively:
//   client/assets/mascots/<name>.webp  (animated, transparent, loops)
//   client/assets/mascots/<name>.png   (still pose)
// Needs Google Chrome and Python 3 with Pillow (WebP support).
// Run from the repo root after scripts/casama-cloud-svg.py:
//   node scripts/casama-mascot-render.mjs [size] [fps] [name ...]
// Pass names to render only some bots (run several processes in parallel to go faster).
import { execFileSync, spawn } from "node:child_process";
import { mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const SIZE = Number(process.argv[2] ?? 320);
const FPS = Number(process.argv[3] ?? 12);
const ONLY = process.argv.slice(4);
const LOOP = 8; // seconds, matches T in casama-cloud-svg.py
const SRC = "client/assets/bots";
const OUT = "client/assets/mascots";
const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const names = readdirSync(SRC)
  .filter((f) => f.endsWith("-animated.svg"))
  .map((f) => f.replace(/^casama-|-animated\.svg$/g, ""))
  .filter((n) => !ONLY.length || ONLY.includes(n));

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

for (const name of names) {
  const dir = mkdtempSync(join(tmpdir(), `casama-${name}-`));
  await load(readFileSync(join(SRC, `casama-${name}.svg`), "utf8"));
  await shot(join(OUT, `${name}.png`));
  await load(readFileSync(join(SRC, `casama-${name}-animated.svg`), "utf8"));
  const frames = Math.round(LOOP * FPS);
  for (let i = 0; i < frames; i++) {
    const t = i / FPS;
    await send("Runtime.evaluate", {
      expression: `(()=>{const s=document.querySelector('svg');s.pauseAnimations();s.setCurrentTime(${t});for(const a of document.getAnimations()){a.pause();a.currentTime=${t * 1000};}})()`,
    });
    await shot(join(dir, `f${String(i).padStart(4, "0")}.png`));
  }
  const _files = readdirSync(dir)
    .sort()
    .map((f) => join(dir, f));
  execFileSync(
    "python3",
    ["scripts/casama-mascot-encode.py", dir, join(OUT, `${name}.webp`), String(FPS)],
    { stdio: "inherit" },
  );
  rmSync(dir, { recursive: true, force: true });
  console.log(name, frames, "frames");
}
ws.close();
const exited = new Promise((r) => (chrome.exitCode !== null ? r() : chrome.once("exit", r)));
chrome.kill();
await Promise.race([exited, new Promise((r) => setTimeout(r, 3000))]);
if (chrome.exitCode === null) chrome.kill("SIGKILL");
rmSync(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });
process.exit(0);
