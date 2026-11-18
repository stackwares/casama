/**
 * Casama Link: live view away from the computer, on the self-hosted server (D-296).
 *
 * Live view's video goes through a relay. This server's own relay sits behind the home router, so
 * a phone that came in through the Casama Link address can't reach it. For those viewers the server
 * asks Casama Cloud for credentials to a relay both ends can reach, hands them to the phone, and
 * hands the same ones to the bot's computer, whose streamer reaches that relay through a forwarder
 * in this server's relay container (a bot's computer has no other way out for it).
 *
 * What Casama Cloud gives lasts half a day. It is kept and reused while it is good for hours more,
 * so a server asks a few times a day at most, and a streamer that is already running is restarted
 * for new credentials only when it has been up that long.
 */
import { createHash } from "node:crypto";

export interface RelayCredentials {
  /** Where a phone reaches the relay. */
  urls: string[];
  username: string;
  credential: string;
  /** Names this set of credentials without giving them away (the streamer is told which it has). */
  key: string;
  expiresAt: number;
}

export type OutsideRelayProblem =
  /** The workspace's plan doesn't have live view away from the computer. */
  | "plan"
  /** Casama Cloud or its relay couldn't be reached, or refused for another reason. */
  | "unavailable";

export class OutsideRelayError extends Error {
  readonly problem: OutsideRelayProblem;
  constructor(problem: OutsideRelayProblem, message: string) {
    super(message);
    this.problem = problem;
  }
}

export interface OutsideRelayOptions {
  cloud: { url: string; key: string };
  /** Where this server's relay container forwards to; credentials for another relay are no use. */
  upstream: string;
  fetch?: typeof fetch;
  now?: () => number;
  logger?: { warn(msg: string, data?: Record<string, unknown>): void };
  /** Asked for, in seconds (default and most: 12 hours). */
  ttlSeconds?: number;
  /** Credentials good for at least this much longer are reused (default 6 hours). */
  reuseMs?: number;
}

export class OutsideRelay {
  private readonly o: OutsideRelayOptions;
  private readonly fetch: typeof fetch;
  private readonly now: () => number;
  private held: RelayCredentials | null = null;
  private asking: Promise<RelayCredentials> | null = null;
  /** A refusal is remembered for a minute, so a screen that retries doesn't hammer Casama Cloud. */
  private refused: { error: OutsideRelayError; until: number } | null = null;

  constructor(o: OutsideRelayOptions) {
    this.o = o;
    this.fetch = o.fetch ?? fetch;
    this.now = o.now ?? Date.now;
  }

  /** What is held now, without asking anyone: for the streamer, which starts on every viewer. */
  cached(): RelayCredentials | null {
    // A few minutes short of the end are no use to a stream that is about to start.
    if (this.held && this.held.expiresAt - this.now() < 10 * 60_000) this.held = null;
    return this.held;
  }

  /** For a viewer outside: what is held if it is good for hours, or new ones from Casama Cloud. */
  get(): Promise<RelayCredentials> {
    const held = this.cached();
    if (held && held.expiresAt - this.now() >= (this.o.reuseMs ?? 6 * 3_600_000))
      return Promise.resolve(held);
    if (this.refused && this.refused.until > this.now()) return this.settle(this.refused.error);
    // One at a time: two people opening live view together share the answer.
    this.asking ??= this.ask()
      .catch((e: unknown) => {
        const error =
          e instanceof OutsideRelayError
            ? e
            : new OutsideRelayError("unavailable", (e as Error).message);
        this.refused = { error, until: this.now() + 60_000 };
        return this.settle(error);
      })
      .finally(() => {
        this.asking = null;
      });
    return this.asking;
  }

  /** After a refusal: something held that still works beats an error, unless the plan lost it. */
  private settle(error: OutsideRelayError): Promise<RelayCredentials> {
    if (error.problem === "plan") {
      this.held = null;
      return Promise.reject(error);
    }
    const held = this.cached();
    return held ? Promise.resolve(held) : Promise.reject(error);
  }

  private async ask(): Promise<RelayCredentials> {
    const ttl = this.o.ttlSeconds ?? 43_200;
    const res = await this.fetch(
      `${this.o.cloud.url.replace(/\/$/, "")}/link/v1/turn-credentials`,
      {
        method: "POST",
        headers: {
          authorization: `Bearer ${this.o.cloud.key}`,
          "content-type": "application/json",
        },
        body: JSON.stringify({ ttl_seconds: ttl }),
        signal: AbortSignal.timeout(15_000),
      },
    );
    const json = (await res.json().catch(() => ({}))) as {
      ice_servers?: Array<{ urls?: string[]; username?: string; credential?: string }>;
      upstream?: string;
      expires_in?: number;
      message?: string;
    };
    if (res.status === 402)
      throw new OutsideRelayError("plan", json.message ?? "The plan doesn't include this");
    if (!res.ok) throw new OutsideRelayError("unavailable", `Casama Cloud answered ${res.status}`);
    const first = json.ice_servers?.[0];
    if (!first?.username || !first.credential || !first.urls?.length)
      throw new OutsideRelayError("unavailable", "Casama Cloud gave no relay");
    if (json.upstream !== this.o.upstream) {
      // The bot's computer would be sent to a relay these credentials aren't for.
      this.o.logger?.warn("casama link: the relay changed; update this server", {
        expected: this.o.upstream,
        given: json.upstream,
      });
      throw new OutsideRelayError("unavailable", "This server needs an update for the relay");
    }
    this.refused = null;
    this.held = {
      urls: first.urls,
      username: first.username,
      credential: first.credential,
      key: keyOf(first.username),
      expiresAt: this.now() + (json.expires_in ?? ttl) * 1000,
    };
    return this.held;
  }
}

/** A short name for a set of credentials: a hash, so it can be logged and compared safely. */
const keyOf = (username: string) =>
  createHash("sha256").update(username).digest("hex").slice(0, 16);
