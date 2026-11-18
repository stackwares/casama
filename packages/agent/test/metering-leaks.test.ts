/**
 * Metering leaks: media paid for but failed on our side, and a reply stopped while the model was
 * still thinking. Both were free before; the provider charged for them anyway.
 */
import { createDb, type DbHandle } from "@casama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import {
  builtinTools,
  CredentialResolver,
  directSteps,
  type FixtureFile,
  hashEmbedder,
  MediaChargedError,
  type MediaProvider,
  PostgresMemoryStore,
  ReplayGateway,
  registerAutonomyTools,
  runAgent,
  ToolRegistry,
} from "../src/index.ts";

let tdb: TestDatabase;
let h: DbHandle;
let orgId: string;
let userId: string;
let credId: string;

beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 5 });
  const user = await createAuthUser(tdb.admin, "meter@example.com");
  userId = user.id;
  const [org] = await tdb.admin<
    { id: string }[]
  >`insert into public.organizations (name, slug) values ('Meter Org', 'meter-org') returning id`;
  orgId = org!.id;
  await tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${userId}, 'owner')`;
  const [cred] = await tdb.admin<{ id: string }[]>`
    insert into public.model_credentials (org_id, provider, label, vault_secret_id)
    values (${orgId}, 'openrouter', 'Main', vault.create_secret('sk-or-meter-123456')) returning id`;
  credId = cred!.id;
});
afterAll(async () => {
  await h?.close();
  await tdb?.stop();
});

async function makeRun(text = "hi") {
  const [bot] = await tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name, model_policy, budget)
    values (${orgId}, ${userId}, 'Meter', ${tdb.admin.json({ primary: { credential_id: credId, model: "fixture-primary" } })},
            ${tdb.admin.json({ per_run_usd: 5, daily_usd: 50 })})
    returning id`;
  const [conv] = await tdb.admin<
    { id: string }[]
  >`insert into public.conversations (org_id, bot_id) values (${orgId}, ${bot!.id}) returning id`;
  const [run] = await tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, created_by) values (${orgId}, ${bot!.id}, ${conv!.id}, ${userId}) returning id`;
  await tdb.admin`insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
    values (${orgId}, ${conv!.id}, 'user', ${userId}, ${tdb.admin.json([{ type: "text", text }])}, ${run!.id})`;
  return { runId: run!.id, botId: bot!.id };
}

const ledger = (runId: string) =>
  tdb.admin<
    {
      kind: string;
      quantity: string;
      cost_usd: string;
      model: string | null;
      billable: boolean;
      meta: Record<string, unknown>;
    }[]
  >`select kind, quantity, cost_usd, model, billable, meta from public.usage_ledger where run_id = ${runId} order by kind`;

describe("media that failed after the provider took it", () => {
  /** A provider whose image and video calls fail the given way, paid by the server's key. */
  function failing(err: Error): MediaProvider {
    return {
      id: "openrouter",
      supports: () => true,
      paidBy: () => "openrouter",
      generateImage: async () => {
        throw err;
      },
      generateVideo: async () => {
        throw err;
      },
    };
  }
  function tools(provider: MediaProvider) {
    const reg = new ToolRegistry();
    registerAutonomyTools(reg, { db: h.db, fetch, mediaFor: async () => provider });
    return reg;
  }
  const ctxOf = (runId: string, botId: string) =>
    ({ runId, botId, orgId, output: async () => {}, emit: async () => {} }) as never;

  it("records a timed-out image once, marked failed, at the estimate with markup", async () => {
    const { runId, botId } = await makeRun();
    const reg = tools(
      failing(
        new MediaChargedError("OpenRouter image timed out", {
          quantity: 1,
          costUsd: 0.0336,
          model: "google/gemini-nano-banana-2.1",
          estimated: true,
        }),
      ),
    );
    await expect(
      reg.get("media.image.generate")!.execute({ prompt: "a cat" } as never, ctxOf(runId, botId)),
    ).rejects.toThrow("OpenRouter image timed out");
    const rows = await ledger(runId);
    expect(rows).toHaveLength(1);
    expect(rows[0]).toMatchObject({
      kind: "media_images",
      model: "google/gemini-nano-banana-2.1",
      billable: true,
      meta: { failed: true, estimated: true, provider_cost_usd: 0.0336, key: "server" },
    });
    expect(Number(rows[0]!.cost_usd)).toBeGreaterThan(0.0336);
  });

  it("records a video that timed out after submission, by its seconds", async () => {
    const { runId, botId } = await makeRun();
    const reg = tools(
      failing(
        new MediaChargedError("OpenRouter video timed out", {
          quantity: 4,
          costUsd: 4 * 0.069504,
          model: "google/gemini-omni-1.2-flash",
          estimated: true,
        }),
      ),
    );
    await expect(
      reg
        .get("media.video.generate")!
        .execute({ prompt: "waves", duration_s: 4 } as never, ctxOf(runId, botId)),
    ).rejects.toThrow("timed out");
    const rows = await ledger(runId);
    expect(rows).toHaveLength(1);
    expect(rows[0]).toMatchObject({ kind: "media_video_seconds", meta: { failed: true } });
    expect(Number(rows[0]!.quantity)).toBe(4);
  });

  it("records nothing when the provider refused the request", async () => {
    const { runId, botId } = await makeRun();
    const reg = tools(failing(new Error("OpenRouter returned 402: Insufficient credits")));
    await expect(
      reg.get("media.image.generate")!.execute({ prompt: "a cat" } as never, ctxOf(runId, botId)),
    ).rejects.toThrow("402");
    expect(await ledger(runId)).toHaveLength(0);
  });
});

describe("stopping a reply while the model thinks", () => {
  const thinking: FixtureFile[] = [
    {
      name: "thinking",
      turns: [
        {
          when: { lastUserIncludes: "think hard" },
          delayMs: 300,
          events: [
            { type: "progress" },
            { type: "progress" },
            { type: "progress" },
            { type: "progress" },
            { type: "progress" },
            { type: "progress" },
            { type: "progress" },
            { type: "progress" },
            { type: "text", text: "Done thinking." },
            {
              type: "finish",
              usage: { inputTokens: 1000, outputTokens: 100 },
              finishReason: "stop",
              model: "",
            },
          ],
        },
      ],
    },
  ];
  const deps = (gateway: ReplayGateway) => {
    const embedder = hashEmbedder();
    return {
      db: h.db,
      gateway,
      tools: builtinTools({
        db: h.db,
        memory: async () => new PostgresMemoryStore(h.db, embedder),
      }),
      credentials: new CredentialResolver(h.db),
      embedderFor: async () => embedder,
      step: directSteps,
      deltaIntervalMs: 20,
      cancelPollMs: 50,
      fallback: { backoffMs: 1 },
    };
  };

  // Thinking chunks aren't passed on by withFallback and carry no text, so only the prompt counts.
  it("pays for the prompt even though nothing was said yet", async () => {
    const { runId } = await makeRun("think hard about this");
    // Stopped once the model has the request (not before the step starts, however slow setup is).
    const gateway = new ReplayGateway(thinking);
    const inner = gateway.stream.bind(gateway);
    gateway.stream = (req) => {
      void tdb.admin`update public.runs set cancel_requested_at = now(), cancelled_by = ${userId} where id = ${runId}`.then(
        () => {},
      );
      return inner(req);
    };
    expect((await runAgent(runId, deps(gateway))).status).toBe("cancelled");
    const rows = await ledger(runId);
    const tin = rows.find((r) => r.kind === "tokens_in");
    const tout = rows.find((r) => r.kind === "tokens_out");
    expect(Number(tin?.quantity)).toBeGreaterThan(0);
    expect(Number(tin?.quantity)).not.toBe(1000); // estimated: the reply never finished
    expect(Number(tout?.quantity)).toBe(0);
    expect(tin?.model).toBe("fixture-primary");
    expect(tin?.billable).toBe(false); // the workspace's own key, as a normal step would be
    const [run] = await tdb.admin<
      { tokens_in: string }[]
    >`select tokens_in from public.runs where id = ${runId}`;
    expect(Number(run?.tokens_in)).toBe(Number(tin?.quantity));
  });
});
