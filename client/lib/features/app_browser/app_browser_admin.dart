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
import 'app_browser_flag.dart';

final _workspaceProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, orgId) => ref.watch(backendProvider).appBrowserWorkspace(orgId),
);

/// The workspace switch beside "Bots in Members' Browsers" (plan §13 decision 10): on by default,
/// a workspace admin can turn it off. Only in builds with the phone browser.
class AppBrowserWorkspaceTile extends ConsumerWidget {
  const AppBrowserWorkspaceTile({super.key, required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kAppBrowserCode || !ref.watch(appBrowserBuildProvider)) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final on = ref.watch(_workspaceProvider(orgId)).value ?? true;
    Future<void> set(bool v) async {
      await runGuarded(
        context,
        () => ref.read(backendProvider).setAppBrowserWorkspace(orgId, v),
      );
      ref.invalidate(_workspaceProvider(orgId));
    }

    return GroupedTile(
      icon: LucideIcons.smartphone,
      title: l10n.appBrowserWorkspaceSwitch,
      subtitle: l10n.appBrowserWorkspaceSwitchHelp,
      onTap: () {
        HapticsHelper.light();
        set(!on);
      },
      trailing: Switch(
        key: const Key('appBrowserWorkspaceSwitch'),
        value: on,
        onChanged: hapticOnChanged(set),
      ),
    );
  }
}

/// Admin → Services → Phone Browser (the instance owner): the stage, testers, reasons, systems and
/// the numbers the stages are switched on by (plan §6). Only in builds with the phone browser.
class AppBrowserAdminCard extends ConsumerWidget {
  const AppBrowserAdminCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kAppBrowserCode || !ref.watch(appBrowserBuildProvider)) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.lg),
      child: GroupedCard(
        children: [
          GroupedTile(
            key: const Key('adminAppBrowser'),
            icon: LucideIcons.smartphone,
            title: l10n.adminAppBrowser,
            subtitle: l10n.adminAppBrowserHelp,
            onTap: () => showAdaptiveSheet<void>(
              context: context,
              heightFactor: 0.9,
              dialogMaxWidth: 640,
              builder: (_) => const AppBrowserAdminSheet(),
            ),
          ),
        ],
      ),
    );
  }
}

final _adminProvider = FutureProvider.autoDispose<AdminAppBrowser>(
  (ref) => ref.watch(backendProvider).adminAppBrowser(),
);

class AppBrowserAdminSheet extends ConsumerStatefulWidget {
  const AppBrowserAdminSheet({super.key});

  @override
  ConsumerState<AppBrowserAdminSheet> createState() =>
      _AppBrowserAdminSheetState();
}

class _AppBrowserAdminSheetState extends ConsumerState<AppBrowserAdminSheet> {
  final _testers = TextEditingController();
  SaveAppBrowserRequestStageEnum? _stage;
  bool _asked = true, _blocked = false, _signedIn = false;
  final _systems = <String>{};
  var _loaded = false;
  var _busy = false;

  void _load(AppBrowserSettings s) {
    if (_loaded) return;
    _loaded = true;
    _stage = SaveAppBrowserRequestStageEnum.values.firstWhere(
      (v) => v.value == s.stage.value,
    );
    _testers.text = s.testers.join('\n');
    _asked = s.reasons.asked;
    _blocked = s.reasons.blocked;
    _signedIn = s.reasons.signedIn;
    _systems
      ..clear()
      ..addAll(s.systems);
  }

  @override
  void dispose() {
    _testers.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    final saved = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .saveAdminAppBrowser(
            SaveAppBrowserRequest(
              stage: _stage ?? SaveAppBrowserRequestStageEnum.off,
              testers: [
                for (final t in _testers.text.split(RegExp(r'[\s,]+')))
                  if (t.trim().isNotEmpty) t.trim(),
              ],
              reasons: SaveAppBrowserRequestReasons(
                asked: _asked,
                blocked: _blocked,
                signedIn: _signedIn,
              ),
              systems: [
                for (final s in SaveAppBrowserRequestSystemsEnum.values)
                  if (_systems.contains(s.value)) s,
              ],
            ),
          ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (saved != null) {
      ref.invalidate(_adminProvider);
      showSuccess(context, l10n.saved);
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = ref.watch(_adminProvider);
    return AsyncView<AdminAppBrowser>(
      value: data,
      onRetry: () => ref.invalidate(_adminProvider),
      data: (a) {
        _load(a.settings);
        final n = a.numbers;
        Widget number(String label, int value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(child: Text(label, style: context.textTheme.bodyMedium)),
              Text(
                '$value',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
        Widget check(
          String label,
          bool value,
          ValueChanged<bool> onChanged,
          Key key,
        ) => SwitchListTile(
          key: key,
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: value,
          onChanged: (v) => setState(() => onChanged(v)),
        );
        return FormSheet(
          icon: LucideIcons.smartphone,
          title: l10n.adminAppBrowser,
          subtitle: l10n.adminAppBrowserHelp,
          submitLabel: l10n.save,
          submitKey: const Key('adminAppBrowserSave'),
          busy: _busy,
          onSubmit: _busy ? null : _save,
          children: [
            Text(
              l10n.adminAppBrowserStage,
              style: context.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpace.xs),
            SegmentedButton<SaveAppBrowserRequestStageEnum>(
              key: const Key('adminAppBrowserStage'),
              segments: [
                ButtonSegment(
                  value: SaveAppBrowserRequestStageEnum.off,
                  label: Text(l10n.adminAppBrowserStageOff),
                ),
                ButtonSegment(
                  value: SaveAppBrowserRequestStageEnum.testers,
                  label: Text(l10n.adminAppBrowserStageTesters),
                ),
                ButtonSegment(
                  value: SaveAppBrowserRequestStageEnum.on_,
                  label: Text(l10n.adminAppBrowserStageOn),
                ),
              ],
              selected: {_stage ?? SaveAppBrowserRequestStageEnum.off},
              onSelectionChanged: (v) => setState(() => _stage = v.first),
            ),
            const SizedBox(height: AppSpace.md),
            TextField(
              key: const Key('adminAppBrowserTesters'),
              controller: _testers,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: l10n.adminAppBrowserTesters,
                helperText: l10n.adminAppBrowserTestersHelp,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              l10n.adminAppBrowserReasons,
              style: context.textTheme.titleSmall,
            ),
            check(
              l10n.adminAppBrowserReasonAsked,
              _asked,
              (v) => _asked = v,
              const Key('adminAppBrowserAsked'),
            ),
            check(
              l10n.adminAppBrowserReasonBlocked,
              _blocked,
              (v) => _blocked = v,
              const Key('adminAppBrowserBlocked'),
            ),
            check(
              l10n.adminAppBrowserReasonSignedIn,
              _signedIn,
              (v) => _signedIn = v,
              const Key('adminAppBrowserSignedIn'),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              l10n.adminAppBrowserSystems,
              style: context.textTheme.titleSmall,
            ),
            for (final (value, label) in [
              ('ios', l10n.adminAppBrowserIos),
              ('android', l10n.adminAppBrowserAndroid),
            ])
              check(
                label,
                _systems.contains(value),
                (v) => v ? _systems.add(value) : _systems.remove(value),
                Key('adminAppBrowserSystem-$value'),
              ),
            const SizedBox(height: AppSpace.md),
            Text(
              l10n.adminAppBrowserNumbers(n.days),
              style: context.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpace.xs),
            number(l10n.adminAppBrowserBlockedRuns, n.blockedRuns),
            number(l10n.adminAppBrowserBlockedPeople, n.blockedPeople),
            number(l10n.adminAppBrowserWatchedRuns, n.watchedBrowserRuns),
            number(l10n.adminAppBrowserPhoneRuns, n.phoneRuns),
            number(l10n.adminAppBrowserPhonePeople, n.phonePeople),
            number(l10n.adminAppBrowserPhonesPaired, n.phonesPaired),
            number(l10n.adminAppBrowserPhonesWithSites, n.phonesWithSites),
            number(l10n.adminAppBrowserRefusedSteps, n.refusedSteps),
          ],
        );
      },
    );
  }
}
