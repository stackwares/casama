import { createSign } from "node:crypto";
import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";

export interface PushMessage {
  title: string;
  body: string;
  /** Deep link path in the app, for example /approvals/{id} or /bots/{id}/chat. */
  link?: string;
  data?: Record<string, string>;
}

/** Sends push notifications to device tokens. */
export interface PushSender {
  send(tokens: string[], message: PushMessage): Promise<{ invalidTokens: string[] }>;
}

/** Records pushes (tests and installs without FCM). */
export class RecordingPushSender implements PushSender {
  readonly sent: Array<{ tokens: string[]; message: PushMessage; at: number }> = [];
  async send(tokens: string[], message: PushMessage) {
    this.sent.push({ tokens, message, at: Date.now() });
    return { invalidTokens: [] };
  }
}

/** Firebase Cloud Messaging HTTP v1 (APNs through FCM) with a service account. */
export class FcmPushSender implements PushSender {
  private readonly account: { client_email: string; private_key: string; project_id: string };
  private token: { value: string; expires: number } | null = null;
  private readonly fetchImpl: typeof fetch;

  constructor(serviceAccountJson: string, fetchImpl: typeof fetch = fetch) {
    this.account = JSON.parse(serviceAccountJson);
    this.fetchImpl = fetchImpl;
  }

  private async accessToken() {
    if (this.token && this.token.expires > Date.now() + 60_000) return this.token.value;
    const now = Math.floor(Date.now() / 1000);
    const b64 = (o: object) => Buffer.from(JSON.stringify(o)).toString("base64url");
    const unsigned = `${b64({ alg: "RS256", typ: "JWT" })}.${b64({
      iss: this.account.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    })}`;
    const signature = createSign("RSA-SHA256")
      .update(unsigned)
      .sign(this.account.private_key, "base64url");
    const res = await this.fetchImpl("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: `${unsigned}.${signature}`,
      }),
    });
    if (!res.ok) throw new Error(`FCM auth failed with ${res.status}`);
    const json = (await res.json()) as { access_token: string; expires_in: number };
    this.token = { value: json.access_token, expires: Date.now() + json.expires_in * 1000 };
    return this.token.value;
  }

  async send(tokens: string[], message: PushMessage) {
    const invalidTokens: string[] = [];
    const access = await this.accessToken();
    for (const token of tokens) {
      const res = await this.fetchImpl(
        `https://fcm.googleapis.com/v1/projects/${this.account.project_id}/messages:send`,
        {
          method: "POST",
          headers: { authorization: `Bearer ${access}`, "content-type": "application/json" },
          body: JSON.stringify({
            message: {
              token,
              notification: { title: message.title, body: message.body },
              data: { ...message.data, ...(message.link ? { link: message.link } : {}) },
              apns: { payload: { aps: { sound: "default" } } },
            },
          }),
        },
      );
      if (res.status === 404 || res.status === 400) invalidTokens.push(token);
    }
    return { invalidTokens };
  }
}

/** In-app inbox row plus push to the user's devices. */
export class NotificationService {
  readonly db: Database;
  readonly push: PushSender;
  constructor(db: Database, push: PushSender) {
    this.db = db;
    this.push = push;
  }

  async notify(
    userId: string,
    orgId: string | null,
    kind: string,
    message: PushMessage & Record<string, unknown>,
  ) {
    const [row] = await this.db.execute<{ id: string }>(sql`
      insert into public.notifications (user_id, org_id, kind, payload)
      values (${userId}::uuid, ${orgId}::uuid, ${kind}, ${JSON.stringify(message)}::jsonb) returning id`);
    const devices = await this.db.execute<{ fcm_token: string }>(
      sql`select fcm_token from public.devices where user_id = ${userId}::uuid`,
    );
    if (devices.length) {
      const { invalidTokens } = await this.push.send(
        devices.map((d) => d.fcm_token),
        {
          title: message.title,
          body: message.body,
          link: message.link,
          data: { notification_id: row?.id ?? "", kind },
        },
      );
      for (const t of invalidTokens)
        await this.db.execute(sql`delete from public.devices where fcm_token = ${t}`);
    }
    return row?.id;
  }
}
