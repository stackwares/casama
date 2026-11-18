import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';

/// Reporting and blocking (D-301): the store rules for apps with content people didn't write
/// themselves, including what an AI says. A report reaches the people who run the server; blocking
/// stops invites from someone and hides them.

String reportReasonLabel(BuildContext context, ReportReason r) => switch (r) {
  ReportReason.spam => context.l10n.reportReasonSpam,
  ReportReason.sexual => context.l10n.reportReasonSexual,
  ReportReason.violence => context.l10n.reportReasonViolence,
  ReportReason.harassment => context.l10n.reportReasonHarassment,
  ReportReason.illegal => context.l10n.reportReasonIllegal,
  ReportReason.impersonation => context.l10n.reportReasonImpersonation,
  ReportReason.other => context.l10n.reportReasonOther,
};

/// Opens the report sheet. [blockUserId] offers "Also block {blockName}" (on by default).
Future<void> showReportSheet(
  BuildContext context, {
  required ReportTarget kind,
  required String targetId,
  String? blockUserId,
  String? blockName,
}) => showAdaptiveSheet<void>(
  context: context,
  dialogMaxWidth: 520,
  builder: (_) => ReportSheet(
    kind: kind,
    targetId: targetId,
    blockUserId: blockUserId,
    blockName: blockName,
  ),
);

class ReportSheet extends ConsumerStatefulWidget {
  const ReportSheet({
    super.key,
    required this.kind,
    required this.targetId,
    this.blockUserId,
    this.blockName,
  });
  final ReportTarget kind;
  final String targetId;
  final String? blockUserId;
  final String? blockName;

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  ReportReason? _reason;
  final _note = TextEditingController();
  var _block = true;
  var _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      final backend = ref.read(backendProvider);
      await backend.report(
        widget.kind,
        widget.targetId,
        reason,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      final blockId = widget.blockUserId;
      if (blockId != null && _block && widget.kind != ReportTarget.user) {
        await backend.block(blockId);
      }
      ref.invalidate(blockedPeopleProvider);
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok != true) return;
    Navigator.pop(context);
    showSuccess(context, l10n.reportSent);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = switch (widget.kind) {
      ReportTarget.message => l10n.reportReply,
      ReportTarget.bot => l10n.reportBot,
      ReportTarget.user => l10n.reportPerson,
      ReportTarget.galleryItem => l10n.reportGalleryItem,
      ReportTarget.galleryRequest => l10n.reportGalleryRequest,
      ReportTarget.workspace => l10n.reportWorkspace,
      ReportTarget.packShare => l10n.reportPackShare,
    };
    return FormSheet(
      icon: LucideIcons.flag,
      iconColor: context.appColors.warning,
      title: title,
      subtitle: widget.kind == ReportTarget.user
          ? l10n.reportPersonHelp
          : l10n.reportHelp,
      submitLabel: widget.kind == ReportTarget.user
          ? l10n.reportAndBlock
          : l10n.report,
      submitKey: const Key('reportSend'),
      busy: _busy,
      onSubmit: _reason == null ? null : _send,
      children: [
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: [
            for (final r in ReportReason.values)
              ChoiceChip(
                key: Key('reportReason-${r.value}'),
                label: Text(reportReasonLabel(context, r)),
                selected: _reason == r,
                showCheckmark: false,
                onSelected: (_) {
                  HapticsHelper.light();
                  setState(() => _reason = r);
                },
              ),
          ],
        ),
        TextField(
          key: const Key('reportNote'),
          controller: _note,
          minLines: 2,
          maxLines: 5,
          maxLength: 2000,
          buildCounter: (
            _, {
            required currentLength,
            required isFocused,
            maxLength,
          }) => null,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.reportNote,
            alignLabelWithHint: true,
          ),
        ),
        if (widget.blockUserId != null && widget.kind != ReportTarget.user)
          SwitchListTile(
            key: const Key('reportAlsoBlock'),
            contentPadding: EdgeInsets.zero,
            value: _block,
            onChanged: (v) => setState(() => _block = v),
            title: Text(
              l10n.reportAlsoBlock(widget.blockName ?? l10n.thisPerson),
            ),
            subtitle: Text(l10n.blockHelp),
          ),
      ],
    );
  }
}

/// What you can do about another person: block them, or report them (which also blocks).
Future<void> showPersonActions(
  BuildContext context, {
  required String userId,
  required String name,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (sheet) => Consumer(
    builder: (sheet, ref, _) {
      final l10n = sheet.l10n;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                0,
                AppSpace.lg,
                AppSpace.sm,
              ),
              child: Text(name, style: sheet.textTheme.titleMedium),
            ),
            ListTile(
              key: const Key('personBlock'),
              leading: const Icon(LucideIcons.userX),
              title: Text(l10n.blockPerson(name)),
              subtitle: Text(l10n.blockHelp),
              onTap: () async {
                Navigator.pop(sheet);
                final ok = await runGuarded(context, () async {
                  await ref.read(backendProvider).block(userId);
                  return true;
                });
                ref.invalidate(blockedPeopleProvider);
                if (ok == true && context.mounted) {
                  showSuccess(context, l10n.blocked(name));
                }
              },
            ),
            ListTile(
              key: const Key('personReport'),
              leading: Icon(LucideIcons.flag, color: sheet.appColors.warning),
              title: Text(l10n.reportPerson),
              onTap: () {
                Navigator.pop(sheet);
                showReportSheet(
                  context,
                  kind: ReportTarget.user,
                  targetId: userId,
                );
              },
            ),
            const SizedBox(height: AppSpace.sm),
          ],
        ),
      );
    },
  ),
);

final blockedPeopleProvider = FutureProvider.autoDispose<List<BlockedPerson>>(
  (ref) => ref.watch(backendProvider).blockedPeople(),
);

/// Settings > Privacy > Blocked people: who you blocked, and unblocking.
class BlockedPeopleScreen extends ConsumerWidget {
  const BlockedPeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SubPage(
      title: l10n.blockedPeople,
      body: AsyncView<List<BlockedPerson>>(
        value: ref.watch(blockedPeopleProvider),
        onRetry: () => ref.invalidate(blockedPeopleProvider),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: LucideIcons.userCheck,
                title: l10n.noBlockedPeople,
                message: l10n.blockHelp,
              )
            : PageColumn(
                children: [
                  FormNote(l10n.blockHelp, icon: LucideIcons.info),
                  GroupedCard(
                    children: [
                      for (final b in items)
                        GroupedTile(
                          key: Key('blocked-${b.userId}'),
                          icon: LucideIcons.userX,
                          title: b.name,
                          showChevron: false,
                          trailing: TextButton(
                            key: Key('unblock-${b.userId}'),
                            onPressed: () async {
                              final ok = await runGuarded(context, () async {
                                await ref
                                    .read(backendProvider)
                                    .unblock(b.userId);
                                return true;
                              });
                              if (ok == true) {
                                ref.invalidate(blockedPeopleProvider);
                              }
                            },
                            child: Text(l10n.unblock),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
