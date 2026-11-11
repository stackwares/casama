# Fix: Sideways lists stop short of the screen edge

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/horizontal-list-padding
- **Needs new dependency**: none

## Why

When a page's scroll view has side padding, every horizontal list inside it gets clipped at that
padding line: chips and cards vanish 16px before the screen edge instead of sliding past it, which
looks cut off and makes the row feel cramped. In Casama this hits the color family and wallpaper
pickers, the Quick Ask bot row, the Apps and Skills category chips and popular apps, the persona
gallery's categories, the live view's action row, and the admin and computer tabs. Each of these
lists should reach the edge and carry its own padding, so its first item still lines up with the
rest of the page.

## Where

All code below was read from the files as they are now; line numbers are where each snippet
starts. In the excerpts, `...` marks lines left out and `// line N` marks a line a step edits;
neither is in the file.

**The page widget that causes most of it.** `PageColumn` (also used by every `SubPage(children: ...)`)
puts the page's side padding on its `ListView`, so every child, horizontal lists included, is
clipped at the gutter:

```dart
// lib/ui/page.dart:53 — current
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = AppSpace.gutter + AppBreakpoints.centeringInset(constraints.maxWidth, maxWidth: maxWidth);
        return ListView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, padding: EdgeInsets.fromLTRB(side, top, side, AppSpace.xxl + MediaQuery.paddingOf(context).bottom), children: children);
      },
    );
  }
}

/// A centered lazy list for long collections, with the page's width and gutters.
```

**Ten horizontal lists clipped by padding around them:**

```dart
// lib/features/settings/theme_screen.dart:116 — current (SubPage children → PageColumn)
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final f in [null, ...SchemeFamily.values])
                ...
            ],
          ),
        ),        // line 138
        const SizedBox(height: AppSpace.md),
        if (shown.isEmpty)
```

```dart
// lib/features/settings/background_screen.dart:44 — current (SubPage children → PageColumn)
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: WallpaperPattern.values.length,
            ...
          ),
        ),        // line 72
        SectionHeader(title: l10n.backgroundColors),
```

```dart
// lib/features/quick_ask/quick_ask_screen.dart:125 — current (SubPage children → PageColumn)
          SizedBox(
            height: 44,
            child: ListView.separated(
              key: const Key('quickAskBot'),
              scrollDirection: Axis.horizontal,
              itemCount: bots.length,
              ...
            ),
          ),      // line 143
          const SizedBox(height: AppSpace.md),
        ],
```

```dart
// lib/features/integrations/integrations_screen.dart:135 — current. The two lists sit inside the
// Column that _browse returns, which is one child of a PageColumn.
            if (tab == _HubTab.connected)
              _Readable(child: _Connected(items: items, onBrowse: () => setState(() => _tab = _HubTab.browse)))
            else
              catalog.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpace.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => FormNote(errorText(context, e), icon: LucideIcons.triangleAlert),
                data: (cat) => _browse(context, cat, items),
              ),
...
// :169
  Widget _browse(BuildContext context, AppCatalog cat, List<Integration> connected) {
...
// :186
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('appSearch'),
...
// :202 (category chips)
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final c in [null, ...categories])
                ...
            ],
          ),
        ),        // line 220
        if (!filtering && popular.isNotEmpty) ...[
          SectionHeader(title: l10n.popularApps),
          SizedBox(                                  // line 223 (popular apps)
            height: 204,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: popular.length,
              ...
            ),
          ),      // line 232
        ],
        SectionHeader(title: filtering ? '${shown.length}' : l10n.allApps),
...
// :252
            },
          ),
      ],
    );
  }
}

String _authLabel(BuildContext context, CatalogApp a) {
```

```dart
// lib/features/skills/skill_catalog_screen.dart:89 — current. The chips sit inside the Column
// that _browse returns, the only child of a PageColumn.
        data: (cat) => PageColumn(
          maxWidth: kWidePageMaxWidth,
          children: [_browse(context, cat)],
        ),
...
// :97
  Widget _browse(BuildContext context, SkillCatalog cat) {
...
// :128
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('catalogSearch'),
...
// :148
        const SizedBox(height: AppSpace.sm),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final c in [null, ...categories])
                ...
            ],
          ),
        ),        // line 176
        if (shown.isEmpty)
...
// :204
        const SizedBox(height: AppSpace.xl),
      ],
    );
  }
```

```dart
// lib/features/bots/template_picker.dart:225 — current (persona gallery sheet: a padded Column)
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.choosePersona, style: context.textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(l10n.choosePersonaHelp, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: AppSpace.md),
          TextField(
            key: const Key('personaSearch'),
            controller: _search,
            decoration: InputDecoration(hintText: l10n.searchPersonas, prefixIcon: const Icon(LucideIcons.search, size: 20)),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpace.sm),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in [null, ...categories])
                  ...
              ],
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final columns = c.maxWidth > 560 ? 2 : 1;
                ...
              },
            ),    // line 297
          ),
        ],
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
```

```dart
// lib/features/computer/live_view_screen.dart:249 — current (Copy / Paste / Screenshot row)
  Widget _quickActions(BuildContext context) {
...
// :259
    return SingleChildScrollView(
      key: const Key('liveQuickActions'),
      scrollDirection: Axis.horizontal,
      child: Row(
...
// :609
          Padding(padding: EdgeInsets.fromLTRB(gutter - 6, 0, gutter, AppSpace.xs), child: _quickActions(context)),
```

```dart
// lib/features/admin/admin_screen.dart:43 — current (scrollable TabBar inside a Padding)
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.sm, 0, AppSpace.sm, AppSpace.xs),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.zero,
                tabs: [
```

```dart
// lib/features/computer/computer_screen.dart:339 — current (scrollable TabBar inside a Padding,
// with the Advanced toggle after it)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          padding: EdgeInsets.zero,
                          tabs: [
```

Already right, not touched: the Inbox filters (`lib/features/inbox/inbox_screen.dart:75`) and the
Tasks filters and board columns (`lib/features/board/board_screen.dart:150` and `:184`) span the
full width and carry their own padding.

**Other fixes that touch the same code.** Two companion fixes may already have run on these
files. If so, the code differs from the excerpts in exactly these ways, which are expected: keep
them as they are, and line numbers may be a few lines off.
- "Make horizontal lists feel scrollable": the scroll views are wrapped as
  `EdgeFade(child: ListView(` / `EdgeFade(child: ListView.separated(` /
  `EdgeFade(child: SingleChildScrollView(` / `EdgeFade(child: TabBar(` with one extra `)` on
  their closing line, and the popular apps' `clipBehavior: Clip.none,` line is already gone.
- "Scroll the tapped tab fully into view": chips and swatches are wrapped as
  `RevealWhenSelected(selected: ..., child: ChoiceChip(` … `)),` (or `_Swatch(`).
- "The ends of lists get cut off above the phone's home indicator or gesture bar": in
  `template_picker.dart`, `showPersonaGallery` gained a `contentPadsBottom: true,` line (so the
  gallery's lines sit one lower) and the gallery `GridView`'s `padding:` (inside the
  `LayoutBuilder`, left out of the excerpt above) ends with `BottomPadding.of(...)`. This plan
  doesn't edit those lines. It also leaves `PageColumn`'s bottom padding exactly as it is.
Other fixes elsewhere in these files can also shift line numbers; find each spot by its quoted
text.

## The fix

The article's rule: keep the page's scroll view edge to edge (no side padding), give each child
its own side padding, and let a horizontal list carry its own padding inside the list
(`ListView(padding: EdgeInsets.symmetric(horizontal: 16))`), so it reaches the edges and its first
item still lines up with the page.

**Central change in `PageColumn`.** Its `ListView` loses its side padding and pads each child
instead, which looks exactly the same for every existing page. A child wrapped in the new marker
`PageBleed` gets only the centering inset, not the gutter, and its list adds the gutter itself.
On a phone the centering inset is 0, so the list reaches the screen edges. On a wide window it
reaches the edges of the centered page column (680px on settings pages), not the window's, so a
row doesn't spill out past the content into the empty sides.

```dart
// target: lib/ui/page.dart, PageColumn.build, then the new PageBleed class
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = AppBreakpoints.centeringInset(constraints.maxWidth, maxWidth: maxWidth);
        final side = AppSpace.gutter + inset;
        // The list itself is edge to edge and each section carries the side padding, so a
        // [PageBleed] section can reach the edges.
        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(0, top, 0, AppSpace.xxl + MediaQuery.paddingOf(context).bottom),
          children: [
            for (final child in children) Padding(padding: EdgeInsets.symmetric(horizontal: child is PageBleed ? inset : side), child: child),
          ],
        );
      },
    );
  }
}

/// A section of a [PageColumn] (or [SubPage]) that reaches the page's edges instead of stopping at
/// its gutters: a horizontal list, so its items slide all the way to the edge of the screen. The
/// page skips its gutter for this child, so the list adds its own:
/// `padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter)`.
class PageBleed extends StatelessWidget {
  const PageBleed({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
```

**Each list** is wrapped in `PageBleed` and gets `padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),`.
`PageBleed` only works as a *direct* child of `PageColumn`, so in Apps and Skills, `_browse` returns
its widgets as a list that is spread into the page instead of one `Column`. Write the wrapper on
the opening line so nothing inside needs re-indenting:

```dart
// target, for example in theme_screen.dart
        PageBleed(child: SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
            children: [
              ...
            ],
          ),
        )),
```

**Lists that aren't in a `PageColumn`** get the same treatment by hand: the persona gallery sheet
moves its side padding from the whole `Column` onto the parts that need it, the live view's
action row takes the padding inside its scroll view, and the two `TabBar`s use their own
`padding:` parameter, which for a scrollable `TabBar` insets the content inside the scroll view
("allowing the padding to scroll with the tab bar, rather than enclosing it", per its docs).

## Steps

1. `lib/ui/page.dart`: replace `PageColumn.build` (lines 53–61, from `  @override` through the
   `  }` that ends `build`) with the `build` shown in "The fix", then add the `PageBleed` class
   from "The fix" right after the closing `}` of `PageColumn` (above the
   `/// A centered lazy list for long collections` comment). Don't change `PageListView`,
   `SubPage` or `pageSide`.

2. `lib/features/settings/theme_screen.dart` (already imports `../../ui/page.dart`):
   - line 116 `        SizedBox(` (the one followed by `          height: 40,`) becomes
     `        PageBleed(child: SizedBox(`
   - directly after the line `            scrollDirection: Axis.horizontal,` of that list, insert
     `            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),`
   - line 138, the `        ),` that closes the `SizedBox` (right above
     `        const SizedBox(height: AppSpace.md),` and `        if (shown.isEmpty)`), becomes `        )),`

3. `lib/features/settings/background_screen.dart` (already imports `../../ui/page.dart`):
   - line 44 `        SizedBox(` (the one followed by `          height: 112,`) becomes
     `        PageBleed(child: SizedBox(`
   - directly after `            scrollDirection: Axis.horizontal,` (the line above
     `            itemCount: WallpaperPattern.values.length,`), insert
     `            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),`
   - line 72, the `        ),` right above `        SectionHeader(title: l10n.backgroundColors),`,
     becomes `        )),`

4. `lib/features/quick_ask/quick_ask_screen.dart` (already imports `../../ui/page.dart`):
   - line 125 `          SizedBox(` (the one followed by `            height: 44,`) becomes
     `          PageBleed(child: SizedBox(`
   - directly after `              scrollDirection: Axis.horizontal,` (the line above
     `              itemCount: bots.length,`), insert
     `              padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),`
   - line 143, the `          ),` right above `          const SizedBox(height: AppSpace.md),`
     and `        ],`, becomes `          )),`

5. `lib/features/integrations/integrations_screen.dart` (already imports `../../ui/page.dart`):
   - Lines 138–145, the `catalog.when(` call shown in "Where", become:

     ```dart
              // Spread into the page, so each part gets the page's side padding and the sideways
              // lists can reach the edges (PageBleed).
              ...catalog.when<List<Widget>>(
                loading: () => const [
                  Padding(
                    padding: EdgeInsets.all(AppSpace.xl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (e, _) => [FormNote(errorText(context, e), icon: LucideIcons.triangleAlert)],
                data: (cat) => _browse(context, cat, items),
              ),
     ```

     (the `if (tab == _HubTab.connected)` line, the `_Readable(...)` line and the `else` line
     above stay as they are). The indentation in this block is the file's own, counted from the
     start of the line: 14 spaces, the same as the `catalog.when(` line it replaces.
   - line 169 `  Widget _browse(BuildContext context, AppCatalog cat, List<Integration> connected) {`
     becomes `  List<Widget> _browse(BuildContext context, AppCatalog cat, List<Integration> connected) {`
   - lines 186–188, the three lines `    return Column(` / `      crossAxisAlignment: CrossAxisAlignment.stretch,` /
     `      children: [`, become the single line `    return [`
   - lines 254–255 at the end of `_browse`, `      ],` / `    );` (right before `  }`, `}` and
     `String _authLabel(`), become the single line `    ];`
   - Leave every line between them exactly as it is, indentation included (don't reformat).
   - Category chips: line 202 `        SizedBox(` (the one followed by `          height: 38,`)
     becomes `        PageBleed(child: SizedBox(`; directly after the
     `            scrollDirection: Axis.horizontal,` line of that list (the one followed by
     `            children: [`), insert
     `            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),`; and line 220,
     the `        ),` right above `        if (!filtering && popular.isNotEmpty) ...[`, becomes `        )),`
   - Popular apps: line 223 `          SizedBox(` (the one followed by `            height: 204,`)
     becomes `          PageBleed(child: SizedBox(`; directly after
     `              scrollDirection: Axis.horizontal,` of that list, insert
     `              padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),`; delete the
     line `              clipBehavior: Clip.none,` if it is still there (it let cards draw past
     the list to fake reaching the edge; now the list really reaches it, and on wide windows the
     cards would otherwise spill past the page column); and line 232, the `          ),` right
     above `        ],` and `        SectionHeader(title: filtering ? ...`, becomes `          )),`

6. `lib/features/skills/skill_catalog_screen.dart` (already imports `../../ui/page.dart`):
   - line 91 `          children: [_browse(context, cat)],` becomes `          children: _browse(context, cat),`
   - line 97 `  Widget _browse(BuildContext context, SkillCatalog cat) {` becomes
     `  List<Widget> _browse(BuildContext context, SkillCatalog cat) {`
   - lines 128–130, `    return Column(` / `      crossAxisAlignment: CrossAxisAlignment.stretch,` /
     `      children: [` (right above `        TextField(` and `          key: const Key('catalogSearch'),`),
     become the single line `    return [`. Don't touch the earlier `Column` inside `grid(...)`.
   - lines 205–206, `      ],` / `    );` right after `        const SizedBox(height: AppSpace.xl),`,
     become the single line `    ];`
   - Leave every line between them exactly as it is (don't reformat).
   - line 149 `        SizedBox(` (right after `        const SizedBox(height: AppSpace.sm),`, followed
     by `          height: 38,`) becomes `        PageBleed(child: SizedBox(`; directly after
     `            scrollDirection: Axis.horizontal,` of that list, insert
     `            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),`; and line 176,
     the `        ),` right above `        if (shown.isEmpty)`, becomes `        )),`

7. `lib/features/bots/template_picker.dart` (persona gallery sheet; side padding is `AppSpace.lg`
   here, and `PageBleed` is not used because this isn't a `PageColumn`):
   - Lines 225–240, from `    return Padding(` through `          const SizedBox(height: AppSpace.sm),`,
     become:

     ```dart
    // Each part carries the sheet's side padding, so the category row can scroll to the sheet's edges.
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.choosePersona, style: context.textTheme.headlineSmall),
                const SizedBox(height: 2),
                Text(l10n.choosePersonaHelp, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: AppSpace.md),
                TextField(
                  key: const Key('personaSearch'),
                  controller: _search,
                  decoration: InputDecoration(hintText: l10n.searchPersonas, prefixIcon: const Icon(LucideIcons.search, size: 20)),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.sm),
     ```

     The indentation in this block is the file's own, counted from the start of the line
     (`    return Padding(` has 4 spaces, as now).
   - In the category list right below, directly after `              scrollDirection: Axis.horizontal,`
     (the line followed by `              children: [`), insert
     `              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),`
   - line 262 `            child: LayoutBuilder(` (right under `          Expanded(`) becomes
     `            child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg), child: LayoutBuilder(`
     (the padding goes outside the `LayoutBuilder` so its 560px one-or-two-columns test sees the
     same width as before)
   - line 297, the `            ),` that closes that `LayoutBuilder` (right after `              },`
     and right above `          ),` / `        ],`), becomes `            )),`

8. `lib/features/computer/live_view_screen.dart`:
   - line 249 `  Widget _quickActions(BuildContext context) {` becomes
     `  Widget _quickActions(BuildContext context, double gutter) {`
   - in `_quickActions`, directly after `      scrollDirection: Axis.horizontal,` (the line under
     `      key: const Key('liveQuickActions'),`), insert these two lines:

     ```dart
      // Scrolls to the screen edges and carries its own gutter (- 6 lines the first button's icon up with the text above).
      padding: EdgeInsets.fromLTRB(gutter - 6, 0, gutter, 0),
     ```

   - line 609 `          Padding(padding: EdgeInsets.fromLTRB(gutter - 6, 0, gutter, AppSpace.xs), child: _quickActions(context)),`
     becomes `          Padding(padding: const EdgeInsets.only(bottom: AppSpace.xs), child: _quickActions(context, gutter)),`

9. `lib/features/admin/admin_screen.dart`:
   - line 44 `            padding: const EdgeInsets.fromLTRB(AppSpace.sm, 0, AppSpace.sm, AppSpace.xs),`
     becomes `            padding: const EdgeInsets.only(bottom: AppSpace.xs),`
   - line 50 `                padding: EdgeInsets.zero,` (inside the `TabBar`, under
     `                tabAlignment: TabAlignment.start,`) becomes
     `                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),`

10. `lib/features/computer/computer_screen.dart`:
    - line 340 `                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),` (the
      `Padding` whose child is the `Row` holding the `TabBar` and `_AdvancedTabsToggle`) becomes
      `                padding: const EdgeInsetsDirectional.only(end: AppSpace.sm),`
    - line 349 `                          padding: EdgeInsets.zero,` (inside that `TabBar`, under
      `                          tabAlignment: TabAlignment.start,`) becomes
      `                          padding: const EdgeInsetsDirectional.only(start: AppSpace.sm),`
    - The tabs now reach the screen's start edge; their end stops at the Advanced toggle, which
      is a control, not padding.

11. Create `test/page_bleed_test.dart`:

    ```dart
    // A sideways list on a page reaches the page's edges while its first item lines up with the page.
    import 'package:flutter/material.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:casama_app/theme/app_tokens.dart';
    import 'package:casama_app/ui/page.dart';

    import 'app_test.dart' show setSize;

    Widget _page() => MaterialApp(
      home: Scaffold(
        body: PageColumn(
          children: [
            const SizedBox(key: Key('section'), height: 20),
            PageBleed(
              child: SizedBox(
                key: const Key('row'),
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
                  children: [for (var i = 0; i < 10; i++) SizedBox(key: Key('item-$i'), width: 100)],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    void main() {
      testWidgets('on a phone the list spans the screen and starts in line with the page', (tester) async {
        await setSize(tester, const Size(375, 667));
        await tester.pumpWidget(_page());
        expect(tester.getTopLeft(find.byKey(const Key('section'))).dx, AppSpace.gutter);
        expect(tester.getRect(find.byKey(const Key('row'))).left, 0);
        expect(tester.getRect(find.byKey(const Key('row'))).width, 375);
        expect(tester.getTopLeft(find.byKey(const Key('item-0'))).dx, AppSpace.gutter);
      });

      testWidgets('on a wide window it spans the centered page column, not the whole window', (tester) async {
        await setSize(tester, const Size(1200, 800));
        await tester.pumpWidget(_page());
        const inset = (1200 - kPageMaxWidth) / 2;
        expect(tester.getTopLeft(find.byKey(const Key('section'))).dx, inset + AppSpace.gutter);
        expect(tester.getRect(find.byKey(const Key('row'))).left, inset);
        expect(tester.getRect(find.byKey(const Key('row'))).width, kPageMaxWidth);
        expect(tester.getTopLeft(find.byKey(const Key('item-0'))).dx, inset + AppSpace.gutter);
      });
    }
    ```

    Then run `dart format -l 200 test/page_bleed_test.dart` (only on this new file).

12. Run, from `client/`:
    `flutter test test/page_bleed_test.dart test/phone_layout_test.dart test/design_test.dart test/desktop_context_test.dart test/advanced_connections_test.dart test/autonomy_test.dart test/skill_library_test.dart test/live_test.dart test/teach_test.dart test/admin_test.dart test/computer_tabs_test.dart test/bot_profile_test.dart test/responsive_test.dart`

## Check it

`dart analyze lib/ui/page.dart test/page_bleed_test.dart lib/features/settings/theme_screen.dart lib/features/settings/background_screen.dart lib/features/quick_ask/quick_ask_screen.dart lib/features/integrations/integrations_screen.dart lib/features/skills/skill_catalog_screen.dart lib/features/bots/template_picker.dart lib/features/computer/live_view_screen.dart lib/features/admin/admin_screen.dart lib/features/computer/computer_screen.dart`
reports no errors and no warnings. (`lib/features/computer/computer_screen.dart` already has five
`curly_braces_in_flow_control_structures` infos; those are not yours. Any other new issue is.)

Each grep below counts in one file:
- `grep -c "class PageBleed " lib/ui/page.dart` → 1
- `grep -c "child is PageBleed ? inset : side" lib/ui/page.dart` → 1
- `grep -c "PageBleed(child: SizedBox(" lib/features/settings/theme_screen.dart` → 1
- `grep -c "padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter)," lib/features/settings/theme_screen.dart` → 1
- `grep -c "PageBleed(child: SizedBox(" lib/features/settings/background_screen.dart` → 1
- `grep -c "padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter)," lib/features/settings/background_screen.dart` → 1
- `grep -c "PageBleed(child: SizedBox(" lib/features/quick_ask/quick_ask_screen.dart` → 1
- `grep -c "padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter)," lib/features/quick_ask/quick_ask_screen.dart` → 1
- `grep -c "PageBleed(child: SizedBox(" lib/features/integrations/integrations_screen.dart` → 2
- `grep -c "List<Widget> _browse(" lib/features/integrations/integrations_screen.dart` → 1
- `grep -c "Clip.none" lib/features/integrations/integrations_screen.dart` → 0
- `grep -c "PageBleed(child: SizedBox(" lib/features/skills/skill_catalog_screen.dart` → 1
- `grep -c "children: _browse(context, cat)," lib/features/skills/skill_catalog_screen.dart` → 1
- `grep -c "EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 0)" lib/features/bots/template_picker.dart` → 0
- `grep -c "EdgeInsets.symmetric(horizontal: AppSpace.lg)" lib/features/bots/template_picker.dart` → 3
- `grep -c "_quickActions(context, gutter)" lib/features/computer/live_view_screen.dart` → 1
- `grep -c "padding: EdgeInsets.fromLTRB(gutter - 6, 0, gutter, 0)," lib/features/computer/live_view_screen.dart` → 1
- `grep -c "padding: EdgeInsets.zero," lib/features/admin/admin_screen.dart` → 0
- `grep -c "EdgeInsetsDirectional.only(start: AppSpace.sm)" lib/features/computer/computer_screen.dart` → 1

The `flutter test` run in step 12 passes.

## Don't touch

- `PageListView` and `pageSide` in `lib/ui/page.dart`: no horizontal list lives in them.
- The Inbox filters and the Tasks filters and board (`inbox_screen.dart`, `board_screen.dart`):
  they already reach the edges with their own padding.
- The files waiting to be sent in the chat composer (`chat_screen.dart:638`): that row sits inside
  the composer's rounded box; its 10px inset keeps chips clear of the 26px corners, so the box
  edge, not the screen edge, is its edge.
- The folder path in the Files tab (`computer_screen.dart:936`): it sits between buttons, not at
  a screen edge.
- Item spacing inside the lists (the chips' own `Padding(right: AppSpace.xs)`), chip styles, keys
  and handlers.
- Edge fades and scrolling the tapped chip into view are separate fixes (see "Other fixes that
  touch the same code"); don't do them here.
- No new strings: nothing user-facing changes, so `lib/l10n/app_en.arb` stays as is.
- If `lib/ui/glass/` exists when you run this, check whether any widget named above moved there;
  if it did, STOP and report instead of editing the old location.
- Never run `dart format` on existing files or on a directory, and run no git commands (the tree
  is shared; others commit).
- No new dependencies.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on
  since this plan was written), other than the differences listed under "Other fixes that touch
  the same code".
- The fix seems to require touching something in "Don't touch".
- A test in step 12 fails because of this change. Pay attention to `phone_layout_test.dart`: the
  `PageColumn` change reaches every settings-style page, and it must lay out exactly as before.
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to
open to see it. For example: rows that scroll sideways now slide all the way to the screen edge
instead of being cut off 16px early, while their first item still lines up with the page; on a
phone, open Settings → Background and scroll the wallpaper patterns.
