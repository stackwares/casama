import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/timeline/timeline_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('the run timeline links to its trace when the server has a viewer', (tester) async {
    await setSize(tester, const Size(800, 900));
    final backend = FakeBackend()
      ..runTraceId = '0123456789abcdef0123456789abcdef'
      ..traceUrlTemplate = 'https://traces.example/trace/{trace_id}';
    await tester.pumpWidget(harness(backend, const RunTimelineScreen(botId: botId, runId: 'run-1')));
    await tester.pumpAndSettle();
    expect(find.text('Trace 0123456789ab…'), findsOneWidget);
    expect(find.byKey(const Key('openTrace')), findsOneWidget);
  });

  testWidgets('no trace row without a trace id', (tester) async {
    await setSize(tester, const Size(800, 900));
    await tester.pumpWidget(harness(FakeBackend(), const RunTimelineScreen(botId: botId, runId: 'run-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('traceLink')), findsNothing);
  });
}
