/** Page PDFs (D-119): headless Chromium prints the same document the pages origin serves. */
import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";

export interface PdfRenderer {
  render(html: string): Promise<Uint8Array>;
}

/** Chromium's own `--print-to-pdf`; the page's CSP already blocks network requests. */
export function chromiumPdf(executable: string): PdfRenderer {
  const run = promisify(execFile);
  return {
    async render(html) {
      const dir = await mkdtemp(join(tmpdir(), "casama-pdf-"));
      try {
        const src = join(dir, "page.html");
        const out = join(dir, "page.pdf");
        await writeFile(src, html);
        await run(
          executable,
          [
            "--headless",
            "--disable-gpu",
            "--no-sandbox",
            "--no-first-run",
            "--disable-extensions",
            "--no-pdf-header-footer",
            `--user-data-dir=${join(dir, "profile")}`,
            `--print-to-pdf=${out}`,
            `file://${src}`,
          ],
          { timeout: 60_000 },
        );
        return new Uint8Array(await readFile(out));
      } finally {
        await rm(dir, { recursive: true, force: true });
      }
    },
  };
}
