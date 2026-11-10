/**
 * Built-in app connections (D-089). Each app is the vendor's own hosted MCP server, connected with
 * one click through OAuth (MCP authorization: discovery, then dynamic client registration, a
 * client metadata document, or a client the server admin registered; always with PKCE) or with an
 * API key. No Composio or Pipedream needed. Endpoints checked against vendor docs on 2026-11-10.
 */
export type AppCategory =
  | "developer"
  | "productivity"
  | "google"
  | "payments"
  | "design"
  | "sales"
  | "data"
  | "automation";

/** managed: a sign-in run by a provider Kasama Cloud uses (Composio), for access its own app lacks. */
export type AppAuth = "oauth" | "api_key" | "none" | "managed";

export interface AppApiKeyHelp {
  /** Field label, e.g. "Secret key" or "Personal access token". */
  label: string;
  placeholder?: string;
  /** Where to create it (opened from the connect sheet). */
  url: string;
  /** Short steps, one per line. */
  steps: string[];
  /** Header the key goes in (Authorization: Bearer by default). */
  header?: string;
}

export interface CatalogApp {
  id: string;
  name: string;
  description: string;
  category: AppCategory;
  /** Brand color (hex, no #) for the logo tile. */
  color: string;
  homepage: string;
  /** The vendor's MCP endpoint (Streamable HTTP; a path ending in /sse means legacy SSE). */
  url: string;
  /** Ways to connect, best first. */
  auth: AppAuth[];
  apiKey?: AppApiKeyHelp;
  /**
   * How Kasama gets an OAuth client: "dcr" registers itself automatically; "cimd" uses Kasama's
   * client metadata document (needs a public https API); "preregistered" needs a client the server
   * admin created with the vendor (MCP_OAUTH_CLIENTS, or GOOGLE_OAUTH_CLIENT_ID for Google).
   */
  oauthClient?: "dcr" | "cimd" | "preregistered";
  /** Scopes to ask for when the server doesn't announce them. */
  scopes?: string[];
  /** Shown on the connect sheet, e.g. a preview or approval caveat. */
  note?: string;
  /** What a bot can do with it, as short phrases for the connect sheet. */
  capabilities: string[];
  popular?: boolean;
  /**
   * Reads the inbox (a restricted Google scope, D-130). Kasama Cloud offers it only through
   * Composio's managed sign-in until Google's restricted-scope review passes.
   */
  inbox?: boolean;
}

export const APP_CATALOG: CatalogApp[] = [
  // ------------------------------------------------------------ developer
  {
    id: "github",
    name: "GitHub",
    description: "Repositories, issues, pull requests and code search.",
    category: "developer",
    color: "181717",
    homepage: "https://github.com",
    url: "https://api.githubcopilot.com/mcp/",
    auth: ["api_key", "oauth"],
    oauthClient: "preregistered",
    apiKey: {
      label: "Personal access token",
      placeholder: "github_pat_…",
      url: "https://github.com/settings/personal-access-tokens/new",
      steps: [
        "Open GitHub → Settings → Developer settings → Fine-grained tokens.",
        "Choose the repositories the bot may use and the permissions it needs.",
        "Generate the token and paste it here.",
      ],
    },
    capabilities: [
      "Read and search code",
      "Open and review pull requests",
      "Create and triage issues",
    ],
    popular: true,
  },
  {
    id: "sentry",
    name: "Sentry",
    description: "Errors, issues and performance data from your apps.",
    category: "developer",
    color: "362D59",
    homepage: "https://sentry.io",
    url: "https://mcp.sentry.dev/mcp",
    auth: ["oauth"],
    oauthClient: "dcr",
    capabilities: [
      "Find and explain errors",
      "Look up issue details and stack traces",
      "Search events",
    ],
    popular: true,
  },
  {
    id: "linear",
    name: "Linear",
    description: "Issues, projects and cycles for your team.",
    category: "developer",
    color: "5E6AD2",
    homepage: "https://linear.app",
    url: "https://mcp.linear.app/mcp",
    auth: ["oauth", "api_key"],
    oauthClient: "dcr",
    apiKey: {
      label: "API key",
      placeholder: "lin_api_…",
      url: "https://linear.app/settings/account/security",
      steps: [
        "Open Linear → Settings → Security & access.",
        "Create a personal API key and paste it here.",
      ],
    },
    capabilities: ["Create and update issues", "Search projects and cycles", "Add comments"],
    popular: true,
  },
  {
    id: "vercel",
    name: "Vercel",
    description: "Projects, deployments and build logs.",
    category: "developer",
    color: "000000",
    homepage: "https://vercel.com",
    url: "https://mcp.vercel.com",
    auth: ["oauth"],
    oauthClient: "cimd",
    note: "Vercel only accepts apps with a public web address, so this works on hosted Kasama servers.",
    capabilities: ["Check deployments", "Read build logs", "Search Vercel docs"],
  },
  {
    id: "supabase",
    name: "Supabase",
    description: "Databases, tables, SQL and project settings.",
    category: "developer",
    color: "3FCF8E",
    homepage: "https://supabase.com",
    url: "https://mcp.supabase.com/mcp",
    auth: ["oauth", "api_key"],
    oauthClient: "dcr",
    apiKey: {
      label: "Access token",
      placeholder: "sbp_…",
      url: "https://supabase.com/dashboard/account/tokens",
      steps: ["Open Supabase → Account → Access tokens.", "Generate a token and paste it here."],
    },
    capabilities: ["Query and inspect tables", "Manage migrations", "Read logs"],
  },
  {
    id: "neon",
    name: "Neon",
    description: "Serverless Postgres projects, branches and queries.",
    category: "developer",
    color: "00E599",
    homepage: "https://neon.tech",
    url: "https://mcp.neon.tech/mcp",
    auth: ["oauth", "api_key"],
    oauthClient: "dcr",
    apiKey: {
      label: "API key",
      placeholder: "napi_…",
      url: "https://console.neon.tech/app/settings/api-keys",
      steps: [
        "Open the Neon console → Account settings → API keys.",
        "Create a key and paste it here.",
      ],
    },
    capabilities: ["Run SQL", "Create branches", "Manage projects"],
  },
  {
    id: "cloudflare",
    name: "Cloudflare Docs",
    description: "Up-to-date Cloudflare documentation.",
    category: "developer",
    color: "F38020",
    homepage: "https://developers.cloudflare.com",
    url: "https://docs.mcp.cloudflare.com/mcp",
    auth: ["none"],
    capabilities: ["Search Cloudflare docs"],
  },
  {
    id: "posthog",
    name: "PostHog",
    description: "Product analytics, feature flags and experiments.",
    category: "data",
    color: "F54E00",
    homepage: "https://posthog.com",
    url: "https://mcp.posthog.com/mcp",
    auth: ["oauth", "api_key"],
    oauthClient: "dcr",
    apiKey: {
      label: "Personal API key",
      placeholder: "phx_…",
      url: "https://app.posthog.com/settings/user-api-keys?preset=mcp_server",
      steps: [
        "Open PostHog → Settings → Personal API keys.",
        "Create a key with the MCP Server preset and paste it here.",
      ],
    },
    capabilities: ["Query insights and trends", "Manage feature flags", "Look up errors"],
  },
  {
    id: "huggingface",
    name: "Hugging Face",
    description: "Models, datasets, Spaces and papers.",
    category: "data",
    color: "FFD21E",
    homepage: "https://huggingface.co",
    url: "https://huggingface.co/mcp",
    auth: ["none", "api_key"],
    apiKey: {
      label: "Access token (optional, unlocks more tools)",
      placeholder: "hf_…",
      url: "https://huggingface.co/settings/tokens",
      steps: [
        "Open Hugging Face → Settings → Access tokens.",
        "Create a read token and paste it here.",
      ],
    },
    capabilities: ["Search models and datasets", "Find papers", "Use Spaces"],
  },
  {
    id: "context7",
    name: "Context7",
    description: "Current docs and code examples for thousands of libraries.",
    category: "developer",
    color: "059669",
    homepage: "https://context7.com",
    url: "https://mcp.context7.com/mcp",
    auth: ["none", "api_key"],
    apiKey: {
      label: "API key (optional, raises limits)",
      placeholder: "ctx7sk-…",
      url: "https://context7.com/dashboard?tab=settings",
      steps: ["Open the Context7 dashboard → Settings.", "Create an API key and paste it here."],
    },
    capabilities: ["Look up library docs", "Get code examples"],
  },
  // --------------------------------------------------------- productivity
  {
    id: "notion",
    name: "Notion",
    description: "Pages, databases and docs in your workspace.",
    category: "productivity",
    color: "000000",
    homepage: "https://notion.so",
    url: "https://mcp.notion.com/mcp",
    auth: ["oauth"],
    oauthClient: "dcr",
    capabilities: ["Search and read pages", "Create and update pages", "Query databases"],
    popular: true,
  },
  {
    id: "atlassian",
    name: "Jira & Confluence",
    description: "Atlassian issues, boards and wiki pages.",
    category: "productivity",
    color: "0052CC",
    homepage: "https://www.atlassian.com",
    url: "https://mcp.atlassian.com/v2/mcp",
    auth: ["oauth"],
    oauthClient: "dcr",
    capabilities: ["Create and update Jira issues", "Search Confluence", "Summarise pages"],
    popular: true,
  },
  {
    id: "asana",
    name: "Asana",
    description: "Tasks, projects and goals.",
    category: "productivity",
    color: "F06A6A",
    homepage: "https://asana.com",
    url: "https://mcp.asana.com/v2/mcp",
    auth: ["oauth"],
    oauthClient: "preregistered",
    note: "Asana needs an app your server admin registers with Asana (client ID and secret).",
    capabilities: ["Create and assign tasks", "Track projects", "Search work"],
  },
  {
    id: "monday",
    name: "monday.com",
    description: "Boards, items and updates.",
    category: "productivity",
    color: "FF3D57",
    homepage: "https://monday.com",
    url: "https://mcp.monday.com/mcp",
    auth: ["oauth", "api_key"],
    oauthClient: "dcr",
    apiKey: {
      label: "Personal API token",
      url: "https://monday.com",
      steps: [
        "In monday.com, open your avatar → Developers → My access tokens.",
        "Copy the token and paste it here.",
      ],
    },
    note: "A monday.com admin may need to approve Kasama the first time.",
    capabilities: ["Create and update items", "Read boards", "Post updates"],
  },
  {
    id: "box",
    name: "Box",
    description: "Files and folders in Box.",
    category: "productivity",
    color: "0061D5",
    homepage: "https://box.com",
    url: "https://mcp.box.com",
    auth: ["oauth"],
    oauthClient: "preregistered",
    capabilities: ["Search files", "Read documents", "Ask questions about files"],
  },
  // --------------------------------------------------------------- google
  {
    id: "gmail",
    name: "Gmail",
    description: "Send email from your address. Reading your inbox is a separate step.",
    category: "google",
    color: "EA4335",
    homepage: "https://mail.google.com",
    url: "https://gmailmcp.googleapis.com/mcp/v1",
    auth: ["oauth"],
    oauthClient: "preregistered",
    note: "Google's MCP servers are in Developer Preview.",
    scopes: ["https://www.googleapis.com/auth/gmail.send"],
    capabilities: ["Send email (asks first)"],
    popular: true,
  },
  {
    id: "gmail_inbox",
    name: "Gmail inbox",
    description: "Search and read your email, and draft replies.",
    category: "google",
    color: "EA4335",
    homepage: "https://mail.google.com",
    url: "https://gmailmcp.googleapis.com/mcp/v1",
    auth: ["oauth"],
    oauthClient: "preregistered",
    note: "Turn this on only for inbox features: catch-ups, triage, replies.",
    scopes: ["https://www.googleapis.com/auth/gmail.modify"],
    capabilities: ["Search and read email", "Draft replies", "Label and archive"],
    inbox: true,
  },
  {
    id: "google_calendar",
    name: "Google Calendar",
    description: "Events, availability and invites.",
    category: "google",
    color: "4285F4",
    homepage: "https://calendar.google.com",
    url: "https://calendarmcp.googleapis.com/mcp/v1",
    auth: ["oauth"],
    oauthClient: "preregistered",
    note: "Google's MCP servers are in Developer Preview.",
    scopes: ["https://www.googleapis.com/auth/calendar.events"],
    capabilities: ["See your schedule", "Create and move events", "Find free time"],
    popular: true,
  },
  {
    id: "google_drive",
    name: "Google Drive",
    description: "Docs, Sheets and files in Drive.",
    category: "google",
    color: "1FA463",
    homepage: "https://drive.google.com",
    url: "https://drivemcp.googleapis.com/mcp/v1",
    auth: ["oauth"],
    oauthClient: "preregistered",
    note: "Google's MCP servers are in Developer Preview.",
    scopes: ["https://www.googleapis.com/auth/drive.file"],
    capabilities: ["Files you pick or that it creates", "Read and write those Docs and Sheets"],
  },
  // ------------------------------------------------------------- payments
  {
    id: "stripe",
    name: "Stripe",
    description: "Customers, payments, invoices and subscriptions.",
    category: "payments",
    color: "635BFF",
    homepage: "https://stripe.com",
    url: "https://mcp.stripe.com",
    auth: ["oauth", "api_key"],
    oauthClient: "dcr",
    apiKey: {
      label: "Agent API key",
      url: "https://dashboard.stripe.com/apikeys",
      steps: [
        "Open Stripe → Developers → API keys.",
        "Create an agent key with only the permissions the bot needs.",
        "Paste it here. A test-mode key lets you try things safely.",
      ],
    },
    capabilities: [
      "Look up customers and payments",
      "Create invoices and payment links",
      "Search Stripe docs",
    ],
    popular: true,
  },
  // --------------------------------------------------------------- design
  {
    id: "figma",
    name: "Figma",
    description: "Designs, components and variables.",
    category: "design",
    color: "F24E1E",
    homepage: "https://figma.com",
    url: "https://mcp.figma.com/mcp",
    auth: ["oauth"],
    oauthClient: "preregistered",
    note: "Figma only lets approved apps connect. It works once your server has a Figma-approved client.",
    capabilities: ["Read frames and components", "Turn designs into code", "Look up variables"],
    popular: true,
  },
  {
    id: "webflow",
    name: "Webflow",
    description: "Sites, CMS collections and pages.",
    category: "design",
    color: "146EF5",
    homepage: "https://webflow.com",
    url: "https://mcp.webflow.com/mcp",
    auth: ["oauth"],
    oauthClient: "dcr",
    capabilities: ["Update CMS items", "Publish sites", "Read pages"],
  },
  {
    id: "slack",
    name: "Slack",
    description: "Channels, messages and people in your workspace.",
    category: "productivity",
    color: "4A154B",
    homepage: "https://slack.com",
    url: "https://mcp.slack.com/mcp",
    auth: ["oauth"],
    oauthClient: "preregistered",
    note: "Slack needs a Slack app your server admin creates (client ID and secret).",
    capabilities: ["Search messages", "Read channels", "Post messages (asks first)"],
    popular: true,
  },
  {
    id: "airtable",
    name: "Airtable",
    description: "Bases, tables and records.",
    category: "data",
    color: "18BFFF",
    homepage: "https://airtable.com",
    url: "https://mcp.airtable.com/mcp",
    auth: ["oauth", "api_key"],
    oauthClient: "dcr",
    apiKey: {
      label: "Personal access token",
      placeholder: "pat…",
      url: "https://airtable.com/create/tokens/new",
      steps: [
        "Open Airtable → Builder hub → Personal access tokens.",
        "Create a token for the bases the bot may use and paste it here.",
      ],
    },
    capabilities: ["Read and search records", "Create and update records", "List bases and tables"],
  },
  {
    id: "zapier",
    name: "Zapier",
    description: "Thousands of apps through your Zapier actions.",
    category: "automation",
    color: "FF4F00",
    homepage: "https://zapier.com",
    url: "https://mcp.zapier.com/api/v1/connect",
    auth: ["oauth", "api_key"],
    oauthClient: "dcr",
    apiKey: {
      label: "MCP connection token",
      url: "https://mcp.zapier.com",
      steps: [
        "Open mcp.zapier.com and create an MCP server.",
        "Add the actions the bot may use, copy the token (shown once) and paste it here.",
      ],
    },
    capabilities: ["Run the Zapier actions you allow", "Reach 8,000+ apps"],
    popular: true,
  },
  {
    id: "exa",
    name: "Exa",
    description: "Web search built for AI, with full page contents.",
    category: "data",
    color: "1F40ED",
    homepage: "https://exa.ai",
    url: "https://mcp.exa.ai/mcp",
    auth: ["none", "api_key"],
    apiKey: {
      label: "API key (optional, raises limits)",
      url: "https://dashboard.exa.ai/api-keys",
      steps: ["Open the Exa dashboard → API keys.", "Create a key and paste it here."],
      header: "x-api-key",
    },
    capabilities: ["Search the web", "Read pages", "Find companies and people"],
  },
  // ---------------------------------------------------------------- sales
  {
    id: "hubspot",
    name: "HubSpot",
    description: "Contacts, companies, deals and tickets.",
    category: "sales",
    color: "FF7A59",
    homepage: "https://hubspot.com",
    url: "https://mcp.hubspot.com",
    auth: ["oauth"],
    oauthClient: "preregistered",
    capabilities: ["Look up contacts and deals", "Log activity", "Update records"],
  },
  {
    id: "intercom",
    name: "Intercom",
    description: "Conversations, contacts and help articles.",
    category: "sales",
    color: "1F8DED",
    homepage: "https://intercom.com",
    url: "https://mcp.intercom.com/mcp",
    auth: ["oauth", "api_key"],
    oauthClient: "dcr",
    apiKey: {
      label: "Access token",
      url: "https://app.intercom.com/a/apps/_/developer-hub",
      steps: [
        "Open Intercom → Developer Hub → your app → Authentication.",
        "Copy the access token and paste it here.",
      ],
    },
    capabilities: ["Search conversations", "Look up contacts", "Find help articles"],
  },
];

export const appByIdOrNull = (id: string) => APP_CATALOG.find((a) => a.id === id) ?? null;

export const appById = (id: string) => APP_CATALOG.find((a) => a.id === id);
