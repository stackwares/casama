import { defineConfig } from "vitepress";

const repo = "https://github.com/stackwares/kasama";

export default defineConfig({
  title: "Kasama",
  description: "Self-hostable AI teammates with their own computers.",
  cleanUrls: true,
  lastUpdated: true,
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
    ["link", { rel: "icon", href: "/logo.png" }],
    ["meta", { name: "theme-color", content: "#0f6b5c" }],
  ],
  themeConfig: {
    logo: "/logo.png",
    nav: [
      { text: "Get started", link: "/quick-start" },
      { text: "Guides", link: "/guide/bots" },
      { text: "Self-hosting", link: "/self-hosting/" },
      { text: "Build on Kasama", link: "/develop/api" },
      { text: "API", link: "/api/", target: "_self" },
    ],
    sidebar: [
      {
        text: "Get started",
        items: [
          { text: "What is Kasama", link: "/introduction" },
          { text: "Quick start", link: "/quick-start" },
          { text: "FAQ", link: "/faq" },
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
          { text: "Bots working together", link: "/guide/bots-together" },
        ],
      },
      {
        text: "Chat",
        collapsed: false,
        items: [
          { text: "Chatting with a bot", link: "/guide/chat" },
          { text: "Group chats", link: "/guide/group-chats" },
          { text: "Pages", link: "/guide/pages" },
          { text: "Voice and calls", link: "/guide/voice" },
          { text: "Chat apps", link: "/guide/chat-apps" },
        ],
      },
      {
        text: "Getting work done",
        collapsed: false,
        items: [
          { text: "Computers", link: "/guide/computers" },
          { text: "Your own computer", link: "/guide/companion" },
          { text: "Coding agents", link: "/guide/coding-agents" },
          { text: "Teach by showing", link: "/guide/teach" },
          { text: "Routines and triggers", link: "/guide/routines" },
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
          { text: "Computer providers", link: "/self-hosting/computers" },
          { text: "Operations", link: "/self-hosting/operations" },
          { text: "Cloud Connect", link: "/guide/cloud-connect" },
          { text: "Troubleshooting", link: "/self-hosting/troubleshooting" },
        ],
      },
      {
        text: "Build on Kasama",
        collapsed: false,
        items: [
          { text: "HTTP API", link: "/develop/api" },
          { text: "CLI", link: "/develop/cli" },
          { text: "Dart SDK", link: "/develop/sdk" },
          { text: "Plugins", link: "/develop/plugins" },
          { text: "Webhooks", link: "/develop/webhooks" },
          { text: "Bot template format", link: "/develop/bot-templates" },
          { text: "Routines and skills as files", link: "/develop/workspace-files" },
          { text: "Agent-to-agent (A2A)", link: "/develop/a2a" },
          { text: "API reference", link: "/api/", target: "_self" },
        ],
      },
    ],
    socialLinks: [{ icon: "github", link: repo }],
    search: { provider: "local" },
    outline: { level: [2, 3] },
    editLink: {
      pattern: `${repo}/edit/main/docs-site/:path`,
      text: "Suggest a change to this page",
    },
    footer: {
      message:
        'Apache-2.0, except <code>ee/</code> (Kasama Enterprise License). <a href="https://github.com/stackwares/kasama/blob/main/CONTRIBUTING.md">Contribute</a>',
    },
  },
});
