/** Billing parity with the app: plan and credit refusals, and live calls' server record (D-327). */
import { CasamaError } from "@casama/client";
import { afterEach, describe, expect, it, vi } from "vitest";
import { needsPlan, planMessage, responseError, teachFailure } from "../src/lib/billing.ts";
import { HEARTBEAT_MS, LiveCall, type Session } from "../src/lib/live.ts";

const problem = (status: number, code: string, detail: string) =>
  new Response(JSON.stringify({ type: "about:blank", title: "T", status, code, detail }), {
    status,
    headers: { "content-type": "application/problem+json" },
  });

describe("plan and credit refusals", () => {
  it("knows the codes the app answers with its plans page, and any 402", () => {
    for (const code of [
      "out_of_credits",
      "quota_exceeded",
      "cloud_daily_cap",
      "computer_hours_exceeded",
      "plan_limit",
      "storage_full",
    ])
      expect(needsPlan(code)).toBe(true);
    // A bot's own budget is fixed in its settings, not in Billing.
    expect(needsPlan("daily_budget_exceeded")).toBe(false);
    expect(needsPlan("no_model_configured")).toBe(false);
    expect(needsPlan(new CasamaError(402, { code: "workspace_limit", detail: "x" }))).toBe(true);
    expect(needsPlan(new CasamaError(409, { code: "out_of_credits", detail: "x" }))).toBe(true);
    expect(needsPlan(new CasamaError(409, { code: "voice_unavailable", detail: "x" }))).toBe(false);
    expect(needsPlan(new Error("out_of_credits"))).toBe(false);
  });

  it("shows the server's sentence, not the code", () => {
    const e = new CasamaError(402, { code: "plan_limit", detail: "Your plan allows 1 bots." });
    expect(planMessage(e)).toBe("Your plan allows 1 bots.");
  });

  it("reads raw fetch failures (read aloud) like the typed client", async () => {
    const e = await responseError(
      problem(
        409,
        "out_of_credits",
        "The workspace is out of credits. Add credits or change plans in Billing.",
      ),
    );
    expect(e.code).toBe("out_of_credits");
    expect(needsPlan(e)).toBe(true);
  });

  it("reports dictation out of credits as out of credits (there's no device dictation here)", async () => {
    const e = await responseError(
      problem(
        409,
        "dictation_unavailable",
        "The workspace is out of credits, so dictation uses your device for now.",
      ),
    );
    expect(e.code).toBe("out_of_credits");
    expect(planMessage(e)).not.toMatch(/your device/);
    const setup = await responseError(
      problem(409, "dictation_unavailable", "Add an OpenRouter key to use dictation."),
    );
    expect(setup.code).toBe("dictation_unavailable");
    expect(needsPlan(setup)).toBe(false);
  });
});

describe("live call heartbeat", () => {
  afterEach(() => vi.useRealTimers());

  const session: Session = {
    connect_url: "wss://live.example/ws",
    client_secret: "s",
    setup: null,
    conversation_id: "c1",
    speak_first: false,
    live_call_id: "11111111-1111-4111-8111-111111111111",
  };
  const fakeSocket = () =>
    ({ close: vi.fn(), send: vi.fn(), readyState: 0 }) as unknown as WebSocket;

  it("beats every 30 seconds until hung up", async () => {
    vi.useFakeTimers();
    const heartbeat = vi.fn(async () => false);
    const call = new LiveCall(session, {
      runTool: async () => "",
      onChange: () => {},
      socket: fakeSocket,
      micStream: async () => ({ getTracks: () => [] }) as unknown as MediaStream,
      heartbeat,
    });
    await call.start();
    await vi.advanceTimersByTimeAsync(HEARTBEAT_MS * 2 + 10);
    expect(heartbeat).toHaveBeenCalledTimes(2);
    await call.hangUp();
    await vi.advanceTimersByTimeAsync(HEARTBEAT_MS * 3);
    expect(heartbeat).toHaveBeenCalledTimes(2);
  });

  it("hangs up when the server already ended the call", async () => {
    vi.useFakeTimers();
    const call = new LiveCall(session, {
      runTool: async () => "",
      onChange: () => {},
      socket: fakeSocket,
      micStream: async () => ({ getTracks: () => [] }) as unknown as MediaStream,
      heartbeat: async () => true,
    });
    await call.start();
    call.state = "live";
    await vi.advanceTimersByTimeAsync(HEARTBEAT_MS + 10);
    expect(call.state).toBe("ended");
  });

  it("keeps the call when a beat fails", async () => {
    vi.useFakeTimers();
    const call = new LiveCall(session, {
      runTool: async () => "",
      onChange: () => {},
      socket: fakeSocket,
      micStream: async () => ({ getTracks: () => [] }) as unknown as MediaStream,
      heartbeat: async () => {
        throw new Error("offline");
      },
    });
    await call.start();
    call.state = "live";
    await vi.advanceTimersByTimeAsync(HEARTBEAT_MS + 10);
    expect(call.state).toBe("live");
    await call.hangUp();
  });
});

describe("teachFailure (D-334)", () => {
  it("shows the server's reason, with plans for credit and plan refusals", () => {
    expect(
      teachFailure({
        error_code: "out_of_credits",
        error_message: "The workspace is out of credits.",
      }),
    ).toEqual({ text: "The workspace is out of credits.", code: "out_of_credits", plans: true });
    expect(teachFailure({ error_code: "plan_limit", error_message: "Upgrade." }).plans).toBe(true);
  });
  it("other failures keep their reason without plans, and nothing falls back to a sentence", () => {
    expect(teachFailure({ error_code: "no_draft", error_message: "No draft." })).toEqual({
      text: "No draft.",
      code: "no_draft",
      plans: false,
    });
    expect(teachFailure(null)).toEqual({
      text: "The skill couldn't be written. Try teaching again.",
      code: null,
      plans: false,
    });
  });
});
