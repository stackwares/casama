/**
 * Readable text from a web page for `web.fetch` (D-384): the title and the main content as plain,
 * markdown-ish text, without scripts, styles, menus, headers, footers or forms. http.request hands
 * the model up to 200 KB of raw HTML, most of it markup; this is usually a tenth of that or less.
 *
 * No HTML parser is in the repo's dependencies, so this is a small regex-based extractor. It is
 * not a sanitizer and nothing it returns is rendered as HTML: the text goes to the model inside
 * wrapUntrusted.
 */

const NAMED: Record<string, string> = {
  amp: "&",
  lt: "<",
  gt: ">",
  quot: '"',
  apos: "'",
  nbsp: " ",
  ndash: "–",
  mdash: "—",
  hellip: "…",
  lsquo: "‘",
  rsquo: "’",
  ldquo: "“",
  rdquo: "”",
  laquo: "«",
  raquo: "»",
  bull: "•",
  middot: "·",
  copy: "©",
  reg: "®",
  trade: "™",
  euro: "€",
  pound: "£",
  yen: "¥",
  cent: "¢",
  deg: "°",
  times: "×",
  divide: "÷",
  shy: "",
  zwj: "",
  zwnj: "",
};

export function decodeEntities(s: string) {
  return s.replace(/&(#x[0-9a-f]+|#\d+|[a-z][a-z0-9]*);/gi, (m, body: string) => {
    if (body[0] === "#") {
      const code =
        body[1] === "x" || body[1] === "X"
          ? Number.parseInt(body.slice(2), 16)
          : Number.parseInt(body.slice(1), 10);
      if (!Number.isFinite(code) || code <= 0 || code > 0x10ffff) return "";
      try {
        return String.fromCodePoint(code);
      } catch {
        return "";
      }
    }
    return NAMED[body.toLowerCase()] ?? m;
  });
}

/** Removes every <tag>…</tag>, innermost first, so nested ones of the same name go too. */
function dropElements(html: string, tags: string[]) {
  const names = tags.join("|");
  // An element of one of these names that holds no other opening tag of the same names.
  const re = new RegExp(`<(${names})\\b[^>]*>(?:(?!<(?:${names})\\b)[\\s\\S])*?</\\1\\s*>`, "gi");
  let out = html;
  for (let i = 0; i < 20; i++) {
    const next = out.replace(re, " ");
    if (next === out) break;
    out = next;
  }
  return out;
}

/** The inner HTML of the first <tag>, outermost (nested ones of the same name included). */
function firstElement(html: string, tag: string): string | null {
  const open = new RegExp(`<${tag}\\b[^>]*>`, "i").exec(html);
  if (!open) return null;
  const tagRe = new RegExp(`<(/?)${tag}\\b[^>]*>`, "gi");
  tagRe.lastIndex = open.index + open[0].length;
  let depth = 1;
  for (let m = tagRe.exec(html); m; m = tagRe.exec(html)) {
    depth += m[1] ? -1 : 1;
    if (depth === 0) return html.slice(open.index + open[0].length, m.index);
  }
  return html.slice(open.index + open[0].length);
}

function attr(tag: string, name: string) {
  const m = new RegExp(`\\b${name}\\s*=\\s*(?:"([^"]*)"|'([^']*)'|([^\\s>]+))`, "i").exec(tag);
  return m ? decodeEntities(m[1] ?? m[2] ?? m[3] ?? "") : null;
}

function absolute(href: string, base: string | undefined) {
  try {
    const u = new URL(href, base);
    return u.protocol === "http:" || u.protocol === "https:" ? u.href : null;
  } catch {
    return null;
  }
}

const textLength = (html: string) =>
  html
    .replace(/<[^>]*>/g, "")
    .replace(/\s+/g, " ")
    .trim().length;

export interface ReadablePage {
  title: string;
  description: string;
  text: string;
}

/** The title, meta description and readable text of an HTML page. */
export function htmlToReadable(html: string, baseUrl?: string): ReadablePage {
  // \ue000 marks preformatted blocks set aside below, so the page itself may not use it.
  let doc = html
    .replace(/\ue000/g, "")
    .replace(/<!--[\s\S]*?-->/g, " ")
    .replace(/<!\[CDATA\[[\s\S]*?\]\]>/g, " ");
  const titleTag = /<title\b[^>]*>([\s\S]*?)<\/title\s*>/i.exec(doc);
  const ogTitle = /<meta\b[^>]*property\s*=\s*["']og:title["'][^>]*>/i.exec(doc);
  const title = decodeEntities(
    (titleTag?.[1] ?? (ogTitle ? (attr(ogTitle[0], "content") ?? "") : ""))
      .replace(/<[^>]*>/g, "")
      .replace(/\s+/g, " ")
      .trim(),
  );
  const descTag =
    /<meta\b[^>]*name\s*=\s*["']description["'][^>]*>/i.exec(doc) ??
    /<meta\b[^>]*property\s*=\s*["']og:description["'][^>]*>/i.exec(doc);
  const description = descTag
    ? (attr(descTag[0], "content") ?? "").replace(/\s+/g, " ").trim()
    : "";

  // Never content, at any depth.
  doc = dropElements(doc, [
    "script",
    "style",
    "noscript",
    "template",
    "svg",
    "math",
    "iframe",
    "object",
    "canvas",
    "head",
    "select",
    "button",
  ]);
  doc = doc.replace(/<(?:link|meta|input|img|source|track|embed|wbr)\b[^>]*>/gi, " ");

  // The main part when the page marks one and it holds real text; else the whole body.
  const body = firstElement(doc, "body") ?? doc;
  let main = body;
  for (const tag of ["article", "main"]) {
    const part = firstElement(body, tag);
    if (part && textLength(part) >= 400) {
      main = part;
      break;
    }
  }
  if (main === body) {
    const roleMain = /<([a-z0-9]+)\b[^>]*\brole\s*=\s*["']main["'][^>]*>/i.exec(body);
    const inner = roleMain ? firstElement(body.slice(roleMain.index), roleMain[1] as string) : null;
    if (inner && textLength(inner) >= 400) main = inner;
  }
  // Page furniture: menus, banners, footers, sidebars, forms and dialogs, by tag and by role.
  main = dropElements(main, ["nav", "header", "footer", "aside", "form", "dialog"]);
  for (const role of ["navigation", "banner", "contentinfo", "search"]) {
    const re = new RegExp(`<([a-z0-9]+)\\b[^>]*\\brole\\s*=\\s*["']${role}["'][^>]*>`, "i");
    for (let i = 0; i < 10; i++) {
      const m = re.exec(main);
      if (!m) break;
      const inner = firstElement(main.slice(m.index), m[1] as string);
      const end = inner === null ? m[0].length : m[0].length + inner.length;
      const closeRe = new RegExp(`^\\s*</${m[1]}\\s*>`, "i");
      const after = main.slice(m.index + end);
      const close = closeRe.exec(after);
      main = `${main.slice(0, m.index)} ${after.slice(close ? close[0].length : 0)}`;
    }
  }

  // Preformatted blocks keep their spacing: set them aside before whitespace is collapsed.
  const blocks: string[] = [];
  main = main.replace(/<pre\b[^>]*>([\s\S]*?)<\/pre\s*>/gi, (_, inner: string) => {
    blocks.push(decodeEntities(inner.replace(/<br\s*\/?>/gi, "\n").replace(/<[^>]*>/g, "")));
    return `\ue000${blocks.length - 1}\ue000`;
  });

  let t = main
    .replace(/<a\b([^>]*)>([\s\S]*?)<\/a\s*>/gi, (_, attrs: string, inner: string) => {
      const label = inner
        .replace(/<[^>]*>/g, " ")
        .replace(/\s+/g, " ")
        .trim();
      if (!label) return " ";
      const href = attr(`<a ${attrs}>`, "href");
      const url = href && !href.startsWith("#") ? absolute(href, baseUrl) : null;
      return url && url !== label ? ` [${label}](${url}) ` : ` ${label} `;
    })
    .replace(/<h([1-6])\b[^>]*>/gi, (_, n: string) => `\n\n${"#".repeat(Number(n))} `)
    .replace(/<\/h[1-6]\s*>/gi, "\n\n")
    .replace(/<li\b[^>]*>/gi, "\n- ")
    .replace(/<(?:td|th)\b[^>]*>/gi, " | ")
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<hr\b[^>]*>/gi, "\n\n---\n\n")
    .replace(/<(?:strong|b)\b[^>]*>([\s\S]*?)<\/(?:strong|b)\s*>/gi, "**$1**")
    .replace(/<code\b[^>]*>([\s\S]*?)<\/code\s*>/gi, "`$1`")
    .replace(
      /<\/?(?:p|div|section|article|main|ul|ol|table|tr|thead|tbody|blockquote|figure|figcaption|dl|dt|dd|details|summary|address)\b[^>]*>/gi,
      "\n",
    )
    .replace(/<[^>]*>/g, " ");
  t = decodeEntities(t)
    .replace(/[ \t\f\v ​]+/g, " ")
    .split("\n")
    .map((l) => l.trim())
    .filter((l, i, all) => l !== "" || (i > 0 && all[i - 1] !== ""))
    .join("\n")
    .replace(/\*\*\s*\*\*/g, "")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
  t = t.replace(
    /\ue000(\d+)\ue000/g,
    (_, i: string) => `\n\`\`\`\n${blocks[Number(i)]?.replace(/^\n+|\s+$/g, "")}\n\`\`\`\n`,
  );
  return { title, description, text: t };
}

/** Reads at most [maxBytes] of a response body; `truncated` when there was more. */
export async function readCapped(
  res: Response,
  maxBytes: number,
): Promise<{ bytes: Uint8Array; truncated: boolean }> {
  if (!res.body) return { bytes: new Uint8Array(), truncated: false };
  const reader = res.body.getReader();
  const parts: Uint8Array[] = [];
  let size = 0;
  let truncated = false;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    if (size + value.byteLength > maxBytes) {
      parts.push(value.subarray(0, maxBytes - size));
      size = maxBytes;
      truncated = true;
      await reader.cancel().catch(() => {});
      break;
    }
    parts.push(value);
    size += value.byteLength;
  }
  const bytes = new Uint8Array(size);
  let at = 0;
  for (const p of parts) {
    bytes.set(p, at);
    at += p.byteLength;
  }
  return { bytes, truncated };
}

/** The charset a response declares (header first, then a <meta> in the first bytes). */
export function decodeBody(bytes: Uint8Array, contentType: string) {
  const fromHeader = /charset\s*=\s*["']?([\w-]+)/i.exec(contentType)?.[1];
  let charset = fromHeader;
  if (!charset) {
    const head = new TextDecoder("latin1").decode(bytes.subarray(0, 2048));
    charset = /<meta[^>]+charset\s*=\s*["']?([\w-]+)/i.exec(head)?.[1];
  }
  try {
    return new TextDecoder(charset ?? "utf-8").decode(bytes);
  } catch {
    return new TextDecoder("utf-8").decode(bytes);
  }
}
