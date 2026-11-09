import { defineConfig } from "vitepress";

export default defineConfig({
  title: "Kasama",
  description: "Self-hostable AI teammates with their own computers.",
  cleanUrls: true,
  lastUpdated: true,
  ignoreDeadLinks: [/^\/api\//],
  themeConfig: {
    nav: [
      { text: "Quick start", link: "/quick-start" },
      { text: "Self-hosting", link: "/self-hosting" },
      { text: "Guides", link: "/guide/bots" },
      { text: "API", link: "/api/", target: "_self" },
      { text: "GitHub", link: "https://github.com/stackwares/kasama" },
    ],
    sidebar: [
      {
        text: "Start",
        items: [
          { text: "What is Kasama", link: "/" },
          { text: "Quick start", link: "/quick-start" },
          { text: "Self-hosting", link: "/self-hosting" },
        ],
      },
      {
        text: "Guides",
        items: [
          { text: "Bots and models", link: "/guide/bots" },
          { text: "Computers", link: "/guide/computers" },
          { text: "Autonomy and approvals", link: "/guide/autonomy" },
          { text: "Routines and webhooks", link: "/guide/routines" },
          { text: "Your own computer (companion)", link: "/guide/companion" },
          { text: "Voice", link: "/guide/voice" },
          { text: "MCP server", link: "/guide/mcp" },
          { text: "Cloud Connect", link: "/guide/cloud-connect" },
          { text: "Privacy and data", link: "/guide/privacy" },
        ],
      },
      {
        text: "Reference",
        items: [
          { text: "CLI", link: "/cli" },
          { text: "Dart SDK", link: "/sdk" },
          { text: "HTTP API", link: "/api/", target: "_self" },
        ],
      },
    ],
    search: { provider: "local" },
    editLink: { pattern: "https://github.com/stackwares/kasama/edit/main/docs-site/:path" },
    footer: { message: "Apache-2.0 (ee/ under the Kasama Enterprise License)" },
  },
});
