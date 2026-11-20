/**
 * The one adapter for decision models (docs/DECISION-MODEL-PLAN.md §5.2): a plain call to
 * OpenRouter's Decisions route. A decision model doesn't write; it returns how likely each answer
 * to a fixed question is. The route is marked alpha, so its shape lives here and nowhere else.
 */

export type DecisionQuestion =
  | { type: "yesno"; ask: string }
  /** name -> what it means. Always include an "other" option when the list may not cover the input. */
  | { type: "choice"; ask?: string; options: Record<string, string> }
  /** 2 to 10 ordered levels, lowest first. */
  | { type: "score"; ask?: string; levels: string[] };

export type DecisionAnswer =
  | { type: "yesno"; p: number }
  | { type: "choice"; choice: string; p: Record<string, number> }
  /** The expected level from 0 (lowest) to levels - 1, as a fraction. */
  | { type: "score"; score: number }
  /** Off, failed, timed out or refused: the caller does what it does today. */
  | { type: "none" };

export interface DecisionCall {
  model: string;
  /** The text to judge; already cut to size by the caller (decide()). */
  state: string;
  questions: Record<string, DecisionQuestion>;
  /** Sent as OpenRouter's `user`, like chat calls on the shared key. */
  user?: string;
  timeoutMs: number;
}

export interface DecisionResult {
  answers: Record<string, DecisionAnswer>;
  inputTokens: number;
  /** What OpenRouter reported, in USD; 0 when it didn't say. */
  costUsd: number;
  latencyMs: number;
  /** Why there are no answers (timeout, http_429, bad_body); undefined when it answered. */
  error?: string;
}

export interface DecisionBackend {
  decide(call: DecisionCall): Promise<DecisionResult>;
}

export const OPENROUTER_DECISIONS_PATH = "/api/alpha/decisions";

const noAnswers = (questions: Record<string, DecisionQuestion>) =>
  Object.fromEntries(Object.keys(questions).map((k) => [k, { type: "none" } as DecisionAnswer]));

const prob = (v: unknown): number | null =>
  typeof v === "number" && Number.isFinite(v) ? Math.min(1, Math.max(0, v)) : null;

/** The request body OpenRouter's Decisions route takes. */
export function decisionRequestBody(call: DecisionCall) {
  const questions: Record<string, unknown> = {};
  for (const [name, q] of Object.entries(call.questions)) {
    if (q.type === "yesno") questions[name] = { type: "noul", instructions: q.ask };
    // Every question carries instructions: OpenAI's decision model refuses one without (400).
    else if (q.type === "choice")
      questions[name] = {
        type: "choice",
        instructions: q.ask || "Pick the option that fits best.",
        criteria: q.options,
      };
    else
      questions[name] = {
        type: "score",
        instructions: q.ask || "Pick the level that fits best.",
        // The route names a score's ordered levels `criteria`, like a choice's options.
        criteria: q.levels,
      };
  }
  return {
    model: call.model,
    state: call.state,
    questions,
    // Same rule as every call on Casama's key: no provider that keeps or trains on prompts.
    provider: { data_collection: "deny" },
    ...(call.user ? { user: call.user } : {}),
  };
}

/** One answer from the route's JSON, or none when it is missing or malformed. */
function parseAnswer(q: DecisionQuestion, raw: unknown): DecisionAnswer {
  if (!raw || typeof raw !== "object") return { type: "none" };
  const a = raw as Record<string, unknown>;
  if (q.type === "yesno") {
    const p = prob(a.noul ?? a.predicate ?? a.probability);
    return p == null ? { type: "none" } : { type: "yesno", p };
  }
  if (q.type === "choice") {
    const probs: Record<string, number> = {};
    const given =
      a.probabilities && typeof a.probabilities === "object"
        ? (a.probabilities as Record<string, unknown>)
        : {};
    for (const name of Object.keys(q.options)) {
      const p = prob(given[name]);
      if (p != null) probs[name] = p;
    }
    const choice = typeof a.choice === "string" && a.choice in q.options ? a.choice : null;
    if (!choice) return { type: "none" };
    if (probs[choice] == null) {
      const c = prob(a.confidence);
      if (c != null) probs[choice] = c;
    }
    return { type: "choice", choice, p: probs };
  }
  const s = typeof a.score === "number" && Number.isFinite(a.score) ? a.score : null;
  if (s == null) return { type: "none" };
  // The expected level, a fraction (0.23 is mostly the lowest level).
  return { type: "score", score: Math.min(q.levels.length - 1, Math.max(0, s)) };
}

/** Maps the route's response to answers; any question it didn't answer is `none`. */
export function parseDecisionResponse(
  questions: Record<string, DecisionQuestion>,
  body: unknown,
): Omit<DecisionResult, "latencyMs"> {
  if (!body || typeof body !== "object")
    return { answers: noAnswers(questions), inputTokens: 0, costUsd: 0, error: "bad_body" };
  const b = body as Record<string, unknown>;
  const raw =
    b.answers && typeof b.answers === "object" ? (b.answers as Record<string, unknown>) : null;
  const usage = b.usage && typeof b.usage === "object" ? (b.usage as Record<string, unknown>) : {};
  const inputTokens =
    typeof usage.input_tokens === "number" ? Math.max(0, Math.round(usage.input_tokens)) : 0;
  const costUsd =
    typeof usage.cost === "number" && Number.isFinite(usage.cost) && usage.cost >= 0
      ? usage.cost
      : 0;
  if (!raw) return { answers: noAnswers(questions), inputTokens, costUsd, error: "bad_body" };
  const answers: Record<string, DecisionAnswer> = {};
  for (const [name, q] of Object.entries(questions)) answers[name] = parseAnswer(q, raw[name]);
  return { answers, inputTokens, costUsd };
}

/** OpenRouter's Decisions route on a key (Casama's shared key, or a self-hoster's own). */
export class OpenRouterDecisions implements DecisionBackend {
  private readonly key: string;
  private readonly opts: { fetch?: typeof fetch; base?: string; now?: () => number };
  constructor(key: string, opts: { fetch?: typeof fetch; base?: string; now?: () => number } = {}) {
    this.key = key;
    this.opts = opts;
  }

  async decide(call: DecisionCall): Promise<DecisionResult> {
    const now = this.opts.now ?? Date.now;
    const started = now();
    const base = (this.opts.base ?? "https://openrouter.ai").replace(/\/$/, "");
    const fail = (error: string): DecisionResult => ({
      answers: noAnswers(call.questions),
      inputTokens: 0,
      costUsd: 0,
      latencyMs: Math.max(0, now() - started),
      error,
    });
    let res: Response;
    try {
      res = await (this.opts.fetch ?? fetch)(`${base}${OPENROUTER_DECISIONS_PATH}`, {
        method: "POST",
        headers: { authorization: `Bearer ${this.key}`, "content-type": "application/json" },
        body: JSON.stringify(decisionRequestBody(call)),
        signal: AbortSignal.timeout(call.timeoutMs),
      });
    } catch (e) {
      const name = (e as Error)?.name;
      return fail(name === "TimeoutError" || name === "AbortError" ? "timeout" : "network");
    }
    if (!res.ok) {
      await res.body?.cancel().catch(() => {});
      return fail(`http_${res.status}`);
    }
    let body: unknown;
    try {
      body = await res.json();
    } catch {
      return fail("bad_body");
    }
    return {
      ...parseDecisionResponse(call.questions, body),
      latencyMs: Math.max(0, now() - started),
    };
  }
}
