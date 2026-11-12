import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/display_text.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/form_sheet.dart';
import '../../ui/glow_button.dart';
import '../../ui/page.dart';
import '../routines/cron_words.dart';
import 'model_picker.dart';
import '../../ui/celebration.dart';
import '../../core/analytics.dart';

/// Share a bot as a template (D-110): a file or a link with its instructions, skills, routines and
/// suggested connections. Never secrets; memories only when chosen. Importing previews first.

Future<void> showShareBot(BuildContext context, Bot bot) =>
    showAdaptiveSheet<void>(
      context: context,
      builder: (_) => _ShareSheet(bot: bot),
    );

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet({required this.bot});
  final Bot bot;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  var _memories = false;
  String? _link;
  var _busy = false;

  Future<void> _saveFile() async {
    setState(() => _busy = true);
    final t = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .exportBot(widget.bot.id, memories: _memories),
    );
    if (t != null) {
      final name =
          '${widget.bot.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}.casama-bot.json';
      try {
        await FilePicker.saveFile(
          fileName: name,
          bytes: Uint8List.fromList(
            utf8.encode(const JsonEncoder.withIndent('  ').convert(t.toJson())),
          ),
          mimeType: 'application/json',
        );
      } catch (_) {}
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _makeLink() async {
    Analytics.feature('share_template');
    setState(() => _busy = true);
    final link = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .createBotShare(widget.bot.id, memories: _memories),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _link = link?.url;
    });
    if (link != null) {
      try {
        await Clipboard.setData(ClipboardData(text: link.url));
        if (mounted) showMessage(context, context.l10n.linkCopied);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.share2,
      title: l10n.shareAsTemplate,
      subtitle: l10n.shareAsTemplateHelp,
      submitLabel: l10n.copyLink,
      submitKey: const Key('makeShareLink'),
      onSubmit: _busy ? null : _makeLink,
      children: [
        CheckboxListTile(
          key: const Key('shareMemories'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.includeMemories),
          subtitle: Text(l10n.includeMemoriesHelp),
          value: _memories,
          onChanged: hapticOnChanged(
            (v) => setState(() => _memories = v ?? false),
            haptic: HapticsHelper.soft,
          ),
        ),
        OutlinedButton.icon(
          key: const Key('saveTemplateFile'),
          onPressed: _busy ? null : _saveFile,
          icon: const Icon(LucideIcons.download, size: 18),
          label: Text(l10n.saveAsFile),
        ),
        if (_link != null)
          SelectableText(
            _link!,
            key: const Key('shareLink'),
            style: AppText.mono.copyWith(fontSize: 12),
          ),
      ],
    );
  }
}

/// Opens a template file and shows the import preview.
Future<void> importBotFromFile(BuildContext context) async {
  final picked = await FilePicker.pickFiles();
  if (picked.isEmpty || !context.mounted) return;
  try {
    final json = jsonDecode(utf8.decode(await picked.first.readAsBytes()));
    final t = BotTemplateFile.fromJson(json as Map<String, dynamic>);
    if (t.format != BotTemplateFileFormatEnum.casamaPeriodBot) {
      throw const FormatException();
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/import/file'),
        builder: (_) => ImportBotScreen(template: t),
      ),
    );
  } catch (_) {
    if (context.mounted) showWarning(context, context.l10n.notABotTemplate);
  }
}

/// The import preview: from a file ([template]) or a share link ([token]).
class ImportBotScreen extends ConsumerStatefulWidget {
  const ImportBotScreen({super.key, this.template, this.token});
  final BotTemplateFile? template;
  final String? token;

  @override
  ConsumerState<ImportBotScreen> createState() => _ImportBotScreenState();
}

class _ImportBotScreenState extends ConsumerState<ImportBotScreen> {
  late final Future<BotTemplateFile> _template = widget.template != null
      ? Future.value(widget.template)
      : ref.read(backendProvider).getBotShare(widget.token!);
  String? _credentialId;
  String _model = '';
  var _memories = true;
  var _routines = true;
  var _busy = false;

  Future<void> _import(BotTemplateFile t) async {
    final org = ref.read(currentOrgProvider);
    if (org == null || _credentialId == null || _model.isEmpty) return;
    setState(() => _busy = true);
    final r = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .importBot(
            org.id,
            t,
            credentialId: _credentialId!,
            model: _model,
            memories: _memories,
            routines: _routines,
          ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (r == null) return;
    ref.invalidate(botsProvider);
    final l10n = context.l10n;
    showCelebration(
      context,
      r.connectionsToAdd.isEmpty
          ? l10n.botImported(t.name)
          : l10n.botImportedConnect(
              t.name,
              r.connectionsToAdd.map((c) => c.name).join(', '),
            ),
    );
    GoRouter.maybeOf(context)?.go('/bots/${r.botId}/chat');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final keys = ref.watch(credentialsProvider).value ?? const <Credential>[];
    _credentialId ??= preferredKeyId(ref, keys);
    // Casama Cloud chooses the key and the model (D-188): the fields are not shown.
    final fixedModel = casamaModelFixed(ref);
    if (_model.isEmpty) {
      final key = keys.where((k) => k.id == _credentialId).firstOrNull;
      if (key != null) {
        _model =
            ref.read(backendProvider).defaultModelFor(key.provider.value) ?? '';
      }
    }
    return FutureBuilder<BotTemplateFile>(
      future: _template,
      builder: (context, snap) {
        final t = snap.data;
        return SubPage(
          title: l10n.importBot,
          children: [
            if (snap.hasError)
              FormNote(
                errorText(context, snap.error!),
                icon: LucideIcons.triangleAlert,
              ),
            if (t == null && !snap.hasError) const _ImportPreviewSkeleton(),
            if (t != null) ...[
              AppCard(
                key: const Key('importPreview'),
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.sm,
                  children: [
                    Row(
                      children: [
                        BotAvatar(name: t.name, avatar: t.avatar, size: 48),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Text(
                            t.name,
                            style: context.textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    if (t.description.isUsable) Text(t.description!),
                    Text(
                      t.personaMd,
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SectionHeader(title: l10n.whatComesWithIt),
              GroupedCard(
                children: [
                  for (final k
                      in t.skills ?? const <BotTemplateFileSkillsInner>[])
                    GroupedTile(
                      icon: LucideIcons.bookOpen,
                      title: k.name,
                      subtitle: k.description,
                    ),
                  for (final r
                      in t.routines ?? const <BotTemplateFileRoutinesInner>[])
                    GroupedTile(
                      icon: LucideIcons.clock,
                      title: r.name,
                      subtitle: scheduleWords(context, r.scheduleCron),
                    ),
                  for (final c
                      in t.connections ??
                          const <BotTemplateFileConnectionsInner>[])
                    GroupedTile(
                      icon: LucideIcons.plug,
                      title: c.name,
                      subtitle: l10n.connectAfterImport,
                    ),
                ],
              ),
              if ((t.routines ?? const []).isNotEmpty)
                SwitchListTile(
                  key: const Key('importRoutines'),
                  title: Text(l10n.importRoutines),
                  value: _routines,
                  onChanged: hapticOnChanged(
                    (v) => setState(() => _routines = v),
                  ),
                ),
              if ((t.memories ?? const []).isNotEmpty)
                SwitchListTile(
                  key: const Key('importMemories'),
                  title: Text(
                    l10n.importMemories((t.memories ?? const []).length),
                  ),
                  value: _memories,
                  onChanged: hapticOnChanged(
                    (v) => setState(() => _memories = v),
                  ),
                ),
              if (!fixedModel) SectionHeader(title: l10n.thinking0),
              if (!fixedModel)
              DropdownButtonFormField<String>(
                key: const Key('importKey'),
                initialValue: _credentialId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.modelKey),
                items: [
                  for (final k in keys)
                    DropdownMenuItem(value: k.id, child: Text(k.label)),
                ],
                onChanged: hapticOnChanged(
                  (v) => setState(() {
                    _credentialId = v;
                    _model = '';
                  }),
                  haptic: HapticsHelper.selection,
                ),
              ),
              if (!fixedModel) const SizedBox(height: AppSpace.sm),
              if (!fixedModel)
              ModelPickerField(
                credentialId: _credentialId,
                value: _model,
                onChanged: (m) => setState(() => _model = m),
              ),
              const SizedBox(height: AppSpace.lg),
              GlowButton.icon(
                key: const Key('importBot'),
                onPressed: _busy || _credentialId == null || _model.isEmpty
                    ? null
                    : () => _import(t),
                icon: const Icon(LucideIcons.download, size: 18),
                label: Text(l10n.importBot),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The import preview while the template loads: the bot's card (avatar, name, description and
/// instructions), then the header over a card of what comes with it, in the real sizes.
class _ImportPreviewSkeleton extends StatelessWidget {
  const _ImportPreviewSkeleton();

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return SkeletonScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonCard(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.sm,
              children: [
                Row(
                  children: [
                    const SkeletonBone(width: 48, height: 48, radius: 24),
                    const SizedBox(width: AppSpace.md),
                    Expanded(child: SkeletonText(style: text.titleLarge, widthFactor: 0.5)),
                  ],
                ),
                const SkeletonText(widthFactor: 0.8),
                const SkeletonText(lines: 4, widthFactor: 0.9),
              ],
            ),
          ),
          const SkeletonSectionHeader(width: 140),
          const SkeletonGroupedCard(row: SkeletonRow(trailing: SkeletonTrailing.none)),
        ],
      ),
    );
  }
}
