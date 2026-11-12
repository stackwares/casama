/**
 * Erases a person's product analytics when their account is purged (D-208, ANALYTICS-PLAN §5.2): PostHog's
 * persons bulk-delete, by distinct id (the account's user id), with their events. Needs a personal API key
 * with person write scope (POSTHOG_PERSONAL_API_KEY) and the project id; without them, or with product
 * analytics off, there is nothing to erase and it does nothing. PostHog finishes the deletion in the
 * background, so a 2xx means "queued".
 */
export interface EraseOptions {
  apiKey?: string;
  projectId?: string;
  appHost?: string;
  enabled?: boolean;
  fetch?: typeof fetch;
}

export async function erasePostHogPerson(
  userId: string,
  opts: EraseOptions = {},
): Promise<"skipped" | "queued"> {
  const apiKey = opts.apiKey ?? process.env.POSTHOG_PERSONAL_API_KEY;
  const projectId = opts.projectId ?? process.env.POSTHOG_PROJECT_ID;
  const enabled = opts.enabled ?? process.env.PRODUCT_ANALYTICS === "on";
  if (!enabled || !apiKey || !projectId) return "skipped";
  const host = (opts.appHost ?? process.env.POSTHOG_APP_HOST ?? "https://us.posthog.com").replace(
    /\/$/,
    "",
  );
  const res = await (opts.fetch ?? fetch)(
    `${host}/api/projects/${projectId}/persons/bulk_delete/`,
    {
      method: "POST",
      headers: { authorization: `Bearer ${apiKey}`, "content-type": "application/json" },
      body: JSON.stringify({
        distinct_ids: [userId],
        delete_events: true,
        delete_recordings: true,
      }),
    },
  );
  if (!res.ok) throw new Error(`PostHog person deletion answered ${res.status}`);
  return "queued";
}
