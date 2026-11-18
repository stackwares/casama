/**
 * The first-run agreement (plan G6, §2 "Disclosure and consent"). The store asks for what is
 * collected and why to be shown before it happens, and again when it changes: bump
 * [CONSENT_VERSION] whenever a release starts sending something new, and the screen comes back.
 * Features that are off until the person switches them on, and explain what they send right at
 * the switch (Phase 4's browser as a device, bookmarks, captions), are disclosed there instead.
 */
import { getLocal, updateLocal } from "./store.ts";

export const CONSENT_VERSION = 1;

export const PRIVACY_URL = "https://casama.ai/privacy";

export async function hasConsent(): Promise<boolean> {
  const c = (await getLocal()).consent;
  return !!c && c.version >= CONSENT_VERSION;
}

export async function giveConsent(): Promise<void> {
  await updateLocal((s) => {
    s.consent = { version: CONSENT_VERSION, at: new Date().toISOString() };
  });
}
