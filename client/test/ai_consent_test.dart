import 'package:casama/core/backend.dart';
import 'package:casama/features/privacy/ai_consent_step.dart';
import 'package:casama/features/settings/name_step.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets(
    'consent comes before the name step, and nothing waits once agreed',
    (tester) async {
      await setSize(tester, const Size(400, 800));
      final backend = FakeBackend()
        ..aiConsent = null
        ..about = const AboutYouView(
          displayName: 'Robin Park',
          nameAsked: false,
        );
      await tester.pumpWidget(harness(backend, const _Steps()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('aiConsentStep')), findsOneWidget);
      expect(find.byKey(const Key('nameStep')), findsNothing);
      expect(find.textContaining('OpenRouter'), findsOneWidget);

      await tester.tap(find.byKey(const Key('aiConsentAgree')));
      await tester.pumpAndSettle();
      expect(backend.aiConsent, isNotNull);
      expect(find.byKey(const Key('aiConsentStep')), findsNothing);
      expect(find.byKey(const Key('nameStep')), findsOneWidget);
    },
  );

  testWidgets('people who agreed never see the consent step', (tester) async {
    await setSize(tester, const Size(400, 800));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const _Steps()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aiConsentStep')), findsNothing);
  });

  testWidgets('withdrawing brings the step back', (tester) async {
    await setSize(tester, const Size(400, 800));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const _Steps()));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(_Steps)),
    );
    await container.read(aiConsentProvider.notifier).set(false);
    await tester.pumpAndSettle();
    expect(backend.aiConsent, isNull);
    expect(find.byKey(const Key('aiConsentStep')), findsOneWidget);
  });
}

class _Steps extends ConsumerWidget {
  const _Steps();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Stack(
    children: [
      const Scaffold(body: Text('app')),
      if (ref.watch(aiConsentNeededProvider))
        const Positioned.fill(child: AiConsentStep())
      else if (ref.watch(nameStepNeededProvider) ?? false)
        const Positioned.fill(child: NameStep()),
    ],
  );
}
