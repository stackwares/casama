/**
 * The page kit (Phase 2): the selection bar (A15), the write button in text boxes (A16), site
 * helpers (A17) and highlights (B7). Chrome runs it only on the sites the person gave Casama access
 * to, and only once they've turned one of these on (background/kit.ts registers it).
 *
 * It reads nothing on its own. It asks the service worker whether this page is allowed (the guard)
 * and what's switched on; a tap on one of its buttons hands the work to the side panel, which reads
 * the page as usual, where the person can see what's sent. Its buttons live in a shadow root and
 * ignore clicks the page makes up (isTrusted), so a page can't press them.
 */
import { type Helper, helperFor } from "./helpers.ts";
import type { KitConfig, KitMessage, WriteMode } from "./protocol.ts";

declare const __CASAMA_TARGET__: string;

(() => {
  const w = window as unknown as { __casamaKit?: boolean };
  if (w.__casamaKit) return;
  w.__casamaKit = true;

  const send = <T>(m: KitMessage): Promise<T | null> =>
    chrome.runtime.sendMessage(m).catch(() => null) as Promise<T | null>;
  const mode = __CASAMA_TARGET__ === "store" ? "closed" : "open";

  const CSS_TEXT = `
    :host{all:initial}
    .bar{position:fixed;z-index:2147483646;display:flex;gap:2px;padding:4px;background:#111;color:#fff;border-radius:10px;box-shadow:0 4px 16px rgba(0,0,0,.25);font:13px/1 system-ui,-apple-system,sans-serif}
    .bar button,.menu button{all:unset;cursor:pointer;padding:6px 8px;border-radius:6px;white-space:nowrap;font:13px/1 system-ui,-apple-system,sans-serif;color:inherit}
    .bar button:hover,.bar button:focus-visible,.menu button:hover,.menu button:focus-visible{background:rgba(255,255,255,.18)}
    .bar .sep{width:1px;background:rgba(255,255,255,.25);margin:4px 2px}
    .pen{position:fixed;z-index:2147483646;width:26px;height:26px;border-radius:13px;background:#111;color:#fff;display:flex;align-items:center;justify-content:center;font:600 13px system-ui,sans-serif;cursor:pointer;box-shadow:0 2px 8px rgba(0,0,0,.25)}
    .menu{position:fixed;z-index:2147483647;display:flex;flex-direction:column;padding:4px;background:#111;color:#fff;border-radius:10px;box-shadow:0 4px 16px rgba(0,0,0,.25)}
    .helper{position:fixed;right:16px;bottom:16px;z-index:2147483645;display:flex;align-items:center;gap:2px;padding:4px 4px 4px 10px;background:#111;color:#fff;border-radius:12px;box-shadow:0 4px 16px rgba(0,0,0,.25);font:13px/1 system-ui,sans-serif}
    .helper .name{opacity:.7;margin-right:4px}
    .helper button{all:unset;cursor:pointer;padding:6px 8px;border-radius:6px;font:13px/1 system-ui,sans-serif}
    .helper button:hover,.helper button:focus-visible{background:rgba(255,255,255,.18)}
    .helper .x{opacity:.6}
    .hl-layer{position:absolute;top:0;left:0;width:0;height:0;pointer-events:none}
    .hl{position:absolute;background:rgba(253,230,138,.55);mix-blend-mode:multiply;border-radius:2px;pointer-events:none}
    .note{position:fixed;z-index:2147483647;left:50%;bottom:24px;transform:translateX(-50%);background:#111;color:#fff;padding:8px 12px;border-radius:8px;font:13px system-ui,sans-serif}
    @media (prefers-color-scheme: dark){.bar,.menu,.helper,.pen,.note{background:#f3f3f3;color:#111}.bar button:hover,.menu button:hover,.helper button:hover{background:rgba(0,0,0,.1)}}
  `;

  const host = document.createElement("casama-kit");
  // The page can't hide or shrink the kit to trick a click: these inline !important rules beat its
  // stylesheets, and a click counts only when the kit is visible and on top (see btn).
  host.setAttribute(
    "style",
    "all:initial !important;display:block !important;position:absolute !important;top:0 !important;left:0 !important;width:0 !important;height:0 !important;overflow:visible !important;opacity:1 !important;visibility:visible !important;transform:none !important;filter:none !important;clip-path:none !important;z-index:2147483647 !important;pointer-events:auto !important",
  );
  const root = host.attachShadow({ mode });
  const style = document.createElement("style");
  style.textContent = CSS_TEXT;
  root.append(style);
  let disabled = false;
  /** Shows a piece of the kit, putting the kit on the page only once there's something to show. */
  const mount = (el: Element) => {
    if (disabled) return;
    if (!host.isConnected) document.documentElement.append(host);
    root.append(el);
  };
  const shownFairly = (e: MouseEvent) => {
    const cs = getComputedStyle(host);
    if (cs.opacity !== "1" || cs.visibility !== "visible" || cs.display === "none") return false;
    // Nothing of the page's is laid over the button.
    return document.elementFromPoint(e.clientX, e.clientY) === host;
  };

  const btn = (label: string, testid: string, run: () => void) => {
    const b = document.createElement("button");
    b.type = "button";
    b.textContent = label;
    b.dataset.testid = testid;
    // Clicks the page makes up don't count, and the page underneath never sees ours.
    b.addEventListener("mousedown", (e) => e.preventDefault());
    b.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();
      if (e.isTrusted && !disabled && shownFairly(e)) run();
    });
    return b;
  };
  const div = (cls: string, testid?: string) => {
    const d = document.createElement("div");
    d.className = cls;
    if (testid) d.dataset.testid = testid;
    return d;
  };
  const note = (text: string) => {
    const n = div("note", "kit-note");
    n.textContent = text;
    mount(n);
    setTimeout(() => n.remove(), 2500);
  };

  let cfg: KitConfig | null = null;

  async function start() {
    cfg = await send<KitConfig>({ type: "kit:config", url: location.href });
    if (!cfg || cfg.off) return;
    // Settings changed, signed out, or switched off remotely: kits already on pages stop too.
    chrome.runtime.onMessage.addListener((m: { type?: string }) => {
      if (m?.type !== "kit:refresh") return;
      void send<KitConfig>({ type: "kit:config", url: location.href }).then((c) => {
        if (!c || c.off) {
          disabled = true;
          host.remove();
        } else cfg = { ...c };
      });
    });
    if (cfg.selectionBar) selectionBar();
    if (cfg.writeBox) writeBox();
    if (cfg.helpers.length) helpers();
    if (cfg.highlights.length) paintAll();
  }

  // ---------------------------------------------------------------------------
  // A15: the selection bar

  let bar: HTMLDivElement | null = null;
  const hideBar = () => {
    bar?.remove();
    bar = null;
  };
  function selectionBar() {
    const show = () => {
      const sel = getSelection();
      const text = sel?.toString().trim() ?? "";
      if (!sel || sel.rangeCount === 0 || text.length < 3) return hideBar();
      const anchor = sel.anchorNode?.parentElement;
      if (anchor?.closest("input,textarea,[contenteditable=''],[contenteditable='true']"))
        return hideBar();
      const r = sel.getRangeAt(0).getBoundingClientRect();
      if (!r.width && !r.height) return hideBar();
      hideBar();
      bar = div("bar", "selection-bar");
      const ask = (prompt: string | undefined, sendNow: boolean) => () => {
        hideBar();
        void send({ type: "kit:ask", prompt, send: sendNow, selection: text });
      };
      bar.append(
        btn("Ask", "sb-ask", ask(undefined, false)),
        btn("Explain", "sb-explain", ask("Explain this.", true)),
        btn("Summarize", "sb-summarize", ask("Summarize this.", true)),
        btn(
          "Translate",
          "sb-translate",
          ask("Translate this into English (or into my language if it's already English).", true),
        ),
        btn("Highlight", "sb-highlight", () => {
          hideBar();
          void highlight(sel);
        }),
      );
      const cmds = cfg?.commands.slice(0, 3) ?? [];
      if (cmds.length) {
        bar.append(div("sep"));
        for (const c of cmds)
          bar.append(btn(`/${c.name}`, `sb-cmd-${c.name}`, ask(c.prompt, true)));
      }
      mount(bar);
      const top = r.top > 48 ? r.top - 40 : r.bottom + 8;
      const left = Math.max(
        8,
        Math.min(innerWidth - bar.offsetWidth - 8, r.left + r.width / 2 - bar.offsetWidth / 2),
      );
      Object.assign(bar.style, { top: `${top}px`, left: `${left}px` });
    };
    document.addEventListener("mouseup", (e) => {
      if (e.composedPath().includes(host)) return;
      setTimeout(show, 0);
    });
    document.addEventListener("keyup", (e) => {
      if (e.key === "Escape") return hideBar();
      if (e.shiftKey) show();
    });
    document.addEventListener("mousedown", (e) => {
      if (!e.composedPath().includes(host)) hideBar();
    });
    addEventListener("scroll", hideBar, { passive: true, capture: true });
  }

  // ---------------------------------------------------------------------------
  // B7: highlights, drawn as boxes inside the kit's own shadow root: the page's DOM and its
  // highlight registry aren't touched, so the page can't read which passages someone kept.

  const marks: Range[] = [];
  const layer = div("hl-layer");
  let repaint = 0;
  function paint() {
    layer.replaceChildren();
    for (const r of marks)
      for (const rect of r.getClientRects()) {
        if (!rect.width || !rect.height) continue;
        const d = div("hl");
        Object.assign(d.style, {
          left: `${rect.left + scrollX}px`,
          top: `${rect.top + scrollY}px`,
          width: `${rect.width}px`,
          height: `${rect.height}px`,
        });
        layer.append(d);
      }
    if (marks.length && !layer.isConnected) {
      mount(layer);
      // Layout changes move the text: draw again, at most twice a second.
      const again = () => {
        if (repaint) return;
        repaint = window.setTimeout(() => {
          repaint = 0;
          paint();
        }, 500);
      };
      addEventListener("resize", again);
      new MutationObserver((list) => {
        if (list.some((m) => !host.contains(m.target))) again();
      }).observe(document.body, { childList: true, subtree: true, characterData: true });
    }
    // The tests read the count; the store build doesn't tell the page.
    if (mode === "open")
      host.dataset.highlights = String(layer.childElementCount ? marks.length : 0);
  }

  /** The page's text nodes and where each starts in the joined text. */
  function textMap() {
    const nodes: { node: Text; start: number }[] = [];
    let all = "";
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
      acceptNode: (n) =>
        /^(SCRIPT|STYLE|NOSCRIPT|TEMPLATE)$/.test(n.parentElement?.tagName ?? "") ||
        host.contains(n)
          ? NodeFilter.FILTER_REJECT
          : NodeFilter.FILTER_ACCEPT,
    });
    while (walker.nextNode()) {
      const node = walker.currentNode as Text;
      nodes.push({ node, start: all.length });
      all += node.data;
    }
    return { nodes, all };
  }

  function findRange(text: string, prefix: string, suffix: string): Range | null {
    const { nodes, all } = textMap();
    let best = -1;
    let bestScore = -1;
    for (let i = all.indexOf(text); i >= 0; i = all.indexOf(text, i + 1)) {
      const before = all.slice(Math.max(0, i - prefix.length), i);
      const after = all.slice(i + text.length, i + text.length + suffix.length);
      const score =
        (prefix && before.endsWith(prefix) ? 2 : 0) + (suffix && after.startsWith(suffix) ? 2 : 0);
      if (score > bestScore) {
        best = i;
        bestScore = score;
      }
    }
    if (best < 0) return null;
    const at = (pos: number) => {
      for (let k = nodes.length - 1; k >= 0; k--)
        if (nodes[k]!.start <= pos) return { node: nodes[k]!.node, offset: pos - nodes[k]!.start };
      return null;
    };
    const s = at(best);
    const e = at(best + text.length);
    if (!s || !e) return null;
    const r = document.createRange();
    r.setStart(s.node, Math.min(s.offset, s.node.length));
    r.setEnd(e.node, Math.min(e.offset, e.node.length));
    return r;
  }

  function paintAll() {
    marks.length = 0;
    for (const hl of cfg?.highlights ?? []) {
      const r = findRange(hl.text, hl.prefix, hl.suffix);
      if (r) marks.push(r);
    }
    paint();
  }

  async function highlight(sel: Selection) {
    const range = sel.getRangeAt(0).cloneRange();
    const text = range.toString().trim();
    if (!text) return;
    const { nodes, all } = textMap();
    // Where this selection is, so the words around it are the right ones when the text repeats.
    const startNode = nodes.find((n) => n.node === range.startContainer);
    const raw = startNode ? startNode.start + range.startOffset : -1;
    const lead = raw >= 0 ? all.indexOf(text, raw) : -1;
    const i = lead >= 0 && lead - raw < 64 ? lead : all.indexOf(text);
    const prefix = i >= 0 ? all.slice(Math.max(0, i - 32), i) : "";
    const suffix = i >= 0 ? all.slice(i + text.length, i + text.length + 32) : "";
    const r = await send<{ id?: string; error?: string }>({
      type: "kit:highlight",
      url: location.href,
      title: document.title,
      text: text.slice(0, 5000),
      prefix,
      suffix,
    });
    if (!r?.id) return note(r?.error ?? "Couldn't save the highlight.");
    marks.push(range);
    paint();
    sel.removeAllRanges();
    note("Highlighted. Your bots can find it.");
  }

  // ---------------------------------------------------------------------------
  // A16: write in any text box

  const editable = (el: Element | null): el is HTMLElement => {
    if (!(el instanceof HTMLElement) || host.contains(el)) return false;
    if (el.isContentEditable) return true;
    if (el instanceof HTMLTextAreaElement) return !el.readOnly && !el.disabled;
    return false;
  };
  function writeBox() {
    let pen: HTMLDivElement | null = null;
    let menu: HTMLDivElement | null = null;
    let field: HTMLElement | null = null;
    const place = () => {
      if (!pen || !field) return;
      const r = field.getBoundingClientRect();
      if (!r.width || r.bottom < 0 || r.top > innerHeight) {
        pen.style.display = "none";
        return;
      }
      pen.style.display = "flex";
      Object.assign(pen.style, { left: `${r.right - 32}px`, top: `${r.bottom - 32}px` });
    };
    const close = () => {
      menu?.remove();
      menu = null;
    };
    const pick = (m: WriteMode) => () => {
      close();
      if (!field) return;
      const id =
        field.getAttribute("data-casama-field") || `f${Math.random().toString(36).slice(2, 10)}`;
      field.setAttribute("data-casama-field", id);
      const text = (
        field.isContentEditable ? field.innerText : (field as HTMLTextAreaElement).value
      ).slice(0, 8000);
      void send({ type: "kit:write", mode: m, fieldId: id, text });
    };
    document.addEventListener("focusin", (e) => {
      const el = e.composedPath()[0] as Element;
      if (host.contains(el)) return;
      if (!editable(el)) return;
      const root_ = el.isContentEditable
        ? ((el.closest("[contenteditable]") as HTMLElement) ?? el)
        : el;
      const r = root_.getBoundingClientRect();
      if (r.width < 120 || r.height < 28) return;
      field = root_;
      if (!pen) {
        pen = div("pen", "write-button");
        pen.textContent = "C";
        pen.title = "Write with Casama";
        pen.addEventListener("mousedown", (ev) => ev.preventDefault());
        pen.addEventListener("click", (ev) => {
          if (!ev.isTrusted) return;
          if (menu) return close();
          menu = div("menu", "write-menu");
          const empty = !(
            field?.isContentEditable
              ? field.innerText
              : (field as HTMLTextAreaElement | null)?.value
          )?.trim();
          menu.append(
            btn(empty ? "Draft it" : "Draft a new one", "write-draft", pick("draft")),
            ...(empty
              ? []
              : [
                  btn("Rewrite", "write-rewrite", pick("rewrite")),
                  btn("Shorten", "write-shorten", pick("shorten")),
                ]),
            btn("Reply in my voice", "write-reply", pick("reply")),
          );
          mount(menu);
          const pr = pen!.getBoundingClientRect();
          Object.assign(menu.style, {
            left: `${Math.max(8, pr.right - menu.offsetWidth)}px`,
            top: `${pr.top > 160 ? pr.top - menu.offsetHeight - 6 : pr.bottom + 6}px`,
          });
        });
        mount(pen);
      }
      place();
    });
    document.addEventListener("focusout", () => {
      setTimeout(() => {
        const a = document.activeElement;
        if (menu || (a && field && (a === field || field.contains(a)))) return;
        pen?.remove();
        pen = null;
      }, 150);
    });
    addEventListener("scroll", place, { passive: true, capture: true });
    addEventListener("resize", place);
  }

  // ---------------------------------------------------------------------------
  // A17: site helpers, hiding themselves when the page changes under them

  function helpers() {
    let shown: { helper: Helper; el: HTMLDivElement } | null = null;
    let dismissed = false;
    const reported = new Set<string>();
    const check = () => {
      if (dismissed || !cfg) return;
      const u = new URL(location.href);
      const helper = helperFor(u, document, cfg.helpers);
      const anchor = helper?.anchor(document) ?? null;
      if (helper && !anchor && !reported.has(helper.name)) {
        // The page is the kind the helper knows, but its element is gone: the site changed.
        reported.add(helper.name);
        void send({ type: "kit:helper-missing", helper: helper.name });
      }
      if (!helper || !anchor) {
        shown?.el.remove();
        shown = null;
        return;
      }
      if (shown?.helper === helper) return;
      shown?.el.remove();
      const el = div("helper", `helper-${helper.name}`);
      const name = document.createElement("span");
      name.className = "name";
      name.textContent = "Casama";
      el.append(name);
      for (const a of helper.actions(u))
        el.append(
          btn(a.label, `helper-action`, () => {
            if (a.watchPrice) void send({ type: "kit:watch-price" });
            else void send({ type: "kit:ask", prompt: a.prompt, send: true, readText: a.readText });
          }),
        );
      el.append(
        btn("×", "helper-close", () => {
          dismissed = true;
          el.remove();
          shown = null;
        }),
      );
      (el.lastChild as HTMLElement).className = "x";
      (el.lastChild as HTMLElement).setAttribute("aria-label", "Hide");
      mount(el);
      shown = { helper, el };
    };
    let timer = 0;
    new MutationObserver(() => {
      if (timer) return;
      timer = window.setTimeout(() => {
        timer = 0;
        check();
      }, 400);
    }).observe(document.documentElement, { childList: true, subtree: true });
    check();
  }

  void start();
})();
