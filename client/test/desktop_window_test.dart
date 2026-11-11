import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/desktop_window.dart';

void main() {
  test('the first window fits the sidebar, chat and computer panel, and leaves the dock or taskbar room', () {
    expect(defaultWindowSize(const Size(1440, 900)), const Size(1320, 760)); // 13-15" laptops
    expect(defaultWindowSize(const Size(1920, 1080)), const Size(1440, 940)); // 1080p monitors
    expect(defaultWindowSize(const Size(2560, 1440)), const Size(1440, 960)); // big screens: capped
    expect(defaultWindowSize(const Size(1366, 768)), const Size(1246, 640)); // small Windows laptops
    expect(defaultWindowSize(const Size(1024, 700)), const Size(960, 620)); // small screens: the minimum that still fits
  });
}
