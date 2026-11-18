/**
 * Functions injected into a tab with chrome.scripting.executeScript, only when the person asks
 * (plan §9.3). Each must stand alone: Chrome serializes the function, so nothing from this module's
 * scope is available inside it.
 */

export interface PageSnapshot {
  url: string;
  title: string;
  selection: string;
  text: string;
  /** A visible password or card number field: the guard won't send this page. */
  secretField: boolean;
  lang: string;
}

/** The page's address, title, selection and readable text. */
export function snapshotPage(maxChars: number): PageSnapshot {
  const SKIP = new Set([
    "SCRIPT",
    "STYLE",
    "NOSCRIPT",
    "TEMPLATE",
    "SVG",
    "CANVAS",
    "IFRAME",
    "NAV",
    "FOOTER",
    "ASIDE",
    "FORM",
    "BUTTON",
    "SELECT",
    "INPUT",
    "TEXTAREA",
  ]);
  const BLOCK =
    /^(P|DIV|SECTION|ARTICLE|LI|UL|OL|H[1-6]|TR|TABLE|BLOCKQUOTE|PRE|FIGCAPTION|DT|DD|HEADER|MAIN|BR)$/;
  const visible = (el: Element) =>
    !(el as HTMLElement).hidden &&
    el.getAttribute("aria-hidden") !== "true" &&
    (typeof (el as HTMLElement).checkVisibility !== "function" ||
      (el as HTMLElement).checkVisibility());
  const textOf = (root: Element) => {
    const out: string[] = [];
    let len = 0;
    const walk = (node: Node) => {
      if (len > maxChars) return;
      if (node.nodeType === Node.TEXT_NODE) {
        const t = (node.textContent ?? "").replace(/\s+/g, " ");
        if (t.trim()) {
          out.push(t);
          len += t.length;
        }
        return;
      }
      if (node.nodeType !== Node.ELEMENT_NODE) return;
      const el = node as Element;
      if (SKIP.has(el.tagName) || !visible(el)) return;
      if (el.getAttribute("role") === "navigation" || el.getAttribute("role") === "banner") return;
      const block = BLOCK.test(el.tagName);
      if (block) out.push("\n");
      if (/^H[1-6]$/.test(el.tagName)) out.push("\n");
      for (const c of el.childNodes) walk(c);
      if (block) out.push("\n");
    };
    walk(root);
    return out
      .join("")
      .replace(/[ \t]+\n/g, "\n")
      .replace(/\n[ \t]+/g, "\n")
      .replace(/\n{3,}/g, "\n\n")
      .trim();
  };
  const candidates = [
    ...document.querySelectorAll("article, main, [role=main], #content, .post, .article"),
  ].filter(visible);
  let root: Element = document.body;
  let best = 0;
  for (const c of candidates) {
    const n = (c.textContent ?? "").length;
    if (n > best * 1.2) {
      best = n;
      root = c;
    }
  }
  let text = root ? textOf(root) : "";
  if (text.length < 400 && document.body && root !== document.body) text = textOf(document.body);
  const secretField = [
    ...document.querySelectorAll(
      'input[type=password], input[autocomplete="cc-number"], input[autocomplete="cc-csc"], input[name*="cardnumber" i], input[name*="card_number" i]',
    ),
  ].some((el) => visible(el));
  return {
    url: location.href,
    title: document.title,
    selection: String(getSelection() ?? ""),
    text: text.slice(0, maxChars),
    secretField,
    lang: document.documentElement.lang || "",
  };
}

/** The page's main content as Markdown, for Save to Library (B1). */
export function pageMarkdown(maxChars: number): { title: string; url: string; markdown: string } {
  const SKIP =
    /^(SCRIPT|STYLE|NOSCRIPT|TEMPLATE|SVG|CANVAS|IFRAME|NAV|FOOTER|ASIDE|FORM|BUTTON|INPUT|SELECT|TEXTAREA)$/;
  const visible = (el: Element) =>
    !(el as HTMLElement).hidden &&
    el.getAttribute("aria-hidden") !== "true" &&
    (typeof (el as HTMLElement).checkVisibility !== "function" ||
      (el as HTMLElement).checkVisibility());
  const candidates = [...document.querySelectorAll("article, main, [role=main]")].filter(visible);
  let root: Element = document.body;
  let best = 0;
  for (const c of candidates) {
    const n = (c.textContent ?? "").length;
    if (n > best) {
      best = n;
      root = c;
    }
  }
  const abs = (href: string) => {
    try {
      const u = new URL(href, location.href);
      return /^https?:$/.test(u.protocol) ? u.href : "";
    } catch {
      return "";
    }
  };
  const inline = (node: Node): string => {
    if (node.nodeType === Node.TEXT_NODE) return (node.textContent ?? "").replace(/\s+/g, " ");
    if (node.nodeType !== Node.ELEMENT_NODE) return "";
    const el = node as Element;
    if (SKIP.test(el.tagName) || !visible(el)) return "";
    const inner = () => [...el.childNodes].map(inline).join("");
    switch (el.tagName) {
      case "A": {
        const t = inner().trim();
        const href = abs(el.getAttribute("href") ?? "");
        return t && href ? `[${t}](${href})` : t;
      }
      case "STRONG":
      case "B":
        return inner().trim() ? `**${inner().trim()}**` : "";
      case "EM":
      case "I":
        return inner().trim() ? `*${inner().trim()}*` : "";
      case "CODE":
        return `\`${el.textContent ?? ""}\``;
      case "IMG": {
        const src = abs(el.getAttribute("src") ?? "");
        return src ? `![${el.getAttribute("alt") ?? ""}](${src})` : "";
      }
      case "BR":
        return "\n";
      default:
        return inner();
    }
  };
  const blocks: string[] = [];
  const block = (node: Node, depth: number) => {
    if (node.nodeType === Node.TEXT_NODE) {
      const t = (node.textContent ?? "").replace(/\s+/g, " ").trim();
      if (t) blocks.push(t);
      return;
    }
    if (node.nodeType !== Node.ELEMENT_NODE) return;
    const el = node as Element;
    if (SKIP.test(el.tagName) || !visible(el)) return;
    const tag = el.tagName;
    if (/^H[1-6]$/.test(tag)) {
      blocks.push(`${"#".repeat(Number(tag[1]))} ${inline(el).trim()}`);
    } else if (tag === "P" || tag === "FIGCAPTION") {
      const t = inline(el).trim();
      if (t) blocks.push(t);
    } else if (tag === "PRE") {
      blocks.push(`\`\`\`\n${el.textContent ?? ""}\n\`\`\``);
    } else if (tag === "BLOCKQUOTE") {
      blocks.push(
        inline(el)
          .trim()
          .split("\n")
          .map((l) => `> ${l}`)
          .join("\n"),
      );
    } else if (tag === "UL" || tag === "OL") {
      let i = 1;
      const lines: string[] = [];
      for (const li of el.children) {
        if (li.tagName !== "LI") continue;
        const t = inline(li).trim();
        if (t) lines.push(`${"  ".repeat(depth)}${tag === "OL" ? `${i++}.` : "-"} ${t}`);
      }
      if (lines.length) blocks.push(lines.join("\n"));
    } else if (tag === "IMG") {
      const t = inline(el);
      if (t) blocks.push(t);
    } else {
      for (const c of el.childNodes) block(c, depth);
    }
  };
  block(root, 0);
  let markdown = blocks.join("\n\n").replace(/\n{3,}/g, "\n\n");
  if (markdown.length > maxChars) markdown = `${markdown.slice(0, maxChars)}…`;
  return { title: document.title, url: location.href, markdown };
}

export interface YouTubeInfo {
  title: string;
  time: number;
  /** json3 caption events, or null when the video has no captions. */
  events: Array<{ tStartMs?: number; segs?: Array<{ utf8?: string }> }> | null;
  language?: string;
}

/** Runs in the page's own world on youtube.com: the open video's captions and position. */
export async function youtubeInfo(): Promise<YouTubeInfo | null> {
  type Track = { baseUrl: string; languageCode?: string; kind?: string };
  type Player = {
    getPlayerResponse?: () => unknown;
    getCurrentTime?: () => number;
  };
  const player = document.querySelector("#movie_player") as unknown as Player | null;
  const response = (player?.getPlayerResponse?.() ??
    (window as unknown as { ytInitialPlayerResponse?: unknown }).ytInitialPlayerResponse) as
    | {
        videoDetails?: { title?: string };
        captions?: { playerCaptionsTracklistRenderer?: { captionTracks?: Track[] } };
      }
    | undefined;
  if (!response) return null;
  const tracks = response.captions?.playerCaptionsTracklistRenderer?.captionTracks ?? [];
  const pick =
    tracks.find((t) => t.languageCode?.startsWith("en") && t.kind !== "asr") ??
    tracks.find((t) => t.languageCode?.startsWith("en")) ??
    tracks[0];
  let events: YouTubeInfo["events"] = null;
  if (pick?.baseUrl) {
    try {
      const url = new URL(pick.baseUrl, location.href);
      url.searchParams.set("fmt", "json3");
      const res = await fetch(url.href, { credentials: "include" });
      if (res.ok) events = ((await res.json()) as { events?: YouTubeInfo["events"] }).events ?? [];
    } catch {
      events = null;
    }
  }
  return {
    title: response.videoDetails?.title ?? document.title,
    time: player?.getCurrentTime?.() ?? 0,
    events,
    language: pick?.languageCode,
  };
}

/** Lets the person drag a box over the page; resolves with it in CSS pixels, or null on Escape. */
export function pickRegion(): Promise<{
  x: number;
  y: number;
  w: number;
  h: number;
  dpr: number;
} | null> {
  return new Promise((resolve) => {
    const ID = "casama-region-picker";
    document.getElementById(ID)?.remove();
    const layer = document.createElement("div");
    layer.id = ID;
    layer.setAttribute(
      "style",
      "position:fixed;inset:0;z-index:2147483647;cursor:crosshair;background:rgba(0,0,0,.25);",
    );
    const hint = document.createElement("div");
    hint.textContent = "Drag over the part to ask about. Esc to cancel.";
    hint.setAttribute(
      "style",
      "position:fixed;top:12px;left:50%;transform:translateX(-50%);background:#1b1b1f;color:#fff;font:14px system-ui;padding:6px 12px;border-radius:999px;pointer-events:none;",
    );
    const box = document.createElement("div");
    box.setAttribute(
      "style",
      "position:fixed;border:2px solid #8ab4f8;background:rgba(138,180,248,.15);display:none;pointer-events:none;",
    );
    layer.append(hint, box);
    document.documentElement.append(layer);
    let start: { x: number; y: number } | null = null;
    const done = (r: { x: number; y: number; w: number; h: number; dpr: number } | null) => {
      layer.remove();
      removeEventListener("keydown", onKey, true);
      resolve(r);
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        e.preventDefault();
        done(null);
      }
    };
    addEventListener("keydown", onKey, true);
    layer.addEventListener("mousedown", (e) => {
      start = { x: e.clientX, y: e.clientY };
      box.style.display = "block";
    });
    layer.addEventListener("mousemove", (e) => {
      if (!start) return;
      const x = Math.min(start.x, e.clientX);
      const y = Math.min(start.y, e.clientY);
      Object.assign(box.style, {
        left: `${x}px`,
        top: `${y}px`,
        width: `${Math.abs(e.clientX - start.x)}px`,
        height: `${Math.abs(e.clientY - start.y)}px`,
      });
    });
    layer.addEventListener("mouseup", (e) => {
      if (!start) return;
      const r = {
        x: Math.min(start.x, e.clientX),
        y: Math.min(start.y, e.clientY),
        w: Math.abs(e.clientX - start.x),
        h: Math.abs(e.clientY - start.y),
        dpr: devicePixelRatio,
      };
      // Hide the layer first so it isn't in the screenshot.
      done(r.w < 8 || r.h < 8 ? null : r);
    });
  });
}

/** Whether the page shows a password or card field (G2): screenshots and saves skip such pages. */
export function hasSecretField(): boolean {
  return [
    ...document.querySelectorAll(
      'input[type=password], input[autocomplete="cc-number"], input[autocomplete="cc-csc"], input[name*="cardnumber" i], input[name*="card_number" i]',
    ),
  ].some(
    (el) =>
      !(el as HTMLElement).hidden &&
      el.getAttribute("aria-hidden") !== "true" &&
      (typeof (el as HTMLElement).checkVisibility !== "function" ||
        (el as HTMLElement).checkVisibility()),
  );
}
