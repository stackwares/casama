// SPDX-License-Identifier: Apache-2.0
// A shared format, also used by the Apache-2.0 SDKs and tools (LICENSING.md).
/**
 * Built-in app connections (D-089). Each app is the vendor's own hosted MCP server, connected with
 * one click through OAuth (MCP authorization: discovery, then dynamic client registration, a
 * client metadata document, or a client the server admin registered; always with PKCE) or with an
 * API key. No Composio or Pipedream needed. Endpoints checked against vendor docs on 2026-11-11.
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

/** managed: a sign-in run by a provider Casama Cloud uses (Composio), for access its own app lacks. */
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
  /**
   * The pasted value is the person's own MCP server URL with its key in it (Zoho MCP), not a key.
   * Casama connects to that URL, keeps it as the connection's secret (never in its config, which
   * members can read), and only accepts https URLs whose host is one of these or ends in `.<host>`.
   */
  serverUrl?: { hosts: string[] };
}

/** The pasted server URL if it's https on one of the app's hosts, else null. */
export function appServerUrl(value: string, hosts: string[]): URL | null {
  let u: URL;
  try {
    u = new URL(value.trim());
  } catch {
    return null;
  }
  const local = u.hostname === "127.0.0.1" || u.hostname === "localhost";
  if (u.protocol !== "https:" && !(local && u.protocol === "http:")) return null;
  if (u.username || u.password) return null;
  const host = u.hostname.toLowerCase();
  return hosts.some((h) => host === h || host.endsWith(`.${h}`)) ? u : null;
}

/** The app id kept on a sign-in for a server that isn't in the catalog (D-473). */
export const CUSTOM_APP = "custom";
/** How many servers bots may bring into one workspace from chats (D-473). */
export const CHAT_SERVER_LIMIT = 25;

/**
 * The address of an MCP server outside the catalog (D-473), or null: https only (http on this
 * machine, for tests and local development) and no user or password in it.
 */
export function customServerUrl(value: string): URL | null {
  let u: URL;
  try {
    u = new URL(value.trim());
  } catch {
    return null;
  }
  const local = u.hostname === "127.0.0.1" || u.hostname === "localhost";
  if (u.protocol !== "https:" && !(local && u.protocol === "http:")) return null;
  if (u.username || u.password || !u.hostname) return null;
  u.hash = "";
  return u;
}

/** Two addresses of the same server: host and path, whatever the case or a closing slash. */
export const serverKey = (u: URL) =>
  `${u.host.toLowerCase()}${u.pathname.replace(/\/+$/, "")}`.toLowerCase();

/** A connection name made from what people call the server: "Acme CRM" is acme_crm. */
export function serverSlug(label: string): string {
  const s = label
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "")
    .slice(0, 30);
  return /^[a-z]/.test(s) ? s : `server_${s}`.replace(/_+$/, "").slice(0, 30);
}

/** Zoho's data centres: each serves MCP servers on its own zohomcp domain. */
const ZOHO_MCP_HOSTS = [
  "zohomcp.com",
  "zohomcp.eu",
  "zohomcp.in",
  "zohomcp.com.au",
  "zohomcp.jp",
  "zohomcp.ca",
  "zohomcp.sa",
  "zohomcp.uk",
  "zohomcp.com.cn",
];

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
   * How Casama gets an OAuth client: "dcr" registers itself automatically; "cimd" uses Casama's
   * client metadata document (needs a public https API); "preregistered" needs a client the server
   * admin created with the vendor (MCP_OAUTH_CLIENTS, or GOOGLE_OAUTH_CLIENT_ID for Google).
   */
  oauthClient?: "dcr" | "cimd" | "preregistered";
  /**
   * Scopes to ask for, used instead of what the server announces; an empty list sends none
   * (Asana rejects any). Unset: whatever the server announces.
   */
  scopes?: string[];
  /** Shown on the connect sheet, e.g. a preview or approval caveat. */
  note?: string;
  /** What a bot can do with it, as short phrases for the connect sheet. */
  capabilities: string[];
  popular?: boolean;
  /**
   * Composio's name for the app (its toolkit slug). With a Composio key on the server, apps whose
   * own sign-in isn't set up connect through Composio's sign-in on that account (D-172).
   */
  composio?: string;
  /**
   * Reads the inbox (a restricted Google scope, D-130). Casama Cloud offers it only through
   * Composio's managed sign-in until Google's restricted-scope review passes.
   */
  inbox?: boolean;
  /** Casama signs in and calls the vendor's own API itself (Zoho, D-350), not an MCP server. */
  provider?: "zoho";
  /** Offered only when this server has the app's OAuth client (no fallback worth showing). */
  hiddenWithoutClient?: boolean;
  /** Not offered when this other app's own sign-in is set up (it covers this one). */
  replacedBy?: string;
}

export const APP_CATALOG: CatalogApp[] = [
  // ---------------------------------------------------------------- google
  // Google's own MCP servers (Developer Preview), one per product, all signed in with the server's
  // Google client (GOOGLE_OAUTH_CLIENT_ID). Scopes are Casama's choice, never the full list a
  // server announces (Gmail's includes full mailbox access).
  {
    id: "gmail",
    composio: "gmail",
    name: "Gmail",
    description: "Search and read your email, draft replies, and label threads.",
    category: "google",
    color: "EA4335",
    homepage: "https://mail.google.com",
    url: "https://gmailmcp.googleapis.com/mcp/v1",
    auth: ["oauth"],
    oauthClient: "preregistered",
    note: "Drafts only: you send them from Gmail. Google's MCP servers are in Developer Preview.",
    scopes: [
      "https://www.googleapis.com/auth/gmail.modify",
      "https://www.googleapis.com/auth/gmail.compose",
    ],
    capabilities: ["Search and read email", "Draft replies", "Label threads"],
    inbox: true,
    popular: true,
  },
  {
    id: "google_calendar",
    composio: "googlecalendar",
    name: "Google Calendar",
    description: "Events, availability and invites.",
    category: "google",
    color: "4285F4",
    homepage: "https://calendar.google.com",
    url: "https://calendarmcp.googleapis.com/mcp/v1",
    auth: ["oauth"],
    oauthClient: "preregistered",
    note: "Google's MCP servers are in Developer Preview.",
    scopes: [
      "https://www.googleapis.com/auth/calendar.calendarlist.readonly",
      "https://www.googleapis.com/auth/calendar.events",
      "https://www.googleapis.com/auth/calendar.events.freebusy",
    ],
    capabilities: [
      "See your schedule",
      "Create and move events",
      "Find free time",
      "Answer invites",
    ],
    popular: true,
  },
  {
    id: "google_drive",
    composio: "googledrive",
    name: "Google Drive",
    description: "Files in Drive that you pick or that it creates.",
    category: "google",
    color: "1FA463",
    homepage: "https://drive.google.com",
    url: "https://drivemcp.googleapis.com/mcp/v1",
    auth: ["oauth"],
    oauthClient: "preregistered",
    note: "Google's MCP servers are in Developer Preview.",
    scopes: ["https://www.googleapis.com/auth/drive.file"],
    capabilities: ["Create and copy files", "Read files it has access to"],
    popular: true,
  },
  {
    id: "google_docs",
    composio: "googledocs",
    name: "Google Docs",
    description: "Read and edit your documents.",
    category: "google",
    color: "4285F4",
    homepage: "https://docs.google.com/document",
    url: "https://docsmcp.googleapis.com/mcp/v1",
    auth: ["oauth"],
    oauthClient: "preregistered",
    note: "Google's MCP servers are in Developer Preview.",
    scopes: ["https://www.googleapis.com/auth/documents"],
    capabilities: ["Read documents", "Write and edit documents"],
    popular: true,
  },
  {
    id: "google_sheets",
    composio: "googlesheets",
    name: "Google Sheets",
    description: "Read and update your spreadsheets.",
    category: "google",
    color: "0F9D58",
    homepage: "https://docs.google.com/spreadsheets",
    url: "https://sheetsmcp.googleapis.com/mcp/v1",
    auth: ["oauth"],
    oauthClient: "preregistered",
    note: "Google's MCP servers are in Developer Preview.",
    scopes: ["https://www.googleapis.com/auth/spreadsheets"],
    capabilities: ["Read cells and sheets", "Update values and formulas", "Add rows and columns"],
    popular: true,
  },
  {
    id: "google_contacts",
    composio: "googlecontacts",
    name: "Google Contacts",
    description: "Look up people in your contacts and your organization's directory.",
    category: "google",
    color: "1A73E8",
    homepage: "https://contacts.google.com",
    url: "https://people.googleapis.com/mcp/v1",
    auth: ["oauth"],
    oauthClient: "preregistered",
    note: "Google's MCP servers are in Developer Preview.",
    scopes: [
      "https://www.googleapis.com/auth/contacts.readonly",
      "https://www.googleapis.com/auth/directory.readonly",
      "https://www.googleapis.com/auth/userinfo.profile",
    ],
    capabilities: ["Search contacts", "Search your organization's directory"],
  },
  {
    id: "google_slides",
    composio: "googleslides",
    name: "Google Slides",
    description: "Read and edit your presentations.",
    category: "google",
    color: "F4B400",
    homepage: "https://docs.google.com/presentation",
    url: "https://slidesmcp.googleapis.com/mcp/v1",
    auth: ["oauth"],
    oauthClient: "preregistered",
    note: "Google's MCP servers are in Developer Preview.",
    scopes: ["https://www.googleapis.com/auth/presentations"],
    capabilities: ["Read presentations", "Edit slides"],
  },
  // ---------------------------------------------------------- productivity
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
    id: "slack",
    composio: "slack",
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
    id: "asana",
    composio: "asana",
    name: "Asana",
    description: "Tasks, projects and goals.",
    category: "productivity",
    color: "F06A6A",
    homepage: "https://asana.com",
    url: "https://mcp.asana.com/v2/mcp",
    auth: ["oauth"],
    oauthClient: "preregistered",
    scopes: [], // Asana's MCP apps take no scope parameter.
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
    note: "A monday.com admin may need to approve Casama the first time.",
    capabilities: ["Create and update items", "Read boards", "Post updates"],
  },
  {
    id: "box",
    composio: "box",
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
  },
  // --------------------------------------------------------- data & search
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
    // Its OAuth sign-in only accepts clients on TrustMRR's own list (ChatGPT): Casama's client
    // metadata document gets "not from a supported client" (checked 2026-11-18). Public tools work
    // without a key; an API key unlocks search and startup details.
    id: "trustmrr",
    name: "TrustMRR",
    description: "Startups with verified revenue, and startups for sale.",
    category: "data",
    color: "5468FF",
    homepage: "https://trustmrr.com",
    url: "https://trustmrr.com/api/mcp",
    auth: ["none", "api_key"],
    apiKey: {
      label: "API key (optional, unlocks search and details)",
      placeholder: "tmrr_…",
      url: "https://trustmrr.com/dashboard-dev",
      steps: ["Open TrustMRR → Developer dashboard.", "Create an API key and paste it here."],
    },
    capabilities: [
      "Find fast-growing startups",
      "Look up a startup's verified revenue",
      "Browse startups for sale",
    ],
  },
  // ------------------------------------------------------------ automation
  // Hubs: one sign-in reaches many apps, and each app is connected inside the hub. Also the way in
  // for apps whose own sign-in needs a client this server doesn't have (see HUB_APPS).
  {
    id: "zapier",
    name: "Zapier",
    description: "Thousands of apps through your Zapier actions.",
    category: "automation",
    color: "FF4F00",
    homepage: "https://zapier.com",
    url: "https://mcp.zapier.com/api/v1/link",
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
    id: "composio",
    name: "Composio",
    description: "1,000+ apps, each signed in through Composio when the bot first needs it.",
    category: "automation",
    color: "1FA2FF",
    homepage: "https://composio.dev",
    url: "https://connect.composio.dev/mcp",
    auth: ["oauth"],
    oauthClient: "dcr",
    note: "Sign in with your Composio account. A Composio API key also works, under More ways to connect.",
    capabilities: [
      "Gmail, Slack, HubSpot, Salesforce and 1,000+ more",
      "Connects each app when it's first used",
    ],
  },
  {
    id: "pipedream",
    name: "Pipedream",
    description: "2,800+ apps through Pipedream, signed in with your Pipedream account.",
    category: "automation",
    color: "34D28B",
    homepage: "https://pipedream.com",
    url: "https://remote.mcp.pipedream.net",
    auth: ["oauth"],
    oauthClient: "dcr",
    note: "Pipedream's MCP server is in beta. A Pipedream Connect project also works, under More ways to connect.",
    capabilities: ["2,800+ apps and their actions", "Connects each app when it's first used"],
  },
  {
    // Zoho MCP (mcp.zoho.com): the person builds their own server from Zoho Mail, CRM, Desk,
    // Projects, Books, Cliq and more, and Zoho gives it a URL with an API key in it. Free with a
    // Zoho account. Zoho asks the person to sign in to each app the first time a tool needs it.
    id: "zoho",
    name: "Zoho MCP",
    description: "Any Zoho app through your own Zoho MCP server.",
    category: "productivity",
    color: "E42527",
    homepage: "https://www.zoho.com/mcp/",
    url: "https://mcp.zoho.com",
    auth: ["api_key"],
    apiKey: {
      label: "MCP server URL",
      placeholder: "https://…zohomcp.com/mcp/…/message",
      url: "https://mcp.zoho.com",
      steps: [
        "Open mcp.zoho.com and create an MCP server (or pick a pre-configured one).",
        "Add the Zoho tools the bot may use: Mail, CRM, Desk, Projects…",
        "Open Connect, copy the MCP URL and paste it here. Treat it like a password.",
      ],
      serverUrl: { hosts: ZOHO_MCP_HOSTS },
    },
    note: "The first time a bot uses a Zoho tool, Zoho may reply with a link to sign in to that app.",
    capabilities: [
      "Read, send and organise Zoho Mail",
      "Work with Zoho CRM, Desk, Projects and Books",
      "Only the tools you add to your server",
    ],
  },
  {
    // Casama's own Zoho sign-in (D-350): one sign-in covers Mail, CRM, Desk and Books, and Casama
    // calls Zoho's APIs itself with a small set of tools for the apps the account has. Needs the
    // server's Zoho client (ZOHO_OAUTH_CLIENT_ID); where it's set, the Composio tiles below hide.
    id: "zoho_apps",
    provider: "zoho",
    name: "Zoho",
    description: "Zoho Mail, CRM, Desk and Books with one sign-in.",
    category: "productivity",
    color: "E42527",
    homepage: "https://www.zoho.com/",
    url: "https://accounts.zoho.com",
    auth: ["oauth"],
    oauthClient: "preregistered",
    hiddenWithoutClient: true,
    popular: true,
    note: "Bots get tools for the Zoho apps your account has. Sending email, replying to customers and sending invoices always ask you first.",
    capabilities: [
      "Find, read, send and file Zoho Mail",
      "Search and update Zoho CRM records",
      "Work Zoho Desk tickets",
      "Zoho Books invoices, bills and customers",
    ],
  },
  // Zoho's apps one by one, signed in through Composio's managed sign-in (D-349): Zoho has no
  // MCP sign-in an app can register with, so until Casama runs its own Zoho server these are
  // offered only where the server has Composio (Casama Cloud does). `url` is Zoho's site: a
  // managed connection never calls it.
  {
    id: "zoho_mail",
    replacedBy: "zoho_apps",
    composio: "zoho_mail",
    name: "Zoho Mail",
    description: "Read, send and organise your Zoho Mail.",
    category: "productivity",
    color: "E42527",
    homepage: "https://www.zoho.com/mail/",
    url: "https://www.zoho.com/mail/",
    auth: ["managed"],
    capabilities: ["Find and read email", "Send and reply", "Folders, labels and flags"],
  },
  {
    id: "zoho_crm",
    replacedBy: "zoho_apps",
    composio: "zoho",
    name: "Zoho CRM",
    description: "Leads, contacts, deals and accounts in Zoho CRM.",
    category: "sales",
    color: "E42527",
    homepage: "https://www.zoho.com/crm/",
    url: "https://www.zoho.com/crm/",
    auth: ["managed"],
    capabilities: ["Find and update leads and contacts", "Track deals", "Add notes and tasks"],
  },
  {
    id: "zoho_desk",
    replacedBy: "zoho_apps",
    composio: "zoho_desk",
    name: "Zoho Desk",
    description: "Support tickets and customers in Zoho Desk.",
    category: "sales",
    color: "E42527",
    homepage: "https://www.zoho.com/desk/",
    url: "https://www.zoho.com/desk/",
    auth: ["managed"],
    capabilities: ["Read and answer tickets", "Look up contacts", "Update ticket status"],
  },
  {
    id: "zoho_books",
    replacedBy: "zoho_apps",
    composio: "zoho_books",
    name: "Zoho Books",
    description: "Invoices, bills, expenses and customers in Zoho Books.",
    category: "payments",
    color: "E42527",
    homepage: "https://www.zoho.com/books/",
    url: "https://www.zoho.com/books/",
    auth: ["managed"],
    capabilities: ["Create and send invoices", "Record expenses and bills", "Check what's owed"],
  },
  // ---------------------------------------------------------------- design
  {
    id: "figma",
    composio: "figma",
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
  // ----------------------------------------------------------------- sales
  {
    id: "hubspot",
    composio: "hubspot",
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
  // -------------------------------------------------------------- payments
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
  },
  {
    id: "revenuecat",
    name: "RevenueCat",
    description: "In-app subscriptions: customers, revenue, products, offerings and paywalls.",
    category: "payments",
    color: "F2545B",
    homepage: "https://www.revenuecat.com",
    url: "https://mcp.revenuecat.ai/mcp",
    auth: ["oauth", "api_key"],
    oauthClient: "dcr",
    apiKey: {
      label: "API v2 secret key",
      placeholder: "sk_…",
      url: "https://app.revenuecat.com",
      steps: [
        "Open your RevenueCat project → API keys.",
        "Create a new API v2 secret key just for Casama. Read-only is enough to look things up; give it write access only if the bot should change things.",
        "Paste it here.",
      ],
    },
    capabilities: [
      "Check revenue, MRR and charts",
      "Look up customers and subscriptions",
      "Manage products, offerings and paywalls",
    ],
  },
  {
    id: "superwall",
    name: "Superwall",
    description: "Paywalls, campaigns, products and subscription analytics.",
    category: "payments",
    color: "0C0B0A",
    homepage: "https://superwall.com",
    url: "https://mcp.superwall.com/mcp",
    auth: ["oauth"],
    oauthClient: "dcr",
    // Its sign-in server announces no MCP scopes; offline_access gets a refresh token.
    scopes: ["openid", "offline_access"],
    capabilities: [
      "Check revenue and run analytics queries",
      "Look up users and transactions",
      "Manage paywalls, campaigns and products",
    ],
  },
  {
    id: "adapty",
    name: "Adapty",
    description: "In-app subscriptions: revenue analytics, paywalls, A/B tests and products.",
    category: "payments",
    color: "6720FF",
    homepage: "https://adapty.io",
    url: "https://mcp.adapty.io/mcp",
    auth: ["oauth"],
    // Adapty registers clients only by client metadata document, not dynamic registration.
    oauthClient: "cimd",
    capabilities: [
      "Check revenue, MRR, retention and LTV",
      "Manage paywalls, placements and products",
      "Run A/B tests",
    ],
  },
  // ------------------------------------------------------------- developer
  {
    id: "github",
    composio: "github",
    name: "GitHub",
    description: "Repositories, issues, pull requests and code search.",
    category: "developer",
    color: "181717",
    homepage: "https://github.com",
    url: "https://api.githubcopilot.com/mcp/",
    auth: ["api_key", "oauth"],
    oauthClient: "preregistered",
    // The server announces package publishing, gists and more; ask for what its tools need.
    scopes: ["repo", "read:org", "read:user", "user:email", "read:project", "notifications"],
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
    oauthClient: "dcr",
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
  {
    id: "posthog",
    name: "PostHog",
    description: "Product analytics, feature flags and experiments.",
    category: "developer",
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
    category: "developer",
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
];

/**
 * Hubs that sign in to many apps at once. An app whose own one-click sign-in isn't set up on this
 * server can still be reached through one of these.
 */
export const HUB_APPS = ["composio", "pipedream", "zapier"] as const;

/** Ids that were merged into another app: Gmail inbox is now part of Gmail. */
const RENAMED_APPS: Record<string, string> = { gmail_inbox: "gmail" };

export const appByIdOrNull = (id: string) => {
  const found = RENAMED_APPS[id] ?? id;
  return APP_CATALOG.find((a) => a.id === found) ?? null;
};

export const appById = (id: string) => APP_CATALOG.find((a) => a.id === id);
