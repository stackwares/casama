/**
 * Bot replies are Markdown, which the Casama app renders. Most chat apps don't: Telegram shows
 * `**bold**` as it is, Slack and WhatsApp have formats of their own, SMS has none. This turns a
 * reply into what each app shows properly (D-340). It covers what bots write: bold, italic,
 * strikethrough, code, code blocks, links, headings, lists, quotes, rules and tables.
 *
 * No parser library: a small line-based reader is enough for chat replies, and anything it
 * doesn't recognise stays as text. Every converter returns something sendable for any input.
 */

// ------------------------------------------------------------------ The parsed reply
export type Inline =
  | { t: "text"; v: string }
  | { t: "b"; c: Inline[] }
  | { t: "i"; c: Inline[] }
  | { t: "s"; c: Inline[] }
  | { t: "code"; v: string }
  | { t: "a"; c: Inline[]; href: string };

export interface ListItem {
  depth: number;
  ordered: boolean;
  num: number;
  c: Inline[];
}

export type Block =
  | { t: "p"; lines: Inline[][] }
  | { t: "h"; level: number; c: Inline[] }
  | { t: "list"; items: ListItem[] }
  | { t: "code"; lang: string; v: string }
  | { t: "quote"; c: Block[] }
  | { t: "hr" }
  | { t: "table"; head: Inline[][]; rows: Inline[][][] };

const FENCE = /^\s{0,3}(`{3,}|~{3,})\s*([\w+#.-]*)/;
const HEADING = /^\s{0,3}(#{1,6})\s+(.*?)\s*#*\s*$/;
const RULE = /^\s{0,3}([-*_])(\s*\1){2,}\s*$/;
const QUOTE = /^\s{0,3}>\s?(.*)$/;
const ITEM = /^(\s*)([-*+•]|\d{1,9}[.)])\s+(.*)$/;
const TABLE_SEP = /^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?\s*$/;

const cells = (line: string) =>
  line
    .trim()
    .replace(/^\|/, "")
    .replace(/\|$/, "")
    .split(/(?<!\\)\|/)
    .map((c) => parseInline(c.trim().replace(/\\\|/g, "|")));

function startsBlock(line: string, next: string | undefined) {
  return (
    FENCE.test(line) ||
    HEADING.test(line) ||
    RULE.test(line) ||
    QUOTE.test(line) ||
    ITEM.test(line) ||
    (line.includes("|") && next !== undefined && TABLE_SEP.test(next))
  );
}

export function parseMarkdown(md: string): Block[] {
  const lines = md.replace(/\r\n?/g, "\n").split("\n");
  const blocks: Block[] = [];
  let blank = false;
  // Blocks keep the spacing they were written with: a list right under a line stays right under it.
  const out = {
    push(b: Block) {
      if (!blank && blocks.length) TIGHT.add(b);
      blank = false;
      blocks.push(b);
    },
  };
  let i = 0;
  while (i < lines.length) {
    const line = lines[i] as string;
    if (!line.trim()) {
      blank = true;
      i++;
      continue;
    }
    const fence = FENCE.exec(line);
    if (fence) {
      const mark = fence[1] as string;
      const body: string[] = [];
      i++;
      while (i < lines.length && !(lines[i] as string).trim().startsWith(mark))
        body.push(lines[i++] as string);
      i++; // the closing fence; an unclosed block runs to the end
      out.push({ t: "code", lang: fence[2] ?? "", v: body.join("\n") });
      continue;
    }
    const heading = HEADING.exec(line);
    if (heading) {
      out.push({ t: "h", level: (heading[1] as string).length, c: parseInline(heading[2] ?? "") });
      i++;
      continue;
    }
    if (RULE.test(line)) {
      out.push({ t: "hr" });
      i++;
      continue;
    }
    if (line.includes("|") && i + 1 < lines.length && TABLE_SEP.test(lines[i + 1] as string)) {
      const head = cells(line);
      const rows: Inline[][][] = [];
      i += 2;
      while (i < lines.length && (lines[i] as string).includes("|") && (lines[i] as string).trim())
        rows.push(cells(lines[i++] as string));
      out.push({ t: "table", head, rows });
      continue;
    }
    if (QUOTE.test(line)) {
      const inner: string[] = [];
      while (i < lines.length && QUOTE.test(lines[i] as string))
        inner.push((QUOTE.exec(lines[i++] as string) as RegExpExecArray)[1] ?? "");
      out.push({ t: "quote", c: parseMarkdown(inner.join("\n")) });
      continue;
    }
    if (ITEM.test(line)) {
      const items: ListItem[] = [];
      while (i < lines.length) {
        const l = lines[i] as string;
        const m = ITEM.exec(l);
        if (m) {
          const marker = m[2] as string;
          const ordered = /^\d/.test(marker);
          items.push({
            depth: Math.floor((m[1] as string).replace(/\t/g, "    ").length / 2),
            ordered,
            num: ordered ? Number.parseInt(marker, 10) : 0,
            c: parseInline(m[3] ?? ""),
          });
          i++;
        } else if (l.trim() && /^\s+/.test(l) && items.length) {
          // A wrapped line of the item above.
          const last = items[items.length - 1] as ListItem;
          last.c.push({ t: "text", v: " " }, ...parseInline(l.trim()));
          i++;
        } else break;
      }
      out.push({ t: "list", items });
      continue;
    }
    const para: Inline[][] = [];
    while (i < lines.length && (lines[i] as string).trim()) {
      if (para.length && startsBlock(lines[i] as string, lines[i + 1])) break;
      para.push(parseInline((lines[i] as string).trim()));
      i++;
    }
    out.push({ t: "p", lines: para });
  }
  return blocks;
}

/** Blocks written straight under the one before, with no blank line between. */
const TIGHT = new WeakSet<Block>();

const PUNCT = /[!-/:-@[-`{-~]/;
const WORD = /[\p{L}\p{N}]/u;

/** Bold, italic, strikethrough, code and links in one line. Unmatched marks stay as text. */
export function parseInline(s: string): Inline[] {
  const out: Inline[] = [];
  let buf = "";
  const flush = () => {
    if (buf) out.push({ t: "text", v: buf });
    buf = "";
  };
  let i = 0;
  while (i < s.length) {
    const ch = s[i] as string;
    const rest = s.slice(i);
    if (ch === "\\" && i + 1 < s.length && PUNCT.test(s[i + 1] as string)) {
      buf += s[i + 1];
      i += 2;
      continue;
    }
    if (ch === "`") {
      const run = (/^`+/.exec(rest) as RegExpExecArray)[0];
      const end = s.indexOf(run, i + run.length);
      if (end > i) {
        flush();
        out.push({ t: "code", v: s.slice(i + run.length, end).replace(/^ (.+) $/, "$1") });
        i = end + run.length;
        continue;
      }
      buf += run;
      i += run.length;
      continue;
    }
    if (ch === "[" || (ch === "!" && s[i + 1] === "[")) {
      const open = ch === "!" ? i + 1 : i;
      const link = matchLink(s, open);
      if (link) {
        flush();
        out.push({ t: "a", c: parseInline(link.text), href: link.href });
        i = link.end;
        continue;
      }
    }
    if (ch === "<") {
      const auto = /^<((?:https?:\/\/|mailto:)[^>\s]+)>/.exec(rest);
      if (auto) {
        flush();
        out.push({ t: "a", c: [{ t: "text", v: auto[1] as string }], href: auto[1] as string });
        i += auto[0].length;
        continue;
      }
    }
    const pair = rest.startsWith("**")
      ? "**"
      : rest.startsWith("__")
        ? "__"
        : rest.startsWith("~~")
          ? "~~"
          : null;
    if (pair) {
      const end = closing(s, i + 2, pair);
      if (end > 0 && (pair !== "__" || boundary(s, i - 1, end + 2))) {
        flush();
        const inner = parseInline(s.slice(i + 2, end));
        out.push(pair === "~~" ? { t: "s", c: inner } : { t: "b", c: inner });
        i = end + 2;
        continue;
      }
    }
    if ((ch === "*" || ch === "_") && s[i + 1] !== ch) {
      const end = closing(s, i + 1, ch);
      if (end > 0 && (ch === "*" || boundary(s, i - 1, end + 1))) {
        flush();
        out.push({ t: "i", c: parseInline(s.slice(i + 1, end)) });
        i = end + 1;
        continue;
      }
    }
    buf += ch;
    i++;
  }
  flush();
  return out;
}

/** Where a mark opened at `from` closes: not right after a space, with something inside. */
function closing(s: string, from: number, mark: string) {
  if (from >= s.length || /\s/.test(s[from] as string)) return -1;
  let j = s.indexOf(mark, from);
  for (; j !== -1; j = s.indexOf(mark, j)) {
    if (j > from && !/\s/.test(s[j - 1] as string) && s[j - 1] !== "\\") {
      if (mark.length === 1) {
        // A single * or _ must not be half of a double one.
        if (s[j + 1] === mark || s[j - 1] === mark) {
          j += 2;
          continue;
        }
      } else {
        // In "***", a double mark closes at the end, leaving the single one inside.
        while (s[j + mark.length] === mark[0]) j++;
      }
      return j;
    }
    j += mark.length;
  }
  return -1;
}

/** Underscores only count at word edges, so snake_case_names stay as they are. */
const boundary = (s: string, before: number, after: number) =>
  !(before >= 0 && WORD.test(s[before] as string)) &&
  !(after < s.length && WORD.test(s[after] as string));

function matchLink(s: string, open: number) {
  let depth = 0;
  let j = open;
  for (; j < s.length; j++) {
    if (s[j] === "\\") {
      j++;
      continue;
    }
    if (s[j] === "[") depth++;
    else if (s[j] === "]" && --depth === 0) break;
  }
  if (j >= s.length || s[j + 1] !== "(") return null;
  const m = /^\(\s*<?([^\s)>]+)>?(?:\s+"[^"]*")?\s*\)/.exec(s.slice(j + 1));
  if (!m) return null;
  return { text: s.slice(open + 1, j), href: m[1] as string, end: j + 1 + m[0].length };
}

// ------------------------------------------------------------------ Shared helpers
const inlineText = (c: Inline[]): string =>
  c.map((n) => (n.t === "text" || n.t === "code" ? n.v : inlineText(n.c))).join("");

/** A link as plain text: the address alone when the text is the address. */
function linkPlain(text: string, href: string) {
  const bare = href.replace(/^mailto:/, "");
  const t = text.trim();
  return !t || t === href || t === bare ? bare : `${t} (${bare})`;
}

const bullet = (it: ListItem, dash = "•") =>
  `${"  ".repeat(it.depth)}${it.ordered ? `${it.num}.` : dash} `;

/** A table as lines of aligned columns, for monospaced blocks. */
function tableGrid(head: string[], rows: string[][]) {
  const n = Math.max(head.length, ...rows.map((r) => r.length));
  const w = Array.from({ length: n }, (_, k) =>
    Math.max(head[k]?.length ?? 0, ...rows.map((r) => r[k]?.length ?? 0)),
  );
  const line = (r: string[]) =>
    w
      .map((x, k) => (r[k] ?? "").padEnd(x))
      .join("  ")
      .trimEnd();
  return [line(head), w.map((x) => "-".repeat(Math.max(x, 1))).join("  "), ...rows.map(line)].join(
    "\n",
  );
}

/** Text formats share their shape and differ in marks, escaping and code blocks. */
interface TextStyle {
  text(v: string): string;
  b(x: string): string;
  i(x: string): string;
  s(x: string): string;
  code(v: string): string;
  link(text: Inline[], href: string): string;
  pre(v: string, lang: string): string;
  heading(x: string): string;
  quote(x: string): string;
  hr: string;
  dash: string;
}

function renderText(blocks: Block[], st: TextStyle): string {
  const inl = (c: Inline[]): string =>
    c
      .map((n) => {
        switch (n.t) {
          case "text":
            return st.text(n.v);
          case "code":
            return st.code(n.v);
          case "b":
            return wrap(inl(n.c), st.b);
          case "i":
            return wrap(inl(n.c), st.i);
          case "s":
            return wrap(inl(n.c), st.s);
          default:
            return st.link(n.c, n.href);
        }
      })
      .join("");
  const parts = blocks.map((b): string => {
    switch (b.t) {
      case "p":
        return b.lines.map(inl).join("\n");
      case "h":
        return st.heading(inl(b.c));
      case "list":
        return b.items.map((it) => st.text(bullet(it, st.dash)) + inl(it.c)).join("\n");
      case "code":
        return st.pre(b.v, b.lang);
      case "quote":
        return st.quote(renderText(b.c, st));
      case "hr":
        return st.hr;
      default:
        return st.pre(
          tableGrid(
            b.head.map(inlineText),
            b.rows.map((r) => r.map(inlineText)),
          ),
          "",
        );
    }
  });
  let text = "";
  parts.forEach((x, k) => {
    if (x === "") return;
    if (text) text += TIGHT.has(blocks[k] as Block) ? "\n" : "\n\n";
    text += x;
  });
  return text;
}

/** Marks can't hug spaces in Slack or WhatsApp, so spaces stay outside them. */
function wrap(x: string, mark: (x: string) => string) {
  const m = /^(\s*)([\s\S]*?)(\s*)$/.exec(x) as RegExpExecArray;
  return m[2] ? `${m[1]}${mark(m[2])}${m[3]}` : x;
}

/** Any converter, falling back to the reply as written if something unexpected happens. */
function safe<T>(md: string, fn: (b: Block[]) => T, fallback: (md: string) => T): T {
  try {
    return fn(parseMarkdown(md));
  } catch {
    return fallback(md);
  }
}

// ------------------------------------------------------------------ Plain text (SMS, iMessage, Messenger, Feishu)
const PLAIN: TextStyle = {
  text: (v) => v,
  b: (x) => x,
  i: (x) => x,
  s: (x) => x,
  code: (v) => v,
  link: (c, href) => linkPlain(inlineText(c), href),
  pre: (v) => v,
  heading: (x) => x,
  quote: (x) =>
    x
      .split("\n")
      .map((l) => `> ${l}`)
      .join("\n"),
  hr: "———",
  dash: "•",
};

export const toPlain = (md: string) =>
  safe(
    md,
    (b) => renderText(b, PLAIN),
    (m) => m,
  );

// ------------------------------------------------------------------ Telegram (parse_mode HTML)
/** Text safe inside Telegram or email HTML. */
export const escapeHtml = (v: string) =>
  v.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
const escHtml = (v: string) => v.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
const escAttr = (v: string) => escHtml(v).replace(/"/g, "&quot;");
const safeHref = (href: string) => /^(https?:|mailto:|tg:)/i.test(href);

const TELEGRAM: TextStyle = {
  text: escHtml,
  b: (x) => `<b>${x}</b>`,
  i: (x) => `<i>${x}</i>`,
  s: (x) => `<s>${x}</s>`,
  code: (v) => `<code>${escHtml(v)}</code>`,
  link: (c, href) =>
    safeHref(href)
      ? `<a href="${escAttr(href)}">${renderInlineWith(c, TELEGRAM) || escHtml(href)}</a>`
      : escHtml(linkPlain(inlineText(c), href)),
  pre: (v, lang) =>
    lang
      ? `<pre><code class="language-${escAttr(lang)}">${escHtml(v)}</code></pre>`
      : `<pre>${escHtml(v)}</pre>`,
  heading: (x) => `<b>${x}</b>`,
  quote: (x) => `<blockquote>${x}</blockquote>`,
  hr: "———",
  dash: "•",
};

export const toTelegramHtml = (md: string) => safe(md, (b) => renderText(b, TELEGRAM), escHtml);

// ------------------------------------------------------------------ Slack (mrkdwn)
const escSlack = (v: string) =>
  v.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

const SLACK: TextStyle = {
  text: escSlack,
  b: (x) => `*${x}*`,
  i: (x) => `_${x}_`,
  s: (x) => `~${x}~`,
  code: (v) => `\`${escSlack(v)}\``,
  link: (c, href) => {
    const t = inlineText(c).trim();
    const h = href.replace(/[<>|]/g, encodeURIComponent);
    return !t || t === href ? `<${h}>` : `<${h}|${escSlack(t).replace(/\|/g, "¦")}>`;
  },
  pre: (v) => `\`\`\`\n${escSlack(v)}\n\`\`\``,
  heading: (x) => `*${x.replace(/^\*(.*)\*$/, "$1")}*`,
  quote: (x) =>
    x
      .split("\n")
      .map((l) => `> ${l}`)
      .join("\n"),
  hr: "———",
  dash: "•",
};

export const toSlack = (md: string) => safe(md, (b) => renderText(b, SLACK), escSlack);

// ------------------------------------------------------------------ WhatsApp
const WHATSAPP: TextStyle = {
  text: (v) => v,
  b: (x) => `*${x}*`,
  i: (x) => `_${x}_`,
  s: (x) => `~${x}~`,
  code: (v) => `\`${v}\``,
  link: (c, href) => linkPlain(inlineText(c), href),
  pre: (v) => `\`\`\`${v}\`\`\``,
  heading: (x) => `*${x.replace(/^\*(.*)\*$/, "$1")}*`,
  quote: (x) =>
    x
      .split("\n")
      .map((l) => `> ${l}`)
      .join("\n"),
  hr: "———",
  dash: "-",
};

export const toWhatsApp = (md: string) =>
  safe(
    md,
    (b) => renderText(b, WHATSAPP),
    (m) => m,
  );

function renderInlineWith(c: Inline[], st: TextStyle) {
  return renderText([{ t: "p", lines: [c] }], st);
}

// ------------------------------------------------------------------ Lists as trees (HTML, Jira)
interface ListTree {
  ordered: boolean;
  start: number;
  items: Array<{ c: Inline[]; sub: ListTree[] }>;
}

function listTree(items: ListItem[]): ListTree[] {
  const roots: ListTree[] = [];
  const stack: Array<{ depth: number; list: ListTree }> = [];
  for (const it of items) {
    while (stack.length && (stack[stack.length - 1] as { depth: number }).depth > it.depth)
      stack.pop();
    let top = stack[stack.length - 1];
    if (top && top.depth < it.depth) {
      const parent = top.list.items[top.list.items.length - 1];
      const list: ListTree = { ordered: it.ordered, start: it.num || 1, items: [] };
      if (parent) parent.sub.push(list);
      else roots.push(list);
      top = { depth: it.depth, list };
      stack.push(top);
    } else if (!top || top.list.ordered !== it.ordered) {
      if (top) stack.pop();
      const list: ListTree = { ordered: it.ordered, start: it.num || 1, items: [] };
      const parentTop = stack[stack.length - 1];
      const parent = parentTop?.list.items[parentTop.list.items.length - 1];
      if (parent) parent.sub.push(list);
      else roots.push(list);
      top = { depth: it.depth, list };
      stack.push(top);
    }
    top.list.items.push({ c: it.c, sub: [] });
  }
  return roots;
}

// ------------------------------------------------------------------ Email (HTML body next to the plain one)
function htmlInline(c: Inline[]): string {
  return c
    .map((n) => {
      switch (n.t) {
        case "text":
          return escHtml(n.v);
        case "code":
          return `<code style="font-family:monospace;background:#f3f3f3;padding:0 3px;border-radius:3px">${escHtml(n.v)}</code>`;
        case "b":
          return `<strong>${htmlInline(n.c)}</strong>`;
        case "i":
          return `<em>${htmlInline(n.c)}</em>`;
        case "s":
          return `<s>${htmlInline(n.c)}</s>`;
        default:
          return safeHref(n.href)
            ? `<a href="${escAttr(n.href)}">${htmlInline(n.c) || escHtml(n.href)}</a>`
            : escHtml(linkPlain(inlineText(n.c), n.href));
      }
    })
    .join("");
}

const htmlList = (l: ListTree): string => {
  const tag = l.ordered ? "ol" : "ul";
  const start = l.ordered && l.start !== 1 ? ` start="${l.start}"` : "";
  return `<${tag}${start}>${l.items.map((it) => `<li>${htmlInline(it.c)}${it.sub.map(htmlList).join("")}</li>`).join("")}</${tag}>`;
};

function htmlBlocks(blocks: Block[]): string {
  return blocks
    .map((b) => {
      switch (b.t) {
        case "p":
          return `<p>${b.lines.map(htmlInline).join("<br>")}</p>`;
        case "h": {
          const level = Math.min(b.level + 1, 6);
          return `<h${level}>${htmlInline(b.c)}</h${level}>`;
        }
        case "list":
          return listTree(b.items).map(htmlList).join("");
        case "code":
          return `<pre style="font-family:monospace;background:#f3f3f3;padding:8px;border-radius:4px;white-space:pre-wrap">${escHtml(b.v)}</pre>`;
        case "quote":
          return `<blockquote style="margin:0 0 0 8px;padding-left:8px;border-left:3px solid #ccc;color:#555">${htmlBlocks(b.c)}</blockquote>`;
        case "hr":
          return "<hr>";
        default: {
          const td = 'style="border:1px solid #ddd;padding:4px 8px;text-align:left"';
          return `<table style="border-collapse:collapse"><thead><tr>${b.head.map((c) => `<th ${td}>${htmlInline(c)}</th>`).join("")}</tr></thead><tbody>${b.rows
            .map((r) => `<tr>${r.map((c) => `<td ${td}>${htmlInline(c)}</td>`).join("")}</tr>`)
            .join("")}</tbody></table>`;
        }
      }
    })
    .join("\n");
}

export const toEmailHtml = (md: string) =>
  safe(
    md,
    (b) =>
      `<div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;font-size:15px;line-height:1.5">${htmlBlocks(b)}</div>`,
    (m) => `<pre style="white-space:pre-wrap;font-family:inherit">${escHtml(m)}</pre>`,
  );

// ------------------------------------------------------------------ Jira (Atlassian Document Format)
type Adf = Record<string, unknown>;

function adfInline(c: Inline[], marks: Adf[] = []): Adf[] {
  const out: Adf[] = [];
  for (const n of c) {
    switch (n.t) {
      case "text":
        if (n.v) out.push({ type: "text", text: n.v, ...(marks.length ? { marks } : {}) });
        break;
      case "code": {
        // Jira lets code sit only next to a link mark.
        const link = marks.filter((m) => m.type === "link");
        if (n.v) out.push({ type: "text", text: n.v, marks: [...link, { type: "code" }] });
        break;
      }
      case "b":
        out.push(...adfInline(n.c, [...marks, { type: "strong" }]));
        break;
      case "i":
        out.push(...adfInline(n.c, [...marks, { type: "em" }]));
        break;
      case "s":
        out.push(...adfInline(n.c, [...marks, { type: "strike" }]));
        break;
      case "a":
        if (safeHref(n.href)) {
          const inner = n.c.length ? n.c : [{ t: "text" as const, v: n.href }];
          out.push(...adfInline(inner, [...marks, { type: "link", attrs: { href: n.href } }]));
        } else
          out.push(...adfInline([{ t: "text", v: linkPlain(inlineText(n.c), n.href) }], marks));
        break;
    }
  }
  return out;
}

const adfPara = (c: Adf[]): Adf => ({ type: "paragraph", content: c });

const adfList = (l: ListTree): Adf => ({
  type: l.ordered ? "orderedList" : "bulletList",
  ...(l.ordered ? { attrs: { order: l.start } } : {}),
  content: l.items.map((it) => ({
    type: "listItem",
    content: [adfPara(adfInline(it.c)), ...it.sub.map(adfList)],
  })),
});

function adfBlocks(blocks: Block[]): Adf[] {
  return blocks.flatMap((b): Adf[] => {
    switch (b.t) {
      case "p":
        return [
          adfPara(
            b.lines.flatMap((l, k) =>
              k ? [{ type: "hardBreak" }, ...adfInline(l)] : adfInline(l),
            ),
          ),
        ];
      case "h":
        return [{ type: "heading", attrs: { level: b.level }, content: adfInline(b.c) }];
      case "list":
        return listTree(b.items).map(adfList);
      case "code":
        return [
          {
            type: "codeBlock",
            ...(b.lang ? { attrs: { language: b.lang } } : {}),
            content: b.v ? [{ type: "text", text: b.v }] : [],
          },
        ];
      case "quote":
        // A quote can't hold headings or tables in Jira: those become bold paragraphs and text.
        return [
          {
            type: "blockquote",
            content: adfBlocks(
              b.c.map(
                (x): Block =>
                  x.t === "h"
                    ? { t: "p", lines: [[{ t: "b", c: x.c }]] }
                    : x.t === "table"
                      ? {
                          t: "code",
                          lang: "",
                          v: tableGrid(
                            x.head.map(inlineText),
                            x.rows.map((r) => r.map(inlineText)),
                          ),
                        }
                      : x,
              ),
            ),
          },
        ];
      case "hr":
        return [{ type: "rule" }];
      default: {
        const cell = (type: string) => (c: Inline[]) => ({
          type,
          content: [adfPara(adfInline(c))],
        });
        return [
          {
            type: "table",
            content: [
              { type: "tableRow", content: b.head.map(cell("tableHeader")) },
              ...b.rows.map((r) => ({ type: "tableRow", content: r.map(cell("tableCell")) })),
            ],
          },
        ];
      }
    }
  });
}

export const toAdf = (md: string): Adf =>
  safe(
    md,
    (b) => ({ type: "doc", version: 1, content: adfBlocks(b) }),
    (m) => ({
      type: "doc",
      version: 1,
      content: m.split(/\n{2,}/).map((p) => adfPara(p.trim() ? [{ type: "text", text: p }] : [])),
    }),
  );

// ------------------------------------------------------------------ Splitting
/**
 * Keeps code blocks whole across a split (D-340): a part that ends inside a ``` block closes it,
 * and the next part opens it again, so each part converts on its own.
 */
export function balanceFences(parts: string[]): string[] {
  let open: string | null = null;
  return parts.map((p) => {
    const text = open !== null ? `\`\`\`${open}\n${p}` : p;
    open = null;
    for (const line of text.split("\n")) {
      const m = /^\s{0,3}```\s*([\w+#.-]*)/.exec(line);
      if (m) open = open === null ? (m[1] ?? "") : null;
    }
    return open !== null ? `${text}\n\`\`\`` : text;
  });
}
