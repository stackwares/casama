import { startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { createLogger } from "@casama/observability";
import { DBOS } from "@dbos-inc/dbos-sdk";
import { afterAll, beforeAll, expect, it } from "vitest";
import { pingWorkflow, startWorker } from "../src/worker/index.ts";

let tdb: TestDatabase;
let worker: { stop: () => Promise<void> };
beforeAll(async () => {
  tdb = await startTestDatabase();
  worker = await startWorker({
    databaseUrl: tdb.url,
    logger: createLogger("test", "error"),
    logLevel: "error",
  });
});
afterAll(async () => {
  await worker?.stop();
  await tdb?.stop();
});

it("runs the test workflow durably and once per workflow id", async () => {
  const h1 = await DBOS.startWorkflow(pingWorkflow, { workflowID: "ping-1" })("hello");
  expect(await h1.getResult()).toBe("HELLO!");
  // Same id returns the recorded result instead of running again.
  const h2 = await DBOS.startWorkflow(pingWorkflow, { workflowID: "ping-1" })("different");
  expect(await h2.getResult()).toBe("HELLO!");
  const steps = await DBOS.listWorkflowSteps("ping-1");
  expect(steps?.map((s) => s.name)).toEqual(["upper", "exclaim"]);
});
