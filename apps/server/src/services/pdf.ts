/** Page PDFs (D-119): headless Chromium prints the same document the pages origin serves. */
import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";

export interface PdfRenderer {
  render(html: string): Promise<Uint8Array>;
}

/**
 * Flags for one print. The document carries the pages content security policy, and Chromium is
 * also pointed at a closed proxy with DNS mapped nowhere, so a missing or ignored policy cannot
 * fetch another host. File access outside the page is left at Chromium's default (off).
 * `--no-sandbox` is added only for root, which is the only way Chromium will start then.
 */
export function chromiumPdfArgs(
  paths: { profile: string; out: string; src: string },
  opts: { asRoot?: boolean } = {},
): string[] {
  const asRoot = opts.asRoot ?? (typeof process.getuid === "function" && process.getuid() === 0);
  return [
    "--headless",
    "--disable-gpu",
    "--no-first-run",
    "--no-default-browser-check",
    "--disable-extensions",
    "--disable-sync",
    "--disable-translate",
    "--disable-background-networking",
    "--disable-component-update",
    "--disable-domain-reliability",
    "--no-pdf-header-footer",
    "--host-resolver-rules=MAP * ~NOTFOUND",
    "--proxy-server=http://127.0.0.1:9",
    // Send loopback targets through that closed proxy too. The proxy connection itself is direct.
    "--proxy-bypass-list=<-loopback>",
    ...(asRoot ? ["--no-sandbox"] : []),
    `--user-data-dir=${paths.profile}`,
    `--print-to-pdf=${paths.out}`,
    `file://${paths.src}`,
  ];
}

/** Chromium's own `--print-to-pdf`. */
export function chromiumPdf(executable: string): PdfRenderer {
  const run = promisify(execFile);
  return {
    async render(html) {
      const dir = await mkdtemp(join(tmpdir(), "casama-pdf-"));
      try {
        const src = join(dir, "page.html");
        const out = join(dir, "page.pdf");
        await writeFile(src, html);
        await run(executable, chromiumPdfArgs({ profile: join(dir, "profile"), out, src }), {
          timeout: 60_000,
        });
        return new Uint8Array(await readFile(out));
      } finally {
        await rm(dir, { recursive: true, force: true });
      }
    },
  };
}
