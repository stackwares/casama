/**
 * Live call (A12): talk with a bot in the panel while looking at the page, over Gemini Live like
 * the app (client/lib/core/gemini_live.dart, D-260). The server mints a single-use token with the
 * bot's persona and tools (`POST /v1/voice/session`); tool calls run as agent runs with the usual
 * approvals (`/v1/voice/tool`); the transcript is saved to the conversation at the end.
 */

export const INPUT_RATE = 16_000;
export const OUTPUT_RATE = 24_000;

export interface Turn {
  role: "user" | "assistant";
  text: string;
}

export interface ToolCall {
  id: string;
  name: string;
  args: Record<string, unknown>;
}

/** What one server message means. Pure, so it's tested without a socket. */
export class LiveEvents {
  ready = false;
  turns: Turn[] = [];
  usage = {
    input_audio_tokens: 0,
    input_text_tokens: 0,
    output_audio_tokens: 0,
    output_text_tokens: 0,
  };
  hasUsage = false;
  private user = "";
  private bot = "";
  private names = new Map<string, string>();

  private flush(role: Turn["role"]) {
    const text = (role === "user" ? this.user : this.bot).trim();
    if (role === "user") this.user = "";
    else this.bot = "";
    if (text) this.turns.push({ role, text });
  }

  /** Returns audio to play, tool calls to run, and whether the bot was interrupted. */
  handle(raw: string): {
    audio: string[];
    tools: ToolCall[];
    interrupted: boolean;
    setup: boolean;
  } {
    const out = {
      audio: [] as string[],
      tools: [] as ToolCall[],
      interrupted: false,
      setup: false,
    };
    interface LiveFrame {
      setupComplete?: unknown;
      usageMetadata?: {
        promptTokensDetails?: { modality: string; tokenCount: number }[];
        responseTokensDetails?: { modality: string; tokenCount: number }[];
      };
      serverContent?: {
        inputTranscription?: { text?: string };
        outputTranscription?: { text?: string };
        modelTurn?: { parts?: { inlineData?: { data?: string } }[] };
        interrupted?: boolean;
        turnComplete?: boolean;
      };
      toolCall?: { functionCalls?: Record<string, unknown>[] };
    }
    let m: LiveFrame;
    try {
      m = JSON.parse(raw);
    } catch {
      return out;
    }
    if ("setupComplete" in m) {
      out.setup = !this.ready;
      this.ready = true;
    }
    const u = m.usageMetadata;
    if (u && typeof u === "object") {
      this.hasUsage = true;
      for (const d of (u.promptTokensDetails ?? []) as { modality: string; tokenCount: number }[])
        if (d.modality === "AUDIO") this.usage.input_audio_tokens += d.tokenCount ?? 0;
        else this.usage.input_text_tokens += d.tokenCount ?? 0;
      for (const d of (u.responseTokensDetails ?? []) as { modality: string; tokenCount: number }[])
        if (d.modality === "AUDIO") this.usage.output_audio_tokens += d.tokenCount ?? 0;
        else this.usage.output_text_tokens += d.tokenCount ?? 0;
    }
    const sc = m.serverContent;
    if (sc && typeof sc === "object") {
      const heard = sc.inputTranscription?.text;
      if (typeof heard === "string") this.user += heard;
      for (const p of (sc.modelTurn?.parts ?? []) as { inlineData?: { data?: string } }[]) {
        const data = p.inlineData?.data;
        if (typeof data === "string") {
          // The person's words are complete once the bot starts answering.
          this.flush("user");
          out.audio.push(data);
        }
      }
      const said = sc.outputTranscription?.text;
      if (typeof said === "string") this.bot += said;
      if (sc.interrupted === true) out.interrupted = true;
      if (sc.turnComplete === true || sc.interrupted === true) {
        this.flush("user");
        this.flush("assistant");
      }
    }
    for (const c of (m.toolCall?.functionCalls ?? []) as Record<string, unknown>[]) {
      if (typeof c.id !== "string" || typeof c.name !== "string") continue;
      this.names.set(c.id, c.name);
      out.tools.push({
        id: c.id,
        name: c.name,
        args: c.args && typeof c.args === "object" ? (c.args as Record<string, unknown>) : {},
      });
    }
    return out;
  }

  toolResponse(id: string, output: string) {
    const name = this.names.get(id) ?? "";
    this.names.delete(id);
    return { toolResponse: { functionResponses: [{ id, name, response: { result: output } }] } };
  }
}

export function toBase64(bytes: Uint8Array): string {
  let s = "";
  for (let i = 0; i < bytes.length; i += 0x8000)
    s += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return btoa(s);
}

/** Float samples (−1…1) to 16-bit little-endian PCM. */
export function floatToPcm16(f: Float32Array): Uint8Array {
  const out = new DataView(new ArrayBuffer(f.length * 2));
  for (let i = 0; i < f.length; i++) {
    const v = Math.max(-1, Math.min(1, f[i]!));
    out.setInt16(i * 2, v < 0 ? v * 0x8000 : v * 0x7fff, true);
  }
  return new Uint8Array(out.buffer);
}

export function pcm16ToFloat(b64: string): Float32Array {
  const bin = atob(b64);
  const n = Math.floor(bin.length / 2);
  const out = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    let v = bin.charCodeAt(i * 2) | (bin.charCodeAt(i * 2 + 1) << 8);
    if (v >= 0x8000) v -= 0x10000;
    out[i] = v / 0x8000;
  }
  return out;
}

export interface Session {
  connect_url: string;
  client_secret: string;
  setup: Record<string, unknown> | null;
  conversation_id: string;
  speak_first: boolean;
  /** The call's server record (D-327): heartbeats keep it open, and hanging up ends and bills it. */
  live_call_id: string;
}

/** How often a live call tells the server it's still on, like the app (D-327). */
export const HEARTBEAT_MS = 30_000;

export type CallState = "connecting" | "live" | "ended" | "failed";

export interface LiveOptions {
  runTool: (t: ToolCall) => Promise<string>;
  onChange: () => void;
  /** A note for the model at the start (the page in view), sent without asking for a reply. */
  context?: string;
  socket?: (url: string) => WebSocket;
  micStream?: () => Promise<MediaStream>;
  /**
   * Tells the server the call is still on, every [HEARTBEAT_MS] until it ends; resolves true when
   * the server already ended the call (no heartbeat in time), which hangs up here too. A call with
   * no heartbeat for 2 minutes is ended and billed by the server only up to its last one.
   */
  heartbeat?: () => Promise<boolean>;
}

/**
 * One call: the socket, the microphone (16 kHz) and the speaker (24 kHz). [runTool] runs a tool call
 * through the server; [onChange] redraws the call bar.
 */
export class LiveCall {
  state: CallState = "connecting";
  muted = false;
  readonly ev = new LiveEvents();
  private ws: WebSocket | null = null;
  private mic: MediaStream | null = null;
  private inCtx: AudioContext | null = null;
  private outCtx: AudioContext | null = null;
  private node: ScriptProcessorNode | null = null;
  private playhead = 0;
  private sources = new Set<AudioBufferSourceNode>();
  readonly startedAt = Date.now();

  readonly session: Session;
  private opts: LiveOptions;
  constructor(session: Session, opts: LiveOptions) {
    this.session = session;
    this.opts = opts;
  }

  private set(s: CallState) {
    this.state = s;
    this.opts.onChange();
  }

  private sendJson(m: unknown) {
    if (this.ws?.readyState === WebSocket.OPEN) this.ws.send(JSON.stringify(m));
  }

  async start() {
    this.mic = await (
      this.opts.micStream ?? (() => navigator.mediaDevices.getUserMedia({ audio: true }))
    )();
    const url = `${this.session.connect_url}${this.session.connect_url.includes("?") ? "&" : "?"}access_token=${encodeURIComponent(this.session.client_secret)}`;
    const ws = (this.opts.socket ?? ((u) => new WebSocket(u)))(url);
    this.ws = ws;
    this.startHeartbeat();
    ws.onopen = () => this.sendJson({ setup: { ...this.session.setup, sessionResumption: {} } });
    ws.onmessage = async (e) => {
      const raw = typeof e.data === "string" ? e.data : await (e.data as Blob).text();
      this.onMessage(raw);
    };
    ws.onclose = () => void this.hangUp();
    ws.onerror = () => {
      if (this.state === "connecting") void this.hangUp();
    };
  }

  private onMessage(raw: string) {
    const r = this.ev.handle(raw);
    if (r.setup) {
      this.set("live");
      if (this.opts.context)
        this.sendJson({
          clientContent: {
            turns: [{ role: "user", parts: [{ text: this.opts.context }] }],
            turnComplete: false,
          },
        });
      if (this.session.speak_first)
        this.sendJson({
          clientContent: {
            turns: [
              { role: "user", parts: [{ text: "(The call has connected. Start speaking.)" }] },
            ],
            turnComplete: true,
          },
        });
      this.startMic();
    }
    if (r.interrupted) this.flushAudio();
    for (const a of r.audio) this.play(a);
    for (const t of r.tools)
      void this.opts
        .runTool(t)
        .catch((e) => `The tool failed: ${(e as Error).message}`)
        .then((output) => this.sendJson(this.ev.toolResponse(t.id, output)));
    if (r.audio.length || r.tools.length || raw.includes("turnComplete")) this.opts.onChange();
  }

  private startMic() {
    if (!this.mic) return;
    this.inCtx = new AudioContext({ sampleRate: INPUT_RATE });
    const src = this.inCtx.createMediaStreamSource(this.mic);
    this.node = this.inCtx.createScriptProcessor(2048, 1, 1);
    this.node.onaudioprocess = (e) => {
      if (this.muted || this.state !== "live") return;
      const pcm = floatToPcm16(e.inputBuffer.getChannelData(0));
      this.sendJson({
        realtimeInput: { audio: { data: toBase64(pcm), mimeType: `audio/pcm;rate=${INPUT_RATE}` } },
      });
    };
    src.connect(this.node);
    // A script processor only runs while connected to the output; it writes silence there.
    this.node.connect(this.inCtx.destination);
  }

  private play(b64: string) {
    this.outCtx ??= new AudioContext({ sampleRate: OUTPUT_RATE });
    const samples = pcm16ToFloat(b64);
    if (!samples.length) return;
    const buf = this.outCtx.createBuffer(1, samples.length, OUTPUT_RATE);
    buf.getChannelData(0).set(samples);
    const src = this.outCtx.createBufferSource();
    src.buffer = buf;
    src.connect(this.outCtx.destination);
    const at = Math.max(this.outCtx.currentTime, this.playhead);
    src.start(at);
    this.playhead = at + buf.duration;
    this.sources.add(src);
    src.onended = () => this.sources.delete(src);
  }

  private flushAudio() {
    for (const s of this.sources) s.stop();
    this.sources.clear();
    this.playhead = 0;
  }

  setMuted(m: boolean) {
    if (m && !this.muted) this.sendJson({ realtimeInput: { audioStreamEnd: true } });
    this.muted = m;
    this.opts.onChange();
  }

  private beat: ReturnType<typeof setInterval> | null = null;
  private startHeartbeat() {
    const send = this.opts.heartbeat;
    if (!send || this.beat) return;
    this.beat = setInterval(() => {
      if (this.closed) return;
      void send()
        .then((ended) => {
          if (ended) void this.hangUp();
        })
        // A missed beat is fine; the server waits 2 minutes before it ends the call.
        .catch(() => {});
    }, HEARTBEAT_MS);
  }

  private closed = false;
  /** Ends the call, or gives up connecting; either way the microphone and sockets are let go. */
  async hangUp() {
    if (this.closed) return;
    this.closed = true;
    if (this.beat) clearInterval(this.beat);
    this.beat = null;
    this.state = this.state === "live" ? "ended" : "failed";
    this.flushAudio();
    this.node?.disconnect();
    for (const t of this.mic?.getTracks() ?? []) t.stop();
    await this.inCtx?.close().catch(() => {});
    await this.outCtx?.close().catch(() => {});
    this.ws?.close();
    this.opts.onChange();
  }

  get seconds() {
    return Math.round((Date.now() - this.startedAt) / 1000);
  }
}
