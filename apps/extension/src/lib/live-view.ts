/**
 * Live view of a bot's cloud computer (D-323 D10), in the panel or a small window of its own.
 *
 * It asks for a view-mode stream session first (the server checks the person may watch, and hands
 * back the screenshot address), then shows a fresh picture about once a second. View only: the
 * extension never takes control; "Take over" opens the app, which has the full viewer.
 */
import type { CasamaClient } from "@casama/client";
import { accessToken } from "./session.ts";
import type { Account } from "./store.ts";

export interface LiveViewOptions {
  account: Account;
  api: CasamaClient;
  computerId: string;
  img: HTMLImageElement;
  status: (text: string) => void;
  /** For tests. */
  everyMs?: number;
}

export class LiveView {
  private timer?: ReturnType<typeof setTimeout>;
  private url: string | null = null;
  private stopped = false;
  private shotUrl = "";
  private readonly o: LiveViewOptions;
  constructor(o: LiveViewOptions) {
    this.o = o;
  }

  async start() {
    this.stopped = false;
    const s = await this.o.api.unwrap(
      this.o.api.POST("/v1/computers/{id}/stream-session", {
        params: { path: { id: this.o.computerId } },
        body: { mode: "view" },
      }),
    );
    this.shotUrl = s.screenshot_url;
    this.o.status("Live");
    await this.tick();
  }

  private async tick() {
    if (this.stopped) return;
    // Left the screen (another tab of the panel): stop rather than poll for nothing.
    if (!this.o.img.isConnected) return this.stop();
    // A hidden panel or window doesn't need pictures.
    if (document.visibilityState !== "hidden") await this.frame();
    if (!this.stopped) this.timer = setTimeout(() => void this.tick(), this.o.everyMs ?? 1000);
  }

  private async frame() {
    try {
      const token = await accessToken(this.o.account.id);
      if (!token) {
        this.o.status("You're signed out.");
        this.stop();
        return;
      }
      const res = await fetch(this.shotUrl, {
        headers: { authorization: `Bearer ${token}` },
        cache: "no-store",
        signal: AbortSignal.timeout(10_000),
      });
      if (res.status === 409) {
        this.o.status("Nothing on its screen right now.");
        return;
      }
      if (!res.ok) {
        this.o.status(`The computer didn't answer (${res.status}).`);
        return;
      }
      const blob = await res.blob();
      if (this.stopped) return;
      const next = URL.createObjectURL(blob);
      this.o.img.src = next;
      if (this.url) URL.revokeObjectURL(this.url);
      this.url = next;
      this.o.status("Live");
    } catch {
      this.o.status("Reconnecting…");
    }
  }

  stop() {
    this.stopped = true;
    clearTimeout(this.timer);
    if (this.url) URL.revokeObjectURL(this.url);
    this.url = null;
  }
}

/** Opens the live view in a small window of its own. */
export async function popOutLiveView(computerId: string, name: string) {
  const url = chrome.runtime.getURL(
    `live/live.html?computer=${encodeURIComponent(computerId)}&name=${encodeURIComponent(name)}`,
  );
  await chrome.windows.create({ url, type: "popup", width: 640, height: 440 });
}
