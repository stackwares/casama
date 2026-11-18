/**
 * Markdown as safe HTML, for replies in the panel and saved PDFs. Everything is escaped first and
 * only a fixed set of tags comes back; links must be http(s). Pictures are never loaded on their
 * own: a reply could otherwise send data out in a picture's address just by being shown (a page
 * can ask a bot to do that), so they become links that open in a new tab when clicked.
 */
const esc = (s: string) =>
  s.replace(
    /[&<>"']/g,
    (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]!,
  );

const safeUrl = (u: string) => (/^https?:\/\/[^\s"<>]+$/i.test(u) ? u : null);
const link = (url: string, label: string) =>
  `<a href="${esc(url)}" target="_blank" rel="noopener noreferrer">${label}</a>`;

function inline(s: string): string {
  // Code spans, links and pictures are set aside first (as NUL-marked slots), so the escaping and
  // the emphasis rules below never touch the HTML made for them, and none can nest in another.
  const slots: string[] = [];
  const slot = (html: string) => `\u0000${slots.push(html) - 1}\u0000`;
  let t = s.replace(/`([^`\n]+)`/g, (_, c: string) => slot(`<code>${esc(c)}</code>`));
  t = t.replace(/!\[([^\]]*)\]\(([^)\s]+)\)/g, (_, alt: string, url: string) => {
    const u = safeUrl(url);
    const label = esc(alt.trim() || "Picture");
    return slot(u ? link(u, `Picture: ${label}`) : label);
  });
  t = t.replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, (_, text: string, url: string) => {
    const u = safeUrl(url);
    return slot(u ? link(u, esc(text)) : esc(text));
  });
  t = t.replace(
    // biome-ignore lint/suspicious/noControlCharactersInRegex: an address stops at a slot's NUL.
    /(^|[\s(])(https?:\/\/[^\s<\u0000]+[^\s<.,;:!?)\u0000])/g,
    (_, pre: string, url: string) => {
      const u = safeUrl(url);
      return `${pre}${u ? slot(link(u, esc(url))) : url}`;
    },
  );
  t = esc(t)
    .replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>")
    .replace(/__(.+?)__/g, "<strong>$1</strong>")
    .replace(/(^|[^*\w])\*(?!\s)(.+?)(?<!\s)\*(?!\w)/g, "$1<em>$2</em>")
    .replace(/~~(.+?)~~/g, "<del>$1</del>");
  // biome-ignore lint/suspicious/noControlCharactersInRegex: NUL marks the slots set aside above.
  return t.replace(/\u0000(\d+)\u0000/g, (_, i: string) => slots[Number(i)] ?? "");
}

export function markdownToHtml(md: string): string {
  const lines = md.replace(/\r\n?/g, "\n").split("\n");
  const out: string[] = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i]!;
    const fence = /^```(\w*)\s*$/.exec(line);
    if (fence) {
      const body: string[] = [];
      i++;
      while (i < lines.length && !/^```\s*$/.test(lines[i]!)) body.push(lines[i++]!);
      i++;
      out.push(`<pre><code>${esc(body.join("\n"))}</code></pre>`);
      continue;
    }
    const heading = /^(#{1,6})\s+(.*)$/.exec(line);
    if (heading) {
      const n = Math.min(6, heading[1]!.length + 2);
      out.push(`<h${n}>${inline(heading[2]!)}</h${n}>`);
      i++;
      continue;
    }
    if (/^\s*(-{3,}|\*{3,}|_{3,})\s*$/.test(line)) {
      out.push("<hr>");
      i++;
      continue;
    }
    if (/^>\s?/.test(line)) {
      const body: string[] = [];
      while (i < lines.length && /^>\s?/.test(lines[i]!))
        body.push(lines[i++]!.replace(/^>\s?/, ""));
      out.push(`<blockquote>${markdownToHtml(body.join("\n"))}</blockquote>`);
      continue;
    }
    const bullet = /^\s*([-*+]|\d+[.)])\s+/;
    if (bullet.test(line)) {
      const ordered = /^\s*\d/.test(line);
      const items: string[] = [];
      while (i < lines.length && bullet.test(lines[i]!))
        items.push(lines[i++]!.replace(bullet, ""));
      const tag = ordered ? "ol" : "ul";
      out.push(`<${tag}>${items.map((it) => `<li>${inline(it)}</li>`).join("")}</${tag}>`);
      continue;
    }
    if (
      /^\|.*\|\s*$/.test(line) &&
      i + 1 < lines.length &&
      /^\|[\s:|-]+\|\s*$/.test(lines[i + 1]!)
    ) {
      const cells = (l: string) =>
        l
          .trim()
          .replace(/^\||\|$/g, "")
          .split("|")
          .map((c) => c.trim());
      const head = cells(line);
      i += 2;
      const rows: string[][] = [];
      while (i < lines.length && /^\|.*\|\s*$/.test(lines[i]!)) rows.push(cells(lines[i++]!));
      out.push(
        `<table><thead><tr>${head.map((c) => `<th>${inline(c)}</th>`).join("")}</tr></thead><tbody>${rows
          .map((r) => `<tr>${r.map((c) => `<td>${inline(c)}</td>`).join("")}</tr>`)
          .join("")}</tbody></table>`,
      );
      continue;
    }
    if (!line.trim()) {
      i++;
      continue;
    }
    const para: string[] = [];
    while (
      i < lines.length &&
      lines[i]!.trim() &&
      !/^(#{1,6}\s|```|>|\s*([-*+]|\d+[.)])\s)/.test(lines[i]!)
    )
      para.push(lines[i++]!);
    out.push(`<p>${para.map(inline).join("<br>")}</p>`);
  }
  return out.join("");
}

/** Markdown as nodes to append. */
export function markdownNodes(md: string): DocumentFragment {
  const t = document.createElement("template");
  t.innerHTML = markdownToHtml(md);
  return t.content;
}
