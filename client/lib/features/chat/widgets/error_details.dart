import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers.dart';
import '../../../core/share.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/adaptive_modal.dart';
import '../chat_controller.dart';
import '../../../ui/glow_button.dart';
import 'chat_widgets.dart' show CodePanel;

const _keyErrors = {
  'model_credential_not_found',
  'model_auth_failed',
  'chatgpt_needs_reconnect',
  'chatgpt_plan_usage_off',
  'chatgpt_plan_not_yours',
  'chatgpt_not_eligible',
};

/// Failures that mean the workspace is out of credits or over its plan: the fix is the plans page.
const limitErrors = {'out_of_credits', 'quota_exceeded', 'cloud_daily_cap', 'computer_hours_exceeded'};

/// A one-tap fix for a failure people can fix themselves: no model, or a missing or rejected key.
/// With no key at all, "no model" also leads to Model keys rather than a model list that's empty.
({String label, String route})? errorFix(BuildContext context, WidgetRef ref, NoticeEntry entry, String botId) {
  final code = entry.errorCode;
  if (entry.kind != NoticeKind.failed || code == null) return null;
  final keys = (route: '/settings/keys', label: context.l10n.addModelKeyTitle);
  if (limitErrors.contains(code)) return (route: '/settings/billing', label: context.l10n.seePlans);
  if (_keyErrors.contains(code)) return keys;
  if (code != 'no_model_configured') return null;
  final hasKeys = ref.read(credentialsProvider).value?.isNotEmpty ?? false;
  return hasKeys ? (route: '/bots/$botId/settings', label: context.l10n.chooseModel) : keys;
}

/// Opens what went wrong in a run: the error, the steps that failed, and ways to copy, export or
/// open the full timeline.
Future<void> showErrorDetails(BuildContext context, {required NoticeEntry entry, required String botId}) => showAdaptiveSheet<void>(
  context: context,
  heightFactor: 0.8,
  dialogMaxWidth: 640,
  builder: (_) => ErrorDetails(entry: entry, botId: botId),
);

class ErrorDetails extends ConsumerWidget {
  const ErrorDetails({super.key, required this.entry, required this.botId});
  final NoticeEntry entry;
  final String botId;

  /// A plain-text report for copying into a bug report or a message.
  static String report(NoticeEntry e, List<RunEventItem> events) {
    final failures = [
      for (final ev in events)
        switch (ev) {
          ToolFailedItem(:final event) => '- ${event.payload.errorCode}: ${event.payload.message}',
          _ => null,
        },
    ].whereType<String>();
    // Intentionally not translated: this report is pasted to support, who read English.
    return [
      'Casama run failed',
      if (e.refId != null) 'Run: ${e.refId}',
      if (e.at != null) 'When: ${e.at!.toUtc().toIso8601String()}',
      if (e.errorCode != null) 'Code: ${e.errorCode}',
      'Message: ${e.text}',
      if (failures.isNotEmpty) ...['Failed steps:', ...failures],
    ].join('\n');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final runId = entry.refId;
    final events = runId == null ? const AsyncValue<List<RunEventItem>>.data([]) : ref.watch(runEventsProvider(runId));
    final list = events.value ?? const <RunEventItem>[];
    final failed = [
      for (final e in list)
        if (e is ToolFailedItem || e is RunFailedItem) e,
    ];
    final text = report(entry, list);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: colors.negative.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
                child: Icon(LucideIcons.circleAlert, color: colors.negative),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.errorDetailsTitle, style: context.textTheme.titleLarge),
                    Text(
                      [if (entry.errorCode != null) entry.errorCode!, if (entry.at != null) relativeTime(entry.at!, context)].join(' · '),
                      style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Expanded(
            child: ListView(
              children: [
                Text(entry.text, style: context.textTheme.bodyLarge?.copyWith(height: 1.45)),
                const SizedBox(height: AppSpace.md),
                if (events.isLoading) const LinearProgressIndicator(),
                for (final e in failed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.xs),
                    child: CodePanel(
                      text: switch (e) {
                        ToolFailedItem(:final event) => '${event.payload.errorCode}\n${event.payload.message}',
                        RunFailedItem(:final event) => '${event.payload.errorCode}\n${event.payload.message}',
                        _ => '',
                      },
                    ),
                  ),
                if (runId != null) ...[
                  const SizedBox(height: AppSpace.xs),
                  SelectableText('Run $runId', style: AppText.mono.copyWith(fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                key: const Key('errorCopy'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) showMessage(context, l10n.copied);
                },
                icon: const Icon(LucideIcons.copy, size: 18),
                label: Text(l10n.copyMessage),
              ),
              Builder(
                builder: (button) => OutlinedButton.icon(
                  key: const Key('errorExport'),
                  onPressed: () {
                    final json = const JsonEncoder.withIndent('  ').convert({
                      'run_id': runId,
                      'error_code': entry.errorCode,
                      'message': entry.text,
                      'at': entry.at?.toUtc().toIso8601String(),
                      'events': [for (final e in list) e.envelope.toJson()],
                    });
                    final name = 'casama-run-${(runId ?? 'error').substring(0, 8)}.json';
                    shareFiles(
                      [XFile.fromData(utf8.encode(json), name: name, mimeType: 'application/json')],
                      names: [name],
                      origin: shareOrigin(button),
                    );
                  },
                  icon: const Icon(LucideIcons.download, size: 18),
                  label: Text(l10n.exportLabel),
                ),
              ),
              if (errorFix(context, ref, entry, botId) case final fix?)
                GlowButton.icon(
                  key: const Key('errorFix'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(fix.route);
                  },
                  icon: const Icon(LucideIcons.keyRound, size: 18),
                  label: Text(fix.label),
                )
              else if (runId != null)
                GlowButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/bots/$botId/runs/$runId');
                  },
                  icon: const Icon(LucideIcons.activity, size: 18),
                  label: Text(l10n.openTimeline),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
