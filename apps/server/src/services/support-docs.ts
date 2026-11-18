/**
 * What the support assistant knows (D-298): the user docs, split into sections and searched by
 * keyword (BM25). It starts from the copy of docs-site shipped with the server, so it always
 * knows this release, then swaps in <DOCS_URL>/llms-full.txt once an hour when that's reachable,
 * so a docs fix reaches the assistant without a server deploy.
 *
 * Both assistants (the app's and the websites', D-401) also know casama.ai's own explainers:
 * /learn, /compare, pricing, security, self-hosting and about, shipped with the server from
 * site/content. Those stay through the hourly docs refresh.
 */
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import { fileURLToPath } from "node:url";

// The index itself (BM25 over ## sections) lives in @casama/mcp, which serves the same docs to
// coding agents as MCP tools (search_docs, read_doc).
import { DocIndex, type DocPage, pageTitle, parseLlmsFull } from "@casama/mcp/docs";

export {
  DocIndex,
  type DocPage,
  type DocSection,
  PAGE_MARK,
  pageTitle,
  parseLlmsFull,
  sectionsOf,
  tokens,
} from "@casama/mcp/docs";

/** docs-site next to the server: ../../../../docs-site from here, in the repo and in the image. */
export function bundledDocsDir(): string {
  return fileURLToPath(new URL("../../../../docs-site/", import.meta.url));
}

/** casama.ai's content next to the server: ../../../../site/content from here. */
export function bundledSiteDir(): string {
  return fileURLToPath(new URL("../../../../site/content/", import.meta.url));
}

/** The casama.ai pages the assistants may answer from (D-401). */
const SITE_PAGES = ["pricing", "security", "self-hosted", "about", "open-source", "bots"];
const SITE_FOLDERS = ["learn", "compare"];

/**
 * casama.ai's explainers from site/content, front matter dropped, the lead kept as the first
 * paragraph, each at its address on the site.
 */
export function readSiteDir(dir: string, base = "https://casama.ai"): DocPage[] {
  if (!existsSync(dir)) return [];
  const files: { file: string; path: string }[] = [];
  for (const name of SITE_PAGES) {
    const file = join(dir, `${name}.md`);
    if (existsSync(file)) files.push({ file, path: `/${name}` });
  }
  for (const folder of SITE_FOLDERS) {
    const d = join(dir, folder);
    if (!existsSync(d)) continue;
    for (const name of readdirSync(d).sort()) {
      if (!name.endsWith(".md")) continue;
      const slug = name.slice(0, -3);
      files.push({
        file: join(d, name),
        path: slug === "index" ? `/${folder}` : `/${folder}/${slug}`,
      });
    }
  }
  return files.map(({ file, path }) => {
    const raw = readFileSync(file, "utf8");
    const fm = /^---\n([\s\S]*?)\n---\n?/.exec(raw);
    const field = (k: string) =>
      fm?.[1] ? new RegExp(`^${k}:\\s*["']?(.+?)["']?\\s*$`, "m").exec(fm[1])?.[1] : undefined;
    const title = field("h1") ?? field("title") ?? pageTitle(raw, path);
    const lead = field("lead") ?? field("description") ?? "";
    const body = `# ${title}\n\n${lead}\n\n${fm ? raw.slice(fm[0].length) : raw}`;
    return { url: `${base}${path}`, title, body };
  });
}

/**
 * The FAQ page split at each question rather than at its groups, so a search finds the one answer
 * instead of a whole group cut off at the length a result keeps.
 */
export function splitFaq(pages: DocPage[]): DocPage[] {
  return pages.map((p) =>
    /\/faq$/.test(p.url)
      ? { ...p, body: p.body.replace(/^## .+$/gm, "").replace(/^### /gm, "## ") }
      : p,
  );
}

/** The user docs from a docs-site folder: guide, self-hosting, develop and the top-level pages. */
export function readDocsDir(dir: string, base: string): DocPage[] {
  if (!existsSync(dir)) return [];
  const files: string[] = [];
  const walk = (d: string) => {
    for (const name of readdirSync(d)) {
      if (
        name.startsWith(".") ||
        name === "node_modules" ||
        name === "public" ||
        name === "scripts"
      )
        continue;
      const full = join(d, name);
      if (statSync(full).isDirectory()) walk(full);
      else if (name.endsWith(".md")) files.push(full);
    }
  };
  walk(dir);
  return files.sort().map((f) => {
    const rel = relative(dir, f).replace(/\\/g, "/").replace(/\.md$/, "");
    const path =
      rel === "index" ? "/" : rel.endsWith("/index") ? `/${rel.slice(0, -5)}` : `/${rel}`;
    const body = readFileSync(f, "utf8");
    return { url: `${base.replace(/\/$/, "")}${path}`, title: pageTitle(body, rel), body };
  });
}

/** The live index: bundled docs at once, the published ones when fetched (hourly). */
export class SupportDocs {
  private index: DocIndex;
  private fetchedAt = 0;
  private inflight?: Promise<void>;

  private readonly opts: {
    docsUrl: string;
    dir?: string;
    /** casama.ai's site/content; empty string leaves it out. */
    siteDir?: string;
    fetchImpl?: typeof fetch;
    now?: () => number;
    refreshMs?: number;
  };

  private readonly site: DocPage[];

  constructor(opts: SupportDocs["opts"]) {
    this.opts = opts;
    this.site = opts.siteDir === "" ? [] : readSiteDir(opts.siteDir ?? bundledSiteDir());
    this.index = this.build(readDocsDir(opts.dir ?? bundledDocsDir(), opts.docsUrl));
  }

  private build(docs: DocPage[]): DocIndex {
    return new DocIndex([...splitFaq(docs), ...this.site]);
  }

  /** How many docs pages (not casama.ai pages) the index holds. */
  private get docsCount() {
    return this.index.pages.length - this.site.length;
  }

  /** The index, refreshing it in the background when it's older than an hour. */
  async current(): Promise<DocIndex> {
    const now = (this.opts.now ?? Date.now)();
    if (now - this.fetchedAt > (this.opts.refreshMs ?? 3_600_000) && !this.inflight) {
      this.fetchedAt = now;
      this.inflight = this.refresh().finally(() => {
        this.inflight = undefined;
      });
      // Wait for the first fetch only when nothing was bundled.
      if (!this.docsCount) await this.inflight;
    }
    return this.index;
  }

  private async refresh() {
    try {
      const res = await (this.opts.fetchImpl ?? fetch)(
        `${this.opts.docsUrl.replace(/\/$/, "")}/llms-full.txt`,
        { signal: AbortSignal.timeout(10_000) },
      );
      if (!res.ok) return;
      const pages = parseLlmsFull(await res.text());
      // A partial or broken file never replaces a good index.
      if (pages.length >= Math.max(5, Math.floor(this.docsCount / 2)))
        this.index = this.build(pages);
    } catch {
      // Offline or the docs are down: keep what we have.
    }
  }
}
