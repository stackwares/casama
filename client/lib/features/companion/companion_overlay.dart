import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import 'companion.dart';

/// Shows which bot is acting on this computer, with Stop. While a bot acts, the window stays on
/// top so the user can always see and stop it (D-066).
class CompanionOverlay extends ConsumerStatefulWidget {
  const CompanionOverlay({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<CompanionOverlay> createState() => _CompanionOverlayState();
}

class _CompanionOverlayState extends ConsumerState<CompanionOverlay> {
  bool? _onTop;

  bool get _desktop => !kIsWeb && const {TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux}.contains(defaultTargetPlatform);

  void _keepOnTop(bool on) {
    if (!_desktop || _onTop == on) return;
    _onTop = on;
    try {
      WindowManager.instance.getCurrent()?.isAlwaysOnTop = on;
    } catch (_) {
      // Window control is best effort (some Linux window managers refuse it).
    }
  }

  @override
  Widget build(BuildContext context) {
    final companion = ref.watch(companionProvider);
    return ValueListenableBuilder<CompanionActivity?>(
      valueListenable: companion.activity,
      builder: (context, a, child) {
        _keepOnTop(a != null);
        return Stack(
          children: [
            child!,
            if (a != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Material(
                    key: const Key('companionOverlay'),
                    elevation: 6,
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.bot, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.botActingHere(a.bot, a.summary.isEmpty ? a.tool : a.summary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton.icon(
                            key: const Key('companionStop'),
                            icon: const Icon(LucideIcons.circleStop),
                            label: Text(context.l10n.stop),
                            onPressed: () => runGuarded(context, () => ref.read(backendProvider).cancelRun(a.runId)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
