import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';

/// Action rules for a bot (D-115): per-action autonomy by category or tool, with limits, in plain
/// language. Workspace rules show too; the bot's own rule wins over them.
final actionRulesProvider = FutureProvider.autoDispose.family<List<ActionRule>, String>((ref, botId) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).actionRules(org.id, botId: botId);
});

const _categories = ['send', 'pay', 'delete', 'publish', 'share', 'sign_in'];

String categoryLabel(BuildContext context, String c) {
  final l10n = context.l10n;
  return switch (c) {
    'send' => l10n.catSend,
    'pay' => l10n.catPay,
    'delete' => l10n.catDelete,
    'publish' => l10n.catPublish,
    'share' => l10n.catShare,
    'sign_in' => l10n.catSignIn,
    _ => c,
  };
}

class ActionRulesScreen extends ConsumerWidget {
  const ActionRulesScreen({super.key, required this.botId});
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SubPage(
      title: l10n.actionRules,
      subtitle: ref.watch(botProvider(botId))?.name,
      actions: [
        IconButton(
          key: const Key('addRule'),
          tooltip: l10n.addRule,
          icon: const Icon(LucideIcons.plus),
          onPressed: () async {
            await showAdaptiveSheet<void>(context: context, builder: (_) => _AddRule(botId: botId));
            ref.invalidate(actionRulesProvider(botId));
          },
        ),
      ],
      body: AsyncView(
        value: ref.watch(actionRulesProvider(botId)),
        onRetry: () => ref.invalidate(actionRulesProvider(botId)),
        data: (rules) {
          final groups = <String, List<ActionRule>>{};
          for (final r in rules) {
            final key = r.matchKind == ActionRuleMatchKindEnum.category ? r.matchValue : 'other';
            (groups[key] ??= []).add(r);
          }
          return PageColumn(
            children: [
              FormNote(l10n.actionRulesHelp),
              const SizedBox(height: AppSpace.md),
              if (rules.isEmpty) Text(l10n.noRules),
              for (final key in [..._categories, 'other'])
                if (groups[key] != null) ...[
                  SectionHeader(title: key == 'other' ? l10n.otherTools : categoryLabel(context, key)),
                  GroupedCard(
                    children: [
                      for (final r in groups[key]!)
                        GroupedTile(
                          key: Key('rule-${r.id}'),
                          icon: switch (r.rule) {
                            ActionRuleRuleEnum.allow || ActionRuleRuleEnum.allowWithinLimits => LucideIcons.circleCheck,
                            ActionRuleRuleEnum.ask => LucideIcons.shieldQuestion,
                            _ => LucideIcons.hand,
                          },
                          title: r.preview,
                          subtitle: r.botId == null ? l10n.workspaceRule : null,
                          trailing: IconButton(
                            tooltip: l10n.delete,
                            icon: const Icon(LucideIcons.trash2, size: 18),
                            onPressed: () async {
                              await runGuarded(context, () => ref.read(backendProvider).deleteActionRule(r.id));
                              ref.invalidate(actionRulesProvider(botId));
                            },
                          ),
                        ),
                    ],
                  ),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _AddRule extends ConsumerStatefulWidget {
  const _AddRule({required this.botId});
  final String botId;

  @override
  ConsumerState<_AddRule> createState() => _AddRuleState();
}

class _AddRuleState extends ConsumerState<_AddRule> {
  var _category = 'send';
  var _rule = 'ask';
  var _workspace = false;
  final _domains = TextEditingController();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _domains.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final domains = _domains.text.split(',').map((d) => d.trim().toLowerCase()).where((d) => d.isNotEmpty).toList();
    final amount = double.tryParse(_amount.text.trim());
    final hasLimits = domains.isNotEmpty || amount != null;
    final valid = _rule != 'allow_within_limits' || hasLimits;
    return FormSheet(
      icon: LucideIcons.shieldCheck,
      title: l10n.addRule,
      subtitle: l10n.addRuleHelp,
      submitLabel: l10n.save,
      submitKey: const Key('saveRule'),
      onSubmit: !valid
          ? null
          : () async {
              final org = ref.read(currentOrgProvider);
              if (org == null) return;
              final ok = await runGuarded(context, () async {
                await ref.read(backendProvider).createActionRule(
                      org.id,
                      botId: _workspace ? null : widget.botId,
                      category: _category,
                      rule: _rule,
                      domains: domains,
                      maxAmount: amount,
                    );
                return true;
              });
              if (ok == true && context.mounted) Navigator.pop(context);
            },
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          key: const Key('ruleCategory'),
          initialValue: _category,
          decoration: InputDecoration(labelText: l10n.whenTheBot),
          items: [for (final c in _categories) DropdownMenuItem(value: c, child: Text(categoryLabel(context, c)))],
          onChanged: (v) => setState(() => _category = v ?? 'send'),
        ),
        DropdownButtonFormField<String>(
          isExpanded: true,
          key: const Key('ruleKind'),
          initialValue: _rule,
          decoration: InputDecoration(labelText: l10n.itShould),
          items: [
            DropdownMenuItem(value: 'allow', child: Text(l10n.ruleAllow)),
            DropdownMenuItem(value: 'allow_within_limits', child: Text(l10n.ruleAllowLimits)),
            DropdownMenuItem(value: 'ask', child: Text(l10n.ruleAsk)),
            DropdownMenuItem(value: 'hand_off', child: Text(l10n.ruleHandOff)),
          ],
          onChanged: (v) => setState(() => _rule = v ?? 'ask'),
        ),
        TextField(
          key: const Key('ruleDomains'),
          controller: _domains,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(labelText: l10n.ruleDomains, hintText: 'acme.com'),
          onChanged: (_) => setState(() {}),
        ),
        TextField(
          key: const Key('ruleAmount'),
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l10n.ruleMaxAmount),
          onChanged: (_) => setState(() {}),
        ),
        SwitchListTile(
          key: const Key('ruleWorkspace'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.ruleForWorkspace),
          value: _workspace,
          onChanged: (v) => setState(() => _workspace = v),
        ),
      ],
    );
  }
}
