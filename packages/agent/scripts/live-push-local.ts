/**
 * A Live Activity push on a local stack, without Firebase (D-324, Phase 4): runs the real
 * LiveRunPusher against the local database for one run, with a sender that writes the APNs
 * payload Firebase would hand to Apple into a file per push instead of sending it. Deliver a file
 * to the Simulator with the device tools, for example
 *
 *   agent-device push ai.casama.app.push-type.liveactivity <file>
 *
 *   DATABASE_URL=… node packages/agent/scripts/live-push-local.ts <run id> <out dir>
 *
 * It feeds the pusher a start, a step and then a request for an OK (it writes nothing to the run),
 * so the last file says "Needs your OK".
 */
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { createDb } from "@casama/db";
import { LiveRunPusher } from "../src/live-runs.ts";
import { FcmPushSender, fcmLiveMessage, type PushSender } from "../src/notifications.ts";

const [runId, out, mode] = process.argv.slice(2);
if (!runId || !out || !process.env.DATABASE_URL) {
  console.error("usage: DATABASE_URL=… node live-push-local.ts <run id> <out dir>");
  process.exit(2);
}
mkdirSync(out, { recursive: true });
const h = createDb(process.env.DATABASE_URL, { max: 1 });
let n = 0;
const files: PushSender = {
  send: async () => ({ invalidTokens: [] }),
  async sendLive(targets, update) {
    for (const t of targets) {
      // The Simulator has no Firebase token; Firebase only needs one to find the phone.
      const m = fcmLiveMessage({ ...t, fcm_token: t.fcm_token ?? "simulator" }, update);
      if (!m) continue;
      const file = join(
        out,
        `${String(++n).padStart(2, "0")}-${t.platform}-${update.state.phase}.json`,
      );
      writeFileSync(file, JSON.stringify("apns" in m ? m.apns.payload : m.data, null, 2));
      console.log(
        `${file}  ${"apns" in m ? `priority ${m.apns.headers["apns-priority"]}` : m.android.priority}`,
      );
    }
    return { invalidTokens: [] };
  },
};
// The service account inline or as a file path, as the server reads it.
const account = process.env.FCM_SERVICE_ACCOUNT?.trim();
const fcm =
  process.env.LIVE_SEND === "1" && account
    ? new FcmPushSender(account.startsWith("{") ? account : readFileSync(account, "utf8"))
    : null;
const pusher = new LiveRunPusher(
  h.db,
  fcm
    ? {
        send: async () => ({ invalidTokens: [] }),
        async sendLive(targets, update) {
          await files.sendLive?.(targets, update);
          const r = await fcm.sendLive(targets, update);
          console.log(`sent through Firebase; invalid tokens: ${r.invalidTokens.length}`);
          return r;
        },
      }
    : files,
  { stepEveryMs: 0 },
);
if (mode === "finish") {
  pusher.observe(runId, "run.completed", {});
} else {
  pusher.observe(runId, "run.started", {});
  pusher.observe(runId, "tool.started", { call_id: "c1", tool: "files.read", args_redacted: {} });
  pusher.observe(runId, "approval.requested", {
    approval_id: "7d4c2f1e-8a3b-4c5d-9e6f-0a1b2c3d4e5f",
    tool: "shell.exec",
    args_redacted: {},
    risk: "high",
  });
}
await pusher.idle();
await h.close();
if (!n) {
  console.error("No phone follows this run (no live token for it).");
  process.exit(1);
}
