/**
 * Casama for Chrome's server pieces (D-323, Phase 1): its devices row gets data-only pushes it
 * draws itself, the push sender id is in /v1/config, and pictures it sends are marked as the
 * person's own so the agent reads them without a computer.
 */
import { NotificationService, RecordingPushSender } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let user: { id: string; token: string };
let orgId: string;
const push = new RecordingPushSender();

beforeAll(async () => {
  h = await startHarness({ env: { FCM_SENDER_ID: "123456789012" } });
  user = await h.user("chrome-ext@example.com");
  orgId = (
    await j(await h.request("/v1/orgs", { method: "POST", token: user.token, json: { name: "C" } }))
  ).id;
}, 60_000);
afterAll(async () => h?.stop());

describe("pushes to the extension", () => {
  it("are data-only for the chrome row, ordinary for the phone, with the approval's link", async () => {
    await h.tdb.admin`
      insert into public.devices (user_id, fcm_token, platform)
      values (${user.id}, 'phone-1', 'ios'), (${user.id}, 'chrome-1', 'chrome')`;
    const svc = new NotificationService(h.handle.db, push);
    await svc.notify(user.id, orgId, "approval_request", {
      title: "Approve sending the email?",
      body: "Mailer wants to send it",
      link: "/approvals/7d0a6c61-3b7e-4b39-a0c8-4ac1b8b1e0aa",
      urgent: true,
    });
    const phone = push.sent.find((p) => p.tokens.includes("phone-1"))!;
    const chrome = push.sent.find((p) => p.tokens.includes("chrome-1"))!;
    expect(phone.tokens).toEqual(["phone-1"]);
    expect(phone.message.dataOnly).toBeUndefined();
    expect(chrome.tokens).toEqual(["chrome-1"]);
    expect(chrome.message).toMatchObject({
      dataOnly: true,
      title: "Approve sending the email?",
      link: "/approvals/7d0a6c61-3b7e-4b39-a0c8-4ac1b8b1e0aa",
      data: { kind: "approval_request", user_id: user.id },
    });
    // The phone's push doesn't need to say whose it is.
    expect(phone.message.data).not.toHaveProperty("user_id");
  });

  it("the extension can register its own row; other platforms' names are still refused", async () => {
    await expect(
      h.tdb
        .admin`insert into public.devices (user_id, fcm_token, platform) values (${user.id}, 'x', 'firefox')`,
    ).rejects.toThrow(/devices_platform_check/);
  });
});

describe("GET /v1/config", () => {
  it("gives the push sender id when the server has one", async () => {
    expect((await j(await h.request("/v1/config"))).push_sender_id).toBe("123456789012");
  });
});

describe("messages with a picture from the browser", () => {
  it("mark media:<id> attachments as sent by the person", async () => {
    const [bot] = await h.tdb.admin<{ id: string }[]>`
      insert into public.bots (org_id, name, created_by) values (${orgId}, 'Eyes', ${user.id}) returning id`;
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: user.token,
        json: { bot_id: bot!.id },
      }),
    );
    const up = await j(
      await h.request(`/v1/media?org_id=${orgId}&name=shot.png`, {
        method: "POST",
        token: user.token,
        headers: { "content-type": "image/png" },
        body: new Uint8Array([0x89, 0x50, 0x4e, 0x47]),
      }),
    );
    const sent = await h.request(`/v1/conversations/${conv.id}/messages`, {
      method: "POST",
      token: user.token,
      json: {
        text: "What's on this page?",
        attachments: [
          { path: up.path, name: "shot.png", mime_type: "image/png", size: 4, uploaded: false },
          { path: "workspace/a.txt", name: "a.txt", mime_type: "text/plain", size: 1 },
        ],
      },
    });
    expect(sent.status).toBe(202);
    const { message_id } = await j(sent);
    const [m] = await h.tdb.admin<{ content: unknown }[]>`
      select content from public.messages where id = ${message_id}`;
    const files = (m!.content as { type: string; path?: string; uploaded?: boolean }[]).filter(
      (p) => p.type === "file",
    );
    expect(files).toEqual([
      expect.objectContaining({ path: up.path, uploaded: true }),
      expect.not.objectContaining({ uploaded: expect.anything() }),
    ]);
  });
});
