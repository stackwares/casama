# Fix: Counters, countdowns and chart amounts jiggle as their digits change

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/tabular-figures
- **Needs new dependency**: none

## Why

In the app's fonts a `1` is narrower than an `8`, so a number that changes or sits in a column
shifts sideways: the "Send again in 59s" countdown wobbles every second, the Inbox badge and
the "Needs you (3)" chip change width as items arrive, and the dollar labels on the Usage chart
don't line up. Tabular figures give every digit the same width, so these numbers stay still and
line up. Casama already does this for most money and stats (`AppText.tabular` in
`lib/theme/app_tokens.dart`, used by `CountPill`, the Usage and Billing totals, timers on the
call screen); these are the changing or aligned numbers that were missed.

## Where

Every changing or aligned number that renders without `FontFeature.tabularFigures()` (a search
for `tabularFigures` finds only `AppText.tabular`; every place that matters was checked).

```dart
// lib/features/usage/usage_screen.dart:270 — current (Usage → Spend by day: the dollar labels stacked on the chart's left axis)
                  : Text(formatUsd(v), style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
```

```dart
// lib/features/projects/projects_screen.dart:244 — current (project budget under its progress bar; changes as bots spend)
              Text('${formatUsd(p.spentUsd)} / ${formatUsd(budget)}'),
```

```dart
// lib/features/board/board_screen.dart:386 — current (task count in each board column header; changes as tasks move)
                  Text('${tasks.length}', style: context.textTheme.bodySmall),
```

```dart
// lib/features/auth/sign_in_screen.dart:385 — current ("Send again in {seconds}s" countdown, ticks every second)
              child: Text(
                _resendIn > 0 ? l10n.resendLinkIn(_resendIn) : l10n.resendLink,
              ),
```

```dart
// lib/ui/floating_tab_chrome.dart:215 — current (Inbox badge on the phone tab bar)
                    label: Text(spec.badge > 99 ? '99+' : '${spec.badge}'),
```

```dart
// lib/features/home/home_shell.dart:337 — current (Inbox badge on the tablet navigation rail, two lines)
            icon: Badge(isLabelVisible: d.path == '/inbox' && badge > 0, label: Text('$badge'), child: Icon(d.icon)),
            selectedIcon: Badge(isLabelVisible: d.path == '/inbox' && badge > 0, label: Text('$badge'), child: Icon(d.selectedIcon)),
```

```dart
// lib/features/workspaces/spaces.dart:154 — current (unread badge next to each workspace in the switcher)
                        if ((badges[o.id] ?? 0) > 0) Badge(label: Text('${badges[o.id]}')),
```

```dart
// lib/features/inbox/inbox_screen.dart:85 — current (Inbox filter chips; "Needs you (3)" counts down as items are handled)
                      label: Text(label(f)),
```

## The fix

The article's fix: turn on `FontFeature.tabularFigures()` in the `TextStyle` of numbers that
change or line up, and only there (it looks loose inside ordinary sentences, so it's never a
global setting). This codebase already holds that feature in one constant,
`AppText.tabular` (`static const List<FontFeature> tabular = [FontFeature.tabularFigures()];` in
`lib/theme/app_tokens.dart`); use it, and merge it into the existing style the way
`lib/ui/bot_activity.dart` (`CountPill`) does: `…?.copyWith(…, fontFeatures: AppText.tabular)`
when the text already has a theme style, `const TextStyle(fontFeatures: AppText.tabular)` when it
has none (it inherits everything else from the surrounding `DefaultTextStyle`, such as the
badge's or chip's own text style).

```dart
// lib/features/usage/usage_screen.dart:270 — target
                  : Text(formatUsd(v), style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: AppText.tabular)),
```

```dart
// lib/features/projects/projects_screen.dart:244 — target
              Text('${formatUsd(p.spentUsd)} / ${formatUsd(budget)}', style: const TextStyle(fontFeatures: AppText.tabular)),
```

```dart
// lib/features/board/board_screen.dart:386 — target
                  Text('${tasks.length}', style: context.textTheme.bodySmall?.copyWith(fontFeatures: AppText.tabular)),
```

```dart
// lib/features/auth/sign_in_screen.dart:385 — target
              child: Text(
                _resendIn > 0 ? l10n.resendLinkIn(_resendIn) : l10n.resendLink,
                style: const TextStyle(fontFeatures: AppText.tabular),
              ),
```

```dart
// lib/ui/floating_tab_chrome.dart:215 — target
                    label: Text(spec.badge > 99 ? '99+' : '${spec.badge}', style: const TextStyle(fontFeatures: AppText.tabular)),
```

```dart
// lib/features/home/home_shell.dart:337 — target
            icon: Badge(isLabelVisible: d.path == '/inbox' && badge > 0, label: Text('$badge', style: const TextStyle(fontFeatures: AppText.tabular)), child: Icon(d.icon)),
            selectedIcon: Badge(isLabelVisible: d.path == '/inbox' && badge > 0, label: Text('$badge', style: const TextStyle(fontFeatures: AppText.tabular)), child: Icon(d.selectedIcon)),
```

```dart
// lib/features/workspaces/spaces.dart:154 — target
                        if ((badges[o.id] ?? 0) > 0) Badge(label: Text('${badges[o.id]}', style: const TextStyle(fontFeatures: AppText.tabular))),
```

```dart
// lib/features/inbox/inbox_screen.dart:85 — target
                      label: Text(label(f), style: const TextStyle(fontFeatures: AppText.tabular)),
```

## Steps

Line numbers are from when this plan was written. If a file has shifted since (for example
new imports were added at the top), find each line by its quoted text; only a change in the
quoted text itself is a reason to stop.

Edit by hand. Never run `dart format` on any of these files.

1. `lib/features/usage/usage_screen.dart` line 270: replace
   `context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant))` with
   `context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: AppText.tabular))`
   on that line only (the same style on line 282 and line 332 stays as it is). The file already
   imports `app_tokens.dart`.
2. `lib/features/projects/projects_screen.dart` line 244: replace the line with the target. The
   file already imports `app_tokens.dart`.
3. `lib/features/board/board_screen.dart` line 386: replace
   `style: context.textTheme.bodySmall),` with
   `style: context.textTheme.bodySmall?.copyWith(fontFeatures: AppText.tabular)),` on that line
   only. The file already imports `app_tokens.dart`.
4. `lib/features/auth/sign_in_screen.dart` line 386: directly below
   `                _resendIn > 0 ? l10n.resendLinkIn(_resendIn) : l10n.resendLink,` insert
   `                style: const TextStyle(fontFeatures: AppText.tabular),`. The file already
   imports `app_tokens.dart`.
5. `lib/ui/floating_tab_chrome.dart`:
   a. Add `import '../theme/app_tokens.dart';` directly below the line
      `import '../theme/app_colors.dart';`.
   b. Line 215: replace the line with the target.
6. `lib/features/home/home_shell.dart` lines 337 and 338: replace both lines with the two target
   lines. The file already imports `app_tokens.dart`.
7. `lib/features/workspaces/spaces.dart` line 154: replace the line with the target. The file
   already imports `app_tokens.dart`.
8. `lib/features/inbox/inbox_screen.dart` line 85: replace the line with the target. The file
   already imports `app_tokens.dart`.
9. From `client/`, run
   `flutter test test/app_test.dart test/design_test.dart test/projects_test.dart test/board_test.dart test/inbox_feed_test.dart test/navigation_test.dart test/sidebar_test.dart test/spaces_test.dart test/responsive_test.dart test/phone_layout_test.dart`.
   All must pass. No test needs a new expectation: tabular figures change digit widths, not text.

## Check it

- `dart analyze lib/features/usage/usage_screen.dart lib/features/projects/projects_screen.dart lib/features/board/board_screen.dart lib/features/auth/sign_in_screen.dart lib/ui/floating_tab_chrome.dart lib/features/home/home_shell.dart lib/features/workspaces/spaces.dart lib/features/inbox/inbox_screen.dart` reports no issues.
- `grep -c "labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: AppText.tabular)" lib/features/usage/usage_screen.dart` → 1
- `grep -c "AppText.tabular" lib/features/projects/projects_screen.dart` → 1
- `grep -c "bodySmall?.copyWith(fontFeatures: AppText.tabular)" lib/features/board/board_screen.dart` → 1
- `grep -c "AppText.tabular" lib/features/auth/sign_in_screen.dart` → 1
- `grep -c "AppText.tabular" lib/ui/floating_tab_chrome.dart` → 1
- `grep -c "theme/app_tokens.dart" lib/ui/floating_tab_chrome.dart` → 1
- `grep -c "AppText.tabular" lib/features/home/home_shell.dart` → 2
- `grep -c "AppText.tabular" lib/features/workspaces/spaces.dart` → 1
- `grep -c "label: Text(label(f), style: const TextStyle(fontFeatures: AppText.tabular))" lib/features/inbox/inbox_screen.dart` → 1
- The `flutter test` run in step 9 passes.

## Don't touch

- `lib/theme/app_tokens.dart` and the app theme: tabular figures are per number, never global.
- Places that already use `AppText.tabular` (`CountPill`, `SectionHeader` counts, Usage, Billing,
  Admin and Settings totals, the call timers, timeline, tool durations).
- Numbers inside sentences (subtitles like "3 members · 2 bots", snackbars, "Step 2 of 5"): the
  rule says to leave those alone.
- The Usage chart's bottom (day) labels, its tooltip and the token labels in the By bot bars:
  they don't change in place or line up in a column.
- How any number is formatted (separators, currency): out of scope here; keep each text argument
  as it is.
- Never run `dart format` on existing files or directories. No git commands (others commit in
  this shared tree).
- No new dependencies. No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on
  since this plan was written). One exception: if a quoted line's text argument differs only in
  how the number inside it is formatted (for example `formatUsd(v)` now reads
  `formatUsd(v, context.l10n.localeName)`, or `'${tasks.length}'` now reads
  `tasks.length.humanizedCount(context.l10n.localeName)`), keep that text argument exactly as it
  is now and make only this plan's style change.
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to
open to see it. Not a list of files, the steps already have those. For example: counters,
badges and the sign-in countdown no longer wobble as their digits change, and the Usage chart's
dollar labels line up; request a sign-in code and watch "Send again in 59s" count down.
