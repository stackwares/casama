/**
 * Activity-based keep-awake (D-195, refines D-178). An open live view or terminal no longer keeps
 * a computer awake by itself: only a person's input, or the app's presence beat while someone is
 * actually there, touches `last_active_at`. The app-side timings live in
 * client/lib/core/user_activity.dart (presence every 60 s while the person touched the app in the
 * last 3 minutes); idle sleep after 5 minutes is IDLE_SLEEP_MS in packages/agent/src/computers.ts.
 */

/** Sent by the app over the live-view and terminal websockets; never forwarded to the computer. */
export const PRESENCE_EVENT = "presence";

/** At most one touch per connection this often, however much input arrives. */
export const TOUCH_THROTTLE_MS = 30_000;

/** Whether a text frame is the app's presence beat: `{"event":"presence"}`. */
export function isPresence(data: unknown): boolean {
  const text = String(data);
  if (!text.includes(PRESENCE_EVENT)) return false;
  try {
    return (JSON.parse(text) as { event?: unknown }).event === PRESENCE_EVENT;
  } catch {
    return false;
  }
}

/** A per-connection toucher: the first call touches, later ones at most every TOUCH_THROTTLE_MS. */
export function throttledTouch(touch: () => Promise<unknown>, now: () => number = Date.now) {
  let last = Number.NEGATIVE_INFINITY;
  return () => {
    const t = now();
    if (t - last < TOUCH_THROTTLE_MS) return;
    last = t;
    void touch().catch(() => {});
  };
}
