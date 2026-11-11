# Fix: Money, counts and sizes ignore how people write numbers

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/format-numbers-for-humans
- **Needs new dependency**: none (`intl: ^0.20.3` is already in `pubspec.yaml`)

## Why

Casama prints its numbers raw: costs are glued together as `'$' + toStringAsFixed(2)` (so
`$1234.50`, never `$1,234.50`, and the `$` always in front even where people write
`1.234,50 $`), token counts use a hand-made "1.2K", and every count inside a translated string
(`"{n} members"`, `"Used {uses} times"`, `"Model credits: {count} tokens"`) comes out as
`1234`. Big numbers are hard to read that way, and they'll be wrong for every language added
later. Formatting every amount, count and size with intl's `NumberFormat` in the person's locale
makes them read the way people expect today (`1,234,567`) and correctly in any language
tomorrow.

## Where

Every place an amount, count or size is turned into text by hand (a search for
`NumberFormat|decimalPattern|simpleCurrency|compact\(` finds nothing in `lib/`). Rule used: if
people read it as "how much", it's formatted; if they read it as "which one" (step 2 of 5, a
click position, a day of the month) it's left alone. 62 places in 24 Dart files, plus the
translation file. Line numbers are from before any edit.

```dart
// 1. lib/core/providers.dart:374–379 — current (formatUsd builds "$1234.50" by hand: no grouping, symbol always first)
/// Formats US dollars for cost meters.
String formatUsd(num value) {
  if (value >= 1) return '\$${value.toStringAsFixed(2)}';
  if (value == 0) return '\$0.00';
  return '\$${value.toStringAsFixed(4)}';
}
```

```dart
// 2. lib/core/mobile_extras.dart:40 — current (home-screen widget cost (no BuildContext here; `l10n` is already resolved for the device locale on line 30))
      await HomeWidget.saveWidgetData('bot_cost', l10n.costToday(formatUsd(cost)));
```

```dart
// 3. lib/features/bots/bots_screen.dart:167 — current (bot list: cost today)
                        l10n.costToday(formatUsd(cost)),
```

```dart
// 4. lib/features/settings/settings_screen.dart:202 — current (Settings → Usage row total)
                      formatUsd(month?.totalCostUsd ?? 0),
```

```dart
// 5. lib/features/projects/projects_screen.dart:74 — current (project row: spent / budget)
                            if (p.budgetUsd != null) '${formatUsd(p.spentUsd)} / ${formatUsd(p.budgetUsd!)}' else formatUsd(p.spentUsd),
```

```dart
// 6. lib/features/projects/projects_screen.dart:244 — current (project budget under its progress bar)
              Text('${formatUsd(p.spentUsd)} / ${formatUsd(budget)}'),
```

```dart
// 7. lib/features/projects/projects_screen.dart:289 — current (project timeline run cost)
                    subtitle: '${formatUsd(r.costUsd)} · ${relativeTime(r.createdAt, context)}',
```

```dart
// 8. lib/features/admin/admin_screen.dart:133 — current (admin stat: spend (24 h))
          _Stat(icon: LucideIcons.banknote, label: l10n.cost24h, value: formatUsd(o.cost24hUsd), color: colors.positive),
```

```dart
// 9. lib/features/admin/admin_screen.dart:292 — current (admin workspace row: spend in 30 days)
                      l10n.cost30d(formatUsd(o.cost30dUsd)),
```

```dart
// 10. lib/features/usage/usage_screen.dart:101 — current (Usage: total spend)
              child: _Stat(key: const Key('usageSpend'), label: l10n.totalSpend, value: formatUsd(report.totalCostUsd), icon: LucideIcons.banknote, accent: true),
```

```dart
// 11. lib/features/usage/usage_screen.dart:139 — current (Usage → Everything metered: cost)
                    trailing: Text(formatUsd(k.costUsd), style: context.textTheme.titleSmall?.copyWith(fontFeatures: AppText.tabular)),
```

```dart
// 12. lib/features/usage/usage_screen.dart:270 — current (Usage chart: left axis amounts)
                  : Text(formatUsd(v), style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
```

```dart
// 13. lib/features/usage/usage_screen.dart:292 — current (Usage chart: tooltip amount)
              '${days[group.x].$1}\n${formatUsd(rod.toY)}',
```

```dart
// 14. lib/features/usage/usage_screen.dart:334 — current (Usage → By bot: cost)
              Text(formatUsd(r.$2), style: context.textTheme.labelLarge?.copyWith(fontFeatures: AppText.tabular)),
```

```dart
// 15. lib/features/usage/usage_screen.dart:403 — current (Usage → By model: cost)
                Text(formatUsd(m.costUsd), style: context.textTheme.labelLarge?.copyWith(fontFeatures: AppText.tabular)),
```

```dart
// 16. lib/features/usage/usage_screen.dart:497 — current (usage text handed to a bot (only the formatUsd calls change, because its signature changes))
    ..writeln('Total: ${formatUsd(r.totalCostUsd)} since ${r.since.toIso8601String().substring(0, 10)} (${r.runs ?? 0} runs)');
```

```dart
// 17. lib/features/usage/usage_screen.dart:501 — current (same)
      b.writeln('- ${x.name ?? l10n.deletedBot}: ${formatUsd(x.costUsd)}, ${x.tokensIn} tokens in, ${x.tokensOut} out');
```

```dart
// 18. lib/features/usage/usage_screen.dart:507 — current (same)
      b.writeln('- ${m.model ?? l10n.otherModel}: ${formatUsd(m.costUsd)}, ${m.tokensIn} in, ${m.tokensOut} out');
```

```dart
// 19. lib/features/usage/usage_screen.dart:513 — current (same)
      b.writeln('- ${d.day}: ${formatUsd(d.costUsd)}');
```

```dart
// 20. lib/features/timeline/timeline_screen.dart:125 — current (run timeline: run cost)
            formatUsd(run.costUsd),
```

```dart
// 21. lib/features/timeline/timeline_screen.dart:241 — current (run timeline: usage event cost and raw token count)
      UsageItem(:final event) => '${formatUsd(event.payload.costUsd)} · ${event.payload.tokensIn + event.payload.tokensOut} tokens',
```

```dart
// 22. lib/features/billing/billing_screen.dart:262 — current (plan limits: "$100 credits a month" (the $ moves out of the ARB string, see the ARB step))
    if (limits['monthly_credits_usd'] != null) l10n.limitCredits(limits['monthly_credits_usd']!.toStringAsFixed(0)),
```

```dart
// 23. lib/features/billing/billing_screen.dart:340 — current (credits balance (the $ moves out of the ARB string))
                        l10n.creditsBalance(b.creditsUsd.toStringAsFixed(2)),
```

```dart
// 24. lib/features/billing/billing_screen.dart:378–379 — current (billed items: computer hours and live-view minutes)
        'computer_seconds' => (l10n.usageComputerHours((i.quantity / 3600).toStringAsFixed(2)), LucideIcons.monitor),
        'stream_seconds' => (l10n.usageLiveViewMinutes((i.quantity / 60).toStringAsFixed(0)), LucideIcons.monitorPlay),
```

```dart
// 25. lib/features/billing/billing_screen.dart:401 — current (billed item cost)
                    '\$${i.costUsd.toStringAsFixed(2)}',
```

```dart
// 26. lib/features/billing/billing_screen.dart:428 — current (Billing → Usage row total)
            subtitle: usage == null ? l10n.billingUsageRow : l10n.billingUsageSoFar('\$${usage.totalUsd.toStringAsFixed(2)}'),
```

```dart
// 27. lib/features/workspaces/spaces.dart:829 — current (payment amounts: "EUR 12.50" by hand (Stripe may send the code in lower case, so it's upper-cased))
String _money(int cents, String currency) => '${currency == 'USD' ? r'$' : '$currency '}${(cents / 100).toStringAsFixed(2)}';
```

```dart
// 28. lib/features/workspaces/spaces.dart:848 — current (Payments row: spent and cap)
          subtitle: p.connected ? l10n.paymentsOn(r'$' + p.spentThisMonthUsd.toStringAsFixed(2), r'$' + p.monthlyCapUsd.toStringAsFixed(0)) : l10n.paymentsHelp,
```

```dart
// 29. lib/features/workspaces/spaces.dart:861 — current (recent payment rows)
            title: '${_money(r.spentCents ?? r.amountCents, r.currency)} · ${r.merchant}',
```

```dart
// 30. lib/features/usage/usage_screen.dart:104 — current (Usage: runs)
              child: _Stat(label: l10n.runsLabel, value: '${report.runs ?? 0}', icon: LucideIcons.zap),
```

```dart
// 31. lib/features/usage/usage_screen.dart:121 — current (Usage → By bot: tokens (only the third element of the record changes))
                  for (final b in report.byBot) (b.name ?? l10n.deletedBot, b.costUsd.toDouble(), b.tokensIn + b.tokensOut == 0 ? '' : '${compactNumber(b.tokensIn + b.tokensOut)} tokens'),
```

```dart
// 32. lib/features/usage/usage_screen.dart:138 — current (Usage → Everything metered: quantity)
                    subtitle: _kindQuantity(k.kind, k.quantity),
```

```dart
// 33. lib/features/usage/usage_screen.dart:180 — current (Usage → Advanced: tokens in)
                  trailing: Text(compactNumber(_tokensIn), style: context.textTheme.titleSmall?.copyWith(fontFeatures: AppText.tabular)),
```

```dart
// 34. lib/features/usage/usage_screen.dart:186 — current (Usage → Advanced: tokens out)
                  trailing: Text(compactNumber(_tokensOut), style: context.textTheme.titleSmall?.copyWith(fontFeatures: AppText.tabular)),
```

```dart
// 35. lib/features/usage/usage_screen.dart:477–483 — current (metered quantities built with toStringAsFixed and a hand-made compact form)
String _kindQuantity(String kind, num q) => switch (kind) {
  'tokens_in' || 'tokens_out' => '${compactNumber(q)} tokens',
  'computer_seconds' => '${(q / 3600).toStringAsFixed(2)} h',
  'stream_seconds' => '${(q / 60).toStringAsFixed(0)} min',
  'tts_chars' => '${compactNumber(q)} characters',
  _ => '$q',
};
```

```dart
// 36. lib/features/usage/usage_screen.dart:485–492 — current (the hand-made compactNumber and the blank line after it: delete all eight lines (NumberFormat.compact replaces it everywhere))
/// 1234 → 1.2K, 3400000 → 3.4M.
String compactNumber(num n) {
  if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(1)}B';
  if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
  if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}K';
  return n.toStringAsFixed(n is int || n == n.roundToDouble() ? 0 : 1);
}

```

```dart
// 37. lib/features/chat/widgets/chat_widgets.dart:537–539 — current (tool step durations)
String formatDuration(int ms) => ms < 1000
    ? '$ms ms'
    : '${(ms / 1000).toStringAsFixed(ms < 10000 ? 1 : 0)} s';
```

```dart
// 38. lib/features/chat/widgets/chat_widgets.dart:597 — current (tool card total)
                          '${l10n.toolSteps(steps.length)} · ${formatDuration(totalMs)}',
```

```dart
// 39. lib/features/chat/widgets/chat_widgets.dart:664 — current (tool step duration)
        formatDuration(entry.durationMs ?? 0),
```

```dart
// 40. lib/features/files/file_preview.dart:134–138 — current (file sizes)
String formatBytes(int n) {
  if (n < 1024) return '$n B';
  if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(n < 10 * 1024 ? 1 : 0)} KB';
  return '${(n / 1024 / 1024).toStringAsFixed(1)} MB';
}
```

```dart
// 41. lib/features/files/file_preview.dart:241 — current (file preview header)
                      [path.startsWith('~/') || path.startsWith('/') ? path : 'workspace/$path', if (bytes != null) formatBytes(bytes.length)].join(' · '),
```

```dart
// 42. lib/features/chat/widgets/chat_widgets.dart:488 — current (chat attachment size)
                        formatBytes(attachment.size),
```

```dart
// 43. lib/features/chat/chat_screen.dart:1011 — current (composer attachment size)
                            Text(formatBytes(item.bytes.length), style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
```

```dart
// 44. lib/features/computer/computer_screen.dart:1039 — current (computer file list size)
                                subtitle: formatBytes(e.size),
```

```dart
// 45. lib/features/privacy/privacy_screen.dart:56 — current ("Export ready (1234 KB)")
      if (mounted) showMessage(context, l10n.exportReady((bytes.length / 1024).toStringAsFixed(0)));
```

```dart
// 46. lib/features/bots/knowledge_screen.dart:198 — current (picked knowledge files: size in KB)
          for (final (n, b) in _files) Text('$n · ${(b.length / 1024).ceil()} KB'),
```

```dart
// 47. lib/features/skills/skill_library.dart:122 — current (skill preview files: size in bytes)
          for (final f in p.files) _FileBlock(title: '${f.path}${f.executable ? ' (executable)' : ''} · ${f.size} B', text: f.text ?? l10n.binaryFile),
```

```dart
// 48. lib/features/admin/admin_screen.dart:123–126 — current (admin stats)
          _Stat(icon: LucideIcons.user, label: l10n.adminUsers, value: '${o.users}'),
          _Stat(icon: LucideIcons.boxes, label: l10n.adminWorkspaces, value: '${o.orgs}'),
          _Stat(icon: LucideIcons.bot, label: l10n.bots, value: '${o.bots}'),
          _Stat(icon: LucideIcons.circlePlay, label: l10n.runs24h, value: '${o.runs24h}', color: colors.info),
```

```dart
// 49. lib/features/admin/admin_screen.dart:130 — current (admin stats: failed runs)
            value: '${o.failedRuns24h}',
```

```dart
// 50. lib/features/admin/admin_screen.dart:134–135 — current (admin stats: computers and devices)
          _Stat(icon: LucideIcons.monitor, label: l10n.computersRunning, value: '${o.computersRunning}', color: colors.working),
          _Stat(icon: LucideIcons.monitorSmartphone, label: l10n.devicesOnline, value: '${o.devicesOnline}'),
```

```dart
// 51. lib/features/settings/about_you_screen.dart:199 — current (section count: things learned about you)
          count: facts.value == null ? null : '${facts.value!.length}',
```

```dart
// 52. lib/features/inbox/inbox_screen.dart:222 — current (section count: needs you)
          if (all && decisions.isNotEmpty) SectionHeader(title: l10n.inboxNeedsYou, count: '${decisions.length}', padding: const EdgeInsets.fromLTRB(AppSpace.xxs, AppSpace.xs, AppSpace.xxs, AppSpace.xs)),
```

```dart
// 53. lib/features/board/board_screen.dart:319 — current (board column count (list view))
          Expanded(child: SectionHeader(title: statusLabel(context, status), count: '$count', padding: EdgeInsets.zero)),
```

```dart
// 54. lib/features/board/board_screen.dart:386 — current (board column count)
                  Text('${tasks.length}', style: context.textTheme.bodySmall),
```

```dart
// 55. lib/features/workspaces/people_screen.dart:49 — current (section count: members)
        SectionHeader(title: l10n.members, count: members.isEmpty ? null : '${members.length}'),
```

```dart
// 56. lib/features/workspaces/people_screen.dart:395 — current (section count: waiting to join)
        SectionHeader(title: l10n.waitingToJoin, count: '${list.length}'),
```

```dart
// 57. lib/features/workspaces/people_screen.dart:431 — current (section count: pending invites)
        SectionHeader(title: l10n.pendingInvites, count: '${list.length}'),
```

```dart
// 58. lib/features/workspaces/people_screen.dart:613 — current (invite link uses)
                      l10n.linkUses('${l.uses}${l.maxUses == null ? '' : '/${l.maxUses}'}'),
```

```dart
// 59. lib/features/integrations/integrations_screen.dart:234 — current (search result count)
        SectionHeader(title: filtering ? '${shown.length}' : l10n.allApps),
```

```dart
// 60. lib/features/settings/gallery_screen.dart:364 — current (gallery section count)
            count: '${list.length}',
```

```dart
// 61. lib/features/skills/skill_catalog_screen.dart:197 — current (skill catalog section count)
              count: '${shown.where((s) => s.category == c).length}',
```

```dart
// 62. lib/features/projects/projects_screen.dart:255 — current (milestone tickets done / total)
                    subtitle: '${m.ticketsDone}/${m.ticketsTotal}${m.requiresSignoff ? ' · ${l10n.needsSignoff}' : ''}',
```

The translation file `lib/l10n/app_en.arb` (the generated code in `lib/l10n/generated/`
interpolates every `int` placeholder raw, for example `return 'Model credits: $count tokens';`):

```json
// 63. lib/l10n/app_en.arb — current: all 76 int placeholders, in 66 lines, are written exactly like this, with no "format"
  "@membersCount": {"placeholders": {"n": {"type": "int"}}},
```

```json
// 64. lib/l10n/app_en.arb:285, 663 and 1522 — current: the "which one" numbers, which stay unformatted
  "@cronMonthlyAt": {"placeholders": {"day": {"type": "int"}, "time": {"type": "String"}}},
  "@stepOf": {"placeholders": {"step": {"type": "int"}, "total": {"type": "int"}}},
  "@teachStepClick": {"placeholders": {"x": {"type": "int"}, "y": {"type": "int"}}},
```

```json
// 65. lib/l10n/app_en.arb:544 and 554 — current: a hard-coded "$" in front of the amount
  "limitCredits": "${amount} credits a month",
  "creditsBalance": "Credits: ${amount}",
```

```dart
// 66. test/app_test.dart:335 — current (a "must not appear" check that would pass for the wrong reason once counts are grouped)
      expect(find.textContaining('1050 tokens'), findsNothing);
```

## The fix

The article's fix: format with `NumberFormat` from `intl` (`decimalPatternDigits` for counts,
`simpleCurrency` for money, `compact` for big numbers), through one small extension on `num`.
One adaptation: Flutter doesn't set intl's default locale, so every method takes the locale
explicitly; callers pass `context.l10n.localeName` (the app's resolved language, from
`AppLocalizations`), never a hard-coded `en_US`. The existing helpers keep their names and gain a
`locale` parameter (`formatUsd`, `formatBytes`, `formatDuration`), and the hand-made
`compactNumber` is replaced by `NumberFormat.compact`. Counts inside translated strings use the
same `NumberFormat` through the ARB file's `"format": "decimalPattern"`, which `flutter gen-l10n`
turns into `NumberFormat.decimalPattern(localeName)`.

New file `lib/core/number_format.dart` (target, complete):

```dart
import 'package:intl/intl.dart';

/// Numbers as people read them, in their locale (pass `context.l10n.localeName`):
/// 1234567 → "1,234,567" in English, "1.234.567" in German.
extension HumanNumbers on num {
  /// A count or amount: 1234567 → "1,234,567". [decimalDigits] fixes the digits after the point.
  String humanizedCount(String locale, {int? decimalDigits}) {
    return NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: decimalDigits).format(this);
  }

  /// Money with its symbol and the currency's decimals: 1234.5 → "$1,234.50" in English,
  /// "1.234,50 $" in German. [decimalDigits] overrides the currency's usual decimals.
  String humanizedCurrency(String locale, String code, {int? decimalDigits}) {
    return NumberFormat.simpleCurrency(locale: locale, name: code, decimalDigits: decimalDigits).format(this);
  }

  /// Big numbers, short: 1234567 → "1.23M", 9800 → "9.8K".
  String humanizedCompact(String locale) {
    return NumberFormat.compact(locale: locale).format(this);
  }
}
```

Targets, numbered as in "Where" (each line keeps everything not shown as changed):

```dart
// 1. lib/core/providers.dart:374–379 — target (formatUsd builds "$1234.50" by hand: no grouping, symbol always first)
/// Formats US dollars for cost meters in the person's locale: two decimals from a dollar up and
/// at zero, four below so small costs don't read as $0.00.
String formatUsd(num value, String locale) => value.humanizedCurrency(locale, 'USD', decimalDigits: value >= 1 || value == 0 ? 2 : 4);
```

```dart
// 2. lib/core/mobile_extras.dart:40 — target (home-screen widget cost (no BuildContext here; `l10n` is already resolved for the device locale on line 30))
      await HomeWidget.saveWidgetData('bot_cost', l10n.costToday(formatUsd(cost, l10n.localeName)));
```

```dart
// 3. lib/features/bots/bots_screen.dart:167 — target (bot list: cost today)
                        l10n.costToday(formatUsd(cost, context.l10n.localeName)),
```

```dart
// 4. lib/features/settings/settings_screen.dart:202 — target (Settings → Usage row total)
                      formatUsd(month?.totalCostUsd ?? 0, context.l10n.localeName),
```

```dart
// 5. lib/features/projects/projects_screen.dart:74 — target (project row: spent / budget)
                            if (p.budgetUsd != null) '${formatUsd(p.spentUsd, context.l10n.localeName)} / ${formatUsd(p.budgetUsd!, context.l10n.localeName)}' else formatUsd(p.spentUsd, context.l10n.localeName),
```

```dart
// 6. lib/features/projects/projects_screen.dart:244 — target (project budget under its progress bar)
              Text('${formatUsd(p.spentUsd, context.l10n.localeName)} / ${formatUsd(budget, context.l10n.localeName)}'),
```

```dart
// 7. lib/features/projects/projects_screen.dart:289 — target (project timeline run cost)
                    subtitle: '${formatUsd(r.costUsd, context.l10n.localeName)} · ${relativeTime(r.createdAt, context)}',
```

```dart
// 8. lib/features/admin/admin_screen.dart:133 — target (admin stat: spend (24 h))
          _Stat(icon: LucideIcons.banknote, label: l10n.cost24h, value: formatUsd(o.cost24hUsd, context.l10n.localeName), color: colors.positive),
```

```dart
// 9. lib/features/admin/admin_screen.dart:292 — target (admin workspace row: spend in 30 days)
                      l10n.cost30d(formatUsd(o.cost30dUsd, context.l10n.localeName)),
```

```dart
// 10. lib/features/usage/usage_screen.dart:101 — target (Usage: total spend)
              child: _Stat(key: const Key('usageSpend'), label: l10n.totalSpend, value: formatUsd(report.totalCostUsd, context.l10n.localeName), icon: LucideIcons.banknote, accent: true),
```

```dart
// 11. lib/features/usage/usage_screen.dart:139 — target (Usage → Everything metered: cost)
                    trailing: Text(formatUsd(k.costUsd, context.l10n.localeName), style: context.textTheme.titleSmall?.copyWith(fontFeatures: AppText.tabular)),
```

```dart
// 12. lib/features/usage/usage_screen.dart:270 — target (Usage chart: left axis amounts)
                  : Text(formatUsd(v, context.l10n.localeName), style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
```

```dart
// 13. lib/features/usage/usage_screen.dart:292 — target (Usage chart: tooltip amount)
              '${days[group.x].$1}\n${formatUsd(rod.toY, context.l10n.localeName)}',
```

```dart
// 14. lib/features/usage/usage_screen.dart:334 — target (Usage → By bot: cost)
              Text(formatUsd(r.$2, context.l10n.localeName), style: context.textTheme.labelLarge?.copyWith(fontFeatures: AppText.tabular)),
```

```dart
// 15. lib/features/usage/usage_screen.dart:403 — target (Usage → By model: cost)
                Text(formatUsd(m.costUsd, context.l10n.localeName), style: context.textTheme.labelLarge?.copyWith(fontFeatures: AppText.tabular)),
```

```dart
// 16. lib/features/usage/usage_screen.dart:497 — target (usage text handed to a bot (only the formatUsd calls change, because its signature changes))
    ..writeln('Total: ${formatUsd(r.totalCostUsd, l10n.localeName)} since ${r.since.toIso8601String().substring(0, 10)} (${r.runs ?? 0} runs)');
```

```dart
// 17. lib/features/usage/usage_screen.dart:501 — target (same)
      b.writeln('- ${x.name ?? l10n.deletedBot}: ${formatUsd(x.costUsd, l10n.localeName)}, ${x.tokensIn} tokens in, ${x.tokensOut} out');
```

```dart
// 18. lib/features/usage/usage_screen.dart:507 — target (same)
      b.writeln('- ${m.model ?? l10n.otherModel}: ${formatUsd(m.costUsd, l10n.localeName)}, ${m.tokensIn} in, ${m.tokensOut} out');
```

```dart
// 19. lib/features/usage/usage_screen.dart:513 — target (same)
      b.writeln('- ${d.day}: ${formatUsd(d.costUsd, l10n.localeName)}');
```

```dart
// 20. lib/features/timeline/timeline_screen.dart:125 — target (run timeline: run cost)
            formatUsd(run.costUsd, context.l10n.localeName),
```

```dart
// 21. lib/features/timeline/timeline_screen.dart:241 — target (run timeline: usage event cost and raw token count)
      UsageItem(:final event) => '${formatUsd(event.payload.costUsd, context.l10n.localeName)} · ${(event.payload.tokensIn + event.payload.tokensOut).humanizedCount(context.l10n.localeName)} tokens',
```

```dart
// 22. lib/features/billing/billing_screen.dart:262 — target (plan limits: "$100 credits a month" (the $ moves out of the ARB string, see the ARB step))
    if (limits['monthly_credits_usd'] != null) l10n.limitCredits(limits['monthly_credits_usd']!.humanizedCurrency(context.l10n.localeName, 'USD', decimalDigits: 0)),
```

```dart
// 23. lib/features/billing/billing_screen.dart:340 — target (credits balance (the $ moves out of the ARB string))
                        l10n.creditsBalance(b.creditsUsd.humanizedCurrency(context.l10n.localeName, 'USD', decimalDigits: 2)),
```

```dart
// 24. lib/features/billing/billing_screen.dart:378–379 — target (billed items: computer hours and live-view minutes)
        'computer_seconds' => (l10n.usageComputerHours((i.quantity / 3600).humanizedCount(context.l10n.localeName, decimalDigits: 2)), LucideIcons.monitor),
        'stream_seconds' => (l10n.usageLiveViewMinutes((i.quantity / 60).humanizedCount(context.l10n.localeName, decimalDigits: 0)), LucideIcons.monitorPlay),
```

```dart
// 25. lib/features/billing/billing_screen.dart:401 — target (billed item cost)
                    i.costUsd.humanizedCurrency(context.l10n.localeName, 'USD', decimalDigits: 2),
```

```dart
// 26. lib/features/billing/billing_screen.dart:428 — target (Billing → Usage row total)
            subtitle: usage == null ? l10n.billingUsageRow : l10n.billingUsageSoFar(usage.totalUsd.humanizedCurrency(context.l10n.localeName, 'USD', decimalDigits: 2)),
```

```dart
// 27. lib/features/workspaces/spaces.dart:829 — target (payment amounts: "EUR 12.50" by hand (Stripe may send the code in lower case, so it's upper-cased))
String _money(int cents, String currency, String locale) => (cents / 100).humanizedCurrency(locale, currency.toUpperCase());
```

```dart
// 28. lib/features/workspaces/spaces.dart:848 — target (Payments row: spent and cap)
          subtitle: p.connected ? l10n.paymentsOn(p.spentThisMonthUsd.humanizedCurrency(context.l10n.localeName, 'USD', decimalDigits: 2), p.monthlyCapUsd.humanizedCurrency(context.l10n.localeName, 'USD', decimalDigits: 0)) : l10n.paymentsHelp,
```

```dart
// 29. lib/features/workspaces/spaces.dart:861 — target (recent payment rows)
            title: '${_money(r.spentCents ?? r.amountCents, r.currency, context.l10n.localeName)} · ${r.merchant}',
```

```dart
// 30. lib/features/usage/usage_screen.dart:104 — target (Usage: runs)
              child: _Stat(label: l10n.runsLabel, value: (report.runs ?? 0).humanizedCount(context.l10n.localeName), icon: LucideIcons.zap),
```

```dart
// 31. lib/features/usage/usage_screen.dart:121 — target (Usage → By bot: tokens (only the third element of the record changes))
                  for (final b in report.byBot) (b.name ?? l10n.deletedBot, b.costUsd.toDouble(), b.tokensIn + b.tokensOut == 0 ? '' : '${(b.tokensIn + b.tokensOut).humanizedCompact(context.l10n.localeName)} tokens'),
```

```dart
// 32. lib/features/usage/usage_screen.dart:138 — target (Usage → Everything metered: quantity)
                    subtitle: _kindQuantity(k.kind, k.quantity, context.l10n.localeName),
```

```dart
// 33. lib/features/usage/usage_screen.dart:180 — target (Usage → Advanced: tokens in)
                  trailing: Text(_tokensIn.humanizedCompact(context.l10n.localeName), style: context.textTheme.titleSmall?.copyWith(fontFeatures: AppText.tabular)),
```

```dart
// 34. lib/features/usage/usage_screen.dart:186 — target (Usage → Advanced: tokens out)
                  trailing: Text(_tokensOut.humanizedCompact(context.l10n.localeName), style: context.textTheme.titleSmall?.copyWith(fontFeatures: AppText.tabular)),
```

```dart
// 35. lib/features/usage/usage_screen.dart:477–483 — target (metered quantities built with toStringAsFixed and a hand-made compact form)
String _kindQuantity(String kind, num q, String locale) => switch (kind) {
  'tokens_in' || 'tokens_out' => '${q.humanizedCompact(locale)} tokens',
  'computer_seconds' => '${(q / 3600).humanizedCount(locale, decimalDigits: 2)} h',
  'stream_seconds' => '${(q / 60).humanizedCount(locale, decimalDigits: 0)} min',
  'tts_chars' => '${q.humanizedCompact(locale)} characters',
  _ => q.humanizedCount(locale),
};
```

```dart
// 36. lib/features/usage/usage_screen.dart:485–492 — target (the hand-made compactNumber and the blank line after it: delete all eight lines (NumberFormat.compact replaces it everywhere))
// (delete these lines; nothing replaces them)
```

```dart
// 37. lib/features/chat/widgets/chat_widgets.dart:537–539 — target (tool step durations)
String formatDuration(int ms, String locale) => ms < 1000
    ? '${ms.humanizedCount(locale)} ms'
    : '${(ms / 1000).humanizedCount(locale, decimalDigits: ms < 10000 ? 1 : 0)} s';
```

```dart
// 38. lib/features/chat/widgets/chat_widgets.dart:597 — target (tool card total)
                          '${l10n.toolSteps(steps.length)} · ${formatDuration(totalMs, context.l10n.localeName)}',
```

```dart
// 39. lib/features/chat/widgets/chat_widgets.dart:664 — target (tool step duration)
        formatDuration(entry.durationMs ?? 0, context.l10n.localeName),
```

```dart
// 40. lib/features/files/file_preview.dart:134–138 — target (file sizes)
String formatBytes(int n, String locale) {
  if (n < 1024) return '${n.humanizedCount(locale)} B';
  if (n < 1024 * 1024) return '${(n / 1024).humanizedCount(locale, decimalDigits: n < 10 * 1024 ? 1 : 0)} KB';
  return '${(n / 1024 / 1024).humanizedCount(locale, decimalDigits: 1)} MB';
}
```

```dart
// 41. lib/features/files/file_preview.dart:241 — target (file preview header)
                      [path.startsWith('~/') || path.startsWith('/') ? path : 'workspace/$path', if (bytes != null) formatBytes(bytes.length, context.l10n.localeName)].join(' · '),
```

```dart
// 42. lib/features/chat/widgets/chat_widgets.dart:488 — target (chat attachment size)
                        formatBytes(attachment.size, context.l10n.localeName),
```

```dart
// 43. lib/features/chat/chat_screen.dart:1011 — target (composer attachment size)
                            Text(formatBytes(item.bytes.length, context.l10n.localeName), style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
```

```dart
// 44. lib/features/computer/computer_screen.dart:1039 — target (computer file list size)
                                subtitle: formatBytes(e.size, context.l10n.localeName),
```

```dart
// 45. lib/features/privacy/privacy_screen.dart:56 — target ("Export ready (1234 KB)")
      if (mounted) showMessage(context, l10n.exportReady((bytes.length / 1024).humanizedCount(context.l10n.localeName, decimalDigits: 0)));
```

```dart
// 46. lib/features/bots/knowledge_screen.dart:198 — target (picked knowledge files: size in KB)
          for (final (n, b) in _files) Text('$n · ${(b.length / 1024).ceil().humanizedCount(context.l10n.localeName)} KB'),
```

```dart
// 47. lib/features/skills/skill_library.dart:122 — target (skill preview files: size in bytes)
          for (final f in p.files) _FileBlock(title: '${f.path}${f.executable ? ' (executable)' : ''} · ${f.size.humanizedCount(context.l10n.localeName)} B', text: f.text ?? l10n.binaryFile),
```

```dart
// 48. lib/features/admin/admin_screen.dart:123–126 — target (admin stats)
          _Stat(icon: LucideIcons.user, label: l10n.adminUsers, value: o.users.humanizedCount(context.l10n.localeName)),
          _Stat(icon: LucideIcons.boxes, label: l10n.adminWorkspaces, value: o.orgs.humanizedCount(context.l10n.localeName)),
          _Stat(icon: LucideIcons.bot, label: l10n.bots, value: o.bots.humanizedCount(context.l10n.localeName)),
          _Stat(icon: LucideIcons.circlePlay, label: l10n.runs24h, value: o.runs24h.humanizedCount(context.l10n.localeName), color: colors.info),
```

```dart
// 49. lib/features/admin/admin_screen.dart:130 — target (admin stats: failed runs)
            value: o.failedRuns24h.humanizedCount(context.l10n.localeName),
```

```dart
// 50. lib/features/admin/admin_screen.dart:134–135 — target (admin stats: computers and devices)
          _Stat(icon: LucideIcons.monitor, label: l10n.computersRunning, value: o.computersRunning.humanizedCount(context.l10n.localeName), color: colors.working),
          _Stat(icon: LucideIcons.monitorSmartphone, label: l10n.devicesOnline, value: o.devicesOnline.humanizedCount(context.l10n.localeName)),
```

```dart
// 51. lib/features/settings/about_you_screen.dart:199 — target (section count: things learned about you)
          count: facts.value == null ? null : facts.value!.length.humanizedCount(context.l10n.localeName),
```

```dart
// 52. lib/features/inbox/inbox_screen.dart:222 — target (section count: needs you)
          if (all && decisions.isNotEmpty) SectionHeader(title: l10n.inboxNeedsYou, count: decisions.length.humanizedCount(context.l10n.localeName), padding: const EdgeInsets.fromLTRB(AppSpace.xxs, AppSpace.xs, AppSpace.xxs, AppSpace.xs)),
```

```dart
// 53. lib/features/board/board_screen.dart:319 — target (board column count (list view))
          Expanded(child: SectionHeader(title: statusLabel(context, status), count: count.humanizedCount(context.l10n.localeName), padding: EdgeInsets.zero)),
```

```dart
// 54. lib/features/board/board_screen.dart:386 — target (board column count)
                  Text(tasks.length.humanizedCount(context.l10n.localeName), style: context.textTheme.bodySmall),
```

```dart
// 55. lib/features/workspaces/people_screen.dart:49 — target (section count: members)
        SectionHeader(title: l10n.members, count: members.isEmpty ? null : members.length.humanizedCount(context.l10n.localeName)),
```

```dart
// 56. lib/features/workspaces/people_screen.dart:395 — target (section count: waiting to join)
        SectionHeader(title: l10n.waitingToJoin, count: list.length.humanizedCount(context.l10n.localeName)),
```

```dart
// 57. lib/features/workspaces/people_screen.dart:431 — target (section count: pending invites)
        SectionHeader(title: l10n.pendingInvites, count: list.length.humanizedCount(context.l10n.localeName)),
```

```dart
// 58. lib/features/workspaces/people_screen.dart:613 — target (invite link uses)
                      l10n.linkUses('${l.uses.humanizedCount(context.l10n.localeName)}${l.maxUses == null ? '' : '/${l.maxUses!.humanizedCount(context.l10n.localeName)}'}'),
```

```dart
// 59. lib/features/integrations/integrations_screen.dart:234 — target (search result count)
        SectionHeader(title: filtering ? shown.length.humanizedCount(context.l10n.localeName) : l10n.allApps),
```

```dart
// 60. lib/features/settings/gallery_screen.dart:364 — target (gallery section count)
            count: list.length.humanizedCount(context.l10n.localeName),
```

```dart
// 61. lib/features/skills/skill_catalog_screen.dart:197 — target (skill catalog section count)
              count: shown.where((s) => s.category == c).length.humanizedCount(context.l10n.localeName),
```

```dart
// 62. lib/features/projects/projects_screen.dart:255 — target (milestone tickets done / total)
                    subtitle: '${m.ticketsDone.humanizedCount(context.l10n.localeName)}/${m.ticketsTotal.humanizedCount(context.l10n.localeName)}${m.requiresSignoff ? ' · ${l10n.needsSignoff}' : ''}',
```

```json
// 63. lib/l10n/app_en.arb — target: every int placeholder gets the decimal format
  "@membersCount": {"placeholders": {"n": {"type": "int", "format": "decimalPattern"}}},
```

```json
// 64. lib/l10n/app_en.arb — target: these three lines end up exactly as they are now
  "@cronMonthlyAt": {"placeholders": {"day": {"type": "int"}, "time": {"type": "String"}}},
  "@stepOf": {"placeholders": {"step": {"type": "int"}, "total": {"type": "int"}}},
  "@teachStepClick": {"placeholders": {"x": {"type": "int"}, "y": {"type": "int"}}},
```

```json
// 65. lib/l10n/app_en.arb — target (the amount now arrives with its own symbol; the two "@" metadata lines stay as they are)
  "limitCredits": "{amount} credits a month",
  "creditsBalance": "Credits: {amount}",
```

```dart
// 66. test/app_test.dart:335 — target
      expect(find.textContaining('1,050 tokens'), findsNothing);
```

## Steps

Edit by hand. Never run `dart format` on existing files.

1. Create `lib/core/number_format.dart` with exactly the content in "The fix", then run
   `dart format -l 200 lib/core/number_format.dart`.
2. `lib/core/providers.dart`: replace the six lines of block 1 (the `/// Formats US dollars…`
   comment and the whole `formatUsd` function) with its three target lines, then add
   `import 'number_format.dart';` directly below the line `import 'local_cache.dart';`.
3. Every other Dart file in "Where", in order:
   a. Replace each quoted line with its target, finding it by its quoted text (line numbers
      shift as you edit). Block 36 in `usage_screen.dart` is a deletion: remove those eight
      lines (the `/// 1234 → 1.2K…` comment, the whole `compactNumber` function and the one blank
      line after it), so exactly one blank line stays between `};` and
      `/// The report as plain text, for a bot to read.`.
   b. Then add the number import directly above the file's line that imports
      `core/providers.dart`, in these 18 files: `lib/features/projects/projects_screen.dart`,
      `lib/features/admin/admin_screen.dart`, `lib/features/usage/usage_screen.dart`,
      `lib/features/timeline/timeline_screen.dart`, `lib/features/billing/billing_screen.dart`,
      `lib/features/workspaces/spaces.dart`, `lib/features/files/file_preview.dart`,
      `lib/features/privacy/privacy_screen.dart`, `lib/features/bots/knowledge_screen.dart`,
      `lib/features/skills/skill_library.dart`, `lib/features/settings/about_you_screen.dart`,
      `lib/features/inbox/inbox_screen.dart`, `lib/features/board/board_screen.dart`,
      `lib/features/workspaces/people_screen.dart`,
      `lib/features/integrations/integrations_screen.dart`,
      `lib/features/settings/gallery_screen.dart`, `lib/features/skills/skill_catalog_screen.dart`
      (all with `import '../../core/number_format.dart';` above
      `import '../../core/providers.dart';`), and `lib/features/chat/widgets/chat_widgets.dart`
      (with `import '../../../core/number_format.dart';` above
      `import '../../../core/providers.dart';`). The other five files
      (`lib/core/mobile_extras.dart`, `lib/features/bots/bots_screen.dart`,
      `lib/features/settings/settings_screen.dart`, `lib/features/chat/chat_screen.dart`,
      `lib/features/computer/computer_screen.dart`) only pass the new argument and need no import.
4. `lib/l10n/app_en.arb`:
   a. Replace every occurrence of `{"type": "int"}` with
      `{"type": "int", "format": "decimalPattern"}` (all 76 of them).
   b. Put the three lines of block 64 (`@cronMonthlyAt`, `@stepOf`, `@teachStepClick`) back
      exactly as quoted, without `"format"`.
   c. Change the two strings of block 65 to their targets (remove the `$` before `{amount}`).
   d. From `client/`, run `flutter gen-l10n`. Never edit `lib/l10n/generated/` by hand.
5. `test/app_test.dart` line 335: replace `'1050 tokens'` with `'1,050 tokens'`.
6. Create `test/number_format_test.dart` with this content, then run
   `dart format -l 200 test/number_format_test.dart`:
   ```dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:casama_app/core/number_format.dart';
   import 'package:casama_app/core/providers.dart' show formatUsd;
   import 'package:casama_app/features/chat/widgets/chat_widgets.dart' show formatDuration;
   import 'package:casama_app/features/files/file_preview.dart' show formatBytes;

   void main() {
     test('counts group digits the way the locale writes them', () {
       expect(1234567.humanizedCount('en'), '1,234,567');
       expect(1234567.humanizedCount('de'), '1.234.567');
       expect(2.humanizedCount('en', decimalDigits: 2), '2.00');
     });

     test('money carries its symbol where the locale puts it', () {
       expect(1234.5.humanizedCurrency('en', 'USD'), r'$1,234.50');
       expect(1234.5.humanizedCurrency('de', 'USD'), '1.234,50 \$');
       expect(25.humanizedCurrency('en', 'USD', decimalDigits: 0), r'$25');
     });

     test('big numbers read short', () {
       expect(1234567.humanizedCompact('en'), '1.23M');
       expect(9800.humanizedCompact('en'), '9.8K');
       expect(999.humanizedCompact('en'), '999');
     });

     test('formatUsd keeps two decimals from a dollar up and four below', () {
       expect(formatUsd(1234.5, 'en'), r'$1,234.50');
       expect(formatUsd(0, 'en'), r'$0.00');
       expect(formatUsd(0.0123, 'en'), r'$0.0123');
     });

     test('durations and file sizes', () {
       expect(formatDuration(42, 'en'), '42 ms');
       expect(formatDuration(1500, 'en'), '1.5 s');
       expect(formatDuration(12000, 'en'), '12 s');
       expect(formatBytes(512, 'en'), '512 B');
       expect(formatBytes(1536, 'en'), '1.5 KB');
       expect(formatBytes(3 * 1024 * 1024, 'en'), '3.0 MB');
     });
   }
   ```
7. From `client/`, run the whole suite with `flutter test` (the translation change touches every
   screen with a count). Everything must pass.

## Check it

- `dart analyze lib/core lib/features/usage lib/features/billing lib/features/workspaces lib/features/projects lib/features/admin lib/features/timeline lib/features/chat lib/features/files lib/features/computer lib/features/privacy lib/features/bots lib/features/skills lib/features/settings lib/features/inbox lib/features/board lib/features/integrations test/number_format_test.dart test/app_test.dart` reports no issues caused by this change (a missed `formatUsd`, `formatBytes` or `formatDuration` call shows up here as a missing argument).
- `grep -c "toStringAsFixed" lib/core/providers.dart` → 0
- `grep -c "compactNumber" lib/features/usage/usage_screen.dart` → 0
- `grep -c "toStringAsFixed" lib/features/usage/usage_screen.dart` → 0
- `grep "formatUsd(" lib/features/usage/usage_screen.dart | grep -vc "localeName"` → 0
- `grep "formatUsd(" lib/features/projects/projects_screen.dart | grep -vc "localeName"` → 0
- `grep "formatUsd(" lib/features/admin/admin_screen.dart | grep -vc "localeName"` → 0
- `grep "formatUsd(" lib/features/timeline/timeline_screen.dart | grep -vc "localeName"` → 0
- `grep -c "toStringAsFixed" lib/features/billing/billing_screen.dart` → 0
- `grep -c "toStringAsFixed" lib/features/workspaces/spaces.dart` → 2 (the two editable cap fields stay)
- `grep -c "toStringAsFixed" lib/features/files/file_preview.dart` → 0
- `grep -c "toStringAsFixed" lib/features/chat/widgets/chat_widgets.dart` → 0
- `grep -c "toStringAsFixed" lib/features/privacy/privacy_screen.dart` → 0
- `grep -c "humanizedCount" lib/features/admin/admin_screen.dart` → 7
- `grep -c "humanizedCount" lib/features/workspaces/people_screen.dart` → 4
- `grep -o '"format": "decimalPattern"' lib/l10n/app_en.arb | wc -l` → 71
- `grep -n '{"type": "int"}' lib/l10n/app_en.arb` lists only the `@cronMonthlyAt`, `@stepOf` and `@teachStepClick` lines.
- `grep -cF '${amount}' lib/l10n/app_en.arb` → 0
- `grep -c "NumberFormat.decimalPattern(localeName)" lib/l10n/generated/app_localizations_en.dart` → not 0
- `grep -c "1,050 tokens" test/app_test.dart` → 1
- The `flutter test` run in step 7 passes.

## Don't touch

- Editable fields' starting text (the caps on `spaces.dart` lines 888–889 and 745,
  `checkins_sheet.dart` line 35, the limits on `admin_screen.dart` lines 327–328): a grouped
  `1,000` in a field would not parse back.
- Text written for bots, files or devices: the raw token counts in `usageSummary`, `usageCsv`,
  `health_summary.dart`, `desktop_watch.dart`, device events.
- "Which one" numbers: step numbers, click positions, the day of the month in schedules, the
  zero-padded minute in `cron_words.dart`, the 1 / 5 / 25 max-uses menu in `people_screen.dart`,
  versions and ids.
- Badges (`'$badge'`, `'${spec.badge}'`, `'${badges[o.id]}'`): always small, and capped at 99+.
- `spaces.dart` line 718 (the daily call cap, a small number on the phone-number line) and
  `admin_screen.dart` line 293 (the raw limits map shown to the instance owner).
- The unit words next to numbers ("tokens", "h", "min", "B", "KB"): translating them is separate
  work.
- Never run `dart format` on existing files or directories (only on the two new files). No git
  commands (others commit in this shared tree).
- No new dependencies. No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on
  since this plan was written). One exception: other fixes may already have changed a part of
  these lines that this plan doesn't touch. Keep that part exactly as it is now and change only
  the number formatting: `usage_screen.dart` line 121's first element may read
  `b.name.orPlaceholder(l10n.deletedBot)`; line 270's style may end in
  `fontFeatures: AppText.tabular)`; line 292's label part may read
  `${byMonth ? days[group.x].$1.formattedMonthYear(context) : …}`; `projects_screen.dart`
  line 244 and `board_screen.dart` line 386 may carry a `style:` with `AppText.tabular`.
- `flutter gen-l10n` fails.
- A test fails because it expects an ungrouped number or a `$` in a new place: report the test
  and the text instead of changing it (only `test/app_test.dart` line 335 is expected to change).
- Any other test fails because of this change.
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to
open to see it. Not a list of files, the steps already have those. For example: every amount,
count and size now goes through intl's NumberFormat in the person's language, so big numbers
read `1,234,567`, money reads `$1,234.50`, and counts in sentences are grouped too; open
Settings → Usage to see the totals, token counts and chart labels.
