// Fix 17: an attachment goes only to a computer the bot uses, picked as the server picks it.
import 'package:casama_app/features/chat/chat_screen.dart' show computerForBot;
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

Computer _c(String id, ComputerKindEnum kind, {String? ownerBotId}) => Computer(
  id: id,
  orgId: 'org',
  kind: kind,
  name: id,
  ownerBotId: ownerBotId,
  lastActiveAt: null,
  error: null,
  provider: 'docker',
  profile: ComputerProfileEnum.headless,
  state: ComputerState.running,
  size: ComputerSize(),
  hasSnapshot: false,
  maxDesktops: 1,
  createdAt: DateTime(2026),
);

void main() {
  final team = _c('team', ComputerKindEnum.team);
  final mine = _c('mine', ComputerKindEnum.private, ownerBotId: 'ada');
  final other = _c('other', ComputerKindEnum.private, ownerBotId: 'max');

  test('the default computer, else its own, else the team computer', () {
    expect(computerForBot([team, mine, other], 'ada', defaultComputerId: 'other')?.id, 'other');
    expect(computerForBot([team, mine, other], 'ada')?.id, 'mine');
    expect(computerForBot([other, team], 'ada')?.id, 'team');
  });

  test("never another bot's computer", () {
    expect(computerForBot([other], 'ada'), isNull);
  });

  test('a default computer that is gone is not swapped for another', () {
    expect(computerForBot([team, mine], 'ada', defaultComputerId: 'missing'), isNull);
  });
}
