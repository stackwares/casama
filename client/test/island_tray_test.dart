import 'package:casama/features/island/island_feed.dart';
import 'package:casama/features/island/island_tray.dart';
import 'package:casama/l10n/generated/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

final l10n = AppLocalizationsEn();

IslandItem item(
  String id,
  IslandPhase phase, {
  String step = 'Searching the web',
  String? approval,
  bool here = false,
}) => IslandItem(
  id: id,
  phase: phase,
  botId: 'b',
  bot: 'Ada',
  step: step,
  link: '/chat/$id',
  startedAt: DateTime(2026, 11, 16),
  runId: id,
  approvalId: approval,
  onThisComputer: here,
);

void main() {
  test('an empty tray says nothing is going on', () {
    expect(trayEntries(const [], l10n).single.label, 'No bot is working right now');
    expect(trayTooltip(const [], l10n), 'Casama');
    expect(trayTitle(const [], l10n), isNull);
  });

  test('each run is a row with the notch\'s buttons, needs you first', () {
    final feed = [
      item('r1', IslandPhase.needsOk, step: 'Delete the old backups', approval: 'a1'),
      item('r2', IslandPhase.working, here: true),
      item('r3', IslandPhase.finished, step: 'Finished'),
    ];
    final e = trayEntries(feed, l10n);
    expect(e.map((e) => e.label), [
      'Ada: Needs your OK: Delete the old backups',
      'Allow',
      'Deny',
      'Open',
      'Ada: Searching the web (on this computer)',
      'Stop',
      'Open',
      'Ada: Finished',
      'Open',
    ]);
    expect(e[1].action, {'kind': 'allow', 'approval_id': 'a1'});
    expect(e[2].action, {'kind': 'deny', 'approval_id': 'a1'});
    expect(e[5].action, {'kind': 'stop', 'run_id': 'r2'});
    expect(e[6].action, {'kind': 'open', 'link': '/chat/r2'});
    expect(e[0].isButton, isFalse);
    expect(trayTooltip(feed, l10n), 'Ada: Needs your OK: Delete the old backups');
    expect(trayTitle(feed, l10n), '● Needs you');
    expect(trayTitle([item('r2', IslandPhase.working)], l10n), '● Ada');
  });

  test('a request without its approval yet offers only Open', () {
    final e = trayEntries([item('r1', IslandPhase.needsOk)], l10n);
    expect(e.map((e) => e.label), ['Ada: Needs your OK: Searching the web', 'Open']);
  });
}
