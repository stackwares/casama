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

firebase.messaging();
