import 'package:casama/core/server_reachability.dart';
import 'package:casama/features/selfhost/local_docker.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama/ui/server_reachability_bar.dart';
import 'package:casama/ui/server_unreachable_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// This computer's own server is down because Docker isn't running (closed after a restart, or
/// quit from its menu): the bar and the launch screen say so and open Docker.
void main() {
  late int opened;

  setUp(() {
    opened = 0;
    checkLocalDocker = (_) async => true;
    openDocker = () async {
      opened++;
      return true;
    };
    canOpenDocker = () => true;
  });

  tearDown(() {
    checkLocalDocker = localDockerDown;
    serverReachability.value = Reachability.ok;
  });

  testWidgets('the bar says Docker is closed and offers to open it', (
    tester,
  ) async {
    await setSize(tester, const Size(1000, 800));
    await tester.pumpWidget(
      harness(FakeBackend(), const ServerReachabilityBar(child: SizedBox())),
    );
    serverReachability.value = Reachability.unreachable;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text("Docker isn't running, so your server is stopped"),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('serverReachabilityOpenDocker')),
      findsOneWidget,
    );

    // Someone else's server, or Docker running: the usual wording, no Docker button.
    checkLocalDocker = (_) async => false;
    serverReachability.value = Reachability.ok;
    await tester.pump(const Duration(milliseconds: 300));
    serverReachability.value = Reachability.unreachable;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text("Can't reach your Casama server"), findsOneWidget);
    expect(find.byKey(const Key('serverReachabilityOpenDocker')), findsNothing);
    serverReachability.value = Reachability.ok;
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets(
    'the launch screen says Docker is closed; Open Docker opens it and tries again',
    (tester) async {
      await setSize(tester, const Size(800, 1000));
      var retries = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ServerUnreachableView(
              apiUrl: 'http://localhost:8080',
              retrying: false,
              nextRetryAt: null,
              onRetry: () => retries++,
              onChangeServer: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.text("Docker isn't running, so your server is stopped"),
        findsOneWidget,
      );
      expect(
        find.textContaining('runs in Docker on this computer'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('startupOpenDocker')));
      await tester.pump();
      expect(opened, 1);
      expect(retries, 1);
    },
  );
}
