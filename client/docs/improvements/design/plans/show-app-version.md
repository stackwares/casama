# Fix: There's no place to see which version and build is installed

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/show-app-version
- **Needs new dependency**: none (`package_info_plus` is already in `pubspec.yaml`)

## Why

When someone reports a bug, the first question is which version they're on, and Casama has no place to answer it. Phones show no version anywhere. Desktop shows only "Version 0.8.0", with no build number, two levels deep under Settings → Advanced → Check for updates. A quiet line at the foot of Settings, "Casama 0.8.0 (8)", answers it for everyone: people, QA and support. A tap copies it for the bug report.

## Where

```dart
// lib/core/updater.dart:81-82 — current (version only, no build number)
/// This app's version ("0.8.0").
final appVersionProvider = FutureProvider<String>((ref) async => (await PackageInfo.fromPlatform()).version);
```

```dart
// lib/features/settings/settings_screen.dart:554-576 — current (the only place a version shows: desktop only, inside the folded Advanced section, and without the build)
    final version = ref.watch(appVersionProvider).value ?? '';
    if (updateNoticeOnly) {
      final newer = ref.watch(newerReleaseProvider).value;
      return GroupedTile(
        key: const Key('settingsUpdates'),
        icon: LucideIcons.download,
        title: newer == null ? l10n.upToDate : l10n.updateReady(newer.version),
        subtitle: l10n.appVersion(version),
        showChevron: newer != null,
        onTap: newer == null ? null : () => launchUrl(newer.page, mode: LaunchMode.externalApplication),
      );
    }
    final auto = ref.watch(autoUpdateChecksProvider).value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GroupedTile(
          key: const Key('settingsCheckUpdates'),
          icon: LucideIcons.download,
          title: l10n.checkForUpdates,
          subtitle: l10n.appVersion(version),
          showChevron: false,
          onTap: () => runGuarded(context, checkForUpdatesNow),
```

`_UpdatesRows` is only built when `selfUpdating || updateNoticeOnly` (line 276), which is desktop downloads.

```dart
// lib/features/settings/settings_screen.dart:315-330 — current (the end of the Settings list; "Sign out" is the last card of `right`, lines 299-313)
          return ListView(
            padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.xxl + MediaQuery.paddingOf(context).bottom),
            children: [
              profile,
              if (twoColumns)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: left)),
                    const SizedBox(width: AppSpace.xl),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: right)),
                  ],
                )
              else ...[...left, ...right],
            ],
          );
```

Shorebird is not used (it was removed by decision D-175, and `pubspec.yaml` has no `shorebird` entry), so there is no patch number to show.

## The fix

The article's fix is a drop-in `VersionIndicator` at the bottom of the settings page. It reads the app name, version and build from `PackageInfo` and shows `'${info.appName} ${info.version} (${info.buildNumber})'` in a small (12 px, weight 500), dim, tabular-figures line. It must show the build number, not just the version, and stay dim, since this line should "whisper". There is no Shorebird patch here.

Adapted to this codebase:

- **The read** goes in a Riverpod `FutureProvider` next to `appVersionProvider` instead of a `StatefulWidget`'s `initState`. It's read once per app run, so reopening Settings never makes the line pop in again. It catches its own failure and returns null, so a platform without package info (widget tests) shows no line and never starts Riverpod's automatic retries.
- **The name** is the existing string `casamaVersion` ("Casama {version}") instead of `PackageInfo.appName`. On the web and Linux, `appName` is the pubspec package name `casama_app`, not "Casama".
- **The build number** is left out of the brackets when a platform reports none, so the line never ends in "()".
- **The style** is the theme's `labelMedium` (12 px, weight 500, the article's size and weight) with `AppText.tabular`, in `onSurfaceVariant` at 75 % opacity (the app's quiet-text color, dimmed).
- **A tap copies the line** and confirms with the existing "Copied" snackbar, for bug reports. A `Tooltip` reading "Copy" names the action for mouse and screen-reader users, and there is no visible button.

`lib/core/updater.dart`, add directly below `appVersionProvider` (after line 82):

```dart

/// This build's version and build number, "0.8.0 (8)", for the line at the foot of Settings (just
/// "0.8.0" where a platform reports no build number). Null when it can't be read (widget tests).
final appVersionLabelProvider = FutureProvider<String?>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return info.buildNumber.isEmpty ? info.version : '${info.version} (${info.buildNumber})';
  } catch (_) {
    return null;
  }
});
```

New file `lib/features/settings/version_indicator.dart`, exactly:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/updater.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';

/// "Casama 0.8.0 (8)" at the foot of Settings: the version and build, so anyone can say which one
/// they're on in a bug report. Dim on purpose; a tap copies it.
class VersionIndicator extends ConsumerWidget {
  const VersionIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionLabelProvider).value;
    if (version == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final label = l10n.casamaVersion(version);
    return Tooltip(
      message: l10n.copy,
      child: InkWell(
        key: const Key('appVersion'),
        borderRadius: AppRadius.rowAll,
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: label));
          if (context.mounted) showMessage(context, l10n.copied);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.sm),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: context.textTheme.labelMedium?.copyWith(
              fontFeatures: AppText.tabular,
              color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}
```

`lib/features/settings/settings_screen.dart`, target for the `ListView` (the two new children go last, after the columns, so the line sits under "Sign out" on phones and centered under both columns on wide windows):

```dart
          return ListView(
            padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.xxl + MediaQuery.paddingOf(context).bottom),
            children: [
              profile,
              if (twoColumns)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: left)),
                    const SizedBox(width: AppSpace.xl),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: right)),
                  ],
                )
              else ...[...left, ...right],
              // The version and build, for bug reports (a tap copies it).
              const SizedBox(height: AppSpace.md),
              const Center(child: VersionIndicator()),
            ],
          );
```

No new strings: `casamaVersion`, `copy` and `copied` already exist in `app_en.arb`.

## Steps

1. In `lib/core/updater.dart`, add `appVersionLabelProvider` from "The fix" directly below `appVersionProvider`. Edit by hand. Never run `dart format` on an existing file or directory.
2. Create `lib/features/settings/version_indicator.dart` with the exact content from "The fix", then run `dart format -l 200 lib/features/settings/version_indicator.dart`. That file only.
3. In `lib/features/settings/settings_screen.dart`, add `import 'version_indicator.dart';` as a new line directly below `import 'about_you_screen.dart';`.
4. In `lib/features/settings/settings_screen.dart`, add the comment and the two lines (`const SizedBox(height: AppSpace.md),` and `const Center(child: VersionIndicator()),`) as the last children of the `ListView`, directly below `else ...[...left, ...right],`, exactly as in the target. Change nothing else in this file.
5. Create `test/version_indicator_test.dart` with exactly this content, then run `dart format -l 200 test/version_indicator_test.dart`:

```dart
import 'package:casama_app/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('Settings ends with the version and build; a tap copies it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(appName: 'casama_app', packageName: 'ai.casama.app', version: '0.8.0', buildNumber: '8', buildSignature: '');
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await setSize(tester, const Size(430, 3200));
    await tester.pumpWidget(harness(FakeBackend(), const SettingsScreen()));
    await tester.pumpAndSettle();
    // "Casama", not the package name, and the build number in brackets.
    expect(find.text('Casama 0.8.0 (8)'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('appVersion')));
    await tester.tap(find.byKey(const Key('appVersion')));
    await tester.pumpAndSettle();
    expect(copied, 'Casama 0.8.0 (8)');
    expect(find.text('Copied'), findsOneWidget);
  });
}
```

6. Run `flutter test test/version_indicator_test.dart test/advanced_section_test.dart test/phone_layout_test.dart` in `client/`.

## Check it

- `dart analyze lib/core/updater.dart lib/features/settings/version_indicator.dart lib/features/settings/settings_screen.dart test/version_indicator_test.dart` reports no issues.
- `grep -c "final appVersionLabelProvider" lib/core/updater.dart` → `1`
- `grep -c "info.buildNumber.isEmpty ? info.version" lib/core/updater.dart` → `1`
- `grep -c "const Center(child: VersionIndicator())" lib/features/settings/settings_screen.dart` → `1`
- `grep -c "import 'version_indicator.dart';" lib/features/settings/settings_screen.dart` → `1`
- `grep -c "class VersionIndicator" lib/features/settings/version_indicator.dart` → `1`
- The `flutter test` command in step 6 passes.

## Don't touch

- `_UpdatesRows` in `settings_screen.dart`: "Check for updates · Version 0.8.0" stays as the context for updating on desktop. The new line is the one place that always shows version and build.
- `appVersionProvider`: `newerReleaseProvider` compares it with the latest release tag, so it must stay the bare version.
- `lib/features/admin/admin_screen.dart`'s `casamaVersion(o.version)`: that's the server's version, a different thing.
- Shorebird: not used (D-175); don't add a patch number or the package.
- The "Sign out" card, the Advanced section and every other row and `Key` in Settings.
- No git commands (others commit in this tree). No `dart format` on existing files or folders. Keep every existing widget `Key`.
- No new dependencies. No refactors, renames or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written). Line numbers may have shifted because of other changes; only the quoted code has to match.
- `pubspec.yaml` lists `shorebird_code_push` (the article then wants the patch number too, which this plan doesn't cover).
- The fix seems to require touching something in "Don't touch".
- A test in step 6 fails because of this change, or any check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different. Settings now ends with a dim "Casama 0.8.0 (8)" line under Sign out on every platform, with the build number, and a tap copies it with a "Copied" confirmation for bug reports. To see it, open Settings and scroll to the bottom.
