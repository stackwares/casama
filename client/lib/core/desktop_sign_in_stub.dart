/// Web: the browser comes back to the site itself, so there is no listener.
bool get loopbackSignInPlatform => false;

class LoopbackSignIn {
  LoopbackSignIn._();

  static Future<LoopbackSignIn> start() =>
      throw UnsupportedError('Loopback sign-in runs only in the desktop apps.');

  String get redirectUrl =>
      throw UnsupportedError('Loopback sign-in runs only in the desktop apps.');

  Future<void> wait(
    Future<String?> Function(Map<String, String> query) finish, {
    Duration timeout = const Duration(minutes: 5),
  }) async {}

  Future<void> close() async {}
}
