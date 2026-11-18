/* Firebase Cloud Messaging for the web app. The page passes this Firebase app on
   the script address (the same FIREBASE_* values as the Dart build) because a
   service worker cannot read --dart-define. Keep the SDK version in step with
   firebase_core_web's supportedFirebaseJsSdkVersion (13.1.0). */
const params = new URL(self.location.href).searchParams;
importScripts('https://www.gstatic.com/firebasejs/13.1.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/13.1.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: params.get('apiKey'),
  authDomain: params.get('authDomain') || undefined,
  projectId: params.get('projectId'),
  messagingSenderId: params.get('messagingSenderId'),
  appId: params.get('appId'),
});

// The bot's own face on the notification. Firebase's handler shows the push with only Chrome's
// logo, and leaves it to the page whenever a Casama tab is merely visible, so a tab on another
// screen got Chrome's "This site has been updated in the background" instead. This handler runs
// first: with a focused tab it steps aside (Firebase hands the push to the page), otherwise it
// draws the notification itself. Keep the lists in step with client/lib/ui/mascot.dart and
// bot_avatar.dart.
const MASCOTS = ['winky', 'sleepy', 'starry', 'lovey', 'cool', 'thinker', 'giggly', 'shy', 'focused', 'wow'];
const PALETTES = [
  ['#14B8A6', '#0F766E'], ['#6366F1', '#4338CA'], ['#F59E0B', '#D97706'], ['#EC4899', '#BE185D'],
  ['#3B82F6', '#1D4ED8'], ['#8B5CF6', '#6D28D9'], ['#10B981', '#047857'], ['#F97316', '#C2410C'],
];
const APP_ICON = '/icons/Icon-192.png';

function palette(name) {
  let h = 0;
  for (const c of name.toLowerCase()) h = (h * 31 + c.charCodeAt(0)) & 0x7fffffff;
  return PALETTES[h % PALETTES.length];
}

function initials(name) {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (!parts.length) return '?';
  const first = (p) => Array.from(p)[0];
  return (parts.length === 1 ? first(parts[0]) : first(parts[0]) + first(parts[1])).toUpperCase();
}

/** The initials tile the app draws, as a data URL (OffscreenCanvas works in Chrome's workers). */
async function initialsIcon(name) {
  if (typeof OffscreenCanvas === 'undefined') return APP_ICON;
  const size = 192;
  const canvas = new OffscreenCanvas(size, size);
  const ctx = canvas.getContext('2d');
  const [a, b] = palette(name);
  const g = ctx.createLinearGradient(0, 0, size, size);
  g.addColorStop(0, a);
  g.addColorStop(1, b);
  ctx.fillStyle = g;
  ctx.beginPath();
  ctx.roundRect(0, 0, size, size, size * 0.28);
  ctx.fill();
  ctx.fillStyle = '#fff';
  ctx.font = `600 ${size * 0.4}px system-ui, sans-serif`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(initials(name), size / 2, size / 2 + size * 0.02);
  const blob = await canvas.convertToBlob({ type: 'image/png' });
  const bytes = new Uint8Array(await blob.arrayBuffer());
  let bin = '';
  for (const x of bytes) bin += String.fromCharCode(x);
  return 'data:image/png;base64,' + btoa(bin);
}

async function botIcon(name, avatar) {
  if (typeof avatar === 'string' && avatar.startsWith('mascot:')) {
    const m = avatar.slice('mascot:'.length);
    if (MASCOTS.includes(m)) return `/assets/assets/mascots/${m}.png`;
  }
  if (typeof avatar === 'string' && /^https:\/\//.test(avatar)) return avatar;
  if (name) return initialsIcon(name).catch(() => APP_ICON);
  return APP_ICON;
}

self.addEventListener('push', (event) => {
  let msg;
  try {
    msg = event.data && event.data.json();
  } catch (_) {
    return;
  }
  const n = msg && msg.notification;
  if (!n || !n.title) return; // not ours to draw: Firebase decides
  event.stopImmediatePropagation();
  event.waitUntil((async () => {
    const tabs = await clients.matchAll({ type: 'window', includeUncontrolled: true });
    const focused = tabs.find((c) => c.focused && new URL(c.url).origin === self.location.origin);
    if (focused) {
      // The person is in the app, which shows it there. Same hand-off Firebase makes.
      focused.postMessage({ ...msg, isFirebaseMessaging: true, messageType: 'push-received' });
      return;
    }
    const data = msg.data || {};
    const approval = data.kind === 'approval_request';
    await self.registration.showNotification(n.title, {
      body: n.body || '',
      icon: await botIcon(data.bot_name, data.bot_avatar),
      badge: APP_ICON,
      // One per approval or notification: a resend replaces it instead of stacking a copy.
      tag: data.tag || data.approval_id || data.notification_id || undefined,
      renotify: !!(data.tag || data.approval_id || data.notification_id),
      // An approval waits on the person: it stays on screen until it's handled.
      requireInteraction: approval,
      timestamp: Date.now(),
      // The click handler below reads the link where Firebase keeps it.
      data: { FCM_MSG: msg },
    });
  })());
});

// A tapped notification opens its link in the app (D-325): the tab already open if there is
// one, otherwise a new one. The app uses hash URLs, so /bots/x/chat is /#/bots/x/chat. Added
// before Firebase's own handler, which would only open a link the server set on fcm_options.
self.addEventListener('notificationclick', (event) => {
  const msg = event.notification && event.notification.data && event.notification.data.FCM_MSG;
  const link = msg && msg.data && msg.data.link;
  if (typeof link !== 'string' || !link.startsWith('/')) return;
  event.stopImmediatePropagation();
  event.notification.close();
  const url = new URL('/#' + link, self.location.origin).href;
  event.waitUntil((async () => {
    const tabs = await clients.matchAll({ type: 'window', includeUncontrolled: true });
    const tab = tabs.find((c) => new URL(c.url).origin === self.location.origin);
    if (tab) {
      await tab.focus();
      if ('navigate' in tab) await tab.navigate(url).catch(() => {});
      return;
    }
    await clients.openWindow(url);
  })());
});

firebase.messaging();
