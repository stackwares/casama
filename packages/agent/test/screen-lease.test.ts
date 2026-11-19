/**
 * One run at a time drives a computer's screen: its browser and its desktop (D-413). Before, two
 * runs of one bot (two topics, a routine beside a chat) both drove the one browser on its computer.
 */
import { createDb, type DbHandle } from "@casama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import {
  claimScreen,
  releaseScreen,
  SCREEN_LEASE_SECONDS,
  screenBusyMessage,
  waitForScreen,
} from "../src/index.ts";
import { backendFor } from "../src/tools/browser.ts";
import type { ToolContext } from "../src/tools/registry.ts";

let tdb: TestDatabase;
let h: DbHandle;
let orgId: string;
let userId: string;
let ada: string;
let milo: string;
let computer: { id: string; org_id: string };

beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 5 });
  userId = (await createAuthUser(tdb.admin, "screen@example.com")).id;
  const [org] = await tdb.admin<{ id: string }[]>`
    insert into public.organizations (name, slug) values ('Screen Org', 'screen-org') returning id`;
  orgId = org!.id;
  const bot = async (name: string) =>
    (
      await tdb.admin<{ id: string }[]>`
        insert into public.bots (org_id, created_by, name) values (${orgId}, ${userId}, ${name}) returning id`
    )[0]!.id;
  ada = await bot("Ada");
  milo = await bot("Milo");
  // Every workspace has a team computer.
  const [c] = await tdb.admin<{ id: string }[]>`
    select id from public.computers where org_id = ${orgId} and kind = 'team'`;
  computer = { id: c!.id, org_id: orgId };
});
afterAll(async () => {
  await h?.close();
  await tdb?.stop();
});

/** A run of [botId], working, in a chat titled [title]. */
async function run(botId: string, title: string | null = null, parent: string | null = null) {
  const [conv] = await tdb.admin<{ id: string }[]>`
    insert into public.conversations (org_id, bot_id, created_by, title) values (${orgId}, ${botId}, ${userId}, ${title}) returning id`;
  const [r] = await tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, created_by, status, parent_run_id)
    values (${orgId}, ${botId}, ${conv!.id}, ${userId}, 'running', ${parent}) returning id`;
  return r!.id;
}
const end = (runId: string) =>
  tdb.admin`update public.runs set status = 'completed', ended_at = now() where id = ${runId}`;
const free = () => tdb.admin`delete from public.computer_screen_leases`;

describe("the computer's screen", () => {
  it("goes to the first run that uses it; another run of the same bot is told who has it", async () => {
    await free();
    const trip = await run(ada, "Plan the trip");
    const taxes = await run(ada, "Taxes");
    expect(await claimScreen(h.db, computer, { runId: trip, botId: ada })).toBeNull();
    // Using it again renews the same lease.
    expect(await claimScreen(h.db, computer, { runId: trip, botId: ada })).toBeNull();
    const holder = await claimScreen(h.db, computer, { runId: taxes, botId: ada });
    expect(holder).toEqual({ bot: "Ada", chat: "Plan the trip", sameBot: true });
    expect(screenBusyMessage(holder!)).toContain(
      'You are using your computer\'s browser and screen in another chat right now ("Plan the trip")',
    );
    await end(trip);
    await end(taxes);
  });

  it("another bot on a team computer waits for it too", async () => {
    await free();
    const mine = await run(ada, "Research");
    const theirs = await run(milo);
    expect(await claimScreen(h.db, computer, { runId: mine, botId: ada })).toBeNull();
    const holder = await claimScreen(h.db, computer, { runId: theirs, botId: milo });
    expect(holder).toMatchObject({ bot: "Ada", sameBot: false });
    expect(screenBusyMessage(holder!)).toContain("Ada is using this computer's browser and screen");
    await end(mine);
    await end(theirs);
  });

  it("is free again when the run ends, gives it back, or stops using it for a while", async () => {
    await free();
    const first = await run(ada);
    const second = await run(ada);
    const third = await run(ada);
    const fourth = await run(ada);
    expect(await claimScreen(h.db, computer, { runId: first, botId: ada })).toBeNull();
    // The run ended without giving it back (the worker stopped): the next run takes it.
    await end(first);
    expect(await claimScreen(h.db, computer, { runId: second, botId: ada })).toBeNull();
    // Given back at the end of a run.
    await releaseScreen(h.db, second);
    expect(await claimScreen(h.db, computer, { runId: third, botId: ada })).toBeNull();
    // Not used for longer than the lease (the run moved on to other work, or waits for a yes).
    await tdb.admin`
      update public.computer_screen_leases set expires_at = now() - make_interval(secs => ${SCREEN_LEASE_SECONDS})`;
    expect(await claimScreen(h.db, computer, { runId: fourth, botId: ada })).toBeNull();
    for (const r of [second, third, fourth]) await end(r);
  });

  it("a run asked by the run that has it shares it: they are the same piece of work", async () => {
    await free();
    const asking = await run(ada, "Book the flights");
    const helper = await run(ada, null, asking);
    const deeper = await run(ada, null, helper);
    const other = await run(ada, "Something else");
    expect(await claimScreen(h.db, computer, { runId: asking, botId: ada })).toBeNull();
    // The run that asked is waiting for its helper: without this they would block each other.
    expect(await claimScreen(h.db, computer, { runId: helper, botId: ada })).toBeNull();
    await claimScreen(h.db, computer, { runId: asking, botId: ada });
    expect(await claimScreen(h.db, computer, { runId: deeper, botId: ada })).toBeNull();
    expect(await claimScreen(h.db, computer, { runId: other, botId: ada })).toMatchObject({
      sameBot: true,
    });
    for (const r of [asking, helper, deeper, other]) await end(r);
  });

  it("a run waits for it, gets it as soon as it is free, and stops waiting when it is stopped", async () => {
    await free();
    const first = await run(ada, "Long research");
    const second = await run(ada);
    const stopped = await run(ada);
    expect(await claimScreen(h.db, computer, { runId: first, botId: ada })).toBeNull();
    const waiting = waitForScreen(
      h.db,
      computer,
      { runId: second, botId: ada },
      { waitMs: 5000, pollMs: 20 },
    );
    await new Promise((r) => setTimeout(r, 80));
    await releaseScreen(h.db, first);
    expect(await waiting).toBeNull();

    // Still in use when the wait is over: the run is told, and can go on without the browser.
    const busy = await waitForScreen(
      h.db,
      computer,
      { runId: first, botId: ada },
      { waitMs: 60, pollMs: 20 },
    );
    expect(busy).toMatchObject({ sameBot: true });
    // The person pressed Stop: no point in waiting out the rest.
    await tdb.admin`update public.runs set cancel_requested_at = now() where id = ${stopped}`;
    const from = Date.now();
    await waitForScreen(
      h.db,
      computer,
      { runId: stopped, botId: ada },
      { waitMs: 30_000, pollMs: 20 },
    );
    expect(Date.now() - from).toBeLessThan(5000);
    for (const r of [first, second, stopped]) await end(r);
  });
});

describe("browser tools", () => {
  it("take the screen for the bot's own computer, not for the person's own Chrome", async () => {
    let claims = 0;
    const base = {
      computer: async () => ({}) as never,
      claimScreen: async () => {
        claims++;
      },
    } as unknown as ToolContext;
    expect((await backendFor(base)).kind).toBe("computer");
    expect(claims).toBe(1);

    const mine = { call: async () => ({ ok: true as const, text: "" }) };
    const withMine = {
      ...base,
      browser: {
        preferred: "mine",
        picked: undefined,
        ownUrls: [],
        pick: () => {},
        mine: async () => mine,
        waitMine: async () => mine,
      },
    } as unknown as ToolContext;
    expect((await backendFor(withMine)).kind).toBe("mine");
    expect(claims).toBe(1);
    expect((await backendFor(withMine, "computer")).kind).toBe("computer");
    expect(claims).toBe(2);
  });
});
