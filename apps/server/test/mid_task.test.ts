/** Sending while the bot works: the message joins the active run instead of starting another. */
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let ana: { id: string; token: string };
let org: string;
let bot: string;

beforeAll(async () => {
  h = await startHarness({});
  ana = await h.user("midtask@example.com");
  org = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: ana.token, json: { name: "Mid" } }),
    )
  ).id;
  bot = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: ana.token,
        json: { org_id: org, name: "Ada" },
      }),
    )
  ).id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

describe("messages sent mid-task", () => {
  it("join the run that is working, and start a new one once it's done", async () => {
    const [conv] = await h.tdb.admin<{ id: string }[]>`
      insert into public.conversations (org_id, bot_id, created_by) values (${org}, ${bot}, ${ana.id}) returning id`;
    const [run] = await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, conversation_id, created_by, status) values (${org}, ${bot}, ${conv!.id}, ${ana.id}, 'running') returning id`;
    await h.tdb.admin`
      insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
      values (${org}, ${conv!.id}, 'user', ${ana.id}, ${h.tdb.admin.json([{ type: "text", text: "paint the fence" }])}, ${run!.id})`;
    const sent = await j(
      await h.request(`/v1/conversations/${conv!.id}/messages`, {
        method: "POST",
        token: ana.token,
        json: { text: "actually blue" },
      }),
    );
    expect(sent).toMatchObject({ run_id: run!.id, joined: true });

    await h.tdb.admin`update public.runs set status = 'completed' where id = ${run!.id}`;
    const after = await j(
      await h.request(`/v1/conversations/${conv!.id}/messages`, {
        method: "POST",
        token: ana.token,
        json: { text: "thanks" },
      }),
    );
    expect(after.run_id).not.toBe(run!.id);
    expect(after.joined).toBeUndefined();
  });
});
