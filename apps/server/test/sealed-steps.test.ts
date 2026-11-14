/**
 * The workflow engine's own tables in a workspace that encrypts content (D-267): a run's recorded
 * steps hold no message text, and ended workflows are purged after a week.
 */
import { randomBytes } from "node:crypto";
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, expect, it } from "vitest";
import { purgeEndedWorkflows } from "../src/worker/workflows.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/sealed-steps.json", import.meta.url));
let h: Harness;
let owner: { id: string; token: string };
let convId = "";

beforeAll(async () => {
  h = await startHarness({
    worker: { fixtures: FIXTURES },
    contentKey: randomBytes(32).toString("base64"),
  });
  owner = await h.user("sealed-steps@example.com");
  const orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "S" } }),
    )
  ).id;
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
    }),
  );
  const bot = await j(
    await h.request("/v1/bots", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: orgId,
        name: "Keeper",
        model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
      },
    }),
  );
  expect(
    (
      await h.request(`/v1/orgs/${orgId}/encryption`, {
        method: "PUT",
        token: owner.token,
        json: { enabled: true },
      })
    ).status,
  ).toBe(200);
  convId = (
    await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: bot.id },
      }),
    )
  ).id;
}, 90_000);
afterAll(async () => h?.stop());

it("a run's recorded steps hold no message text, and the reply still arrives", async () => {
  const sent = await j(
    await h.request(`/v1/conversations/${convId}/messages`, {
      method: "POST",
      token: owner.token,
      json: { text: "Remind me of the walrus-teapot phrase" },
    }),
  );
  let run: { status: string } = { status: "" };
  for (let i = 0; i < 200 && !["completed", "failed"].includes(run.status); i++) {
    await new Promise((r) => setTimeout(r, 100));
    run = await j(await h.request(`/v1/runs/${sent.run_id}`, { token: owner.token }));
  }
  expect(run.status).toBe("completed");
  const thread = await j(
    await h.request(`/v1/conversations/${convId}/thread`, { token: owner.token }),
  );
  expect(JSON.stringify(thread)).toContain("marzipan-lighthouse");

  const steps = await h.tdb.admin<{ output: string | null; error: string | null }[]>`
    select output, error from dbos.operation_outputs where workflow_uuid = ${sent.run_id}`;
  expect(steps.length).toBeGreaterThan(3);
  const all = JSON.stringify(steps);
  expect(all).not.toContain("marzipan-lighthouse");
  expect(all).not.toContain("walrus-teapot");
  expect(all).toContain("$sealedStep");

  // The workflow outlives the run's "completed" by a few steps (learning, posts in General), and
  // only an ended workflow is purged: wait for it to end.
  for (let i = 0; i < 100; i++) {
    const [w] = await h.tdb.admin<{ status: string }[]>`
      select status from dbos.workflow_status where workflow_uuid = ${sent.run_id}`;
    if (w && w.status !== "PENDING" && w.status !== "ENQUEUED") break;
    await new Promise((r) => setTimeout(r, 50));
  }
  // Ended workflows go after a week; a fresh one stays.
  expect(await purgeEndedWorkflows(h.handle.db)).toBe(0);
  await h.tdb.admin`update dbos.workflow_status set updated_at = updated_at - 8 * 86400000
    where workflow_uuid = ${sent.run_id}`;
  expect(await purgeEndedWorkflows(h.handle.db)).toBeGreaterThan(0);
  const [left] = await h.tdb.admin<{ n: number }[]>`
    select count(*)::int as n from dbos.operation_outputs where workflow_uuid = ${sent.run_id}`;
  expect(left?.n).toBe(0);
}, 60_000);
