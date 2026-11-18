import createClient, { type Client } from "openapi-fetch";
import { CasamaError } from "./errors.ts";
import type { components, paths } from "./generated/schema.ts";
import { readSse } from "./sse.ts";

export type Schemas = components["schemas"];
export type Run = Schemas["Run"];
export type RunStatus = Schemas["RunStatus"];
export type Approval = Schemas["Approval"];
/**
 * A run event. The union covers every type this client version knows, so `switch (e.type)`
 * narrows `payload`. A newer server can send types that aren't listed: ignore what you don't know.
 */
export type RunEvent = Schemas["RunEvent"];
export type RunEventOf<T extends RunEvent["type"]> = Extract<RunEvent, { type: T }>;
export type ApprovalRequest = RunEventOf<"approval.requested">["payload"];
export type Site = Schemas["Site"];
export type Domain = Schemas["Domain"];
export type DomainSearchResult = Schemas["DomainSearchResult"];
export type Pack = Schemas["Pack"];
export type PackPreview = Schemas["PackPreview"];
export type PackInstallResult = Schemas["PackInstallResult"];
export type PackUpdatePreview = Schemas["PackUpdatePreview"];
/** Where a pack comes from: a GitHub link (with the previewed commit), the directory, a share link or files. */
export type PackSource = Omit<Schemas["PreviewPackRequest"], "org_id">;

export type TokenSource = () => string | null | undefined | Promise<string | null | undefined>;

export interface CasamaClientOptions {
  /** The server's API address. Defaults to Casama Cloud, `https://api.casama.ai`. */
  apiUrl?: string;
  /** A fixed access token (a Casama sign-in token, sent as `Authorization: Bearer`). */
  token?: string;
  /** Called before every request for the current token, so you can refresh it. Wins over `token`. */
  getToken?: TokenSource;
  /** A fetch implementation; defaults to the global `fetch`. */
  fetch?: typeof fetch;
  /** Extra headers on every request. */
  headers?: Record<string, string>;
}

export interface WatchRunOptions {
  /** Start after this `seq`; pass the last one you processed to resume. Default 0. */
  afterSeq?: number;
  /** `sse` (default) streams live; `poll` asks `GET /v1/runs/{id}/events` every `pollIntervalMs`. */
  transport?: "sse" | "poll";
  /** Poll interval for `transport: "poll"`. Default 1000 ms. */
  pollIntervalMs?: number;
  /** Failed connections in a row before giving up. Default 8. */
  maxRetries?: number;
  signal?: AbortSignal;
}

export type ApprovalAnswer =
  | "approved"
  | "denied"
  | { decision: "approved" | "denied"; alwaysAllow?: boolean };

export interface AskOptions extends Pick<WatchRunOptions, "transport" | "pollIntervalMs"> {
  /** Continue this conversation; without it, a new one is started. */
  conversationId?: string;
  /** The new conversation's title. */
  title?: string;
  /** Stop waiting after this long and return what arrived so far (`timedOut: true`). Default 10 minutes. */
  timeoutMs?: number;
  /** Called for every event, in order. */
  onEvent?: (event: RunEvent) => void | Promise<void>;
  /**
   * Called when the bot asks for approval. Return the decision and the run carries on. Without
   * it, `ask` returns as soon as the run waits for approval, with `pendingApproval` set.
   */
  onApproval?: (request: ApprovalRequest) => ApprovalAnswer | Promise<ApprovalAnswer>;
  /** Extra fields for the message, such as `attachments` or `skills`. */
  message?: Omit<Schemas["SendMessageRequest"], "text">;
  signal?: AbortSignal;
}

export interface AskResult {
  /** The bot's reply: the text parts of its completed messages. */
  text: string;
  /** The run as it stands at the end: status, tokens, cost, error. */
  run: Run;
  runId: string;
  conversationId: string;
  messageId: string;
  /** Every event `ask` saw, in order. */
  events: RunEvent[];
  /** The approval the run is waiting on, when it stopped there and no `onApproval` was given. */
  pendingApproval?: ApprovalRequest;
  /** `timeoutMs` passed before the run ended. */
  timedOut: boolean;
}

type FetchResult<T> = { data?: T; error?: unknown; response: Response };

/** Returns `data` from an openapi-fetch result, or throws a {@link CasamaError}. */
export async function unwrap<T>(result: FetchResult<T> | Promise<FetchResult<T>>): Promise<T> {
  const r = await result;
  if (r.error !== undefined || !r.response.ok)
    throw await CasamaError.fromResponse(r.response, r.error);
  return r.data as T;
}

const TERMINAL = new Set(["run.completed", "run.failed", "run.cancelled"]);
const ENDED: ReadonlySet<string> = new Set<RunStatus>(["completed", "failed", "cancelled"]);

export type CasamaClient = Client<paths> & {
  /** The openapi-fetch client, for `use(middleware)` and the like. */
  readonly api: Client<paths>;
  readonly apiUrl: string;
  /** Send `text` to a bot, wait for the run to finish and return its reply. */
  ask(botId: string, text: string, options?: AskOptions): Promise<AskResult>;
  /** A run's events, in `seq` order with no repeats, ending with the run. Reconnects on drops. */
  watchRun(runId: string, options?: WatchRunOptions): AsyncGenerator<RunEvent, void, undefined>;
  /** Approve or deny a step the bot is waiting on. */
  decideApproval(
    approvalId: string,
    decision: "approved" | "denied",
    options?: { alwaysAllow?: boolean },
  ): Promise<Approval>;
  /** Cancel a run. Throws `run_finished` (409) when it already ended. */
  cancelRun(runId: string): Promise<Run>;
  /** Sites: published pages at their own address (D-329). */
  sites: {
    /** The workspace's published sites, with their hosts and states. */
    list(orgId: string): Promise<Site[]>;
    /** Whether an address name is free, and why not when it isn't. */
    checkAddress(orgId: string, label: string): Promise<Schemas["SiteAddressCheck"]>;
    /** Puts a page on the web at `<label>.<sites zone>`; the page becomes public. */
    publish(pageId: string, options?: Schemas["PublishSiteRequest"]): Promise<Site>;
    /** Takes a site off the web; the page goes private again. */
    unpublish(pageId: string): Promise<void>;
  };
  /** Domains: connected and bought (D-329). Buying, renewing and transfers stay in the app. */
  domains: {
    list(orgId: string): Promise<Domain[]>;
    /** With the records to add and what DNS shows now, and its history. */
    get(domainId: string): Promise<Domain>;
    /** Connects a domain the workspace owns; answers the records to add. */
    connect(
      orgId: string,
      name: string,
      options?: { pageId?: string },
    ): Promise<{ domain: Domain | null; claim: Schemas["ConnectDomainResult"]["claim"] }>;
    /** Checks DNS now (at most once every 10 seconds per domain). */
    check(domainId: string): Promise<Domain>;
    /** Points a domain at a site (null: none). */
    setSite(domainId: string, pageId: string | null): Promise<Domain>;
    /** Disconnects a domain; a bought one stays registered. */
    disconnect(domainId: string): Promise<void>;
    /** Names, availability and prices (admins; servers that sell domains). */
    search(orgId: string, query: string): Promise<DomainSearchResult[]>;
  };
  /** Packs: plugins that bring bots, skills, routines, apps and looks to a workspace. */
  packs: {
    list(orgId: string): Promise<Pack[]>;
    /** What a pack brings, before installing. */
    preview(orgId: string, from: PackSource): Promise<PackPreview>;
    /** Installs a pack; a link installs `from.commit`, or the commit a preview shows when unset. */
    install(
      orgId: string,
      from: PackSource,
      options?: Omit<Schemas["InstallPackRequest"], "org_id" | keyof PackSource>,
    ): Promise<PackInstallResult>;
    /** The newer version, as a diff, with the items you edited. */
    checkUpdate(packId: string): Promise<PackUpdatePreview>;
    update(packId: string, body: Schemas["UpdatePackRequest"]): Promise<PackInstallResult>;
    /** Removes a pack; edited items and (by default) its bots stay. */
    remove(
      packId: string,
      options?: { deleteBots?: boolean },
    ): Promise<{ deleted: string; kept: number }>;
    /** Bots as a pack's files, with lines that look like keys. */
    export(orgId: string, body: Schemas["ExportPackRequest"]): Promise<Schemas["PackExport"]>;
    /** A 30-day link to a pack made of these bots. */
    share(orgId: string, body: Schemas["SharePackRequest"]): Promise<Schemas["PackShare"]>;
  };
  /** Returns `data` from a raw call, or throws a {@link CasamaError}. */
  unwrap: typeof unwrap;
};

/** Creates a typed client for the Casama HTTP API. */
export function createCasamaClient(options: CasamaClientOptions = {}): CasamaClient {
  const apiUrl = (options.apiUrl ?? "https://api.casama.ai").replace(/\/+$/, "");
  const fetchImpl: typeof fetch = options.fetch ?? ((input, init) => globalThis.fetch(input, init));

  const authorize = async (headers: Headers) => {
    const token = options.getToken ? await options.getToken() : options.token;
    if (token && !headers.has("authorization")) headers.set("authorization", `Bearer ${token}`);
  };

  const api = createClient<paths>({
    baseUrl: apiUrl,
    headers: options.headers,
    fetch: (request) => fetchImpl(request),
  });
  api.use({
    async onRequest({ request }) {
      await authorize(request.headers);
      return request;
    },
  });

  /** A raw request with the same auth, for the event stream. */
  const raw = async (path: string, init: RequestInit = {}) => {
    const headers = new Headers(options.headers);
    for (const [k, v] of new Headers(init.headers)) headers.set(k, v);
    await authorize(headers);
    return fetchImpl(new Request(`${apiUrl}${path}`, { ...init, headers }));
  };

  async function* watchRun(
    runId: string,
    opts: WatchRunOptions = {},
  ): AsyncGenerator<RunEvent, void, undefined> {
    let lastSeq = opts.afterSeq ?? 0;
    let failures = 0;
    const maxRetries = opts.maxRetries ?? 8;
    const signal = opts.signal;
    const path = `/v1/runs/${encodeURIComponent(runId)}/events`;
    let transport = opts.transport ?? "sse";

    const fail = async (err: unknown) => {
      if (signal?.aborted) throw signal.reason;
      if (
        err instanceof CasamaError &&
        err.status < 500 &&
        err.status !== 408 &&
        err.status !== 429
      )
        throw err;
      failures += 1;
      if (failures > maxRetries) throw err;
      const wait =
        err instanceof CasamaError && err.retryAfter !== undefined
          ? err.retryAfter * 1000
          : Math.min(250 * 2 ** (failures - 1), 8000);
      await sleep(wait, signal);
    };

    while (true) {
      signal?.throwIfAborted();
      try {
        if (transport === "poll") {
          const res = await raw(`${path}?after_seq=${lastSeq}&limit=1000`, { signal });
          if (!res.ok) throw await CasamaError.fromResponse(res);
          const page = (await res.json()) as Schemas["RunEventsPage"];
          failures = 0;
          let ended = false;
          for (const e of page.items as RunEvent[]) {
            if (e.seq <= lastSeq) continue;
            lastSeq = e.seq;
            yield e;
            if (TERMINAL.has(e.type)) ended = true;
          }
          if (ended || (ENDED.has(page.run_status) && page.items.length < 1000)) return;
          if (page.items.length < 1000) await sleep(opts.pollIntervalMs ?? 1000, signal);
          continue;
        }

        const res = await raw(`${path}?after_seq=${lastSeq}`, {
          signal,
          headers: { accept: "text/event-stream", "last-event-id": String(lastSeq) },
        });
        if (!res.ok) throw await CasamaError.fromResponse(res);
        if (!res.body || !res.headers.get("content-type")?.includes("text/event-stream")) {
          // Something on the way (a proxy, an older server) answered without streaming: poll.
          await res.body?.cancel();
          transport = "poll";
          continue;
        }
        for await (const m of readSse(res.body)) {
          if (m.event !== "run_event") continue;
          const e = JSON.parse(m.data) as RunEvent;
          failures = 0;
          if (e.seq <= lastSeq) continue;
          lastSeq = e.seq;
          yield e;
          if (TERMINAL.has(e.type)) return;
        }
        // The stream closed without a final event: reconnect and pick up where it stopped.
        await fail(new Error("The event stream closed early"));
      } catch (err) {
        await fail(err);
      }
    }
  }

  const decideApproval: CasamaClient["decideApproval"] = (approvalId, decision, o = {}) =>
    unwrap(
      api.POST("/v1/approvals/{id}/decision", {
        params: { path: { id: approvalId } },
        body: { decision, ...(o.alwaysAllow ? { always_allow: true } : {}) },
      }),
    );

  const getRun = (runId: string, signal?: AbortSignal) =>
    unwrap(api.GET("/v1/runs/{id}", { params: { path: { id: runId } }, signal }));

  async function ask(botId: string, text: string, o: AskOptions = {}): Promise<AskResult> {
    const timeout = AbortSignal.timeout(o.timeoutMs ?? 10 * 60_000);
    const signal = o.signal ? AbortSignal.any([o.signal, timeout]) : timeout;

    const conversationId =
      o.conversationId ??
      (
        await unwrap(
          api.POST("/v1/conversations", {
            body: { bot_id: botId, ...(o.title ? { title: o.title } : {}) },
            signal,
          }),
        )
      ).id;
    const sent = await unwrap(
      api.POST("/v1/conversations/{id}/messages", {
        params: { path: { id: conversationId } },
        headers: { "idempotency-key": crypto.randomUUID() },
        body: { ...o.message, text },
        signal,
      }),
    );

    const events: RunEvent[] = [];
    let pendingApproval: ApprovalRequest | undefined;
    let timedOut = false;
    try {
      for await (const e of watchRun(sent.run_id, {
        transport: o.transport,
        pollIntervalMs: o.pollIntervalMs,
        signal,
      })) {
        events.push(e);
        await o.onEvent?.(e);
        if (e.type !== "approval.requested") continue;
        if (o.onApproval) {
          const answer = await o.onApproval(e.payload);
          const a = typeof answer === "string" ? { decision: answer } : answer;
          try {
            await decideApproval(e.payload.approval_id, a.decision, { alwaysAllow: a.alwaysAllow });
          } catch (err) {
            // Someone else decided it first, or it expired: the run goes on either way.
            if (!(err instanceof CasamaError && err.status === 409)) throw err;
          }
        } else if ((await getRun(sent.run_id, signal)).status === "waiting_approval") {
          pendingApproval = e.payload;
          break;
        }
      }
    } catch (err) {
      if (!(timeout.aborted && !o.signal?.aborted)) throw err;
      timedOut = true;
    }

    return {
      text: replyText(events),
      run: await getRun(sent.run_id, o.signal),
      runId: sent.run_id,
      conversationId,
      messageId: sent.message_id,
      events,
      ...(pendingApproval ? { pendingApproval } : {}),
      timedOut,
    };
  }

  const cancelRun = (runId: string) =>
    unwrap(api.POST("/v1/runs/{id}/cancel", { params: { path: { id: runId } } }));

  const id = (v: string) => ({ params: { path: { id: v } } });
  const sites: CasamaClient["sites"] = {
    list: async (orgId) => (await unwrap(api.GET("/v1/orgs/{id}/sites", id(orgId)))).items,
    checkAddress: (orgId, label) =>
      unwrap(api.GET("/v1/sites/address", { params: { query: { org_id: orgId, label } } })),
    publish: (pageId, o = {}) => unwrap(api.PUT("/v1/pages/{id}/site", { ...id(pageId), body: o })),
    unpublish: async (pageId) => {
      await unwrap(api.DELETE("/v1/pages/{id}/site", id(pageId)));
    },
  };
  const domains: CasamaClient["domains"] = {
    list: async (orgId) => (await unwrap(api.GET("/v1/orgs/{id}/domains", id(orgId)))).items,
    get: (domainId) => unwrap(api.GET("/v1/domains/{id}", id(domainId))),
    connect: async (orgId, name, o = {}) => {
      const r = await unwrap(
        api.POST("/v1/orgs/{id}/domains", {
          ...id(orgId),
          body: { name, ...(o.pageId ? { page_id: o.pageId } : {}) },
        }),
      );
      return { domain: (r.domain as Domain | null) ?? null, claim: r.claim };
    },
    check: (domainId) => unwrap(api.POST("/v1/domains/{id}/check", id(domainId))),
    setSite: (domainId, pageId) =>
      unwrap(api.PATCH("/v1/domains/{id}", { ...id(domainId), body: { page_id: pageId } })),
    disconnect: async (domainId) => {
      await unwrap(api.DELETE("/v1/domains/{id}", id(domainId)));
    },
    search: async (orgId, query) =>
      (
        await unwrap(
          api.GET("/v1/domains/search", { params: { query: { org_id: orgId, q: query } } }),
        )
      ).items,
  };

  const packs: CasamaClient["packs"] = {
    list: async (orgId) =>
      (await unwrap(api.GET("/v1/packs", { params: { query: { org_id: orgId } } }))).items,
    preview: (orgId, from) =>
      unwrap(api.POST("/v1/packs/preview", { body: { org_id: orgId, ...from } })),
    install: async (orgId, from, o = {}) => {
      let commit = from.commit;
      if (from.url && !commit) commit = (await packs.preview(orgId, from)).commit ?? undefined;
      return unwrap(
        api.POST("/v1/packs", {
          body: { org_id: orgId, ...from, ...(commit ? { commit } : {}), ...o },
        }),
      );
    },
    checkUpdate: (packId) => unwrap(api.GET("/v1/packs/{id}/update", id(packId))),
    update: (packId, body) => unwrap(api.POST("/v1/packs/{id}/update", { ...id(packId), body })),
    remove: (packId, o = {}) =>
      unwrap(
        api.DELETE("/v1/packs/{id}", {
          params: { path: { id: packId }, query: { bots: o.deleteBots ? "delete" : "keep" } },
        }),
      ),
    export: (orgId, body) => unwrap(api.POST("/v1/orgs/{id}/packs/export", { ...id(orgId), body })),
    share: (orgId, body) => unwrap(api.POST("/v1/orgs/{id}/packs/share", { ...id(orgId), body })),
  };

  return {
    ...api,
    api,
    apiUrl,
    packs,
    ask,
    watchRun,
    decideApproval,
    cancelRun,
    sites,
    domains,
    unwrap,
  };
}

/** The text of a run's completed messages, or its streamed deltas when none completed. */
export function replyText(events: readonly RunEvent[]): string {
  const parts: string[] = [];
  for (const e of events) {
    if (e.type !== "message.completed") continue;
    for (const p of e.payload.content) {
      if (p.type === "text" && typeof p.text === "string") parts.push(p.text);
    }
  }
  if (parts.length > 0) return parts.join("\n");
  return events.map((e) => (e.type === "message.delta" ? e.payload.text : "")).join("");
}

function sleep(ms: number, signal?: AbortSignal) {
  return new Promise<void>((resolve, reject) => {
    if (signal?.aborted) return reject(signal.reason);
    const t = setTimeout(() => {
      signal?.removeEventListener("abort", onAbort);
      resolve();
    }, ms);
    const onAbort = () => {
      clearTimeout(t);
      reject(signal?.reason);
    };
    signal?.addEventListener("abort", onAbort, { once: true });
  });
}
