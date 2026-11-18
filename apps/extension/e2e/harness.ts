/**
 * The end-to-end harness: loads the dev build into Chromium and makes a throwaway account on a
 * running Casama server (the local dev stack by default) to sign in with.
 *
 * Settings, all optional:
 * - CASAMA_E2E_API: the server's API address. Default http://localhost:8787.
 * - CASAMA_E2E_AUTH_ADMIN_URL: its Auth service, reached directly for admin calls. Default
 *   http://127.0.0.1:54321 (local Supabase).
 * - CASAMA_E2E_SERVICE_ROLE_KEY: Auth's service key. Default: from `supabase status` (a stack
 *   with its own JWT secret needs the key from its .env instead).
 *
 * Nothing here sends an email: accounts are made with the admin API, and the email-code test reads
 * its code from Auth's admin generate_link instead of an inbox.
 */
import { execFileSync } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import {
  type BrowserContext,
  test as base,
  chromium,
  type Page,
  type Worker,
} from "@playwright/test";

export const API = (process.env.CASAMA_E2E_API ?? "http://localhost:8787").replace(/\/+$/, "");
const AUTH_ADMIN = (process.env.CASAMA_E2E_AUTH_ADMIN_URL ?? "http://127.0.0.1:54321").replace(
  /\/+$/,
  "",
);
const EXTENSION = resolve(import.meta.dirname, "../dist/e2e");

function serviceRoleKey(): string | undefined {
  if (process.env.CASAMA_E2E_SERVICE_ROLE_KEY) return process.env.CASAMA_E2E_SERVICE_ROLE_KEY;
  try {
    const out = execFileSync("supabase", ["status", "-o", "env"], {
      cwd: resolve(import.meta.dirname, "../../.."),
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    });
    return /^SERVICE_ROLE_KEY="?([^"\n]+)"?$/m.exec(out)?.[1];
  } catch {
    return undefined;
  }
}

async function json<T>(res: Response): Promise<T> {
  const text = await res.text();
  if (!res.ok) throw new Error(`${res.status} ${res.url}: ${text.slice(0, 300)}`);
  return (text ? JSON.parse(text) : {}) as T;
}

/** A throwaway account with a workspace and a bot, removed afterwards. */
export class TestAccount {
  readonly email = `chrome-e2e-${Date.now()}-${Math.random().toString(36).slice(2, 8)}@example.com`;
  readonly botName = `Ext Bot ${Math.random().toString(36).slice(2, 6)}`;
  userId = "";
  orgId = "";
  botId = "";
  private token = "";
  private anonKey = "";
  private readonly password = `pw-${crypto.randomUUID()}`;

  readonly serviceKey: string;
  constructor(serviceKey: string) {
    this.serviceKey = serviceKey;
  }

  private admin(path: string, init: RequestInit = {}) {
    return fetch(`${AUTH_ADMIN}/auth/v1${path}`, {
      ...init,
      headers: {
        apikey: this.serviceKey,
        authorization: `Bearer ${this.serviceKey}`,
        "content-type": "application/json",
      },
    });
  }

  api(path: string, init: RequestInit = {}) {
    return fetch(`${API}${path}`, {
      ...init,
      headers: { authorization: `Bearer ${this.token}`, "content-type": "application/json" },
    });
  }

  async create() {
    const config = await json<{ supabase_anon_key: string }>(await fetch(`${API}/v1/config`));
    this.anonKey = config.supabase_anon_key;
    const user = await json<{ id: string }>(
      await this.admin("/admin/users", {
        method: "POST",
        body: JSON.stringify({ email: this.email, password: this.password, email_confirm: true }),
      }),
    );
    this.userId = user.id;
    const session = await json<{ access_token: string }>(
      await fetch(`${AUTH_ADMIN}/auth/v1/token?grant_type=password`, {
        method: "POST",
        headers: { apikey: this.anonKey, "content-type": "application/json" },
        body: JSON.stringify({ email: this.email, password: this.password }),
      }),
    );
    this.token = session.access_token;
    let orgs = (await json<{ items: { id: string }[] }>(await this.api("/v1/orgs"))).items;
    if (!orgs.length) {
      await json(
        await this.api("/v1/orgs", {
          method: "POST",
          body: JSON.stringify({ name: "Chrome test" }),
        }),
      );
      orgs = (await json<{ items: { id: string }[] }>(await this.api("/v1/orgs"))).items;
    }
    this.orgId = orgs[0]!.id;
    const bot = await json<{ id: string }>(
      await this.api("/v1/bots", {
        method: "POST",
        body: JSON.stringify({ org_id: this.orgId, name: this.botName }),
      }),
    );
    this.botId = bot.id;
    return this;
  }

  /** What "Sign In on Another Device" shows: a one-time sign-in link. */
  async signInLink(): Promise<string> {
    const code = await json<{ pair_url: string }>(
      await this.api("/v1/auth/pairing-codes", { method: "POST" }),
    );
    return code.pair_url;
  }

  /** The six-digit code an email would carry, made without sending one. */
  async emailCode(): Promise<string> {
    const link = await json<{ email_otp?: string; properties?: { email_otp?: string } }>(
      await this.admin("/admin/generate_link", {
        method: "POST",
        body: JSON.stringify({ type: "magiclink", email: this.email }),
      }),
    );
    const otp = link.email_otp ?? link.properties?.email_otp;
    if (!otp) throw new Error("Auth didn't return an email code");
    return otp;
  }

  /** PostgREST as the service role, for rows a test sets up that no route makes (runs, approvals). */
  async rest<T = unknown>(path: string, init: RequestInit = {}): Promise<T> {
    return json<T>(
      await fetch(`${AUTH_ADMIN}/rest/v1${path}`, {
        ...init,
        headers: {
          apikey: this.serviceKey,
          authorization: `Bearer ${this.serviceKey}`,
          "content-type": "application/json",
          prefer: "return=representation",
        },
      }),
    );
  }

  async remove() {
    if (this.userId)
      await this.admin(`/admin/users/${this.userId}`, { method: "DELETE" }).catch(() => {});
  }
}

export async function serverUp(): Promise<boolean> {
  try {
    return (await fetch(`${API}/readyz`, { signal: AbortSignal.timeout(3000) })).ok;
  } catch {
    return false;
  }
}

type Fixtures = {
  context: BrowserContext;
  extensionId: string;
  worker: Worker;
  account: TestAccount;
};

export const test = base.extend<Fixtures>({
  // biome-ignore lint/correctness/noEmptyPattern: Playwright fixtures take an object pattern.
  context: async ({}, use) => {
    const dir = mkdtempSync(join(tmpdir(), "casama-ext-"));
    const context = await chromium.launchPersistentContext(dir, {
      channel: "chromium",
      args: [
        `--disable-extensions-except=${EXTENSION}`,
        `--load-extension=${EXTENSION}`,
        // A fake microphone for the live call test, allowed without a prompt.
        "--use-fake-ui-for-media-stream",
        "--use-fake-device-for-media-stream",
      ],
    });
    await use(context);
    await context.close();
    rmSync(dir, { recursive: true, force: true });
  },
  worker: async ({ context }, use) => {
    const worker = context.serviceWorkers()[0] ?? (await context.waitForEvent("serviceworker"));
    await use(worker);
  },
  extensionId: async ({ worker }, use) => {
    await use(new URL(worker.url()).host);
  },
  // biome-ignore lint/correctness/noEmptyPattern: Playwright fixtures take an object pattern.
  account: async ({}, use) => {
    const key = serviceRoleKey();
    test.skip(!key, "No Auth service key: set CASAMA_E2E_SERVICE_ROLE_KEY or run supabase start");
    test.skip(!(await serverUp()), `No Casama server at ${API}`);
    const account = await new TestAccount(key!).create();
    await use(account);
    await account.remove();
  },
});

export const expect = test.expect;

/** The options page, opened on install; reused rather than opening a second one. */
export async function optionsPage(context: BrowserContext, extensionId: string): Promise<Page> {
  const url = `chrome-extension://${extensionId}/options/options.html`;
  const existing = context.pages().find((p) => p.url().startsWith(url));
  if (existing) return existing;
  const opened = await context
    .waitForEvent("page", { predicate: (p) => p.url().startsWith(url), timeout: 5000 })
    .catch(() => null);
  if (opened) return opened;
  const page = await context.newPage();
  await page.goto(url);
  return page;
}

/** What the extension has stored, read from its service worker. */
export function storage(worker: Worker) {
  return worker.evaluate(async () => ({
    local: await chrome.storage.local.get(null),
    session: await chrome.storage.session.get(null),
    sync: await chrome.storage.sync.get(null),
  }));
}
