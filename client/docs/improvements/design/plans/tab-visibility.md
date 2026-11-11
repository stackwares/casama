# Fix: A tapped chip at the edge of a row stays half hidden

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/tab-visibility
- **Needs new dependency**: none (`ScrollPosition.ensureVisible` is in Flutter)

## Why

In a row of tabs or chips, tapping one that's only half visible should scroll it fully into view.
Casama's filter and category rows are custom-built (a horizontal list of `ChoiceChip`s), so
nothing does this: tap the half-hidden "Pages" filter in the Inbox or a category at the edge of the
Apps catalog and it stays cut off, so people can't see what they picked or what comes next.
Material's `TabBar` already does it, which is why the admin and computer tabs are fine.

## Where

Eight custom horizontal rows whose items track a selected value and whose selection handler
scrolls nothing (there is no `ensureVisible` in any of them; the only `ensureVisible` in the app is
in the chat search, `lib/features/chat/chat_screen.dart:261`, unrelated). The two scrollable
`TabBar`s (`lib/features/admin/admin_screen.dart:47`, `lib/features/computer/computer_screen.dart:346`)
already scroll the tapped tab into view and are not touched. All code below was read from the
files as they are now; line numbers are where each snippet starts, and `...` marks lines left out.

```dart
// lib/features/inbox/inbox_screen.dart:81 — current (All · Needs you · Briefs · Pages;
// the filter can also change from the route, in didUpdateWidget at line 52)
                  for (final f in InboxFilter.values)
                    ChoiceChip(
                      key: Key('inboxFilter-${f.name}'),
                      showCheckmark: false,
                      label: Text(label(f)),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
```

```dart
// lib/features/board/board_screen.dart:131 — current (All · Mine · Bots; a sideways row on
// phones, a Wrap on wider windows)
            for (final (o, label) in [(_Owner.all, l10n.filterAll), (_Owner.mine, l10n.filterMine), (_Owner.bots, l10n.filterBots)])
              ChoiceChip(key: Key('filter-${o.name}'), label: Text(label), selected: _owner == o, onSelected: (_) => setState(() => _owner = o)),
```

```dart
// lib/features/settings/theme_screen.dart:121 — current (color families)
              for (final f in [null, ...SchemeFamily.values])
                Padding(
                  padding: const EdgeInsets.only(right: AppSpace.xs),
                  child: ChoiceChip(
                    key: Key('family-${f?.name ?? 'all'}'),
                    selected: _family == f,
                    showCheckmark: false,
                    label: Text(
                      f == null
                          ? l10n.familyAll
                          : schemeFamilyLabel(context, f),
                    ),
                    onSelected: (_) => setState(() => _family = f),
                  ),
                ),
```

```dart
// lib/features/settings/background_screen.dart:50 — current (wallpaper patterns; the saved
// pattern can be any of them when the page opens)
            itemBuilder: (context, i) {
              final p = WallpaperPattern.values[i];
              return _Swatch(
                key: Key('pattern-${p.name}'),
                label: p.label,
                selected: spec.pattern == p,
                onTap: () => set(
                  ...
                ),
                child: Wallpaper(
                  ...
                ),
              );
            },
```

```dart
// lib/features/bots/template_picker.dart:246 — current (persona gallery categories)
                for (final c in [null, ...categories])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.xs),
                    child: ChoiceChip(
                      key: Key('personaCategory-${c?.name ?? 'all'}'),
                      showCheckmark: false,
                      selected: _category == c,
                      label: Text(c == null ? l10n.familyAll : _categoryLabel(context, c)),
                      onSelected: (_) => setState(() => _category = c),
                    ),
                  ),
```

```dart
// lib/features/integrations/integrations_screen.dart:207 — current (app categories)
              for (final c in [null, ...categories])
                Padding(
                  padding: const EdgeInsets.only(right: AppSpace.xs),
                  child: ChoiceChip(
                    key: Key('appCategory-${c?.name ?? 'all'}'),
                    showCheckmark: false,
                    selected: _category == c,
                    label: Text(c == null ? l10n.allApps : appCategoryLabel(context, c)),
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ),
```

```dart
// lib/features/skills/skill_catalog_screen.dart:154 — current (skill categories)
              for (final c in [null, ...categories])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
                  child: ChoiceChip(
                    key: Key('category-${c ?? 'all'}'),
                    showCheckmark: false,
                    avatar: c == null
                        ? null
                        : Icon(
                            ...
                          ),
                    selected: _category == c,
                    label: Text(
                      c == null ? l10n.all : skillCategoryLabel(context, c),
                    ),
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ),
```

```dart
// lib/features/quick_ask/quick_ask_screen.dart:132 — current (which bot to ask)
              itemBuilder: (context, i) {
                final b = bots[i];
                return ChoiceChip(
                  selected: b.id == _botId,
                  showCheckmark: false,
                  avatar: BotAvatar(name: b.name, avatar: b.avatarUrl, size: 22),
                  label: Text(b.name),
                  onSelected: (_) => setState(() => _botId = b.id),
                );
              },
```

**Other fixes that touch the same code.** Two companion fixes may already have run on these
files. If so, the code around these items differs from the excerpts in exactly these ways, which
are expected: keep them as they are, and line numbers may be a few lines off.
- "Make horizontal lists feel scrollable": the scroll view holding each row is wrapped as
  `EdgeFade(child: ListView(` / `EdgeFade(child: SingleChildScrollView(` … `)),`.
- "Let horizontal lists reach the screen edges": some of these lists gained a
  `padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),` (or `AppSpace.lg`) line,
  their `SizedBox(` is wrapped as `PageBleed(child: SizedBox(` … `)),`, and in
  `integrations_screen.dart` / `skill_catalog_screen.dart` the `_browse` method returns a list
  (`return [` … `];`) instead of a `Column`.
- "Use tabular figures for changing numbers": the Inbox chip's label line (`inbox_screen.dart:85`)
  reads `label: Text(label(f), style: const TextStyle(fontFeatures: AppText.tabular)),`.
None of them changes the lines this plan edits. Other fixes elsewhere in these files can also
shift line numbers; find each spot by its quoted text.

## The fix

The article's fix: when a tab becomes the selected one (from a tap or from the parent), call
`ensureVisible` on it with `alignment: 0.5` so it lands fully visible and centered, over 200 ms
with `Curves.easeInOut`; and once the strip is first laid out, do the same for the tab that's
already selected. The article keeps a `GlobalKey` per tab in each strip; here that logic lives in
one small wrapper, `RevealWhenSelected`, that each item wraps itself in and that uses its own
context the way the article uses the key's `currentContext`. Three adaptations:

1. **Only the row scrolls.** `Scrollable.ensureVisible` scrolls *every* scroll view around the
   item, so on Settings → Color scheme or Apps the whole page would also jump to center the chip
   row vertically. The wrapper calls `ensureVisible` on the row's own `ScrollPosition` instead.
2. **The first-layout reveal happens once per row.** Lazy lists build items as they come near
   while the person scrolls; a selected item built then must not pull the row back to it. So the
   wrapper reveals on creation only while the row has never been laid out.
3. **Reduced motion is respected**: the 200 ms becomes `AppMotion.of(context, ...)`, which is zero
   when the system asks for less motion (then the row jumps instead of animating).

Outside a horizontal scroll view (the Tasks filters on a wide window sit in a `Wrap`) the wrapper
does nothing.

New file `lib/ui/reveal_when_selected.dart`, exactly:

```dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// A chip, tab or swatch in a horizontal row that scrolls itself fully into view, centered, when it
/// becomes the selected one, whether tapped or picked from elsewhere. An item already selected when
/// the row first appears is brought into view too. Only the row scrolls, never the page around it;
/// outside a horizontal scroll view (a wrapping row on a wide window) it does nothing.
class RevealWhenSelected extends StatefulWidget {
  const RevealWhenSelected({super.key, required this.selected, required this.child});

  /// Whether this item is the row's current choice.
  final bool selected;
  final Widget child;

  @override
  State<RevealWhenSelected> createState() => _RevealWhenSelectedState();
}

class _RevealWhenSelectedState extends State<RevealWhenSelected> {
  @override
  void initState() {
    super.initState();
    // Only while the row lays out for the first time: an item rebuilt as the person scrolls (lazy
    // lists build items as they come near) must not pull the row back to it.
    final row = context.findAncestorStateOfType<ScrollableState>();
    if (widget.selected && row != null && !row.position.hasContentDimensions) _revealAfterLayout();
  }

  @override
  void didUpdateWidget(RevealWhenSelected oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) _revealAfterLayout();
  }

  void _revealAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final row = context.findAncestorStateOfType<ScrollableState>();
      final item = context.findRenderObject();
      if (row == null || row.position.axis != Axis.horizontal || item == null || !item.attached) return;
      // The row's own position, not Scrollable.ensureVisible: that one also scrolls every scroll
      // view around the row, so the page would jump to center the row vertically.
      row.position.ensureVisible(
        item,
        alignment: 0.5,
        duration: AppMotion.of(context, const Duration(milliseconds: 200)),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

Each item wraps itself, passing the same expression it already uses for `selected:`. The item's
`key` stays on the item (tests find chips by these keys). Write the wrapper on the item's opening
line so nothing inside needs re-indenting, and add one `)` to the item's closing line:

```dart
// target, for example in theme_screen.dart
                Padding(
                  padding: const EdgeInsets.only(right: AppSpace.xs),
                  child: RevealWhenSelected(selected: _family == f, child: ChoiceChip(
                    key: Key('family-${f?.name ?? 'all'}'),
                    selected: _family == f,
                    ...
                    onSelected: (_) => setState(() => _family = f),
                  )),
                ),
```

Wrap the chip itself, not the `Padding` around it, so the chip (not chip plus gap) is what gets
centered.

## Steps

1. Create `lib/ui/reveal_when_selected.dart` with exactly the code in "The fix". Then run
   `dart format -l 200 lib/ui/reveal_when_selected.dart` (only on this new file).

2. In each file below, add the import next to the file's other `'../../ui/...'` imports:
   `import '../../ui/reveal_when_selected.dart';`
   Files: `lib/features/inbox/inbox_screen.dart`, `lib/features/board/board_screen.dart`,
   `lib/features/settings/theme_screen.dart`, `lib/features/settings/background_screen.dart`,
   `lib/features/bots/template_picker.dart`, `lib/features/integrations/integrations_screen.dart`,
   `lib/features/skills/skill_catalog_screen.dart`, `lib/features/quick_ask/quick_ask_screen.dart`.

3. `lib/features/inbox/inbox_screen.dart`:
   - line 82 `                    ChoiceChip(` becomes
     `                    RevealWhenSelected(selected: _filter == f, child: ChoiceChip(`
   - line 88, the `                    ),` right after `onSelected: (_) => setState(() => _filter = f),`,
     becomes `                    )),`
   - Leave `didUpdateWidget` (line 52) alone: when the route changes the filter, the chip's
     `selected` flips and the wrapper scrolls it into view by itself.

4. `lib/features/board/board_screen.dart`, line 132, the whole line
   `              ChoiceChip(key: Key('filter-${o.name}'), label: Text(label), selected: _owner == o, onSelected: (_) => setState(() => _owner = o)),`
   becomes
   `              RevealWhenSelected(selected: _owner == o, child: ChoiceChip(key: Key('filter-${o.name}'), label: Text(label), selected: _owner == o, onSelected: (_) => setState(() => _owner = o))),`
   Leave the `DropdownButton` for priority as it is: it opens a menu, it isn't a tab.

5. `lib/features/settings/theme_screen.dart`:
   - line 124 `                  child: ChoiceChip(` becomes
     `                  child: RevealWhenSelected(selected: _family == f, child: ChoiceChip(`
   - line 134, the `                  ),` right after `onSelected: (_) => setState(() => _family = f),`,
     becomes `                  )),`

6. `lib/features/settings/background_screen.dart`:
   - line 52 `              return _Swatch(` becomes
     `              return RevealWhenSelected(selected: spec.pattern == p, child: _Swatch(`
   - line 69, the `              );` right before `            },` (the end of `itemBuilder`),
     becomes `              ));`
   - Only the pattern row: the colors below it are a `Wrap` and don't scroll.

7. `lib/features/bots/template_picker.dart`:
   - line 249 `                    child: ChoiceChip(` becomes
     `                    child: RevealWhenSelected(selected: _category == c, child: ChoiceChip(`
   - line 255, the `                    ),` right after `onSelected: (_) => setState(() => _category = c),`,
     becomes `                    )),`

8. `lib/features/integrations/integrations_screen.dart`:
   - line 210 `                  child: ChoiceChip(` becomes
     `                  child: RevealWhenSelected(selected: _category == c, child: ChoiceChip(`
   - line 216, the `                  ),` right after `onSelected: (_) => setState(() => _category = c),`,
     becomes `                  )),`

9. `lib/features/skills/skill_catalog_screen.dart`:
   - line 157 `                  child: ChoiceChip(` becomes
     `                  child: RevealWhenSelected(selected: _category == c, child: ChoiceChip(`
   - line 172, the `                  ),` right after `onSelected: (_) => setState(() => _category = c),`,
     becomes `                  )),`

10. `lib/features/quick_ask/quick_ask_screen.dart`:
    - line 134 `                return ChoiceChip(` becomes
      `                return RevealWhenSelected(selected: b.id == _botId, child: ChoiceChip(`
    - line 140, the `                );` right after `onSelected: (_) => setState(() => _botId = b.id),`,
      becomes `                ));`

11. Create `test/reveal_when_selected_test.dart`:

    ```dart
    // A tapped tab in a horizontal row scrolls fully into view, and only the row scrolls.
    import 'package:flutter/material.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:casama_app/ui/reveal_when_selected.dart';

    class _Row extends StatefulWidget {
      const _Row({this.initial = 0});
      final int initial;

      @override
      State<_Row> createState() => _RowState();
    }

    class _RowState extends State<_Row> {
      late int _selected = widget.initial;

      @override
      Widget build(BuildContext context) => SizedBox(
        width: 250,
        height: 40,
        child: ListView(
          key: const Key('row'),
          scrollDirection: Axis.horizontal,
          children: [
            for (var i = 0; i < 10; i++)
              RevealWhenSelected(
                selected: i == _selected,
                child: GestureDetector(
                  key: Key('tab-$i'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _selected = i),
                  child: const SizedBox(width: 100, height: 40),
                ),
              ),
          ],
        ),
      );
    }

    // The row sits inside a vertical page, so a reveal that also scrolled the page would show.
    Widget _page(Widget row) => MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [const SizedBox(height: 300), Align(alignment: Alignment.topLeft, child: row), const SizedBox(height: 2000)],
        ),
      ),
    );

    void expectFullyInRow(WidgetTester tester, String tab) {
      final row = tester.getRect(find.byKey(const Key('row')));
      final rect = tester.getRect(find.byKey(Key(tab)));
      expect(rect.left, greaterThanOrEqualTo(row.left));
      expect(rect.right, lessThanOrEqualTo(row.right));
    }

    void main() {
      testWidgets('tapping a half-visible tab scrolls it fully into view, centered', (tester) async {
        await tester.pumpWidget(_page(const _Row()));
        // Tab 2 spans 200 to 300 in a 250-wide row: only its first half shows.
        await tester.tapAt(tester.getTopLeft(find.byKey(const Key('tab-2'))) + const Offset(10, 10));
        await tester.pumpAndSettle();
        expectFullyInRow(tester, 'tab-2');
        expect(tester.getCenter(find.byKey(const Key('tab-2'))).dx, moreOrLessEquals(tester.getCenter(find.byKey(const Key('row'))).dx));
      });

      testWidgets('only the row scrolls, not the page around it', (tester) async {
        await tester.pumpWidget(_page(const _Row()));
        await tester.tapAt(tester.getTopLeft(find.byKey(const Key('tab-2'))) + const Offset(10, 10));
        await tester.pumpAndSettle();
        final page = tester.state<ScrollableState>(find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down));
        expect(page.position.pixels, 0);
      });

      testWidgets('a tab already selected when the row appears is brought into view', (tester) async {
        await tester.pumpWidget(_page(const _Row(initial: 3)));
        await tester.pumpAndSettle();
        expectFullyInRow(tester, 'tab-3');
      });
    }
    ```

    Then run `dart format -l 200 test/reveal_when_selected_test.dart` (only on this new file).

12. Run, from `client/`:
    `flutter test test/reveal_when_selected_test.dart test/phone_layout_test.dart test/inbox_feed_test.dart test/tasks_phone_test.dart test/board_test.dart test/design_test.dart test/autonomy_test.dart test/desktop_context_test.dart test/advanced_connections_test.dart test/skill_library_test.dart`

## Check it

`dart analyze lib/ui/reveal_when_selected.dart test/reveal_when_selected_test.dart lib/features/inbox/inbox_screen.dart lib/features/board/board_screen.dart lib/features/settings/theme_screen.dart lib/features/settings/background_screen.dart lib/features/bots/template_picker.dart lib/features/integrations/integrations_screen.dart lib/features/skills/skill_catalog_screen.dart lib/features/quick_ask/quick_ask_screen.dart`
reports no issues.

Each grep below counts in one file:
- `grep -c "class RevealWhenSelected " lib/ui/reveal_when_selected.dart` → 1
- `grep -c "row.position.ensureVisible(" lib/ui/reveal_when_selected.dart` → 1
- `grep -c "RevealWhenSelected(selected: _filter == f, child: ChoiceChip(" lib/features/inbox/inbox_screen.dart` → 1
- `grep -c "RevealWhenSelected(selected: _owner == o, child: ChoiceChip(" lib/features/board/board_screen.dart` → 1
- `grep -c "RevealWhenSelected(selected: _family == f, child: ChoiceChip(" lib/features/settings/theme_screen.dart` → 1
- `grep -c "RevealWhenSelected(selected: spec.pattern == p, child: _Swatch(" lib/features/settings/background_screen.dart` → 1
- `grep -c "RevealWhenSelected(selected: _category == c, child: ChoiceChip(" lib/features/bots/template_picker.dart` → 1
- `grep -c "RevealWhenSelected(selected: _category == c, child: ChoiceChip(" lib/features/integrations/integrations_screen.dart` → 1
- `grep -c "RevealWhenSelected(selected: _category == c, child: ChoiceChip(" lib/features/skills/skill_catalog_screen.dart` → 1
- `grep -c "RevealWhenSelected(selected: b.id == _botId, child: ChoiceChip(" lib/features/quick_ask/quick_ask_screen.dart` → 1

The `flutter test` run in step 12 passes.

## Don't touch

- Material `TabBar`s (`lib/features/admin/admin_screen.dart`, `lib/features/computer/computer_screen.dart`):
  they already scroll the tapped tab into view.
- Rows without a selection: files waiting to be sent in the chat composer, the live view's
  Copy / Paste / Screenshot row, the folder path in the Files tab, the popular apps cards, and the
  Tasks board columns. Nothing in them is "picked", so there's nothing to reveal.
- The chip styles, keys, `onSelected` handlers and spacing: only the wrapper is added.
- The chat search's `Scrollable.ensureVisible` (`lib/features/chat/chat_screen.dart:261`): different feature.
- Edge fades and moving list padding to the screen edge are separate fixes (see "Other fixes that
  touch the same code"); don't do them here.
- No new strings: nothing user-facing changes, so `lib/l10n/app_en.arb` stays as is.
- If `lib/ui/glass/` exists when you run this, check whether any widget named above moved there;
  if it did, STOP and report instead of editing the old location.
- Never run `dart format` on existing files or on a directory, and run no git commands (the tree is
  shared; others commit).
- No new dependencies.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on
  since this plan was written), other than the differences listed under "Other fixes that touch
  the same code".
- The fix seems to require touching something in "Don't touch".
- A test in step 12 fails because of this change (a test that taps a chip and then expects
  something without letting the 200 ms scroll finish is a real failure to report, not to patch).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to
open to see it. For example: tapping a chip that's half off the edge of a filter or category row
now slides it fully into view, centered, without moving the page; on a narrow phone, open the
Inbox and tap the partly hidden last filter.
