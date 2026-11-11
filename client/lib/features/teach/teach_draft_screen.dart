import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';

/// The draft skill from a teach recording (D-120): wait for the bot's draft, edit it, save it,
/// and try it right away.
class TeachDraftScreen extends ConsumerStatefulWidget {
  const TeachDraftScreen({super.key, required this.sessionId, this.pollEvery = const Duration(seconds: 2)});
  final String sessionId;
  final Duration pollEvery;

  @override
  ConsumerState<TeachDraftScreen> createState() => _TeachDraftScreenState();
}

class _TeachDraftScreenState extends ConsumerState<TeachDraftScreen> {
  TeachSession? _s;
  Object? _error;
  Timer? _poll;
  var _filled = false;
  var _busy = false;
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _body = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _name.dispose();
    _description.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await ref.read(backendProvider).teach(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _s = s;
        _error = null;
        final d = s.draft;
        if (d != null && !_filled) {
          _name.text = d.name;
          _description.text = d.description;
          _body.text = d.body;
          _filled = true;
        }
      });
      _poll?.cancel();
      if (s.status == TeachSessionStatusEnum.drafting || s.status == TeachSessionStatusEnum.recording) _poll = Timer(widget.pollEvery, _load);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _save({required bool tryNow}) async {
    final s = _s;
    if (s == null) return;
    setState(() => _busy = true);
    final r = await runGuarded(context, () => ref.read(backendProvider).saveTeach(s.id, name: _name.text.trim(), description: _description.text.trim(), body: _body.text, tryNow: tryNow));
    if (!mounted) return;
    setState(() => _busy = false);
    if (r == null) return;
    showMessage(context, context.l10n.teachSaved(_name.text.trim()));
    final router = GoRouter.maybeOf(context);
    if (r.conversationId != null) {
      router?.go('/bots/${s.botId}/chat?c=${r.conversationId}');
    } else {
      router?.go('/bots/${s.botId}/settings');
    }
  }

  Future<void> _discard() async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.teachDiscardTitle,
      message: l10n.teachDiscardBody,
      confirmLabel: l10n.discard,
      destructive: true,
      confirmKey: const Key('confirmDiscardTeach'),
    );
    if (!ok || !mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).cancelTeach(widget.sessionId));
    if (mounted) GoRouter.maybeOf(context)?.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = _s;
    final valid = RegExp(r'^[a-z0-9][a-z0-9_-]{0,62}$').hasMatch(_name.text.trim()) && _description.text.trim().isNotEmpty && _body.text.trim().isNotEmpty;
    final Widget body;
    if (_error != null && s == null) {
      body = EmptyState(icon: LucideIcons.triangleAlert, title: l10n.somethingWentWrong, message: errorText(context, _error!));
    } else if (s == null || s.status == TeachSessionStatusEnum.drafting || s.status == TeachSessionStatusEnum.recording) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpace.md),
            Text(l10n.teachDrafting, key: const Key('teachDrafting')),
            if (s != null) Text(l10n.teachSteps(s.steps.length), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    } else if (s.status == TeachSessionStatusEnum.saved) {
      body = EmptyState(icon: LucideIcons.circleCheck, title: l10n.teachAlreadySaved, message: '');
    } else {
      body = PageColumn(
        children: [
          if (s.status == TeachSessionStatusEnum.failed) FormNote(l10n.teachDraftFailed, icon: LucideIcons.triangleAlert) else FormNote(l10n.teachReviewHelp, icon: LucideIcons.sparkles),
          const SizedBox(height: AppSpace.md),
          TextField(
            key: const Key('teachName'),
            controller: _name,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l10n.skillName),
          ),
          const SizedBox(height: AppSpace.sm),
          TextField(
            key: const Key('teachDescription'),
            controller: _description,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l10n.skillDescription),
          ),
          const SizedBox(height: AppSpace.sm),
          TextField(
            key: const Key('teachBody'),
            controller: _body,
            onChanged: (_) => setState(() {}),
            minLines: 8,
            maxLines: 30,
            decoration: InputDecoration(labelText: l10n.skillInstructions, alignLabelWithHint: true),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
          const SizedBox(height: AppSpace.md),
          Text(l10n.teachRecordedSteps(s.steps.length), style: Theme.of(context).textTheme.labelLarge),
          for (final st in s.steps.take(50))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(switch (st.kind) {
                TeachStepKindEnum.click => LucideIcons.mousePointerClick,
                TeachStepKindEnum.type => st.secretName != null ? LucideIcons.keyRound : LucideIcons.keyboard,
                TeachStepKindEnum.key => LucideIcons.cornerDownLeft,
                _ => LucideIcons.arrowDownUp,
              }, size: 18),
              title: Text(teachStepLabel(context, st)),
              subtitle: st.url == null ? null : Text(st.url!, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              FilledButton.icon(
                key: const Key('teachSaveTry'),
                onPressed: !valid || _busy ? null : () => _save(tryNow: true),
                icon: const Icon(LucideIcons.play, size: 18),
                label: Text(l10n.teachSaveAndTry),
              ),
              OutlinedButton(key: const Key('teachSave'), onPressed: !valid || _busy ? null : () => _save(tryNow: false), child: Text(l10n.save)),
              OutlinedButton.icon(
                key: const Key('teachSaveReplay'),
                onPressed: !valid || _busy
                    ? null
                    : () async {
                        final r = await runGuarded(context, () => ref.read(backendProvider).replayFromTeach(s.id, _name.text.trim(), description: _description.text.trim()));
                        if (r != null && context.mounted) showMessage(context, l10n.replaySaved(r.name));
                      },
                icon: const Icon(LucideIcons.listVideo, size: 18),
                label: Text(l10n.saveAsReplay),
              ),
              TextButton(key: const Key('teachDiscard'), onPressed: _busy ? null : _discard, child: Text(l10n.discard)),
            ],
          ),
        ],
      );
    }
    return SubPage(title: l10n.teachDraftTitle, body: body);
  }
}

/// One recorded step in words; secrets show their placeholder, never a value.
String teachStepLabel(BuildContext context, TeachStep s) {
  final l10n = context.l10n;
  return switch (s.kind) {
    TeachStepKindEnum.click => l10n.teachStepClick(s.x ?? 0, s.y ?? 0),
    TeachStepKindEnum.type => s.secretName != null ? l10n.teachStepSecret(s.secretName!) : l10n.teachStepType(s.text ?? ''),
    TeachStepKindEnum.key => l10n.teachStepKey(s.key ?? ''),
    _ => l10n.teachStepScroll,
  };
}
