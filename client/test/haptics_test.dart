import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/haptics.dart';
import 'package:casama_app/core/widgets.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/ui/form_sheet.dart';

void main() {
  const channel = MethodChannel('haptic_feedback');
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    HapticsHelper.debugReset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'canVibrate' ? true : null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    HapticsHelper.debugReset();
  });

  List<String> played() => [
    for (final c in calls)
      if (c.method != 'canVibrate') c.method,
  ];

  Widget app(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('an error snackbar plays the error haptic as touch feedback', (tester) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(onPressed: () => showError(context, Exception('Nope')), child: const Text('Fail')),
        ),
      ),
    );
    await tester.tap(find.text('Fail'));
    await tester.pump();
    expect(played(), ['error']);
    expect((calls.last.arguments as Map)['usage'], 'touch');
  });

  testWidgets('success and warning snackbars play their haptics', (tester) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => Column(
            children: [
              TextButton(onPressed: () => showSuccess(context, 'Saved'), child: const Text('Save')),
              TextButton(onPressed: () => showWarning(context, 'Check the email'), child: const Text('Warn')),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.tap(find.text('Warn'));
    await tester.pump();
    expect(played(), ['success', 'warning']);
  });

  testWidgets('flipping a form switch plays a light tap', (tester) async {
    var on = false;
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) => FormSwitch(title: 'Wi-Fi', value: on, onChanged: (v) => setState(() => on = v)),
        ),
      ),
    );
    await tester.tap(find.text('Wi-Fi'));
    await tester.pump();
    expect(on, isTrue);
    expect(played(), ['light']);
  });

  testWidgets('a disabled control stays disabled', (tester) async {
    expect(hapticOnChanged<bool>(null), isNull);
  });

  testWidgets('desktop plays nothing', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await HapticsHelper.success();
    debugDefaultTargetPlatformOverride = null;
    expect(calls, isEmpty);
  });

  testWidgets('without the plugin nothing throws', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    // The test engine answers unknown channels for real, outside the test's fake clock.
    await tester.runAsync(() async {
      await HapticsHelper.error();
      await HapticsHelper.error();
    });
  });
}
