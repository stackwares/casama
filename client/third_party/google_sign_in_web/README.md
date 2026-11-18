# google_sign_in_web (empty)

Stands in for `google_sign_in_web` from pub.dev. That plugin downloads Google Identity Services
(`accounts.google.com/gsi/client`, about 100 KB) when it registers, so every visit to the web app
fetched it before the first frame. The web app never uses it: Continue with Google on the web is a
redirect (`googleNativeClient` in `lib/core/google_sign_in.dart` returns null on the web), so
nothing calls `GoogleSignIn` there.

If the web app ever signs in through Google's own button or One Tap, remove the
`google_sign_in_web` override from `client/pubspec.yaml` and delete this folder.
