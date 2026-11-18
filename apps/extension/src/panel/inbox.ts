/**
 * The Inbox tab (D2): approvals with Approve, Deny and Always allow; secret requests in a
 * protected field that goes straight to the server; suggestions with Do it and Not now; running
 * work with Stop. Today's brief (D9) sits on top when there is one.
 */
import type { Schemas } from "@casama/client";
import { updateBadge } from "../lib/alerts.ts";
import { h } from "../lib/dom.ts";
import { botAvatar, emptyState } from "../lib/look.ts";
import { markdownNodes } from "../lib/md.ts";
import { appUrl, type Here, rest } from "../lib/workspace.ts";
import { ago, errorBox, message, T, toast } from "./shared.ts";

interface Suggestion {
  id: string;
  bot_id: string;
  title: string;
  body_md: string;
  created_at: string;
}
interface RunRow {
  id: string;
  bot_id: string;
  trigger: string;
  status: string;
  created_at: string;
}

export class InboxView {
  readonly el = h("section", { className: "view", "data-testid": "inbox" });
  private here: Here;
  private botNames = new Map<string, string>();
  private botAvatars = new Map<string, string | null>();
  onCount: (n: number) => void = () => {};

  constructor(here: Here) {
    this.here = here;
  }

  private loads = 0;

  async load() {
    const { api, org, account } = this.here;
    // Only the newest load draws: an older one finishing late would bring back decided items.
    const mine = ++this.loads;
    if (!this.el.childElementCount)
      this.el.replaceChildren(h("p", { className: "empty" }, "Loading…"));
    try {
      const [bots, approvals, secrets, suggestions, runs, feed] = await Promise.all([
        api.unwrap(api.GET("/v1/bots", { params: { query: { org_id: org.id } }, signal: T() })),
        api.unwrap(
          api.GET("/v1/approvals", {
            params: { query: { org_id: org.id, status: "pending" } },
            signal: T(),
          }),
        ),
        api.unwrap(
          api.GET("/v1/secrets/requests", { params: { query: { org_id: org.id } }, signal: T() }),
        ),
        rest(
          account,
          `suggestions?org_id=eq.${org.id}&status=eq.pending&order=created_at.desc&limit=20&select=id,bot_id,title,body_md,created_at`,
        )
          .then((r) => r.json() as Promise<Suggestion[]>)
          .catch(() => [] as Suggestion[]),
        rest(
          account,
          `runs?org_id=eq.${org.id}&status=in.(queued,running)&order=created_at.desc&limit=10&select=id,bot_id,trigger,status,created_at`,
        )
          .then((r) => r.json() as Promise<RunRow[]>)
          .catch(() => [] as RunRow[]),
        api
          .unwrap(api.GET("/v1/for-you", { params: { query: { org_id: org.id } }, signal: T() }))
          .catch(() => null),
      ]);
      if (mine !== this.loads) return;
      for (const b of bots.items) {
        this.botNames.set(b.id, b.name);
        this.botAvatars.set(b.id, b.avatar_url);
      }
      const pendingSecrets = secrets.items.filter((s) => s.status === "pending");
      this.onCount(approvals.items.length + pendingSecrets.length);
      const sections: Node[] = [];
      const today = new Date().toDateString();
      const brief = feed?.briefs
        .filter((b) => new Date(b.created_at).toDateString() === today)
        .sort((a, b) => b.created_at.localeCompare(a.created_at))[0];
      if (brief) sections.push(this.brief(brief));
      if (approvals.items.length)
        sections.push(
          h("div", { className: "section-title" }, "Approvals"),
          ...approvals.items.map((a) => this.approval(a)),
        );
      if (pendingSecrets.length)
        sections.push(
          h("div", { className: "section-title" }, "Asked for"),
          ...pendingSecrets.map((s) => this.secret(s)),
        );
      if (suggestions.length)
        sections.push(
          h("div", { className: "section-title" }, "Suggestions"),
          ...suggestions.map((s) => this.suggestion(s)),
        );
      if (runs.length)
        sections.push(
          h("div", { className: "section-title" }, "Working now"),
          ...runs.map((r) => this.run(r)),
        );
      this.el.replaceChildren(
        ...(sections.length
          ? sections
          : [
              emptyState({
                mascot: "starry",
                badge: "check",
                testid: "inbox-empty",
                message: "Nothing needs you right now.",
              }),
            ]),
      );
    } catch (e) {
      if (mine === this.loads) this.el.replaceChildren(errorBox(e, () => void this.load()));
    }
  }

  /** D9: today's brief, as the bot wrote it, with a link to its conversation. */
  private brief(b: Schemas["ForYouBrief"]) {
    const long = b.text.length > 1500;
    return h(
      "div",
      { className: "item brief", "data-testid": "brief" },
      this.head(b.bot_id, "Today's brief", `${this.name(b.bot_id)} · ${ago(b.created_at)}`),
      h("div", { className: "body" }, markdownNodes(long ? `${b.text.slice(0, 1500)}…` : b.text)),
      h(
        "a",
        {
          href: appUrl(this.here.account, `/bots/${b.bot_id}/chat?c=${b.conversation_id}`),
          target: "_blank",
          rel: "noopener",
        },
        long ? "Read it all in Casama" : "Open in Casama",
      ),
    );
  }

  private name(botId: string | null | undefined) {
    return (botId && this.botNames.get(botId)) || "A bot";
  }

  /** A card's top: the bot's avatar beside the title and its line, as the app's Inbox cards. */
  private head(botId: string | null | undefined, title: string, meta: string) {
    return h(
      "div",
      { className: "item-head" },
      botAvatar(this.name(botId), botId ? this.botAvatars.get(botId) : null, 36),
      h("div", {}, h("h3", {}, title), h("div", { className: "meta" }, meta)),
    );
  }

  private approval(a: Schemas["Approval"]) {
    const card = h(
      "div",
      { className: "item", "data-testid": "approval" },
      this.head(
        a.bot_id,
        a.summary || a.tool_name,
        `${this.name(a.bot_id)} · ${a.risk} risk · ${ago(a.created_at)}`,
      ),
    );
    const decide = async (decision: "approved" | "denied", alwaysAllow = false) => {
      try {
        await this.here.api.decideApproval(a.id, decision, { alwaysAllow });
        card.replaceChildren(
          h("div", { className: "meta" }, decision === "approved" ? "Approved" : "Denied"),
        );
        void updateBadge().catch(() => {});
      } catch (e) {
        card.append(errorBox(e));
      }
    };
    card.append(
      h(
        "div",
        { className: "row" },
        h(
          "button",
          {
            className: "primary",
            "data-testid": "approve",
            onClick: () => void decide("approved"),
          },
          "Approve",
        ),
        h("button", { "data-testid": "deny", onClick: () => void decide("denied") }, "Deny"),
        a.risk !== "high"
          ? h(
              "button",
              { className: "link", onClick: () => void decide("approved", true) },
              "Always allow",
            )
          : "",
      ),
    );
    return card;
  }

  /** The value goes straight to the server's Vault; it never reaches the bot or this page again. */
  private secret(s: Schemas["BotSecretRequest"]) {
    const input = h("input", {
      type: "password",
      autocomplete: "off",
      placeholder: s.kind === "totp" ? "Setup key" : "Value",
      "aria-label": s.name,
    }) as HTMLInputElement;
    const card = h(
      "form",
      { className: "item", "data-testid": "secret" },
      this.head(
        s.bot_id,
        `${this.name(s.bot_id)} asks for ${s.name}`,
        `${s.service} · ${s.reason}`,
      ),
      input,
      h(
        "div",
        { className: "row" },
        h("button", { className: "primary", type: "submit" }, "Send to the server"),
        h("button", { type: "button", onClick: () => void decline() }, "Decline"),
      ),
    );
    const decline = async () => {
      try {
        await this.here.api.unwrap(
          this.here.api.POST("/v1/secrets/requests/{id}/decline", {
            params: { path: { id: s.id } },
            signal: T(),
          }),
        );
        card.replaceChildren(h("div", { className: "meta" }, "Declined"));
      } catch (e) {
        card.append(errorBox(e));
      }
    };
    card.addEventListener("submit", async (ev) => {
      ev.preventDefault();
      if (!input.value) return;
      try {
        await this.here.api.unwrap(
          this.here.api.POST("/v1/secrets/requests/{id}/fulfill", {
            params: { path: { id: s.id } },
            body: { value: input.value },
            signal: T(),
          }),
        );
        input.value = "";
        card.replaceChildren(h("div", { className: "meta" }, "Sent. The bot can use it now."));
      } catch (e) {
        card.append(errorBox(e));
      }
    });
    return card;
  }

  private suggestion(s: Suggestion) {
    const card = h(
      "div",
      { className: "item", "data-testid": "suggestion" },
      this.head(s.bot_id, s.title, `${this.name(s.bot_id)} · ${ago(s.created_at)}`),
      s.body_md ? h("p", {}, s.body_md.slice(0, 280)) : "",
    );
    const act = async (what: "accept" | "dismiss") => {
      try {
        if (what === "accept")
          await this.here.api.unwrap(
            this.here.api.POST("/v1/suggestions/{id}/accept", {
              params: { path: { id: s.id } },
              signal: T(),
            }),
          );
        else
          await this.here.api.unwrap(
            this.here.api.POST("/v1/suggestions/{id}/dismiss", {
              params: { path: { id: s.id } },
              body: { dont_suggest_again: false },
              signal: T(),
            }),
          );
        card.replaceChildren(
          h("div", { className: "meta" }, what === "accept" ? "On it" : "Dismissed"),
        );
      } catch (e) {
        toast(message(e));
      }
    };
    card.append(
      h(
        "div",
        { className: "row" },
        h("button", { className: "primary", onClick: () => void act("accept") }, "Do it"),
        h("button", { onClick: () => void act("dismiss") }, "Not now"),
      ),
    );
    return card;
  }

  private run(r: RunRow) {
    const card = h(
      "div",
      { className: "item", "data-testid": "running" },
      this.head(
        r.bot_id,
        `${this.name(r.bot_id)} is working`,
        `${r.trigger} · started ${ago(r.created_at)}`,
      ),
    );
    card.append(
      h(
        "div",
        { className: "row" },
        h(
          "button",
          {
            onClick: async () => {
              try {
                await this.here.api.cancelRun(r.id);
                card.replaceChildren(h("div", { className: "meta" }, "Stopped"));
              } catch (e) {
                toast(message(e));
              }
            },
          },
          "Stop",
        ),
        h(
          "a",
          {
            href: appUrl(this.here.account, `/bots/${r.bot_id}/runs/${r.id}`),
            target: "_blank",
            rel: "noopener",
          },
          "Watch",
        ),
      ),
    );
    return card;
  }
}
