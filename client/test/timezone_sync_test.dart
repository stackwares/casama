import 'package:casama_app/core/timezone_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('timezone sync (D-250)', () {
    test('saves the device timezone when the profile differs, once', () async {
      var profile = 'UTC';
      var saves = 0;
      final s = TimezoneSync(
        read: () async => 'Asia/Manila',
        current: () async => profile,
        save: (tz) async {
          profile = tz;
          saves++;
        },
      );
      await s.sync();
      await s.sync();
      expect(profile, 'Asia/Manila');
      expect(saves, 1);
    });

    test('leaves the profile alone when it already matches, or the name is not IANA', () async {
      var saves = 0;
      Future<void> save(String _) async => saves++;
      await TimezoneSync(read: () async => 'Asia/Manila', current: () async => 'Asia/Manila', save: save).sync();
      await TimezoneSync(read: () async => 'PST', current: () async => 'UTC', save: save).sync();
      await TimezoneSync(read: () async => null, current: () async => 'UTC', save: save).sync();
      expect(saves, 0);
      expect(TimezoneSync.usable('America/Argentina/Buenos_Aires'), isTrue);
      expect(TimezoneSync.usable('Etc/GMT+8'), isTrue);
      expect(TimezoneSync.usable('UTC'), isTrue);
    });

    test('a failing read or save never throws', () async {
      await TimezoneSync(read: () async => throw Exception('no plugin'), current: () async => 'UTC', save: (_) async {}).sync();
      await TimezoneSync(read: () async => 'Europe/Berlin', current: () async => 'UTC', save: (_) async => throw Exception('offline')).sync();
    });
  });
}
