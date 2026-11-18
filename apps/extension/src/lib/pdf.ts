/**
 * PDFs (A5): the text of a PDF open in the tab, read with the bundled pdf.js on this computer.
 * Chrome's own viewer can't be scripted, so the file is fetched again by its address (allowed by
 * site access, or the PDF's own server).
 */
import workerUrl from "pdfjs-dist/legacy/build/pdf.worker.min.mjs?url";

export function looksLikePdf(url: string | undefined): boolean {
  if (!url) return false;
  try {
    const u = new URL(url);
    return /\.pdf$/i.test(u.pathname) || u.hostname === "mhjfbmdgcfjbbpaeojofohoefgiehjai";
  } catch {
    return false;
  }
}

/** Up to [maxChars] of the PDF's text, page by page, with its page count. */
export async function pdfText(
  data: Uint8Array,
  maxChars: number,
): Promise<{ text: string; pages: number; title?: string }> {
  const pdfjs = await import("pdfjs-dist/legacy/build/pdf.mjs");
  pdfjs.GlobalWorkerOptions.workerSrc = workerUrl;
  const task = pdfjs.getDocument({ data, useSystemFonts: false });
  const doc = await task.promise;
  try {
    const out: string[] = [];
    let len = 0;
    for (let n = 1; n <= doc.numPages && len < maxChars; n++) {
      const page = await doc.getPage(n);
      const content = await page.getTextContent();
      const text = content.items
        .map((i) => ("str" in i ? `${i.str}${i.hasEOL ? "\n" : ""}` : ""))
        .join("")
        .replace(/[ \t]+/g, " ")
        .trim();
      if (text) {
        out.push(`[Page ${n}]\n${text}`);
        len += text.length;
      }
    }
    const meta = await doc.getMetadata().catch(() => null);
    const title = (meta?.info as { Title?: string } | undefined)?.Title || undefined;
    return { text: out.join("\n\n").slice(0, maxChars), pages: doc.numPages, title };
  } finally {
    await task.destroy();
  }
}

/** Fetches the PDF's bytes; throws when the server or site access doesn't allow it. */
export async function fetchPdf(url: string, maxBytes = 30 * 1024 * 1024): Promise<Uint8Array> {
  const res = await fetch(url, { credentials: "include" });
  if (!res.ok) throw new Error(`The PDF couldn't be loaded (${res.status}).`);
  const len = Number(res.headers.get("content-length") ?? 0);
  if (len > maxBytes) throw new Error("This PDF is too big to read here.");
  const data = new Uint8Array(await res.arrayBuffer());
  if (data.length > maxBytes) throw new Error("This PDF is too big to read here.");
  return data;
}
