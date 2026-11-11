# Fix: After an update, nothing tells people what's new

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/in-app-changelog
- **Needs new dependency**: `pub_semver: ^2.2.1`, the article's way to compare versions (so someone jumping from 1.2.0 to 1.5.0 sees everything in between). It is already in `pubspec.lock` at 2.2.1 as a transitive dependency, so nothing new downloads. It must be listed directly because the app imports it (the `depend_on_referenced_packages` lint).

## Why

After an update, people open Casama and nothing tells them what changed. The fix someone reported and the feature someone asked for go unnoticed. A short list that comes up by itself the first time they open a new version, once, shows them what's new, and the person who asked knows they were heard.

## Where

Nothing in the app shows release notes (`grep -rniE "changelog|whats_new|whatsNew|release_notes|last_seen_version|version_history" lib` finds nothing). The repo's `CHANGELOG.md` is written for developers (Keep a Changelog, API and self-hosting details) and isn't shipped in the app.

The view will hang off the signed-in shell, which is the only place it should appear: never over `/sign-in`, `/welcome`, `/onboarding`, `/join-team`, `/two-step` or `/new-password`, which are all routes outside this `ShellRoute`.

```dart
// lib/core/router.dart:238-244 — current
      ShellRoute(
        pageBuilder: (context, state, child) => MaterialPage(
          key: state.pageKey,
          child: PasskeySuggestion(
            child: HomeShell(location: state.uri.path, child: child),
          ),
        ),
```

`PasskeySuggestion` (`lib/features/auth/account_screen.dart:358-387`) already uses this pattern: a one-time prompt that wraps the shell and runs on a timer once the first screen settles. The new gate copies its shape.

Things that can sit above the app and must not be covered or stacked on: the "What should bots call you?" page (`nameStepNeededProvider`, `lib/features/settings/name_step.dart:30`) and the "Turn on notifications" page (`pushProvider`'s `needsAsk`, `lib/core/push.dart:81`). Both are drawn by `_FirstRunSteps` in `lib/app.dart` above the navigator, so a sheet would end up underneath them.

The app's version comes from `PackageInfo.fromPlatform().version` (`"0.8.0"`, from `version: 0.8.0+8` in `pubspec.yaml`), the same source as `appVersionProvider` in `lib/core/updater.dart:82`.

## The fix

The article's fix:

- A versioned map of plain-language lines.
- `unseenChanges(lastSeen, current)` returns every version's lines after the last seen one, compared with `pub_semver`.
- `package_info_plus` gives the current version, and `shared_preferences` keeps the last seen one under `last_seen_version`.
- First install: save and show nothing. Same version: nothing. No lines: save and move on. Otherwise show the list and mark the version seen the moment it appears.

Applied here:

- **The lines** are a Dart map, as in the article. Each line is a string in `app_en.arb`, because every user-facing string in this app lives there. That covers the article's "support all languages" through the app's own localizations instead of a `Language` enum.
- **Every version needs lines.** A test reads `pubspec.yaml`'s version and fails until the map has it. Without that, a release would quietly ship with no notes and the sheet would never appear.
- **The view** is the app's adaptive sheet (`showAdaptiveSheet`: a bottom sheet on phones, a dialog on larger windows) with the app's `FormSheet` body: icon tile, title, the lines with a check mark each, and one "Got it" button.
- **When it shows:** 800 ms after the signed-in shell first appears. Not over the name or notifications pages, and not over another sheet or dialog; in those cases it waits for the next open, without marking the version as seen. The key is `whatsNew.lastSeenVersion`, in the dotted style of this app's other keys (`passkey.suggested`, `appearance.mode`).
- **Remote copy** (the article's optional "fetch it remotely") is left for later. See "Don't touch".

About the first entry: no installed build has this feature yet, so every install that first runs it counts as fresh and shows nothing. The 0.8.0 lines below will therefore never be shown. They exist because every version needs lines, and they show the pattern. The first sheet anyone sees will be for the next version.

New file `lib/features/whats_new/whats_new.dart`, exactly:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/push.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';
import '../settings/name_step.dart';

/// What changed for people in each version, newest first, in plain words: what someone will notice,
/// not how it was built (CHANGELOG.md is the developers' record). When pubspec.yaml's version goes
/// up, add that version at the top with three to five lines, each a string in app_en.arb named
/// whatsNew<version><Topic>. test/whats_new_test.dart fails until the current version has lines.
Map<String, List<String>> whatsNewByVersion(AppLocalizations l10n) => {
  '0.8.0': [
    l10n.whatsNew080Calls,
    l10n.whatsNew080Looks,
    l10n.whatsNew080AboutYou,
    l10n.whatsNew080SignIn,
  ],
};

/// The version whose lines were shown last, or the version first opened.
const whatsNewSeenKey = 'whatsNew.lastSeenVersion';

Version? _version(String value) {
  try {
    return Version.parse(value);
  } on FormatException {
    return null;
  }
}

/// The lines of every version after [lastSeen] up to and including [current], newest first, so
/// someone who skipped updates sees all they missed. Empty when a version can't be read.
List<String> unseenChanges({required String lastSeen, required String current, required Map<String, List<String>> changelog}) {
  final seen = _version(lastSeen);
  final now = _version(current);
  if (seen == null || now == null) return const <String>[];
  final result = <String>[];
  for (final entry in changelog.entries) {
    final version = _version(entry.key);
    if (version != null && version > seen && version <= now) result.addAll(entry.value);
  }
  return result;
}

/// Shows what's new once, the first time the signed-in app opens after an update. Never on a fresh
/// install (the version is only remembered), never over sign-in, the welcome chat or onboarding
/// (it wraps only the signed-in shell), and not over the name or notifications pages or another
/// sheet: then it waits for the next open.
class WhatsNewGate extends ConsumerStatefulWidget {
  const WhatsNewGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<WhatsNewGate> createState() => _WhatsNewGateState();
}

class _WhatsNewGateState extends ConsumerState<WhatsNewGate> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Let the first screen settle before anything slides over it.
    _timer = Timer(const Duration(milliseconds: 800), _check);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (!mounted) return;
    final l10n = context.l10n;
    try {
      final current = (await PackageInfo.fromPlatform()).version;
      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getString(whatsNewSeenKey);
      final lines = lastSeen == null ? const <String>[] : unseenChanges(lastSeen: lastSeen, current: current, changelog: whatsNewByVersion(l10n));
      // A fresh install (nothing seen yet), the same version, or an update with no lines.
      if (lines.isEmpty) {
        if (lastSeen != current) await prefs.setString(whatsNewSeenKey, current);
        return;
      }
      if (!mounted) return;
      // Not over the name or notifications pages, or over another sheet: next open instead.
      if ((ref.read(nameStepNeededProvider) ?? false) || ref.read(pushProvider).needsAsk.value) return;
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      // Seen the moment it shows, so it never comes back for this version.
      await prefs.setString(whatsNewSeenKey, current);
      if (!mounted) return;
      await showWhatsNew(context, version: current, lines: lines);
    } catch (_) {
      // No version or preferences (widget tests, a locked keychain): nothing to show.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The list of what's new in [version], in the app's adaptive sheet (a sheet on phones, a dialog on
/// larger windows).
Future<void> showWhatsNew(BuildContext context, {required String version, required List<String> lines}) {
  final l10n = context.l10n;
  return showAdaptiveSheet<void>(
    context: context,
    dialogMaxWidth: 460,
    builder: (c) => FormSheet(
      key: const Key('whatsNewSheet'),
      icon: LucideIcons.sparkles,
      title: l10n.whatsNewTitle(version),
      submitLabel: l10n.whatsNewGotIt,
      submitKey: const Key('whatsNewDone'),
      showCancel: false,
      onSubmit: () => Navigator.pop(c),
      children: [for (final line in lines) _Line(line)],
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Icon(LucideIcons.check, size: 18, color: context.colorScheme.primary),
      ),
      const SizedBox(width: AppSpace.sm),
      Expanded(child: Text(text, style: context.textTheme.bodyLarge?.copyWith(height: 1.4))),
    ],
  );
}
```

`lib/core/router.dart`, target:

```dart
      ShellRoute(
        pageBuilder: (context, state, child) => MaterialPage(
          key: state.pageKey,
          child: PasskeySuggestion(
            child: WhatsNewGate(
              child: HomeShell(location: state.uri.path, child: child),
            ),
          ),
        ),
```

New strings in `lib/l10n/app_en.arb`:

```json
  "whatsNewTitle": "What's new in Casama {version}",
  "@whatsNewTitle": {"placeholders": {"version": {"type": "String"}}},
  "whatsNewGotIt": "Got it",
  "whatsNew080Calls": "Call your bots and talk things through. They answer out loud, with captions.",
  "whatsNew080Looks": "Make Casama yours: color schemes, fonts and wallpapers in Settings → Themes, with more in the Gallery.",
  "whatsNew080AboutYou": "Tell your bots about yourself once, in Settings → About you: what to call you and how you like replies.",
  "whatsNew080SignIn": "Sign in with a passkey, Apple, Google or a code from your email.",
```

## Steps

1. In `pubspec.yaml`, under `dependencies:`, add the line `  pub_semver: ^2.2.1` directly below the existing line `  package_info_plus: ^10.2.2`. Edit by hand. Then run `flutter pub get` in `client/`.
2. In `lib/l10n/app_en.arb`, add the seven lines from "The fix" directly below the existing line `  "@appVersion": {"placeholders": {"version": {"type": "String"}}},`. Edit by hand and keep the commas exactly as shown. Then run `flutter gen-l10n` in `client/`.
3. Create `lib/features/whats_new/whats_new.dart` with the exact content from "The fix", then run `dart format -l 200 lib/features/whats_new/whats_new.dart`. That file only: never run `dart format` on any existing file or directory.
4. In `lib/core/router.dart`, add `import '../features/whats_new/whats_new.dart';` as a new line among the `import '../features/…';` lines at the top. Any position in that block is fine.
5. In `lib/core/router.dart`, wrap `HomeShell(…)` in `WhatsNewGate(child: …)` exactly as in the target. Keep `key: state.pageKey`, `PasskeySuggestion` and `HomeShell(location: state.uri.path, child: child)` as they are. Change nothing else in this file.
6. Create `test/whats_new_test.dart` with exactly this content, then run `dart format -l 200 test/whats_new_test.dart`:

```dart
import 'dart:io';

import 'package:casama_app/features/whats_new/whats_new.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';

/// The app's version from pubspec.yaml ("0.8.0" from "version: 0.8.0+8").
final _appVersion = RegExp(r'^version:\s*([^+\s]+)', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1)!;

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  setUp(() => PackageInfo.setMockInitialValues(appName: 'Casama', packageName: 'ai.casama.app', version: _appVersion, buildNumber: '1', buildSignature: ''));

  test("every app version has its what's-new lines (add them when pubspec.yaml's version goes up)", () {
    expect(
      whatsNewByVersion(l10n)[_appVersion],
      isNotEmpty,
      reason: 'Add $_appVersion to whatsNewByVersion in lib/features/whats_new/whats_new.dart, with its strings in app_en.arb',
    );
  });

  test('someone who skipped updates sees everything since the version they last saw, newest first', () {
    const log = {
      '1.3.0': ['c'],
      '1.2.0': ['a', 'b'],
      '1.1.0': ['old'],
    };
    expect(unseenChanges(lastSeen: '1.1.0', current: '1.3.0', changelog: log), ['c', 'a', 'b']);
    expect(unseenChanges(lastSeen: '1.2.0', current: '1.3.0', changelog: log), ['c']);
    expect(unseenChanges(lastSeen: '1.3.0', current: '1.3.0', changelog: log), isEmpty);
    // A downgrade, or a version that can't be read: nothing.
    expect(unseenChanges(lastSeen: '1.3.0', current: '1.2.0', changelog: log), isEmpty);
    expect(unseenChanges(lastSeen: 'garbage', current: '1.3.0', changelog: log), isEmpty);
  });

  Future<void> openApp(WidgetTester tester) async {
    final backend = FakeBackend();
    // The name page was answered, so nothing sits above the app.
    backend.about = backend.about.copyWith(nameAsked: true);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(harness(backend, const WhatsNewGate(child: Scaffold(body: Text('home')))));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  testWidgets('a fresh install shows nothing and remembers this version', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await openApp(tester);
    expect(find.byKey(const Key('whatsNewSheet')), findsNothing);
    expect((await SharedPreferences.getInstance()).getString(whatsNewSeenKey), _appVersion);
  });

  testWidgets('after an update the new lines come up once', (tester) async {
    SharedPreferences.setMockInitialValues({whatsNewSeenKey: '0.0.1'});
    await openApp(tester);
    expect(find.byKey(const Key('whatsNewSheet')), findsOneWidget);
    expect(find.text(l10n.whatsNewTitle(_appVersion)), findsOneWidget);
    expect(find.text(whatsNewByVersion(l10n)[_appVersion]!.first), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getString(whatsNewSeenKey), _appVersion);
    await tester.tap(find.byKey(const Key('whatsNewDone')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('whatsNewSheet')), findsNothing);
    // The next open: nothing new.
    await openApp(tester);
    expect(find.byKey(const Key('whatsNewSheet')), findsNothing);
  });
}
```

7. Record the decision. Run `grep -n "^## D-" /Users/nemoryoliver/Desktop/Projects/Kasama/docs/DECISIONS.md | tail -1` to find the highest number in use (D-188 when this plan was written; others add entries in parallel). Then append the entry below at the end of `/Users/nemoryoliver/Desktop/Projects/Kasama/docs/DECISIONS.md`, with one blank line before it, replacing `NNN` with that number plus one:

```markdown
## D-NNN What's new after an update

- **Decision:** the first time the signed-in app opens on a new version, a sheet lists what changed since the version the person last saw, in plain words (a bottom sheet on phones, a dialog on larger windows, one "Got it" button). It never shows on a fresh install (the version is only remembered), never over sign-in, the welcome chat or onboarding (it wraps only the signed-in shell), and not over the name or notifications pages or another sheet (then it waits for the next open). It shows once: the version is saved as seen the moment it appears (SharedPreferences `whatsNew.lastSeenVersion`). Someone who skipped versions sees every version's lines in between, newest first (compared with `pub_semver`).
- **Where the words come from:** `whatsNewByVersion` in `client/lib/features/whats_new/whats_new.dart`, with each line a string in `app_en.arb`. CHANGELOG.md stays the developers' record. The lines are bundled, so fixing a typo needs a release; the server could serve them later.
- **Every version needs lines:** `client/test/whats_new_test.dart` fails until pubspec.yaml's version has an entry, so a release can't ship without its notes. The 0.8.0 lines are never shown (no earlier build has this feature, so every install of it counts as fresh); the first sheet people see is the next version's.
- **Tests:** `client/test/whats_new_test.dart`.
```

8. Run `flutter test test/whats_new_test.dart test/navigation_test.dart test/phone_layout_test.dart` in `client/`.

## Check it

- `dart analyze lib/features/whats_new/whats_new.dart lib/core/router.dart test/whats_new_test.dart` reports no errors and no warnings. The `curly_braces_in_flow_control_structures` infos in `router.dart`'s `redirect` (six `if` lines) were there before this change; leave them.
- `grep -c "WhatsNewGate(" lib/core/router.dart` → `1`
- `grep -c "import '../features/whats_new/whats_new.dart';" lib/core/router.dart` → `1`
- `grep -c "pub_semver: \^2.2.1" pubspec.yaml` → `1`
- `grep -c '"whatsNewTitle"' lib/l10n/app_en.arb` → `1`
- `grep -c "whatsNew080Calls" lib/l10n/generated/app_localizations.dart` → at least `1` (proves `flutter gen-l10n` ran)
- `grep -c "class WhatsNewGate" lib/features/whats_new/whats_new.dart` → `1`
- `grep -c "What's new after an update" /Users/nemoryoliver/Desktop/Projects/Kasama/docs/DECISIONS.md` → `1`
- The `flutter test` command in step 8 passes.

## Don't touch

- `CHANGELOG.md` at the repo root: it stays the developers' record and isn't shipped in the app.
- `lib/features/auth/account_screen.dart` (`PasskeySuggestion`), `lib/app.dart` (`_FirstRunSteps`), `lib/features/settings/name_step.dart`, `lib/core/push.dart`: the gate only reads their state.
- `lib/core/updater.dart`: `appVersionProvider` stays as it is. The gate reads `PackageInfo` directly, as the article does, so a failed read in widget tests never starts Riverpod's automatic retries.
- The sign-in, welcome, onboarding and other routes outside the `ShellRoute`.
- Fetching the lines from the server: the article suggests it as an option. It needs an API and a cache, so it's a separate change.
- No git commands (others commit in this tree). No `dart format` on existing files or folders. Keep every existing widget `Key` (`state.pageKey` included).
- No new dependencies beyond `pub_semver`. No refactors, renames or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written). Line numbers may have shifted because of other changes; only the quoted code has to match.
- `pubspec.yaml`'s `version:` is no longer `0.8.0+…`. The `0.8.0` key in `whatsNewByVersion` must then be the new version, with lines written for it, and those words are the developer's call.
- The fix seems to require touching something in "Don't touch".
- A test in step 8 fails because of this change, or any check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different. The first time someone opens a new version of the signed-in app, a "What's new in Casama X" sheet lists that version's lines (and any versions they skipped), once, never on a fresh install or over sign-in and onboarding. Each release now needs its lines in `whatsNewByVersion` and `app_en.arb`, and a test fails until they're there. To see it locally, set `whatsNew.lastSeenVersion` to `0.0.1` (for example, in the test above) and open the app signed in.
