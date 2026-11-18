import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../ui/app_card.dart';
import '../pages/pages_screen.dart' show openInAppBrowser;

/// Whether this server has Casama's Slack app for [botId] (D-277). The install route answers 409
/// when it has none (self-hosters connect their own Slack app with a bot token), and 403 to
/// people who don't manage the bot; either way the button stays hidden. Asking makes no change:
/// the address only carries a signed state that expires in 15 minutes.
final slackInstallAvailableProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, botId) async {
      try {
        return await ref.watch(backendProvider).slackInstallUrl(botId) != null;
      } catch (_) {
        return false;
      }
    });

/// Opens Slack's sign-in page. Overridable in tests.
final slackInstallOpenerProvider = Provider<Future<void> Function(Uri url)>(
  (ref) => openInAppBrowser,
);

/// Add to Slack: one tap opens Slack's sign-in for Casama's Slack app; Slack sends the person
/// back to a page on the server that makes the chat app. When the app comes back to the front,
/// [onReturn] runs (the chat apps list reloads to show the new one). Shows nothing when the server
/// has no Slack app.
class SlackInstallTile extends ConsumerStatefulWidget {
  const SlackInstallTile({
    super.key,
    required this.botId,
    required this.botName,
    this.onReturn,
  });
  final String botId;
  final String botName;
  final VoidCallback? onReturn;

  @override
  ConsumerState<SlackInstallTile> createState() => _SlackInstallTileState();
}

class _SlackInstallTileState extends ConsumerState<SlackInstallTile> {
  AppLifecycleListener? _listener;
  var _busy = false;

  @override
  void dispose() {
    _listener?.dispose();
    super.dispose();
  }

  Future<void> _install() async {
    setState(() => _busy = true);
    // A fresh address each time: the one checked when the screen opened may have expired.
    final url = await runGuarded(
      context,
      () => ref.read(backendProvider).slackInstallUrl(widget.botId),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (url == null) return;
    _listener ??= AppLifecycleListener(onResume: () => widget.onReturn?.call());
    await ref.read(slackInstallOpenerProvider)(Uri.parse(url));
    if (mounted) showMessage(context, context.l10n.slackInstallFinish);
  }

  @override
  Widget build(BuildContext context) {
    final available =
        ref.watch(slackInstallAvailableProvider(widget.botId)).value ?? false;
    if (!available) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GroupedCard(
        children: [
          GroupedTile(
            key: const Key('slackInstall'),
            icon: LucideIcons.hash,
            title: l10n.slackInstall,
            subtitle: l10n.slackInstallHelp(widget.botName),
            onTap: _busy ? null : _install,
            trailing: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.externalLink, size: 18),
          ),
        ],
      ),
    );
  }
}
