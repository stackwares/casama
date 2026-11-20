import { readFileSync } from "node:fs";
import { defineConfig } from "vitepress";

const repo = "https://github.com/stackwares/casama";
const site = "https://docs.casama.ai";
const sectionNames: Record<string, string> = {
  guide: "Guides",
  develop: "Build on Casama",
  "self-hosting": "Self-hosting",
};

/** introduction.md → /introduction, self-hosting/index.md → /self-hosting/, index.md → /. */
const cleanPath = (relativePath: string) =>
  `/${relativePath.replace(/\.md$/, "").replace(/(^|\/)index$/, "$1")}`;

/** The first paragraph under a page's title as plain text, cut at a sentence end near 160 characters. */
const firstParagraph = (relativePath: string) => {
  let source: string;
  try {
    source = readFileSync(new URL(`../${relativePath}`, import.meta.url), "utf8");
  } catch {
    return "";
  }
  const body = source.replace(/^---[\s\S]*?\n---\n/, "").split(/^# .+$/m)[1] ?? "";
  const paragraph = body
    .split(/\n\s*\n/)
    .map((block) => block.trim())
    .find((block) => block && !/^(#|<|:::|```|\||- |\d+\. |!\[|>)/.test(block));
  if (!paragraph) return "";
  const text = paragraph
    .replace(/\[([^\]]+)\]\([^)]*\)/g, "$1")
    .replace(/[`*_]/g, "")
    .replace(/\s+/g, " ")
    .trim();
  if (text.length <= 160) return text;
  const cut = text.slice(0, 160);
  const end = Math.max(cut.lastIndexOf(". "), cut.lastIndexOf("? "));
  return end > 80 ? cut.slice(0, end + 1) : `${cut.slice(0, cut.lastIndexOf(" ", 158))}…`;
};

/** Markdown to plain text for structured data: links keep their words, formatting goes. */
const plain = (markdown: string) =>
  markdown
    .replace(/!\[[^\]]*\]\([^)]*\)/g, "")
    .replace(/\[([^\]]+)\]\([^)]*\)/g, "$1")
    .replace(/<[^>]+>/g, " ")
    .replace(/^\s*([-*]|\d+\.)\s+/gm, "")
    .replace(/^:::.*$/gm, "")
    .replace(/[`*_]/g, "")
    .replace(/\s+/g, " ")
    .trim();

/** The FAQ's questions ("### Question?" and the answer up to the next heading) for FAQPage data. */
const faqQuestions = (relativePath: string) => {
  let source: string;
  try {
    source = readFileSync(new URL(`../${relativePath}`, import.meta.url), "utf8");
  } catch {
    return [];
  }
  const items: { question: string; answer: string[] }[] = [];
  let current: { question: string; answer: string[] } | null = null;
  let fence = false;
  for (const line of source.replace(/^---[\s\S]*?\n---\n/, "").split("\n")) {
    if (/^\s*(```|~~~)/.test(line)) fence = !fence;
    const h3 = !fence && line.match(/^###\s+(.+?)\s*(\{#[^}]*\})?\s*$/);
    if (h3) {
      current = { question: plain(h3[1]), answer: [] };
      items.push(current);
    } else if (!fence && /^#{1,2}\s/.test(line)) {
      current = null;
    } else if (current) {
      current.answer.push(line);
    }
  }
  return items
    .map((q) => ({ question: q.question, answer: plain(q.answer.join("\n")) }))
    .filter((q) => q.question && q.answer);
};

const searchTitles: Record<string, string> = {
  "develop/cli.md": "Casama CLI: commands for bots, runs and servers",
  "develop/packs.md": "Pack format: build and publish a pack",
  "guide/packs.md": "Packs: install whole bots, routines and apps",
  "develop/plugins.md": "Plugins: give a Casama bot new skills and tools",
  "develop/webhooks.md": "Webhooks: send Casama events to your own URL",
  "develop/api.md": "Casama HTTP API reference (OpenAPI 3.1)",
  "develop/sdk.md": "Dart SDK for the Casama API",
  "faq.md": "Casama FAQ: pricing, privacy and self-hosting",
  "guide/skills.md": "Skills: a repeatable way of working for a bot",
  "guide/routines.md": "Routines: scheduled and triggered bot work",
  "guide/computers.md": "Computers: a Linux machine for every Casama bot",
  "guide/limits.md": "Limits: every default cap, timeout and budget",
  "guide/pages.md": "Pages: reports and dashboards a bot publishes",
  "guide/memory.md": "Memory and knowledge: what a Casama bot remembers",
  "guide/library.md": "The Library: files and pages your bots keep for you",
  "guide/chat.md": "Chatting with a bot: messages, files and voice",
  "guide/bots.md": "Bots and models: pick the AI model for each bot",
  "self-hosting/index.md": "Self-hosting Casama: run it on your own server",
  "self-hosting/configuration.md": "Self-hosting configuration: all settings",
  "self-hosting/operations.md": "Operating a Casama server: updates and backups",
  "self-hosting/troubleshooting.md": "Self-hosting troubleshooting: common fixes",
};

export default defineConfig({
  title: "Casama",
  // Every page's <title> reads "<what it covers> | Casama docs": the docs' own name in the search result.
  titleTemplate: ":title | Casama docs",
  description: "Casama docs: guides, the HTTP API, SDKs and self-hosting for open-source AI teammates that have their own computers.",
  sitemap: {
    hostname: "https://docs.casama.ai",
  },
  cleanUrls: true,
  lastUpdated: true,
  // public/ holds each page's markdown copy (scripts/sync.ts). Without this VitePress builds those
  // copies as pages too, so every page existed twice, once under /public/ (docs/SEO-PLAN.md §2.3).
  srcExclude: ["public/**", "node_modules/**", "scripts/**"],
  ignoreDeadLinks: [/^\/api\//],
  markdown: {
    // Inline code shows placeholders like {{secret:NAME}} as written, instead of Vue evaluating them.
    config: (md) => {
      const render = md.renderer.rules.code_inline;
      md.renderer.rules.code_inline = (...args) =>
        (render?.(...args) ?? "").replace("<code", "<code v-pre");
    },
  },
  head: [
    ["link", { rel: "icon", type: "image/svg+xml", href: "/casama-winky-animated.svg" }],
    ["link", { rel: "icon", href: "/favicon.ico", sizes: "48x48" }],
    ["link", { rel: "apple-touch-icon", href: "/apple-touch-icon.png" }],
    // Error reports (D-416): loads Sentry only when a page breaks; no cookie (docs-site/public/errors.js).
    ["script", { src: "/errors.js", "data-dsn": "https://86edd9eaf9c8b7f88c6a1cf3b71a1e94@o219011.ingest.us.sentry.io/4512413457776640", "data-surface": "docs" }],
    ["meta", { name: "theme-color", content: "#ffffff", media: "(prefers-color-scheme: light)" }],
    ["meta", { name: "theme-color", content: "#1c1c1e", media: "(prefers-color-scheme: dark)" }],
    [
      "link",
      {
        rel: "preload",
        href: "/brand/GoogleSans-Regular.woff2",
        as: "font",
        type: "font/woff2",
        crossorigin: "",
      },
    ],
    ["link", { rel: "alternate", type: "text/plain", href: "/llms.txt", title: "llms.txt" }],
    ["meta", { property: "og:image", content: "https://docs.casama.ai/og-image.png" }],
    ["meta", { property: "og:image:width", content: "1200" }],
    ["meta", { property: "og:image:height", content: "630" }],
    ["meta", { name: "twitter:card", content: "summary_large_image" }],
    ["meta", { name: "twitter:image", content: "https://docs.casama.ai/og-image.png" }],
  ],
  // A page with no description of its own gets its first paragraph, so search results and share
  // cards say what the page is about instead of repeating the site's one line.
  transformPageData: (pageData) => {
    // A one-word page title ("Packs", "CLI") says little in a search result, and two pages shared
    // "Packs". These pages get a fuller <title>; their on-page heading stays as written.
    const fuller = searchTitles[pageData.relativePath];
    if (fuller) pageData.title = fuller;
    if (pageData.frontmatter.description) return;
    const description = firstParagraph(pageData.relativePath);
    if (description) pageData.description = description;
  },
  // Each page names its one address, carries share tags and structured data, and points at its
  // markdown copy (written by scripts/sync.ts), for AI agents.
  transformHead: ({ pageData }) => {
    if (pageData.isNotFound) return [];
    const url = `${site}${cleanPath(pageData.relativePath)}`;
    const home = pageData.relativePath === "index.md";
    const title = home ? "Casama docs" : `${pageData.title} | Casama docs`;
    const description =
      pageData.description || "Self-hostable AI teammates with their own computers.";
    const crumbs = cleanPath(pageData.relativePath).split("/").filter(Boolean);
    const data: Record<string, unknown>[] = [
      {
        "@context": "https://schema.org",
        "@type": "TechArticle",
        headline: pageData.title || "Casama docs",
        description,
        url,
        inLanguage: "en",
        ...(pageData.lastUpdated
          ? { dateModified: new Date(pageData.lastUpdated).toISOString() }
          : {}),
        author: { "@type": "Organization", name: "Casama", url: "https://casama.ai/" },
        publisher: { "@type": "Organization", name: "Casama", url: "https://casama.ai/" },
        isPartOf: { "@type": "WebSite", name: "Casama docs", url: `${site}/` },
      },
    ];
    if (crumbs.length) {
      data.push({
        "@context": "https://schema.org",
        "@type": "BreadcrumbList",
        itemListElement: [
          { "@type": "ListItem", position: 1, name: "Docs", item: `${site}/` },
          ...crumbs.map((part, i) => ({
            "@type": "ListItem",
            position: i + 2,
            name: i === crumbs.length - 1 ? pageData.title || part : (sectionNames[part] ?? part),
            item: `${site}/${crumbs.slice(0, i + 1).join("/")}${i === crumbs.length - 1 ? "" : "/"}`,
          })),
        ],
      });
    }
    if (pageData.relativePath === "faq.md") {
      const questions = faqQuestions(pageData.relativePath);
      if (questions.length) {
        data.push({
          "@context": "https://schema.org",
          "@type": "FAQPage",
          url,
          mainEntity: questions.map((q) => ({
            "@type": "Question",
            name: q.question,
            acceptedAnswer: { "@type": "Answer", text: q.answer },
          })),
        });
      }
    }
    return [
      ["link", { rel: "canonical", href: url }],
      ["link", { rel: "alternate", type: "text/markdown", href: `/${pageData.relativePath}` }],
      ["meta", { property: "og:type", content: home ? "website" : "article" }],
      ["meta", { property: "og:site_name", content: "Casama docs" }],
      ["meta", { property: "og:url", content: url }],
      ["meta", { property: "og:title", content: title }],
      ["meta", { property: "og:description", content: description }],
      ["meta", { property: "og:image", content: "https://casama.ai/og-image.png" }],
      ["meta", { name: "twitter:card", content: "summary_large_image" }],
      ["meta", { name: "twitter:title", content: title }],
      ["meta", { name: "twitter:description", content: description }],
      ["meta", { name: "twitter:image", content: "https://casama.ai/og-image.png" }],
      ["script", { type: "application/ld+json" }, JSON.stringify(data).replace(/</g, "\\u003c")],
    ];
  },
  themeConfig: {
    nav: [
      { text: "Get started", link: "/quick-start" },
      { text: "Guides", link: "/guide/bots" },
      { text: "Self-hosting", link: "/self-hosting/" },
      { text: "Build on Casama", link: "/develop/api" },
      { text: "API", link: "/api/", target: "_self" },
    ],
    sidebar: [
      {
        text: "Get started",
        items: [
          { text: "What is Casama", link: "/introduction" },
          { text: "Quick start", link: "/quick-start" },
          { text: "FAQ", link: "/faq" },
          { text: "Getting an invite", link: "/guide/getting-an-invite" },
        ],
      },
      {
        text: "Bots",
        collapsed: false,
        items: [
          { text: "Bots and models", link: "/guide/bots" },
          { text: "Memory and knowledge", link: "/guide/memory" },
          { text: "Skills", link: "/guide/skills" },
          { text: "Templates, sharing and import", link: "/guide/sharing" },
          { text: "Packs", link: "/guide/packs" },
          { text: "Bots working together", link: "/guide/bots-together" },
          { text: "Moving from Grok Bot", link: "/guide/moving-from-grok-bot" },
        ],
      },
      {
        text: "Chat",
        collapsed: false,
        items: [
          { text: "Chatting with a bot", link: "/guide/chat" },
          { text: "Group chats", link: "/guide/group-chats" },
          { text: "The Library", link: "/guide/library" },
          { text: "Pages", link: "/guide/pages" },
          { text: "Sites and domains", link: "/guide/sites-and-domains" },
          { text: "Domain terms and prices", link: "/guide/domain-terms" },
          { text: "Voice and calls", link: "/guide/voice" },
          { text: "Chat apps", link: "/guide/chat-apps" },
          { text: "Appearance and themes", link: "/guide/appearance" },
        ],
      },
      {
        text: "Getting work done",
        collapsed: false,
        items: [
          { text: "Computers", link: "/guide/computers" },
          { text: "Your own computer", link: "/guide/companion" },
          { text: "Casama for Chrome", link: "/guide/chrome" },
          { text: "Bots in the notch and menu bar", link: "/guide/notch" },
          { text: "Bots on the Lock Screen", link: "/guide/lock-screen" },
          { text: "Widgets and controls", link: "/guide/widgets" },
          { text: "Casama on Apple Watch", link: "/guide/apple-watch" },
          { text: "Casama on Wear OS", link: "/guide/wear-os" },
          { text: "Casama on a folding phone", link: "/guide/folding-phones" },
          { text: "Coding agents", link: "/guide/coding-agents" },
          { text: "Teach by showing", link: "/guide/teach" },
          { text: "Routines and triggers", link: "/guide/routines" },
          { text: "Meeting notes", link: "/guide/meetings" },
          { text: "Projects and tickets", link: "/guide/projects" },
        ],
      },
      {
        text: "Connections",
        collapsed: false,
        items: [
          { text: "Apps and connections", link: "/guide/connections" },
          { text: "Device connections and health", link: "/guide/devices" },
          { text: "Payments", link: "/guide/payments" },
          { text: "Connect AI apps (MCP)", link: "/guide/mcp" },
        ],
      },
      {
        text: "Control and privacy",
        collapsed: false,
        items: [
          { text: "Autonomy and approvals", link: "/guide/autonomy" },
          { text: "Notifications and attention", link: "/guide/attention" },
          { text: "Usage, budgets and plans", link: "/guide/usage" },
          { text: "Saved resets", link: "/guide/saved-resets" },
          { text: "Limits", link: "/guide/limits" },
          { text: "Workspaces and teams", link: "/guide/workspaces" },
          { text: "Privacy and security", link: "/guide/privacy" },
        ],
      },
      {
        text: "Self-hosting",
        collapsed: false,
        items: [
          { text: "Install", link: "/self-hosting/" },
          { text: "Configuration", link: "/self-hosting/configuration" },
          { text: "Casama Link", link: "/guide/casama-link" },
          { text: "Use it on your phone", link: "/self-hosting/remote-access" },
          { text: "Cloud computers and credits", link: "/self-hosting/casama-link-cloud" },
          { text: "Computer providers", link: "/self-hosting/computers" },
          { text: "Operations", link: "/self-hosting/operations" },
          { text: "Troubleshooting", link: "/self-hosting/troubleshooting" },
        ],
      },
      {
        text: "Build on Casama",
        collapsed: false,
        items: [
          { text: "Build with AI agents", link: "/develop/agents" },
          { text: "HTTP API", link: "/develop/api" },
          { text: "CLI", link: "/develop/cli" },
          { text: "Dart SDK", link: "/develop/sdk" },
          { text: "TypeScript client", link: "/develop/typescript" },
          { text: "Plugins", link: "/develop/plugins" },
          { text: "Packs", link: "/develop/packs" },
          { text: "Webhooks", link: "/develop/webhooks" },
          { text: "Bot template format", link: "/develop/bot-templates" },
          { text: "Gallery catalog format", link: "/develop/gallery-format" },
          { text: "Routines and skills as files", link: "/develop/workspace-files" },
          { text: "Agent-to-agent (A2A)", link: "/develop/a2a" },
          { text: "How Casama is built", link: "/develop/architecture" },
          { text: "Contribute to Casama", link: "/develop/contributing" },
          { text: "API reference", link: "/api/", target: "_self" },
        ],
      },
    ],
    socialLinks: [
      { icon: "github", link: repo },
      { icon: "discord", link: "https://discord.gg/e86XbXFHwz", ariaLabel: "Casama on Discord" },
      { icon: "x", link: "https://x.com/CasamaAI", ariaLabel: "Casama on X" },
      { icon: "bluesky", link: "https://bsky.app/profile/casama.ai", ariaLabel: "Casama on Bluesky" },
      { icon: "youtube", link: "https://www.youtube.com/@casamaai", ariaLabel: "Casama on YouTube" },
      { icon: "instagram", link: "https://www.instagram.com/casamaai/", ariaLabel: "Casama on Instagram" },
      { icon: "facebook", link: "https://www.facebook.com/casamaai", ariaLabel: "Casama on Facebook" },
    ],
    search: { provider: "local" },
    outline: { level: [2, 3] },
    editLink: {
      pattern: `${repo}/edit/main/docs-site/:path`,
      text: "Suggest a change to this page",
    },
    footer: {
      message:
        'Open source: AGPL-3.0, SDKs and docs Apache-2.0, <code>ee/</code> under the Casama Enterprise License (<a href="https://github.com/stackwares/casama/blob/main/LICENSING.md">licensing</a>). <a href="https://github.com/stackwares/casama/blob/main/CONTRIBUTING.md">Contribute</a> · <a href="https://github.com/sponsors/stackwares">Sponsor</a> · <a href="https://status.casama.ai">Status</a> · <a href="https://casama.ai/newsletter">Monthly email</a>',
    },
  },
});
