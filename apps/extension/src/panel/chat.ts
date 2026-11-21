/**
 * The Chat tab (A1–A6, A10, A11, G3, G4): pick a bot and a conversation, ask with the page as
 * context, watch the reply stream in with its cards, stop it, read it aloud. Phase 2 adds the "/"
 * menu (A13), "@" other tabs (A14), pointing at part of the page (A19), this page before (A20),
 * writing for a text box (A16), a live call (A12), quick answers on this computer (F1) and sending
 * less of a long page (F2).
 */
import type { RunEvent, Schemas } from "@casama/client";
import { playAudio } from "../lib/audio.ts";
import { responseError } from "../lib/billing.ts";
import { FEATURES } from "../lib/browser.ts";
import { uploadMedia } from "../lib/capture.ts";
import { renderSurface, type UiAction } from "../lib/cards.ts";
import { ChatFocus } from "../lib/chat-focus.ts";
import {
  type ChipKey,
  messageText,
  type PageContext,
  type SentRecord,
  sentRecord,
} from "../lib/context.ts";
import { bytesLabel, h, sizeLabel } from "../lib/dom.ts";
import { pickElement } from "../lib/inject.ts";
import type { Intent } from "../lib/intent.ts";
import { LiveCall, type ToolCall } from "../lib/live.ts";
import { botAvatar, emptyState } from "../lib/look.ts";
import { markdownNodes } from "../lib/md.ts";
import {
  canAnswerLocally,
  localAnswer,
  type QuickKind,
  quickAnswer,
  quickKinds,
} from "../lib/ondevice.ts";
import { activeTab, blockedReason, readTab, regionScreenshot, screenshot } from "../lib/page.ts";
import { noteConversation, pageEntry, pageKey } from "../lib/page-index.ts";
import { looksLikePdf } from "../lib/pdf.ts";
import { botIsPrivate, carriesPage, privateVerdict, REFUSED } from "../lib/private-model.ts";
import { chipLabel, QUICK_REACTIONS, type Reaction, toggled, withMine } from "../lib/reactions.ts";
import { clock, recordingName, TabRecorder } from "../lib/record.ts";
import { cachedRemoteConfig, promptFor } from "../lib/remote-config.ts";
import { accessToken } from "../lib/session.ts";
import { getSettings, updateSettings } from "../lib/settings.ts";
import { ensureTabs, filterChoices, type TabChoice, tabBlock, tabChoices } from "../lib/tabs.ts";
import { sendLess } from "../lib/trim.ts";
import { appUrl, type Here, rest } from "../lib/workspace.ts";
import { isYouTubeVideo } from "../lib/youtube.ts";
import { putInField } from "./page-tools.ts";
import { errorBox, failureBox, message, T, toast } from "./shared.ts";

/** One per panel: tells the server which chat is on screen, so its replies don't push (D-325). */
let chatFocus: ChatFocus | null = null;

type Bot = Schemas["Bot"];
type Conversation = Schemas["Conversation"];
type Part = Record<string, unknown> & { type?: string };
/** A message the server has, so it can carry reactions. */
const SAVED_ID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

interface ThreadItem {
  id: string;
  role: string;
  content: Part[] | string;
  run_id: string | null;
  created_at: string | null;
  bot_id: string | null;
  /** Grouped by emoji (D-331); people's messages and bots' replies only. */
  reactions?: Reaction[];
}
interface Pending {
  name: string;
  blob: Blob;
  label: string;
}
/** More context for the next message: another tab (A14) or a part of the page pointed at (A19). */
interface Extra {
  label: string;
  text: string;
  kind: "tab" | "part";
}
interface MenuItem {
  label: string;
  hint?: string;
  testid: string;
  run: () => void | Promise<void>;
}

const WRITE_PROMPTS = {
  draft:
    "Write the text for the box I'm typing in on this page, ready to send. Reply with only that text, nothing before or after it.",
  rewrite:
    "Rewrite the text below so it's clearer, keeping its meaning and my voice. Reply with only the new text.",
  shorten: "Make the text below shorter, keeping what matters. Reply with only the new text.",
  reply:
    "Write my reply for the box I'm typing in on this page, in my voice (use what you know about me). Reply with only the reply's text.",
} as const;

const NEW = "__new";
const SENT_KEEP = 300;

export class ChatView {
  readonly el = h("section", { className: "view chat", "data-testid": "chat" });
  private here: Here;
  private bots: Bot[] = [];
  private bot: Bot | null = null;
  private convs: Conversation[] = [];
  private convIdNow: string | null = null;
  private get convId(): string | null {
    return this.convIdNow;
  }
  private set convId(id: string | null) {
    this.convIdNow = id;
    chatFocus ??= new ChatFocus();
    chatFocus.set(this.here.account, id);
  }
  private ctx: PageContext = {};
  private ctxError: unknown = null;
  /** The tab (id and address) the context was last read from; null until the person asks. */
  private readFor: string | null = null;
  /** Bumped on every context change, so a slow read never overwrites a newer one. */
  private ctxToken = 0;
  /** Runs that ended while this panel watched; the thread never re-watches them. */
  private ended = new Set<string>();
  private chips: Record<ChipKey, boolean> = {
    page: true,
    selection: true,
    text: false,
    screenshot: false,
  };
  private attachments: Pending[] = [];
  private extras: Extra[] = [];
  /** A16: the text box a reply goes back into, and the run it's waiting for. */
  private writeFor: { tabId: number; fieldId: string; origin: string } | null = null;
  private writeRun: { tabId: number; fieldId: string; origin: string; runId: string } | null = null;
  private menu = h("div", {
    className: "menu",
    role: "listbox",
    hidden: true,
    "data-testid": "composer-menu",
  });
  private menuItems: MenuItem[] = [];
  private menuIndex = 0;
  private pageBefore = h("div", {
    className: "page-before",
    hidden: true,
    "data-testid": "page-before",
  });
  private quickRow = h("div", { className: "quick", hidden: true, "data-testid": "quick" });
  private quick: QuickKind[] = [];
  private callBar = h("div", { className: "call", hidden: true, "data-testid": "call-bar" });
  /** B12: record this tab. */
  private recorder = new TabRecorder();
  private recordBtn = h(
    "button",
    {
      type: "button",
      className: "icon-btn",
      "data-icon": "record",
      title: "Record this tab, with its sound, for up to two minutes",
      "aria-label": "Record this tab",
      "data-testid": "record-tab",
      onClick: () => void this.toggleRecording(),
    },
    "Record",
  ) as HTMLButtonElement;
  private call: LiveCall | null = null;
  private commands: { name: string; prompt: string }[] | null = null;
  private skills: { name: string; description: string }[] = [];
  private running: { runId: string; abort: AbortController } | null = null;
  private thread = h("div", { className: "thread", "data-testid": "thread" });
  private live = h("div", { className: "live" });
  /** Why a run failed, by run id, so the reason stays under the message after the thread reloads. */
  private failures = new Map<string, { text: string; code: string | null }>();
  private chipRow = h("div", { className: "chips", "data-testid": "chips" });
  private input = h("textarea", {
    placeholder: "Ask about this page…",
    "aria-label": "Message",
    "data-testid": "composer",
  }) as HTMLTextAreaElement;
  private sendBtn = h(
    "button",
    { className: "primary", type: "submit", "data-testid": "send" },
    "Send",
  ) as HTMLButtonElement;
  private topBots = h("select", {
    "aria-label": "Bot",
    "data-testid": "bot-select",
  }) as HTMLSelectElement;
  private topConvs = h("select", {
    "aria-label": "Conversation",
    "data-testid": "conv-select",
  }) as HTMLSelectElement;
  private status = h("div", { className: "notice-line", "data-testid": "status" });

  constructor(here: Here) {
    this.here = here;
    this.build();
  }

  private key() {
    return `${this.here.account.id} ${this.here.org.id}`;
  }

  /** Highlights and chats about a page are kept per account and workspace. */
  private owner() {
    return `${this.here.account.id} ${this.here.org.id}`;
  }

  get hereNow() {
    return this.here;
  }
  get currentBot() {
    return this.bot;
  }

  private build() {
    const fileInput = h("input", {
      type: "file",
      multiple: true,
      hidden: true,
      "data-testid": "file-input",
    }) as HTMLInputElement;
    fileInput.addEventListener("change", () => {
      for (const f of fileInput.files ?? []) this.addAttachment(f, f.name);
      fileInput.value = "";
    });
    const form = h(
      "form",
      { className: "composer" },
      this.chipRow,
      this.quickRow,
      this.menu,
      h(
        "div",
        { className: "composer-box" },
        this.input,
        h(
          "div",
          { className: "composer-tools" },
          h(
            "button",
            {
              type: "button",
              className: "icon-btn",
              "data-icon": "attach",
              title: "Attach a file",
              "aria-label": "Attach a file",
              onClick: () => fileInput.click(),
            },
            "Attach",
          ),
          h(
            "button",
            {
              type: "button",
              className: "icon-btn",
              "data-icon": "region",
              title: "Drag a box over the page",
              "aria-label": "Screenshot part of the page",
              "data-testid": "region",
              onClick: () => void this.region(),
            },
            "Region",
          ),
          // B12 needs tab capture, which Firefox doesn't have.
          FEATURES.record && this.recordBtn,
          h(
            "button",
            {
              type: "button",
              className: "icon-btn",
              "data-icon": "point",
              title: "Point at part of the page",
              "aria-label": "Point at part of the page",
              "data-testid": "point",
              onClick: () => void this.point(),
            },
            "Point",
          ),
          this.micButton(),
          fileInput,
        ),
        this.sendBtn,
      ),
      this.status,
    );
    form.addEventListener("submit", (e) => {
      e.preventDefault();
      if (this.running) void this.stop();
      else void this.send();
    });
    // Starting a message is asking about the page: read it now, once per page.
    this.input.addEventListener("focus", () => void this.refreshContext());
    this.input.addEventListener("keydown", (e) => {
      if (!this.menu.hidden && this.menuItems.length) {
        if (e.key === "ArrowDown" || e.key === "ArrowUp") {
          e.preventDefault();
          const n = this.menuItems.length;
          this.menuIndex = (this.menuIndex + (e.key === "ArrowDown" ? 1 : n - 1)) % n;
          this.drawMenu();
          return;
        }
        if (e.key === "Enter" || e.key === "Tab") {
          e.preventDefault();
          void this.menuItems[this.menuIndex]?.run();
          return;
        }
        if (e.key === "Escape") {
          e.preventDefault();
          this.closeMenu();
          return;
        }
      }
      if (e.key === "Enter" && !e.shiftKey && !e.isComposing) {
        e.preventDefault();
        form.requestSubmit();
      }
    });
    // "/" for page commands and skills (A13), "@" for other tabs (A14).
    this.input.addEventListener("input", () => void this.onTyping());
    // A10: paste pictures, drop files or images dragged from the page.
    this.input.addEventListener("paste", (e) => {
      for (const item of e.clipboardData?.items ?? [])
        if (item.kind === "file") {
          const f = item.getAsFile();
          if (f) this.addAttachment(f, f.name || "pasted.png");
        }
    });
    this.el.addEventListener("dragover", (e) => e.preventDefault());
    this.el.addEventListener("drop", (e) => {
      e.preventDefault();
      for (const f of e.dataTransfer?.files ?? []) this.addAttachment(f, f.name);
      const url = e.dataTransfer?.getData("text/uri-list");
      if (!e.dataTransfer?.files.length && url && /^https?:/.test(url))
        void this.attachImageUrl(url);
    });
    this.topBots.addEventListener("change", () => void this.pickBot(this.topBots.value));
    this.topConvs.addEventListener(
      "change",
      () => void this.pickConv(this.topConvs.value === NEW ? null : this.topConvs.value),
    );
    this.el.append(
      h(
        "div",
        { className: "topbar" },
        this.topBots,
        this.topConvs,
        h(
          "button",
          {
            className: "icon-btn",
            "data-icon": "new",
            title: "New conversation",
            "aria-label": "New conversation",
            "data-testid": "new-chat",
            onClick: () => void this.pickConv(null),
          },
          "New",
        ),
        h(
          "button",
          {
            className: "icon-btn",
            "data-icon": "call",
            title: "Talk with the bot",
            "aria-label": "Start a live call",
            "data-testid": "call",
            onClick: () => void this.startCall(),
          },
          "Call",
        ),
      ),
      this.callBar,
      this.pageBefore,
      this.thread,
      form,
    );
  }

  async load() {
    const s = await getSettings();
    this.chips = { ...s.chips };
    const tabReady = this.tabChanged();
    try {
      this.bots = (
        await this.here.api.unwrap(
          this.here.api.GET("/v1/bots", {
            params: { query: { org_id: this.here.org.id } },
            signal: T(),
          }),
        )
      ).items;
    } catch (e) {
      this.thread.replaceChildren(errorBox(e, () => void this.load()));
      return;
    }
    if (!this.bots.length) {
      this.thread.replaceChildren(
        emptyState({
          mascot: "sleepy",
          badge: "bot",
          message: "No bots in this workspace yet. Create one in the Casama app.",
        }),
      );
      return;
    }
    const last = s.lastBot[this.key()];
    this.topBots.replaceChildren(...this.bots.map((b) => h("option", { value: b.id }, b.name)));
    await this.pickBot(this.bots.find((b) => b.id === last)?.id ?? this.bots[0]!.id);
    await tabReady;
  }

  private async pickBot(id: string) {
    this.bot = this.bots.find((b) => b.id === id) ?? null;
    if (!this.bot) return;
    this.topBots.value = id;
    await updateSettings((s) => {
      s.lastBot[this.key()] = id;
    });
    try {
      this.convs = (
        await this.here.api.unwrap(
          this.here.api.GET("/v1/bots/{id}/conversations", {
            params: { path: { id } },
            signal: T(),
          }),
        )
      ).items.slice(0, 25);
    } catch (e) {
      if (this.bot?.id === id)
        this.thread.replaceChildren(errorBox(e, () => void this.pickBot(id)));
      return;
    }
    // Another bot was picked while this one's conversations loaded.
    if (this.bot?.id !== id) return;
    this.topConvs.replaceChildren(
      h("option", { value: NEW }, "New conversation"),
      ...this.convs.map((c) =>
        h(
          "option",
          { value: c.id },
          (c.title || (c.is_main ? "General" : "Conversation")).slice(0, 60),
        ),
      ),
    );
    const main = this.convs.find((c) => c.is_main) ?? this.convs[0];
    await this.pickConv(main?.id ?? null);
  }

  private async pickConv(id: string | null) {
    this.running?.abort.abort();
    this.running = null;
    this.setRunning(false);
    this.convId = id;
    this.topConvs.value = id ?? NEW;
    await this.loadThread();
  }

  private async loadThread() {
    this.live.replaceChildren();
    if (!this.convId) {
      this.thread.replaceChildren(
        // The bot itself over the line, as the app's empty chat shows it.
        emptyState({
          art: botAvatar(this.bot?.name ?? "Bot", this.bot?.avatar_url, 72),
          badge: "sparkles",
          testid: "empty-thread",
          message: `Ask ${this.bot?.name ?? "a bot"} about this page, or anything else.`,
        }),
        this.live,
      );
      return;
    }
    const conv = this.convId;
    let items: ThreadItem[];
    try {
      items = (
        (await this.here.api.unwrap(
          this.here.api.GET("/v1/conversations/{id}/thread", {
            params: { path: { id: this.convId }, query: { limit: 40 } },
            signal: T(),
          }),
        )) as unknown as { items: ThreadItem[] }
      ).items;
    } catch (e) {
      if (this.convId === conv)
        this.thread.replaceChildren(
          errorBox(e, () => void this.loadThread()),
          this.live,
        );
      return;
    }
    const sent = await sentRecords();
    // Another conversation was picked while this one loaded.
    if (this.convId !== conv) return;
    const answered = new Set<string>();
    for (const m of items)
      if (m.role === "user" && Array.isArray(m.content))
        for (const p of m.content)
          if (p.type === "ui_action" && typeof p.surface_id === "string")
            answered.add(p.surface_id);
    this.thread.replaceChildren(
      ...items
        .filter((m) => m.role === "user" || m.role === "assistant")
        .map((m) => this.messageEl(m, sent[m.id], answered))
        // Only a name left (a card answer, an unknown part): nothing to show.
        .filter((el) => [...el.children].some((c) => !c.classList.contains("who"))),
      this.live,
    );
    this.thread.scrollTop = this.thread.scrollHeight;
    // Came back while the bot was still answering: catch up (§9.3).
    const lastMsg = items.at(-1);
    if (
      lastMsg?.role === "user" &&
      lastMsg.run_id &&
      !this.ended.has(lastMsg.run_id) &&
      lastMsg.created_at &&
      Date.now() - new Date(lastMsg.created_at).getTime() < 15 * 60_000
    )
      void this.watch(lastMsg.run_id);
  }

  private messageEl(
    m: ThreadItem,
    record: SentRecord | undefined,
    answered: Set<string>,
  ): HTMLElement {
    const parts: Part[] =
      typeof m.content === "string" ? [{ type: "text", text: m.content }] : m.content;
    const text = parts
      .filter((p) => p.type === "text")
      .map((p) => String(p.text ?? ""))
      .join("");
    const el = h("div", { className: `msg ${m.role}`, "data-testid": `msg-${m.role}` });
    if (m.role === "assistant")
      el.append(
        h(
          "div",
          { className: "who" },
          this.bots.find((b) => b.id === m.bot_id)?.name ?? this.bot?.name ?? "Bot",
        ),
      );
    // The person's own message shows what they typed; the context block folds into "What was sent".
    const shown =
      m.role === "assistant"
        ? text
        : record
          ? text.slice(0, record.typedChars ?? text.length)
          : text;
    // No words (only a card, a file, a page or a creation): no empty bubble.
    if (shown.trim()) {
      const body = h("div", { className: "body" });
      if (m.role === "assistant") body.append(markdownNodes(shown));
      else body.textContent = shown;
      el.append(body);
    }
    for (const p of parts) {
      if (p.type === "file") el.append(this.fileEl(p));
      if (p.type === "ui" && typeof p.surface_id === "string")
        el.append(
          renderSurface(p.surface_id, (p.messages as Record<string, unknown>[]) ?? [], {
            answered: answered.has(p.surface_id),
            onAction: (t, a) => this.answer(t, a),
            openUrl: appUrl(this.here.account, `/bots/${this.bot?.id}/chat`),
          }),
        );
      if (p.type === "creation")
        el.append(
          h(
            "a",
            {
              className: "file-chip",
              href: appUrl(this.here.account, "/library"),
              target: "_blank",
              rel: "noopener",
            },
            String(p.title || p.name || "Made a file"),
          ),
        );
      if (p.type === "page" && typeof p.page_id === "string")
        el.append(
          h(
            "a",
            {
              className: "file-chip",
              href: appUrl(this.here.account, `/pages`),
              target: "_blank",
              rel: "noopener",
            },
            `Page: ${String(p.title ?? "Open")}`,
          ),
        );
    }
    if (SAVED_ID.test(m.id)) el.append(this.reactionsEl(m.id, m.reactions ?? []));
    if (m.role === "assistant" && text.trim()) el.append(this.replyActions(m.id, text));
    if (m.role === "user" && record) el.append(this.sentDetails(record, m.run_id));
    const failed = m.role === "user" && m.run_id ? this.failures.get(m.run_id) : undefined;
    if (failed) el.append(failureBox(failed.text, failed.code, "run-failed"));
    return el;
  }

  /** Reactions under a message (D-331): a chip per emoji (yours outlined; a click adds that one
   * or takes yours back) and a React button with the six quick ones. */
  private reactionsEl(messageId: string, groups: Reaction[]): HTMLElement {
    const conv = this.convId;
    const row = h("div", { className: "reactions", "data-testid": "reactions" });
    const react = async (emoji: string | null) => {
      if (!conv) return;
      const before = groups;
      row.replaceWith(this.reactionsEl(messageId, withMine(before, emoji)));
      const shown = () =>
        this.thread.querySelector<HTMLElement>(`.reactions[data-message="${messageId}"]`);
      try {
        const path = { params: { path: { id: conv, message_id: messageId } }, signal: T() };
        const out = (await this.here.api.unwrap(
          emoji === null
            ? this.here.api.DELETE("/v1/conversations/{id}/messages/{message_id}/reaction", path)
            : this.here.api.PUT("/v1/conversations/{id}/messages/{message_id}/reaction", {
                ...path,
                body: { emoji },
              }),
        )) as { reactions: Reaction[] };
        if (this.convId === conv) shown()?.replaceWith(this.reactionsEl(messageId, out.reactions));
      } catch (e) {
        if (this.convId === conv) shown()?.replaceWith(this.reactionsEl(messageId, before));
        toast(message(e));
      }
    };
    row.dataset.message = messageId;
    for (const g of groups)
      row.append(
        h(
          "button",
          {
            className: g.mine ? "reaction mine" : "reaction",
            "data-testid": `reaction-${g.emoji}`,
            "aria-label": chipLabel(g),
            "aria-pressed": g.mine ? "true" : "false",
            onClick: () => void react(toggled(groups, g.emoji)),
          },
          h("span", {}, g.emoji),
          g.count > 1 || g.mine ? h("span", { className: "count" }, String(g.count)) : null,
        ),
      );
    const strip = h(
      "div",
      { className: "quick-reactions", hidden: true, role: "group", "aria-label": "Reactions" },
      ...QUICK_REACTIONS.map((e) =>
        h(
          "button",
          {
            className: groups.some((g) => g.mine && g.emoji === e) ? "mine" : "",
            "data-testid": `quick-${e}`,
            "aria-label": `React with ${e}`,
            onClick: () => void react(toggled(groups, e)),
          },
          e,
        ),
      ),
    );
    row.append(
      h(
        "button",
        {
          className: "reaction add",
          "data-testid": "react",
          title: "React",
          "aria-label": "React",
          onClick: () => {
            strip.hidden = !strip.hidden;
          },
        },
        "☺+",
      ),
      strip,
    );
    return row;
  }

  private fileEl(p: Part): HTMLElement {
    const path = String(p.path ?? "");
    const name = String(p.name ?? "file");
    const mime = String(p.mime_type ?? "");
    const id = /^media:([0-9a-f-]{36})$/i.exec(path)?.[1];
    if (id && mime.startsWith("image/")) {
      const img = h("img", { className: "thumb", alt: name }) as HTMLImageElement;
      void mediaUrl(this.here, id).then((u) => {
        if (u) img.src = u;
      });
      return img;
    }
    return h(
      "span",
      { className: "file-chip" },
      `${name}${typeof p.size === "number" ? ` · ${bytesLabel(p.size)}` : ""}`,
    );
  }

  private replyActions(messageId: string, text: string) {
    return h(
      "div",
      { className: "msg-actions" },
      h(
        "button",
        {
          className: "link",
          onClick: () => void navigator.clipboard.writeText(text).then(() => toast("Copied")),
        },
        "Copy",
      ),
      h(
        "button",
        {
          className: "link",
          "data-testid": "read-aloud",
          onClick: async () => {
            try {
              const token = await accessToken(this.here.account.id);
              const res = await fetch(
                `${this.here.account.server}/v1/messages/${messageId}/speech`,
                { headers: { authorization: `Bearer ${token}` }, signal: T(60_000) },
              );
              if (!res.ok) throw await responseError(res);
              await playAudio(
                await res.arrayBuffer(),
                res.headers.get("content-type") ?? "audio/mpeg",
              );
            } catch (e) {
              toast(message(e));
            }
          },
        },
        "Read aloud",
      ),
    );
  }

  /** G4: what went with the message, and the run's timeline in the app. */
  private sentDetails(r: SentRecord, runId: string | null) {
    return h(
      "details",
      { className: "sent", "data-testid": "what-was-sent" },
      h("summary", {}, "What was sent"),
      h("div", {}, r.parts.length ? r.parts.join(" · ") : "Only your message"),
      r.url ? h("div", {}, r.url) : "",
      h("div", {}, sizeLabel(r.chars)),
      runId && this.bot
        ? h(
            "a",
            {
              href: appUrl(this.here.account, `/bots/${this.bot.id}/runs/${runId}`),
              target: "_blank",
              rel: "noopener",
            },
            "Open the run's timeline",
          )
        : "",
    );
  }

  // -------------------------------------------------------------------------
  // Context chips (A3) and attachments (A10)

  /**
   * The open tab changed: chips from its address and title only, with the guard's verdict. Nothing
   * is read from the page until the person asks (§11).
   */
  async tabChanged() {
    const token = ++this.ctxToken;
    const tab = await activeTab();
    const blocked = await blockedReason(tab?.url);
    if (token !== this.ctxToken) return;
    const textKind = looksLikePdf(tab?.url)
      ? "pdf"
      : isYouTubeVideo(tab?.url)
        ? "transcript"
        : "page";
    this.ctx = blocked
      ? { url: tab?.url, title: tab?.title, blocked }
      : { url: tab?.url, title: tab?.title, textKind };
    this.ctxError = null;
    this.readFor = null;
    this.extras = this.extras.filter((x) => x.kind === "tab");
    this.drawChips();
    void this.drawPageBefore();
    if (document.activeElement === this.input) await this.refreshContext();
  }

  /** Reads the open tab, because the person is asking about it: once per page unless [fresh]. */
  async refreshContext(fresh = false) {
    const tab = await activeTab();
    const key = `${tab?.id} ${tab?.url}`;
    if (!fresh && this.readFor === key) return;
    const token = ++this.ctxToken;
    let ctx: PageContext;
    let error: unknown = null;
    try {
      ctx = await readTab(tab);
    } catch (e) {
      ctx = { url: tab?.url, title: tab?.title };
      error = e;
    }
    if (token !== this.ctxToken) return;
    this.ctx = ctx;
    this.ctxError = error;
    this.readFor = key;
    this.drawChips();
  }

  private chip(key: ChipKey, label: string, title?: string) {
    return h(
      "button",
      {
        type: "button",
        className: "chip",
        "aria-pressed": String(this.chips[key]),
        "data-testid": `chip-${key}`,
        title: title ?? label,
        onClick: () => {
          this.chips[key] = !this.chips[key];
          this.drawChips();
          // Switching a chip on asks for that part of the page: read it now.
          if (this.chips[key]) void this.refreshContext();
        },
      },
      label,
    );
  }

  private drawChips() {
    const c = this.ctx;
    const row: (Node | string)[] = [];
    if (c.blocked)
      row.push(h("span", { className: "notice-line", "data-testid": "blocked" }, c.blocked));
    else {
      if (c.url) row.push(this.chip("page", c.title ? `Page: ${c.title}` : "Page address", c.url));
      if (c.selection?.trim())
        row.push(this.chip("selection", `Selection · ${sizeLabel(c.selection.trim().length)}`));
      const kind =
        c.textKind === "pdf"
          ? "PDF text"
          : c.textKind === "transcript"
            ? "Transcript"
            : "Page text";
      // Before it's read, the chip offers the text without a size; after, only if there is some.
      if (c.text?.trim()) row.push(this.chip("text", `${kind} · ${sizeLabel(c.text.length)}`));
      else if (!this.readFor && c.url && /^(https?|file):/.test(c.url))
        row.push(this.chip("text", kind));
      if (c.url) row.push(this.chip("screenshot", "Screenshot"));
    }
    for (const [i, x] of this.extras.entries())
      row.push(
        h(
          "button",
          {
            type: "button",
            className: "chip",
            "aria-pressed": "true",
            "data-testid": x.kind === "tab" ? "extra-tab" : "extra-part",
            title: "Remove",
            onClick: () => {
              this.extras.splice(i, 1);
              this.drawChips();
            },
          },
          `${x.kind === "tab" ? "Tab" : "This"}: ${x.label.slice(0, 40)} · ${sizeLabel(x.text.length)}`,
          h("span", { className: "x", "aria-hidden": "true" }, "×"),
        ),
      );
    for (const [i, a] of this.attachments.entries())
      row.push(
        h(
          "button",
          {
            type: "button",
            className: "chip",
            "aria-pressed": "true",
            "data-testid": "attachment",
            title: "Remove",
            onClick: () => {
              this.attachments.splice(i, 1);
              this.drawChips();
            },
          },
          `${a.label} · ${bytesLabel(a.blob.size)}`,
          h("span", { className: "x", "aria-hidden": "true" }, "×"),
        ),
      );
    if (this.ctxError) row.push(errorBox(this.ctxError, () => void this.refreshContext()));
    this.chipRow.replaceChildren(...row);
    void this.drawQuick();
  }

  private addAttachment(blob: Blob, name: string) {
    if (this.attachments.length >= 10) return toast("Ten files at most.");
    if (blob.size > 50 * 1024 * 1024) return toast("Files are limited to 50 MB.");
    this.attachments.push({ name, blob, label: name });
    this.drawChips();
  }

  private async attachImageUrl(url: string) {
    try {
      const res = await fetch(url, { signal: T() });
      if (!res.ok) throw new Error(`The image couldn't be loaded (${res.status}).`);
      const blob = await res.blob();
      const raw = new URL(url).pathname.split("/").pop() || "image";
      let decoded = raw;
      try {
        decoded = decodeURIComponent(raw);
      } catch {
        // Keep the raw segment when percent-encoding is malformed.
      }
      const name = decoded || "image";
      this.addAttachment(blob, name);
    } catch (e) {
      toast(message(e));
    }
  }

  /** B12: starts or stops recording the tab in view; the video is attached to the next message. */
  private async toggleRecording() {
    if (this.recorder.recording) {
      this.recorder.stop();
      return;
    }
    const tab = await activeTab();
    if (!tab?.id) return toast("No tab open.");
    const blocked = await blockedReason(tab.url);
    if (blocked) return toast(blocked);
    try {
      this.recordBtn.setAttribute("aria-pressed", "true");
      const video = await this.recorder.start(tab.id, (sec) => {
        this.recordBtn.textContent = `Stop ${clock(sec)}`;
      });
      if (video.size) this.addAttachment(video, recordingName());
      else toast("Nothing was recorded.");
    } catch (e) {
      toast(message(e));
    } finally {
      this.recordBtn.textContent = "Record";
      this.recordBtn.removeAttribute("aria-pressed");
    }
  }

  private async region() {
    const tab = await activeTab();
    if (!tab) return;
    try {
      const shot = await regionScreenshot(tab);
      if (shot) this.addAttachment(shot, "Part of the page.png");
    } catch (e) {
      this.ctxError = e;
      this.drawChips();
    }
  }

  // -------------------------------------------------------------------------
  // Voice (A11): dictation through the server's transcription

  private micButton() {
    let rec: MediaRecorder | null = null;
    const btn = h(
      "button",
      {
        type: "button",
        className: "icon-btn",
        "data-icon": "mic",
        title: "Dictate",
        "aria-label": "Dictate a message",
        "data-testid": "mic",
      },
      "Mic",
    ) as HTMLButtonElement;
    btn.addEventListener("click", async () => {
      if (rec) {
        rec.stop();
        return;
      }
      let stream: MediaStream;
      try {
        stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      } catch {
        // The side panel can't ask for the microphone itself: Settings asks once, then it works here.
        toast("Allow the microphone in the tab that opens, then try again.");
        void chrome.tabs.create({ url: chrome.runtime.getURL("options/options.html#microphone") });
        return;
      }
      const chunks: Blob[] = [];
      rec = new MediaRecorder(stream, { mimeType: "audio/webm" });
      rec.ondataavailable = (e) => chunks.push(e.data);
      rec.onstop = async () => {
        for (const t of stream.getTracks()) t.stop();
        rec = null;
        btn.textContent = "Mic";
        btn.setAttribute("aria-pressed", "false");
        if (!this.bot) return;
        this.status.textContent = "Writing down what you said…";
        try {
          const token = await accessToken(this.here.account.id);
          const res = await fetch(
            `${this.here.account.server}/v1/voice/transcribe?bot_id=${this.bot.id}`,
            {
              method: "POST",
              headers: { authorization: `Bearer ${token}`, "content-type": "audio/webm" },
              body: new Blob(chunks, { type: "audio/webm" }),
              signal: T(60_000),
            },
          );
          if (!res.ok) throw await responseError(res);
          const { text } = (await res.json()) as { text: string };
          this.input.value = `${this.input.value}${this.input.value ? " " : ""}${text}`;
          this.input.focus();
          this.status.textContent = "";
        } catch (e) {
          this.status.replaceChildren(errorBox(e));
        }
      };
      rec.start();
      btn.textContent = "Stop";
      btn.setAttribute("aria-pressed", "true");
    });
    return btn;
  }

  // -------------------------------------------------------------------------
  // Sending and the live reply

  private setRunning(on: boolean) {
    this.sendBtn.textContent = on ? "Stop" : "Send";
    this.sendBtn.dataset.testid = on ? "stop" : "send";
    this.sendBtn.className = on ? "" : "primary";
  }

  /** Applies something started from a menu, a shortcut or the address bar. */
  async apply(intent: Intent) {
    if (intent.write && intent.tabId !== undefined) return this.write(intent.write, intent.tabId);
    await this.refreshContext();
    if (intent.readText) this.chips.text = true;
    if (intent.selection) {
      this.ctx = { ...this.ctx, selection: intent.selection };
      this.chips.selection = true;
    }
    if (intent.linkUrl) this.input.value = `${intent.text ?? ""}\n${intent.linkUrl}`.trim();
    else if (intent.text) this.input.value = intent.text;
    if (intent.imageUrl) await this.attachImageUrl(intent.imageUrl);
    if (intent.attach === "screenshot") this.chips.screenshot = true;
    if (intent.attach === "region") await this.region();
    this.drawChips();
    this.input.focus();
    if (intent.send && this.input.value.trim()) await this.send();
  }

  private async send() {
    // A16: the text box this message writes for, if any; only this send may claim it.
    const write = this.writeFor;
    this.writeFor = null;
    const typed = this.input.value.trim();
    if (!typed && !this.attachments.length) return;
    const bot = this.bot;
    if (!bot) return;
    this.sendBtn.disabled = true;
    this.status.textContent = "";
    try {
      // What's on the page now: the selection may have changed since the chips were drawn.
      await this.refreshContext(true);
      // F3: content kept to private models goes only to bots on them, else stays on this computer.
      const rule = !!(
        (await chrome.storage.local.get("browserDevice")).browserDevice as
          | { privateModel?: boolean }
          | undefined
      )?.privateModel;
      const carries = carriesPage(
        this.chips,
        this.ctx,
        this.extras.length + this.attachments.length,
      );
      if (rule && carries) {
        const verdict = privateVerdict({
          rule,
          carries,
          botPrivate: await botIsPrivate(this.here.api, bot.id).catch(() => false),
          localModel: await canAnswerLocally(),
        });
        if (verdict === "refuse") {
          this.status.textContent = REFUSED;
          return;
        }
        if (verdict === "local") {
          await this.answerLocally(typed);
          return;
        }
      }
      const tab = await activeTab();
      const files = [...this.attachments];
      if (this.chips.screenshot && tab && !this.ctx.blocked)
        files.unshift({ name: "Screenshot.png", blob: await screenshot(tab), label: "Screenshot" });
      const uploaded: Schemas["MessageAttachment"][] = [];
      for (const f of files) {
        this.status.textContent = `Sending ${f.label}…`;
        const r = await uploadMedia(
          this.here.account,
          { orgId: this.here.org.id, name: f.name, purpose: "attachment" },
          f.blob,
          f.blob.type || "application/octet-stream",
        );
        uploaded.push({ path: r.path, name: r.name, mime_type: r.mime_type, size: r.size });
      }
      // F2: a long page goes trimmed to the parts that matter to the question.
      let ctx = this.ctx;
      let trimmedFrom = 0;
      if (
        this.chips.text &&
        ctx.text &&
        ctx.textKind === "page" &&
        (await getSettings()).sendLess
      ) {
        const t = sendLess(ctx.text, typed);
        if (t.trimmed) {
          ctx = { ...ctx, text: t.text };
          trimmedFrom = t.from;
        }
      }
      // Nothing from a blocked page goes, not even a part pointed at earlier; other tabs were each
      // checked when added.
      const extras = this.extras.filter((x) => !ctx.blocked || x.kind === "tab");
      const text = [
        messageText(typed, ctx, this.chips),
        ...extras.map((x) =>
          x.kind === "tab" ? x.text : `The part of the page I pointed at (${x.label}):\n${x.text}`,
        ),
      ]
        .filter(Boolean)
        .join("\n\n");
      // A20: remember the page a conversation started from, to find it again from that page.
      const source =
        !ctx.blocked &&
        this.chips.page &&
        ctx.url &&
        /^https?:/.test(ctx.url) &&
        ctx.url.length <= 2000
          ? ctx.url
          : undefined;
      if (!this.convId) {
        const conv = await this.here.api.unwrap(
          this.here.api.POST("/v1/conversations", {
            body: { bot_id: bot.id, ...(source ? { source_url: source } : {}) },
            signal: T(),
          }),
        );
        if (source)
          await noteConversation(source, this.owner(), {
            id: conv.id,
            botId: bot.id,
            title: (typed || "Conversation").slice(0, 80),
          }).catch(() => {});
        this.convId = conv.id;
        this.convs.unshift(conv);
        this.topConvs.append(
          h("option", { value: conv.id }, (typed || "Conversation").slice(0, 60)),
        );
        this.topConvs.value = conv.id;
      }
      const sent = await this.here.api.unwrap(
        this.here.api.POST("/v1/conversations/{id}/messages", {
          params: { path: { id: this.convId } },
          body: { text: text || " ", ...(uploaded.length ? { attachments: uploaded } : {}) },
          signal: T(),
        }),
      );
      const record = {
        ...sentRecord(ctx, this.chips, text, [
          ...extras.map((x) =>
            x.kind === "tab" ? `Tab: ${x.label}` : `Part of the page: ${x.label}`,
          ),
          ...files.map((f) => f.label),
        ]),
        typedChars: typed.length,
        runId: sent.run_id,
        botId: bot.id,
      };
      if (trimmedFrom)
        record.parts = record.parts.map((p) =>
          p === "Page text"
            ? `Page text, trimmed from ${sizeLabel(trimmedFrom)} on this computer`
            : p,
        );
      if (write) this.writeRun = { ...write, runId: sent.run_id };
      // The message is sent: clear the composer first, so a failure below can't invite a resend.
      this.input.value = "";
      this.attachments = [];
      this.extras = [];
      this.status.textContent = "";
      await saveSent(sent.message_id, record).catch(() => {});
      const s = await getSettings();
      this.chips = { ...s.chips };
      this.drawChips();
      await this.loadThread();
      if (!(sent as { joined?: boolean }).joined) void this.watch(sent.run_id);
    } catch (e) {
      this.status.replaceChildren(errorBox(e));
    } finally {
      this.sendBtn.disabled = false;
    }
  }

  private async answer(text: string, action: UiAction) {
    if (!this.convId) return;
    try {
      const sent = await this.here.api.unwrap(
        this.here.api.POST("/v1/conversations/{id}/messages", {
          params: { path: { id: this.convId } },
          body: { text, ui_action: action as never },
          signal: T(),
        }),
      );
      await this.loadThread();
      void this.watch(sent.run_id);
    } catch (e) {
      toast(message(e));
    }
  }

  private async stop() {
    const r = this.running;
    if (!r) return;
    try {
      await this.here.api.cancelRun(r.runId);
    } catch (e) {
      // Already finished: nothing to stop.
      if (!/finished/i.test(message(e))) toast(message(e));
    }
  }

  /** Streams a run's reply into the thread (§9.3), then reloads the thread. */
  async watch(runId: string) {
    if (this.running?.runId === runId) return;
    this.running?.abort.abort();
    const abort = new AbortController();
    this.running = { runId, abort };
    this.setRunning(true);
    const bubble = h(
      "div",
      { className: "msg assistant", "data-testid": "live-reply" },
      h("div", { className: "who" }, this.bot?.name ?? "Bot"),
    );
    const body = h("div", { className: "body typing" });
    const extras = h("div");
    bubble.append(body, extras);
    this.live.replaceChildren(bubble);
    let text = "";
    let frame = 0;
    const paint = () => {
      frame = 0;
      body.replaceChildren(markdownNodes(text));
      this.thread.scrollTop = this.thread.scrollHeight;
    };
    try {
      for await (const e of this.here.api.watchRun(runId, { signal: abort.signal })) {
        this.onEvent(e as RunEvent, extras, (t) => {
          text += t;
          if (!frame) frame = requestAnimationFrame(paint);
        });
      }
    } catch (e) {
      if (!abort.signal.aborted) extras.append(errorBox(e));
    } finally {
      if (this.running?.runId === runId) {
        this.running = null;
        this.setRunning(false);
      }
    }
    if (!abort.signal.aborted) {
      this.ended.add(runId);
      const w = this.writeRun?.runId === runId ? this.writeRun : null;
      if (w) this.writeRun = null;
      await this.loadThread();
      // A16: the reply goes into the page only when the person says so, after reading it here.
      const reply = text.trim();
      if (w && reply) this.thread.insertBefore(this.insertCard(w, reply), this.live);
    }
  }

  private insertCard(w: { tabId: number; fieldId: string; origin: string }, reply: string) {
    const card = h(
      "div",
      { className: "item", "data-testid": "insert-card" },
      h(
        "div",
        { className: "meta" },
        "Read it first: it goes into the page's text box, and the page can see it.",
      ),
    );
    card.append(
      h(
        "div",
        { className: "row" },
        h(
          "button",
          {
            className: "primary",
            "data-testid": "insert-reply",
            onClick: async () => {
              try {
                // Still the same site, and still allowed?
                const tab = await chrome.tabs.get(w.tabId).catch(() => undefined);
                if (!tab?.url || originOf(tab.url) !== w.origin)
                  throw new Error("That page has changed; copy the reply instead.");
                const blocked = await blockedReason(tab.url);
                if (blocked) throw new Error(blocked);
                const ok = await putInField(w.tabId, w.fieldId, reply);
                card.replaceChildren(
                  h(
                    "div",
                    { className: "meta" },
                    ok
                      ? "Put into the text box. Check it, then send it yourself."
                      : "The text box is gone; copy the reply instead.",
                  ),
                );
              } catch (e) {
                toast(message(e));
              }
            },
          },
          "Put it in the text box",
        ),
        h("button", { onClick: () => card.remove() }, "Not now"),
      ),
    );
    return card;
  }

  private onEvent(e: RunEvent, extras: HTMLElement, append: (t: string) => void) {
    const p = e.payload as Record<string, unknown>;
    switch (e.type) {
      case "message.delta":
        append(String(p.text ?? ""));
        break;
      case "tool.started":
        this.status.textContent = `Working: ${String(p.tool ?? "")}`;
        break;
      case "ui.shown":
        extras.append(
          renderSurface(String(p.surface_id), (p.messages as Record<string, unknown>[]) ?? [], {
            onAction: (t, a) => this.answer(t, a),
            openUrl: appUrl(this.here.account, `/bots/${this.bot?.id}/chat`),
          }),
        );
        break;
      case "approval.requested":
        extras.append(this.approvalCard(String(p.approval_id), String(p.tool), String(p.risk)));
        break;
      case "secret.requested":
        extras.append(
          h(
            "p",
            { className: "notice-line" },
            `The bot asks for ${String(p.name)}. Answer it in the Inbox tab.`,
          ),
        );
        break;
      case "run.failed": {
        const why = String(p.message ?? "The run failed.");
        const code = typeof p.error_code === "string" ? p.error_code : null;
        if (e.run_id) this.failures.set(String(e.run_id), { text: why, code });
        extras.append(failureBox(why, code));
        break;
      }
      case "run.cancelled":
        extras.append(h("p", { className: "notice-line" }, "Stopped."));
        break;
      case "run.completed":
        this.status.textContent = "";
        break;
    }
  }

  // -------------------------------------------------------------------------
  // Phase 2

  /** A16: write for a text box in the page; the reply goes back into it when it's done. */
  private async write(w: NonNullable<Intent["write"]>, tabId: number) {
    const tab = await chrome.tabs.get(tabId).catch(() => undefined);
    const blocked = await blockedReason(tab?.url);
    if (blocked) return toast(blocked);
    if (!tab?.url) return;
    await this.refreshContext(true);
    // The page read says no (a password or card field, or a blocked address after a redirect), or
    // it's a different page than the one the box is on: nothing is written or sent.
    if (this.ctx.blocked) return toast(this.ctx.blocked);
    if (!this.ctx.url || originOf(this.ctx.url) !== originOf(tab.url)) return;
    this.chips.page = true;
    // Drafts and replies need what's on the page (the thread being answered).
    if (w.mode === "draft" || w.mode === "reply") this.chips.text = true;
    const box = w.text.trim();
    // The server's owner may reword these (D-372); the built-in text otherwise.
    const ask = promptFor(
      await cachedRemoteConfig(this.here.account.server),
      `write.${w.mode}`,
      WRITE_PROMPTS[w.mode],
    );
    this.input.value =
      w.mode === "rewrite" || w.mode === "shorten"
        ? `${ask}\n\nText:\n${box}`
        : `${ask}${box ? `\n\nWhat's in the box now:\n${box}` : ""}`;
    this.writeFor = { tabId, fieldId: w.fieldId, origin: originOf(tab.url) };
    this.drawChips();
    await this.send();
  }

  /** Other context to send with the next message (also used by "send these tabs", B9). */
  addExtra(x: Extra) {
    if (this.extras.some((e) => e.kind === x.kind && e.label === x.label && e.text === x.text))
      return;
    this.extras.push(x);
    this.drawChips();
  }

  /** A19: the person clicks part of the page to mean "this". */
  private async point() {
    const tab = await activeTab();
    if (!tab?.id) return;
    const blocked = await blockedReason(tab.url);
    if (blocked) return toast(blocked);
    // A page with a password or card field sends nothing, pointed at or not.
    await this.refreshContext(true);
    if (this.ctx.blocked) return toast(this.ctx.blocked);
    try {
      await chrome.tabs.update(tab.id, { active: true });
      const [r] = await chrome.scripting.executeScript({
        target: { tabId: tab.id },
        func: pickElement,
        args: ["Click the part of the page you mean"],
      });
      const picked = r?.result;
      if (!picked?.text) return;
      this.addExtra({ kind: "part", label: picked.label, text: picked.text });
      this.input.focus();
    } catch (e) {
      this.ctxError = /permission|Cannot access/i.test(message(e))
        ? new Error(
            "Casama can't reach this tab. Click the Casama button first, or allow this site in Settings.",
          )
        : e;
      this.drawChips();
    }
  }

  // "/" and "@" menus -------------------------------------------------------

  private async onTyping() {
    const v = this.input.value;
    const slash = /^\/([\w-]*)$/.exec(v);
    const at = /(?:^|\s)@([^@\n]*)$/.exec(v);
    if (slash) return this.slashMenu(slash[1]!.toLowerCase());
    if (at) return this.atMenu(at[1]!, at.index + (at[0].startsWith("@") ? 0 : 1));
    this.closeMenu();
  }

  private async loadCommands() {
    if (this.commands) return;
    try {
      this.commands = (
        await this.here.api.unwrap(this.here.api.GET("/v1/me/page-commands", { signal: T() }))
      ).items.map((c) => ({ name: c.name, prompt: c.prompt }));
    } catch {
      this.commands = [];
    }
    if (!this.bot) return;
    try {
      const res = await rest(
        this.here.account,
        `skills?select=name,description&enabled=eq.true&org_id=eq.${this.here.org.id}&or=(bot_id.eq.${this.bot.id},bot_id.is.null)&order=name&limit=50`,
      );
      this.skills = (await res.json()) as { name: string; description: string }[];
    } catch {
      this.skills = [];
    }
  }

  private async slashMenu(q: string) {
    await this.loadCommands();
    if (!/^\/[\w-]*$/.test(this.input.value)) return;
    const items: MenuItem[] = [
      ...(this.commands ?? [])
        .filter((c) => c.name.toLowerCase().includes(q))
        .map((c) => ({
          label: `/${c.name}`,
          hint: c.prompt.slice(0, 60),
          testid: "menu-command",
          run: () => {
            this.input.value = c.prompt;
            this.closeMenu();
            this.input.focus();
          },
        })),
      ...this.skills
        .filter((sk) => sk.name.includes(q))
        .map((sk) => ({
          label: `/${sk.name}`,
          hint: `Skill · ${sk.description.slice(0, 50)}`,
          testid: "menu-skill",
          run: () => {
            this.input.value = `Use your ${sk.name} skill: `;
            this.closeMenu();
            this.input.focus();
          },
        })),
    ];
    if (!items.length)
      items.push({
        label: "No page commands yet",
        hint: "Add them in Settings",
        testid: "menu-empty",
        run: () => {
          this.closeMenu();
          void chrome.tabs.create({
            url: chrome.runtime.getURL("options/options.html#page-commands"),
          });
        },
      });
    this.openMenu(items);
  }

  private tabList: TabChoice[] | null = null;
  private async atMenu(q: string, start: number) {
    if (!this.tabList) {
      if (!(await ensureTabs())) {
        this.closeMenu();
        return toast("Casama needs to see your tabs' titles to add one. Try @ again to allow it.");
      }
      this.tabList = await tabChoices((await activeTab())?.id);
      setTimeout(() => {
        this.tabList = null;
      }, 30_000);
    }
    const items = filterChoices(this.tabList, q).map((c) => ({
      label: c.label.slice(0, 60),
      hint:
        c.kind === "group"
          ? c.tabs
              .map((t) => t.title)
              .join(", ")
              .slice(0, 60)
          : c.tabs[0]?.url?.slice(0, 60),
      testid: "menu-tab",
      run: async () => {
        this.input.value = this.input.value.slice(0, start).trimEnd();
        this.closeMenu();
        this.input.focus();
        for (const t of c.tabs.slice(0, 10)) {
          const b = await tabBlock(t);
          if (b.skipped) toast(`${b.label.slice(0, 40)}: ${b.skipped}`);
          else this.addExtra({ kind: "tab", label: b.label, text: b.text });
        }
      },
    }));
    if (!items.length) return this.closeMenu();
    this.openMenu(items);
  }

  private openMenu(items: MenuItem[]) {
    this.menuItems = items;
    this.menuIndex = 0;
    this.drawMenu();
  }

  private drawMenu() {
    this.menu.hidden = false;
    this.menu.replaceChildren(
      ...this.menuItems.map((it, i) =>
        h(
          "button",
          {
            type: "button",
            role: "option",
            className: "menu-item",
            "aria-selected": String(i === this.menuIndex),
            "data-testid": it.testid,
            onMousedown: (e: Event) => e.preventDefault(),
            onClick: () => void it.run(),
          },
          h("span", {}, it.label),
          it.hint ? h("span", { className: "hint" }, it.hint) : "",
        ),
      ),
    );
  }

  private closeMenu() {
    this.menu.hidden = true;
    this.menuItems = [];
  }

  // A20: this page before ---------------------------------------------------

  private async drawPageBefore() {
    const url = this.ctx.blocked ? undefined : this.ctx.url;
    const e = await pageEntry(url, this.owner());
    if (url !== (this.ctx.blocked ? undefined : this.ctx.url)) return;
    if (!e || !url) {
      this.pageBefore.hidden = true;
      return;
    }
    const n = e.convs.length;
    const m = e.highlights.length;
    const bits = [
      n ? `${n} chat${n === 1 ? "" : "s"}` : "",
      m ? `${m} highlight${m === 1 ? "" : "s"}` : "",
    ].filter(Boolean);
    this.pageBefore.hidden = false;
    this.pageBefore.replaceChildren(
      h("span", {}, `This page before: ${bits.join(" · ")}`),
      h(
        "button",
        {
          className: "link",
          "data-testid": "page-before-show",
          onClick: () => void this.showHistory(url),
        },
        "Show",
      ),
    );
  }

  /** The server's list for this page, asked only now that the person wants it. */
  private async showHistory(url: string) {
    const list = h(
      "div",
      { className: "history", "data-testid": "page-history" },
      h("p", { className: "empty" }, "Loading…"),
    );
    this.pageBefore.replaceChildren(list);
    try {
      const r = await this.here.api.unwrap(
        this.here.api.GET("/v1/me/page-history", {
          params: { query: { org_id: this.here.org.id, url } },
          signal: T(),
        }),
      );
      list.replaceChildren(
        ...r.conversations.map((c) =>
          h(
            "button",
            {
              className: "link",
              "data-testid": "history-chat",
              onClick: async () => {
                if (this.bot?.id !== c.bot_id) await this.pickBot(c.bot_id);
                if (!this.convs.some((x) => x.id === c.id))
                  this.topConvs.append(
                    h("option", { value: c.id }, (c.title || "Conversation").slice(0, 60)),
                  );
                await this.pickConv(c.id);
              },
            },
            `${c.title || "Conversation"} · ${this.bots.find((b) => b.id === c.bot_id)?.name ?? "Bot"}`,
          ),
        ),
        ...r.highlights.map((hl) =>
          h(
            "div",
            { className: "hl", "data-testid": "history-highlight" },
            h("span", {}, `“${hl.text.slice(0, 140)}${hl.text.length > 140 ? "…" : ""}”`),
            h(
              "button",
              {
                className: "link",
                onClick: async (ev: Event) => {
                  await this.here.api.unwrap(
                    this.here.api.DELETE("/v1/me/highlights/{id}", {
                      params: { path: { id: hl.id } },
                      signal: T(),
                    }),
                  );
                  const { forgetHighlight } = await import("../lib/page-index.ts");
                  await forgetHighlight(url, this.owner(), hl.id);
                  (ev.target as HTMLElement).closest(".hl")?.remove();
                },
              },
              "Delete",
            ),
          ),
        ),
      );
      if (!r.conversations.length && !r.highlights.length)
        list.replaceChildren(
          h("p", { className: "empty" }, "Nothing on the server for this page."),
        );
    } catch (e) {
      list.replaceChildren(errorBox(e, () => void this.showHistory(url)));
    }
    list.prepend(h("div", { className: "meta" }, pageKey(url)));
  }

  // F1: quick answers on this computer ---------------------------------------

  private async drawQuick() {
    const sel = this.ctx.blocked ? "" : (this.ctx.selection ?? "").trim();
    if (!sel) {
      this.quickRow.hidden = true;
      return;
    }
    if (!this.quick.length) this.quick = await quickKinds();
    if (!this.quick.length) {
      this.quickRow.hidden = true;
      return;
    }
    const label = { summarize: "Summarize", explain: "Explain", translate: "Translate" };
    this.quickRow.hidden = false;
    this.quickRow.replaceChildren(
      h("span", { className: "meta" }, "On this computer:"),
      ...this.quick.map((k) =>
        h(
          "button",
          {
            type: "button",
            className: "link",
            "data-testid": `quick-${k}`,
            onClick: async () => {
              const out = h(
                "div",
                { className: "msg assistant local", "data-testid": "quick-answer" },
                h("div", { className: "who" }, "This computer"),
                h("div", { className: "body typing" }),
              );
              this.live.replaceChildren(out);
              try {
                const answer = await quickAnswer(k, sel);
                out.lastElementChild!.replaceWith(
                  h("div", { className: "body" }, markdownNodes(answer)),
                );
                out.append(
                  h("div", { className: "meta" }, "Answered on this computer. Nothing was sent."),
                );
              } catch (e) {
                out.lastElementChild!.replaceWith(errorBox(e));
              }
            },
          },
          label[k],
        ),
      ),
    );
  }

  /** F3: the built-in model answers about the page; nothing leaves the computer. */
  private async answerLocally(question: string) {
    const out = h(
      "div",
      { className: "item", "data-testid": "local-answer" },
      h("h3", {}, question || "About this page"),
      h("p", { className: "meta" }, "Answering on this computer…"),
    );
    this.live.replaceChildren(out);
    try {
      const page = [this.ctx.title, this.ctx.url, this.ctx.selection, this.ctx.text]
        .filter(Boolean)
        .join("\n\n");
      const answer = await localAnswer(question, page);
      out.lastElementChild!.replaceWith(h("div", { className: "body" }, markdownNodes(answer)));
      out.append(
        h(
          "div",
          { className: "meta" },
          "Answered on this computer: you keep page content to private models. Nothing was sent.",
        ),
      );
      this.input.value = "";
    } catch (e) {
      out.lastElementChild!.replaceWith(errorBox(e));
    }
  }

  // A12: live call -------------------------------------------------------------

  private async startCall() {
    if (this.call && (this.call.state === "live" || this.call.state === "connecting")) return;
    const bot = this.bot;
    if (!bot) return;
    let session: Schemas["VoiceSession"];
    try {
      session = await this.here.api.unwrap(
        this.here.api.POST("/v1/voice/session", {
          body: { bot_id: bot.id, ...(this.convId ? { conversation_id: this.convId } : {}) },
          signal: T(),
        }),
      );
    } catch (e) {
      return toast(message(e));
    }
    const ctx = this.ctx;
    // F3: the page's address goes to a hosted bot only when the private model rule allows it.
    const rule = !!(
      (await chrome.storage.local.get("browserDevice")).browserDevice as
        | { privateModel?: boolean }
        | undefined
    )?.privateModel;
    const pageOk = !rule || (await botIsPrivate(this.here.api, bot.id).catch(() => false));
    const note =
      pageOk && !ctx.blocked && this.chips.page && ctx.url
        ? `(I'm in my browser, looking at: ${ctx.title ? `${ctx.title} ` : ""}(${ctx.url}). Only bring it up if it helps.)`
        : undefined;
    const liveCallId = session.live_call_id;
    const call: LiveCall = new LiveCall(session, {
      context: note,
      onChange: () => this.drawCall(),
      // Keeps the call's server record open, with the usage so far, so it's billed like the app's
      // (D-327); a call the server already ended is hung up.
      heartbeat: async () =>
        (
          await this.here.api.unwrap(
            this.here.api.POST("/v1/voice/live/{id}/heartbeat", {
              params: { path: { id: liveCallId } },
              body: call.ev.hasUsage ? { usage: call.ev.usage } : {},
              signal: T(),
            }),
          )
        ).ended,
      runTool: async (t: ToolCall) => {
        const r = await this.here.api.unwrap(
          this.here.api.POST("/v1/voice/tool", {
            body: {
              bot_id: bot.id,
              conversation_id: session.conversation_id,
              live_call_id: liveCallId,
              call_id: t.id,
              name: t.name,
              arguments: t.args,
            },
            signal: T(30_000),
          }),
        );
        return r.output;
      },
    });
    this.call = call;
    this.drawCall();
    try {
      await call.start();
    } catch {
      this.call = null;
      this.drawCall();
      toast("Allow the microphone in the tab that opens, then try again.");
      void chrome.tabs.create({ url: chrome.runtime.getURL("options/options.html#microphone") });
    }
  }

  private savedCall: LiveCall | null = null;
  private drawCall() {
    const c = this.call;
    if (!c) {
      this.callBar.hidden = true;
      return;
    }
    this.callBar.hidden = false;
    const state = {
      connecting: "Connecting…",
      live: "On a call",
      ended: "Call ended",
      failed: "The call couldn't start",
    }[c.state];
    const last = c.ev.turns.slice(-3);
    this.callBar.replaceChildren(
      h(
        "div",
        { className: "row", style: "margin:0" },
        h(
          "strong",
          { "data-testid": "call-state" },
          `${state}${c.state === "live" ? ` · ${this.bot?.name ?? "Bot"}` : ""}`,
        ),
        c.state === "live" || c.state === "connecting"
          ? h(
              "div",
              { className: "row", style: "margin:0" },
              h(
                "button",
                {
                  "data-testid": "call-mute",
                  "aria-pressed": String(c.muted),
                  onClick: () => c.setMuted(!c.muted),
                },
                c.muted ? "Unmute" : "Mute",
              ),
              h(
                "button",
                { className: "danger", "data-testid": "hang-up", onClick: () => void c.hangUp() },
                "Hang up",
              ),
            )
          : h(
              "button",
              {
                className: "link",
                onClick: () => {
                  this.call = null;
                  this.drawCall();
                },
              },
              "Close",
            ),
      ),
      ...last.map((t) =>
        h(
          "div",
          { className: `turn ${t.role}`, "data-testid": "call-turn" },
          `${t.role === "user" ? "You" : (this.bot?.name ?? "Bot")}: ${t.text}`,
        ),
      ),
    );
    // Over: save what was said to the conversation, once.
    if (c.state === "ended" && this.savedCall !== c) {
      this.savedCall = c;
      void this.saveCall(c);
    }
  }

  private async saveCall(c: LiveCall) {
    try {
      const conv = c.session.conversation_id;
      // Always sent, even with nothing said: it ends the call's server record and settles its
      // charge (D-327).
      await this.here.api.unwrap(
        this.here.api.POST("/v1/voice/transcript", {
          body: {
            conversation_id: conv,
            live_call_id: c.session.live_call_id,
            turns: c.ev.turns.slice(0, 500),
            seconds: c.seconds,
            provider: "gemini",
            ...(c.ev.hasUsage ? { usage: c.ev.usage } : {}),
          },
          signal: T(),
        }),
      );
      if (this.convId !== conv) {
        this.convId = conv;
        if (!this.convs.some((x) => x.id === conv))
          this.topConvs.append(h("option", { value: conv }, "Call"));
        this.topConvs.value = conv;
      }
      await this.loadThread();
    } catch (e) {
      toast(message(e));
    }
  }

  private approvalCard(id: string, tool: string, risk: string) {
    const card = h(
      "div",
      { className: "item", "data-testid": "approval-inline" },
      h("h3", {}, "Approve this step?"),
      h("div", { className: "meta" }, `${tool} · ${risk} risk`),
    );
    const decide = async (d: "approved" | "denied") => {
      try {
        await this.here.api.decideApproval(id, d);
        card.replaceChildren(
          h("div", { className: "meta" }, d === "approved" ? "Approved" : "Denied"),
        );
      } catch (e) {
        card.append(errorBox(e));
      }
    };
    card.append(
      h(
        "div",
        { className: "row" },
        h("button", { className: "primary", onClick: () => void decide("approved") }, "Approve"),
        h("button", { onClick: () => void decide("denied") }, "Deny"),
      ),
    );
    return card;
  }
}

/** A media file's picture as a blob URL, fetched with the token (it isn't public). */
const blobs = new Map<string, string>();
async function mediaUrl(here: Here, id: string): Promise<string | null> {
  if (blobs.has(id)) return blobs.get(id)!;
  try {
    const token = await accessToken(here.account.id);
    const res = await fetch(`${here.account.server}/v1/media/${id}`, {
      headers: { authorization: `Bearer ${token}` },
      signal: T(),
    });
    if (!res.ok) return null;
    const u = URL.createObjectURL(await res.blob());
    blobs.set(id, u);
    return u;
  } catch {
    return null;
  }
}

type Sent = Record<string, SentRecord & { typedChars?: number }>;
async function sentRecords(): Promise<Sent> {
  return ((await chrome.storage.local.get("sent")).sent as Sent | undefined) ?? {};
}
async function saveSent(id: string, r: SentRecord & { typedChars?: number }) {
  const all = await sentRecords();
  all[id] = r;
  const keep = Object.entries(all)
    .sort((a, b) => b[1].at - a[1].at)
    .slice(0, SENT_KEEP);
  await chrome.storage.local.set({ sent: Object.fromEntries(keep) });
}

function originOf(url: string): string {
  try {
    return new URL(url).origin;
  } catch {
    return "";
  }
}
