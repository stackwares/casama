/**
 * Light projects (D-295): a project needs only a name and a bot, a topic can become one, what is
 * made in its chat (or in a run that works on it) is filed under it in the Library, a project that
 * grew out of a chat follows the chat, and working by itself is a switch.
 */
import { fileURLToPath } from "node:url";
import {
  fileRunUnderProject,
  NotificationService,
  projectHeartbeat,
  RecordingPushSender,
} from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/light-projects.json", import.meta.url));
let h: Harness;
let owner: { id: string; token: string };
let member: { id: string; token: string };
let orgId = "";
let botId = "";
let generalId = "";
let zineId = "";
let catId = "";
let catChat = "";
let dodgerId = "";

type Chat = {
  id: string;
  is_main: boolean;
  parent_conversation_id: string | null;
  project_id: string | null;
};
const settle = async () => {
  for (let i = 0; i < 200; i++) {
    const [r] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.runs where status in ('queued', 'running', 'waiting_approval')`;
    if (!r?.n) return;
    await new Promise((res) => setTimeout(res, 100));
  }
  throw new Error("runs did not settle");
};
const beat = async () => {
  const started = await projectHeartbeat(
    h.handle.db,
    (id) => h.deps.workflows.startRun(id),
    new NotificationService(h.handle.db, new RecordingPushSender()),
  );
  await settle();
  return started;
};
const chats = async () =>
  (await j(await h.request(`/v1/bots/${botId}/conversations`, { token: owner.token })))
    .items as Chat[];
const newChat = async (): Promise<Chat> =>
  j(
    await h.request("/v1/conversations", {
      method: "POST",
      token: owner.token,
      json: { bot_id: botId },
    }),
  );
const send = async (conversationId: string, text: string) => {
  await h.request(`/v1/conversations/${conversationId}/messages`, {
    method: "POST",
    token: owner.token,
    json: { text },
  });
  await settle();
  const [reply] = await h.tdb.admin<{ content: { type: string; text?: string }[] }[]>`
    select content from public.messages where conversation_id = ${conversationId} and role = 'assistant'
    order by created_at desc limit 1`;
  return (reply?.content ?? []).map((p) => p.text ?? "").join("");
};
const media = async (name: string, a: { conversation?: string; run?: string }) => {
  const [m] = await h.tdb.admin<{ id: string }[]>`
    insert into public.chat_media (org_id, bot_id, conversation_id, run_id, name, content_type, bytes, size)
    values (${orgId}, ${botId}, ${a.conversation ?? null}, ${a.run ?? null}, ${name}, 'image/png', ${Buffer.from("0123456789")}, 10)
    returning id`;
  const [c] = await h.tdb.admin<{ id: string; project_id: string | null }[]>`
    select id, project_id from public.creations where media_id = ${m!.id}`;
  return c!;
};
const create = (json: Record<string, unknown>, token = owner.token) =>
  h.request("/v1/projects", {
    method: "POST",
    token,
    json: { org_id: orgId, lead_bot_id: botId, ...json },
  });
const project = async (id: string, token = owner.token) =>
  h.request(`/v1/projects/${id}`, { token });
const patch = (id: string, json: Record<string, unknown>, token = owner.token) =>
  h.request(`/v1/projects/${id}`, { method: "PATCH", token, json });
const filed = async (id: string, token = owner.token) =>
  (await j(await h.request(`/v1/creations?org_id=${orgId}&project_id=${id}`, { token }))).items as {
    id: string;
    title: string;
    project_id: string | null;
    project_title: string | null;
  }[];

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  owner = await h.user("light-owner@example.com");
  member = await h.user("light-member@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Light" } }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
    }),
  );
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Maker",
          autonomy: "autonomous",
          model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
        },
      }),
    )
  ).id;
}, 60_000);
afterAll(async () => h?.stop());

describe("light projects (D-295)", () => {
  it("needs only a name and a bot, and gets its own topic; nothing starts by itself", async () => {
    const res = await create({ title: "Zine", autonomous: false });
    expect(res.status).toBe(201);
    const p = await j(res);
    zineId = p.id;
    expect(p).toMatchObject({
      status: "active",
      plan_status: "draft",
      autonomous: false,
      personal: false,
      goal_md: "",
      // On a team computer, under the bot's own folder (D-148).
      folder: expect.stringMatching(/^workspace\/(bots\/maker\/)?projects\/zine$/),
      can_steer: true,
    });
    // Its chat is a topic under General (made first, so the project's chat isn't General).
    const all = await chats();
    const general = all.find((c) => c.is_main);
    expect(general).toBeTruthy();
    generalId = general!.id;
    expect(all.find((c) => c.id === p.conversation_id)).toMatchObject({
      is_main: false,
      parent_conversation_id: generalId,
      project_id: zineId,
    });
    const [runs] = await h.tdb.admin<{ n: number }[]>`select count(*)::int as n from public.runs`;
    expect(runs?.n).toBe(0);
    expect(await beat()).toEqual([]);
    // Older apps send no `autonomous`: the project plans and runs by itself, so it needs a goal.
    const old = await create({ title: "No goal" });
    expect(old.status).toBe(400);
    expect((await j(old)).code).toBe("goal_needed");
  });

  it("a topic becomes a project, and what was made in it comes along", async () => {
    const topic = await newChat();
    expect(topic.parent_conversation_id).toBe(generalId);
    catChat = topic.id;
    await h.tdb.admin`
      insert into public.pages (org_id, bot_id, created_by, conversation_id, title, html)
      values (${orgId}, ${botId}, ${owner.id}, ${catChat}, 'Space Cat, the game', '<p>meow</p>')`;
    const before = await media("cat-sprite.png", { conversation: catChat });
    expect(before.project_id).toBeNull();

    // General stays everything's home.
    const general = await create({ title: "No", autonomous: false, conversation_id: generalId });
    expect(general.status).toBe(400);
    expect((await j(general)).code).toBe("general_not_project");
    // Only the person who started the chat.
    const other = await create(
      { title: "No", autonomous: false, conversation_id: catChat },
      member.token,
    );
    expect([403, 404]).toContain(other.status);

    const res = await create({ title: "Space Cat", autonomous: false, conversation_id: catChat });
    expect(res.status).toBe(201);
    const p = await j(res);
    catId = p.id;
    expect(p).toMatchObject({ personal: true, conversation_id: catChat, status: "active" });
    expect((await chats()).find((c) => c.id === catChat)).toMatchObject({
      project_id: catId,
      parent_conversation_id: generalId,
    });
    const items = await filed(catId);
    expect(items.map((c) => c.title).sort()).toEqual(["Space Cat, the game", "cat-sprite"]);
    expect(items.every((c) => c.project_id === catId && c.project_title === "Space Cat")).toBe(
      true,
    );
    const again = await create({ title: "Twice", autonomous: false, conversation_id: catChat });
    expect((await j(again)).code).toBe("already_project");
  });

  it("what is made in the project's chat afterwards is filed by itself, and runs there are the project's", async () => {
    expect((await media("cat-jump.png", { conversation: catChat })).project_id).toBe(catId);
    // The bot is told which project the chat belongs to.
    expect(await send(catChat, "what are we building?")).toBe("We are building Space Cat.");
    const [run] = await h.tdb.admin<{ project_id: string | null }[]>`
      select project_id from public.runs where conversation_id = ${catChat} order by created_at desc limit 1`;
    expect(run?.project_id).toBe(catId);
    const detail = await j(await project(catId));
    expect(detail.runs).toHaveLength(1);
    expect(detail.creations_count).toBe(3);
    expect(detail.latest_creation).toMatchObject({ title: "cat-jump", project_id: catId });
    const listed = (
      await j(await h.request(`/v1/projects?org_id=${orgId}`, { token: owner.token }))
    ).items as { id: string; creations_count: number; latest_creation?: { title: string } }[];
    expect(listed.find((x) => x.id === catId)).toMatchObject({
      creations_count: 3,
      latest_creation: { title: "cat-jump" },
    });
    const zine = listed.find((x) => x.id === zineId);
    expect(zine?.creations_count).toBe(0);
    expect(zine?.latest_creation).toBeUndefined();
  });

  it("an item can be taken out of a project and filed under another", async () => {
    const [first] = await filed(catId);
    const id = first!.id;
    const edit = (json: Record<string, unknown>, token = owner.token) =>
      h.request(`/v1/creations/${id}`, { method: "PATCH", token, json });
    expect((await j(await edit({ project_id: null }))).project_id).toBeNull();
    expect(await filed(catId)).toHaveLength(2);
    expect(await j(await edit({ project_id: zineId }))).toMatchObject({
      project_id: zineId,
      project_title: "Zine",
    });
    expect(await filed(zineId)).toHaveLength(1);
    expect((await edit({ project_id: "00000000-0000-4000-8000-00000000dead" })).status).toBe(404);
    expect((await edit({ project_id: catId }, member.token)).status).toBe(403);
    expect((await j(await edit({ project_id: catId }))).project_id).toBe(catId);
  });

  it("a project that grew out of a chat follows the chat; one made in the app is the workspace's", async () => {
    const seen = async () =>
      (
        (await j(await h.request(`/v1/projects?org_id=${orgId}`, { token: member.token })))
          .items as { id: string }[]
      ).map((x) => x.id);
    expect(await seen()).toEqual(expect.arrayContaining([zineId, catId]));
    await h.tdb.admin`update public.conversations set private = true where id = ${catChat}`;
    const ids = await seen();
    expect(ids).toContain(zineId);
    expect(ids).not.toContain(catId);
    expect((await project(catId, member.token)).status).toBe(404);
    expect((await project(catId)).status).toBe(200);
    // Its things were already private with the chat; the member can't file theirs under it either.
    expect(await filed(catId, member.token)).toEqual([]);
    await h.tdb.admin`update public.conversations set private = false where id = ${catChat}`;
  });

  it("a bot starts a project from a topic: the chat becomes the project's, and its plan needs no approval", async () => {
    const topic = await newChat();
    await send(topic.id, "make me a game");
    const [p] = await h.tdb.admin<
      {
        id: string;
        autonomous: boolean;
        personal: boolean;
        status: string;
        conversation_id: string | null;
        owner_user_id: string | null;
        slug: string;
      }[]
    >`select id, autonomous, personal, status, conversation_id, owner_user_id, slug
      from public.projects where title = 'Space Dodger'`;
    expect(p).toMatchObject({
      autonomous: false,
      personal: true,
      status: "active",
      conversation_id: topic.id,
      owner_user_id: owner.id,
      slug: "space-dodger",
    });
    dodgerId = p!.id;
    expect((await media("ship.png", { conversation: topic.id })).project_id).toBe(dodgerId);

    await send(topic.id, "list the to-dos");
    const detail = await j(await project(dodgerId));
    expect(detail).toMatchObject({ plan_status: "draft", plan_md: "Build, then polish." });
    // No sign-off in a project worked on together, and nobody is asked to approve anything.
    expect(detail.milestones).toMatchObject([
      { name: "Build", requires_signoff: false, status: "open", tickets_total: 2 },
    ]);
    const [asked] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.notifications where kind = 'project'`;
    expect(asked?.n).toBe(0);
    expect(await beat()).toEqual([]);
    // A milestone is done when its to-dos are (nothing else closes it here).
    await h.tdb.admin`update public.tasks set status = 'done' where project_id = ${dodgerId}`;
    expect((await j(await project(dodgerId))).milestones[0]).toMatchObject({
      status: "done",
      tickets_done: 2,
    });
    // "Blocked" is for projects that run alone; here the bot asks in the chat.
    await send(topic.id, "ask the owner");
    expect((await j(await project(dodgerId))).status).toBe("active");
  });

  it("from General only that run's work is filed; projects.open files a later run", async () => {
    await send(generalId, "start a project for the newsletter");
    const [p] = await h.tdb.admin<
      { id: string; conversation_id: string | null; personal: boolean }[]
    >`select id, conversation_id, personal from public.projects where title = 'Newsletter'`;
    expect(p).toMatchObject({ conversation_id: null, personal: true });
    const [run] = await h.tdb.admin<{ id: string; project_id: string | null }[]>`
      select id, project_id from public.runs where conversation_id = ${generalId} order by created_at desc limit 1`;
    expect(run?.project_id).toBe(p!.id);
    expect((await media("masthead.png", { run: run!.id })).project_id).toBe(p!.id);
    // General itself belongs to no project, so the next run there starts clean…
    expect((await chats()).find((c) => c.id === generalId)?.project_id ?? null).toBeNull();
    expect(await send(generalId, "what is open?")).toBe("Open projects seen.");
    // …until the bot opens the project it's asked about. A ticket it makes then is the project's.
    await send(generalId, "more art for the game please");
    const [later] = await h.tdb.admin<{ project_id: string | null }[]>`
      select project_id from public.runs where conversation_id = ${generalId} order by created_at desc limit 1`;
    expect(later?.project_id).toBe(dodgerId);
    const [ticket] = await h.tdb.admin<{ project_id: string | null }[]>`
      select project_id from public.tasks where title = 'Draw the ship'`;
    expect(ticket?.project_id).toBe(dodgerId);

    // What a run made before it was filed comes along.
    const [loose] = await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, created_by, trigger, status)
      values (${orgId}, ${botId}, ${owner.id}, 'chat', 'completed') returning id`;
    const early = await media("early.png", { run: loose!.id });
    expect(early.project_id).toBeNull();
    expect(await fileRunUnderProject(h.handle.db, { id: dodgerId, org_id: orgId }, loose!.id)).toBe(
      true,
    );
    const [moved] = await h.tdb.admin<{ project_id: string | null }[]>`
      select project_id from public.creations where id = ${early.id}`;
    expect(moved?.project_id).toBe(dodgerId);
  });

  it("working by itself is a switch: on plans for approval, off stops the heartbeat", async () => {
    const noGoal = await patch(zineId, { autonomous: true });
    expect(noGoal.status).toBe(400);
    expect((await j(noGoal)).code).toBe("goal_needed");
    // Nothing is posted into a chat while a run works there.
    const [busy] = await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger, status)
      values (${orgId}, ${botId}, (select conversation_id from public.projects where id = ${zineId}), ${owner.id}, 'chat', 'running')
      returning id`;
    expect((await patch(zineId, { autonomous: true, goal_md: "Print the zine." })).status).toBe(
      409,
    );
    await h.tdb.admin`update public.runs set status = 'completed' where id = ${busy!.id}`;

    const on = await patch(zineId, { autonomous: true, goal_md: "Print the zine." });
    expect(on.status).toBe(200);
    expect(await j(on)).toMatchObject({ autonomous: true, status: "planning" });
    await settle();
    let p = await j(await project(zineId));
    expect(p).toMatchObject({ plan_status: "proposed", plan_md: "One milestone." });
    const approved = await h.request(`/v1/projects/${zineId}/plan/approve`, {
      method: "POST",
      token: owner.token,
    });
    expect((await j(approved)).status).toBe("active");
    expect(await beat()).toHaveLength(1);

    const off = await patch(zineId, { autonomous: false });
    expect(await j(off)).toMatchObject({ autonomous: false, status: "active" });
    expect(await beat()).toEqual([]);
    // Finished, then picked up again.
    expect((await j(await patch(zineId, { status: "done" }))).status).toBe("done");
    expect((await j(await patch(zineId, { status: "active" }))).status).toBe("active");
    // On again: the plan approved earlier still stands, so it carries on without planning twice.
    p = await j(await patch(zineId, { autonomous: true }));
    expect(p).toMatchObject({ autonomous: true, status: "active", plan_status: "approved" });
    await patch(zineId, { autonomous: false });
  });
});
