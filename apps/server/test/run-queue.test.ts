/**
 * Billing audit 2026-11-17: the runs queue is partitioned by workspace, so one workspace can't
 * take every run slot. Every queued run carries its workspace as the partition key, and runs queued
 * without one (by an older process) get it, or they would never start.
 */
import { fileURLToPath } from "node:url";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { keyQueuedRuns } from "../src/worker/run-queue.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));

describe("runs wait in their workspace's line", () => {
  let h: Harness;
  let token: string;
  let org: string;
  let bot: string;

  beforeAll(async () => {
    h = await startHarness({ worker: { fixtures: FIXTURES } });
    const owner = await h.user("queue-owner@example.com");
    token = owner.token;
    const post = async (path: string, json: unknown) => {
      const r = await h.request(path, { method: "POST", token, json });
      if (r.status >= 300) throw new Error(`${path}: ${r.status} ${await r.text()}`);
      return j(r);
    };
    org = (await post("/v1/orgs", { name: "Queue" })).id;
    const credential = (
      await post("/v1/credentials", {
        org_id: org,
        provider: "openrouter",
        label: "k",
        api_key: "sk-queue",
      })
    ).id;
    bot = (
      await post("/v1/bots", {
        org_id: org,
        name: "Liner",
        model_policy: { primary: { credential_id: credential, model: "fixture-main" } },
      })
    ).id;
  }, 60_000);

  afterAll(async () => {
    await h?.stop();
  });

  it("queues each run under its workspace, on a queue limited per workspace", async () => {
    const conv = await j(
      await h.request("/v1/conversations", { method: "POST", token, json: { bot_id: bot } }),
    );
    const sent = await j(
      await h.request(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token,
        json: { text: "hello" },
      }),
    );
    for (let i = 0; i < 100; i++) {
      const r = await j(await h.request(`/v1/runs/${sent.run_id}`, { token }));
      if (r.status === "completed") break;
      await new Promise((res) => setTimeout(res, 200));
    }
    let wf: { queue_partition_key: string | null; status: string } | undefined;
    for (let i = 0; i < 100; i++) {
      [wf] = await h.handle.db.execute<{ queue_partition_key: string | null; status: string }>(
        sql`select queue_partition_key, status from dbos.workflow_status where workflow_uuid = ${sent.run_id}`,
      );
      if (wf?.status === "SUCCESS") break;
      await new Promise((res) => setTimeout(res, 200));
    }
    expect(wf?.queue_partition_key).toBe(org);
    // It ran: the partitioned queue starts keyed runs.
    expect(wf?.status).toBe("SUCCESS");
    const [q] = await h.handle.db.execute<Record<string, unknown>>(
      sql`select * from dbos.queues where name = 'runs'`,
    );
    // The queue admits ten started runs for each one that may work (D-413): RunSlots keeps the
    // five working per workspace, so runs waiting for a person don't use the places up.
    const limit = Object.entries(q ?? {}).find(([k]) => k.startsWith("partition_concurrency"));
    expect(Number(limit?.[1])).toBe(50);
  }, 60_000);

  it("a run queued without a workspace key gets one", async () => {
    const conv = await j(
      await h.request("/v1/conversations", { method: "POST", token, json: { bot_id: bot } }),
    );
    const [run] = await h.handle.db.execute<{ id: string }>(sql`
      insert into public.runs (org_id, bot_id, conversation_id, trigger, status)
      values (${org}::uuid, ${bot}::uuid, ${conv.id}::uuid, 'chat', 'completed') returning id`);
    // As an older process would have queued it (a far-future time keeps the dispatcher off it).
    await h.handle.db.execute(sql`
      insert into dbos.workflow_status (workflow_uuid, status, name, queue_name, created_at, updated_at)
      values (${run!.id}, 'ENQUEUED', 'agentRun', 'runs', 0, 0)`);
    expect(await keyQueuedRuns(h.handle.db)).toBeGreaterThanOrEqual(1);
    const [wf] = await h.handle.db.execute<{ queue_partition_key: string | null }>(
      sql`select queue_partition_key from dbos.workflow_status where workflow_uuid = ${run!.id}`,
    );
    expect(wf?.queue_partition_key).toBe(org);
    await h.handle.db.execute(
      sql`update dbos.workflow_status set status = 'CANCELLED' where workflow_uuid = ${run!.id}`,
    );
  }, 60_000);
});
