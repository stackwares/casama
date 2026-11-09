import type { CheckResult, EvalRun } from "./types.ts";

const ok = (pass: boolean, why?: string): CheckResult => (pass ? { pass } : { pass, why });

export const answerIncludes =
  (...needles: string[]) =>
  (r: EvalRun) =>
    ok(
      r.status === "completed" &&
        needles.every((n) => r.answer.toLowerCase().includes(n.toLowerCase())),
      `answer should include ${needles.join(", ")}: ${r.answer.slice(0, 200)}`,
    );

/** Exact answer; numbers compare by value (3447 = 3447.0 = "3,447"). */
export const answerEquals = (expected: string) => (r: EvalRun) => {
  const got = r.answer.trim().replace(/[.\s]+$/, "");
  const asNum = (s: string) =>
    /^-?[\d,]*\.?\d+$/.test(s) ? Number(s.replaceAll(",", "")) : Number.NaN;
  const same =
    got === expected || (!Number.isNaN(asNum(expected)) && asNum(got) === asNum(expected));
  return ok(
    r.status === "completed" && same,
    `answer should be exactly ${expected}: ${r.answer.slice(0, 200)}`,
  );
};

export const toolsUsed = (r: EvalRun) =>
  r.events.filter((e) => e.type === "tool.started").map((e) => String(e.payload.tool));

export const toolOutput = (r: EvalRun) =>
  r.events
    .filter((e) => e.type === "tool.output")
    .map((e) => String(e.payload.chunk ?? ""))
    .join("");

export const fileMatches =
  (path: string, test: (content: string) => boolean, what: string) => async (r: EvalRun) => {
    const content = await r.file(path);
    return ok(
      content != null && test(content),
      `${path} should ${what}; got ${content?.slice(0, 200) ?? "no file"}`,
    );
  };

export const all =
  (...checks: Array<(r: EvalRun) => CheckResult | Promise<CheckResult>>) =>
  async (r: EvalRun) => {
    for (const c of checks) {
      const res = await c(r);
      if (!res.pass) return res;
    }
    return { pass: true };
  };

export const isJson = (s: string) => {
  try {
    return JSON.parse(s) as unknown;
  } catch {
    return undefined;
  }
};
