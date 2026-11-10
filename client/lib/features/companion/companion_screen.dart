import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import 'companion.dart';
import 'companion_controller.dart';

/// Settings > Use this computer for bots (desktop only, D-066).
class CompanionScreen extends ConsumerWidget {
  const CompanionScreen({super.key});

  static const capabilityKeys = ['shell', 'files', 'browser', 'desktop'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final companion = ref.watch(companionProvider);
    final controller = ref.read(companionControllerProvider.notifier);
    final value = ref.watch(companionControllerProvider);
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    String capLabel(String c) => switch (c) {
      'shell' => l10n.capShell,
      'files' => l10n.capFiles,
      'browser' => l10n.capBrowser,
      _ => l10n.capDesktop,
    };
    return SubPage(
      title: l10n.useThisComputer,
      body: !companion.supported
          ? EmptyState(icon: Icons.desktop_access_disabled_outlined, title: l10n.useThisComputer, message: l10n.companionDesktopOnly)
          : AsyncView(
              value: value,
              onRetry: () => ref.invalidate(companionControllerProvider),
              data: (device) {
                if (device == null) {
                  return EmptyState(
                    icon: Icons.laptop_mac_rounded,
                    title: l10n.useThisComputer,
                    message: l10n.companionIntro,
                    action: FilledButton.icon(
                      key: const Key('pairComputer'),
                      onPressed: () => runGuarded(context, () => controller.pair(l10n.thisComputer)),
                      icon: const Icon(Icons.link_rounded, size: 18),
                      label: Text(l10n.useThisComputer),
                    ),
                  );
                }
                final caps = capsOf(device);
                final scheme = context.colorScheme;
                return ValueListenableBuilder(
                  valueListenable: companion.status,
                  builder: (context, status, _) {
                    final (statusText, statusColor) = switch (status) {
                      CompanionStatus.online => (l10n.companionOnline, context.appColors.working),
                      CompanionStatus.connecting => (l10n.connectingLive, context.appColors.waiting),
                      CompanionStatus.error => (l10n.companionError, context.appColors.negative),
                      CompanionStatus.off => (l10n.companionOff, scheme.onSurfaceVariant),
                    };
                    return PageColumn(
                      children: [
                        AppCard(
                          padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.sm, AppSpace.md),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                                alignment: Alignment.center,
                                child: Icon(Icons.laptop_mac_rounded, color: statusColor),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.useThisComputer, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    StatusLabel(key: const Key('companionStatus'), text: statusText, color: statusColor, pill: true),
                                  ],
                                ),
                              ),
                              Switch(
                                key: const Key('companionEnabled'),
                                value: device.enabled,
                                onChanged: (v) => runGuarded(context, () => controller.save(enabled: v)),
                              ),
                            ],
                          ),
                        ),
                        SectionHeader(title: l10n.companionCapabilities),
                        GroupedCard(
                          children: [
                            for (final c in capabilityKeys)
                              GroupedTile(
                                key: Key('cap-$c'),
                                icon: switch (c) {
                                  'shell' => Icons.terminal_rounded,
                                  'files' => Icons.folder_outlined,
                                  'browser' => Icons.language_rounded,
                                  _ => Icons.mouse_outlined,
                                },
                                title: capLabel(c),
                                onTap: () => runGuarded(context, () => controller.save(capabilities: caps.contains(c) ? ({...caps}..remove(c)) : {...caps, c})),
                                trailing: Switch(
                                  value: caps.contains(c),
                                  onChanged: (v) => runGuarded(context, () => controller.save(capabilities: v ? {...caps, c} : ({...caps}..remove(c)))),
                                ),
                              ),
                          ],
                        ),
                        Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 0), child: FormNote(l10n.companionCapabilitiesHelp)),
                        SectionHeader(
                          title: l10n.sharedFolders,
                          trailing: TextButton.icon(
                            key: const Key('addFolder'),
                            onPressed: () async {
                              final dir = await FilePicker.getDirectoryPath();
                              if (dir == null || !context.mounted) return;
                              await runGuarded(context, () => controller.save(roots: {...device.allowedRoots, dir}.toList()));
                            },
                            icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                            label: Text(l10n.addFolder),
                          ),
                        ),
                        if (device.allowedRoots.isEmpty)
                          AppCard(child: FormNote(l10n.sharedFoldersHelp, icon: Icons.folder_off_outlined))
                        else
                          GroupedCard(
                            children: [
                              for (final r in device.allowedRoots)
                                GroupedTile(
                                  icon: Icons.folder_outlined,
                                  title: r.split('/').where((p) => p.isNotEmpty).lastOrNull ?? r,
                                  subtitle: r,
                                  trailing: IconButton(
                                    tooltip: l10n.delete,
                                    icon: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
                                    onPressed: () => runGuarded(context, () => controller.save(roots: device.allowedRoots.where((x) => x != r).toList())),
                                  ),
                                ),
                            ],
                          ),
                        SectionHeader(title: l10n.botsAllowed),
                        GroupedCard(
                          children: [
                            for (final b in bots)
                              CheckboxListTile(
                                key: Key('allowBot-${b.id}'),
                                secondary: BotAvatar(name: b.name, size: 32),
                                title: Text(b.name, style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                                value: device.allowedBotIds.contains(b.id),
                                onChanged: (v) async {
                                  final ids = v == true ? {...device.allowedBotIds, b.id} : ({...device.allowedBotIds}..remove(b.id));
                                  await runGuarded(context, () async {
                                    await controller.save(botIds: ids.toList());
                                    // An allowed bot uses this computer; a removed one goes back to its default.
                                    await ref.read(backendProvider).setBotComputer(b.id, v == true ? device.computerId : null);
                                  });
                                  ref.invalidate(botsProvider);
                                },
                              ),
                          ],
                        ),
                        Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 0), child: FormNote(l10n.botsAllowedHelp)),
                        const SizedBox(height: AppSpace.lg),
                        GroupedCard(
                          children: [
                            GroupedTile(
                              icon: Icons.link_off_rounded,
                              destructive: true,
                              title: l10n.unpairComputer,
                              onTap: () => runGuarded(context, controller.unpair),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}
