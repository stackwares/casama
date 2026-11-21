// Guided setup of a server on this computer (D-309): Docker, the server, the owner's account, a
// model and a phone, at /setup.
import 'dart:async';
import 'dart:io';

import 'package:casama/app.dart';
import 'package:casama/core/backend.dart';
import 'package:casama/core/local_cache.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/core/router.dart';
import 'package:casama/core/server_address.dart';
import 'package:casama/features/auth/sign_in_screen.dart';
import 'package:casama/features/link/link_screen.dart';
import 'package:casama/features/selfhost/docker_check.dart';
import 'package:casama/features/selfhost/guided_setup.dart';
import 'package:casama/features/selfhost/local_server.dart';
import 'package:casama/features/selfhost/setup_screen.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_link.dart';
import 'package:casama_sdk/casama_sdk.dart' show WelcomeChat;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'casama_link_test.dart' show FakeSetup, status;
import 'fake_backend.dart';

/// Scripted answers for `docker`, `sysctl`, `open` and `df`.
class _Runner implements ProcessRunner {
  _Runner({this.docker = 0, this.dockerMissing = false, this.dockerSays = '', this.compose = 0, this.arm = '1'});
  int docker;
  bool dockerMissing;
  String dockerSays;
  int compose;
  String arm;
  final calls = <String>[];

  @override
  Future<ProcessResult> run(String exe, List<String> args, {String? cwd}) async {
    calls.add('$exe ${args.join(' ')}');
    if (exe == 'docker') {
      if (dockerMissing) throw const ProcessException('docker', [], 'not found');
      if (args.first == 'compose') return ProcessResult(1, compose, '', '');
      return ProcessResult(1, docker, '27.0', dockerSays);
    }
    if (exe == 'sysctl') return ProcessResult(1, 0, '$arm\n', '');
    if (exe == 'df') {
      return ProcessResult(1, 0, 'Filesystem 1024-blocks Used Available Capacity Mounted on\n/dev/disk 100 50 ${5 * 1024 * 1024} 50% /\n', '');
    }
    return ProcessResult(1, 0, '', '');
  }

  @override
  Future<Process> start(String exe, List<String> args, {String? cwd}) => throw UnimplementedError();
}

/// Docker as the page sees it, changed by the test.
class _Docker extends DockerCheck {
  _Docker(this.now, {bool mac = true}) : super(platform: mac ? TargetPlatform.macOS : TargetPlatform.linux, runner: _Runner());
  DockerState now;
  var opened = 0;
  double? free;

  @override
  Future<DockerState> state() async => now;
  @override
  Future<Uri> downloadUrl() async => Uri.parse('https://desktop.docker.com/mac/main/arm64/Docker.dmg');
  @override
  Future<bool> open() async {
    opened++;
    return true;
  }

  @override
  Future<double?> freeDiskGb() async => free;
}

/// The installer as the page sees it: the test sends its progress.
class _Manager extends LocalServerManager {
  StreamController<LocalServerProgress>? run;
  var starts = 0;

  @override
  Stream<LocalServerProgress> start() {
    starts++;
    return (run = StreamController<LocalServerProgress>()).stream;
  }
}

/// A local server: signing up signs in at once.
class _Backend extends FakeBackend {
  String? signedUp;
  String? welcomedAs;

  @override
  Future<bool> signUp(String email, String password) async {
    signedUp = email;
    await signIn(email, password);
    return true;
  }

  @override
  Future<WelcomeChat> startWelcome({String? firstName}) {
    welcomedAs = firstName;
    return super.startWelcome(firstName: firstName);
  }
}

void main() {
  late List<Uri> opened;
  late List<String> went;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GuidedSetup.reset();
    opened = [];
    went = [];
    setupOpenUrl = (u) async => opened.add(u);
  });
  tearDown(() {
    onChangeServer = null;
    GuidedSetup.reset();
  });

  /// The setup page in a router, on a Mac. [local] says whether the app is on this computer's
  /// server; connecting to the new server flips it.
  Future<({_Docker docker, _Manager manager, FakeSetup setup})> open(
    WidgetTester tester,
    FakeBackend backend, {
    DockerState docker = DockerState.ready,
    bool local = false,
  }) async {
    await setSize(tester, const Size(900, 1000));
    final check = _Docker(docker);
    final manager = _Manager();
    final setup = FakeSetup();
    var onLocal = local;
    onChangeServer = (_) async => onLocal = true;
    final router = GoRouter(
      initialLocation: '/setup',
      routes: [
        GoRoute(path: '/setup', builder: (_, _) => const SetupScreen()),
        GoRoute(
          path: '/bots',
          builder: (_, _) {
            went.add('/bots');
            return const Text('chats');
          },
        ),
        GoRoute(
          path: '/sign-in',
          builder: (_, _) {
            went.add('/sign-in');
            return const Text('sign in');
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendProvider.overrideWithValue(backend),
          localCacheProvider.overrideWithValue(const NoCache()),
          usingLocalServerProvider.overrideWith((ref) async => onLocal),
          dockerCheckProvider.overrideWithValue(check),
          localServerManagerProvider.overrideWithValue(manager),
          linkSetupProvider.overrideWith((ref) async => setup),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await settle(tester);
    return (docker: check, manager: manager, setup: setup);
  }

  group('Docker on this computer', () {
    DockerCheck check(_Runner r, {bool mac = true, bool app = false}) =>
        DockerCheck(runner: r, platform: mac ? TargetPlatform.macOS : TargetPlatform.linux, exists: (_) => app);

    test('ready, missing, stopped, not allowed, and without Compose are told apart', () async {
      expect(await check(_Runner()).state(), DockerState.ready);
      expect(await check(_Runner(dockerMissing: true)).state(), DockerState.notInstalled);
      // Docker Desktop is in Applications but was never opened: no command line yet.
      expect(await check(_Runner(dockerMissing: true), app: true).state(), DockerState.notRunning);
      expect(await check(_Runner(docker: 1, dockerSays: 'Cannot connect to the Docker daemon')).state(), DockerState.notRunning);
      final denied = _Runner(docker: 1, dockerSays: 'permission denied while trying to connect to the Docker daemon socket');
      expect(await check(denied, mac: false).state(), DockerState.noPermission);
      expect(await check(denied).state(), DockerState.notRunning);
      expect(await check(_Runner(compose: 1)).state(), DockerState.noCompose);
    });

    test('the download fits the chip; Linux gets the install guide', () async {
      expect('${await check(_Runner(arm: '1')).downloadUrl()}', 'https://desktop.docker.com/mac/main/arm64/Docker.dmg');
      expect('${await check(_Runner(arm: '0')).downloadUrl()}', 'https://desktop.docker.com/mac/main/amd64/Docker.dmg');
      expect('${await check(_Runner(), mac: false).downloadUrl()}', 'https://docs.docker.com/engine/install/');
      expect(await check(_Runner()).freeDiskGb(), 5);
    });

    test('opens Docker Desktop on a Mac only', () async {
      final r = _Runner();
      expect(await check(r).open(), isTrue);
      expect(r.calls, contains('open -a Docker'));
      expect(await check(_Runner(), mac: false).open(), isFalse);
    });
  });

  group('what the setup remembers', () {
    test('survives a restart: under way, skipped steps, the closed card', () async {
      await GuidedSetup.begin();
      await GuidedSetup.skip('ai');
      await GuidedSetup.dismissCard();
      GuidedSetup.reset();
      expect(GuidedSetup.active.value, isFalse);
      await GuidedSetup.preload();
      expect(GuidedSetup.active.value, isTrue);
      expect(GuidedSetup.skipped.value, {'ai'});
      expect(GuidedSetup.cardDismissed.value, isTrue);
      await GuidedSetup.unskip('ai');
      await GuidedSetup.end();
      GuidedSetup.reset();
      await GuidedSetup.preload();
      expect(GuidedSetup.active.value, isFalse);
      expect(GuidedSetup.skipped.value, isEmpty);
    });
  });

  onMac('without Docker: a download for this Mac, then it opens Docker and starts the server by itself', (tester) async {
    final backend = FakeBackend()..signedIn = false;
    final t = await open(tester, backend, docker: DockerState.notInstalled);
    expect(find.text('First, install Docker'), findsOneWidget);
    expect(find.byKey(const Key('setupDockerWaiting')), findsOneWidget);
    await tester.tap(find.byKey(const Key('setupGetDocker')));
    await settle(tester);
    expect(opened.single.toString(), 'https://desktop.docker.com/mac/main/arm64/Docker.dmg');

    // Installed: the page opens it without another click.
    t.docker.now = DockerState.notRunning;
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    expect(find.text('Docker needs to be running'), findsOneWidget);
    expect(t.docker.opened, 1);
    expect(find.text('Starting Docker…'), findsOneWidget);

    // Running: straight on to the server, as the page promised.
    t.docker.now = DockerState.ready;
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    expect(find.byKey(const Key('setupServer')), findsOneWidget);
    expect(t.manager.starts, 1);
    await leave(tester);
  });

  onMac('Linux: the commands to start Docker and to be allowed to use it', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await setSize(tester, const Size(900, 1000));
    for (final (state, command) in [
      (DockerState.notRunning, 'sudo systemctl start docker'),
      (DockerState.noPermission, r'sudo usermod -aG docker $USER'),
    ]) {
      final check = _Docker(state, mac: false);
      await tester.pumpWidget(
        harness(FakeBackend(), Scaffold(body: DockerStep(key: ValueKey(state), state: state, check: check, onCheck: () async {}))),
      );
      await settle(tester);
      expect(find.text(command), findsOneWidget);
      expect(check.opened, 0);
    }
    final missing = _Docker(DockerState.notInstalled, mac: false)..free = 4;
    await tester.pumpWidget(
      harness(FakeBackend(), Scaffold(body: DockerStep(state: DockerState.notInstalled, check: missing, onCheck: () async {}))),
    );
    await settle(tester);
    expect(find.text("Open Docker's Install Guide"), findsOneWidget);
    expect(find.textContaining('Only 4 GB of disk space is free'), findsOneWidget);
  });

  onMac('a long wait offers help: what Docker said, Check Again and the guide', (tester) async {
    final urls = <Uri>[];
    setupOpenUrl = (u) async => urls.add(u);
    await setSize(tester, const Size(900, 1200));
    final check = _Docker(DockerState.notRunning)..lastDetail = 'Cannot connect to the Docker daemon';
    var checks = 0;
    await tester.pumpWidget(
      harness(FakeBackend(), Scaffold(body: SingleChildScrollView(child: DockerStep(state: DockerState.notRunning, check: check, onCheck: () async => checks++)))),
    );
    await settle(tester);
    expect(find.byKey(const Key('setupDockerSlow')), findsNothing, reason: 'only a spinner at first');
    await tester.pump(const Duration(seconds: 46));
    await settle(tester);
    expect(find.byKey(const Key('setupDockerSlow')), findsOneWidget);
    expect(find.textContaining('Cannot connect to the Docker daemon'), findsOneWidget);
    final opened = check.opened;
    await tester.tap(find.byKey(const Key('setupDockerRecheck')));
    await settle(tester);
    expect(check.opened, opened + 1, reason: 'opens Docker again');
    expect(checks, greaterThan(0));
    await tester.tap(find.byKey(const Key('setupDockerGuide')));
    await settle(tester);
    expect(urls.single.fragment, 'docker-is-not-running-or-this-user-cannot-use-it');
  });

  onMac('wide windows get the painted scene and a bot per step; narrow ones neither', (tester) async {
    final backend = FakeBackend()..signedIn = false;
    await open(tester, backend, docker: DockerState.notRunning);
    expect(find.byKey(const Key('setupArtPane')), findsOneWidget);
    expect(find.byKey(const Key('splashScene')), findsOneWidget);
    expect(find.text('First, the box your server lives in.'), findsOneWidget);
    expect(find.bySemanticsLabel('Thinker'), findsWidgets);

    await setSize(tester, const Size(600, 1000));
    await settle(tester);
    expect(find.byKey(const Key('setupArtPane')), findsNothing);
    expect(find.byKey(const Key('splashScene')), findsNothing);
    expect(find.bySemanticsLabel('Thinker'), findsNothing, reason: "it would stack on the step's own icon");
    expect(find.text('Docker needs to be running'), findsOneWidget);
    await leave(tester);
  });

  onMac('with Docker ready: one click downloads, starts and connects to the server', (tester) async {
    final backend = FakeBackend()..signedIn = false;
    String? switched;
    final t = await open(tester, backend);
    final connect = onChangeServer!;
    onChangeServer = (u) async {
      switched = u;
      await connect(u);
    };
    expect(find.text('Download and start your server'), findsOneWidget);
    expect(t.manager.starts, 0, reason: 'nothing downloads before the person says so');
    await tester.tap(find.byKey(const Key('setupStartServer')));
    await settle(tester);
    t.manager.run!.add(const LocalServerProgress(LocalServerStep.downloading, fraction: 0.5));
    await settle(tester);
    expect(tester.widget<LinearProgressIndicator>(find.byKey(const Key('setupServerBar'))).value, 0.5);
    for (final line in [
      '==> Generating secrets',
      '==> Pulling Casama images (ghcr.io, abc)',
      'Image ghcr.io/stackwares/casama/server:abc Pulling',
      'Image ghcr.io/stackwares/casama/turn:abc Pulling',
      'Image ghcr.io/stackwares/casama/turn:abc Pulled',
    ]) {
      t.manager.run!.add(LocalServerProgress(LocalServerStep.installing, detail: line));
    }
    await settle(tester);
    // The longest part says how far along it is, from Compose's own lines.
    expect(find.text('1 of 2 downloaded so far'), findsOneWidget);
    t.manager.run!.add(const LocalServerProgress(LocalServerStep.installing, detail: '==> Starting the stack'));
    await settle(tester);
    expect(find.text('1 of 2 downloaded so far'), findsNothing);
    expect(find.text('Keep Casama open until this finishes.'), findsOneWidget);
    // The installer's own lines stay out of sight until asked for.
    expect(find.byKey(const Key('setupLog')), findsNothing);
    await tester.tap(find.byKey(const Key('setupDetails')));
    await settle(tester);
    expect(find.textContaining('Pulling Casama images'), findsOneWidget);

    t.manager.run!.add(const LocalServerProgress(LocalServerStep.ready, detail: 'http://localhost:8080'));
    await settle(tester);
    expect(switched, 'http://localhost:8080');
    expect((await SharedPreferences.getInstance()).getString('casama.server_url'), 'http://localhost:8080');
    // On the new server, signed out: the account comes next.
    expect(find.byKey(const Key('setupAccount')), findsOneWidget);
    await leave(tester);
  });

  onMac('a failed install says why and tries again; Docker gone goes back to its step', (tester) async {
    final t = await open(tester, FakeBackend()..signedIn = false);
    await tester.tap(find.byKey(const Key('setupStartServer')));
    await settle(tester);
    t.manager.run!.add(const LocalServerProgress(LocalServerStep.failed, detail: 'The installer stopped (exit 3).'));
    await settle(tester);
    expect(find.text('The installer stopped (exit 3).'), findsOneWidget);
    await tester.tap(find.byKey(const Key('setupStartServer')));
    await settle(tester);
    expect(t.manager.starts, 2);
    t.docker.now = DockerState.notRunning;
    t.manager.run!.add(const LocalServerProgress(LocalServerStep.failed, detail: 'Docker stopped'));
    await settle(tester);
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    expect(find.text('Docker needs to be running'), findsOneWidget);
    await leave(tester);
  });

  onMac('the account, then a model, then the phone: created, skipped, paired, done', (tester) async {
    final backend = _Backend()
      ..signedIn = false
      ..hasOrg = false
      ..noKeys = true
      ..canConnectChatGpt = true
      ..remoteAccessStatus = status('off', on: false);
    final t = await open(tester, backend, local: true);
    expect(find.text('Create your account'), findsOneWidget);
    await tester.tap(find.byKey(const Key('setupAccountSubmit')));
    await settle(tester);
    expect(find.text('Enter your name'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('setupName')), 'Oliver Martinez');
    await tester.enterText(find.byKey(const Key('setupEmail')), 'me@example.com');
    await tester.enterText(find.byKey(const Key('setupPassword')), 'secret1');
    await tester.tap(find.byKey(const Key('setupAccountSubmit')));
    await settle(tester);
    expect(backend.signedUp, 'me@example.com');
    expect(backend.about.preferredName, 'Oliver Martinez');
    expect(backend.welcomedAs, 'Oliver');
    expect(backend.welcomeCalls, 1);

    // A model next: ChatGPT in one click, or a key; or later.
    expect(find.text('Give your bots a model'), findsOneWidget);
    expect(find.byKey(const Key('continueWithChatGpt')), findsOneWidget);
    await tester.tap(find.byKey(const Key('setupSkipModel')));
    await settle(tester);
    expect(GuidedSetup.skipped.value, {'ai'});

    // The phone: an address first, approved in the browser.
    expect(find.text('Connect your phone'), findsOneWidget);
    expect(find.byKey(const Key('setupStepSkipped-3')), findsOneWidget, reason: 'a skipped step is a dash, not a tick');
    await tester.tap(find.byKey(const Key('setupPhoneTurnOn')));
    await settle(tester);
    expect(t.setup.onCalls, 1);
    final url = Uri.parse('https://casama.ai/link?code=ABCD-2345');
    t.setup.on!.add(
      RemoteSetupProgress(
        RemoteSetupStep.linking,
        code: LinkCode(deviceCode: 'd', userCode: 'ABCD-2345', verificationUrl: url, interval: const Duration(seconds: 3), expiresIn: const Duration(minutes: 15)),
      ),
    );
    await settle(tester);
    expect(find.text('ABCD-2345'), findsOneWidget);
    expect(opened, [url]);
    backend.remoteAccessStatus = status('online');
    t.setup.on!.add(const RemoteSetupProgress(RemoteSetupStep.ready, address: 'https://k7qm2xfd9abc.link.test'));
    await t.setup.on!.close();
    await settle(tester);

    // The code the phone scans, and the page says when the phone is in.
    expect(find.byKey(const Key('setupPhoneQr')), findsOneWidget);
    expect(find.byKey(const Key('setupPhoneWaiting')), findsOneWidget);
    expect(find.byKey(const Key('setupKeepAwake')), findsOneWidget);
    backend.notificationsController.add(
      NotificationView(id: 'n1', kind: 'sign_in', title: 'New sign-in', body: 'Signed in on iPhone', createdAt: DateTime(2026, 11, 15)),
    );
    await settle(tester);
    expect(find.text('Phone connected'), findsOneWidget);
    expect(find.byKey(const Key('setupPhoneQr')), findsNothing);

    await tester.tap(find.byKey(const Key('setupFinish')));
    await settle(tester);
    expect(went, ['/bots']);
    expect(GuidedSetup.active.value, isFalse);
  });

  onMac('an account that exists signs in; a server that takes no new accounts offers only that', (tester) async {
    final backend = _Backend()
      ..signedIn = false
      ..remoteAccessStatus = status('off', on: false);
    await open(tester, backend, local: true);
    await tester.tap(find.byKey(const Key('setupAccountToggle')));
    await settle(tester);
    expect(find.text('Sign in to your server'), findsOneWidget);
    expect(find.byKey(const Key('setupName')), findsNothing);
    await tester.enterText(find.byKey(const Key('setupEmail')), 'me@example.com');
    await tester.enterText(find.byKey(const Key('setupPassword')), 'secret1');
    await tester.tap(find.byKey(const Key('setupAccountSubmit')));
    await settle(tester);
    expect(backend.signedUp, isNull);
    expect(backend.welcomeCalls, 0, reason: 'their space is already there');
    // They have a key already, so the phone is next.
    expect(find.text('Connect your phone'), findsOneWidget);
    await leave(tester);

    GuidedSetup.reset();
    await open(tester, FakeBackend()
      ..signedIn = false
      ..signUpsOpen = false, local: true);
    expect(find.textContaining('already has its owner'), findsOneWidget);
    expect(find.byKey(const Key('setupAccountToggle')), findsNothing);
    await leave(tester);
  });

  onMac('closing leaves the setup; skipping the phone finishes it', (tester) async {
    await open(tester, FakeBackend()..signedIn = false, docker: DockerState.notInstalled);
    expect(GuidedSetup.active.value, isTrue);
    await tester.tap(find.byKey(const Key('setupClose')));
    await settle(tester);
    expect(went, ['/sign-in']);
    expect(GuidedSetup.active.value, isFalse);

    went.clear();
    final backend = FakeBackend()..remoteAccessStatus = status('off', on: false);
    await open(tester, backend, local: true);
    await tester.tap(find.byKey(const Key('setupSkipPhone')));
    await settle(tester);
    expect(went, ['/bots']);
    expect(GuidedSetup.skipped.value, {'phone'});
  });

  onMac('the sign-in screen offers it on a Mac, not on a phone', (tester) async {
    await setSize(tester, const Size(500, 900));
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SignInScreen()),
        GoRoute(path: '/setup', builder: (_, _) => const Text('setup page')),
      ],
    );
    Widget app() => ProviderScope(
      overrides: [backendProvider.overrideWithValue(FakeBackend()..signedIn = false), localCacheProvider.overrideWithValue(const NoCache())],
      child: MaterialApp.router(routerConfig: router, localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
    );
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Run on This Mac'), findsOneWidget);
    await tester.tap(find.byKey(const Key('runOnThisComputer')));
    await settle(tester);
    expect(find.text('setup page'), findsOneWidget);
    expect(GuidedSetup.active.value, isTrue);

    GuidedSetup.reset();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    router.go('/');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('runOnThisComputer')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  onMac('a launch during the setup opens it again; other launches never do', (tester) async {
    await setSize(tester, const Size(900, 1000));
    Future<ProviderContainer> launch(FakeBackend backend) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            backendProvider.overrideWithValue(backend),
            usingLocalServerProvider.overrideWith((ref) async => false),
            dockerCheckProvider.overrideWithValue(_Docker(DockerState.notInstalled)),
          ],
          child: const CasamaApp(),
        ),
      );
      await settle(tester);
      return ProviderScope.containerOf(tester.element(find.byType(CasamaApp)));
    }

    var c = await launch(FakeBackend()..signedIn = false);
    expect(c.read(routerProvider).state.matchedLocation, '/sign-in');
    await GuidedSetup.begin();
    c = await launch(FakeBackend()..signedIn = false);
    expect(c.read(routerProvider).state.matchedLocation, '/setup');
    expect(find.byKey(const Key('setupScreen')), findsOneWidget);
    // Signed in and part way: back to the setup, with no name page over it.
    c = await launch(FakeBackend()..about = const AboutYouView(displayName: 'Test Person'));
    expect(c.read(routerProvider).state.matchedLocation, '/setup');
    expect(find.byKey(const Key('nameStep')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  onMac('the home card says what is left and opens the setup again', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend()
      ..noKeys = true
      ..remoteAccessStatus = status('off', on: false);
    await GuidedSetup.skip('ai');
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: FinishSetupCard())),
        GoRoute(path: '/setup', builder: (_, _) => const Text('setup page')),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendProvider.overrideWithValue(backend),
          localCacheProvider.overrideWithValue(const NoCache()),
          usingLocalServerProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp.router(routerConfig: router, localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
      ),
    );
    await settle(tester);
    expect(find.text('Finish setting up'), findsOneWidget);
    expect(find.text('Add an AI model so your bots can answer.'), findsOneWidget);
    expect(find.text('Connect your phone to this computer.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('finishSetupOpen')));
    await settle(tester);
    expect(find.text('setup page'), findsOneWidget);
    expect(GuidedSetup.skipped.value, isEmpty);
    expect(GuidedSetup.active.value, isTrue);

    // Closed for good.
    await GuidedSetup.end();
    router.go('/');
    await settle(tester);
    await tester.tap(find.byKey(const Key('finishSetupDismiss')));
    await settle(tester);
    expect(find.byKey(const Key('finishSetupCard')), findsNothing);
    expect(GuidedSetup.cardDismissed.value, isTrue);
  });
}

/// A widget test on a Mac (the platform override has to be gone before the test ends).
void onMac(String description, Future<void> Function(WidgetTester tester) body) => testWidgets(description, (tester) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
  try {
    await body(tester);
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
});

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Takes the page down, so its timers stop before the test ends.
Future<void> leave(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 100));
}
