# Fix: Sideways rows of chips and cards don't look scrollable

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/shader-mask
- **Needs new dependency**: none (`ShaderMask` and `LinearGradient` are in Flutter)

## Why

A horizontal list doesn't always say it scrolls, especially when the visible items happen to end
right at the edge and nothing is cut in half. In Casama that's the Inbox filters, the Tasks
filters and board, the category chips in Apps, Skills and the persona gallery, the color and
wallpaper pickers, and more: people miss the choices past the edge. Fading the edge where there's
more to scroll hints that the row moves, and the fade goes away once there's nothing more that way.

## Where

Fifteen horizontal scroll views, none with an edge fade today (the only `ShaderMask`s in the app
are the shimmer in `lib/ui/motion.dart` and the voice-call fades, which are unrelated). All code
below was read from the files as they are now; line numbers are where each snippet starts. In the
excerpts, `...` marks lines left out and `// line N` marks the closing line a step edits; neither
is in the file.

```dart
// lib/features/inbox/inbox_screen.dart:75 — current (Inbox filter chips in the header)
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.xxs),
              child: Row(
                spacing: AppSpace.xs,
                children: [
                  ...
                ],
              ),
            ),        // line 91
          ),
        ),
      ),
      body: _filter == InboxFilter.pages ? const PagesList() : _InboxFeed(filter: _filter),
```

```dart
// lib/features/board/board_screen.dart:150 — current (phone filter row)
                SingleChildScrollView(
                  key: const Key('ticketFilters'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.xs),
                  child: Row(spacing: AppSpace.xs, children: filters),
                )
              else
```

```dart
// lib/features/board/board_screen.dart:183 — current (status columns on tablets and desktops)
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                    children: [
                      for (final s in BoardScreen.statuses)
                        _Column(
                          ...
                        ),
                    ],
                  ),      // line 195
                ),
            ],
```

```dart
// lib/features/settings/theme_screen.dart:116 — current (color family chips)
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final f in [null, ...SchemeFamily.values])
                Padding(
                  ...
                ),
            ],
          ),              // line 137
        ),
```

```dart
// lib/features/settings/background_screen.dart:44 — current (wallpaper pattern swatches)
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: WallpaperPattern.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpace.xs),
            itemBuilder: (context, i) {
              ...
            },
          ),              // line 71
        ),
        SectionHeader(title: l10n.backgroundColors),
```

```dart
// lib/features/bots/template_picker.dart:241 — current (persona gallery category chips)
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in [null, ...categories])
                  Padding(
                    ...
                  ),
              ],
            ),            // line 258
          ),
```

```dart
// lib/features/quick_ask/quick_ask_screen.dart:125 — current (which bot to ask)
          SizedBox(
            height: 44,
            child: ListView.separated(
              key: const Key('quickAskBot'),
              scrollDirection: Axis.horizontal,
              itemCount: bots.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpace.xs),
              itemBuilder: (context, i) {
                ...
              },
            ),            // line 142
          ),
```

```dart
// lib/features/chat/chat_screen.dart:638 — current (files waiting to be sent, inside the composer)
                              : SizedBox(
                                  height: 64,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _pending.length,
                                    separatorBuilder: (_, _) => const SizedBox(width: AppSpace.xs),
                                    itemBuilder: (context, i) => _PendingChip(item: _pending[i], onRemove: () => setState(() => _pending.removeAt(i))),
                                  ),
                                ),
```

```dart
// lib/features/computer/live_view_screen.dart:259 — current (Copy / Paste / Screenshot row)
    return SingleChildScrollView(
      key: const Key('liveQuickActions'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...
        ],
      ),
    );                    // line 270
  }

  // --- teach a task (D-120) -------------------------------------------------
```

```dart
// lib/features/integrations/integrations_screen.dart:202 — current (app category chips, then popular apps)
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final c in [null, ...categories])
                Padding(
                  ...
                ),
            ],
          ),              // line 219
        ),
        if (!filtering && popular.isNotEmpty) ...[
          SectionHeader(title: l10n.popularApps),
          SizedBox(
            height: 204,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: popular.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
              itemBuilder: (_, i) => _FeaturedApp(app: popular[i], connected: connectedIds.contains(popular[i].id), onTap: () => _connect(popular[i])),
            ),
          ),
        ],
```

```dart
// lib/features/computer/computer_screen.dart:936 — current (folder path in the Files tab; reverse: true)
                      builder: (context, bar) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: ConstrainedBox(
                          ...
                        ),
                      ),          // line 966
                    ),
                  ),
```

```dart
// lib/features/skills/skill_catalog_screen.dart:149 — current (skill category chips)
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final c in [null, ...categories])
                Padding(
                  ...
                ),
            ],
          ),              // line 175
        ),
        if (shown.isEmpty)
```

```dart
// lib/features/admin/admin_screen.dart:45 — current (scrollable admin TabBar)
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.zero,
                tabs: [
                  ...
                  Tab(height: 40, text: l10n.adminAbuse),
                ],
              ),          // line 58
            ),
          ),
        ),
        body: const TabBarView(children: [_Overview(), _Users(), _Orgs(), _Services(), _Abuse()]),
```

```dart
// lib/features/computer/computer_screen.dart:344 — current (scrollable Screen / Terminal / Files tabs)
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          padding: EdgeInsets.zero,
                          tabs: [
                            ...
                          ],
                        ),        // line 371
                      ),
                    ),
                    _AdvancedTabsToggle(open: advanced),
```

**Other fixes that touch the same code.** Two companion fixes may already have run on these
files. If so, the code differs from the excerpts above in exactly these ways, which are expected:
keep them as they are, and line numbers may be a few lines off.
- "Scroll the tapped tab fully into view": chips and swatches inside these rows are wrapped as
  `RevealWhenSelected(selected: ..., child: ChoiceChip(` … `)),` (or `_Swatch(`).
- "Let horizontal lists reach the screen edges": some of these lists gained a
  `padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),` (or `AppSpace.lg`) line,
  their `SizedBox(` is wrapped as `PageBleed(child: SizedBox(` … `)),`, the popular-apps
  `clipBehavior: Clip.none,` line is already gone, the two `TabBar`s have a non-zero `padding:`,
  `_quickActions` takes a second `gutter` argument and has a `padding:` line, and in
  `integrations_screen.dart` / `skill_catalog_screen.dart` the `_browse` method returns a list
  (`return [` … `];`) instead of a `Column`.
- "The ends of lists get cut off above the phone's home indicator or gesture bar": the board
  columns' `padding:` line (`board_screen.dart:186`) reads
  `padding: EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, BottomPadding.of(context, minimum: AppSpace.md)),`
  and the two empty states above it lost their `Padding(padding: EdgeInsets.only(bottom: barInset), ...)`
  wrappers (a few lines shorter). This plan doesn't edit those lines.
Other fixes elsewhere in these files can also shift line numbers; find each spot by its quoted
text.

## The fix

The article's reusable `Edgy` widget, a `ShaderMask` with a `LinearGradient` and
`BlendMode.dstIn` that fades a scroll view's start and end, applied to this codebase as
`EdgeFade` in `lib/ui/edge_fade.dart`. Three adaptations, all inside the widget so call sites
stay one line:

1. **Each edge fades only while there's more to scroll that way.** The article's `fadeStart` /
   `fadeEnd` flags are driven by the scroll position: a row that fits shows no fade, a row at
   rest fades only its end, and the fade eases out over the last `extent` pixels as the row
   reaches either end.
2. **Fixed fade length in pixels** (40, about the article's "subtle" `0.1` stop on a phone)
   instead of 12% of the width, so the Tasks board on a 1400px window doesn't get a 170px fade.
3. **Follows the reading direction and `reverse`**, so right-to-left layouts and the reversed
   folder path fade on the correct side.

New file `lib/ui/edge_fade.dart`, exactly:

```dart
import 'package:flutter/material.dart';

/// Fades the edges of a scroll view where it has more to show, so a row of chips or cards reads as
/// scrollable even when no item is cut in half. Wrap the scroll view itself.
///
/// Each edge fades only while there is more to scroll that way (a row that fits shows no fade),
/// easing out over the last [extent] pixels. It follows the reading direction and `reverse`. The
/// mask is alpha-only, so it works over any background and in light and dark mode.
class EdgeFade extends StatefulWidget {
  const EdgeFade({super.key, required this.child, this.extent = 40});

  /// The scroll view to fade.
  final Widget child;

  /// How far each fade reaches into the scroll view, in logical pixels.
  final double extent;

  @override
  State<EdgeFade> createState() => EdgeFadeState();
}

class EdgeFadeState extends State<EdgeFade> {
  double _before = 0;
  double _after = 0;
  AxisDirection _direction = AxisDirection.right;

  /// How strongly the edge where scrolling starts fades, from 0 (sharp) to 1.
  @visibleForTesting
  double get before => _before;

  /// How strongly the edge where scrolling ends fades, from 0 (sharp) to 1.
  @visibleForTesting
  double get after => _after;

  /// The direction the scroll view's content runs in.
  @visibleForTesting
  AxisDirection get direction => _direction;

  bool _onMetrics(ScrollMetrics metrics, int depth) {
    // Only the scroll view this wraps; lists inside its items (a board column) report a higher depth.
    if (depth != 0) return false;
    final before = (metrics.extentBefore / widget.extent).clamp(0.0, 1.0);
    final after = (metrics.extentAfter / widget.extent).clamp(0.0, 1.0);
    if (before != _before || after != _after || metrics.axisDirection != _direction) {
      setState(() {
        _before = before;
        _after = after;
        _direction = metrics.axisDirection;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      // The first layout, and content that grows or shrinks without a scroll.
      onNotification: (n) => _onMetrics(n.metrics, n.depth),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _onMetrics(n.metrics, n.depth),
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) {
            final length = axisDirectionToAxis(_direction) == Axis.horizontal ? bounds.width : bounds.height;
            final stop = length <= 0 ? 0.0 : (widget.extent / length).clamp(0.0, 0.5);
            // From the edge where scrolling starts to the edge where it ends: right to left in
            // right-to-left layouts and in reversed lists.
            final (begin, end) = switch (_direction) {
              AxisDirection.right => (Alignment.centerLeft, Alignment.centerRight),
              AxisDirection.left => (Alignment.centerRight, Alignment.centerLeft),
              AxisDirection.down => (Alignment.topCenter, Alignment.bottomCenter),
              AxisDirection.up => (Alignment.bottomCenter, Alignment.topCenter),
            };
            return LinearGradient(
              begin: begin,
              end: end,
              colors: [
                const Color(0xFFFFFFFF).withValues(alpha: 1 - _before),
                const Color(0xFFFFFFFF),
                const Color(0xFFFFFFFF),
                const Color(0xFFFFFFFF).withValues(alpha: 1 - _after),
              ],
              stops: [0, stop, 1 - stop, 1],
            ).createShader(bounds);
          },
          child: widget.child,
        ),
      ),
    );
  }
}
```

Each call site wraps its scroll view and nothing else, keeping the scroll view's `key` on the
scroll view. Write the wrapper on the scroll view's opening line so nothing inside needs
re-indenting, and add one `)` to the scroll view's closing line:

```dart
// target, for example in theme_screen.dart
        SizedBox(
          height: 40,
          child: EdgeFade(child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...
            ],
          )),
        ),
```

`ShaderMask` with a `LinearGradient` and `BlendMode.dstIn` is already how
`lib/features/voice/call_screen.dart` (around line 729) fades its captions; imitate its style.

## Steps

1. Create `lib/ui/edge_fade.dart` with exactly the code in "The fix". Then run
   `dart format -l 200 lib/ui/edge_fade.dart` (only on this new file).

2. In each file below, add the import next to the file's other `'../../ui/...'` imports:
   `import '../../ui/edge_fade.dart';`
   Files: `lib/features/inbox/inbox_screen.dart`, `lib/features/board/board_screen.dart`,
   `lib/features/settings/theme_screen.dart`, `lib/features/settings/background_screen.dart`,
   `lib/features/bots/template_picker.dart`, `lib/features/quick_ask/quick_ask_screen.dart`,
   `lib/features/chat/chat_screen.dart`, `lib/features/computer/live_view_screen.dart`,
   `lib/features/integrations/integrations_screen.dart`, `lib/features/computer/computer_screen.dart`,
   `lib/features/skills/skill_catalog_screen.dart`, `lib/features/admin/admin_screen.dart`.

3. `lib/features/inbox/inbox_screen.dart`:
   - line 75 `            child: SingleChildScrollView(` becomes
     `            child: EdgeFade(child: SingleChildScrollView(`
   - line 91, the `            ),` that closes that `SingleChildScrollView` (directly after the
     `              ),` that closes the `Row`, four lines above
     `      body: _filter == InboxFilter.pages ...`), becomes `            )),`

4. `lib/features/board/board_screen.dart`, phone filter row:
   - line 150 `                SingleChildScrollView(` becomes
     `                EdgeFade(child: SingleChildScrollView(`
   - line 155 `                )` (the line right before `              else`) becomes `                ))`
   - The `key: const Key('ticketFilters'),` line stays on the `SingleChildScrollView`.

5. `lib/features/board/board_screen.dart`, status columns:
   - line 184 `                  child: ListView(` becomes `                  child: EdgeFade(child: ListView(`
   - line 195, the `                  ),` right after the `                    ],` that ends its
     `children`, becomes `                  )),`

6. `lib/features/settings/theme_screen.dart`:
   - line 118 `          child: ListView(` becomes `          child: EdgeFade(child: ListView(`
   - line 137, the `          ),` right after the `            ],` that ends its `children`,
     becomes `          )),`

7. `lib/features/settings/background_screen.dart`:
   - line 46 `          child: ListView.separated(` becomes
     `          child: EdgeFade(child: ListView.separated(`
   - line 71, the `          ),` right after the `            },` that ends `itemBuilder`,
     becomes `          )),`

8. `lib/features/bots/template_picker.dart`:
   - line 243 `            child: ListView(` becomes `            child: EdgeFade(child: ListView(`
   - line 258, the `            ),` right after the `              ],` that ends its `children`,
     becomes `            )),`

9. `lib/features/quick_ask/quick_ask_screen.dart`:
   - line 127 `            child: ListView.separated(` becomes
     `            child: EdgeFade(child: ListView.separated(`
   - line 142, the `            ),` right after the `              },` that ends `itemBuilder`,
     becomes `            )),`
   - The `key: const Key('quickAskBot'),` line stays on the `ListView.separated`.

10. `lib/features/chat/chat_screen.dart`:
    - line 640 `                                  child: ListView.separated(` becomes
      `                                  child: EdgeFade(child: ListView.separated(`
    - line 645, the `                                  ),` right after the `itemBuilder: ... _PendingChip(...)` line,
      becomes `                                  )),`

11. `lib/features/computer/live_view_screen.dart`, in `_quickActions`:
    - line 259 `    return SingleChildScrollView(` becomes `    return EdgeFade(child: SingleChildScrollView(`
    - line 270 `    );` (the one right before `  }` and the `// --- teach a task (D-120)` comment)
      becomes `    ));`
    - The `key: const Key('liveQuickActions'),` line stays on the `SingleChildScrollView`.

12. `lib/features/integrations/integrations_screen.dart`, category chips:
    - line 204 `          child: ListView(` becomes `          child: EdgeFade(child: ListView(`
    - line 219, the `          ),` right after the `            ],` that ends its `children`,
      becomes `          )),`

13. `lib/features/integrations/integrations_screen.dart`, popular apps:
    - line 225 `            child: ListView.separated(` becomes
      `            child: EdgeFade(child: ListView.separated(`
    - delete line 227 `              clipBehavior: Clip.none,` if it is still there. The mask
      only covers the list's own box, so cards drawn outside it (which `Clip.none` allows)
      would show past the fade, unfaded. The list's default clip keeps them inside.
    - the `            ),` right after the `itemBuilder: (_, i) => _FeaturedApp(...)` line
      becomes `            )),`

14. `lib/features/computer/computer_screen.dart`, folder path:
    - line 936 `                      builder: (context, bar) => SingleChildScrollView(` becomes
      `                      builder: (context, bar) => EdgeFade(child: SingleChildScrollView(`
    - line 966, the `                      ),` that closes that `SingleChildScrollView` (right after
      the `                        ),` that closes the `ConstrainedBox`), becomes `                      )),`

15. `lib/features/skills/skill_catalog_screen.dart`:
    - line 151 `          child: ListView(` becomes `          child: EdgeFade(child: ListView(`
    - line 175, the `          ),` right after the `            ],` that ends its `children`,
      becomes `          )),`

16. `lib/features/admin/admin_screen.dart`:
    - line 47 `              child: TabBar(` becomes `              child: EdgeFade(child: TabBar(`
    - line 58, the `              ),` right after the `                ],` that ends `tabs`,
      becomes `              )),`

17. `lib/features/computer/computer_screen.dart`, tabs:
    - line 346 `                        child: TabBar(` becomes
      `                        child: EdgeFade(child: TabBar(`
    - line 371, the `                        ),` right after the `                          ],` that
      ends `tabs` (three lines above `_AdvancedTabsToggle(open: advanced),`), becomes
      `                        )),`

18. Create `test/edge_fade_test.dart`:

    ```dart
    // Horizontal lists fade an edge only while there is more to scroll that way.
    import 'package:flutter/material.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:casama_app/ui/edge_fade.dart';

    Widget _row({int count = 12, TextDirection direction = TextDirection.ltr}) => MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Center(
          child: SizedBox(
            width: 300,
            height: 40,
            child: EdgeFade(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [for (var i = 0; i < count; i++) SizedBox(key: Key('item-$i'), width: 100)],
              ),
            ),
          ),
        ),
      ),
    );

    EdgeFadeState _fade(WidgetTester tester) => tester.state<EdgeFadeState>(find.byType(EdgeFade));

    void main() {
      testWidgets('at the start only the end fades; at the end only the start fades', (tester) async {
        await tester.pumpWidget(_row());
        await tester.pump();
        expect(_fade(tester).before, 0);
        expect(_fade(tester).after, 1);

        await tester.drag(find.byType(ListView), const Offset(-3000, 0));
        await tester.pumpAndSettle();
        expect(_fade(tester).before, 1);
        expect(_fade(tester).after, 0);
      });

      testWidgets('a row that fits has no fade', (tester) async {
        await tester.pumpWidget(_row(count: 2));
        await tester.pump();
        expect(_fade(tester).before, 0);
        expect(_fade(tester).after, 0);
      });

      testWidgets('right to left: the row runs leftwards and its far end still fades', (tester) async {
        await tester.pumpWidget(_row(direction: TextDirection.rtl));
        await tester.pump();
        expect(_fade(tester).direction, AxisDirection.left);
        expect(_fade(tester).before, 0);
        expect(_fade(tester).after, 1);
      });
    }
    ```

    Then run `dart format -l 200 test/edge_fade_test.dart` (only on this new file).

19. Run, from `client/`:
    `flutter test test/edge_fade_test.dart test/phone_layout_test.dart test/inbox_feed_test.dart test/tasks_phone_test.dart test/board_test.dart test/design_test.dart test/autonomy_test.dart test/desktop_context_test.dart test/advanced_connections_test.dart test/skill_library_test.dart test/live_test.dart test/computer_tabs_test.dart test/admin_test.dart`

## Check it

`dart analyze lib/ui/edge_fade.dart test/edge_fade_test.dart lib/features/inbox/inbox_screen.dart lib/features/board/board_screen.dart lib/features/settings/theme_screen.dart lib/features/settings/background_screen.dart lib/features/bots/template_picker.dart lib/features/quick_ask/quick_ask_screen.dart lib/features/chat/chat_screen.dart lib/features/computer/live_view_screen.dart lib/features/integrations/integrations_screen.dart lib/features/computer/computer_screen.dart lib/features/skills/skill_catalog_screen.dart lib/features/admin/admin_screen.dart`
reports no errors and no warnings. (`lib/features/computer/computer_screen.dart` already has five
`curly_braces_in_flow_control_structures` infos; those are not yours. Any other new issue is.)

Each grep below counts in one file:
- `grep -c "class EdgeFade " lib/ui/edge_fade.dart` → 1
- `grep -c "BlendMode.dstIn" lib/ui/edge_fade.dart` → 1
- `grep -c "EdgeFade(child: SingleChildScrollView(" lib/features/inbox/inbox_screen.dart` → 1
- `grep -c "EdgeFade(child:" lib/features/board/board_screen.dart` → 2
- `grep -c "EdgeFade(child: ListView(" lib/features/settings/theme_screen.dart` → 1
- `grep -c "EdgeFade(child: ListView.separated(" lib/features/settings/background_screen.dart` → 1
- `grep -c "EdgeFade(child: ListView(" lib/features/bots/template_picker.dart` → 1
- `grep -c "EdgeFade(child: ListView.separated(" lib/features/quick_ask/quick_ask_screen.dart` → 1
- `grep -c "EdgeFade(child: ListView.separated(" lib/features/chat/chat_screen.dart` → 1
- `grep -c "EdgeFade(child: SingleChildScrollView(" lib/features/computer/live_view_screen.dart` → 1
- `grep -c "EdgeFade(child:" lib/features/integrations/integrations_screen.dart` → 2
- `grep -c "Clip.none" lib/features/integrations/integrations_screen.dart` → 0
- `grep -c "EdgeFade(child:" lib/features/computer/computer_screen.dart` → 2
- `grep -c "EdgeFade(child: ListView(" lib/features/skills/skill_catalog_screen.dart` → 1
- `grep -c "EdgeFade(child: TabBar(" lib/features/admin/admin_screen.dart` → 1

The `flutter test` run in step 19 passes.

## Don't touch

- `PageView` / `TabBarView` (the swipeable pages under the admin and computer tabs): they scroll
  sideways but are pages, not lists; a fade there would dim the page being read.
- Single-line text fields (they scroll sideways internally) and every vertical list.
- `lib/ui/motion.dart` (`Shimmer`) and the fades in `lib/features/voice/`: unrelated masks.
- Padding, spacing, chip styles and keys of the rows: only the wrapper is added. Moving list
  padding to the screen edge and scrolling the tapped chip into view are separate fixes (see
  "Other fixes that touch the same code"); don't do them here.
- No new strings: nothing user-facing changes, so `lib/l10n/app_en.arb` stays as is.
- If `lib/ui/glass/` exists when you run this, check whether any widget named above moved
  there; if it did, STOP and report instead of editing the old location.
- Never run `dart format` on existing files or on a directory, and run no git commands (the
  tree is shared; others commit).
- No new dependencies.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on
  since this plan was written), other than the differences listed under "Other fixes that touch
  the same code".
- The fix seems to require touching something in "Don't touch".
- A test in step 19 fails because of this change (a missing `)` usually shows as an analyzer
  error first; a layout or overflow failure in `phone_layout_test.dart` is a real failure).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to
open to see it. For example: rows that scroll sideways now fade softly at the edge where there's
more, and the fade disappears at the end of the row; on a phone, open Settings → Color scheme
and look at the color family chips, then scroll them to the end.
