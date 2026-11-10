/// ChatGPT plan sign-in needs a loopback listener, which only the desktop apps have (D-091).
library;

export 'chatgpt_connect_stub.dart' if (dart.library.io) 'chatgpt_connect_io.dart';
