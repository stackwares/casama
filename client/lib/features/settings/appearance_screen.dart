import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/backend.dart';
import '../../core/haptics.dart';
import '../../core/share.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/appearance.dart';
import '../../theme/fonts.dart';
import '../../theme/presets.dart';
import '../../theme/schemes.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/segmented.dart';
import 'appearance_preview.dart';
import 'colors_panel.dart' show SchemeDots;
import 'gallery_looks.dart';
import 'gallery_previews.dart';
import 'gallery_screen.dart' show showGalleryDetail;

/// The Appearance row's line in Settings: the theme in use and light, dark or system.
String appearanceSummary(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  final appearance = ref.watch(appearanceProvider);
  final theme = currentThemeName(ref) ?? l10n.appearanceCustomLook;
  final mode = switch (appearance.mode) {
    ThemeMode.light => l10n.themeLight,
    ThemeMode.dark => l10n.themeDark,
    ThemeMode.system => l10n.themeSystem,
  };
  return '$theme · $mode';
}

/// The name of the built-in or saved theme the app looks like right now, if any.
String? currentThemeName(WidgetRef ref) => currentTheme(
  ref.watch(appearanceProvider),
  ref.watch(savedThemesProvider),
)?.name;

/// The built-in or saved theme [a] looks like, or null for a look of one's own.
ThemePreset? currentTheme(Appearance a, List<ThemePreset> saved) =>
    [...builtInPresets, ...saved].where((p) => p.matches(a)).firstOrNull;

/// Asks for a name and keeps the current look with the saved themes.
Future<void> saveCurrentLook(BuildContext context, WidgetRef ref) async {
  final name = await showAdaptiveSheet<String>(
    context: context,
    builder: (_) => const _NameForm(),
  );
  if (name == null || name.trim().isEmpty) return;
  final preset = await ref
      .read(savedThemesProvider.notifier)
      .save(name.trim(), ref.read(appearanceProvider));
  if (context.mounted) {
    showSuccess(context, context.l10n.appearanceSaved(preset.name));
  }
}

/// Settings → Appearance, the one place for how Casama looks. The look in use, drawn as a small
/// chat, with Customize for its colors, background and fonts; light or dark; then every theme as
/// a card in its own colors (yours, Casama's and the gallery's), one tap to use. A look you've
/// changed and not saved can be brought back with Undo after picking a theme.
class AppearanceScreen extends ConsumerStatefulWidget {
  const AppearanceScreen({super.key});

  @override
  ConsumerState<AppearanceScreen> createState() => _AppearanceScreenState();
}

/// Gallery themes shown before "Show all".
const _galleryFirst = 6;

class _AppearanceScreenState extends ConsumerState<AppearanceScreen> {
  var _allGallery = false;

  /// Uses a theme. Leaving a changed look that isn't saved offers Undo, so trying a theme never
  /// loses work.
  Future<void> _use(String name, Future<void> Function() apply) async {
    final l10n = context.l10n;
    final notifier = ref.read(appearanceProvider.notifier);
    final before = ref.read(appearanceProvider);
    final unsaved = currentTheme(before, ref.read(savedThemesProvider)) == null;
    HapticsHelper.selection();
    try {
      await apply();
    } catch (e) {
      if (mounted) showError(context, e);
      return;
    }
    if (!unsaved || !mounted) return;
    showToast(
      context,
      l10n.appearanceSwitched(name),
      replace: true,
      action: SnackBarAction(
        key: const Key('undoTheme'),
        label: l10n.undo,
        onPressed: () => notifier.apply(
          schemeId: before.schemeId,
          headingFont: before.headingFont,
          bodyFont: before.bodyFont,
          wallpaper: before.wallpaper,
          fewerEffects: before.fewerEffects,
        ),
      ),
    );
  }

  Future<void> _import() async {
    final preset = await showAdaptiveSheet<ThemePreset>(
      context: context,
      builder: (_) => const _ImportForm(),
    );
    if (preset == null || !mounted) return;
    await ref.read(savedThemesProvider.notifier).add(preset);
    await ref.read(appearanceProvider.notifier).applyPreset(preset);
    if (mounted) showSuccess(context, context.l10n.themeImported(preset.name));
  }

  Future<void> _share(ThemePreset preset, Rect? origin) async {
    final code = preset.toCode();
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) showMessage(context, context.l10n.themeCodeCopied);
    await shareText(code, origin: origin);
  }

  Future<void> _delete(ThemePreset preset) async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.deleteThemeTitle(preset.name),
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (ok) await ref.read(savedThemesProvider.notifier).remove(preset.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appearance = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);
    final saved = ref.watch(savedThemesProvider);
    final looks = ref.watch(galleryLooksProvider);
    final scheme = context.colorScheme;
    final galleryThemes = [
      for (final item in looks.value ?? const <GalleryItem>[])
        if (item.type == 'theme') item,
    ];
    // A gallery theme you've used is kept with your themes for when the gallery is offline; while
    // it's listed below, its card there is the one that shows.
    final listed = {for (final t in galleryThemes) gallerySavedThemeId(t)};
    final yours = [
      for (final p in saved)
        if (!listed.contains(p.id)) p,
    ];
    final current = currentTheme(appearance, saved);
    final shownGallery = _allGallery
        ? galleryThemes
        : galleryThemes.take(_galleryFirst).toList();

    ThemeCard presetCard(ThemePreset p) => ThemeCard(
      key: Key('preset-${p.id}'),
      menuKey: Key('presetMenu-${p.id}'),
      name: p.name,
      line: _fontsLine(p.headingFont, p.bodyFont),
      look: GalleryLook(
        scheme: themeChoiceById(p.schemeId),
        headingFont: p.headingFont,
        bodyFont: p.bodyFont,
        wallpaper: p.wallpaper,
      ),
      selected: p.matches(appearance),
      onTap: () => _use(p.name, () => notifier.applyPreset(p)),
      // Everyone has the built-in themes, so only your own have Share and Delete.
      menu: [
        if (!p.builtIn) ...[
          ThemeCardAction(
            label: l10n.shareTheme,
            icon: LucideIcons.share,
            onSelected: (origin) => _share(p, origin),
          ),
          ThemeCardAction(
            label: l10n.delete,
            icon: LucideIcons.trash2,
            onSelected: (_) => _delete(p),
          ),
        ],
      ],
    );

    ThemeCard galleryCard(GalleryItem item) {
      final heading = galleryHeadingFontOf(item);
      final body = galleryBodyFontOf(item);
      final community =
          item.authorName.isNotEmpty && item.authorName != 'Casama';
      return ThemeCard(
        key: Key('gallery-theme-${item.id}'),
        menuKey: Key('galleryMenu-${item.id}'),
        name: item.name,
        line: community
            ? l10n.galleryBy(item.authorName)
            : heading != null && body != null
            ? _fontsLine(heading, body)
            : l10n.galleryLightAndDark,
        look: GalleryLook.of(item, appearance),
        selected: galleryInUse(item, appearance),
        onTap: () => _use(item.name, () => useGalleryLook(ref, item)),
        menu: [
          ThemeCardAction(
            label: l10n.appearanceAboutTheme,
            icon: LucideIcons.info,
            onSelected: (_) => showGalleryDetail(context, item),
          ),
        ],
      );
    }

    return SubPage(
      title: l10n.appearance,
      children: [
        _CurrentLook(
          name: current?.name,
          fonts: _fontsLine(appearance.headingFont, appearance.bodyFont),
          onSave: () => saveCurrentLook(context, ref),
          onCustomize: () => context.push('/settings/appearance/customize'),
        ),
        const SizedBox(height: AppSpace.sm),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.sm),
          child: AppSegmentedControl<ThemeMode>(
            values: const [ThemeMode.light, ThemeMode.system, ThemeMode.dark],
            labels: {
              ThemeMode.light: l10n.themeLight,
              ThemeMode.system: l10n.themeSystem,
              ThemeMode.dark: l10n.themeDark,
            },
            icons: const {
              ThemeMode.light: LucideIcons.sun,
              ThemeMode.system: LucideIcons.sunMoon,
              ThemeMode.dark: LucideIcons.moon,
            },
            groupValue: appearance.mode,
            onValueChanged: notifier.setMode,
          ),
        ),
        SectionHeader(title: l10n.themes),
        _CardGrid(
          children: [
            for (final p in yours) presetCard(p),
            for (final p in builtInPresets) presetCard(p),
          ],
        ),
        if (looks.isLoading) ...[
          SectionHeader(title: l10n.appearanceFromGallery),
          const _CardGrid(children: [_CardSkeleton(), _CardSkeleton()]),
        ] else if (looks.hasError) ...[
          SectionHeader(title: l10n.appearanceFromGallery),
          InlineError(
            error: looks.error!,
            onRetry: () => ref.invalidate(galleryLooksProvider),
          ),
        ] else if (galleryThemes.isNotEmpty) ...[
          SectionHeader(
            title: l10n.appearanceFromGallery,
            count: '${galleryThemes.length}',
          ),
          _CardGrid(children: [for (final t in shownGallery) galleryCard(t)]),
          if (galleryThemes.length > shownGallery.length)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.sm),
              child: Center(
                child: TextButton.icon(
                  key: const Key('showAllGalleryThemes'),
                  onPressed: () => setState(() => _allGallery = true),
                  icon: const Icon(LucideIcons.chevronDown, size: 18),
                  label: Text(l10n.appearanceShowAll(galleryThemes.length)),
                ),
              ),
            ),
        ],
        const SizedBox(height: AppSpace.lg),
        GroupedCard(
          children: [
            SwitchListTile(
              key: const Key('fewerEffects'),
              secondary: Icon(
                LucideIcons.wandSparkles,
                color: scheme.onSurfaceVariant,
              ),
              title: Text(l10n.fewerEffects),
              subtitle: Text(l10n.fewerEffectsHelp),
              value: appearance.fewerEffects,
              onChanged: hapticOnChanged(notifier.setFewerEffects),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpace.xs,
          children: [
            TextButton.icon(
              key: const Key('importTheme'),
              onPressed: _import,
              icon: const Icon(LucideIcons.download, size: 18),
              label: Text(l10n.importTheme),
            ),
            TextButton.icon(
              key: const Key('shareToGallery'),
              onPressed: () {
                final code = ThemePreset.fromAppearance(
                  ref.read(appearanceProvider),
                  id: 'shared',
                  name: current?.name ?? l10n.myThemes,
                ).toCode();
                launchUrl(
                  galleryShareUri(code),
                  mode: LaunchMode.externalApplication,
                );
              },
              icon: const Icon(LucideIcons.share, size: 18),
              label: Text(l10n.galleryShare),
            ),
          ],
        ),
      ],
    );
  }
}

String _fontsLine(String heading, String body) =>
    heading == body ? body : '$heading · $body';

/// The look in use: a small chat in it, its name, and the way into Customize. A look that
/// matches no theme is "Custom look", with Save beside Customize.
class _CurrentLook extends StatelessWidget {
  const _CurrentLook({
    required this.name,
    required this.fonts,
    required this.onSave,
    required this.onCustomize,
  });

  /// Null for a look of one's own.
  final String? name;
  final String fonts;
  final VoidCallback onSave;
  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = context.colorScheme.onSurfaceVariant;
    final custom = name == null;
    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name ?? l10n.appearanceCustomLook,
          key: const Key('currentLookName'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          custom ? l10n.appearanceCustomHelp : fonts,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelMedium?.copyWith(color: muted),
        ),
      ],
    );
    final save = OutlinedButton.icon(
      key: const Key('saveTheme'),
      onPressed: onSave,
      icon: const Icon(LucideIcons.bookmarkPlus, size: 18),
      label: Text(l10n.save, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    final customize = FilledButton.tonalIcon(
      key: const Key('customizeLook'),
      onPressed: onCustomize,
      icon: const Icon(LucideIcons.slidersHorizontal, size: 18),
      label: Text(l10n.customize, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppearancePreview(height: 184),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xs,
              AppSpace.sm,
              0,
              AppSpace.xxs,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // The buttons go under the name when they'd squeeze it: narrow phones, large
                // text, or a custom look with Save beside Customize.
                final scale = MediaQuery.textScalerOf(context).scale(1);
                final stacked =
                    constraints.maxWidth < (custom ? 440 : 300) * scale;
                if (!stacked) {
                  return Row(
                    children: [
                      Expanded(child: label),
                      if (custom) ...[const SizedBox(width: AppSpace.xs), save],
                      const SizedBox(width: AppSpace.xs),
                      customize,
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    label,
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      children: [
                        if (custom) ...[
                          Expanded(child: save),
                          const SizedBox(width: AppSpace.xs),
                        ],
                        Expanded(child: customize),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Cards in equal columns that keep a useful size: two on phones, up to four on wide windows.
/// Rows take the height of their cards, so captions never get cut.
class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = AppSpace.sm;
      final columns = ((constraints.maxWidth + gap) / (168 + gap))
          .floor()
          .clamp(2, 4);
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final c in children) SizedBox(width: width, child: c)],
      );
    },
  );
}

/// Something a theme card's menu can do.
class ThemeCardAction {
  const ThemeCardAction({
    required this.label,
    required this.icon,
    required this.onSelected,
  });
  final String label;
  final IconData icon;

  /// Gets where the menu was, for share sheets that point at it.
  final void Function(Rect? origin) onSelected;
}

/// A whole look as a card: a small chat in its colors, fonts and background, its name in its own
/// heading font, and its colors as dots. Built-in, saved and gallery themes all look the same, so
/// people choose by what they see, not where a theme came from.
class ThemeCard extends StatelessWidget {
  const ThemeCard({
    super.key,
    required this.name,
    required this.line,
    required this.look,
    required this.selected,
    required this.onTap,
    this.menu = const [],
    this.menuKey,
  });
  final String name;
  final String line;
  final GalleryLook look;
  final bool selected;
  final VoidCallback onTap;
  final List<ThemeCardAction> menu;
  final Key? menuKey;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final brightness = Theme.of(context).brightness;
    final title = context.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 15,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: Material(
        color: context.isDark
            ? scheme.surfaceContainer
            : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: selected ? scheme.primary : context.appColors.hairline,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.tile - 2),
                      child: GalleryChatPreview(
                        look: look,
                        brightness: brightness,
                      ),
                    ),
                    if (selected)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.surface, width: 2),
                          ),
                          child: Icon(
                            LucideIcons.check,
                            size: 13,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(5, 8, menu.isEmpty ? 5 : 0, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: title == null
                                  ? null
                                  : fontStyle(look.headingFont, title),
                            ),
                            Text(
                              line,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SchemeDots(
                        colors: look.scheme.colors(brightness),
                        size: 12,
                      ),
                      if (menu.isNotEmpty)
                        Builder(
                          builder: (context) => PopupMenuButton<int>(
                            key: menuKey,
                            tooltip: MaterialLocalizations.of(context)
                                .showMenuTooltip,
                            icon: Icon(
                              LucideIcons.ellipsis,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                            padding: EdgeInsets.zero,
                            onSelected: (i) =>
                                menu[i].onSelected(shareOrigin(context)),
                            itemBuilder: (_) => [
                              for (final (i, a) in menu.indexed)
                                PopupMenuItem(
                                  value: i,
                                  child: Row(
                                    children: [
                                      Icon(a.icon, size: 18),
                                      const SizedBox(width: AppSpace.sm),
                                      Text(a.label),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A card's shape while the gallery loads.
class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    final fill = context.colorScheme.surfaceContainerHigh;
    return AppCard(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(AppRadius.tile - 2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.6,
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _NameForm extends StatefulWidget {
  const _NameForm();

  @override
  State<_NameForm> createState() => _NameFormState();
}

class _NameFormState extends State<_NameForm> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.bookmarkPlus,
      title: l10n.saveTheme,
      submitLabel: l10n.save,
      submitKey: const Key('saveThemeSubmit'),
      onSubmit: _name.text.trim().isEmpty
          ? null
          : () => Navigator.pop(context, _name.text),
      children: [
        TextField(
          key: const Key('themeName'),
          controller: _name,
          autofocus: true,
          maxLength: 60,
          decoration: InputDecoration(labelText: l10n.themeName),
          onChanged: (_) => setState(() {}),
          onSubmitted: (v) =>
              v.trim().isEmpty ? null : Navigator.pop(context, v),
        ),
      ],
    );
  }
}

class _ImportForm extends StatefulWidget {
  const _ImportForm();

  @override
  State<_ImportForm> createState() => _ImportFormState();
}

class _ImportFormState extends State<_ImportForm> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = _code.text.trim();
    final preset = ThemePreset.fromCode(text);
    return FormSheet(
      icon: LucideIcons.download,
      title: l10n.importTheme,
      subtitle: l10n.themeCodeHelp,
      submitLabel: l10n.importTheme,
      submitKey: const Key('importThemeSubmit'),
      onSubmit: preset == null ? null : () => Navigator.pop(context, preset),
      children: [
        TextField(
          key: const Key('themeCode'),
          controller: _code,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n.themeCode,
            hintText: 'casama-theme:…',
            errorText: text.isNotEmpty && preset == null
                ? l10n.invalidThemeCode
                : null,
            suffixIcon: IconButton(
              tooltip: MaterialLocalizations.of(context).pasteButtonLabel,
              icon: const Icon(LucideIcons.clipboardPaste, size: 20),
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) {
                  setState(() => _code.text = data!.text!);
                }
              },
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (preset != null)
          Text(
            '${preset.name} · ${preset.headingFont} · ${preset.bodyFont}',
            style: context.textTheme.bodyMedium,
          ),
      ],
    );
  }
}
