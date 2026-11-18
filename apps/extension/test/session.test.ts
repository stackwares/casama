import { beforeEach, describe, expect, it } from "vitest";
import {
  accessToken,
  sendEmailCode,
  setFetch,
  signInWithEmailCode,
  signInWithLink,
  signOut,
  switchAccount,
  UnreachableError,
} from "../src/lib/session.ts";
import { getLocal, getSession, updateLocal, updateSession } from "../src/lib/store.ts";
import { fakeBackend, installFakeChrome } from "./fake-chrome.ts";

let chrome: ReturnType<typeof installFakeChrome>;
let be: ReturnType<typeof fakeBackend>;

beforeEach(() => {
  chrome = installFakeChrome();
  be = fakeBackend();
  setFetch(be.fetch);
});

const link = () =>
  `https://casama.ai/pair#v=1&s=${encodeURIComponent(be.server)}&c=${be.state.validCode}`;

describe("signing in with a link", () => {
  it("keeps the refresh token on disk and the access token in memory only", async () => {
    const account = await signInWithLink(link());
    expect(account.email).toBe("ada@example.test");
    expect(account.server).toBe(be.server);

    const local = chrome.areas.local!.data as { accounts: { refreshToken: string }[] };
    expect(local.accounts).toHaveLength(1);
    expect(local.accounts[0]!.refreshToken).toBe("refresh-2");
    expect(JSON.stringify(local)).not.toContain("access-1");

    const session = chrome.areas.session!.data as { tokens: Record<string, { token: string }> };
    expect(session.tokens[account.id]!.token).toBe("access-1");
    expect(chrome.areas.sync!.data).toEqual({});
    // Asked to keep both areas from content scripts.
    expect(chrome.areas.local!.accessLevel).toBe("TRUSTED_CONTEXTS");
    expect(chrome.areas.session!.accessLevel).toBe("TRUSTED_CONTEXTS");

    const redeem = be.calls.find((c) => c.url.endsWith("/v1/auth/pairing-codes/redeem"))!;
    expect(redeem.body).toMatchObject({ code: expect.stringMatching(/^ksc_/) });
    const verify = be.calls.find((c) => c.url.endsWith("/auth/v1/verify"))!;
    expect(verify.body).toEqual({ type: "magiclink", token_hash: "hash-1" });
    expect(verify.headers.apikey).toBe("anon");
  });

  it("takes a bare code for the chosen server", async () => {
    const account = await signInWithLink(be.state.validCode, { fallbackServer: be.server });
    expect(account.server).toBe(be.server);
  });

  it("says when a code was already used", async () => {
    await signInWithLink(link());
    await expect(
      signInWithLink(
        `https://casama.ai/pair#v=1&s=${encodeURIComponent(be.server)}&c=ksc_${"z".repeat(43)}`,
      ),
    ).rejects.toThrow(/isn't valid any more/);
  });

  it("refuses a server the page may not sign in to", async () => {
    await expect(
      signInWithLink(link(), { allowedServers: ["https://api.casama.ai"] }),
    ).rejects.toThrow(/can't sign in this way/);
    expect(be.calls).toHaveLength(0);
  });

  it("refuses when the server can't make sign-in codes", async () => {
    be.state.signInCodes = false;
    await expect(signInWithLink(link())).rejects.toThrow(/email code/);
  });

  it("names the address it couldn't reach", async () => {
    be.state.unreachable.add(be.server);
    const err = await signInWithLink(link()).catch((e) => e);
    expect(err).toBeInstanceOf(UnreachableError);
    expect(err.url).toBe(be.server);
  });
});

describe("signing in with an email code", () => {
  it("sends a code without creating an account, then signs in", async () => {
    const server = await sendEmailCode("api.example.test", " ada@example.test ");
    expect(server).toBe(be.server);
    const otp = be.calls.find((c) => c.url.endsWith("/auth/v1/otp"))!;
    expect(otp.body).toEqual({ email: "ada@example.test", create_user: false });
    await expect(signInWithEmailCode(server, "ada@example.test", "999999")).rejects.toThrow(
      /wrong or has run out/,
    );
    const account = await signInWithEmailCode(server, "ada@example.test", "123 456");
    expect(account.email).toBe("ada@example.test");
  });

  it("checks the email and code before asking", async () => {
    await expect(sendEmailCode(be.server, "nope")).rejects.toThrow(/email/);
    await expect(signInWithEmailCode(be.server, "a@b.co", "abc")).rejects.toThrow(
      /code from the email/,
    );
    expect(be.calls).toHaveLength(0);
  });
});

describe("tokens", () => {
  it("refreshes a token that is about to run out, once", async () => {
    const account = await signInWithLink(link());
    expect(await accessToken(account.id)).toBe("access-1");
    await updateSession((s) => {
      s.tokens[account.id]!.expiresAt = Date.now() + 10_000;
    });
    const [a, b] = await Promise.all([accessToken(account.id), accessToken(account.id)]);
    expect(a).toBe("access-2");
    expect(b).toBe("access-2");
    expect(be.calls.filter((c) => c.url.includes("/auth/v1/token"))).toHaveLength(1);
    expect((await getLocal()).accounts[0]!.refreshToken).toBe("refresh-3");
  });

  it("forgets an account whose sign-in ended elsewhere", async () => {
    const account = await signInWithLink(link());
    await updateSession((s) => {
      s.tokens = {};
    });
    be.state.refreshRefused = true;
    expect(await accessToken(account.id)).toBeNull();
    expect((await getLocal()).accounts).toEqual([]);
  });

  it("keeps the account when Auth is only unreachable", async () => {
    const account = await signInWithLink(link());
    await updateSession((s) => {
      s.tokens = {};
    });
    be.state.unreachable.add(be.auth);
    await expect(accessToken(account.id)).rejects.toBeInstanceOf(UnreachableError);
    expect((await getLocal()).accounts).toHaveLength(1);
  });
});

describe("signing out", () => {
  it("ends the session at Auth and forgets it here", async () => {
    const account = await signInWithLink(link());
    await signOut(account.id);
    const logout = be.calls.find((c) => c.url.includes("/auth/v1/logout"))!;
    expect(logout.url).toContain("scope=local");
    expect(logout.headers.authorization).toBe("Bearer access-1");
    expect((await getLocal()).accounts).toEqual([]);
    expect((await getSession()).tokens).toEqual({});
  });

  it("refreshes first to end the session at Auth after Chrome restarted", async () => {
    const account = await signInWithLink(link());
    await updateSession((s) => {
      s.tokens = {};
    });
    await signOut(account.id);
    const logout = be.calls.find((c) => c.url.includes("/auth/v1/logout"))!;
    expect(logout.headers.authorization).toBe("Bearer access-2");
    expect((await getLocal()).accounts).toEqual([]);
  });

  it("a refresh never switches the active account", async () => {
    const a = await signInWithLink(link());
    await updateLocal((s) => {
      s.accounts.push({ ...s.accounts[0]!, id: "other", email: "b@example.test" });
    });
    await switchAccount("other");
    await updateSession((s) => {
      s.tokens = {};
    });
    expect(await accessToken(a.id)).toBe("access-2");
    expect((await getLocal()).activeAccountId).toBe("other");
  });

  it("signing out while a refresh runs doesn't bring the account back", async () => {
    const account = await signInWithLink(link());
    await updateSession((s) => {
      s.tokens = {};
    });
    await Promise.all([accessToken(account.id).catch(() => null), signOut(account.id)]);
    expect((await getLocal()).accounts).toEqual([]);
  });

  it("forgets the account even when Auth can't be reached", async () => {
    const account = await signInWithLink(link());
    be.state.unreachable.add(be.auth);
    await signOut(account.id);
    expect((await getLocal()).accounts).toEqual([]);
  });
});
