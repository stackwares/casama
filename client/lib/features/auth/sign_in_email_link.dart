// The address a link asked the sign-in screen to start with (`/sign-in?email=`, sent by casama.ai's
// invite page after a claim). On the web, `web/boot.js` takes it out of the page's address before
// the app or its analytics start, so the address never ends up in an event's page URL, and leaves
// it in the tab's session storage for [takeSignInEmailFromPage]. Null off the web.
export 'sign_in_email_link_stub.dart'
    if (dart.library.js_interop) 'sign_in_email_link_web.dart';
