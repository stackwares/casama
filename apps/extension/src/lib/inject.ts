/**
 * More functions injected with chrome.scripting.executeScript when the person asks (Phase 2). Each
 * stands alone: Chrome serializes the function, so nothing from this module's scope is inside it.
 */

export interface Picked {
  /** What the element says, cut to 4,000 characters. */
  text: string;
  /** "table", "button", "section"… */
  tag: string;
  /** A short label for the chip: the element's kind and its first words. */
  label: string;
  /** For a watcher: the first words, to find the part again, and how much of it to compare. */
  anchor: string;
  chars: number;
}

/**
 * A19 and B10: the person points at part of the page. Hover outlines, a click picks, Esc cancels.
 * Resolves null when cancelled.
 */
export function pickElement(hint: string): Promise<Picked | null> {
  return new Promise((resolve) => {
    const host = document.createElement("div");
    host.setAttribute("data-casama-picker", "");
    const root = host.attachShadow({ mode: "closed" });
    root.innerHTML = `<style>
      .box{position:fixed;pointer-events:none;border:2px solid #1a73e8;background:rgba(26,115,232,.08);border-radius:4px;z-index:2147483647;transition:all .05s}
      .tip{position:fixed;left:50%;top:12px;transform:translateX(-50%);background:#111;color:#fff;font:13px system-ui,sans-serif;padding:8px 12px;border-radius:8px;z-index:2147483647;pointer-events:none}
    </style><div class="box"></div><div class="tip"></div>`;
    const box = root.querySelector(".box") as HTMLElement;
    (root.querySelector(".tip") as HTMLElement).textContent = `${hint} (Esc to cancel)`;
    document.documentElement.append(host);
    let target: Element | null = null;
    const meaningful = (el: Element | null): Element | null => {
      // Climb past tiny inline bits to something worth meaning "this".
      let e = el;
      while (e && e !== document.body && (e.textContent ?? "").trim().length < 12)
        e = e.parentElement;
      return e && e !== document.body && e !== document.documentElement ? e : el;
    };
    const move = (ev: MouseEvent) => {
      if (!ev.isTrusted) return;
      const el = meaningful(document.elementFromPoint(ev.clientX, ev.clientY));
      if (!el || host.contains(el)) return;
      target = el;
      const r = el.getBoundingClientRect();
      Object.assign(box.style, {
        left: `${r.left - 2}px`,
        top: `${r.top - 2}px`,
        width: `${r.width + 4}px`,
        height: `${r.height + 4}px`,
      });
    };
    // Nobody clicked within two minutes: give up rather than leave the panel waiting.
    const timer = setTimeout(() => done(null), 120_000);
    const done = (v: Picked | null) => {
      clearTimeout(timer);
      removeEventListener("mousemove", move, true);
      removeEventListener("click", click, true);
      removeEventListener("keydown", key, true);
      host.remove();
      resolve(v);
    };
    const click = (ev: MouseEvent) => {
      // Clicks the page makes up don't count.
      if (!ev.isTrusted) return;
      ev.preventDefault();
      ev.stopPropagation();
      if (!target) return done(null);
      const el = target as HTMLElement;
      const text = (el.textContent || "").replace(/[ \t]+/g, " ").trim();
      const tag = el.tagName.toLowerCase();
      const first = text.replace(/\s+/g, " ").slice(0, 60).trim();
      const kind =
        tag === "table"
          ? "Table"
          : /^h[1-6]$/.test(tag)
            ? "Heading"
            : tag === "button"
              ? "Button"
              : tag === "img"
                ? "Picture"
                : "Part";
      // A watcher finds the part again by the steady words just before it (a label or heading),
      // not by its own text, which is what changes (a price).
      const flat = (s: string) => s.replace(/\s+/g, " ");
      const page = flat(document.body.textContent || "");
      const own = flat(text).trim();
      const at = own ? page.indexOf(own.slice(0, 60)) : -1;
      let anchor = first;
      let chars = Math.max(20, Math.min(2000, own.length));
      if (at > 0) {
        const before = page.slice(Math.max(0, at - 80), at);
        const words = before.replace(/^\S*\s/, "").trim();
        if (words.length >= 8) {
          anchor = words.slice(-60).trim();
          const from = page.lastIndexOf(anchor, at);
          if (from >= 0) chars = Math.max(20, Math.min(2000, at - from + own.length));
        }
      }
      done({
        text: text.slice(0, 4000),
        tag,
        label: `${kind}: ${first.slice(0, 40)}${first.length > 40 ? "…" : ""}`,
        anchor,
        chars,
      });
    };
    const key = (ev: KeyboardEvent) => {
      if (ev.isTrusted && ev.key === "Escape") {
        ev.preventDefault();
        done(null);
      }
    };
    addEventListener("mousemove", move, true);
    addEventListener("click", click, true);
    addEventListener("keydown", key, true);
  });
}

/**
 * A18: translates the page's text in place with Chrome's on-device Translator. Resolves
 * "unavailable" when this computer can't, so the bot does it instead.
 */
export async function translatePage(
  target: string,
): Promise<{ done: number } | "unavailable" | "same"> {
  interface BrowserTranslator {
    availability(o: { sourceLanguage: string; targetLanguage: string }): Promise<string>;
    create(o: {
      sourceLanguage: string;
      targetLanguage: string;
    }): Promise<{ translate(s: string): Promise<string> }>;
  }
  const T = (globalThis as { Translator?: BrowserTranslator }).Translator;
  if (!T) return "unavailable";
  const source = (document.documentElement.lang || "en").split("-")[0]!.toLowerCase();
  if (source === target) return "same";
  try {
    if (
      (await T.availability({ sourceLanguage: source, targetLanguage: target })) === "unavailable"
    )
      return "unavailable";
    const tr = await T.create({ sourceLanguage: source, targetLanguage: target });
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
      acceptNode: (n) =>
        n.textContent &&
        n.textContent.trim().length > 1 &&
        !/^(SCRIPT|STYLE|NOSCRIPT|TEXTAREA|CODE|PRE)$/.test(n.parentElement?.tagName ?? "")
          ? NodeFilter.FILTER_ACCEPT
          : NodeFilter.FILTER_REJECT,
    });
    const nodes: Text[] = [];
    while (walker.nextNode() && nodes.length < 3000) nodes.push(walker.currentNode as Text);
    let done = 0;
    for (const n of nodes) {
      n.textContent = await tr.translate(n.textContent ?? "");
      done++;
    }
    document.documentElement.lang = target;
    return { done };
  } catch {
    return "unavailable";
  }
}

/**
 * The text of the page's form field the person was in, if any, and a handle to put text back.
 * "secret" when the page shows a password or card field, or the field is one (nothing is read).
 */
export function focusedField(): { id: string; text: string } | "secret" | null {
  const el = document.activeElement as HTMLElement | null;
  if (!el) return null;
  const SECRET = /^(cc-|one-time-code|current-password|new-password)/;
  const secretInput = (i: Element) =>
    (i instanceof HTMLInputElement &&
      (i.type === "password" ||
        SECRET.test(i.autocomplete || "") ||
        /card|cvc|cvv/i.test(i.name || ""))) ||
    SECRET.test(i.getAttribute("autocomplete") || "");
  if (secretInput(el)) return "secret";
  for (const i of document.querySelectorAll("input"))
    if (secretInput(i) && (i as HTMLElement).offsetParent !== null) return "secret";
  const editable =
    el.isContentEditable ||
    el instanceof HTMLTextAreaElement ||
    (el instanceof HTMLInputElement && /^(text|email|search|url)$/.test(el.type));
  if (!editable) return null;
  const id = el.getAttribute("data-casama-field") || `f${Math.random().toString(36).slice(2, 10)}`;
  el.setAttribute("data-casama-field", id);
  const text = el.isContentEditable ? (el.textContent ?? "") : (el as HTMLInputElement).value;
  return { id, text: text.slice(0, 8000) };
}

/** Puts [text] into the field marked [id], as if typed, so the page sees the change. */
export function insertIntoField(id: string, text: string): boolean {
  const el = document.querySelector(
    `[data-casama-field="${CSS.escape(id)}"]`,
  ) as HTMLElement | null;
  if (!el) return false;
  el.removeAttribute("data-casama-field");
  el.focus();
  if (el.isContentEditable) {
    const sel = getSelection();
    sel?.selectAllChildren(el);
    // execCommand keeps the page's own undo and its editors (Gmail) in step.
    if (!document.execCommand("insertText", false, text)) el.textContent = text;
  } else {
    const input = el as HTMLInputElement | HTMLTextAreaElement;
    const proto = Object.getPrototypeOf(input);
    const setter = Object.getOwnPropertyDescriptor(proto, "value")?.set;
    if (setter) setter.call(input, text);
    else input.value = text;
    input.dispatchEvent(new Event("input", { bubbles: true }));
    input.dispatchEvent(new Event("change", { bubbles: true }));
  }
  return true;
}
