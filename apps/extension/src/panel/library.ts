/**
 * The Library tab (B1–B5, D5): save the page (Markdown, PDF or a screenshot), a selection, an image
 * or a link into the Library, optionally into a project; remember a fact; add the page to a bot's
 * knowledge; make a task. Below, the newest things in the Library.
 */
import type { Schemas } from "@casama/client";
import { type Capture, capture, queued, toBase64 } from "../lib/capture.ts";
import { h } from "../lib/dom.ts";
import { emptyState } from "../lib/look.ts";
import {
  activeTab,
  blockedReason,
  readTab,
  screenshot,
  tabHtml,
  tabMarkdown,
} from "../lib/page.ts";
import { appUrl, type Here } from "../lib/workspace.ts";
import { ago, errorBox, message, T, toast } from "./shared.ts";

const fileName = (title: string, ext: string) =>
  `${
    (title || "Page")
      .replace(/[\\/:*?"<>|]+/g, " ")
      .trim()
      .slice(0, 120) || "Page"
  }.${ext}`;

export class Captures {
  private here: Here;
  projectId: string | undefined;
  constructor(here: Here) {
    this.here = here;
  }

  /** True (and says why) when the tab's page can't be sent (G2). */
  private async refused(url: string | undefined): Promise<boolean> {
    const why = await blockedReason(url);
    if (why) toast(why);
    return why !== null;
  }

  private async run(c: Capture, done: string): Promise<boolean> {
    try {
      const r = await capture(this.here.account, c);
      toast(
        r.state === "sent" ? done : "You're offline. It's kept here and sent when you're back.",
      );
      return true;
    } catch (e) {
      toast(message(e));
      return false;
    }
  }

  private library(name: string, bytes: Uint8Array, type: string, convert?: "pdf"): Capture {
    return {
      kind: "library",
      orgId: this.here.org.id,
      name,
      data: toBase64(bytes),
      type,
      convert,
      projectId: this.projectId,
    };
  }

  async savePage(as: "markdown" | "pdf" | "screenshot") {
    const tab = await activeTab();
    if (!tab) return false;
    try {
      if (as === "screenshot") {
        const png = await screenshot(tab);
        return this.run(
          this.library(
            fileName(tab.title ?? "", "png"),
            new Uint8Array(await png.arrayBuffer()),
            "image/png",
          ),
          "Screenshot saved to the Library.",
        );
      }
      if (as === "pdf") {
        const html = await tabHtml(tab);
        return this.run(
          this.library(
            fileName(tab.title ?? "", "html"),
            new TextEncoder().encode(html),
            "text/html",
            "pdf",
          ),
          "Saved to the Library as a PDF.",
        );
      }
      const md = await tabMarkdown(tab);
      const body = `# ${md.title}\n\nFrom ${md.url}, saved ${new Date().toISOString().slice(0, 10)}\n\n${md.markdown}\n`;
      return this.run(
        this.library(fileName(md.title, "md"), new TextEncoder().encode(body), "text/markdown"),
        "Saved to the Library.",
      );
    } catch (e) {
      toast(message(e));
      return false;
    }
  }

  async saveNote(text: string, source?: { url?: string; title?: string }) {
    const body = `${text.trim()}\n${source?.url ? `\nFrom [${source.title || source.url}](${source.url})\n` : ""}`;
    const title = text.trim().split("\n")[0]!.slice(0, 60) || "Note";
    return this.run(
      this.library(fileName(title, "md"), new TextEncoder().encode(body), "text/markdown"),
      "Note saved to the Library.",
    );
  }

  async saveLink(url: string, title?: string) {
    return this.saveNote(`[${title || url}](${url})`, undefined);
  }

  async saveImage(url: string) {
    try {
      const res = await fetch(url, { signal: T() });
      if (!res.ok) throw new Error(`The image couldn't be loaded (${res.status}).`);
      const blob = await res.blob();
      const name = decodeURIComponent(new URL(url).pathname.split("/").pop() || "image") || "image";
      return this.run(
        this.library(name, new Uint8Array(await blob.arrayBuffer()), blob.type || "image/png"),
        "Image saved to the Library.",
      );
    } catch (e) {
      toast(message(e));
      return false;
    }
  }

  remember(text: string) {
    return this.run({ kind: "fact", text: text.trim() }, "Saved to About you.");
  }

  async knowledge(botId: string | undefined, site: boolean) {
    const tab = await activeTab();
    if (!tab?.url || (await this.refused(tab.url))) return false;
    const url = site ? new URL(tab.url).origin : tab.url;
    return this.run(
      {
        kind: "knowledge",
        orgId: this.here.org.id,
        botId,
        url,
        name: site ? new URL(tab.url).hostname : tab.title || tab.url,
        site,
      },
      site ? "The site is being added as knowledge." : "The page is being added as knowledge.",
    );
  }

  async task(botId: string | undefined, withShot: boolean) {
    const tab = await activeTab();
    if (!tab || (await this.refused(tab.url))) return false;
    const ctx = await readTab(tab).catch(() => ({ url: tab.url, title: tab.title, selection: "" }));
    if ("blocked" in ctx && ctx.blocked) {
      toast(ctx.blocked);
      return false;
    }
    let details = `${ctx.url ? `Page: [${ctx.title || ctx.url}](${ctx.url})\n` : ""}`;
    if (ctx.selection?.trim())
      details += `\n> ${ctx.selection.trim().slice(0, 4000).split("\n").join("\n> ")}\n`;
    if (withShot) {
      try {
        const png = await screenshot(tab);
        const r = await capture(
          this.here.account,
          this.library(
            fileName(tab.title ?? "", "png"),
            new Uint8Array(await png.arrayBuffer()),
            "image/png",
          ),
        );
        if (r.state === "sent")
          details += `\nScreenshot: ${appUrl(this.here.account, `/library/${r.id}`)}\n`;
      } catch {
        // The task still goes without the picture.
      }
    }
    return this.run(
      {
        kind: "task",
        orgId: this.here.org.id,
        title: ctx.title || "From the browser",
        details,
        botId,
      },
      "Task made.",
    );
  }
}

export class LibraryView {
  readonly el = h("section", { className: "view", "data-testid": "library" });
  private here: Here;
  readonly captures: Captures;
  constructor(here: Here) {
    this.here = here;
    this.captures = new Captures(here);
  }

  async load() {
    const { api, org } = this.here;
    const projectSelect = h(
      "select",
      { "aria-label": "Project", "data-testid": "project-select" },
      h("option", { value: "" }, "No project"),
    ) as HTMLSelectElement;
    projectSelect.addEventListener("change", () => {
      this.captures.projectId = projectSelect.value || undefined;
    });
    const bots = h(
      "select",
      { "aria-label": "Bot", "data-testid": "capture-bot" },
      h("option", { value: "" }, "The whole workspace"),
    ) as HTMLSelectElement;
    const recent = h(
      "div",
      { "data-testid": "recent" },
      h("p", { className: "empty" }, "Loading…"),
    );
    const pending = h("div", { className: "notice-line", "data-testid": "queued" });
    const btn = (label: string, testid: string, fn: () => Promise<unknown>) =>
      h(
        "button",
        {
          "data-testid": testid,
          onClick: async (e: Event) => {
            const b = e.currentTarget as HTMLButtonElement;
            b.disabled = true;
            try {
              await fn();
              await this.recent(recent);
              await this.pending(pending);
            } finally {
              b.disabled = false;
            }
          },
        },
        label,
      );
    this.el.replaceChildren(
      h("div", { className: "section-title" }, "Save this page"),
      h(
        "div",
        { className: "row", style: "margin-top:0" },
        btn("Markdown", "save-markdown", () => this.captures.savePage("markdown")),
        btn("PDF", "save-pdf", () => this.captures.savePage("pdf")),
        btn("Screenshot", "save-screenshot", () => this.captures.savePage("screenshot")),
      ),
      h("label", {}, "Into a project", projectSelect),
      h("div", { className: "section-title" }, "Send it to Casama"),
      h("label", {}, "For", bots),
      h(
        "div",
        { className: "row" },
        btn("Add page to knowledge", "add-knowledge", () =>
          this.captures.knowledge(bots.value || undefined, false),
        ),
        btn("Add whole site", "add-site", () =>
          this.captures.knowledge(bots.value || undefined, true),
        ),
        btn("Make a task", "make-task", () => this.captures.task(bots.value || undefined, true)),
      ),
      pending,
      h("div", { className: "section-title" }, "Newest in the Library"),
      recent,
    );
    void api
      .unwrap(api.GET("/v1/projects", { params: { query: { org_id: org.id } }, signal: T() }))
      .then((p) =>
        projectSelect.append(
          ...(p.items as Schemas["Project"][])
            .filter((x) => x.status !== "done" && x.status !== "cancelled")
            .map((x) => h("option", { value: x.id }, x.title)),
        ),
      )
      .catch(() => {});
    void api
      .unwrap(api.GET("/v1/bots", { params: { query: { org_id: org.id } }, signal: T() }))
      .then((b) => bots.append(...b.items.map((x) => h("option", { value: x.id }, x.name))))
      .catch(() => {});
    await Promise.all([this.recent(recent), this.pending(pending)]);
  }

  private async pending(el: HTMLElement) {
    const q = (await queued()).filter((x) => x.accountId === this.here.account.id);
    el.textContent = q.length ? `${q.length} waiting to be sent when you're back online.` : "";
  }

  private async recent(el: HTMLElement) {
    const { api, org, account } = this.here;
    try {
      const items = (
        await api.unwrap(
          api.GET("/v1/creations", {
            params: { query: { org_id: org.id, limit: 15 } },
            signal: T(),
          }),
        )
      ).items;
      el.replaceChildren(
        ...(items.length
          ? items.map((c) =>
              h(
                "div",
                { className: "item", "data-testid": "creation" },
                h(
                  "h3",
                  {},
                  h(
                    "a",
                    {
                      href: appUrl(account, `/library/${c.id}`),
                      target: "_blank",
                      rel: "noopener",
                    },
                    c.title,
                  ),
                ),
                h(
                  "div",
                  { className: "meta" },
                  `${c.kind}${c.bot_name ? ` · ${c.bot_name}` : ""}${c.project_title ? ` · ${c.project_title}` : ""} · ${ago(c.created_at)}`,
                ),
              ),
            )
          : [
              emptyState({
                mascot: "sleepy",
                compact: true,
                message: "Nothing in the Library yet.",
              }),
            ]),
      );
    } catch (e) {
      el.replaceChildren(errorBox(e, () => void this.recent(el)));
    }
  }
}
