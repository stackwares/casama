# Fix: Tapping a half-hidden gallery filter chip leaves it cut off

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/tab-visibility
- **Needs new dependency**: none

## Why

When someone taps a filter chip that's only half visible in a sideways row, the chip should slide fully into view. Every other chip row in the app already does this. The type filter in Settings → Gallery doesn't, whether the chip is tapped or picked through a section's "See all" button.

## Where

All paths are relative to `client/`. A full sweep of the horizontal rows with a selected item:
- Already handled (they use `RevealWhenSelected`): template picker, theme, background, quick ask, inbox, board, integrations, skill catalog.
- The computer screen and admin use Material's `TabBar`, which handles this itself.
- The chat, live view and computer rows that remain hold no selected item.

One custom row is missing it:

```dart
// lib/features/settings/gallery_screen.dart:276 — current (inside _typeChips)
          for (final type in [null, ..._types]) ...[
            if (type != null) const SizedBox(width: AppSpace.xs),
            ChoiceChip(
              key: Key('galleryType-${type ?? 'all'}'),
              showCheckmark: false,
              selected: _type == type,
              onSelected: (_) => _showType(type),
              label: Text.rich(
                ...
              ),
            ),
          ],
```

The selection handler does no scrolling:

```dart
// lib/features/settings/gallery_screen.dart:108 — current
  void _showType(String? type) {
    setState(() {
      _type = type;
    });
  }
```

`_showType` is also called from each section's "See all" button (line 368), so the chip must come into view whenever the selection changes, not only when it's tapped.

## The fix

The article: when a custom tab becomes selected, scroll it fully into view, centered (`alignment: 0.5`, 200 ms, `Curves.easeInOut`), using each tab's context and `ensureVisible`. Do the same on first show and whenever the selection changes. This app already wraps that in `lib/ui/revealable.dart`'s sibling, `lib/ui/reveal_when_selected.dart` (`RevealWhenSelected(selected:, child:)`):
- It calls the row's own `position.ensureVisible(item, alignment: 0.5, duration: 200 ms, curve: Curves.easeInOut)` after layout whenever `selected` turns true.
- It does the same for an item that's already selected when the row first appears.
- It scrolls only the row, never the page.

Wrap each chip. Imitate `lib/features/inbox/inbox_screen.dart:91`:

```dart
RevealWhenSelected(selected: _filter == f, child: ChoiceChip(...)),
```

Target:

```dart
// target
          for (final type in [null, ..._types]) ...[
            if (type != null) const SizedBox(width: AppSpace.xs),
            RevealWhenSelected(
              selected: _type == type,
              child: ChoiceChip(
                key: Key('galleryType-${type ?? 'all'}'),
                showCheckmark: false,
                selected: _type == type,
                onSelected: (_) => _showType(type),
                label: Text.rich(
                  // unchanged
                ),
              ),
            ),
          ],
```

## Steps

1. In `lib/features/settings/gallery_screen.dart`, add `import '../../ui/reveal_when_selected.dart';` to the `../../ui/` import group, after `import '../../ui/page.dart';`. Keep it alphabetical.
2. In `_typeChips`, wrap the `ChoiceChip(...)` (lines 278–299) in `RevealWhenSelected(selected: _type == type, child: ChoiceChip(...))`. Leave the `ChoiceChip`'s key and arguments unchanged.
3. Leave `_showType` unchanged. `RevealWhenSelected` reacts to `selected` changing, which covers taps and "See all".
4. Don't run `dart format` on this existing file. Match the indentation by hand. If `shader-mask.md` was applied first and the scroll view is wrapped in `EdgeFade`, that's fine: the chips are inside it either way.

## Check it

- From `client/`, `flutter analyze lib/features/settings/gallery_screen.dart` reports no issues.
- `grep -c "RevealWhenSelected(" lib/features/settings/gallery_screen.dart` → 1.
- `grep -c "import '../../ui/reveal_when_selected.dart';" lib/features/settings/gallery_screen.dart` → 1.
- `flutter test test/gallery_test.dart test/design_test.dart test/reveal_when_selected_test.dart` passes. `design_test.dart:406` taps `galleryType-theme`.

## Don't touch

- `lib/ui/reveal_when_selected.dart`.
- The other chip rows, which already have it, and Material `TabBar`s.
- `_showType` and the gallery's filtering logic.
- No new dependencies.
- No refactors, renames or cleanups beyond the fix.

## Repo rules

- Never `git add -A` or `git add .`. Stage by path only. **Don't commit**; the developer commits.
- Only run `dart format` on new files.

## STOP if

- The code at the location doesn't match the excerpts (the codebase moved on).
- The fix seems to need `Scrollable.ensureVisible` directly. Don't use it: it also scrolls the page around the row. Use `RevealWhenSelected`.
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, that tapping a half-hidden gallery filter chip, or a section's "See all", now slides that chip fully into view, centered. Point them to Settings → Gallery on a phone-width window.
