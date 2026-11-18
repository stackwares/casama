/**
 * Record this tab (D-323 B12): a short video with the tab's sound, for a bot (a bug report, a
 * clip of a call). Chrome shows its own "this tab is being shared" marker the whole time.
 *
 * The recording runs in the panel, which the person keeps open while it records: closing the
 * panel stops it. The tab's sound keeps playing for the person while it's captured.
 */
import { browserName } from "./browser.ts";

/** Two minutes at most, a little under 50 MB at these rates. */
export const MAX_SECONDS = 120;
const VIDEO_BPS = 2_000_000;
const AUDIO_BPS = 96_000;

export function recordingName(at = new Date()) {
  const p = (n: number) => String(n).padStart(2, "0");
  return `Tab recording ${at.getFullYear()}-${p(at.getMonth() + 1)}-${p(at.getDate())} ${p(at.getHours())}.${p(at.getMinutes())}.webm`;
}

export function clock(seconds: number) {
  const s = Math.max(0, Math.floor(seconds));
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
}

export class TabRecorder {
  private recorder: MediaRecorder | null = null;
  private stream: MediaStream | null = null;
  private audio: AudioContext | null = null;
  private chunks: Blob[] = [];
  private timer?: ReturnType<typeof setInterval>;
  private started = 0;
  private done: ((b: Blob) => void) | null = null;

  get recording() {
    return this.recorder?.state === "recording";
  }

  /** Starts recording [tabId]; [onTick] gets the seconds so far. Resolves with the video. */
  async start(tabId: number, onTick: (seconds: number) => void): Promise<Blob> {
    if (this.recording) throw new Error("Already recording.");
    if (__CASAMA_BROWSER__ === "firefox") throw new Error("Firefox can't record a tab.");
    const streamId = await new Promise<string>((resolve, reject) =>
      chrome.tabCapture.getMediaStreamId({ targetTabId: tabId }, (id) => {
        const err = chrome.runtime.lastError;
        if (err || !id)
          reject(new Error(err?.message || `${browserName()} didn't allow recording this tab.`));
        else resolve(id);
      }),
    );
    const source = { mandatory: { chromeMediaSource: "tab", chromeMediaSourceId: streamId } };
    this.stream = await navigator.mediaDevices.getUserMedia({
      audio: source as MediaTrackConstraints,
      video: source as MediaTrackConstraints,
    });
    // Captured sound stops reaching the speakers unless it's played back.
    if (this.stream.getAudioTracks().length) {
      this.audio = new AudioContext();
      this.audio.createMediaStreamSource(this.stream).connect(this.audio.destination);
    }
    const mime = MediaRecorder.isTypeSupported("video/webm;codecs=vp9,opus")
      ? "video/webm;codecs=vp9,opus"
      : "video/webm";
    this.recorder = new MediaRecorder(this.stream, {
      mimeType: mime,
      videoBitsPerSecond: VIDEO_BPS,
      audioBitsPerSecond: AUDIO_BPS,
    });
    this.chunks = [];
    const result = new Promise<Blob>((resolve) => {
      this.done = resolve;
    });
    this.recorder.ondataavailable = (e) => {
      if (e.data.size) this.chunks.push(e.data);
    };
    this.recorder.onstop = () => {
      this.cleanup();
      this.done?.(new Blob(this.chunks, { type: "video/webm" }));
      this.done = null;
    };
    // The video track ends when the tab closes or navigates somewhere Chrome won't capture.
    this.stream.getVideoTracks()[0]?.addEventListener("ended", () => this.stop());
    this.recorder.start(1000);
    this.started = Date.now();
    onTick(0);
    this.timer = setInterval(() => {
      const s = (Date.now() - this.started) / 1000;
      onTick(s);
      if (s >= MAX_SECONDS) this.stop();
    }, 500);
    return result;
  }

  stop() {
    if (this.recorder && this.recorder.state !== "inactive") this.recorder.stop();
    else this.cleanup();
  }

  private cleanup() {
    clearInterval(this.timer);
    for (const t of this.stream?.getTracks() ?? []) t.stop();
    void this.audio?.close().catch(() => {});
    this.stream = null;
    this.audio = null;
  }
}
