# Fix: Gallery rows don't look scrollable

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/shader-mask
- **Needs new dependency**: none

## Why

A horizontal list doesn't always look scrollable, especially when the visible items just fit and none is cut in half. Every horizontal row in this app already fades its edges, except the two in Settings → Gallery: the type filter chips and the sideways "shelves" of cards. Fading their edges hints that there's more to see.

## Where

All paths are relative to `client/`. A full sweep of `lib/` for `scrollDirection: Axis.horizontal` found 16 horizontal scroll views. 14 are already wrapped in the app's `EdgeFade`. The 2 below are not, both in `lib/features/settings/gallery_screen.dart`:

```dart
// lib/features/settings/gallery_screen.dart:271 — current (inside _typeChips)
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: side),
      child: Row(
        children: [
          for (final type in [null, ..._types]) ...[
            ...
          ],
        ],
      ),
    );
```

```dart
// lib/features/settings/gallery_screen.dart:399 — current
  Widget _shelf(List<Widget> cards, double side) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsets.symmetric(horizontal: side),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, card) in cards.indexed) ...[
          if (i > 0) const SizedBox(width: _gap),
          card,
        ],
      ],
    ),
  );
```

`_shelf` is called at lines 348, 381 and 465, so this one fix covers every shelf.

## The fix

The article fades scroll views with a `ShaderMask` and an alpha-only `LinearGradient` (`blendMode: BlendMode.dstIn`), running left to right for horizontal lists. This app already has exactly that as a reusable widget: `lib/ui/edge_fade.dart` (`EdgeFade`). It is a `ShaderMask` with `BlendMode.dstIn` that fades each edge only while there's more to scroll that way, and it follows right-to-left layouts. Wrap each scroll view itself in `EdgeFade(child: ...)`. Imitate `lib/features/inbox/inbox_screen.dart:84`:

```dart
child: EdgeFade(child: SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  ...
)),
```

Targets:

```dart
// target — _typeChips
    return EdgeFade(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: side),
        child: Row(
          children: [
            // unchanged chip loop
          ],
        ),
      ),
    );
```

```dart
// target — _shelf
  Widget _shelf(List<Widget> cards, double side) => EdgeFade(
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: side),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, card) in cards.indexed) ...[
            if (i > 0) const SizedBox(width: _gap),
            card,
          ],
        ],
      ),
    ),
  );
```

## Steps

1. In `lib/features/settings/gallery_screen.dart`, add the import `import '../../ui/edge_fade.dart';` to the `../../ui/` import group, after `import '../../ui/app_card.dart';`. Keep the group alphabetical.
2. In `_typeChips` (line 271), change `return SingleChildScrollView(` to `return EdgeFade(child: SingleChildScrollView(`, and change the method's closing `);` (line 303) to `));`. Nothing inside the scroll view changes. If the plan in `tab-visibility.md` was applied first and the chips are now wrapped in `RevealWhenSelected`, that's fine: wrap the scroll view all the same.
3. In `_shelf` (line 399), change `=> SingleChildScrollView(` to `=> EdgeFade(child: SingleChildScrollView(`, and change its final `);` (line 411) to `));`.
4. Don't run `dart format` on this file. It is an existing file, and the repo formats only new files. Match the surrounding indentation by hand.

## Check it

- From `client/`, `flutter analyze lib/features/settings/gallery_screen.dart` reports no issues.
- `grep -c "EdgeFade(child: SingleChildScrollView" lib/features/settings/gallery_screen.dart` → 2.
- `grep -c "import '../../ui/edge_fade.dart';" lib/features/settings/gallery_screen.dart` → 1.
- `flutter test test/gallery_test.dart test/design_test.dart test/edge_fade_test.dart` passes.

## Don't touch

- The other 14 horizontal rows (template picker, theme, quick ask, inbox, chat, background, board, integrations, live view, computer, skill catalog). They already have `EdgeFade`.
- `lib/ui/edge_fade.dart` itself.
- The non-compact `_rows`/`_grid` layouts in the gallery. They don't scroll sideways.
- No new dependencies.
- No refactors, renames or cleanups beyond the fix.

## Repo rules

- Never `git add -A` or `git add .`; this tree is shared. If staging is ever needed, stage by path only. **Don't commit**; the developer commits.
- Only run `dart format` on new files, never on existing ones.

## STOP if

- The code at either location doesn't match the excerpts above (the codebase moved on).
- The fix seems to need a change to `lib/ui/edge_fade.dart`.
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, that the gallery's filter chips and card shelves now fade softly at the edge while there's more to scroll. Point them to Settings → Gallery on a phone-width window.
