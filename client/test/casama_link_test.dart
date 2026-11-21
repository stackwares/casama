// Casama Link in the app (D-296): the QR code that signs another device in, scanning one on a
// phone, the page that links a server to a workspace, and a self-hosted server's own remote access.
import 'dart:async';
import 'dart:io';

import 'package:casama/core/providers.dart';
import 'package:casama/core/server_address.dart';
import 'package:casama/features/link/link_screen.dart';
import 'package:casama/features/link/keep_awake.dart';
import 'package:casama/features/link/link_server_screen.dart';
import 'package:casama/features/link/pair_device_sheet.dart';
import 'package:casama/features/link/pairing.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama/main.dart' show tunnelSaysOffline;
import 'package:casama_sdk/casama_link.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

/// The switch as the screen sees it: scripted steps, no installer and no network.
class FakeSetup extends RemoteAccessSetup {
  FakeSetup()
    : super(stackDir: Directory('/nowhere'), runInstaller: (_) async => 0);
  StreamController<RemoteSetupProgress>? on;
  StreamController<RemoteSetupProgress>? off;
  var onCalls = 0;
  var offCalls = 0;

  /// What the last turn-on asked about invitations (null: leave as it is).
  bool? invitesAsked;

  @override
  Stream<RemoteSetupProgress> turnOn({
    bool Function()? cancelled,
    bool relink = false,
    bool? invites,
  }) {
    onCalls++;
    invitesAsked = invites;
    return (on = StreamController<RemoteSetupProgress>()).stream;
  }

  @override
  Stream<RemoteSetupProgress> turnOff() {
    offCalls++;
    return (off = StreamController<RemoteSetupProgress>()).stream;
  }
}

RemoteAccessStatus status(
  String state, {
  String? problem,
  bool on = true,
  bool linked = true,
  bool invites = false,
  String? liveView,
}) => RemoteAccessStatus(
  state: state,
  address: on ? 'https://k7qm2xfd9abc.link.test' : null,
  pagesAddress: on ? 'https://k7qm2xfd9abc-p.link.test' : null,
  localAddress: 'http://localhost:8080',
  linked: on || linked,
  problem: problem,
  connections: state == 'online' ? 4 : 0,
  checkedAt: DateTime(2026, 11, 14),
  // A linked server with no Firebase key of its own pushes through Casama Cloud.
  push: on || linked ? 'relay' : 'off',
  privateNotifications: false,
  invites: invites,
  liveView: liveView,
);

/// The process that holds the Mac awake, as far as the switch can tell.
class _Held implements Process {
  var killed = false;
  final _exit = Completer<int>();
  @override
  Future<int> get exitCode => _exit.future;
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    if (!_exit.isCompleted) _exit.complete(-15);
    return true;
  }

  @override
  int get pid => 4242;
  @override
  Stream<List<int>> get stdout => const Stream.empty();
  @override
  Stream<List<int>> get stderr => const Stream.empty();
  @override
  IOSink get stdin => throw UnimplementedError();
}

/// A page inside a router (sub-pages and their links need one).
Widget routed(
  FakeBackend backend,
  Widget page, {
  FakeSetup? setup,
  List<String>? went,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => page),
      GoRoute(
        path: '/bots',
        builder: (_, _) {
          went?.add('/bots');
          return const Text('chats');
        },
      ),
      GoRoute(
        path: '/settings/two-step',
        builder: (_, _) => const Text('two-step page'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      backendProvider.overrideWithValue(backend),
      linkSetupProvider.overrideWith((ref) async => setup),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

/// A button that runs [action] with a context and a ref, for the functions screens call.
Widget withButton(
  FakeBackend backend,
  Future<void> Function(BuildContext, WidgetRef) action,
) => ProviderScope(
  overrides: [backendProvider.overrideWithValue(backend)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Consumer(
        builder: (context, ref, _) => Column(
          children: [
            TextButton(
              key: const Key('go'),
              onPressed: () => action(context, ref),
              child: const Text('go'),
            ),
            const PendingPairingRunner(),
          ],
        ),
      ),
    ),
  ),
);

/// Opens Sign In on Another Device the way Settings does (a sheet over a page).
Future<void> openPairSheet(
  WidgetTester tester,
  FakeBackend backend, {
  VoidCallback? onTurnOnLink,
}) async {
  await tester.pumpWidget(
    routed(
      backend,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            key: const Key('openPair'),
            onPressed: () =>
                showPairDevice(context, onTurnOnLink: onTurnOnLink),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('openPair')));
}

DioException apiError(int code) {
  final req = RequestOptions(path: '/v1/auth/pairing-codes/redeem');
  return DioException(
    requestOptions: req,
    response: Response(
      requestOptions: req,
      statusCode: code,
      data: {'title': 'Error', 'status': code, 'code': 'code_not_valid'},
    ),
  );
}

void main() {
  const code = 'ksc_0123456789abcdefghijklmnopqrstuvwxyzABCDEFG';
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PendingPairing.link = null;
    onChangeServer = null;
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    onChangeServer = null;
  });

  group('what a sign-in QR code carries', () {
    test('the server and the code, after the # so no web server sees them', () {
      final link = PairLink.parse(
        'https://casama.ai/pair#v=1&s=https%3A%2F%2Fk7qm2xfd9abc.link.test&c=$code',
      );
      expect(link!.server, 'https://k7qm2xfd9abc.link.test');
      expect(link.code, code);
      expect(link.host, 'k7qm2xfd9abc.link.test');
    });

    test('also as the app link and with the values in the query', () {
      expect(
        PairLink.parse(
          'casama://app/pair?s=https%3A%2F%2Fhome.example&c=$code',
        )!.server,
        'https://home.example',
      );
      expect(
        PairLink.parse('casama://pair?s=https%3A%2F%2Fhome.example&c=$code')!
            .server,
        'https://home.example',
      );
      expect(
        PairLink.parse(
          'https://casama.ai/pair?s=https%3A%2F%2Fhome.example%2F&c=$code',
        )!.server,
        'https://home.example',
      );
      // The router hands the values over without the path.
      expect(
        PairLink.fromValues({'s': 'http://192.168.1.20:8080', 'c': code})!
            .server,
        'http://192.168.1.20:8080',
      );
    });

    test('anything else is not a sign-in code', () {
      for (final other in [
        'otpauth://totp/Casama:me?secret=ABC',
        'https://casama.ai/i/friend',
        'https://casama.ai/pair',
        'https://casama.ai/pair#s=https%3A%2F%2Fhome.example&c=short',
        'https://casama.ai/pair#s=javascript%3Aalert(1)&c=$code',
        'https://casama.ai/pair#s=home.example&c=$code',
        'not a link at all',
      ]) {
        expect(PairLink.parse(other), isNull, reason: other);
      }
    });
  });

  group('Sign In on Another Device', () {
    testWidgets('shows a code for this server, and a new one on request', (
      tester,
    ) async {
      await setSize(tester, const Size(500, 900));
      final backend = FakeBackend();
      await openPairSheet(tester, backend);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pairQr')), findsOneWidget);
      expect(
        find.text('Signs in to k7qm2xfd9abc.link.test'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Anyone who scans it is signed in as you'),
        findsOneWidget,
      );
      expect(backend.signInCodesMade, 1);

      await tester.tap(find.byKey(const Key('pairNewCode')));
      await tester.pumpAndSettle();
      expect(backend.signInCodesMade, 2);
      expect(find.byKey(const Key('pairQr')), findsOneWidget);
    });

    testWidgets('a code that ran out says so until a new one is made', (
      tester,
    ) async {
      await setSize(tester, const Size(500, 900));
      final backend = FakeBackend();
      await openPairSheet(tester, backend);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 5, seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('This code ran out.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('pairNewCode')));
      await tester.pumpAndSettle();
      expect(find.text('This code ran out.'), findsNothing);
    });

    testWidgets(
      'a server only this computer reaches offers Casama Link, not a useless code',
      (tester) async {
        await setSize(tester, const Size(500, 900));
        final backend = FakeBackend()
          ..signInCodeServer = 'http://localhost:8080'
          ..signInCodeReachable = false;
        var opened = 0;
        await openPairSheet(tester, backend, onTurnOnLink: () => opened++);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('pairQr')), findsNothing);
        expect(
          find.text(
            "This server only answers on this computer, so a phone can't reach it yet.",
          ),
          findsOneWidget,
        );
        expect(find.text('Use on Your Phone'), findsOneWidget);
        await tester.tap(find.byKey(const Key('pairTurnOnLink')));
        await tester.pumpAndSettle();
        expect(opened, 1);
      },
    );

    testWidgets(
      'where the server is run by someone else, it says who can fix that',
      (tester) async {
        await setSize(tester, const Size(500, 900));
        final backend = FakeBackend()..signInCodeReachable = false;
        await openPairSheet(tester, backend);
        await tester.pumpAndSettle();
        expect(find.textContaining('Ask whoever runs it'), findsOneWidget);
        expect(find.byKey(const Key('pairTurnOnLink')), findsNothing);
      },
    );
  });

  group('signing in from a scanned code', () {
    final here = PairLink('http://localhost:8787', code);
    final elsewhere = PairLink('https://k7qm2xfd9abc.link.test', code);

    testWidgets('a code for the server the app already uses signs in at once', (
      tester,
    ) async {
      final backend = FakeBackend()..signedIn = false;
      await tester.pumpWidget(
        withButton(backend, (c, ref) => signInFromPairLink(c, ref, here)),
      );
      await tester.tap(find.byKey(const Key('go')));
      await tester.pumpAndSettle();
      expect(backend.redeemedCodes.single.$1, code);
      expect(backend.redeemedCodes.single.$2, isNotEmpty);
      expect(backend.signedIn, isTrue);
    });

    testWidgets(
      'a code for another server asks, switches the app over, and signs in there',
      (tester) async {
        final backend = FakeBackend()..signedIn = false;
        final switched = <String>[];
        onChangeServer = (url) async => switched.add(url);
        await tester.pumpWidget(
          withButton(
            backend,
            (c, ref) => signInFromPairLink(c, ref, elsewhere),
          ),
        );
        await tester.tap(find.byKey(const Key('go')));
        await tester.pumpAndSettle();
        expect(
          find.text('Sign in to k7qm2xfd9abc.link.test?'),
          findsOneWidget,
        );
        expect(
          find.textContaining('This device uses localhost now'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('pairConfirm')));
        await tester.pumpAndSettle();
        expect(switched, ['https://k7qm2xfd9abc.link.test']);
        // Nothing is traded on the old server; the code waits for the new one.
        expect(backend.redeemedCodes, isEmpty);
        expect(PendingPairing.link?.code, code);
      },
    );

    testWidgets(
      'after the switch, the sign-in screen finishes with the waiting code',
      (tester) async {
        PendingPairing.link = here;
        final backend = FakeBackend()..signedIn = false;
        await tester.pumpWidget(withButton(backend, (_, _) async {}));
        await tester.pumpAndSettle();
        expect(backend.redeemedCodes.single.$1, code);
        expect(PendingPairing.link, isNull);
        expect(find.byKey(const Key('pairSigningIn')), findsNothing);
      },
    );

    testWidgets(
      'a waiting code for some other server is dropped, not sent to this one',
      (tester) async {
        PendingPairing.link = elsewhere;
        final backend = FakeBackend()..signedIn = false;
        await tester.pumpWidget(withButton(backend, (_, _) async {}));
        await tester.pumpAndSettle();
        expect(backend.redeemedCodes, isEmpty);
        expect(PendingPairing.link, isNull);
      },
    );

    testWidgets('someone already signed in is asked first, and can say no', (
      tester,
    ) async {
      final backend = FakeBackend();
      await tester.pumpWidget(
        withButton(backend, (c, ref) => signInFromPairLink(c, ref, here)),
      );
      await tester.tap(find.byKey(const Key('go')));
      await tester.pumpAndSettle();
      expect(find.text('Sign in to localhost?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(backend.redeemedCodes, isEmpty);
      expect(backend.signedIn, isTrue);
    });

    testWidgets('a used or expired code says to show a new one', (
      tester,
    ) async {
      final backend = FakeBackend()
        ..signedIn = false
        ..signInWithCodeError = apiError(404);
      await tester.pumpWidget(
        withButton(backend, (c, ref) => signInFromPairLink(c, ref, here)),
      );
      await tester.tap(find.byKey(const Key('go')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text(
          "That code isn't valid any more. Show a new one and scan again.",
        ),
        findsOneWidget,
      );
      expect(backend.signedIn, isFalse);
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });

    test('only phones and tablets scan; everything else shows the code', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(canScanSignInCode, isTrue);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(canScanSignInCode, isTrue);
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(canScanSignInCode, isFalse);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('linking a server to a workspace', () {
    testWidgets('shows which server asked and its code, and links it', (
      tester,
    ) async {
      await setSize(tester, const Size(500, 1100));
      final backend = FakeBackend();
      final went = <String>[];
      await tester.pumpWidget(
        routed(backend, const LinkServerScreen(code: 'k7qm-2xfd'), went: went),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Home Mac wants to connect to your Casama Cloud account.'),
        findsOneWidget,
      );
      expect(find.text('K7QM-2XFD'), findsOneWidget);
      expect(find.textContaining('shows this same code'), findsOneWidget);
      expect(
        find.textContaining("It can't spend your credits"),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('linkServerApprove')));
      await tester.pumpAndSettle();
      expect(backend.approvedLinks, [(orgId, 'K7QM-2XFD')]);
      expect(find.byKey(const Key('linkServerDone')), findsOneWidget);
      expect(
        find.text('Go back to Home Mac. It carries on by itself.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('linkServerClose')));
      await tester.pumpAndSettle();
      expect(went, ['/bots']);
    });

    testWidgets(
      'without a code in the link, the person types it; a wrong one says so',
      (tester) async {
        await setSize(tester, const Size(500, 1100));
        final backend = FakeBackend();
        await tester.pumpWidget(routed(backend, const LinkServerScreen()));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('linkServerCode')),
          'ZZZZ-ZZZZ',
        );
        await tester.tap(find.byKey(const Key('linkServerFind')));
        await tester.pumpAndSettle();
        expect(
          find.text(
            "That code isn't valid any more. Start again on your server.",
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('linkServerApprove')), findsNothing);

        await tester.enterText(
          find.byKey(const Key('linkServerCode')),
          'K7QM-2XFD',
        );
        await tester.tap(find.byKey(const Key('linkServerFind')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('linkServerApprove')), findsOneWidget);
      },
    );

    testWidgets('opened from a link with nothing behind it, it can still be left', (
      tester,
    ) async {
      await setSize(tester, const Size(1300, 1000));
      final backend = FakeBackend();
      final went = <String>[];
      await tester.pumpWidget(
        routed(backend, const LinkServerScreen(), went: went),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(went, ['/bots']);
    });

    testWidgets('only owners and admins can link', (tester) async {
      await setSize(tester, const Size(500, 1100));
      final backend = FakeBackend()..orgRole = OrgRole.member;
      await tester.pumpWidget(
        routed(backend, const LinkServerScreen(code: 'K7QM-2XFD')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('linkServerNeedAdmin')), findsOneWidget);
      expect(find.byKey(const Key('linkServerApprove')), findsNothing);
    });
  });

  group("a self-hosted server's own remote access", () {
    testWidgets(
      'the owner turns it on: the code to approve, the steps, then the sign-in QR',
      (tester) async {
        await setSize(tester, const Size(500, 1200));
        final backend = FakeBackend()
          ..remoteAccessStatus = status('off', on: false);
        final setup = FakeSetup();
        await tester.pumpWidget(
          routed(backend, const LinkScreen(), setup: setup),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('an address your phone can reach from anywhere'),
          findsOneWidget,
        );
        expect(find.textContaining('never through Casama'), findsOneWidget);
        expect(
          find.textContaining('New sign-ups close while it is on'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('linkTurnOn')));
        await tester.pump();
        expect(setup.onCalls, 1);
        setup.on!.add(
          RemoteSetupProgress(
            RemoteSetupStep.linking,
            code: LinkCode(
              deviceCode: 'kcl_x',
              userCode: 'K7QM-2XFD',
              verificationUrl: Uri.parse(
                'https://app.example.test/link?code=K7QM-2XFD',
              ),
              interval: const Duration(seconds: 3),
              expiresIn: const Duration(minutes: 15),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(find.byKey(const Key('linkSignInCode')), findsOneWidget);
        expect(find.text('K7QM-2XFD'), findsOneWidget);
        expect(find.byKey(const Key('linkOpenSignIn')), findsOneWidget);

        setup.on!.add(const RemoteSetupProgress(RemoteSetupStep.address));
        setup.on!.add(
          const RemoteSetupProgress(
            RemoteSetupStep.restarting,
            detail: '==> Starting the stack',
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(find.byKey(const Key('linkSignInCode')), findsNothing);
        expect(find.text('==> Starting the stack'), findsOneWidget);

        // It is on now: the status says so and the code a phone scans opens by itself.
        backend.remoteAccessStatus = status('online');
        setup.on!.add(const RemoteSetupProgress(RemoteSetupStep.connecting));
        setup.on!.add(
          const RemoteSetupProgress(
            RemoteSetupStep.ready,
            address: 'https://k7qm2xfd9abc.link.test',
          ),
        );
        await setup.on!.close();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('pairQr')), findsOneWidget);
        expect(find.text('Online'), findsOneWidget);
        expect(find.text('https://k7qm2xfd9abc.link.test'), findsOneWidget);
      },
    );

    testWidgets(
      'a refusal is shown in its own words and nothing is left half done',
      (tester) async {
        await setSize(tester, const Size(500, 1200));
        final backend = FakeBackend()
          ..remoteAccessStatus = status('off', on: false);
        final setup = FakeSetup();
        await tester.pumpWidget(
          routed(backend, const LinkScreen(), setup: setup),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('linkTurnOn')));
        await tester.pump();
        setup.on!.addError(
          LinkException(
            'plan_limit',
            'Your plan connects 1 server. Remove one or upgrade to add more.',
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Your plan connects 1 server. Remove one or upgrade to add more.',
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('linkTurnOn')), findsOneWidget);
        expect(find.byKey(const Key('linkProgress')), findsNothing);
      },
    );

    testWidgets('on: the address, where it stops, and turning off asks first', (
      tester,
    ) async {
      await setSize(tester, const Size(500, 1200));
      final backend = FakeBackend()
        ..remoteAccessStatus = status('offline', problem: 'connector_blocked');
      final setup = FakeSetup();
      await tester.pumpWidget(
        routed(backend, const LinkScreen(), setup: setup),
      );
      await tester.pumpAndSettle();
      expect(find.text('Offline'), findsOneWidget);
      expect(find.textContaining('outbound port 7844'), findsOneWidget);
      expect(find.text('http://localhost:8080'), findsOneWidget);
      // Reachable from the internet now, so two-step sign-in is suggested until it is on.
      expect(find.byKey(const Key('linkTwoStep')), findsOneWidget);

      backend.remoteAccessStatus = status('online');
      await tester.tap(find.byKey(const Key('linkCheck')));
      await tester.pumpAndSettle();
      expect(find.text('Online'), findsOneWidget);
      expect(backend.remoteAccessChecks, 2);

      await tester.ensureVisible(find.byKey(const Key('linkTurnOff')));
      await tester.tap(find.byKey(const Key('linkTurnOff')));
      await tester.pumpAndSettle();
      expect(find.textContaining('The address stops working'), findsOneWidget);
      await tester.tap(find.byKey(const Key('linkTurnOffConfirm')));
      await tester.pump();
      expect(setup.offCalls, 1);
      expect(find.byKey(const Key('linkTurningOff')), findsOneWidget);
      backend.remoteAccessStatus = status('off', on: false);
      setup.off!.add(const RemoteSetupProgress(RemoteSetupStep.off));
      await setup.off!.close();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('linkTurnOn')), findsOneWidget);
    });

    testWidgets(
      'a problem only linking again fixes offers exactly that; one this app has never heard of still reads',
      (tester) async {
        await setSize(tester, const Size(500, 1200));
        final backend = FakeBackend()
          ..remoteAccessStatus = status(
            'needs_attention',
            problem: 'key_rejected',
          );
        final setup = FakeSetup();
        await tester.pumpWidget(
          routed(backend, const LinkScreen(), setup: setup),
        );
        await tester.pumpAndSettle();
        expect(find.text('Needs attention'), findsOneWidget);
        expect(
          find.textContaining("no longer accepts this server's key"),
          findsOneWidget,
        );
        expect(find.byKey(const Key('linkTurnOnAgain')), findsOneWidget);
        // No code to show while it has no address.
        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('linkShowCode')))
              .onPressed,
          isNull,
        );

        backend.remoteAccessStatus = status(
          'some_new_state',
          problem: 'some_new_problem',
        );
        await tester.tap(find.byKey(const Key('linkCheck')));
        await tester.pumpAndSettle();
        expect(find.text('Needs attention'), findsWidgets);
      },
    );

    testWidgets(
      'private notifications: one switch, and the relay gets no text from then on',
      (tester) async {
        await setSize(tester, const Size(500, 1400));
        final backend = FakeBackend()..remoteAccessStatus = status('online');
        await tester.pumpWidget(
          routed(backend, const LinkScreen(), setup: FakeSetup()),
        );
        await tester.pumpAndSettle();
        final toggle = find.byKey(const Key('linkPrivateNotifications'));
        expect(tester.widget<Switch>(toggle).value, isFalse);
        expect(find.textContaining('say only "New activity"'), findsOneWidget);
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(backend.remoteAccessStatus!.privateNotifications, isTrue);
        expect(
          tester
              .widget<Switch>(
                find.byKey(const Key('linkPrivateNotifications')),
              )
              .value,
          isTrue,
        );
      },
    );

    testWidgets(
      'a linked server without an address still has the notifications switch',
      (tester) async {
        await setSize(tester, const Size(500, 1400));
        final backend = FakeBackend()
          ..remoteAccessStatus = status('off', on: false);
        await tester.pumpWidget(
          routed(backend, const LinkScreen(), setup: FakeSetup()),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('linkPrivateNotifications')),
          findsOneWidget,
        );
        // Who may sign up only matters once the server can be reached.
        expect(find.byKey(const Key('linkInvites')), findsNothing);
      },
    );

    testWidgets(
      'says what the plan gives for live view away from the computer',
      (tester) async {
        await setSize(tester, const Size(500, 1400));
        final backend = FakeBackend()
          ..remoteAccessStatus = status('online', liveView: 'plan');
        await tester.pumpWidget(
          routed(backend, const LinkScreen(), setup: FakeSetup()),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('linkLiveView')), findsOneWidget);
        expect(find.textContaining('Comes with Plus and up'), findsOneWidget);

        backend.remoteAccessStatus = status('online', liveView: 'included');
        await tester.tap(find.byKey(const Key('linkCheck')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Included in your plan'), findsOneWidget);
        expect(find.textContaining('Comes with Plus and up'), findsNothing);

        // Not known (an older Casama Cloud), or a word this app doesn't know: nothing is claimed.
        for (final other in [null, 'something_new']) {
          backend.remoteAccessStatus = status('online', liveView: other);
          await tester.tap(find.byKey(const Key('linkCheck')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('linkLiveView')), findsNothing);
        }
      },
    );

    testWidgets('never linked: nothing to switch', (tester) async {
      await setSize(tester, const Size(500, 1400));
      final backend = FakeBackend()
        ..remoteAccessStatus = status('off', on: false, linked: false);
      await tester.pumpWidget(
        routed(backend, const LinkScreen(), setup: FakeSetup()),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('linkPrivateNotifications')),
        findsNothing,
      );
    });

    testWidgets(
      'letting invited people sign up switches the server over, and back',
      (tester) async {
        await setSize(tester, const Size(500, 1400));
        final backend = FakeBackend()..remoteAccessStatus = status('online');
        final setup = FakeSetup();
        await tester.pumpWidget(
          routed(backend, const LinkScreen(), setup: setup),
        );
        await tester.pumpAndSettle();
        final toggle = find.byKey(const Key('linkInvites'));
        expect(tester.widget<Switch>(toggle).value, isFalse);
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pump();
        expect(setup.onCalls, 1);
        expect(setup.invitesAsked, isTrue);
        // The server restarts with it; the page shows the steps meanwhile.
        expect(find.byKey(const Key('linkProgress')), findsOneWidget);
        backend.remoteAccessStatus = status('online', invites: true);
        setup.on!.add(
          const RemoteSetupProgress(
            RemoteSetupStep.ready,
            address: 'https://k7qm2xfd9abc.link.test',
          ),
        );
        await setup.on!.close();
        await tester.pumpAndSettle();
        // The sign-in code opens after a switch; close it to see the page.
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Switch>(find.byKey(const Key('linkInvites'))).value,
          isTrue,
        );
      },
    );

    testWidgets(
      'keeping the Mac awake: offered on a Mac, remembered, and let go when turned off',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        await setSize(tester, const Size(500, 1400));
        var started = 0;
        final holder = _Held();
        KeepAwake.start = () async {
          started++;
          return holder;
        };
        addTearDown(KeepAwake.release);
        final backend = FakeBackend()..remoteAccessStatus = status('online');
        await tester.pumpWidget(
          routed(backend, const LinkScreen(), setup: FakeSetup()),
        );
        await tester.pumpAndSettle();
        final toggle = find.byKey(const Key('linkKeepAwake'));
        expect(tester.widget<Switch>(toggle).value, isFalse);
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(started, 1);
        expect(KeepAwake.holding, isTrue);
        expect(await KeepAwake.enabled(), isTrue);
        expect(
          tester
              .widget<Switch>(find.byKey(const Key('linkKeepAwake')))
              .value,
          isTrue,
        );

        await tester.tap(find.byKey(const Key('linkKeepAwake')));
        await tester.pumpAndSettle();
        expect(holder.killed, isTrue);
        expect(KeepAwake.holding, isFalse);
        expect(await KeepAwake.enabled(), isFalse);
        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'keeping awake is a Mac thing: other computers are not offered it',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        await setSize(tester, const Size(500, 1400));
        final backend = FakeBackend()..remoteAccessStatus = status('online');
        await tester.pumpWidget(
          routed(backend, const LinkScreen(), setup: FakeSetup()),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('linkKeepAwake')), findsNothing);
        expect(find.byKey(const Key('linkInvites')), findsOneWidget);
        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'anyone but the owner is told so; a server on another machine shows its command',
      (tester) async {
        await setSize(tester, const Size(500, 1200));
        final backend = FakeBackend();
        await tester.pumpWidget(routed(backend, const LinkScreen()));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('linkNeedsOwner')), findsOneWidget);

        final owner = FakeBackend()
          ..remoteAccessStatus = status('off', on: false);
        await tester.pumpWidget(
          routed(owner, const LinkScreen(key: Key('second'))),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('linkTurnOn')), findsNothing);
        expect(find.text('casama selfhost remote on'), findsOneWidget);
      },
    );
  });

  test('a tunnel that says the computer behind it is off is not "check your connection"', () {
    DioException answered(int code) {
      final req = RequestOptions(path: '/v1/config');
      return DioException(
        requestOptions: req,
        response: Response(requestOptions: req, statusCode: code),
      );
    }

    const mine = 'https://k7qm2xfd9abc.link.test';
    expect(tunnelSaysOffline(answered(530), mine), isTrue);
    expect(tunnelSaysOffline(answered(502), mine), isTrue);
    expect(tunnelSaysOffline(answered(404), mine), isFalse);
    // No answer at all: that may well be this device's own connection.
    expect(
      tunnelSaysOffline(
        DioException(requestOptions: RequestOptions(path: '/v1/config')),
        mine,
      ),
      isFalse,
    );
    expect(tunnelSaysOffline(TimeoutException('slow'), mine), isFalse);
    // Casama Cloud has no computer of the person's to wake.
    expect(tunnelSaysOffline(answered(530), 'https://api.casama.ai'), isFalse);
  });
}
