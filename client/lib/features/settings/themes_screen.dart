import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/share.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../../theme/appearance.dart';
import '../../theme/presets.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/glow_button.dart';
import '../../ui/page.dart';
import '../../ui/shell_header.dart';
import 'appearance_preview.dart';
import 'gallery_screen.dart';
import 'theme_screen.dart' show SchemeDots;

/// Settings → Themes: presets that set scheme, fonts and background at once, the themes this
/// person saved, and sharing or importing a theme as a code (D-087).
class ThemesScreen extends ConsumerWidget {
  const ThemesScreen({super.key});

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final name = await showAdaptiveSheet<String>(
      context: context,
      builder: (_) => const _NameForm(),
    );
    if (name == null || name.trim().isEmpty) return;
    await ref
        .read(savedThemesProvider.notifier)
        .save(name.trim(), ref.read(appearanceProvider));
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final preset = await showAdaptiveSheet<ThemePreset>(
      context: context,
      builder: (_) => const _ImportForm(),
    );
    if (preset == null || !context.mounted) return;
    await ref.read(savedThemesProvider.notifier).add(preset);
    await ref.read(appearanceProvider.notifier).applyPreset(preset);
    if (context.mounted) {
      showSuccess(context, context.l10n.themeImported(preset.name));
    }
  }

  Future<void> _share(
    BuildContext context,
    ThemePreset preset,
    Rect? origin,
  ) async {
    final code = preset.toCode();
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) showMessage(context, context.l10n.themeCodeCopied);
    await shareText(code, origin: origin);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final appearance = ref.watch(appearanceProvider);
    final saved = ref.watch(savedThemesProvider);
    final notifier = ref.read(appearanceProvider.notifier);
    final custom = ![
      ...builtInPresets,
      ...saved,
    ].any((p) => p.matches(appearance));

    Widget grid(List<ThemePreset> presets) => LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 170).floor().clamp(2, 4);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpace.sm,
            crossAxisSpacing: AppSpace.sm,
            childAspectRatio: 1.05,
          ),
          itemCount: presets.length,
          itemBuilder: (context, i) {
            final p = presets[i];
            return _PresetTile(
              preset: p,
              selected: p.matches(appearance),
              onTap: () => notifier.applyPreset(p),
              onShare: (origin) => _share(context, p, origin),
              onDelete: p.builtIn
                  ? null
                  : () async {
                      final ok = await showConfirm(
                        context: context,
                        title: l10n.deleteThemeTitle(p.name),
                        confirmLabel: l10n.delete,
                        destructive: true,
                      );
                      if (ok) {
                        await ref
                            .read(savedThemesProvider.notifier)
                            .remove(p.id);
                      }
                    },
            );
          },
        );
      },
    );

    return SubPage(
      title: l10n.themes,
      actions: [
        HeaderIconButton(
          icon: LucideIcons.download,
          tooltip: l10n.importTheme,
          onPressed: () => _import(context, ref),
        ),
      ],
      children: [
        const AppearancePreview(),
        const SizedBox(height: AppSpace.sm),
        FormNote(l10n.themesHelp),
        SectionHeader(title: l10n.themePresets),
        grid(builtInPresets),
        SectionHeader(
          title: l10n.myThemes,
          count: saved.isEmpty ? null : "${saved.length}",
        ),
        if (saved.isNotEmpty) ...[
          grid(saved),
          const SizedBox(height: AppSpace.md),
        ],
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            GlowButton.icon(
              key: const Key('saveTheme'),
              onPressed: custom ? () => _save(context, ref) : null,
              icon: const Icon(LucideIcons.bookmarkPlus, size: 18),
              label: Text(l10n.saveTheme),
            ),
            OutlinedButton.icon(
              key: const Key('importTheme'),
              onPressed: () => _import(context, ref),
              icon: const Icon(LucideIcons.download, size: 18),
              label: Text(l10n.importTheme),
            ),
            OutlinedButton.icon(
              key: const Key('openGallery'),
              onPressed: () => context.push('/settings/gallery?type=theme'),
              icon: const Icon(LucideIcons.layoutGrid, size: 18),
              label: Text(l10n.gallery),
            ),
            OutlinedButton.icon(
              key: const Key('shareToGallery'),
              onPressed: () {
                final look = ref.read(appearanceProvider);
                final code = ThemePreset.fromAppearance(
                  look,
                  id: 'shared',
                  name: l10n.myThemes,
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
        const SizedBox(height: AppSpace.lg),
        GroupedCard(
          children: [
            GroupedTile(
              icon: LucideIcons.palette,
              title: l10n.colorScheme,
              subtitle: appearance.scheme.name,
              onTap: () => context.push('/settings/theme'),
            ),
            GroupedTile(
              icon: LucideIcons.type,
              title: l10n.fonts,
              subtitle: '${appearance.headingFont} · ${appearance.bodyFont}',
              onTap: () => context.push('/settings/fonts'),
            ),
            GroupedTile(
              icon: LucideIcons.image,
              title: l10n.background,
              subtitle: appearance.wallpaper.pattern.label,
              onTap: () => context.push('/settings/background'),
            ),
          ],
        ),
      ],
    );
  }
}

/// A preset drawn in its own scheme, fonts and wallpaper.
class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
    required this.onShare,
    this.onDelete,
  });
  final ThemePreset preset;
  final bool selected;
  final VoidCallback onTap;
  final void Function(Rect? origin) onShare;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final outer = context.colorScheme;
    final dark = context.isDark;
    final look = Appearance(
      schemeId: preset.schemeId,
      headingFont: preset.headingFont,
      bodyFont: preset.bodyFont,
      wallpaper: preset.wallpaper,
    );
    final theme = dark ? AppTheme.dark(look) : AppTheme.light(look);
    return Semantics(
      button: true,
      selected: selected,
      label: preset.name,
      child: Material(
        color: dark ? outer.surfaceContainer : outer.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? outer.primary : context.appColors.hairline,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('preset-${preset.id}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Theme(
                    data: theme,
                    child: const AppearancePreview(
                      compact: true,
                      height: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preset.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily:
                                  theme.textTheme.headlineSmall?.fontFamily,
                              color: outer.onSurface,
                            ),
                          ),
                          Text(
                            preset.headingFont == preset.bodyFont
                                ? preset.bodyFont
                                : '${preset.headingFont} · ${preset.bodyFont}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: outer.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SchemeDots(
                      colors: look.scheme.colors(theme.brightness),
                      size: 12,
                    ),
                    if (selected) ...[
                      const SizedBox(width: 6),
                      Icon(
                        LucideIcons.circleCheck,
                        size: 18,
                        color: outer.primary,
                      ),
                    ],
                    Builder(
                      builder: (context) => PopupMenuButton<String>(
                        key: Key('presetMenu-${preset.id}'),
                        icon: Icon(
                          LucideIcons.ellipsis,
                          size: 18,
                          color: outer.onSurfaceVariant,
                        ),
                        padding: EdgeInsets.zero,
                        onSelected: (v) => v == 'share'
                            ? onShare(shareOrigin(context))
                            : onDelete?.call(),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'share',
                            child: Text(context.l10n.shareTheme),
                          ),
                          if (onDelete != null)
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(context.l10n.delete),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
