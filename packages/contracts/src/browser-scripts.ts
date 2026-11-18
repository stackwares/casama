/**
 * Scripts both browser backends run inside a page (D-323 Phase 3), kept in one place so the bot's
 * computer and the person's Chrome give the same answers. No imports: the extension bundles this file.
 */

/** Visible tables (or, failing that, lists) on the page as CSV. */
export const EXTRACT_TABLES_JS = `(() => {
  const esc = (v) => /[",\\n]/.test(v) ? '"' + v.replace(/"/g, '""') + '"' : v;
  const cell = (c) => esc(c.innerText.trim().replace(/\\s+/g, " "));
  const rows = (t) => [...t.querySelectorAll("tr")].map((tr) => [...tr.querySelectorAll("th,td")].map(cell).join(","));
  const tables = [...document.querySelectorAll("table")].filter((t) => t.offsetParent !== null);
  if (tables.length) return tables.slice(0, 5).map((t, i) => "# Table " + (i + 1) + "\\n" + rows(t).join("\\n")).join("\\n\\n");
  const lists = [...document.querySelectorAll("ul,ol")].filter((l) => l.offsetParent !== null && l.children.length >= 3);
  return lists.slice(0, 3).map((l, i) => "# List " + (i + 1) + "\\n" + [...l.children].map(cell).join("\\n")).join("\\n\\n") || "No tables or lists on this page.";
})()`;
