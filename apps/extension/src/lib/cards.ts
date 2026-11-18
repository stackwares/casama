/**
 * Cards in replies (A2): a renderer for the A2UI v1.0 basic catalog bots use (D-086, D-322), in
 * plain DOM. Anything it doesn't know becomes an "Open in Casama" card, so nothing a bot showed
 * is silently lost. Answers go back as the app sends them: a summary text and a ui_action part.
 */
import { h } from "./dom.ts";
import { markdownNodes } from "./md.ts";

type Comp = Record<string, unknown> & { id: string; component: string };
type Msg = Record<string, unknown>;

export interface UiAction {
  surface_id: string;
  name: string;
  context: Record<string, unknown>;
}

export interface CardOptions {
  /** Sends the person's answer. */
  onAction?: (text: string, action: UiAction) => void | Promise<void>;
  /** Where "Open in Casama" goes. */
  openUrl?: string;
  /** Already answered: shown dimmed, inputs off. */
  answered?: boolean;
}

export const KNOWN = new Set([
  "Text",
  "Row",
  "Column",
  "List",
  "Card",
  "Tabs",
  "Divider",
  "Button",
  "TextField",
  "CheckBox",
  "ChoicePicker",
  "Slider",
  "DateTimeInput",
  "Image",
  "Icon",
  "Video",
  "AudioPlayer",
]);

/** The surface's components and data from its A2UI messages. */
export function surfaceOf(messages: Msg[]) {
  const comps = new Map<string, Comp>();
  let data: Record<string, unknown> = {};
  for (const m of messages) {
    const upd = (m.updateComponents as { components?: Comp[] } | undefined)?.components;
    if (Array.isArray(upd))
      for (const c of upd) if (c && typeof c.id === "string") comps.set(c.id, c);
    const dm = m.updateDataModel as { path?: string; value?: unknown } | undefined;
    if (dm) {
      if (!dm.path || dm.path === "/") data = (dm.value as Record<string, unknown>) ?? {};
      else setPath(data, dm.path, dm.value);
    }
  }
  return { comps, data };
}

/** A card's data paths, without the keys that would reach Object.prototype from bot-sent data. */
const UNSAFE = new Set(["__proto__", "prototype", "constructor"]);
const pathKeys = (path: string) => {
  const keys = path.split("/").filter(Boolean);
  return keys.some((k) => UNSAFE.has(k)) ? null : keys;
};

export function getPath(data: Record<string, unknown>, path: string): unknown {
  const keys = pathKeys(path);
  if (!keys) return undefined;
  let cur: unknown = data;
  for (const k of keys) {
    if (!cur || typeof cur !== "object" || !Object.hasOwn(cur, k)) return undefined;
    cur = (cur as Record<string, unknown>)[k];
  }
  return cur;
}

export function setPath(data: Record<string, unknown>, path: string, value: unknown) {
  const keys = pathKeys(path);
  if (!keys?.length) return;
  let cur = data;
  for (const k of keys.slice(0, -1)) {
    if (!Object.hasOwn(cur, k) || !cur[k] || typeof cur[k] !== "object") cur[k] = {};
    cur = cur[k] as Record<string, unknown>;
  }
  cur[keys.at(-1)!] = value;
}

/** A value that may be bound: {"@path": "/x"} (v1.0) or {path: "/x"} (older), else literal. */
export function resolve(v: unknown, data: Record<string, unknown>): unknown {
  if (v && typeof v === "object" && !Array.isArray(v)) {
    const o = v as Record<string, unknown>;
    if (typeof o["@path"] === "string") return getPath(data, o["@path"]);
    if (typeof o.path === "string" && Object.keys(o).length === 1) return getPath(data, o.path);
    if (typeof o["@call"] === "string") return checkCall(o, data);
    return Object.fromEntries(Object.entries(o).map(([k, x]) => [k, resolve(x, data)]));
  }
  if (Array.isArray(v)) return v.map((x) => resolve(x, data));
  return v;
}

const pathOf = (v: unknown) =>
  v && typeof v === "object"
    ? ((v as { "@path"?: string; path?: string })["@path"] ?? (v as { path?: string }).path)
    : undefined;

/** The D-322 check functions. */
export function checkCall(o: Record<string, unknown>, data: Record<string, unknown>): boolean {
  const args = (o.args ?? {}) as Record<string, unknown>;
  const val = resolve(args.value, data);
  const str = val == null ? "" : Array.isArray(val) ? val.join(",") : String(val);
  switch (o["@call"]) {
    case "required":
      return Array.isArray(val) ? val.length > 0 : str.trim().length > 0;
    case "email":
      return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(str);
    case "length":
      return str.length >= Number(args.min ?? 0) && str.length <= Number(args.max ?? Infinity);
    case "numeric": {
      const n = Number(str);
      return (
        str.trim() !== "" &&
        !Number.isNaN(n) &&
        n >= Number(args.min ?? -Infinity) &&
        n <= Number(args.max ?? Infinity)
      );
    }
    case "regex":
      try {
        return new RegExp(String(args.pattern ?? "")).test(str);
      } catch {
        return false;
      }
    case "and":
      return ((args.values as unknown[]) ?? []).every((x) => resolve(x, data) === true);
    case "or":
      return ((args.values as unknown[]) ?? []).some((x) => resolve(x, data) === true);
    case "not":
      return resolve(args.value, data) !== true;
    default:
      return false;
  }
}

/** The first failing check's message, or null. */
export function failingCheck(c: Comp, data: Record<string, unknown>): string | null {
  for (const ch of (c.checks as Array<{ condition: unknown; message?: string }>) ?? [])
    if (resolve(ch.condition, data) !== true) return ch.message ?? "Check this first.";
  return null;
}

/** The answer's text, as the app writes it: the button's label and the values sent. */
export function answerText(label: string, context: Record<string, unknown>): string {
  const vals = Object.entries(context)
    .filter(
      ([, v]) => v !== undefined && v !== null && v !== "" && !(Array.isArray(v) && !v.length),
    )
    .map(
      ([k, v]) =>
        `${k}: ${Array.isArray(v) ? v.join(", ") : typeof v === "object" ? JSON.stringify(v) : String(v)}`,
    );
  return [label, ...vals].filter(Boolean).join("\n");
}

const LETTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
const httpsUrl = (u: unknown) => (typeof u === "string" && /^https:\/\//.test(u) ? u : null);

/** Draws one surface. Returns null when there's nothing to draw. */
export function renderSurface(
  surfaceId: string,
  messages: Msg[],
  opts: CardOptions = {},
): HTMLElement {
  const { comps, data } = surfaceOf(messages);
  const root = comps.get("root");
  const card = h("div", {
    className: `ui-card${opts.answered ? " answered" : ""}`,
    "data-testid": "ui-card",
  });
  const unknown = [...comps.values()].some((c) => !KNOWN.has(c.component));
  if (!root || unknown) {
    card.append(
      h("p", { className: "muted" }, "This card opens in the Casama app."),
      opts.openUrl
        ? h("a", { href: opts.openUrl, target: "_blank", rel: "noopener" }, "Open in Casama")
        : "",
    );
    return card;
  }
  const refreshers: Array<() => void> = [];
  const refreshChecks = () => {
    for (const r of refreshers) r();
  };
  const draw = (id: unknown, depth = 0): Node => {
    const c = typeof id === "string" ? comps.get(id) : undefined;
    if (!c || depth > 30) return document.createTextNode("");
    const kids = () => ((c.children as string[]) ?? []).map((k) => draw(k, depth + 1));
    const r = (v: unknown) => resolve(v, data);
    switch (c.component) {
      case "Text": {
        const text = String(r(c.text) ?? "");
        const el = h("div", { className: `ui-text ${c.variant === "caption" ? "caption" : ""}` });
        el.append(markdownNodes(text));
        return el;
      }
      case "Row":
      case "Column":
      case "List":
        return h(
          "div",
          {
            className: `ui-${c.component === "Row" || c.direction === "horizontal" ? "row" : "col"}`,
            "data-align": c.align ?? "",
            "data-justify": c.justify ?? "",
          },
          ...kids(),
        );
      case "Card":
        return h("div", { className: "ui-inner-card" }, draw(c.child, depth + 1));
      case "Divider":
        return h("hr");
      case "Tabs": {
        const tabs = (c.tabs as Array<{ title: unknown; child: string }>) ?? [];
        const body = h("div", { className: "ui-tab-body" });
        const bar = h("div", { className: "ui-tabs", role: "tablist" });
        const pick = (i: number) => {
          body.replaceChildren(draw(tabs[i]?.child, depth + 1));
          for (const [j, b] of [...bar.children].entries())
            b.setAttribute("aria-selected", String(i === j));
        };
        for (const [i, t] of tabs.entries())
          bar.append(
            h(
              "button",
              { role: "tab", type: "button", onClick: () => pick(i) },
              String(r(t.title) ?? ""),
            ),
          );
        pick(0);
        return h("div", {}, bar, body);
      }
      case "Image": {
        const u = httpsUrl(r(c.url));
        return u
          ? h("img", {
              className: "ui-image",
              src: u,
              alt: String(r(c.description) ?? ""),
              loading: "lazy",
            })
          : document.createTextNode("");
      }
      case "Icon":
        return h("span", { className: "ui-icon", "aria-hidden": "true" }, "•");
      case "Video": {
        const u = httpsUrl(r(c.url));
        return u
          ? h("video", {
              className: "ui-media",
              src: u,
              controls: true,
              poster: httpsUrl(r(c.posterUrl)) ?? undefined,
              preload: "metadata",
            })
          : document.createTextNode("");
      }
      case "AudioPlayer": {
        const u = httpsUrl(r(c.url));
        return u
          ? h("audio", {
              className: "ui-media",
              src: u,
              controls: true,
              preload: "metadata",
              "aria-label": String(r(c.description) ?? "Audio"),
            })
          : document.createTextNode("");
      }
      case "TextField": {
        const p = pathOf(c.value);
        const long = c.variant === "longText";
        const input = h(long ? "textarea" : "input", {
          placeholder: String(r(c.placeholder) ?? ""),
          disabled: opts.answered,
          ...(long ? {} : { type: c.variant === "number" ? "number" : "text" }),
        }) as HTMLInputElement;
        input.value = String(r(c.value) ?? "");
        input.addEventListener("input", () => {
          if (p)
            setPath(
              data,
              p,
              c.variant === "number" && input.value !== "" ? Number(input.value) : input.value,
            );
          refreshChecks();
        });
        return h("label", { className: "ui-field" }, String(r(c.label) ?? ""), input);
      }
      case "CheckBox": {
        const p = pathOf(c.value);
        const box = h("input", { type: "checkbox", disabled: opts.answered }) as HTMLInputElement;
        box.checked = r(c.value) === true;
        box.addEventListener("change", () => {
          if (p) setPath(data, p, box.checked);
          refreshChecks();
        });
        return h("label", { className: "ui-check" }, box, String(r(c.label) ?? ""));
      }
      case "ChoicePicker": {
        const p = pathOf(c.value);
        const multi = c.variant === "multipleSelection";
        const chips = c.displayStyle === "chips";
        const options = ((c.options as Array<{ label: unknown; value: unknown }>) ?? []).map(
          (o) => ({
            label: String(r(o.label) ?? r(o.value) ?? ""),
            value: String(r(o.value) ?? ""),
          }),
        );
        const current = () => {
          const v = p ? getPath(data, p) : undefined;
          return Array.isArray(v) ? v.map(String) : v != null ? [String(v)] : [];
        };
        const wrap = h("fieldset", {
          className: `ui-choices${chips ? " chips" : ""}`,
          disabled: opts.answered,
        });
        if (c.label) wrap.append(h("legend", {}, String(r(c.label))));
        options.forEach((o, i) => {
          const input = h("input", {
            type: multi ? "checkbox" : "radio",
            name: `${surfaceId}-${c.id}`,
            value: o.value,
          }) as HTMLInputElement;
          input.checked = current().includes(o.value);
          input.addEventListener("change", () => {
            const now = new Set(multi ? current() : []);
            if (input.checked) now.add(o.value);
            else now.delete(o.value);
            if (p) setPath(data, p, [...now]);
            refreshChecks();
          });
          wrap.append(
            h(
              "label",
              { className: "ui-choice" },
              input,
              chips ? o.label : `${LETTERS[i] ?? i + 1}) ${o.label}`,
            ),
          );
        });
        return wrap;
      }
      case "Slider": {
        const p = pathOf(c.value);
        const input = h("input", {
          type: "range",
          min: String(c.min ?? 0),
          max: String(c.max ?? 100),
          disabled: opts.answered,
        }) as HTMLInputElement;
        input.value = String(r(c.value) ?? c.min ?? 0);
        const out = h("output", {}, input.value);
        input.addEventListener("input", () => {
          out.textContent = input.value;
          if (p) setPath(data, p, Number(input.value));
          refreshChecks();
        });
        return h(
          "label",
          { className: "ui-field" },
          String(r(c.label) ?? ""),
          h("div", { className: "ui-row" }, input, out),
        );
      }
      case "DateTimeInput": {
        const p = pathOf(c.value);
        const date = c.enableDate !== false;
        const time = c.enableTime === true;
        const input = h("input", {
          type: date && time ? "datetime-local" : time ? "time" : "date",
          disabled: opts.answered,
        }) as HTMLInputElement;
        input.value = String(r(c.value) ?? "");
        input.addEventListener("input", () => {
          if (p) setPath(data, p, input.value);
          refreshChecks();
        });
        return h("label", { className: "ui-field" }, String(r(c.label) ?? ""), input);
      }
      case "Button": {
        const labelComp = comps.get(String(c.child));
        const label = String(resolve(labelComp?.text, data) ?? "OK");
        const btn = h(
          "button",
          {
            type: "button",
            className:
              c.variant === "primary" ? "primary" : c.variant === "borderless" ? "link" : "",
            disabled: opts.answered,
          },
          label,
        ) as HTMLButtonElement;
        const update = () => {
          const fail = failingCheck(c, data);
          btn.disabled = !!opts.answered || !!fail;
          btn.title = fail ?? "";
        };
        refreshers.push(update);
        update();
        btn.addEventListener("click", async () => {
          const event = (c.action as { event?: { name?: string; context?: unknown } })?.event ?? {};
          const context = (resolve(event.context ?? {}, data) ?? {}) as Record<string, unknown>;
          const name = String(event.name ?? "submit");
          if (!opts.onAction) return;
          for (const b of card.querySelectorAll("button, input, textarea, select"))
            (b as HTMLButtonElement).disabled = true;
          card.classList.add("answered");
          await opts.onAction(answerText(label, context), { surface_id: surfaceId, name, context });
        });
        return btn;
      }
      default:
        return document.createTextNode("");
    }
  };
  card.append(draw("root"));
  return card;
}
