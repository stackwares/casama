/** A small in-memory stand-in for the chrome.* APIs the extension's modules use. */
type Listener = (
  changes: Record<string, { oldValue?: unknown; newValue?: unknown }>,
  area: string,
) => void;

export interface FakeArea {
  data: Record<string, unknown>;
  accessLevel: string;
}

import { resetStoreForTests } from "../src/lib/store.ts";

export function installFakeChrome() {
  resetStoreForTests();
  const listeners: Listener[] = [];
  const areas: Record<string, FakeArea> = {
    local: { data: {}, accessLevel: "TRUSTED_AND_UNTRUSTED_CONTEXTS" },
    session: { data: {}, accessLevel: "TRUSTED_CONTEXTS" },
    sync: { data: {}, accessLevel: "TRUSTED_AND_UNTRUSTED_CONTEXTS" },
  };
  const area = (name: string) => ({
    async get(keys: null | string | string[]) {
      const all = structuredClone(areas[name]!.data);
      if (keys === null) return all;
      const out: Record<string, unknown> = {};
      for (const k of Array.isArray(keys) ? keys : [keys]) if (k in all) out[k] = all[k];
      return out;
    },
    async set(items: Record<string, unknown>) {
      const changes: Record<string, { oldValue?: unknown; newValue?: unknown }> = {};
      for (const [k, v] of Object.entries(items)) {
        changes[k] = { oldValue: areas[name]!.data[k], newValue: structuredClone(v) };
        areas[name]!.data[k] = structuredClone(v);
      }
      for (const l of listeners) l(changes, name);
    },
    async remove(keys: string | string[]) {
      for (const k of Array.isArray(keys) ? keys : [keys]) delete areas[name]!.data[k];
    },
    async setAccessLevel({ accessLevel }: { accessLevel: string }) {
      areas[name]!.accessLevel = accessLevel;
    },
  });
  const opened: string[] = [];
  const chrome = {
    storage: {
      local: area("local"),
      session: area("session"),
      sync: area("sync"),
      onChanged: { addListener: (l: Listener) => listeners.push(l) },
    },
    runtime: {
      openOptionsPage: async () => void opened.push("options"),
      getURL: (path: string) => `chrome-extension://test/${path.replace(/^\//, "")}`,
    },
  };
  (globalThis as unknown as { chrome: unknown }).chrome = chrome;
  return { areas, opened };
}

/** A fake server and Auth service on fixed addresses, answering what the extension asks. */
export function fakeBackend(opts: { server?: string; auth?: string } = {}) {
  const server = opts.server ?? "https://api.example.test";
  const auth = opts.auth ?? "https://auth.example.test";
  const calls: { url: string; method: string; body?: unknown; headers: Record<string, string> }[] =
    [];
  const state = {
    validCode: `ksc_${"a".repeat(43)}`,
    refreshToken: "refresh-1",
    refreshRefused: false,
    emailCode: "123456",
    unreachable: new Set<string>(),
    signInCodes: true,
    /** Uploads received at POST /v1/media. */
    uploads: [] as { query: Record<string, string>; type: string; size: number }[],
    facts: [] as unknown[],
    /** POST /v1/media answers this status instead (409: the Library is full). */
    uploadStatus: 201,
  };
  let n = 0;
  const session = (email = "ada@example.test") => {
    n += 1;
    state.refreshToken = `refresh-${n + 1}`;
    return {
      access_token: `access-${n}`,
      refresh_token: state.refreshToken,
      expires_in: 3600,
      user: { id: "00000000-0000-4000-8000-000000000001", email },
    };
  };
  const json = (status: number, body: unknown) =>
    new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
  const fetch: typeof globalThis.fetch = async (input, init) => {
    const req = input instanceof Request ? input : new Request(input, init);
    const url = new URL(req.url);
    if (state.unreachable.has(url.origin)) throw new TypeError("Failed to fetch");
    const isJson = (req.headers.get("content-type") ?? "").includes("json");
    const raw = req.body ? new Uint8Array(await req.arrayBuffer()) : new Uint8Array(0);
    const text = isJson || !req.headers.get("content-type") ? new TextDecoder().decode(raw) : "";
    const body = text ? JSON.parse(text) : undefined;
    calls.push({
      url: req.url,
      method: req.method,
      body,
      headers: Object.fromEntries(req.headers),
    });
    if (url.origin === new URL(server).origin) {
      if (url.pathname === "/v1/config")
        return json(200, {
          supabase_url: auth,
          supabase_anon_key: "anon",
          sign_in_codes: state.signInCodes,
        });
      if (url.pathname === "/v1/app-config")
        return json(200, {
          min_versions: {},
          update_urls: {},
          maintenance: null,
          announcements: [],
          flags: {},
        });
      if (url.pathname === "/v1/auth/pairing-codes/redeem")
        return body.code === state.validCode
          ? ((state.validCode = "used"),
            json(200, { token_hash: "hash-1", email: "ada@example.test" }))
          : json(404, {
              type: "about:blank",
              title: "Not Found",
              status: 404,
              code: "code_not_valid",
              detail: "That code isn't valid any more.",
            });
      if (url.pathname === "/v1/media" && req.method === "POST") {
        if (state.uploadStatus !== 201)
          return json(state.uploadStatus, {
            type: "about:blank",
            title: "No",
            status: state.uploadStatus,
            code: "storage_full",
            detail: "The workspace's Library is full.",
          });
        const query = Object.fromEntries(url.searchParams);
        state.uploads.push({
          query,
          type: req.headers.get("content-type") ?? "",
          size: raw.length,
        });
        const id = `00000000-0000-4000-8000-${String(state.uploads.length).padStart(12, "0")}`;
        return json(201, {
          id,
          path: `media:${id}`,
          name: query.name,
          mime_type: req.headers.get("content-type"),
          size: raw.length,
          creation_id: query.purpose === "library" ? `c-${id}` : null,
        });
      }
      if (url.pathname === "/v1/me/facts" && req.method === "POST") {
        state.facts.push(...body.items);
        return json(201, {
          items: body.items.map((f: object, i: number) => ({ id: `f${i}`, ...f })),
        });
      }
      return json(404, {});
    }
    if (url.origin === new URL(auth).origin) {
      if (url.pathname === "/auth/v1/verify") {
        if (body.type === "magiclink" && body.token_hash === "hash-1") return json(200, session());
        if (body.type === "email" && body.token === state.emailCode)
          return json(200, session(body.email));
        return json(403, {
          code: 403,
          error_code: "otp_expired",
          msg: "Token has expired or is invalid",
        });
      }
      if (url.pathname === "/auth/v1/otp") return json(200, {});
      if (url.pathname === "/auth/v1/token") {
        if (state.refreshRefused || body.refresh_token !== state.refreshToken)
          return json(400, {
            code: 400,
            error_code: "refresh_token_not_found",
            msg: "Invalid Refresh Token",
          });
        return json(200, session());
      }
      if (url.pathname === "/auth/v1/logout") return new Response(null, { status: 204 });
    }
    return json(404, {});
  };
  return { server, auth, calls, state, fetch };
}
