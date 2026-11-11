/// Browser sign-in that comes back to the app on 127.0.0.1, for desktops that don't open
/// casama:// links (Windows and Linux).
library;

export 'desktop_sign_in_stub.dart'
    if (dart.library.io) 'desktop_sign_in_io.dart';
