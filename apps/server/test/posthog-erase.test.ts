import { expect, it } from "vitest";
import { erasePostHogPerson } from "../src/services/posthog-erase.ts";

it("asks PostHog to delete the person and their events, and does nothing without a key or when off", async () => {
  const calls: { url: string; init: RequestInit }[] = [];
  const fake = (async (url: string, init: RequestInit) => {
    calls.push({ url, init });
    return new Response("{}", { status: 202 });
  }) as unknown as typeof fetch;
  const on = { enabled: true, apiKey: "phx_key", projectId: "637030", fetch: fake };

  expect(await erasePostHogPerson("user-1", on)).toBe("queued");
  expect(calls[0]?.url).toBe("https://us.posthog.com/api/projects/637030/persons/bulk_delete/");
  expect(JSON.parse(String(calls[0]?.init.body))).toEqual({
    distinct_ids: ["user-1"],
    delete_events: true,
    delete_recordings: true,
  });
  expect(((calls[0]?.init.headers ?? {}) as Record<string, string>).authorization).toBe(
    "Bearer phx_key",
  );

  expect(await erasePostHogPerson("user-1", { ...on, enabled: false })).toBe("skipped");
  expect(await erasePostHogPerson("user-1", { ...on, apiKey: "" })).toBe("skipped");
  expect(calls).toHaveLength(1);

  const failing = (async () => new Response("no", { status: 403 })) as unknown as typeof fetch;
  await expect(erasePostHogPerson("user-1", { ...on, fetch: failing })).rejects.toThrow("403");
});
