import 'dart:convert';

import 'package:casama_sdk/casama_sdk.dart' show CatalogApp;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/backend.dart';
import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/action_buttons.dart';
import '../../../ui/adaptive_modal.dart';
import '../../../ui/glow_button.dart';
import '../../../ui/lucide_names.dart';
import '../../gallery/gallery_install.dart';
import '../../integrations/app_logo.dart';
import 'chat_look.dart';

/// What was done with each gallery card in one conversation (D-315), by card key: `dismissed`
/// (Not now), `added`, `saved`, `submitted`. Kept on this device, so a card stays put away after a
/// reload without the server knowing.
class GalleryCardMarks extends Notifier<Map<String, Set<String>>> {
  GalleryCardMarks(this.conversationId);
  final String conversationId;

  String get _prefKey => 'gallery_cards.$conversationId';

  @override
  Map<String, Set<String>> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_prefKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final loaded = {
        for (final e in decoded.entries)
          if (e.value is List)
            '${e.key}': {for (final v in e.value as List) '$v'},
      };
      // Marks made while loading win over the stored ones.
      state = {
        ...loaded,
        for (final e in state.entries) e.key: {...?loaded[e.key], ...e.value},
      };
    } catch (_) {
      // No storage (tests, private windows): marks last for this session only.
    }
  }

  void mark(String cardKey, String what) {
    state = {
      ...state,
      cardKey: {...?state[cardKey], what},
    };
    final snapshot = {for (final e in state.entries) e.key: e.value.toList()};
    SharedPreferences.getInstance()
        .then((p) => p.setString(_prefKey, jsonEncode(snapshot)))
        .catchError((_) => false);
  }
}

final galleryCardMarksProvider =
    NotifierProvider.family<GalleryCardMarks, Map<String, Set<String>>, String>(
      GalleryCardMarks.new,
    );

/// Runs the install flow for one gallery item; true once it is installed (or waiting for approval).
typedef GalleryInstallFlow = Future<bool> Function(
  BuildContext context,
  WidgetRef ref, {
  required String type,
  required String id,
});

/// The icon for a gallery kind, when the item names none we know.
IconData galleryKindIcon(String type) => switch (type) {
  'app' => LucideIcons.plug,
  'skill' => LucideIcons.bookOpen,
  'routine' => LucideIcons.repeat,
  'bot' => LucideIcons.bot,
  'plugin' => LucideIcons.puzzle,
  'theme' || 'scheme' => LucideIcons.palette,
  'wallpaper' => LucideIcons.image,
  'set' => LucideIcons.package,
  _ => LucideIcons.sparkles,
};

/// One short line of what an item can touch and needs: "Reads email, calendar · Sends email ·
/// Runs code · Needs Gmail". Empty when the item says nothing.
String galleryAccessLine(
  BuildContext context, {
  GalleryAccess? access,
  GalleryNeeds? needs,
  Map<String, String> appNames = const {},
}) {
  final l10n = context.l10n;
  String cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
  return [
    if (access != null && access.reads.isNotEmpty)
      l10n.galleryChatReads(access.reads.join(', ')),
    if (access != null && access.writes.isNotEmpty)
      cap(access.writes.join(', ')),
    if (access != null && access.runsCode) l10n.galleryChatRunsCode,
    if (access != null && access.computer && !access.runsCode)
      l10n.galleryChatComputer,
    if (needs != null && needs.apps.isNotEmpty)
      l10n.galleryChatNeeds(
        [for (final a in needs.apps) appNames[a] ?? a].join(', '),
      ),
  ].join(' · ');
}

/// The card frame gallery cards share with the chat's other cards (D-256): an icon and a small
/// label up top, a bold title, grey text, then the rest.
class _GalleryCardFrame extends StatelessWidget {
  const _GalleryCardFrame({
    super.key,
    required this.leading,
    required this.label,
    required this.title,
    required this.children,
    required this.footer,
  });

  final Widget leading;
  final String label;
  final String title;
  final List<Widget> children;
  final Widget footer;

  @override
  Widget build(BuildContext context) => Container(
    padding: ChatLook.cardPadding,
    decoration: ChatLook.card(context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        ...children,
        const SizedBox(height: 14),
        footer,
      ],
    ),
  );
}

Widget _iconBox(BuildContext context, IconData icon, Color color) => Container(
  width: 30,
  height: 30,
  decoration: BoxDecoration(
    color: ChatLook.fieldFill(context),
    borderRadius: BorderRadius.circular(9),
  ),
  alignment: Alignment.center,
  child: Icon(icon, size: 17, color: color),
);

/// A finished card folded into one quiet line.
class _DoneLine extends StatelessWidget {
  const _DoneLine({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
  });
  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

/// A gallery item the bot suggests (D-315, `gallery.suggest`): what it is, why the bot thinks it
/// helps, what it can touch, and **Add** (the install flow, with its questions and needs) or
/// **Not now**, which puts it away for this conversation.
class GallerySuggestionCard extends ConsumerStatefulWidget {
  const GallerySuggestionCard({
    super.key,
    required this.part,
    required this.conversationId,
    this.install = showGalleryInstall,
  });

  final GallerySuggestionPart part;

  /// The install flow Add runs (the gallery's wizard; tests put in their own).
  final GalleryInstallFlow install;

  /// Where Not now and Add are remembered; null before the chat exists (then only for now).
  final String? conversationId;

  @override
  ConsumerState<GallerySuggestionCard> createState() =>
      _GallerySuggestionCardState();
}

class _GallerySuggestionCardState extends ConsumerState<GallerySuggestionCard> {
  var _busy = false;
  final _local = <String>{};

  Set<String> _marks() => {
    ..._local,
    if (widget.conversationId case final c?)
      ...?ref.watch(galleryCardMarksProvider(c))[widget.part.key],
  };

  void _mark(String what) {
    setState(() => _local.add(what));
    if (widget.conversationId case final c?) {
      ref
          .read(galleryCardMarksProvider(c).notifier)
          .mark(widget.part.key, what);
    }
  }

  Future<void> _add() async {
    setState(() => _busy = true);
    final p = widget.part;
    final ok = await widget.install(context, ref, type: p.type, id: p.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) _mark('added');
  }

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: AppMotion.of(context, AppMotion.duration),
    curve: AppMotion.curve,
    alignment: AlignmentDirectional.topStart,
    child: AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.fast),
      child: _content(context),
    ),
  );

  Widget _content(BuildContext context) {
    final l10n = context.l10n;
    final p = widget.part;
    final marks = _marks();
    if (marks.contains('added')) {
      return _DoneLine(
        key: Key('gallerySuggestionAdded-${p.key}'),
        text: l10n.galleryChatAdded(p.name),
        icon: LucideIcons.circleCheck,
        color: context.appColors.positive,
      );
    }
    if (marks.contains('dismissed')) {
      return SizedBox.shrink(key: Key('gallerySuggestionHidden-${p.key}'));
    }
    final scheme = context.colorScheme;
    final appNames = {
      for (final a
          in ref.watch(appCatalogProvider).value?.apps ?? const <CatalogApp>[])
        a.id: a.name,
    };
    final access = galleryAccessLine(
      context,
      access: p.access,
      needs: p.needs,
      appNames: appNames,
    );
    final grey = context.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.4,
    );
    return _GalleryCardFrame(
      key: Key('gallerySuggestion-${p.key}'),
      leading: p.type == 'app'
          ? AppLogo(appId: p.id, name: p.name, size: 30)
          : _iconBox(
              context,
              lucideByName(p.icon) ?? galleryKindIcon(p.type),
              scheme.primary,
            ),
      label: l10n.galleryChatSuggestionLabel,
      title: p.name,
      footer: ActionButtons(
        actions: [
          OutlinedButton(
            key: Key('gallerySuggestionNotNow-${p.key}'),
            onPressed: _busy ? null : () => _mark('dismissed'),
            child: Text(l10n.notNow),
          ),
          GlowButton.icon(
            key: Key('gallerySuggestionAdd-${p.key}'),
            onPressed: _busy ? null : _add,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: Text(l10n.galleryChatAdd),
          ),
        ],
      ),
      children: [
        if (p.description?.trim() case final d? when d.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              d,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: grey,
            ),
          ),
        if (p.reason.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    LucideIcons.sparkles,
                    size: 15,
                    color: context.appColors.working,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.reason.trim(),
                    style: context.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        if (access.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    LucideIcons.shieldCheck,
                    size: 15,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    access,
                    key: Key('gallerySuggestionAccess-${p.key}'),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A skill the bot drafted from the chat (D-315, `gallery.draft_skill`): its name, description
/// and instructions (folded), with **Save to my skills** and **Submit to the gallery**.
class GalleryDraftCard extends ConsumerStatefulWidget {
  const GalleryDraftCard({
    super.key,
    required this.part,
    required this.conversationId,
  });

  final GalleryDraftPart part;
  final String? conversationId;

  @override
  ConsumerState<GalleryDraftCard> createState() => _GalleryDraftCardState();
}

class _GalleryDraftCardState extends ConsumerState<GalleryDraftCard> {
  var _busy = false;
  var _open = false;
  final _local = <String>{};

  Set<String> _marks() => {
    ..._local,
    if (widget.conversationId case final c?)
      ...?ref.watch(galleryCardMarksProvider(c))[widget.part.key],
  };

  void _mark(String what) {
    setState(() => _local.add(what));
    if (widget.conversationId case final c?) {
      ref
          .read(galleryCardMarksProvider(c).notifier)
          .mark(widget.part.key, what);
    }
  }

  Future<void> _save() async {
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId == null) return;
    final p = widget.part;
    final l10n = context.l10n;
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref
          .read(backendProvider)
          .saveSkill(
            orgId,
            name: p.skillName,
            description: p.description,
            bodyMd: p.instructions,
          );
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok != true) return;
    ref.invalidate(skillsProvider);
    _mark('saved');
    showSuccess(context, l10n.galleryChatSavedSkill);
  }

  Future<void> _submit() async {
    final p = widget.part;
    final l10n = context.l10n;
    final yes = await showConfirm(
      context: context,
      title: l10n.galleryChatSubmitTitle(p.name),
      message: l10n.galleryChatSubmitBody,
      confirmLabel: l10n.galleryChatSubmit,
      icon: LucideIcons.send,
      confirmKey: const Key('galleryDraftSubmitConfirm'),
    );
    if (!yes || !mounted) return;
    setState(() => _busy = true);
    final files = p.files.isNotEmpty ? p.files : {'SKILL.md': _skillMd(p)};
    final item = {...p.item, 'name': p.name, 'description': p.description}
      ..remove('instructions_md');
    var off = false;
    final ok = await runGuarded(context, () async {
      try {
        await ref
            .read(backendProvider)
            .submitToGallery(type: p.type, id: p.id, item: item, files: files);
      } on DioException catch (e) {
        final body = e.response?.data;
        if (e.response?.statusCode == 503 ||
            (body is Map && body['code'] == 'submissions_off')) {
          off = true;
          return false;
        }
        rethrow;
      }
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (off) {
      showToast(context, l10n.galleryChatSubmissionsOff);
      return;
    }
    if (ok != true) return;
    _mark('submitted');
    showSuccess(context, l10n.galleryChatSubmitted);
  }

  static String _skillMd(GalleryDraftPart p) {
    final desc = p.description.replaceAll('\n', ' ');
    return '---\nname: ${p.skillName}\ndescription: $desc\n---\n\n${p.instructions}\n';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final p = widget.part;
    final marks = _marks();
    final saved = marks.contains('saved');
    // Kept loaded for Save.
    ref.watch(currentOrgIdProvider);
    final submitted = marks.contains('submitted');
    final instructions = p.instructions;
    return _GalleryCardFrame(
      key: Key('galleryDraft-${p.key}'),
      leading: _iconBox(context, LucideIcons.bookOpen, scheme.primary),
      label: l10n.galleryChatDraftLabel,
      title: p.name,
      footer: ActionButtons(
        actions: [
          OutlinedButton.icon(
            key: const Key('galleryDraftSubmit'),
            onPressed: _busy || submitted ? null : _submit,
            icon: Icon(
              submitted ? LucideIcons.check : LucideIcons.send,
              size: 16,
            ),
            label: Text(
              submitted ? l10n.galleryChatSent : l10n.galleryChatSubmit,
            ),
          ),
          GlowButton.icon(
            key: const Key('galleryDraftSave'),
            onPressed: _busy || saved ? null : _save,
            icon: Icon(
              saved ? LucideIcons.check : LucideIcons.bookmarkPlus,
              size: 18,
            ),
            label: Text(
              saved ? l10n.galleryChatSaved : l10n.galleryChatSaveSkill,
            ),
          ),
        ],
      ),
      children: [
        if (p.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              p.description,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        if (instructions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('galleryDraftToggle'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () => setState(() => _open = !_open),
              icon: Icon(
                _open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 16,
              ),
              label: Text(
                _open
                    ? l10n.galleryChatHideInstructions
                    : l10n.galleryChatShowInstructions,
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.of(context, AppMotion.duration),
            curve: AppMotion.curve,
            alignment: AlignmentDirectional.topStart,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Container(
                    key: const Key('galleryDraftInstructions'),
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 260),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ChatLook.fieldFill(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        instructions,
                        style: context.textTheme.bodySmall?.copyWith(
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}

/// The card for one gallery part.
class GalleryChatCard extends StatelessWidget {
  const GalleryChatCard({
    super.key,
    required this.part,
    required this.conversationId,
  });
  final GalleryChatPart part;
  final String? conversationId;

  @override
  Widget build(BuildContext context) => switch (part) {
    final GallerySuggestionPart p => GallerySuggestionCard(
      part: p,
      conversationId: conversationId,
    ),
    final GalleryDraftPart p => GalleryDraftCard(
      part: p,
      conversationId: conversationId,
    ),
  };
}
