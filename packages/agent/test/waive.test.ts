/** A run that failed on our side costs nothing (D-275). */
import { createDb, type DbHandle } from "@casama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, expect, it } from "vitest";
import { lowCreditWorkspaces, waiveFailedRun } from "../src/waive.ts";

let tdb: TestDatabase;
let h: DbHandle;
beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 2 });
});
afterAll(async () => {
  await h?.close();
  await tdb?.stop();
});

it("unsettled charges stop being billable; settled ones come back once as a refund", async () => {
  const user = await createAuthUser(tdb.admin, "waive@example.com");
  const [org] = await tdb.admin<{ id: string }[]>`
    insert into public.organizations (name, slug) values ('Waive', 'waive') returning id`;
  const [bot] = await tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name) values (${org!.id}, ${user.id}, 'B') returning id`;
  const [run] = await tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, created_by, status) values (${org!.id}, ${bot!.id}, ${user.id}, 'failed') returning id`;
  await tdb.admin`insert into public.usage_ledger (org_id, bot_id, run_id, kind, quantity, cost_usd, billable, billed_at) values
    (${org!.id}, ${bot!.id}, ${run!.id}, 'tokens_in', 1000, 0.25, true, null),
    (${org!.id}, ${bot!.id}, ${run!.id}, 'tokens_out', 100, 0.10, true, now()),
    (${org!.id}, ${bot!.id}, ${run!.id}, 'computer_seconds', 60, 0.05, true, null)`;
  expect(await waiveFailedRun(h.db, run!.id)).toBeCloseTo(0.35, 6);
  const rows = await tdb.admin<{ kind: string; billable: boolean }[]>`
    select kind, billable from public.usage_ledger where run_id = ${run!.id} order by kind`;
  // Computer time is still billed: the computer did run.
  expect(rows).toEqual([
    { kind: "computer_seconds", billable: true },
    { kind: "tokens_in", billable: false },
    { kind: "tokens_out", billable: true },
  ]);
  const refunds = await tdb.admin<{ delta: string }[]>`
    select delta from public.credit_ledger where org_id = ${org!.id} and reason = 'refund'`;
  expect(refunds.map((r) => Number(r.delta))).toEqual([0.1]);
  // Twice is the same as once.
  await waiveFailedRun(h.db, run!.id);
  expect(
    await tdb.admin`select 1 from public.credit_ledger where org_id = ${org!.id} and reason = 'refund'`,
  ).toHaveLength(1);
});

it("owners of a workspace whose credits fell under $1 are told once a week", async () => {
  const user = await createAuthUser(tdb.admin, "low@example.com");
  const [org] = await tdb.admin<{ id: string }[]>`
    insert into public.organizations (name, slug) values ('Low', 'low-credits') returning id`;
  await tdb.admin`insert into public.memberships (org_id, user_id, role) values (${org!.id}, ${user.id}, 'owner')`;
  await tdb.admin`select public.credit_apply(${org!.id}::uuid, 5, 'grant', 'test-grant', 'Start')`;
  await tdb.admin`insert into public.usage_ledger (org_id, kind, quantity, cost_usd, billable) values (${org!.id}, 'tokens_in', 1, 0.01, true)`;
  expect((await lowCreditWorkspaces(h.db)).filter((l) => l.org_id === org!.id)).toHaveLength(0);
  await tdb.admin`select public.credit_apply(${org!.id}::uuid, -4.5, 'usage', 'test-usage', 'Usage')`;
  const low = (await lowCreditWorkspaces(h.db)).filter((l) => l.org_id === org!.id);
  expect(low).toEqual([
    { org_id: org!.id, balance: expect.stringMatching(/^0\.5/), owner_id: user.id },
  ]);
  await tdb.admin`insert into public.notifications (user_id, org_id, kind) values (${user.id}, ${org!.id}, 'credits_low')`;
  expect((await lowCreditWorkspaces(h.db)).filter((l) => l.org_id === org!.id)).toHaveLength(0);

  // A new free workspace starts with a $1 grant: its first message ($0.01) leaves $0.99 and must
  // not immediately warn that credits are running low; warning waits until <25% ($0.25) is left.
  const [freeOrg] = await tdb.admin<{ id: string }[]>`
    insert into public.organizations (name, slug) values ('Free', 'free-starter') returning id`;
  await tdb.admin`insert into public.memberships (org_id, user_id, role) values (${freeOrg!.id}, ${user.id}, 'owner')`;
  await tdb.admin`select public.credit_apply(${freeOrg!.id}::uuid, 1, 'grant', 'monthly:free', 'Free')`;
  await tdb.admin`insert into public.usage_ledger (org_id, kind, quantity, cost_usd, billable) values (${freeOrg!.id}, 'tokens_in', 1, 0.01, true)`;
  await tdb.admin`select public.credit_apply(${freeOrg!.id}::uuid, -0.01, 'usage', 'first-msg', 'Usage')`;
  expect((await lowCreditWorkspaces(h.db)).filter((l) => l.org_id === freeOrg!.id)).toHaveLength(0);
  await tdb.admin`select public.credit_apply(${freeOrg!.id}::uuid, -0.79, 'usage', 'more-msg', 'Usage')`;
  expect((await lowCreditWorkspaces(h.db)).filter((l) => l.org_id === freeOrg!.id)).toEqual([
    { org_id: freeOrg!.id, balance: expect.stringMatching(/^0\.2/), owner_id: user.id },
  ]);
});

it("a give-back (a hold released, a failed run waived) isn't a top-up for the low-credit rule", async () => {
  const user = await createAuthUser(tdb.admin, "low-giveback@example.com");
  const [org] = await tdb.admin<{ id: string }[]>`
    insert into public.organizations (name, slug) values ('Give back', 'low-giveback') returning id`;
  await tdb.admin`insert into public.memberships (org_id, user_id, role) values (${org!.id}, ${user.id}, 'owner')`;
  await tdb.admin`select public.credit_apply(${org!.id}::uuid, 10, 'grant', 'monthly:test', 'Pro')`;
  await tdb.admin`insert into public.usage_ledger (org_id, kind, quantity, cost_usd, billable) values (${org!.id}, 'tokens_in', 1, 0.01, true)`;
  await tdb.admin`select public.credit_apply(${org!.id}::uuid, -9.2, 'usage', 'spent', 'Usage')`;
  // A hold larger than its usage comes back as a small positive usage entry: $0.81 is still low.
  await tdb.admin`select public.credit_apply(${org!.id}::uuid, 0.01, 'usage', 'hold-back', 'Usage')`;
  expect((await lowCreditWorkspaces(h.db)).filter((l) => l.org_id === org!.id)).toEqual([
    { org_id: org!.id, balance: expect.stringMatching(/^0\.81/), owner_id: user.id },
  ]);
});
