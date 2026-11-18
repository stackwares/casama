/**
 * How this server sends pushes: its own Firebase key first; without one, a server linked to Casama
 * Cloud sends through the cloud's relay (D-296), since only Casama's key can address the store
 * apps; otherwise nothing goes out. The worker's notifications and the capacity alerts (D-252)
 * both use it, so an alert reaches the owner's phone the same way everything else does.
 */
import {
  CloudRelayPushSender,
  FcmPushSender,
  type PushSender,
  RecordingPushSender,
} from "@casama/agent";
import type { Database } from "@casama/db";
import { privateNotifications } from "./link-settings.ts";

export function serverPushSender(o: {
  db: Database;
  fcmServiceAccountJson?: string;
  cloud?: { url: string; key: string };
  onRelayError?: (error: Error) => void;
  /** For tests: how the relay reaches Casama Cloud. */
  fetch?: typeof fetch;
}): PushSender {
  if (o.fcmServiceAccountJson) return new FcmPushSender(o.fcmServiceAccountJson);
  if (o.cloud)
    return new CloudRelayPushSender(o.cloud, {
      private: () => privateNotifications(o.db),
      onError: o.onRelayError,
      ...(o.fetch ? { fetch: o.fetch } : {}),
    });
  return new RecordingPushSender();
}
