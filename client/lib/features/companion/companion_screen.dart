import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.useThisComputer)),
      body: !companion.supported
          ? EmptyState(icon: Icons.desktop_access_disabled, message: l10n.companionDesktopOnly)
          : AsyncView(
              value: value,
              onRetry: () => ref.invalidate(companionControllerProvider),
              data: (device) {
                if (device == null) {
                  return EmptyState(
                    icon: Icons.laptop_mac,
                    message: l10n.companionIntro,
                    action: FilledButton(
                      key: const Key('pairComputer'),
                      onPressed: () => runGuarded(context, () => controller.pair(l10n.thisComputer)),
                      child: Text(l10n.useThisComputer),
                    ),
                  );
                }
                final caps = capsOf(device);
                return ValueListenableBuilder(
                  valueListenable: companion.status,
                  builder: (context, status, _) => ListView(padding: const EdgeInsets.all(8), children: [
                    SwitchListTile(
                      key: const Key('companionEnabled'),
                      title: Text(l10n.useThisComputer),
                      subtitle: Text(switch (status) {
                        CompanionStatus.online => l10n.companionOnline,
                        CompanionStatus.connecting => l10n.connectingLive,
                        CompanionStatus.error => l10n.companionError,
                        CompanionStatus.off => l10n.companionOff,
                      }, key: const Key('companionStatus')),
                      value: device.enabled,
                      onChanged: (v) => runGuarded(context, () => controller.save(enabled: v)),
                    ),
                    const Divider(),
                    ListTile(title: Text(l10n.companionCapabilities), subtitle: Text(l10n.companionCapabilitiesHelp)),
                    for (final c in capabilityKeys)
                      SwitchListTile(
                        key: Key('cap-$c'),
                        title: Text(capLabel(c)),
                        value: caps.contains(c),
                        onChanged: (v) => runGuarded(
                          context,
                          () => controller.save(capabilities: v ? {...caps, c} : ({...caps}..remove(c))),
                        ),
                      ),
                    const Divider(),
                    ListTile(
                      title: Text(l10n.sharedFolders),
                      subtitle: Text(l10n.sharedFoldersHelp),
                      trailing: IconButton(
                        key: const Key('addFolder'),
                        tooltip: l10n.addFolder,
                        icon: const Icon(Icons.create_new_folder_outlined),
                        onPressed: () async {
                          final dir = await FilePicker.getDirectoryPath();
                          if (dir == null || !context.mounted) return;
                          await runGuarded(context, () => controller.save(roots: {...device.allowedRoots, dir}.toList()));
                        },
                      ),
                    ),
                    for (final r in device.allowedRoots)
                      ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(r),
                        trailing: IconButton(
                          tooltip: l10n.delete,
                          icon: const Icon(Icons.close),
                          onPressed: () => runGuarded(
                            context,
                            () => controller.save(roots: device.allowedRoots.where((x) => x != r).toList()),
                          ),
                        ),
                      ),
                    const Divider(),
                    ListTile(title: Text(l10n.botsAllowed), subtitle: Text(l10n.botsAllowedHelp)),
                    for (final b in bots)
                      CheckboxListTile(
                        key: Key('allowBot-${b.id}'),
                        title: Text(b.name),
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
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.link_off),
                      title: Text(l10n.unpairComputer),
                      onTap: () => runGuarded(context, controller.unpair),
                    ),
                  ]),
                );
              },
            ),
    );
  }
}
