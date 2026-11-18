/**
 * Running out (D-249): the server refuses with the same codes for the extension as for the app.
 * The app answers them with its plans page; the extension shows the server's sentence and a button
 * that opens Billing in the web app. Nothing is bought in the extension.
 */
import { CasamaError } from "@casama/client";

/** The web app's Billing page (client/lib/core/router.dart, settings → billing). */
export const BILLING_PATH = "/settings/billing";

/**
 * Codes whose fix is a plan or credits, as the app's chat reads them
 * (client/lib/features/chat/widgets/error_details.dart `limitErrors`), plus the other refusals
 * whose message points at Billing.
 */
export const PLAN_CODES = new Set([
  "out_of_credits",
  "quota_exceeded",
  "cloud_daily_cap",
  "computer_hours_exceeded",
  "plan_limit",
  "workspace_limit",
  "storage_full",
  "paid_plan_required",
]);

/** Whether a failure (an API error, or a run's error code) is fixed in Billing. */
export function needsPlan(e: unknown): boolean {
  if (typeof e === "string") return PLAN_CODES.has(e);
  return e instanceof CasamaError && (e.status === 402 || PLAN_CODES.has(e.code));
}

/**
 * Why a taught skill's draft wasn't written (D-334): the server keeps the drafting run's error on
 * the recording, so a draft refused for credits or a plan limit says so and offers Billing.
 */
export function teachFailure(
  s: { error_code?: string | null; error_message?: string | null } | null | undefined,
): { text: string; code: string | null; plans: boolean } {
  const code = s?.error_code || null;
  return {
    text: s?.error_message || "The skill couldn't be written. Try teaching again.",
    code,
    plans: !!code && needsPlan(code),
  };
}

/** The sentence to show for an API error: the server's own words, without the code suffix. */
export function planMessage(e: CasamaError): string {
  return e.detail || e.title || e.message;
}

/**
 * A failed raw `fetch` to the API (read aloud, dictation) as a CasamaError, so it reads like the
 * typed client's errors. Dictation out of credits comes back as `dictation_unavailable` (the app
 * then uses the phone's own dictation, which the extension doesn't have), so it's told apart by
 * its sentence and reported as out of credits.
 */
export async function responseError(res: Response): Promise<CasamaError> {
  const e = await CasamaError.fromResponse(res);
  if (e.code === "dictation_unavailable" && /out of credits/i.test(e.detail ?? ""))
    return new CasamaError(res.status, {
      code: "out_of_credits",
      title: e.title,
      status: res.status,
      detail:
        "The workspace is out of credits, so dictation is off. Add credits or change plans in Billing.",
    });
  return e;
}
