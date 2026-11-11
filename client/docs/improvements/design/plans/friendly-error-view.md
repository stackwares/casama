# Fix: A screen that fails to build shows a red error (debug) or an empty grey box (release)

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/friendly-error-view
- **Needs new dependency**: none

## Why

When a widget throws while it builds, Flutter swaps it for its error widget: a red screen of text in debug and a plain grey box in release. In Casama, people in the release app would see a grey hole where a card, a chat or a whole screen should be, with no word about what happened. The app should show a calm "Something went wrong" in its own colors, sized to the space that broke. Debug builds should still show what broke, and a hidden long press should copy the details for a bug report.

## Where

Nothing sets `ErrorWidget.builder` anywhere in `lib/` (`grep -rn "ErrorWidget" lib` finds nothing). The one place to set it is app startup:

```dart
// lib/main.dart:55-61 — current
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Desktop: a window sized for the sidebar, chat and computer panel, or where it was last.
  await setUpDesktopWindow();
  // Draw at once; connecting happens behind the startup gate (never block runApp on the network).
  await Telemetry.run(const StartupGate(config: AppConfig.fromEnvironment));
}
```

Error reporting needs no change. Flutter reports a build error through `FlutterError.reportError` before it calls `ErrorWidget.builder`, and `lib/core/telemetry.dart` already captures those (`captureFlutterErrors` for PostHog at lines 77-81, `SentryFlutter.init` at line 85).

## The fix

The article's fix is one line in `main` before `runApp`, `ErrorWidget.builder = (details) => FriendlyErrorView(details: details);`, plus the article's `FriendlyErrorView`:

- A friendly "Something went wrong" in theme colors in release, with no technical details.
- In debug, the same view plus the exception and stack trace (it replaces Flutter's red screen in debug too).
- A long press anywhere copies the details, with no visible button.
- A full layout when there's room, an icon-only badge in small slots.

It is applied unchanged except for three adaptations to this codebase:

1. Dart's dot shorthands (`.min`, `.center`) are spelled out, because this codebase doesn't use them.
2. The two lines of text come from `app_en.arb` when an `AppLocalizations` ancestor exists. The view can replace a widget anywhere, including above `MaterialApp` (the startup gate, the app root), where there are no localizations. There it falls back to the same English words, which is safe because the app ships in English only.
3. Text direction comes from the surrounding `Directionality` when there is one, otherwise left-to-right as in the article.

Colors come from `Theme.of(context).colorScheme`, as in the article. Inside the app that is Casama's scheme. Above `MaterialApp`, `Theme.of` returns Flutter's default theme, so the view still renders. `context.colorScheme` is the same call; `Theme.of` is used so this file needs no app imports for colors.

New file `lib/ui/friendly_error_view.dart`, exactly:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';

/// Friendly replacement for Flutter's red error screen (debug) and empty grey box (release),
/// installed with [ErrorWidget.builder] in main.dart. Release builds show no technical details;
/// debug builds add the exception and stack trace. A long press anywhere copies the details to the
/// clipboard (no visible button, so people never notice it; handy on a production build).
///
/// Adapts to the space the broken widget occupied: a full layout when there is room, an icon-only
/// badge inside small slots. It can land anywhere in the tree, even above MaterialApp, so it brings
/// its own Directionality and Material, takes colors from the nearest Theme (Flutter's default
/// theme when there is none) and falls back to English where there are no localizations. The error
/// itself is already reported through FlutterError.onError (see telemetry.dart).
class FriendlyErrorView extends StatefulWidget {
  const FriendlyErrorView({super.key, required this.details});

  final FlutterErrorDetails details;

  @override
  State<FriendlyErrorView> createState() => _FriendlyErrorViewState();
}

class _FriendlyErrorViewState extends State<FriendlyErrorView> {
  Timer? _timer;
  bool _copied = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    HapticFeedback.mediumImpact();

    await Clipboard.setData(ClipboardData(text: '${widget.details.exceptionAsString()}\n\n${widget.details.stack}'));

    if (!mounted) return;

    setState(() => _copied = true);

    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    // app_en.arb's words where localizations exist; the same English words anywhere else.
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final title = l10n?.somethingWentWrong ?? 'Something went wrong';
    final hint = l10n?.errorViewHint ?? 'Restarting the app should fix it.';

    // The view can land anywhere in the tree, including where no Material or Directionality
    // ancestor exists, so it provides its own. The transparent Material also prevents the yellow
    // "missing Material" text underlines.
    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          container: true,
          label: '$title. $hint',
          child: ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: _copy,
              child: LayoutBuilder(
                builder: (context, c) {
                  final bool full = c.maxHeight.isFinite && c.maxHeight >= 320 && c.maxWidth.isFinite && c.maxWidth >= 300;

                  // Only fill bounded axes; under unbounded constraints (lists, FittedBox) the view
                  // sizes to its content.
                  return Container(
                    width: c.hasBoundedWidth ? c.maxWidth : null,
                    height: c.hasBoundedHeight ? c.maxHeight : null,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(full ? 0 : 28),
                    ),
                    child: full
                        ? _FullView(details: widget.details, copied: _copied, title: title, hint: hint)
                        : _CompactView(details: widget.details, copied: _copied),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullView extends StatelessWidget {
  const _FullView({required this.details, required this.copied, required this.title, required this.hint});

  final FlutterErrorDetails details;
  final bool copied;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    final Widget header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Badge(size: 104, copied: copied),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: tt.titleLarge?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: tt.bodyMedium?.copyWith(color: cs.onPrimaryContainer.withValues(alpha: 0.75)),
        ),
      ],
    );

    // Centered while the content fits, scrollable once it doesn't: the sliver forces the child to at
    // least viewport height, and the centered column simply grows past it when the debug stack
    // trace is long.
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            // Clear the status bar and home indicator; the view has no Scaffold or SafeArea above it
            // (and possibly no MediaQuery).
            padding: EdgeInsets.fromLTRB(
              32,
              (MediaQuery.maybePaddingOf(context)?.top ?? 0) + 32,
              32,
              (MediaQuery.maybePaddingOf(context)?.bottom ?? 0) + 32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                header,
                if (kDebugMode) ...[
                  const SizedBox(height: 32),
                  _DebugText('${details.exceptionAsString()}\n\n${details.stack}'),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactView extends StatelessWidget {
  const _CompactView({required this.details, required this.copied});

  final FlutterErrorDetails details;
  final bool copied;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Badge(size: 48, copied: copied),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: 240,
                  child: _DebugText(details.exceptionAsString(), maxLines: 2, textAlign: TextAlign.center),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The badge briefly swaps its "!" for a check after the hidden long-press copy gesture, so regular
/// users never see a hint.
class _Badge extends StatelessWidget {
  const _Badge({required this.size, required this.copied});

  final double size;
  final bool copied;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: cs.primary,
        // A soft flower built with the SDK's StarBorder, so this file needs no shape package.
        shape: const StarBorder(points: 12, innerRadiusRatio: 0.8, pointRounding: 0.7, valleyRounding: 0.3),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          copied ? Icons.check_rounded : Icons.priority_high_rounded,
          key: ValueKey<bool>(copied),
          color: cs.onPrimary,
          size: size * 0.4,
        ),
      ),
    );
  }
}

/// Exception text shown only in debug builds.
class _DebugText extends StatelessWidget {
  const _DebugText(this.text, {this.maxLines, this.textAlign});

  final String text;
  final int? maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Text(
      text,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: maxLines == null ? TextOverflow.fade : TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'monospace',
        fontFamilyFallback: const ['Menlo', 'Courier'],
        fontSize: 12,
        color: cs.onPrimaryContainer.withValues(alpha: 0.6),
      ),
    );
  }
}
```

`lib/main.dart`, target for `main()`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // A widget that fails to build shows a calm "Something went wrong" in the app's colors instead of
  // Flutter's red screen (debug) or an empty grey box (release). Telemetry still reports the error.
  ErrorWidget.builder = (details) => FriendlyErrorView(details: details);
  // Desktop: a window sized for the sidebar, chat and computer panel, or where it was last.
  await setUpDesktopWindow();
  // Draw at once; connecting happens behind the startup gate (never block runApp on the network).
  await Telemetry.run(const StartupGate(config: AppConfig.fromEnvironment));
}
```

New string in `lib/l10n/app_en.arb` (the title reuses the existing `somethingWentWrong`):

```json
  "errorViewHint": "Restarting the app should fix it.",
```

## Steps

1. In `lib/l10n/app_en.arb`, add the line `  "errorViewHint": "Restarting the app should fix it.",` directly below the existing line `  "somethingWentWrong": "Something went wrong",` (line 13). Edit by hand.
2. Run `flutter gen-l10n` in `client/`.
3. Create `lib/ui/friendly_error_view.dart` with the exact content from "The fix", then run `dart format -l 200 lib/ui/friendly_error_view.dart`. That file only: never run `dart format` on any existing file or directory.
4. In `lib/main.dart`, add `import 'ui/friendly_error_view.dart';` as a new line among the imports at the top, for example directly below `import 'ui/glow_button.dart';`. Any position in the import block is fine; other changes may have added imports there.
5. In `lib/main.dart`, add the comment and the `ErrorWidget.builder = …` line from the target directly below `WidgetsFlutterBinding.ensureInitialized();` in `main()`. Leave the rest of `main()`, `bootstrap` and `StartupGate` unchanged.
6. Create `test/friendly_error_view_test.dart` with exactly this content, then run `dart format -l 200 test/friendly_error_view_test.dart`:

```dart
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/theme/app_theme.dart';
import 'package:casama_app/ui/friendly_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FlutterErrorDetails details() => FlutterErrorDetails(exception: StateError('boom'), stack: StackTrace.current);

  Widget app(Widget home) => MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  testWidgets('a broken screen says something went wrong, in the app colors', (tester) async {
    await tester.pumpWidget(app(FriendlyErrorView(details: details())));
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Restarting the app should fix it.'), findsOneWidget);
    // Tests run in debug, where the view also shows what broke.
    expect(find.textContaining('boom'), findsOneWidget);
    // The view's own box (the badge uses a ShapeDecoration, the box a BoxDecoration).
    final box = tester
        .widgetList<Container>(find.descendant(of: find.byType(FriendlyErrorView), matching: find.byType(Container)))
        .firstWhere((c) => c.decoration is BoxDecoration);
    expect((box.decoration! as BoxDecoration).color, AppTheme.light().colorScheme.primaryContainer);
  });

  testWidgets('a broken small slot shows only the badge', (tester) async {
    await tester.pumpWidget(app(Center(child: SizedBox(width: 60, height: 60, child: FriendlyErrorView(details: details())))));
    expect(find.text('Something went wrong'), findsNothing);
    expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
  });

  testWidgets('it works above the app too, in English', (tester) async {
    await tester.pumpWidget(FriendlyErrorView(details: details()));
    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('a long press copies the error, with no visible button', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(app(FriendlyErrorView(details: details())));
    await tester.longPress(find.byType(FriendlyErrorView));
    await tester.pump();
    expect(copied, contains('boom'));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
  });

  testWidgets('a widget that throws while building shows it', (tester) async {
    final original = ErrorWidget.builder;
    ErrorWidget.builder = (d) => FriendlyErrorView(details: d);
    try {
      await tester.pumpWidget(app(Builder(builder: (_) => throw StateError('boom'))));
      expect(tester.takeException(), isA<StateError>());
      expect(find.byType(FriendlyErrorView), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    } finally {
      // The test framework checks this right after the test body, before tear-downs run.
      ErrorWidget.builder = original;
    }
  });
}
```

7. Run `flutter test test/friendly_error_view_test.dart test/startup_test.dart test/phone_layout_test.dart` in `client/`.

## Check it

- `dart analyze lib/ui/friendly_error_view.dart lib/main.dart test/friendly_error_view_test.dart` reports no issues.
- `grep -c "ErrorWidget.builder = (details) => FriendlyErrorView(details: details);" lib/main.dart` → `1`
- `grep -c "import 'ui/friendly_error_view.dart';" lib/main.dart` → `1`
- `grep -c '"errorViewHint"' lib/l10n/app_en.arb` → `1`
- `grep -c "errorViewHint" lib/l10n/generated/app_localizations.dart` → at least `1` (proves `flutter gen-l10n` ran)
- `grep -c "class FriendlyErrorView" lib/ui/friendly_error_view.dart` → `1`
- The `flutter test` command in step 7 passes.

## Don't touch

- `lib/core/telemetry.dart`: errors are already reported through `FlutterError.onError` before `ErrorWidget.builder` runs. Reporting again from the view would double-count.
- `FlutterError.onError`, `PlatformDispatcher.instance.onError`: unchanged; this rule is only about what's drawn in place of a broken widget.
- `bootstrap()` and `StartupGate` in `lib/main.dart`: other changes may edit those parts. This plan only adds one import and two lines in `main()`.
- Screens' own error states (`AsyncView`, `FormNote` with `errorText`): those are for failed requests and stay as they are.
- No git commands (others commit in this tree). No `dart format` on existing files or folders. Keep every existing widget `Key`.
- No new dependencies. No refactors, renames or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written). Line numbers may have shifted because of other changes; only the quoted code has to match.
- `grep -rn "ErrorWidget.builder" lib` already finds a setter before you start (someone else installed one).
- The fix seems to require touching something in "Don't touch".
- A test in step 7 fails because of this change, or any check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different. A widget that fails to build now shows a calm "Something went wrong, restarting the app should fix it" in the app's own colors: full-size when a whole screen breaks, a small badge in tight spots. Debug builds add the exception and stack trace, and a long press copies them on any build. To see it, temporarily throw inside any screen's `build` in a debug run.
