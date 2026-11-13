import 'package:casama_app/features/admin/admin_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets(
    'the owner sees the server filling up and when it will be full (D-252)',
    (tester) async {
      await setSize(tester, const Size(900, 1600));
      final backend = FakeBackend()
        ..capacity = ServerCapacity(
          budgetMb: 9216,
          latest: ServerCapacityLatest(
            at: '2026-11-13T10:00:00Z',
            memTotalMb: 11960,
            memAvailableMb: 5000,
            load1: 1.2,
            cpus: 6,
            diskUsedPct: 41,
            computersRunning: 2,
            computersMemMb: 6144,
          ),
          days: [
            for (var i = 0; i < 10; i++)
              ServerCapacityDaysInner(
                day: '2026-11-0$i',
                peakComputersMemMb: 2048 + i * 400,
                peakComputers: 1,
                minAvailableMb: 5000,
                peakLoad1: 1,
              ),
          ],
          refusals30d: 2,
          fullInWeeks: 3.4,
          alerts: const [],
        );
      await tester.pumpWidget(harness(backend, const AdminScreen()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('capacityCard')));
      await tester.pumpAndSettle();
      expect(find.text('Server capacity'), findsOneWidget);
      expect(find.text('Computers: 6.0 GB of 9.0 GB'), findsOneWidget);
      expect(find.text('Full in about 3 weeks at this trend'), findsOneWidget);
      expect(find.text('2 computer starts refused in 30 days'), findsOneWidget);
    },
  );
}
