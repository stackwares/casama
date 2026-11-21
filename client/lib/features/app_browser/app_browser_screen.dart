import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import 'app_browser_ask.dart';
import 'app_browser_controller.dart';
import 'app_browser_flag.dart';
import 'app_browser_view.dart';

/// The phone browser full size (plan §8.7): the site's name with a lock for https, the bot's name
/// while it works, Stop, Take Over and Hand Back, "Your turn" for a handoff, and the asks over the
/// page. With [person] it's the person's own browsing (Sign In to a Site): an address field,
/// back, forward, reload and "Let My Bots Use This Site".
class AppBrowserScreen extends ConsumerStatefulWidget {
  const AppBrowserScreen({super.key, this.person = false, this.startUrl});
  final bool person;
  final String? startUrl;

  @override
  ConsumerState<AppBrowserScreen> createState() => _AppBrowserScreenState();
}

class _AppBrowserScreenState extends ConsumerState<AppBrowserScreen> {
  final _address = TextEditingController();
  late final AppBrowserController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(appBrowserProvider.notifier);
    // After this frame: a provider can't change while the tree builds.
    if (widget.person) {
      Future.microtask(() => _controller.openForPerson(widget.startUrl));
    }
  }

  @override
  void dispose() {
    if (widget.person) Future.microtask(_controller.closePerson);
    _address.dispose();
    super.dispose();
  }

  Future<void> _go(String text) async {
    final ok = await _controller.loadForPerson(text);
    if (!ok && mounted) {
      showWarning(context, context.l10n.appBrowserAddressRefused);
    }
  }

  Future<void> _allowSite() async {
    final host = await runGuarded(context, _controller.allowCurrentSite);
    if (host != null && mounted) {
      showSuccess(context, context.l10n.appBrowserSiteAdded(host));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!kAppBrowserCode || !ref.watch(appBrowserOnProvider)) {
      return const Scaffold();
    }
    final s = ref.watch(appBrowserProvider);
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final bot = s.run?.botName ?? '';
    final site = s.host ?? (s.title.isNotEmpty ? s.title : '');
    ref.listen(appBrowserProvider.select((v) => v.url), (_, url) {
      if (widget.person &&
          url != null &&
          url != 'about:blank' &&
          !_address.selection.isValid) {
        _address.text = url;
      }
    });
    final banner = switch (s.phase) {
      AppBrowserPhase.yourTurn => _Banner(
        key: const Key('appBrowserYourTurn'),
        color: colors.waiting,
        icon: LucideIcons.hand,
        title: l10n.appBrowserYourTurn,
        message: s.handoffReason,
        action: TextButton(
          key: const Key('appBrowserHandBackBanner'),
          onPressed: _controller.handBack,
          child: Text(l10n.appBrowserHandBack),
        ),
      ),
      AppBrowserPhase.tookOver => _Banner(
        key: const Key('appBrowserPausedBanner'),
        color: colors.working,
        icon: LucideIcons.pause,
        title: l10n.appBrowserPaused(bot),
        action: TextButton(
          key: const Key('appBrowserHandBackBanner'),
          onPressed: _controller.handBack,
          child: Text(l10n.appBrowserHandBack),
        ),
      ),
      AppBrowserPhase.away when s.run != null => _Banner(
        color: scheme.onSurfaceVariant,
        icon: LucideIcons.circlePause,
        title: l10n.appBrowserAway,
      ),
      _ => null,
    };
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('appBrowserClose'),
          tooltip: l10n.close,
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (site.isNotEmpty)
                  Tooltip(
                    message: s.secure
                        ? l10n.appBrowserSecure
                        : l10n.appBrowserNotSecure,
                    child: Icon(
                      s.secure ? LucideIcons.lock : LucideIcons.lockOpen,
                      key: Key(
                        s.secure ? 'appBrowserLock' : 'appBrowserNoLock',
                      ),
                      size: 15,
                      color: s.secure
                          ? scheme.onSurfaceVariant
                          : colors.negative,
                    ),
                  ),
                if (site.isNotEmpty) const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    site.isEmpty ? l10n.appBrowserTitle : site,
                    key: const Key('appBrowserSite'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (s.botActive)
              Text(
                l10n.appBrowserWorking(bot),
                key: const Key('appBrowserBot'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          if (s.botActive &&
              s.phase != AppBrowserPhase.tookOver &&
              s.phase != AppBrowserPhase.yourTurn)
            TextButton(
              key: const Key('appBrowserTakeOver'),
              onPressed: _controller.takeOver,
              child: Text(l10n.appBrowserTakeOver),
            ),
          if (s.phase == AppBrowserPhase.tookOver ||
              s.phase == AppBrowserPhase.yourTurn)
            TextButton(
              key: const Key('appBrowserHandBack'),
              onPressed: _controller.handBack,
              child: Text(l10n.appBrowserHandBack),
            ),
          if (s.botActive)
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.xs),
              child: TextButton.icon(
                key: const Key('appBrowserStop'),
                style: TextButton.styleFrom(foregroundColor: colors.negative),
                onPressed: () {
                  HapticsHelper.medium();
                  _controller.stopBot();
                },
                icon: const Icon(LucideIcons.square, size: 16),
                label: Text(l10n.stop),
              ),
            ),
        ],
        bottom: s.loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (widget.person)
              _AddressBar(
                controller: _address,
                session: s,
                onGo: _go,
                browser: _controller,
              ),
            ?banner,
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ref.watch(appBrowserWebAreaProvider)(context),
                  if (s.ask != null)
                    Positioned(
                      left: AppSpace.sm,
                      right: AppSpace.sm,
                      bottom: AppSpace.sm,
                      child: Material(
                        type: MaterialType.transparency,
                        child: AppBrowserAskCard(ask: s.ask!),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.person)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.md,
                  AppSpace.xs,
                  AppSpace.md,
                  AppSpace.xs,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('appBrowserAllowSite'),
                    onPressed: s.host == null ? null : _allowSite,
                    icon: const Icon(LucideIcons.check, size: 18),
                    label: Text(l10n.appBrowserAllowSite),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddressBar extends StatelessWidget {
  const _AddressBar({
    required this.controller,
    required this.session,
    required this.onGo,
    required this.browser,
  });
  final TextEditingController controller;
  final AppBrowserSession session;
  final ValueChanged<String> onGo;
  final AppBrowserController browser;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xs,
        0,
        AppSpace.xs,
        AppSpace.xs,
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('appBrowserBack'),
            tooltip: l10n.appBrowserBack,
            icon: const Icon(LucideIcons.chevronLeft),
            onPressed: session.canGoBack ? browser.back : null,
          ),
          IconButton(
            key: const Key('appBrowserForward'),
            tooltip: l10n.appBrowserForward,
            icon: const Icon(LucideIcons.chevronRight),
            onPressed: session.canGoForward ? browser.forward : null,
          ),
          Expanded(
            child: TextField(
              key: const Key('appBrowserAddress'),
              controller: controller,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: l10n.appBrowserAddress,
                isDense: true,
                prefixIcon: const Icon(LucideIcons.globe, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: onGo,
            ),
          ),
          IconButton(
            key: const Key('appBrowserReload'),
            tooltip: l10n.appBrowserReload,
            icon: const Icon(LucideIcons.rotateCw),
            onPressed: session.url == null ? null : browser.reload,
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });
  final Color color;
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(
      AppSpace.md,
      AppSpace.xs,
      AppSpace.xs,
      AppSpace.xs,
    ),
    color: color.withValues(alpha: 0.14),
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpace.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if ((message ?? '').isNotEmpty)
                Text(message!, style: context.textTheme.bodySmall),
            ],
          ),
        ),
        ?action,
      ],
    ),
  );
}
