#!/usr/bin/env node
/**
 * Turns the mascots' Lottie animations (client/assets/mascots/*.json) into animated GIFs for
 * emails (site/email/*.gif). Email clients don't run Lottie (no JavaScript), but nearly all play
 * GIFs; Outlook on Windows shows the first frame.
 *
 * Each GIF is the mascot on Casama's lilac tile (#F1E2FC), with no transparency: GIF only has
 * hard-edged transparency, which would fringe in dark mode. The email rounds the tile's corners.
 * Defaults (12 fps, 192px, 64 colors, no dithering) keep each 8-second loop near 300 KB.
 *
 * Needs a headless Chromium, ffmpeg, and puppeteer-core plus lottie-web (not project
 * dependencies). One way:
 *   npm i --prefix /tmp/gifdeps puppeteer-core lottie-web
 *   NODE_PATH=/tmp/gifdeps/node_modules CHROMIUM=/path/to/chrome-headless-shell \
 *     node scripts/render-email-gifs.mjs winky lovey wow thinker focused shy
 */
import { execFileSync } from "node:child_process";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, statSync } from "node:fs";
import { createRequire } from "node:module";
import { tmpdir } from "node:os";
import { join } from "node:path";

const require = createRequire(join(process.env.NODE_PATH ?? ".", "noop.js"));
const puppeteer = require("puppeteer-core");
const lottiePath = require.resolve("lottie-web/build/player/lottie.min.js");

const SIZE = Number(process.env.SIZE ?? 192); // the email shows it at 112px; sharp on 2x screens
const FPS = Number(process.env.FPS ?? 12);
const SECONDS = Number(process.env.SECONDS ?? 0); // 0: the whole animation
const TILE = process.env.TILE ?? "#F1E2FC";
const COLORS = Number(process.env.COLORS ?? 64);
// No dithering by default: dither noise changes every frame, which defeats GIF's frame reuse.
const DITHER = process.env.DITHER ?? "none";
const root = new URL("..", import.meta.url).pathname;
const names = process.argv.slice(2);
if (!names.length) throw new Error("name the mascots to render, e.g. winky lovey");

const browser = await puppeteer.launch({
  executablePath: process.env.CHROMIUM,
  args: ["--no-sandbox", "--disable-gpu"],
});
try {
  for (const name of names) {
    const data = JSON.parse(readFileSync(join(root, `client/assets/mascots/${name}.json`), "utf8"));
    const total = data.op - data.ip;
    const length = SECONDS > 0 ? Math.min(total, SECONDS * data.fr) : total;
    const count = Math.round((length / data.fr) * FPS);
    const page = await browser.newPage();
    await page.setViewport({ width: SIZE, height: SIZE, deviceScaleFactor: 1 });
    await page.setContent(
      `<html><body style="margin:0;background:${TILE}"><div id="t" style="width:${SIZE}px;height:${SIZE}px;background:${TILE};display:flex;align-items:center;justify-content:center"><div id="a" style="width:${Math.round(SIZE * 0.88)}px;height:${Math.round(SIZE * 0.88)}px"></div></div></body></html>`,
    );
    await page.addScriptTag({ path: lottiePath });
    await page.evaluate((json) => {
      window.anim = window.lottie.loadAnimation({
        container: document.getElementById("a"),
        renderer: "svg",
        loop: false,
        autoplay: false,
        animationData: json,
      });
    }, data);
    const dir = mkdtempSync(join(tmpdir(), `gif-${name}-`));
    for (let i = 0; i < count; i++) {
      const frame = data.ip + (i * data.fr) / FPS;
      await page.evaluate((f) => window.anim.goToAndStop(f, true), frame);
      await page.screenshot({
        path: join(dir, `f${String(i).padStart(4, "0")}.png`),
        clip: { x: 0, y: 0, width: SIZE, height: SIZE },
      });
    }
    await page.close();
    mkdirSync(join(root, "site/email"), { recursive: true });
    const out = join(root, `site/email/${name}.gif`);
    execFileSync("ffmpeg", [
      "-y",
      "-loglevel",
      "error",
      "-framerate",
      String(FPS),
      "-i",
      join(dir, "f%04d.png"),
      "-vf",
      `split[a][b];[a]palettegen=stats_mode=diff:max_colors=${COLORS}[p];[b][p]paletteuse=dither=${DITHER}:diff_mode=rectangle`,
      "-loop",
      "0",
      out,
    ]);
    rmSync(dir, { recursive: true, force: true });
    // gifsicle (if installed) trims another few percent without visible loss.
    try {
      execFileSync("gifsicle", ["-O3", "--lossy=40", "--batch", out]);
    } catch {}
    const kb = Math.round(statSync(out).size / 1024);
    console.log(`wrote site/email/${name}.gif (${count} frames, ${kb} KB)`);
  }
} finally {
  await browser.close();
}
