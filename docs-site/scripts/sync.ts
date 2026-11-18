/** Copies the OpenAPI document into the site and writes the API reference page before a build. */
import {
  copyFileSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  statSync,
  writeFileSync,
} from "node:fs";

const root = new URL("../../", import.meta.url);
const here = new URL("../", import.meta.url);
mkdirSync(new URL("public/api/", here), { recursive: true });
copyFileSync(
  new URL("packages/contracts/openapi.json", root),
  new URL("public/api/openapi.json", here),
);
const version = JSON.parse(readFileSync(new URL("packages/contracts/openapi.json", root), "utf8"))
  .info.version;
writeFileSync(
  new URL("public/api/index.html", here),
  `<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Casama API reference</title></head>
<body>
<script id="api-reference" data-url="./openapi.json"></script>
<script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference@1.76.0"></script>
</body>
</html>
`,
);
console.log(`synced OpenAPI ${version}`);

// Docs for AI agents. Three outputs, all from the same markdown:
// - llms-full.txt (D-298): every page's source in one file, each after `<!-- page: URL -->`. The
//   support assistant in the API refreshes its docs from it hourly, so it stays the raw source.
// - llms.txt (llmstxt.org): an index of every page, in sidebar order, with a one-line summary
//   and a link to the page's markdown copy.
// - <page>.md next to every page (docs.casama.ai/develop/plugins.md): the page as clean
//   markdown, with VitePress containers turned into quotes and site links made absolute.
{
  const site = "https://docs.casama.ai";
  const skip = new Set(["node_modules", "public", "scripts", ".vitepress", ".wrangler"]);
  type Page = { clean: string; file: string; source: string };
  const pages: Page[] = [];
  const walk = (dir: URL, rel: string) => {
    for (const name of readdirSync(dir).sort()) {
      if (name.startsWith(".") || skip.has(name)) continue;
      const url = new URL(name, dir);
      if (statSync(url).isDirectory()) walk(new URL(`${name}/`, dir), `${rel}${name}/`);
      else if (name.endsWith(".md")) {
        const path = `${rel}${name.replace(/\.md$/, "")}`;
        const clean =
          path === "index" ? "/" : path.endsWith("/index") ? `/${path.slice(0, -5)}` : `/${path}`;
        pages.push({ clean, file: `${rel}${name}`, source: readFileSync(url, "utf8").trim() });
      }
    }
  };
  walk(here, "");
  writeFileSync(
    new URL("public/llms-full.txt", here),
    pages.map((p) => `<!-- page: ${site}${p.clean} -->\n${p.source}\n`).join("\n"),
  );

  /** The markdown copy's URL: /develop/plugins.md, and /self-hosting/index.md for a folder. */
  const mdUrl = (clean: string) =>
    clean === "/"
      ? `${site}/index.md`
      : `${site}${clean.endsWith("/") ? `${clean}index` : clean}.md`;
  const byClean = new Map(pages.map((p) => [p.clean, p]));
  const toMarkdown = (p: Page) => {
    let body = p.source;
    if (body.startsWith("---")) body = homePage(body);
    // Site links become absolute links to the markdown copies, so an agent can follow them.
    body = body.replace(/\]\((\/[^)\s#]*)(#[^)\s]*)?\)/g, (_all, path: string, hash = "") => {
      const page = byClean.get(path.replace(/\/$/, "") || "/") ?? byClean.get(path);
      return page ? `](${mdUrl(page.clean)}${hash})` : `](${site}${path}${hash})`;
    });
    // `::: tip Title` … `:::` → a quote, outside code fences.
    const out: string[] = [];
    let fence = false;
    let quote = false;
    for (const line of body.split("\n")) {
      if (/^\s*(```|~~~)/.test(line)) fence = !fence;
      const open = !fence && line.match(/^:::\s*(tip|info|warning|danger|details|note)\s*(.*)$/);
      if (open) {
        const kind = open[1][0].toUpperCase() + open[1].slice(1);
        out.push(`> **${open[2] ? `${kind}: ${open[2]}` : kind}**`, ">");
        quote = true;
      } else if (!fence && quote && line.trim() === ":::") quote = false;
      else out.push(quote ? (line ? `> ${line}` : ">") : line);
    }
    return `${out.join("\n").trim()}\n`;
  };
  for (const p of pages) {
    const target = new URL(`public${new URL(mdUrl(p.clean)).pathname}`, here);
    mkdirSync(new URL("./", target), { recursive: true });
    writeFileSync(target, toMarkdown(p));
  }

  // llms.txt follows the sidebar: a group is a `text:` line without a link, a page has both.
  const config = readFileSync(new URL(".vitepress/config.ts", here), "utf8");
  const sections: Array<{ title: string; pages: Page[] }> = [];
  const sidebar = config.slice(config.indexOf("sidebar:"), config.indexOf("socialLinks:"));
  for (const line of sidebar.split("\n")) {
    const item = line.match(/text: "([^"]+)", link: "([^"]+)"/);
    const group = !item && line.match(/^\s*text: "([^"]+)",\s*$/);
    if (group) sections.push({ title: group[1], pages: [] });
    else if (item && sections.length) {
      const page = byClean.get(item[2].replace(/\/$/, "") || "/") ?? byClean.get(item[2]);
      if (page && !sections.some((s) => s.pages.includes(page))) sections.at(-1)?.pages.push(page);
    }
  }
  const listed = new Set(sections.flatMap((s) => s.pages));
  const rest = pages.filter((p) => !listed.has(p) && p.clean !== "/");
  if (rest.length) sections.push({ title: "More", pages: rest });
  const title = (p: Page) => p.source.match(/^# (.+)$/m)?.[1].trim() ?? p.clean;
  /** The first sentence of the paragraph under the title (a page that opens with a heading: none). */
  const summary = (p: Page) => {
    const after = (p.source.split(/^# .+$/m)[1] ?? "").split(/^#/m)[0];
    const para = after.split(/\n\s*\n/).find((b) => /^[A-Za-z*_[`]/.test(b.trim())) ?? "";
    const plain = para
      .replace(/\s+/g, " ")
      .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1")
      .replace(/[*`]/g, "")
      .trim();
    if (plain) return plain.match(/^.+?[.!?](?=\s|$)/)?.[0] ?? plain;
    const headings = [...p.source.matchAll(/^## (.+)$/gm)].map((m) => m[1].trim());
    return headings.length ? `Covers ${headings.join(", ")}.` : "";
  };
  const llms = [
    "# Casama",
    "",
    "> Casama gives people AI teammates (bots) with their own computers. Bots remember, work on a real Linux computer, ask before risky steps, run on schedules and triggers, and can be self-hosted with any model. Open source (AGPL-3.0; SDKs, CLI and plugin kit Apache-2.0).",
    "",
    "Each link below goes to a page's markdown copy. Every page on docs.casama.ai has one: add `.md` to its address.",
    "",
    "Building on Casama:",
    "",
    `- HTTP API: https://api.casama.ai, described by ${site}/api/openapi.json (OpenAPI 3.1).`,
    "- Docs over MCP, no sign-in needed: https://api.casama.ai/mcp/docs (tools: search_docs, read_doc, list_doc_pages, get_api_operation). `npx -y @casama/mcp` has the same tools plus check_plugin, gallery_search and your bots.",
    "- Skills for coding agents: https://github.com/stackwares/casama/tree/main/agent-kit (in Claude Code: `/plugin marketplace add stackwares/casama`, then `/plugin install casama-dev@casama`).",
    "- Start a plugin, skill, bot template or routine with `casama init`, and check a plugin with `npx @casama/plugin-check`.",
    "- Check the gallery before you build: https://gallery.casama.ai has ready-made skills, apps, routines, bots, plugins, starter sets and looks. `npx -y @casama/mcp` has gallery_search, `casama gallery search <words>` searches from a terminal and `casama init --from-gallery bot/<id>` (or `plugin/<id>`) starts from one.",
    "",
    "Gallery catalog (public JSON, no sign-in; every file has `schema` and `items` except where noted):",
    "",
    "- https://gallery.casama.ai/index.json: themes, color schemes, wallpapers and skills.",
    "- https://gallery.casama.ai/apps.json, bots.json, routines.json, plugins.json, sets.json: apps, starter bots, routine ideas, reviewed plugins and starter sets. lists.json: search words, welcome choices, empty-screen starters and app curation.",
    "- https://gallery.casama.ai/authors.json: authors and their items (`authors`).",
    "- https://gallery.casama.ai/manifest.json: the sha256 of every file above (`files`), signed with Ed25519 in manifest.sig.",
    "- https://api.casama.ai/v1/gallery/stats: installs, trending, active users and run success per item (`items`, keyed `<type>/<id>`; small numbers left out).",
    "",
    ...sections.flatMap((s) => [
      `## ${s.title}`,
      "",
      ...s.pages.map((p) => {
        const d = summary(p);
        return `- [${title(p)}](${mdUrl(p.clean)})${d ? `: ${d}` : ""}`;
      }),
      "",
    ]),
    "## Optional",
    "",
    `- [Every page in one file](${site}/llms-full.txt): all of the above, about 600 KB.`,
    "",
  ].join("\n");
  writeFileSync(new URL("public/llms.txt", here), llms);
  console.log(`wrote llms.txt, llms-full.txt and ${pages.length} markdown pages`);
}

/** The home page is all frontmatter: its hero and feature cards, as plain markdown. */
function homePage(source: string) {
  const fm = source.split(/^---$/m)[1] ?? "";
  const field = (key: string) => fm.match(new RegExp(`^\\s+${key}: (.+)$`, "m"))?.[1].trim();
  const cards = [
    ...fm.matchAll(/- title: (.+)\n\s+details: (.+)\n\s+link: (.+)\n\s+linkText: (.+)/g),
  ].map((m) => `- **${m[1].trim()}.** ${m[2].trim()} See [${m[4].trim()}](${m[3].trim()}).`);
  return [`# Casama: ${field("text") ?? ""}`, "", field("tagline") ?? "", "", ...cards].join("\n");
}
