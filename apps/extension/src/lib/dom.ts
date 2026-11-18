/** A tiny element builder shared by the extension's pages. Plain DOM; no framework. */
export type Child = Node | string | null | undefined | false;

export function h<K extends keyof HTMLElementTagNameMap>(
  tag: K,
  props: Record<string, unknown> = {},
  ...children: Child[]
): HTMLElementTagNameMap[K] {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(props)) {
    if (v === undefined || v === null || v === false) continue;
    if (k.startsWith("on") && typeof v === "function")
      el.addEventListener(k.slice(2).toLowerCase(), v as EventListener);
    else if (k === "className") el.className = String(v);
    else if (k in el && typeof v !== "string") (el as unknown as Record<string, unknown>)[k] = v;
    else el.setAttribute(k, v === true ? "" : String(v));
  }
  for (const c of children) if (c) el.append(c);
  return el;
}

/** Text size as people read it: "3,200 characters", "48 KB". */
export function sizeLabel(chars: number): string {
  return chars < 10_000
    ? `${chars.toLocaleString("en-US")} characters`
    : `${Math.round(chars / 1000).toLocaleString("en-US")}k characters`;
}

export function bytesLabel(n: number): string {
  if (n >= 1024 * 1024) return `${(n / 1024 / 1024).toFixed(1)} MB`;
  return `${Math.max(1, Math.round(n / 1024))} KB`;
}
