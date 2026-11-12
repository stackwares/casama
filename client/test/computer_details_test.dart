import 'package:casama_app/features/companion/os_label.dart';
import 'package:casama_app/features/computer/computer_details.dart';
import 'package:casama_app/features/computer/computers_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

const _localId = '66666666-6666-4666-8666-666666666666';
const _brokenId = '77777777-7777-4777-8777-777777777777';

Computer _computer({
  required String id,
  required ComputerKindEnum kind,
  required String name,
  ComputerState state = ComputerState.running,
  String provider = 'docker',
  ComputerSize? size,
  String? os,
  ComputerDevice? device,
  DateTime? lastActiveAt,
  String? error,
  bool hasSnapshot = false,
}) => Computer(
  id: id,
  orgId: orgId,
  kind: kind,
  name: name,
  ownerBotId: null,
  lastActiveAt: lastActiveAt,
  error: error,
  provider: provider,
  profile: ComputerProfileEnum.headless,
  state: state,
  size: size ?? ComputerSize(),
  hasSnapshot: hasSnapshot,
  maxDesktops: 1,
  createdAt: DateTime(2026),
  os: os,
  device: device,
);

/// A team computer, a personal one that's offline, and one that failed.
class _DetailedComputers extends FakeBackend {
  @override
  Future<List<Computer>> computers(String orgId) async => [
    _computer(
      id: computerId,
      kind: ComputerKindEnum.team,
      name: 'Team computer',
      state: ComputerState.sleeping,
      size: ComputerSize(cpus: 1, memoryMb: 1024, diskGb: 10),
      os: 'Ubuntu 24.04',
      hasSnapshot: true,
      lastActiveAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    _computer(
      id: _localId,
      kind: ComputerKindEnum.local,
      name: 'Work laptop',
      provider: 'local',
      state: ComputerState.stopped,
      os: 'macOS 26.2',
      device: ComputerDevice(
        platform: ComputerDevicePlatformEnum.macos,
        online: false,
        lastSeenAt: DateTime.now().subtract(const Duration(minutes: 5)),
        capabilities: LocalCapabilities(files: true, shell: true),
      ),
    ),
    _computer(
      id: _brokenId,
      kind: ComputerKindEnum.private,
      name: 'Build box',
      state: ComputerState.error,
      error: 'supervisor unreachable: fetch failed',
    ),
  ];
}

void main() {
  test('OS names read like people say them', () {
    expect(osLabel(os: 'macos', version: 'Version 26.2 (Build 25C56)'), 'macOS 26.2');
    expect(osLabel(os: 'macos', version: 'something else'), 'macOS');
    expect(osLabel(os: 'windows', version: '"Windows 10 Pro" 10.0 (Build 26100)'), 'Windows 11 Pro');
    expect(osLabel(os: 'windows', version: '"Windows 10 Home" 10.0 (Build 19045)'), 'Windows 10 Home');
    expect(
      osLabel(os: 'linux', version: '#1 SMP', osRelease: 'NAME="Ubuntu"\nPRETTY_NAME="Ubuntu 24.04.1 LTS"\nID=ubuntu\n'),
      'Ubuntu 24.04.1 LTS',
    );
    expect(osLabel(os: 'linux', version: '#1 SMP'), 'Linux');
  });

  test('memory sizes', () {
    expect(memoryLabel(512), '512 MB');
    expect(memoryLabel(1024), '1 GB');
    expect(memoryLabel(1536), '1.5 GB');
  });

  testWidgets('computer cards say what the machine is, what bots may use, and when it was last on', (tester) async {
    await setSize(tester, const Size(600, 1000));
    await tester.pumpWidget(harness(_DetailedComputers(), const ComputersScreen()));
    await tester.pumpAndSettle();

    // The team computer: no "Team computer" twice; its system and size instead.
    expect(find.text('Team computer'), findsOneWidget);
    expect(find.text('Ubuntu 24.04 · 1 CPU · 1 GB RAM · 10 GB disk'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Last used 2 hours ago'), findsOneWidget);

    // A personal computer on another machine: its OS (not "This device"), access, last seen.
    expect(find.byKey(const Key('computerSystem-$_localId')), findsOneWidget);
    expect(find.text('macOS 26.2'), findsOneWidget);
    expect(find.text('Bots can use: Files, Terminal'), findsOneWidget);
    expect(find.text('Last seen 5 minutes ago'), findsOneWidget);
    expect(find.text('This device'), findsNothing);

    // A failed computer says why.
    expect(find.text('Private computer'), findsOneWidget);
    expect(find.text('supervisor unreachable: fetch failed'), findsOneWidget);
  });

  testWidgets('this machine says so, and an older server without details still shows a card', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(harness(FakeBackend(), Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    })));
    final local = _computer(id: _localId, kind: ComputerKindEnum.local, name: 'Mac', os: 'macOS 26.2');
    expect(computerSystemLine(ctx, local, thisDevice: true), 'macOS 26.2 · This device');
    final old = _computer(id: computerId, kind: ComputerKindEnum.team, name: 'Team computer', size: ComputerSize(cpus: 2));
    expect(computerSystemLine(ctx, old, thisDevice: false), '2 CPUs');
    expect(computerAccessLine(ctx, local), isNull);
    expect(computerActivityLine(ctx, old), isNull);
  });
}
